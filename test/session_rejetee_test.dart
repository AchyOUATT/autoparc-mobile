import 'package:auto/core/api/api_exception.dart';
import 'package:auto/features/partner_accounts/data/partner_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Deux refus que 403 confond, et que le client doit traiter à l'opposé.
///
/// ── LES DEUX FAUTES SYMETRIQUES QUE CE BANC FERME ──────────────────────────
///
/// Côté partenaire, la règle était `statusCode == 401 || statusCode == 403`.
/// Elle effaçait le jeton sur n'importe quel 403 — « cette annonce n'est pas
/// la vôtre » comprise. Un partenaire perdait sa session en touchant une
/// annonce qui n'était pas la sienne.
///
/// Côté personnel, la règle était `statusCode == 401` seul, et c'était le bon
/// choix à l'époque : le plan gratuit de Render s'endort, un délai dépassé ne
/// doit pas déconnecter (34,8 s mesurées sur `/up` à froid le 2026-10-15,
/// aucune réponse en 180 s le 11 octobre). Mais le lot 1 a fait rendre 403
/// `account_disabled` à un compte désactivé — un statut qui veut dire « ce
/// compte est fini », atterrissant dans le panier « le serveur est juste
/// lent ». L'employé passait en mode visiteur sans un mot, le jeton mort
/// restant au coffre.
///
/// Même cause des deux côtés : avoir demandé au STATUT de dire ce que seul le
/// CODE peut dire. Ce banc éprouve les deux sens — ce qui doit fermer la
/// session, et ce qui ne doit surtout pas la fermer.
void main() {
  final requete = RequestOptions(path: '/api/me');

  DioException reponse(int code, {Object? corps}) => DioException(
        requestOptions: requete,
        response:
            Response(requestOptions: requete, statusCode: code, data: corps),
      );

  group('Le code lu depuis la réponse du serveur', () {
    test('un compte désactivé est reconnu, et ferme la session', () {
      final e = ApiException.fromDioError(reponse(403, corps: {
        'message': 'Votre compte a ete desactive.',
        'code': 'account_disabled',
        'request_id': 'abc12345',
      }));

      expect(e.code, 'account_disabled');
      expect(e.isAccountDisabled, isTrue);
      expect(e.isPermissionDenied, isFalse);
      expect(e.sessionRejected, isTrue);

      // Le motif du serveur est conservé : c'est lui qu'on montre, et il dit
      // à l'utilisateur pourquoi il vient d'être déconnecté.
      expect(e.userMessage, 'Votre compte a ete desactive.');
    });

    test('un refus de permission NE ferme PAS la session', () {
      final e = ApiException.fromDioError(reponse(403, corps: {
        'message': 'Acces reserve au personnel.',
        'code': 'permission_denied',
      }));

      expect(e.isPermissionDenied, isTrue);
      expect(e.isAccountDisabled, isFalse);
      expect(e.sessionRejected, isFalse,
          reason: "C'est la faute d'origine du côté partenaire : un refus "
              "d'autorisation effaçait le jeton.");
    });

    /// LE BANC DE COMPATIBILITE, et il compte autant que les autres.
    ///
    /// Le serveur déployé porte les codes, mais un 403 sans `code` reste
    /// possible : un middleware tiers, un mandataire, une route qui appelle
    /// encore `abort(403)`. Si l'absence de code valait « session morte »,
    /// l'application régresserait vers la faute qu'on vient de corriger.
    /// L'absence de code ne décide donc de RIEN.
    test('un 403 sans code ne ferme rien du tout', () {
      final e =
          ApiException.fromDioError(reponse(403, corps: {'message': 'Interdit.'}));

      expect(e.code, isNull);
      expect(e.isAccountDisabled, isFalse);
      expect(e.sessionRejected, isFalse);
    });

    test('un 401 ferme la session, avec ou sans code', () {
      expect(
        ApiException.fromDioError(
                reponse(401, corps: {'message': 'Unauthenticated.'}))
            .sessionRejected,
        isTrue,
      );

      // 401 est décisif à lui seul : le jeton n'existe plus. Un code qui
      // dirait le contraire ne peut pas le racheter.
      expect(
        ApiException.fromDioError(reponse(401,
                corps: {'message': 'x', 'code': 'permission_denied'}))
            .sessionRejected,
        isTrue,
      );
    });

    test('un code non textuel est ignoré au lieu de faire lever', () {
      final e = ApiException.fromDioError(
          reponse(403, corps: {'message': 'x', 'code': 42}));

      expect(e.code, isNull, reason: 'Transtyper aurait levé et perdu le 403.');
      expect(e.sessionRejected, isFalse);
    });

    test('un corps vide ou non JSON ne fait pas lever', () {
      expect(ApiException.fromDioError(reponse(403)).sessionRejected, isFalse);
      expect(
        ApiException.fromDioError(reponse(403, corps: '<html>502</html>'))
            .sessionRejected,
        isFalse,
      );
    });

    /// LE BANC QUI PROTEGE LE PLAN GRATUIT DE RENDER.
    ///
    /// Une coupure, un délai dépassé, un 500 : le serveur n'a pas dit que la
    /// session était morte, il n'a rien dit du tout. Fermer la session là
    /// dessus est le défaut qui déconnectait le personnel à chaque
    /// réouverture de l'application.
    test('ni coupure réseau ni erreur serveur ne ferment une session', () {
      final coupure = ApiException.fromDioError(DioException(
        requestOptions: requete,
        type: DioExceptionType.connectionError,
        message: 'SocketException: Failed host lookup',
      ));

      expect(coupure.isNetworkFailure, isTrue);
      expect(coupure.code, isNull);
      expect(coupure.sessionRejected, isFalse);

      expect(
        ApiException.fromDioError(
                reponse(500, corps: {'message': 'Server Error'}))
            .sessionRejected,
        isFalse,
      );
      expect(
        ApiException.fromDioError(reponse(503, corps: {'message': 'Maintenance'}))
            .sessionRejected,
        isFalse,
      );
    });
  });

  /// `PartnerApiException` est une classe PARALLELE, pas dérivée : rien dans
  /// le langage ne garantit que les deux règles restent d'accord. Ce groupe
  /// est ce qui le garantit.
  group('PartnerApiException tient exactement la même règle', () {
    test('account_disabled ferme, un 403 nu ou de permission ne ferme pas', () {
      expect(
        const PartnerApiException('x',
                statusCode: 403, code: 'account_disabled')
            .sessionRejected,
        isTrue,
      );
      expect(
        const PartnerApiException('x',
                statusCode: 403, code: 'permission_denied')
            .sessionRejected,
        isFalse,
      );
      expect(
        const PartnerApiException('x', statusCode: 403).sessionRejected,
        isFalse,
      );
      expect(
        const PartnerApiException('x', statusCode: 401).sessionRejected,
        isTrue,
      );
    });

    test('les deux classes répondent la même chose aux mêmes entrées', () {
      for (final (statut, code) in const [
        (401, null),
        (401, 'permission_denied'),
        (403, 'account_disabled'),
        (403, 'permission_denied'),
        (403, null),
        (404, null),
        (500, null),
      ]) {
        final cote = ApiException(statusCode: statut, message: 'x', code: code);
        final partenaire =
            PartnerApiException('x', statusCode: statut, code: code);

        expect(
          partenaire.sessionRejected,
          cote.sessionRejected,
          reason: 'Désaccord sur ($statut, $code) : les deux règles ont '
              'divergé, et c\'est exactement ce qui a produit la panne.',
        );
      }
    });
  });
}
