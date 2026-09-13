import 'package:auto/core/api/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ce que l'utilisateur lit quand ça échoue.
///
/// L'application affichait l'exception brute : « ApiException(500): Server
/// Error », ou le message anglais de Dio sur une coupure réseau. Visible, mais
/// inexploitable — ni pour l'utilisateur, qui ne sait pas quoi faire, ni pour
/// le développeur, qui n'a aucune prise pour chercher.
void main() {
  final requete = RequestOptions(path: '/api/catalog/vehicles');

  DioException reponse(int code, {Object? corps, Map<String, List<String>>? entetes}) =>
      DioException(
        requestOptions: requete,
        response: Response(
          requestOptions: requete,
          statusCode: code,
          data: corps,
          headers: Headers.fromMap(entetes ?? {}),
        ),
      );

  DioException coupure() => DioException(
        requestOptions: requete,
        type: DioExceptionType.connectionError,
        message: 'SocketException: Failed host lookup',
      );

  group('Message présenté à l\'utilisateur', () {
    test('une coupure réseau le dit, en français', () {
      final e = ApiException.fromDioError(coupure());

      expect(e.isNetworkFailure, isTrue);
      expect(e.userMessage, contains('connexion'));
      expect(e.userMessage, isNot(contains('SocketException')));
    });

    test('une session expirée invite à se reconnecter', () {
      final e = ApiException.fromDioError(
        reponse(401, corps: {'message': 'Token Firebase invalide ou expire.'}),
      );

      expect(e.userMessage.toLowerCase(), contains('reconnect'));
    });

    /// Le serveur sait pourquoi il refuse : « Votre rôle ne permet pas cette
    /// action ». Le remplacer par un message générique perdrait l'information.
    test('un refus de droits conserve le message du serveur', () {
      final e = ApiException.fromDioError(
        reponse(403, corps: {'message': 'Votre role ne permet pas cette action.'}),
      );

      expect(e.userMessage, 'Votre role ne permet pas cette action.');
    });

    test('une validation montre la première erreur corrigeable', () {
      final e = ApiException.fromDioError(reponse(422, corps: {
        'message': 'The given data was invalid.',
        'errors': {
          'plate_number': ['Le numéro de plaque est déjà utilisé.'],
        },
      }));

      expect(e.userMessage, 'Le numéro de plaque est déjà utilisé.');
    });

    test('une erreur serveur ne montre pas « Server Error » mais une référence', () {
      final e = ApiException.fromDioError(reponse(500, corps: {
        'message': 'Server Error',
        'request_id': 'a1b2c3d4',
      }));

      expect(e.userMessage, isNot(contains('Server Error')));
      expect(e.userMessage, contains('a1b2c3d4'),
          reason: 'Sans la référence, le signalement de l\'utilisateur ne mène nulle part.');
    });

    /// Le cas qui avait coûté des heures : le serveur ne peut pas vérifier la
    /// session. Lui répondre « reconnectez-vous » envoie tourner en rond.
    test('une vérification impossible affiche le message du serveur, pas une invite à se reconnecter', () {
      final e = ApiException.fromDioError(reponse(503, corps: {
        'message': 'Verification de session indisponible. Reessayez dans un instant.',
        'request_id': 'ff00ff00',
      }));

      expect(e.userMessage, contains('indisponible'));
      expect(e.userMessage.toLowerCase(), isNot(contains('reconnect')));
      expect(e.userMessage, contains('ff00ff00'));
    });
  });

  group('Référence de requête', () {
    test('elle est lue dans le corps', () {
      final e = ApiException.fromDioError(
        reponse(500, corps: {'message': 'Server Error', 'request_id': 'depuis-le-corps'}),
      );

      expect(e.requestId, 'depuis-le-corps');
    });

    /// Une réponse non JSON — passerelle, proxy — n'a pas de corps exploitable ;
    /// l'en-tête reste.
    test('à défaut, elle est lue dans l\'en-tête', () {
      final e = ApiException.fromDioError(reponse(
        502,
        corps: '<html>Bad Gateway</html>',
        entetes: {'x-request-id': ['depuis-l-entete']},
      ));

      expect(e.requestId, 'depuis-l-entete');
      expect(e.userMessage, contains('depuis-l-entete'));
    });
  });

  group('messageFor', () {
    test('accepte une exception quelconque sans afficher sa classe', () {
      final message = messageFor(StateError('Bad state: no element'));

      expect(message, isNot(contains('StateError')));
      expect(message, isNotEmpty);
    });

    test('déballe une DioException brute', () {
      expect(messageFor(coupure()), contains('connexion'));
    });
  });
}
