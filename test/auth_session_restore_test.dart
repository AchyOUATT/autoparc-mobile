import 'dart:async';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Restauration de la session client au démarrage.
///
/// Firebase relit sa session enregistrée de façon asynchrone : pendant les
/// premières secondes du lancement, `currentUser` est encore nul. Une lecture
/// unique à l'initialisation tombait dans ce trou et affichait « Non connecté »
/// alors que la session existait — il fallait retoucher « Se connecter » pour
/// que l'application se rende compte qu'on l'était déjà.
///
/// Le cas est systématique après une connexion Google : Android tue le
/// processus pendant que l'onglet Chrome est au premier plan (vu en journal :
/// « Process bf.autoparc.app has died » entre l'ouverture de l'onglet et le
/// retour), puis le relance. La `Future` de `signInWithProvider` est morte avec
/// l'ancien processus ; seul le flux d'état annonce la connexion au nouveau.
class _FauxUtilisateur extends Fake implements User {
  @override
  String get uid => 'Ozb68ZKZ2ON582lgPOyDxFHGKlN2';

  @override
  String? get email => 'kesseni1@yahoo.fr';
}

class _FauxDepot extends AuthRepository {
  _FauxDepot() : super(ApiClient());

  final controleur = StreamController<User?>.broadcast();

  /// Nul au démarrage : Firebase n'a pas encore fini de restaurer la session.
  @override
  User? get utilisateurCourant => null;

  @override
  Stream<User?> get firebaseAuthStream => controleur.stream;
}

Future<AuthNotifier> _notifier(_FauxDepot depot) async {
  final auth = AuthNotifier(depot);
  await Future<void>.delayed(Duration.zero);
  return auth;
}

void main() {
  // Le stockage sécurisé passe par un canal de plateforme, absent en test.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  group('Session Firebase', () {
    test('une session restaurée après le démarrage connecte l\'application', () async {
      final depot = _FauxDepot();
      final auth  = await _notifier(depot);
      addTearDown(depot.controleur.close);

      expect(auth.state.isAuthenticated, isFalse,
          reason: 'Rien à restaurer au moment du lancement.');

      // Firebase termine sa lecture quelques instants plus tard.
      depot.controleur.add(_FauxUtilisateur());
      await Future<void>.delayed(Duration.zero);

      expect(auth.state.isClient, isTrue,
          reason: 'Sans écoute du flux, l\'application reste « non connectée » '
                  'alors que la session existe.');
      expect(auth.state.firebaseUser?.email, 'kesseni1@yahoo.fr');
    });

    test('une déconnexion annoncée par Firebase vide l\'état', () async {
      final depot = _FauxDepot();
      final auth  = await _notifier(depot);
      addTearDown(depot.controleur.close);

      depot.controleur.add(_FauxUtilisateur());
      await Future<void>.delayed(Duration.zero);
      expect(auth.state.isClient, isTrue);

      depot.controleur.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(auth.state.isAuthenticated, isFalse);
    });
  });
}
