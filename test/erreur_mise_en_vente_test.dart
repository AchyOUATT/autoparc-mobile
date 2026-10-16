import 'package:auto/core/api/api_exception.dart';
import 'package:auto/features/vehicles/presentation/pages/vehicle_register_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le titre qui n'a jamais dit la vérité.
///
/// L'écran de mise en vente affichait `title: const Text('Erreur serveur')`,
/// écrit en dur. Un champ refusé, le réseau coupé, une session expirée : tout
/// s'annonçait comme une panne du serveur.
///
/// Ce n'est pas un défaut d'apparence. Le propriétaire a signalé « erreur
/// serveur sans autre précision », et ce titre a envoyé chercher du côté du
/// serveur ce qui se répare à l'écran — l'enquête est allée jusqu'à sonder la
/// route de production avant qu'on s'aperçoive que le titre ne disait rien.
///
/// Le corps aggravait le cas : il rendait `e.message`, le texte brut du
/// serveur, au lieu de `e.userMessage`. En production Laravel répond
/// `{"message":"Server Error","request_id":"..."}` — l'écran affichait donc
/// « Server Error » et **jetait la référence**, qui est le seul fil entre ce
/// que voit l'utilisateur et ce qu'on peut lire dans le journal du serveur.
void main() {
  ApiException erreur(int? code) =>
      ApiException(message: 'peu importe', statusCode: code);

  group('Le titre nomme la cause', () {
    test('un champ refusé parle du formulaire, pas du serveur', () {
      expect(titreErreurEnregistrement(erreur(422)), 'Formulaire incomplet');
    });

    test('une session expirée se dit telle quelle', () {
      expect(titreErreurEnregistrement(erreur(401)), 'Session expirée');
    });

    test('un refus de droits ne se déguise pas en panne', () {
      expect(titreErreurEnregistrement(erreur(403)), 'Action non autorisée');
    });

    test('un envoi trop volumineux se répare à l\'écran', () {
      expect(titreErreurEnregistrement(erreur(413)), 'Envoi trop volumineux');
    });

    test('seule une vraie 5xx porte le nom du serveur', () {
      expect(titreErreurEnregistrement(erreur(500)), 'Erreur du serveur');
      expect(titreErreurEnregistrement(erreur(502)), 'Erreur du serveur');
    });

    test('un code inattendu reste honnête sur son ignorance', () {
      // 405, 409, 418 : on ne prétend pas savoir d'où ça vient.
      expect(titreErreurEnregistrement(erreur(405)), 'Enregistrement impossible');
      expect(titreErreurEnregistrement(erreur(null)), 'Enregistrement impossible');
    });

    test('une coupure réseau l\'emporte sur le code', () {
      // isNetworkFailure est testé avant le switch : sans cela, une requête
      // qui n'a jamais atteint le serveur s'annoncerait comme une panne de
      // celui-ci. C'est précisément le cas du réveil à froid de Render, qui
      // prend jusqu'à 35 secondes.
      final coupure = ApiException.fromDioError(
        DioException(
          requestOptions: RequestOptions(path: '/vehicles'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(coupure.isNetworkFailure, isTrue);
      expect(titreErreurEnregistrement(coupure), 'Pas de connexion');
    });
  });

  group('La référence survit jusqu\'à l\'écran', () {
    test('userMessage rattache la référence à une 5xx', () {
      // C'est ce que l'ancien code perdait en affichant e.message.
      final e = ApiException(
          message: 'Server Error', statusCode: 500, requestId: 'nj027ajn');

      expect(e.userMessage, contains('nj027ajn'));
      expect(
        e.message,
        isNot(contains('nj027ajn')),
        reason: 'La référence ne vient pas du message brut : c\'est bien '
            'userMessage qui la rattache.',
      );
    });
  });
}
