import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/widgets.dart';
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

  /// Le serveur a confirmé cette session pendant cette exécution.
  ///
  /// Faux dans un seul cas : le DEMARRAGE OPTIMISTE. L'application s'ouvre sur
  /// ce que le coffre contient, sans attendre le réseau, puis une vérification
  /// en arrière-plan confirme ou ferme la session.
  ///
  /// Le défaut est `vrai` à dessein, et ce n'est pas une facilité : une
  /// cinquantaine de constructions `const AuthState(...)` existent dans les
  /// bancs, et une session fraîchement ouverte VIENT du serveur — elle est
  /// confirmée par construction. Seul le chemin optimiste a de bonnes raisons
  /// de dire le contraire, et il le dit explicitement.
  final bool verified;

  const AuthState({
    this.type      = AuthType.none,
    this.staffUser = null,
    this.firebaseUser = null,
    this.isLoading = false,
    this.error     = null,
    this.verified  = true,
  });

  bool get isAuthenticated => type != AuthType.none;
  bool get isStaff         => type == AuthType.staff;
  bool get isClient        => type == AuthType.client;

  /// Session du personnel restaurée du coffre, pas encore confirmée.
  ///
  /// C'est ce que l'indicateur discret montre. On ne le dit que du personnel :
  /// une session client est tenue par Firebase, qui est son propre juge.
  bool get sessionAConfirmer => isStaff && !verified;

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

  /// Paramètres de contact de la plateforme.
  bool get canManageSettings => _roleIn(const {'admin', 'manager'});

  /// Envoyer une notification a tous les clients.
  bool get canBroadcast      => _roleIn(const {'admin', 'manager'});

  AuthState copyWith({
    AuthType? type,
    StaffUser? staffUser,
    User? firebaseUser,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? verified,
  }) =>
      AuthState(
        type:         type         ?? this.type,
        staffUser:    staffUser    ?? this.staffUser,
        firebaseUser: firebaseUser ?? this.firebaseUser,
        isLoading:    isLoading    ?? this.isLoading,
        error:        clearError ? null : (error ?? this.error),
        verified:     verified     ?? this.verified,
      );
}

// ── Notifier ───────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> with WidgetsBindingObserver {
  final AuthRepository _repo;

  /// Attente avant la SECONDE tentative de vérification.
  ///
  /// Ce qu'elle achète, précisément : le Dio d'`ApiClient` porte déjà 60 s de
  /// `connectTimeout` et de `receiveTimeout`, ce qui couvre largement les
  /// 34,8 s mesurées sur `/up` à froid le 2026-10-15. Une première tentative
  /// qui échoue a donc le plus souvent RÉVEILLÉ l'instance au passage : la
  /// seconde aboutit. Le 11 octobre, l'instance n'a rien rendu en 180 s —
  /// deux tentatives n'y suffisent pas, et c'est assumé : la session reste
  /// alors simplement non confirmée, jeton intact, indicateur affiché.
  ///
  /// Injectable parce qu'un banc ne doit pas attendre cinq secondes.
  final Duration delaiAvantSecondeTentative;

  StreamSubscription<User?>? _abonnementFirebase;

  /// Numéro de la vérification en cours.
  ///
  /// ── CE QU'IL EMPECHE ──────────────────────────────────────────────────
  ///
  /// Une vérification peut durer une minute. Pendant ce temps l'utilisateur
  /// peut se déconnecter, se reconnecter sous un autre compte, ou l'app
  /// revenir au premier plan et en lancer une autre. La réponse de la
  /// vérification PERIMEE arrive alors après, et écrasait un état plus récent
  /// — reconnectant un compte qu'on vient de quitter, ou rouvrant une session
  /// qu'on vient de fermer.
  ///
  /// Chaque vérification prend un numéro en commençant ; elle n'écrit que si
  /// ce numéro est encore le courant. `mounted` ne suffit pas : il ne dit que
  /// la mort du notifier, pas qu'un état plus récent a été posé entre-temps.
  int _generation = 0;

  AuthNotifier(
    this._repo, {
    this.delaiAvantSecondeTentative = const Duration(seconds: 5),
  }) : super(const AuthState()) {
    // L'écoute d'abord : elle doit être en place avant que `_init` ne rende la
    // main, sinon une session restaurée entre-temps passe inaperçue.
    _ecouterFirebase();
    _observerLeCycleDeVie();
    _init();
  }

  /// Revérifie la session au retour au premier plan.
  ///
  /// Un téléphone reste des jours sans être redémarré : sans cela, une session
  /// désactivée pendant la nuit resterait ouverte jusqu'au prochain lancement
  /// à froid, qui peut ne jamais venir.
  void _observerLeCycleDeVie() {
    // `WidgetsBinding.instance` lève si la liaison n'est pas initialisée, ce
    // qui arrive dans un banc purement unitaire. L'absence de reprise au
    // premier plan n'empêche rien d'autre de fonctionner.
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (e) {
      debugPrint('[Auth] cycle de vie non observable : $e');
    }
  }

  /// Le paramètre s'appelle `etat` et non `state`, contrairement à ce que
  /// demande `avoid_renaming_method_parameters` : `state` est déjà le getter
  /// du notifier, et le masquer ici ferait lire l'état du CYCLE DE VIE là où
  /// on veut celui de la SESSION, deux lignes plus bas. La remarque se tait,
  /// le bug n'est pas écrit.
  // ignore: avoid_renaming_method_parameters
  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    if (etat != AppLifecycleState.resumed) return;
    if (!mounted || !state.isStaff) return;

    _verifier();
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
        _perimerLesVerifications();
        state = AuthState(type: AuthType.client, firebaseUser: utilisateur);
      } else if (state.isClient) {
        _perimerLesVerifications();
        state = const AuthState();
      }
    });
  }

  /// Au démarrage : vérifie si un token Sanctum existe encore (staff),
  /// ou si Firebase a déjà restauré un utilisateur (client).
  Future<void> _init() async {
    SessionStockee? session;
    try {
      session = await ApiClient.readSession();
    } catch (e) {
      debugPrint('[Auth] coffre illisible au démarrage : $e');
    }

    if (!mounted) return;

    if (session != null) {
      // ── DEMARRAGE OPTIMISTE ───────────────────────────────────────────
      //
      // On ouvre l'application sur ce que le coffre contient, SANS attendre
      // le réseau. Ce qu'on évite : `getMe()` bloquait le premier écran, et
      // sur une instance Render endormie cela durait 34,8 s (mesure du
      // 2026-10-15) pendant lesquelles l'employé voyait l'écran visiteur.
      //
      // `verified: false` dit que c'est une hypothèse, pas un fait. La
      // vérification qui suit la confirme, ou ferme la session.
      state = AuthState(
        type: AuthType.staff,
        staffUser: _profilDepuis(session.user),
        verified: false,
      );

      // Sans `await`, à dessein : `_init` doit rendre la main tout de suite.
      _verifier();

      return;
    }

    await _restaurerFirebase();
  }

  /// Le profil enregistré au coffre, quand il y en a un de lisible.
  ///
  /// Nul dans deux cas : une session d'avant cette version, qui n'enregistrait
  /// que le jeton, ou un enregistrement abîmé. L'application démarre alors en
  /// personnel SANS nom ni rôle — donc sans tuiles — et la vérification
  /// ramène le profil en quelques secondes puis l'écrit au coffre. C'est
  /// dégradé pendant une exécution, et cela se répare tout seul ; l'autre
  /// choix était de bloquer le premier écran, ce qu'on vient d'arrêter.
  StaffUser? _profilDepuis(Map<String, dynamic>? json) {
    if (json == null) return null;

    try {
      return StaffUser.fromJson(json);
    } catch (e) {
      debugPrint('[Auth] profil du coffre illisible : $e');

      return null;
    }
  }

  /// Périme toute vérification en vol.
  ///
  /// ── POURQUOI CHAQUE MUTATION DOIT L'APPELER ───────────────────────────
  ///
  /// `_generation` ne protège rien si seule la vérification l'incrémente.
  /// Mesure du scénario, avant ce helper : une vérification part (génération
  /// 1), l'utilisateur se déconnecte, la réponse arrive — sa génération est
  /// toujours la courante, elle écrit, et le compte qu'on vient de quitter
  /// est REOUVERT. Même chose en se reconnectant sous un autre compte : la
  /// réponse de l'ancienne session écrasait la nouvelle.
  ///
  /// Toute affectation autoritaire de l'état périme donc ce qui est en vol.
  void _perimerLesVerifications() => _generation++;

  /// Confirme ou ferme, en arrière-plan, la session restaurée du coffre.
  Future<void> _verifier({bool reessayer = true}) async {
    final generation = ++_generation;
    var perimee = false;

    try {
      final profil = await _repo.getMe();
      perimee = !mounted || generation != _generation;
      if (perimee) return;

      // Le profil frais retourne au coffre. C'est ce qui répare, en une
      // exécution, une session d'avant cette version : le démarrage suivant
      // aura de quoi s'ouvrir complet.
      final session = await ApiClient.readSession();
      if (session != null) {
        await ApiClient.saveSession(session.token, profil.toJson());
      }

      if (!mounted || generation != _generation) return;
      state = AuthState(type: AuthType.staff, staffUser: profil);
    } on ApiException catch (e) {
      if (!mounted || generation != _generation) return;

      // ── LE SEUL CAS QUI FERME LA SESSION ────────────────────────────────
      //
      // 401, ou 403 `account_disabled`. Rien d'autre : voir
      // `ApiException.sessionRejected`. Le message du serveur est conservé
      // dans l'état, parce que « votre compte a été désactivé » est la seule
      // chose qui explique à l'employé pourquoi il vient d'être déconnecté.
      if (e.sessionRejected) {
        await ApiClient.deleteSession();
        if (!mounted || generation != _generation) return;
        state = AuthState(error: e.userMessage);

        return;
      }

      // Lenteur, coupure, erreur serveur : le serveur n'a rien dit de la
      // session. On garde le jeton et on retente une fois.
      if (reessayer) {
        await Future<void>.delayed(delaiAvantSecondeTentative);
        if (!mounted || generation != _generation) return;

        return _verifier(reessayer: false);
      }

      debugPrint('[Auth] session non confirmée (${e.statusCode}), jeton conservé');
    } catch (e) {
      if (!mounted || generation != _generation) return;
      debugPrint('[Auth] vérification impossible, jeton conservé : $e');
    }
  }

  /// Session Firebase déjà restaurée ? Sinon `_ecouterFirebase` prendra le
  /// relais dès qu'elle le sera.
  Future<void> _restaurerFirebase() async {
    User? fbUser;
    try {
      fbUser = _repo.utilisateurCourant;
    } catch (e) {
      debugPrint('[Auth] Firebase indisponible : $e');
    }

    if (!mounted) return;

    state = fbUser != null
        ? AuthState(type: AuthType.client, firebaseUser: fbUser)
        : const AuthState();
  }

  @override
  void dispose() {
    _abonnementFirebase?.cancel();

    // Symetrique de `_observerLeCycleDeVie`, et leve pour la meme raison
    // quand la liaison n'existe pas.
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}

    super.dispose();
  }

  /// Extrait un message lisible en français depuis une exception.
  String _extractMessage(Object e) {
    // ── Erreurs Firebase Auth ──────────────────────────────────────
    // ── Échecs du SDK Google ───────────────────────────────────────
    //
    // Ils surviennent AVANT Firebase et ne sont donc pas des
    // `FirebaseAuthException`. Sans cette branche, fermer la fenêtre de choix
    // du compte affichait « Une erreur est survenue », ce qui laisse chercher
    // une panne là où l'utilisateur a simplement changé d'avis.
    if (e is GoogleSignInException) {
      return switch (e.code) {
        // « Interrompue », et non « annulée ».
        //
        // La documentation du SDK présente ce code comme « canceled by the
        // user », et le message disait donc « annulée ». C'était trop
        // affirmatif : une coupure réseau pendant la connexion remonte le
        // même code, et l'utilisateur lisait qu'il avait renoncé alors qu'il
        // n'avait rien fait. Il cherchait son erreur au lieu de regarder sa
        // connexion.
        //
        // On nomme donc le fait observé — la connexion ne s'est pas faite —
        // sans lui en attribuer la cause, et on indique la seule chose
        // vérifiable de son côté.
        GoogleSignInExceptionCode.canceled =>
          'Connexion Google interrompue. Si vous n\'avez pas fermé la fenêtre, '
          'vérifiez votre connexion internet puis réessayez.',
        GoogleSignInExceptionCode.interrupted =>
          'Connexion Google interrompue. Vérifiez votre connexion internet '
          'puis réessayez.',
        // Le cas d'une application mal déclarée côté Google : empreinte de
        // signature absente du projet Firebase, le plus souvent.
        GoogleSignInExceptionCode.clientConfigurationError =>
          'La connexion Google n\'est pas correctement configurée pour cette '
          'version de l\'application.',
        GoogleSignInExceptionCode.providerConfigurationError =>
          'La connexion Google n\'est pas disponible sur cet appareil.',
        GoogleSignInExceptionCode.uiUnavailable =>
          'Impossible d\'afficher la fenêtre de connexion Google.',
        // La description du SDK est jetée partout ailleurs, et c'est voulu :
        // elle est en anglais et ne dit rien d'actionnable à qui ferme une
        // fenêtre. Ici en revanche, le code est inconnu — c'est le seul
        // endroit où elle a une chance d'expliquer quelque chose, et sans
        // elle il ne resterait qu'un nom d'énumération.
        //
        // Cas concret : « aucun compte Google sur l'appareil » arrive sous le
        // code `unknownError` avec la description « No credential available ».
        // Sans la description, l'utilisateur lirait « Connexion Google
        // impossible (unknownError) » et ne saurait pas qu'il lui manque
        // simplement un compte.
        _ => [
            'Connexion Google impossible (${e.code.name}).',
            if (e.description != null && e.description!.isNotEmpty) e.description!,
          ].join(' '),
      };
    }

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
        // Codes du Web. Sur Android, l'ancien flux par onglet Chrome rendait
        // `web-context-canceled`, qui n'était pas traité : fermer l'onglet
        // affichait « Erreur de connexion (web-context-canceled) », donc une
        // hésitation ressemblait à une panne. Ce flux a disparu au profit du
        // SDK natif, mais la version publiée l'emploie encore, et ces deux
        // codes restent valables sur le web.
        //
        // Même prudence qu'avec le SDK natif : on ne dit pas « annulée », une
        // coupure réseau produit le même résultat.
        'popup-closed-by-user' || 'cancelled-popup-request' ||
        'web-context-canceled'
                               => 'Connexion Google interrompue. Si vous n\'avez '
                                  'pas fermé la fenêtre, vérifiez votre connexion '
                                  'internet puis réessayez.',
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
    _perimerLesVerifications();
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final staff = await _repo.loginStaff(email, password);
      state = AuthState(type: AuthType.staff, staffUser: staff);
    } catch (e) {
      final msg = _extractMessage(e);
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  /// ── L'ETAT PART D'ABORD, LE SERVEUR EST PREVENU ENSUITE ────────────────
  ///
  /// L'ordre inverse laissait une porte ouverte, et elle a ete mesuree :
  /// `_repo.logoutStaff()` appelle le serveur, ce qui peut durer jusqu'a 60 s
  /// sur une instance Render endormie. Pendant toute cette attente, l'etat
  /// restait « personnel connecte » — et `didChangeAppLifecycleState` exige
  /// precisement `state.isStaff` pour lancer une verification. Un retour au
  /// premier plan dans cet intervalle reposait donc une session CONFIRMEE
  /// alors que l'utilisateur venait de se deconnecter et lisait son ecran de
  /// visiteur.
  ///
  /// `_perimerLesVerifications()` etait bien appele, mais APRES l'attente :
  /// il perimait ce qui etait en vol avant la deconnexion, et rien de ce qui
  /// partait pendant. C'etait exactement le tort que ce compteur a ete ecrit
  /// pour empecher, par la seule porte qu'il ne gardait pas.
  ///
  /// Vider l'etat en premier les ferme toutes les deux : le compteur perime
  /// l'ancienne verification, et l'etat vide empeche la nouvelle de naitre.
  /// Le coffre, lui, ne risque rien — `_verifier()` ne reecrit la session que
  /// si `readSession()` rend quelque chose, et `logoutStaff()` l'a vide.
  Future<void> logoutStaff() async {
    _perimerLesVerifications();
    state = const AuthState();

    await _repo.logoutStaff();
  }

  // ── Connexion client Firebase ──────────────────────────────────────

  Future<void> signInWithGoogle() async {
    _perimerLesVerifications();
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.signInWithGoogle();
      state = AuthState(type: AuthType.client, firebaseUser: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractMessage(e));
    }
  }

  Future<void> signInClientEmail(String email, String password) async {
    _perimerLesVerifications();
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
    _perimerLesVerifications();
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
    _perimerLesVerifications();
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.registerWithEmailAndPassword(email, password);
      state = AuthState(type: AuthType.client, firebaseUser: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractMessage(e));
    }
  }

  /// Meme ordre, et pour la meme raison, que [logoutStaff].
  Future<void> signOut() async {
    // Lu AVANT de vider : c'est l'etat qui dit quel systeme d'identite
    // prevenir.
    final etaitPersonnel = state.isStaff;
    final etaitClient = state.isClient;

    _perimerLesVerifications();
    state = const AuthState();

    if (etaitPersonnel) await _repo.logoutStaff();
    if (etaitClient) await _repo.signOutClient();
  }

  /// Supprime définitivement le compte client.
  ///
  /// Rend `null` en cas de succès, le message à afficher sinon. L'état n'est
  /// remis à zéro que si l'effacement a réellement eu lieu : annoncer une
  /// déconnexion après un échec laisserait croire que les données sont parties.
  Future<String?> deleteAccount() async {
    if (!state.isClient) return 'Seuls les comptes clients se suppriment ici.';

    _perimerLesVerifications();
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repo.deleteClientAccount();
      _perimerLesVerifications();
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
