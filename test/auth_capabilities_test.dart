import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Miroir de `App\Enums\UserRole` cote serveur.
///
/// L'API reste l'autorite : ces capacites ne servent qu'a masquer les
/// commandes inutilisables. Mais si les deux matrices divergent, l'application
/// propose des boutons qui repondront 403 — d'ou ce test, jumeau de
/// `UserRoleCapabilitiesTest` cote backend.
AuthState _staff(String role) => AuthState(
  type: AuthType.staff,
  staffUser: StaffUser(
    id: 1,
    name: 'Test',
    email: 'test@autoparc.bf',
    role: role,
  ),
);

void main() {
  const roles = ['admin', 'manager', 'sales', 'mechanic', 'warehouse', 'viewer'];

  // Capacite → roles qui la possedent.
  const matrix = <String, Set<String>>{
    'canManageCatalog':  {'admin', 'manager', 'sales'},
    'canDeleteCatalog':  {'admin', 'manager'},
    'canManageFaults':   {'admin', 'manager', 'mechanic'},
    'canManageStock':    {'admin', 'manager', 'warehouse'},
    'canManagePartners': {'admin', 'manager'},
    'canBroadcast':      {'admin', 'manager'},
  };

  bool read(AuthState s, String capability) => switch (capability) {
    'canManageCatalog'  => s.canManageCatalog,
    'canDeleteCatalog'  => s.canDeleteCatalog,
    'canManageFaults'   => s.canManageFaults,
    'canManageStock'    => s.canManageStock,
    'canManagePartners' => s.canManagePartners,
    'canBroadcast'      => s.canBroadcast,
    _ => throw ArgumentError('Capacité inconnue : $capability'),
  };

  group('Capacités du personnel', () {
    for (final entry in matrix.entries) {
      test('${entry.key} n\'est accordée qu\'aux rôles prévus', () {
        for (final role in roles) {
          expect(
            read(_staff(role), entry.key),
            entry.value.contains(role),
            reason: '$role / ${entry.key}',
          );
        }
      });
    }

    test('un client ne possède aucune capacité back-office', () {
      const client = AuthState(type: AuthType.client);
      for (final capability in matrix.keys) {
        expect(read(client, capability), isFalse, reason: capability);
      }
    });

    test('un visiteur non connecté non plus', () {
      const anonymous = AuthState();
      for (final capability in matrix.keys) {
        expect(read(anonymous, capability), isFalse, reason: capability);
      }
    });

    /// Un role inconnu (ajoute cote serveur, pas encore ici) ne doit rien
    /// ouvrir : mieux vaut un bouton manquant qu'un bouton qui echoue.
    test('un rôle inconnu n\'ouvre rien', () {
      final unknown = _staff('comptable');
      for (final capability in matrix.keys) {
        expect(read(unknown, capability), isFalse, reason: capability);
      }
    });
  });
}
