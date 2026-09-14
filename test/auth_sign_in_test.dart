import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Connexion unifiée : un seul formulaire, deux systèmes d'identité.
///
/// L'application essaie Firebase, puis le compte serveur. Le point délicat est
/// de savoir *quand* se rabattre : un mot de passe refusé justifie d'essayer
/// l'autre système, une panne réseau non. Une première version basculait sur
/// n'importe quel échec, et affichait donc « Email ou mot de passe incorrect »
/// pour une panne qui n'avait rien à voir avec le compte — la personne
/// cherchait une faute de frappe inexistante.
class _FauxDepot extends AuthRepository {
  _FauxDepot({this.erreurFirebase, this.erreurStaff, this.staff})
      : super(ApiClient());

  final Object? erreurFirebase;
  final Object? erreurStaff;
  final StaffUser? staff;

  var firebaseAppele = false;
  var staffAppele    = false;

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    firebaseAppele = true;
    throw erreurFirebase ?? FirebaseAuthException(code: 'invalid-credential');
  }

  @override
  Future<StaffUser> loginStaff(String email, String password) async {
    staffAppele = true;
    if (erreurStaff != null) throw erreurStaff!;
    return staff!;
  }
}

const _staff = StaffUser(
  id: 1,
  name: 'Marie Konaté',
  email: 'manager@autoparc.bf',
  role: 'manager',
);

/// Cree le notifier et laisse son initialisation se terminer.
///
/// Le constructeur lance `_init()` sans l attendre : sans cette pause, l etat
/// pose par la connexion serait ecrase par la fin de l initialisation.
Future<AuthNotifier> _notifier(_FauxDepot depot) async {
  final auth = AuthNotifier(depot);
  await Future<void>.delayed(Duration.zero);
  return auth;
}

void main() {
  // Le stockage securise passe par un canal de plateforme, absent en test.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  group('Connexion unifiée', () {
    test('un compte du personnel est reconnu après le refus de Firebase', () async {
      final depot = _FauxDepot(staff: _staff);
      final auth  = await _notifier(depot);

      await auth.signIn('manager@autoparc.bf', 'bon-mot-de-passe');

      expect(depot.firebaseAppele, isTrue, reason: 'Firebase passe en premier.');
      expect(depot.staffAppele, isTrue);
      expect(auth.state.isStaff, isTrue);
      expect(auth.state.staffUser?.role, 'manager');
      expect(auth.state.error, isNull);
    });

    test('deux refus donnent un message unique, sans révéler quel système', () async {
      final depot = _FauxDepot(
        erreurStaff: const ApiException(statusCode: 422, message: 'Identifiants invalides.'),
      );
      final auth = await _notifier(depot);

      await auth.signIn('inconnu@exemple.test', 'x');

      expect(auth.state.isAuthenticated, isFalse);
      expect(auth.state.error, 'Email ou mot de passe incorrect.');
      expect(auth.state.isLoading, isFalse);
    });

    /// Le défaut qu'on vient de corriger : une panne réseau côté Firebase ne
    /// dit rien du compte, et ne doit surtout pas s'afficher comme un mot de
    /// passe faux.
    test('une panne Firebase ne se déguise pas en mot de passe incorrect', () async {
      final depot = _FauxDepot(
        erreurFirebase: FirebaseAuthException(code: 'network-request-failed'),
      );
      final auth = await _notifier(depot);

      await auth.signIn('client@exemple.test', 'x');

      expect(depot.staffAppele, isFalse,
          reason: 'Une panne réseau ne justifie pas d\'essayer l\'autre système.');
      expect(auth.state.error, isNot('Email ou mot de passe incorrect.'));
      expect(auth.state.error, contains('réseau'));
    });

    test('une configuration Firebase absente se dit, elle ne se masque pas', () async {
      final depot = _FauxDepot(
        erreurFirebase: FirebaseAuthException(code: 'operation-not-allowed'),
      );
      final auth = await _notifier(depot);

      await auth.signIn('client@exemple.test', 'x');

      expect(depot.staffAppele, isFalse);
      expect(auth.state.error, isNot('Email ou mot de passe incorrect.'));
    });

    /// Le serveur limite les tentatives : son message dit combien de temps
    /// patienter, et vaut mieux qu'un « identifiants incorrects » qui enverrait
    /// chercher une faute de frappe.
    test('un refus pour excès de tentatives garde le message du serveur', () async {
      final depot = _FauxDepot(
        erreurStaff: const ApiException(
          statusCode: 429,
          message: 'Trop de tentatives de connexion. Patientez une minute.',
        ),
      );
      final auth = await _notifier(depot);

      await auth.signIn('admin@autoparc.bf', 'x');

      expect(auth.state.error, contains('Patientez'));
    });

    test('un échec laisse l\'état déconnecté et le chargement terminé', () async {
      final depot = _FauxDepot(
        erreurStaff: const ApiException(statusCode: 422, message: 'non'),
      );
      final auth = await _notifier(depot);

      await auth.signIn('x@y.z', 'x');

      expect(auth.state.type, AuthType.none);
      expect(auth.state.isLoading, isFalse,
          reason: 'Sinon le bouton reste désactivé et l\'écran paraît figé.');
    });
  });
}
