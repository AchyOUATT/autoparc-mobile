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

  /// Extrait le message lisible depuis une exception (ApiException ou autre).
  String _extractMessage(Object e) {
    if (e is ApiException) {
      // 422 : prendre le premier message du champ "errors" (plus précis que message)
      final errs = e.errors;
      if (errs != null && errs.isNotEmpty) {
        final first = errs.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
      return e.message;
    }
    return e.toString();
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
