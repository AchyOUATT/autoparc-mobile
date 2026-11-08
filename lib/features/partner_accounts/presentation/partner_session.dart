import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notice_tableau_de_bord.dart';
import '../data/partner_repository.dart';

/// Le `deniedStatus` d'une session fermée par le serveur SANS statut — le 401
/// nu d'un compte refusé ou suspendu, dont les jetons ont été révoqués. Pas une
/// valeur du serveur : un mot de l'application, pour que l'accueil dise « votre
/// session vendeur a été fermée » et que la reconnexion montre le motif.
const String sessionRevoquee = 'revoked';

class PartnerSession {
  const PartnerSession({this.profile, this.loading = false, this.error, this.deniedStatus, this.reviewReason, this.restoreFailed = false, this.verified = true, this.espaceFerme = false});
  final PartnerProfile? profile;
  final bool loading;
  final String? error;
  final String? deniedStatus;
  final String? reviewReason;
  final bool restoreFailed;

  /// Le serveur a répondu 503 : l'espace partenaire est fermé.
  ///
  /// Distinct de [error], qui porte le message : la page ne doit pas montrer
  /// ce refus-là en ligne rouge sous un formulaire rempli, mais remplacer le
  /// formulaire par un panneau — c'est souvent le tout premier contact d'un
  /// vendeur avec l'application. Et le message du serveur est le SEUL moyen
  /// de le savoir quand `GET /api/app/version` n'a pas encore répondu.
  final bool espaceFerme;

  /// Le serveur a confirmé cette session pendant cette exécution.
  ///
  /// Faux dans un seul cas : le DEMARRAGE OPTIMISTE, où l'espace partenaire
  /// s'ouvre sur le profil enregistré au coffre sans attendre le réseau.
  ///
  /// Le défaut est `vrai` parce qu'un profil qui vient d'une réponse du serveur
  /// est confirmé par construction — connexion, inscription, actualisation.
  /// Seule la restauration dit le contraire, et elle le dit explicitement.
  final bool verified;

  /// Session restaurée du coffre, pas encore confirmée par le serveur.
  bool get sessionAConfirmer => profile != null && !verified;
}

/// Le profil enregistré au coffre, s'il est lisible.
///
/// Nul pour une session d'avant la version qui l'y a mis — elle n'enregistrait
/// que le jeton — ou pour un enregistrement abîmé.
PartnerProfile? profilDepuisLeCoffre(Map<String, dynamic>? json) {
  if (json == null) return null;

  try {
    return PartnerProfile.fromJson(json);
  } catch (_) {
    return null;
  }
}

/// L'état OPTIMISTE que vaut un coffre : la session telle qu'elle était, avant
/// toute vérification.
///
/// Une seule définition, employée par `restore()` et par le démarrage : rien
/// pour un coffre vide ; le profil non confirmé quand il y en a un ; et
/// `loading` seulement quand le coffre porte un jeton SANS profil — session
/// d'avant cette version —, parce qu'il n'y a alors rien à montrer tant que le
/// serveur n'a pas répondu.
PartnerSession sessionInitialeDepuis(PartnerSessionStockee? stockee) {
  if (stockee == null) return const PartnerSession();

  final profil = profilDepuisLeCoffre(stockee.profile);

  return PartnerSession(profile: profil, verified: false, loading: profil == null);
}

/// La session partenaire telle que `main()` la lit AVANT `runApp`.
///
/// ── POURQUOI UNE LECTURE DE PLUS AU DÉMARRAGE ─────────────────────────────
///
/// L'accueil dépend d'elle : un partenaire ouvre sur son tableau de bord, les
/// autres sur l'accueil acheteur. Le notifier lit le coffre dans son
/// constructeur, mais de façon asynchrone — à la première trame il ne sait
/// encore rien, et l'accueil acheteur s'afficherait un instant avant le
/// tableau de bord, à CHAQUE lancement. C'est le même clignotement que la
/// langue a réglé avec `localeInitialeProvider`, et la même réponse.
///
/// ── CE QUE LE DÉLAI PROTÈGE ───────────────────────────────────────────────
///
/// Le coffre chiffré d'Android peut être lent à s'ouvrir, et parfois ne pas
/// répondre. Deux secondes, puis on démarre SANS savoir : l'état rendu est
/// l'état de départ du notifier, qui refera sa lecture et décidera. Un coffre
/// lent ne retarde donc jamais le démarrage de plus de deux secondes, et un
/// coffre cassé ne l'empêche pas.
Future<PartnerSession> sessionPartenaireAuDemarrage(
  PartnerTokenStore coffre, {
  Duration delai = const Duration(seconds: 2),
}) async {
  try {
    return sessionInitialeDepuis(await coffre.readSession().timeout(delai));
  } catch (_) {
    return const PartnerSession(loading: true);
  }
}

/// La session lue par `main()`, injectée par surcharge — comme la langue.
///
/// Le défaut est l'état de départ historique du notifier, « on ne sait pas
/// encore » : les bancs qui ne surchargent rien gardent exactement le
/// comportement qu'ils ont toujours éprouvé.
final sessionPartenaireInitialeProvider =
    Provider<PartnerSession>((_) => const PartnerSession(loading: true));

final partnerSessionProvider = StateNotifierProvider<PartnerSessionNotifier, PartnerSession>((ref) =>
  PartnerSessionNotifier(
    ref.watch(partnerRepositoryProvider),
    initiale: ref.read(sessionPartenaireInitialeProvider),
  ));

class PartnerSessionNotifier extends StateNotifier<PartnerSession> with WidgetsBindingObserver {
  /// [initiale] : ce que `main()` a lu au coffre avant `runApp`, pour que la
  /// première trame soit déjà la bonne. `restore()` relit et vérifie quand
  /// même : la lecture du démarrage n'est qu'une avance, pas une autorité.
  PartnerSessionNotifier(
    this._repository, {
    PartnerSession initiale = const PartnerSession(loading: true),
  }) : super(initiale) {
    _observerLeCycleDeVie();
    restore();
  }
  final PartnerRepository _repository;

  /// Numéro de la vérification en cours.
  ///
  /// Une vérification peut durer une minute. Pendant ce temps le partenaire
  /// peut se déconnecter, se connecter sous un autre compte, ou l'application
  /// revenir au premier plan et en lancer une autre. La réponse PERIMEE arrive
  /// alors après, et écraserait un état plus récent — rouvrant une session
  /// fermée, ou remettant l'ancien compte à la place du nouveau.
  ///
  /// `mounted` ne suffit pas : il ne dit que la mort du notifier, pas qu'un
  /// état plus récent a été posé entre-temps. Et le compteur ne protège que si
  /// TOUTE mutation autoritaire l'incrémente, pas seulement la vérification.
  int _generation = 0;

  void _perimerLesVerifications() => _generation++;

  /// Revérifie la session au retour au premier plan.
  ///
  /// Un téléphone reste des jours sans redémarrer : sans cela, une suspension
  /// de compte décidée pendant la nuit resterait invisible jusqu'au prochain
  /// lancement à froid, qui peut ne jamais venir.
  void _observerLeCycleDeVie() {
    // `WidgetsBinding.instance` lève si la liaison n'est pas initialisée, ce
    // qui arrive dans un banc purement unitaire. Le reste continue de marcher.
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
  }

  /// Le paramètre s'appelle `etat` et non `state` : `state` est déjà le getter
  /// du notifier, et le masquer ici ferait lire l'état du CYCLE DE VIE là où on
  /// veut celui de la SESSION.
  // ignore: avoid_renaming_method_parameters
  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    if (etat != AppLifecycleState.resumed) return;
    if (!mounted || state.profile == null) return;

    // Silencieuse : personne ne l'a demandee, elle ne doit donc pas griser
    // les commandes de la page.
    refresh(silencieux: true);
  }

  @override
  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}

    super.dispose();
  }



  /// Ouvre l'espace partenaire sur le coffre, PUIS vérifie.
  ///
  /// ── CE QUE CELA SUPPRIME ─────────────────────────────────────────────────
  ///
  /// `restore()` attendait `/api/partner/me` avant de publier quoi que ce soit,
  /// et `partner_account_page.dart:63` montre un indicateur bloquant tant que
  /// `loading && profile == null`. Sur une instance Render endormie, le
  /// partenaire regardait donc tourner cet indicateur : 34,8 s mesurées sur
  /// `/up` à froid le 2026-10-15, et jusqu'à 60 s de `receiveTimeout`.
  ///
  /// Il n'y a pas de seconde tentative automatique ici, contrairement au
  /// chemin du personnel, et c'est délibéré : `restoreFailed` allume déjà un
  /// bouton « Réessayer » dans la page. Une tentative que l'utilisateur
  /// déclenche vaut mieux qu'une tentative qu'il ne voit pas.
  Future<void> restore() async {
    final generation = ++_generation;

    PartnerSessionStockee? stockee;
    try {
      stockee = await _repository.sessionStockee();
    } catch (_) {
      stockee = null;
    }

    if (!mounted || generation != _generation) return;

    if (stockee == null) {
      state = const PartnerSession();

      return;
    }

    // Démarrage optimiste : le coffre tel quel, avant la vérification. La
    // définition est partagée avec `main()`, voir `sessionInitialeDepuis`.
    final profil = profilDepuisLeCoffre(stockee.profile);
    state = sessionInitialeDepuis(stockee);

    try {
      final frais = await _repository.getMe();
      if (!mounted || generation != _generation) return;
      state = PartnerSession(profile: frais);
    } on PartnerApiException catch (error) {
      if (!mounted || generation != _generation) return;

      // Un rejet définitif ferme la session — `getMe()` a déjà vidé le coffre.
      // Tout le reste la conserve : une lenteur ou une coupure ne dit rien de
      // la validité de la session, et `restoreFailed` propose de réessayer.
      //
      // ── LE REFUS RÉEL EST UN 401 NU ─────────────────────────────────────
      //
      // Quand le personnel refuse ou suspend un compte, il révoque ses jetons :
      // le prochain `/partner/me` répond 401 « Unauthenticated. », SANS
      // `status` ni motif — ceux-là ne viennent qu'à la reconnexion. Ne poser
      // `deniedStatus` que depuis le corps laissait donc l'accueil muet sur le
      // seul chemin que le serveur produit : l'ancien partenaire retombait en
      // « Visiteur » sans un mot. `revoked` dit « fermée, motif à la
      // reconnexion », et c'est ce que la carte de l'accueil affiche.
      state = error.sessionRejected
          ? PartnerSession(error: error.message,
              deniedStatus: error.accountStatus ?? (profil != null ? sessionRevoquee : null),
              reviewReason: error.reviewReason)
          : PartnerSession(profile: profil, verified: false, error: error.message,
              restoreFailed: true, deniedStatus: error.accountStatus, reviewReason: error.reviewReason,
              espaceFerme: error.statusCode == 503);
    } catch (_) {
      if (!mounted || generation != _generation) return;
      state = PartnerSession(profile: profil, verified: false,
        error: 'Impossible de vérifier votre session. Réessayez.', restoreFailed: true);
    }
  }

  Future<void> _authenticate(Future<PartnerProfile> Function() action) async {
    final generation = ++_generation;
    state = const PartnerSession(loading: true);
    try {
      final profile = await action();
      if (mounted && generation == _generation) state = PartnerSession(profile: profile);
      // Une session qui NAÎT dans cette version n'a jamais connu l'ancien
      // accueil : la ligne « votre accueil est maintenant votre tableau de
      // bord » ne s'adresse qu'aux sessions restaurées d'un coffre antérieur.
      // SANS attendre, et APRÈS la session : des préférences qui ne répondent
      // pas ne doivent pas retenir une connexion réussie — mesuré en banc,
      // où le canal reste muet et bloquait l'inscription.
      NoticeTableauDeBord.marquerVue().ignore();
    } on PartnerApiException catch (error) {
      if (mounted && generation == _generation) state = PartnerSession(error: error.message, deniedStatus: error.accountStatus, reviewReason: error.reviewReason, espaceFerme: error.statusCode == 503);
    } catch (_) {
      if (mounted && generation == _generation) state = const PartnerSession(error: 'La connexion n’a pas abouti. Réessayez.');
    }
  }

  /// [identifiant] : un numéro de téléphone ou une adresse. Voir
  /// `PartnerRepository.login`.
  Future<void> login(String identifiant, String password) =>
      _authenticate(() => _repository.login(identifiant, password));
  Future<void> register(Map<String, dynamic> fields) => _authenticate(() => _repository.register(fields));
  /// Reinterroge le serveur sur la session courante.
  ///
  /// ── `silencieux` : CE QU'IL EVITE ──────────────────────────────────────
  ///
  /// `loading` desactive quatre commandes de la page — la deconnexion et les
  /// deux boutons d'actualisation (`partner_account_page.dart` lignes 59, 158,
  /// 180 et 182). C'est juste pour une actualisation que le partenaire a
  /// DEMANDEE : il attend, et les boutons gris le disent.
  ///
  /// Mais la reprise au premier plan appelle aussi cette methode, et personne
  /// ne l'a demandee. Un partenaire qui revenait a l'application se retrouvait
  /// donc incapable de se deconnecter ou de rafraichir son statut pendant
  /// jusqu'a 60 s, sur un ecran qui ne lui disait pas pourquoi. Et comme
  /// `loading` est global au notifier, cela valait sur n'importe quelle page du
  /// parcours partenaire.
  ///
  /// Une verification de fond ne touche donc pas a `loading`. La puce
  /// « Statut a confirmer… » reste le seul signe visible, et elle suffit.
  Future<void> refresh({bool silencieux = false}) async {
    if (state.profile == null) return restore();

    final generation = ++_generation;
    final previous = state.profile;

    // ── POURQUOI ON RETIENT `verified` ────────────────────────────────────
    //
    // Une lenteur, une coupure ou un 500 ne disent RIEN de la session : le
    // serveur n'a pas repondu, pas desavoue. Les deux branches d'erreur
    // posaient pourtant `verified: false`, ce qui DEFAISAIT une confirmation
    // deja obtenue — la puce passait a « Statut a confirmer… » sur un simple
    // hoquet reseau, et y restait. Le cote personnel ne fait pas cela : son
    // `_verifier()` laisse l'etat intact quand le serveur se tait.
    final confirme = state.verified;

    state = PartnerSession(profile: previous, loading: ! silencieux, verified: confirme);

    try {
      final profile = await _repository.getMe();
      if (mounted && generation == _generation) state = PartnerSession(profile: profile);
    } on PartnerApiException catch (error) {
      if (mounted && generation == _generation) {
        // Même règle qu'à la restauration : un 401 nu sur une session connue
        // est une session fermée, pas un simple visiteur.
        state = PartnerSession(profile: error.sessionRejected ? null : previous,
          verified: error.sessionRejected ? true : confirme,
          error: error.message,
          deniedStatus: error.accountStatus ?? (error.sessionRejected && previous != null ? sessionRevoquee : null),
          reviewReason: error.reviewReason,
          espaceFerme: error.statusCode == 503);
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        state = PartnerSession(profile: previous, verified: confirme,
          error: 'Actualisation impossible. Réessayez.');
      }
    }
  }

  /// Le profil part AVANT l'attente reseau.
  ///
  /// Le garder pendant l'appel laissait la meme porte ouverte que du cote du
  /// personnel : `didChangeAppLifecycleState` exige `state.profile != null`,
  /// donc une reprise au premier plan pendant la deconnexion lancait un
  /// `refresh()` qui reposait la session. L'etat vide l'empeche de naitre, et
  /// le compteur perime ce qui etait deja en vol.
  Future<void> logout() async {
    _perimerLesVerifications();
    state = const PartnerSession(loading: true);

    try { await _repository.logout(); } catch (_) { /* Local token is cleared even offline. */ }

    if (mounted) {
      _perimerLesVerifications();
      state = const PartnerSession();
    }
  }
  void clearNotice() {
    _perimerLesVerifications();
    state = const PartnerSession();
  }
}
