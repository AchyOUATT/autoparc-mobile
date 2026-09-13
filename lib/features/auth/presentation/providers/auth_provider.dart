import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../data/auth_repository.dart';

// ── État d'authentification ────────────────────────────────────────

enum AuthType { none, staff, client }

class AuthState {
  final AuthType type;
  final StaffUser? staffUser;
  final User? firebaseUser;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.type      = AuthType.none,
    this.staffUser = null,
    this.firebaseUser = null,
    this.isLoading = false,
    this.error     = null,
  });

  bool get isAuthenticated => type != AuthType.none;
  bool get isStaff         => type == AuthType.staff;
  bool get isClient        => type == AuthType.client;

  String get displayName {
    if (isStaff)  return staffUser?.name  ?? 'Staff';
    if (isClient) return firebaseUser?.displayName ?? firebaseUser?.email ?? 'Client';
    return '';
  }

  // ── Capacites par role ──────────────────────────────────────────────────
  //
  // Reflet de App\Enums\UserRole cote serveur. L'API reste l'autorite : ces
  // getters servent uniquement a masquer les commandes qu'un role ne peut pas
  // utiliser, plutot que de le laisser buter sur un 403. Toute modification de
  // la matrice se fait donc des deux cotes.

  bool _roleIn(Set<String> roles) =>
      isStaff && roles.contains(staffUser?.role);

  /// Creer et modifier une fiche du catalogue.
  bool get canManageCatalog  => _roleIn(const {'admin', 'manager', 'sales'});

  /// Supprimer definitivement une fiche — plus restreint que la modification.
  bool get canDeleteCatalog  => _roleIn(const {'admin', 'manager'});

  /// Declarer et resoudre une panne.
  bool get canManageFaults   => _roleIn(const {'admin', 'manager', 'mechanic'});

  /// Entrees, sorties et disponibilite du stock.
  bool get canManageStock    => _roleIn(const {'admin', 'manager', 'warehouse'});

  /// Annuaire des partenaires et rattachement aux produits.
  bool get canManagePartners => _roleIn(const {'admin', 'manager'});

  /// Envoyer une notification a tous les clients.
  bool get canBroadcast      => _roleIn(const {'admin', 'manager'});

  AuthState copyWith({
    AuthType? type,
    StaffUser? staffUser,
    User? firebaseUser,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AuthState(
        type:         type         ?? this.type,
        staffUser:    staffUser    ?? this.staffUser,
        firebaseUser: firebaseUser ?? this.firebaseUser,
        isLoading:    isLoading    ?? this.isLoading,
        error:        clearError ? null : (error ?? this.error),
      );
}

// ── Notifier ───────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState()) {
    _init();
  }

  /// Au démarrage : vérifie si un token Sanctum existe encore (staff),
  /// ou si Firebase a un utilisateur connecté (client).
  Future<void> _init() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // 1. Token Sanctum présent → valide côté serveur ?
      final token = await ApiClient.readToken();
      if (token != null) {
        final staff = await _repo.getMe();
        state = AuthState(type: AuthType.staff, staffUser: staff);
        return;
      }

      // 2. Utilisateur Firebase connecté ?
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        state = AuthState(type: AuthType.client, firebaseUser: fbUser);
        return;
      }
    } catch (_) {
      // Token invalide ou erreur réseau → on efface
      await ApiClient.deleteToken();
    }

    state = const AuthState();
  }

  /// Extrait un message lisible en français depuis une exception.
  String _extractMessage(Object e) {
    // ── Erreurs Firebase Auth ──────────────────────────────────────
    if (e is FirebaseAuthException) {
      return switch (e.code) {
        'user-not-found'       => 'Aucun compte trouvé pour cet email.',
        'wrong-password'       => 'Mot de passe incorrect.',
        'invalid-credential'   => 'Email ou mot de passe incorrect.',
        'email-already-in-use' => 'Un compte existe déjà avec cet email.',
        'weak-password'        => 'Mot de passe trop faible (6 caractères minimum).',
        'invalid-email'        => 'Adresse email invalide.',
        'user-disabled'        => 'Ce compte a été désactivé. Contactez le support.',
        'too-many-requests'    => 'Trop de tentatives. Réessayez dans quelques minutes.',
        'network-request-failed' => 'Erreur réseau. Vérifiez votre connexion internet.',
        'operation-not-allowed'  => 'Cette méthode de connexion n\'est pas activée.',
        'account-exists-with-different-credential'
                               => 'Ce compte existe déjà avec un autre mode de connexion.',
        'popup-closed-by-user' || 'cancelled-popup-request'
                               => 'Connexion Google annulée.',
        _                      => 'Erreur de connexion (${e.code}).',
      };
    }
    // ── Erreurs API Laravel ────────────────────────────────────────
    if (e is ApiException) {
      // 422 : prendre le premier message du champ "errors" (plus précis que message)
      final errs = e.errors;
      if (errs != null && errs.isNotEmpty) {
        final first = errs.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
      return e.message;
    }
    return messageFor(e);
  }

  // ── Connexion staff ────────────────────────────────────────────────

  Future<void> loginStaff(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final staff = await _repo.loginStaff(email, password);
      state = AuthState(type: AuthType.staff, staffUser: staff);
    } catch (e) {
      final msg = _extractMessage(e);
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> logoutStaff() async {
    await _repo.logoutStaff();
    state = const AuthState();
  }

  // ── Connexion client Firebase ──────────────────────────────────────

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.signInWithGoogle();
      state = AuthState(type: AuthType.client, firebaseUser: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractMessage(e));
    }
  }

  Future<void> signInClientEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.signInWithEmailAndPassword(email, password);
      state = AuthState(type: AuthType.client, firebaseUser: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractMessage(e));
    }
  }

  Future<void> registerClient(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.registerWithEmailAndPassword(email, password);
      state = AuthState(type: AuthType.client, firebaseUser: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractMessage(e));
    }
  }

  Future<void> signOut() async {
    if (state.isStaff) await _repo.logoutStaff();
    if (state.isClient) await _repo.signOutClient();
    state = const AuthState();
  }
}

// ── Provider ───────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authRepositoryProvider)),
);
