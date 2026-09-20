import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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

  StreamSubscription<User?>? _abonnementFirebase;

  AuthNotifier(this._repo) : super(const AuthState()) {
    // L'écoute d'abord : elle doit être en place avant que `_init` ne rende la
    // main, sinon une session restaurée entre-temps passe inaperçue.
    _ecouterFirebase();
    _init();
  }

  /// Suit l'état d'authentification Firebase pour toute la durée de vie de
  /// l'application, au lieu de le lire une seule fois au démarrage.
  ///
  /// Firebase restaure une session enregistrée de façon asynchrone : au
  /// lancement, `currentUser` reste nul pendant quelques secondes. Une lecture
  /// unique tombait donc régulièrement dans ce trou et affichait « Non
  /// connecté » alors que la session existait.
  ///
  /// Le cas est systématique après une connexion Google : l'onglet Chrome
  /// passe au premier plan, Android tue le processus de l'application, puis le
  /// relance pour recevoir le résultat. La `Future` rendue par
  /// `signInWithProvider` meurt avec l'ancien processus — seul ce flux annonce
  /// la connexion au nouveau.
  void _ecouterFirebase() {
    // Firebase peut être hors service — initialisation échouée sur l'appareil,
    // ou plugin absent sous test. L'application doit rester utilisable en
    // catalogue seul plutôt que de mourir au démarrage.
    final Stream<User?> flux;
    try {
      flux = _repo.firebaseAuthStream;
    } catch (e) {
      debugPrint('[Auth] Flux Firebase indisponible : $e');
      return;
    }

    _abonnementFirebase = flux.listen((utilisateur) {
      if (!mounted) return;
      // Une session du personnel prime : elle vient d'un autre système
      // d'identité et ne doit pas être écrasée par un résidu Firebase.
      if (state.isStaff) return;

      if (utilisateur != null) {
        state = AuthState(type: AuthType.client, firebaseUser: utilisateur);
      } else if (state.isClient) {
        state = const AuthState();
      }
    });
  }

  /// Au démarrage : vérifie si un token Sanctum existe encore (staff),
  /// ou si Firebase a déjà restauré un utilisateur (client).
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
    } catch (_) {
      // Token invalide ou erreur réseau → on efface
      await ApiClient.deleteToken();
    }

    if (!mounted) return;

    // 2. Session Firebase déjà restaurée ? Sinon, `_ecouterFirebase` prendra
    //    le relais dès qu'elle le sera.
    User? fbUser;
    try {
      fbUser = _repo.utilisateurCourant;
    } catch (e) {
      debugPrint('[Auth] Firebase indisponible : $e');
    }

    state = fbUser != null
        ? AuthState(type: AuthType.client, firebaseUser: fbUser)
        : const AuthState();
  }

  @override
  void dispose() {
    _abonnementFirebase?.cancel();
    super.dispose();
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

  // ── Connexion unifiée ──────────────────────────────────────────────
  //
  // Clients et personnel relèvent de deux systèmes d'identité distincts :
  // Firebase pour les uns, un compte serveur pour les autres. L'écran de
  // connexion demandait donc à chacun de se classer lui-même — et un employé
  // qui ne remarquait pas les onglets lisait « aucun compte trouvé », un
  // message qui accuse le compte alors que le problème était l'onglet.
  //
  // On essaie donc les deux, Firebase d'abord : les clients sont la majorité,
  // le cas courant ne coûte qu'un appel.
  //
  // Firebase ne distingue plus « compte inconnu » de « mot de passe faux »
  // (protection contre l'énumération de comptes) : impossible de savoir au vu
  // de l'échec s'il faut tenter l'autre système. On le tente donc toujours.

  /// Codes Firebase qui désignent le compte ou le mot de passe, et eux seuls.
  ///
  /// `invalid-credential` couvre aujourd'hui « compte inconnu » comme « mot de
  /// passe faux » : Firebase les confond volontairement pour empêcher
  /// d'énumérer les comptes.
  static bool _estUnRefusDIdentifiants(String code) => const {
        'invalid-credential',
        'user-not-found',
        'wrong-password',
        'invalid-email',
        'user-disabled',
      }.contains(code);

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await _repo.signInWithEmailAndPassword(email, password);
      state = AuthState(type: AuthType.client, firebaseUser: user);
      return;
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] Firebase a refusé : ${e.code}');

      // Seul un refus d'identifiants autorise à essayer l'autre système. Une
      // panne réseau ou une configuration Firebase absente n'a rien à voir
      // avec le compte : la masquer derrière « mot de passe incorrect »
      // enverrait chercher une faute de frappe pendant des heures.
      if (!_estUnRefusDIdentifiants(e.code)) {
        state = state.copyWith(isLoading: false, error: _extractMessage(e));
        return;
      }
    } catch (e) {
      debugPrint('[Auth] Firebase indisponible : $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Connexion impossible pour le moment. Réessayez.',
      );
      return;
    }

    try {
      final staff = await _repo.loginStaff(email, password);
      state = AuthState(type: AuthType.staff, staffUser: staff);
      return;
    } catch (e) {
      // Un refus pour excès de tentatives se dit tel quel : « identifiants
      // incorrects » enverrait chercher une faute de frappe inexistante.
      final message = (e is ApiException && e.isThrottled)
          ? e.userMessage
          : 'Email ou mot de passe incorrect.';

      state = state.copyWith(isLoading: false, error: message);
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

  /// Supprime définitivement le compte client.
  ///
  /// Rend `null` en cas de succès, le message à afficher sinon. L'état n'est
  /// remis à zéro que si l'effacement a réellement eu lieu : annoncer une
  /// déconnexion après un échec laisserait croire que les données sont parties.
  Future<String?> deleteAccount() async {
    if (!state.isClient) return 'Seuls les comptes clients se suppriment ici.';

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repo.deleteClientAccount();
      state = const AuthState();
      return null;
    } catch (e) {
      final message = messageFor(e);
      state = state.copyWith(isLoading: false, error: message);
      return message;
    }
  }
}

// ── Provider ───────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authRepositoryProvider)),
);
