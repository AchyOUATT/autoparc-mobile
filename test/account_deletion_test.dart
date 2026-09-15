import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Suppression de compte, côté application.
///
/// Le point sensible n'est pas l'appel — c'est ce qui se passe quand il échoue.
/// Remettre l'état à zéro sans distinguer le succès de l'échec afficherait un
/// écran déconnecté après une suppression qui n'a pas eu lieu : la personne
/// croirait ses données effacées alors qu'elles sont toujours là.
class _FauxDepot extends AuthRepository {
  _FauxDepot({this.erreur}) : super(ApiClient());

  final Object? erreur;
  var appele = false;

  @override
  Future<void> deleteClientAccount() async {
    appele = true;
    if (erreur != null) throw erreur!;
  }
}

/// Crée le notifier et laisse son initialisation se terminer, sans quoi la fin
/// de `_init()` écraserait l'état posé par le test.
Future<AuthNotifier> _notifier(_FauxDepot depot) async {
  final auth = AuthNotifier(depot);
  await Future<void>.delayed(Duration.zero);
  return auth;
}

/// Place le notifier dans l'état « client connecté ».
///
/// `firebaseUser` reste nul — il demanderait un vrai Firebase — mais `type`
/// suffit : c'est lui que `deleteAccount` consulte.
void _connecterClient(AuthNotifier auth) {
  auth.state = auth.state.copyWith(type: AuthType.client);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  group('Suppression de compte', () {
    test('un succès déconnecte et ne rend aucun message', () async {
      final depot = _FauxDepot();
      final auth  = await _notifier(depot);
      _connecterClient(auth);

      final erreur = await auth.deleteAccount();

      expect(depot.appele, isTrue);
      expect(erreur, isNull);
      expect(auth.state.isAuthenticated, isFalse);
      expect(auth.state.type, AuthType.none);
    });

    /// Le défaut que ce test existe pour empêcher.
    test('un échec laisse la session en place et dit pourquoi', () async {
      final depot = _FauxDepot(
        erreur: const ApiException(statusCode: 500, message: 'Serveur indisponible.'),
      );
      final auth = await _notifier(depot);
      _connecterClient(auth);

      final erreur = await auth.deleteAccount();

      expect(erreur, isNotNull);
      expect(auth.state.isClient, isTrue,
          reason: 'Une suppression ratée ne déconnecte pas : ce serait annoncer '
              'un effacement qui n\'a pas eu lieu.');
      expect(auth.state.isLoading, isFalse);
      expect(auth.state.error, isNotNull);
    });

    test('une panne réseau se dit en termes lisibles', () async {
      final depot = _FauxDepot(erreur: Exception('SocketException'));
      final auth  = await _notifier(depot);
      _connecterClient(auth);

      final erreur = await auth.deleteAccount();

      expect(erreur, isNotNull);
      expect(erreur, isNot(contains('Exception')));
    });

    /// Le personnel relève d'un autre système d'identité : son compte se gère
    /// côté serveur, pas depuis cet écran.
    test('un compte du personnel n\'est pas supprimable ici', () async {
      final depot = _FauxDepot();
      final auth  = await _notifier(depot);
      auth.state = auth.state.copyWith(type: AuthType.staff);

      final erreur = await auth.deleteAccount();

      expect(depot.appele, isFalse);
      expect(erreur, isNotNull);
      expect(auth.state.isStaff, isTrue);
    });

    test('sans session, rien n\'est appelé', () async {
      final depot = _FauxDepot();
      final auth  = await _notifier(depot);

      expect(await auth.deleteAccount(), isNotNull);
      expect(depot.appele, isFalse);
    });
  });
}
