import 'dart:async';

import 'package:auto/features/partner_accounts/partner_accounts.dart';

/// LE FAUX DÉPÔT PARTENAIRE, partagé par les bancs qui montent un écran avec
/// une session partenaire.
///
/// ── POURQUOI UN FAUX PARTAGÉ, ALORS QUE CHAQUE BANC AVAIT LE SIEN ──────────
///
/// Trois copies privées de `PartnerRepository` vivaient dans les bancs :
/// `_Depot` dans `partner_session_test.dart` (coffre, journal des appels,
/// `getMe` piloté par une fonction, porte de déconnexion), `_Repository`
/// dans `partner_account_page_test.dart` (profil enregistré, inscription,
/// porte sur `getMe`), et `_Tokens`/`_Adapter` dans
/// `partner_repository_test.dart` — ces deux-là RESTENT, ils éprouvent le
/// dépôt lui-même et non ce qui le lit.
///
/// Les deux premières se recopiaient, et c'est le pari que `polices.dart`
/// raconte : quatre copies d'une fonction de banc, dont trois abandonnaient en
/// silence, et une publication pour le payer. Ici la divergence coûterait la
/// même chose, parce que les deux copies ne modélisaient pas le même CONTRAT :
///
///  — le vrai dépôt VIDE LE COFFRE sur un rejet définitif
///    (`partner_repository.dart`, branche `if (error.sessionRejected) await
///    _tokens.clear()`). `_Depot` le faisait ; `_Repository` ne modélisait
///    aucun rejet. Un faux qui ne le ferait pas MENTIRAIT sur le contrat : la
///    reprise au premier plan retrouverait un coffre garni et reconstituerait
///    la notice, alors qu'en production elle la perd. Une mutation a survécu
///    exactement pour cette raison, et c'est la règle que [getMe] honore.
///
///  — le notifier lit le COFFRE avant de vérifier. Un faux qui ne modélise que
///    `getMe()` laisse `sessionStockee()` tomber sur le vrai magasin sécurisé,
///    dont le canal de plateforme n'existe pas en banc. Le commentaire de
///    `_Repository` disait que la page « resterait sur son indicateur de
///    chargement » ; ce n'est plus vrai depuis que `restore()` attrape cette
///    exception. Elle tombe désormais EN SILENCE sur l'état anonyme — ce qui
///    est pire : un banc qui oublierait le coffre resterait vert en montrant
///    l'écran de connexion à la place de l'espace partenaire.
///
/// L'accueil, le tableau de bord et le tiroir montent à leur tour une session
/// partenaire : quatre appelants pour un même faux, et une seule liste
/// d'appels à tenir.
///
/// ── CE QU'IL MODÉLISE, ET CE QU'IL NE MODÉLISE PAS ────────────────────────
///
/// Le coffre, la vérification, la connexion, l'inscription, la déconnexion, la
/// boîte aux lettres, le tableau de bord et les listes — tout ce qu'un écran
/// appelle au MONTAGE. Les médias, les références et la publication restent
/// sur le dépôt réel : le banc de widgets prive toute requête de réseau (elle
/// rend 400), donc un écran qui les appelle sans que le banc le sache LÈVE, il
/// ne passe pas au vert.
///
/// Chaque appel est journalisé dans [appels], dans l'ordre : c'est ce qui
/// permet d'asserter « pas de jeton, pas d'appel » ou « une seule
/// vérification », que l'état seul ne dit pas.
class FauxDepotPartenaire extends PartnerRepository {
  /// Le jeton de toute session posée par [profilAuCoffre], [login] et
  /// [register]. Sa valeur n'importe à aucun écran ; son NOM, si, pour lire
  /// un journal.
  static const jetonDeBanc = 'jeton-de-banc';

  /// Ce que le coffre rend. Nul : aucune session.
  ///
  /// À poser directement pour une session d'AVANT cette version — un jeton
  /// sans profil, `PartnerSessionStockee(token: …)` — ou abîmée. Pour le cas
  /// courant, [profilAuCoffre] suffit.
  PartnerSessionStockee? coffre;

  /// Le profil au coffre, pour les bancs qui ne se soucient pas du jeton.
  ///
  /// Passe par `toJson()`/`fromJson()`, comme le vrai coffre : un profil qui ne
  /// survivrait pas à l'aller-retour tomberait ici plutôt que dans l'écran.
  PartnerProfile? get profilAuCoffre {
    final json = coffre?.profile;

    return json == null ? null : PartnerProfile.fromJson(json);
  }

  set profilAuCoffre(PartnerProfile? profil) {
    coffre = profil == null
        ? null
        : PartnerSessionStockee(token: jetonDeBanc, profile: profil.toJson());
  }

  /// Le journal des appels, dans l'ordre : `coffre`, `getMe`, `login`,
  /// `register`, `logout`, `nonLues`, `notifications`, `dashboard`,
  /// `listings:<type>`.
  final List<String> appels = [];

  /// Ce que `getMe()` fera, quand une fonction est plus parlante qu'un
  /// `Completer` : faire JETER (`() => throw const PartnerApiException(…)`)
  /// ou attendre une porte. Prime sur [porteGetMe].
  Future<PartnerProfile> Function()? reponseGetMe;

  /// Quand elle est posée, `getMe()` attend : la fenêtre du démarrage
  /// optimiste devient observable, et le banc la ferme en la complétant.
  Completer<PartnerProfile>? porteGetMe;

  /// Ce que `login()` rend ou jette. Sans elle, le profil au coffre ; sans
  /// l'un ni l'autre, le refus du serveur — voir [login].
  Future<PartnerProfile> Function()? reponseLogin;

  /// Les identifiants reçus par [login], pour asserter ce qui est PARTI et
  /// non seulement ce que le formulaire a accepté.
  final List<({String identifiant, String motDePasse})> connexions = [];

  /// Les champs reçus par [register], tels que le formulaire les a envoyés :
  /// « absent » et « vide » y arrivent distinctement.
  Map<String, dynamic>? inscription;

  /// Quand elle est posée, `logout()` attend APRÈS avoir vidé le coffre : la
  /// fenêtre de l'appel serveur devient observable.
  Completer<void>? porteDeconnexion;

  /// La pastille de la boîte aux lettres.
  int nonLues = 0;

  /// Pour faire jeter `notificationsNonLues()` — ou rendre autre chose que
  /// [nonLues]. Prime sur lui.
  Future<int> Function()? reponseNonLues;

  /// Les lignes que `notifications()` rend, la plus récente en tête.
  List<Map<String, dynamic>> lignesNotifications = [];

  /// Le tableau de bord rendu par `dashboard()`. Nul : un tableau vide, à
  /// zéro partout — un inventaire vide est un état honnête, pas un mensonge.
  PartnerDashboard? tableauDeBord;

  /// Pour faire jeter `dashboard()` — un serveur antérieur à la route rend
  /// 404 — ou le faire attendre. Prime sur [tableauDeBord].
  Future<PartnerDashboard> Function()? reponseTableauDeBord;

  /// Les annonces que `listListings()` rend, par inventaire. Vides par
  /// défaut, en une seule page.
  Map<PartnerListingKind, List<Map<String, dynamic>>> annonces = {};

  @override
  Future<PartnerSessionStockee?> sessionStockee() async {
    appels.add('coffre');

    return coffre;
  }

  @override
  Future<PartnerProfile> getMe() async {
    appels.add('getMe');

    try {
      final frais = await _reponseGetMe();

      // Le profil frais retourne au coffre, comme dans le vrai dépôt : c'est
      // ce qui complète en une exécution une session d'avant cette version.
      // Un banc qui relit le coffre après la vérification doit y trouver ce
      // que la production y laisse.
      if (coffre case final session?) {
        coffre = PartnerSessionStockee(
          token: session.token,
          profile: frais.toJson(),
        );
      }

      return frais;
    } on PartnerApiException catch (erreur) {
      // LE CONTRAT, voir l'en-tête : un rejet définitif vide le coffre AVANT
      // de relancer, parce que le vrai dépôt le fait.
      if (erreur.sessionRejected) coffre = null;

      rethrow;
    }
  }

  Future<PartnerProfile> _reponseGetMe() {
    if (reponseGetMe case final reponse?) return reponse();
    if (porteGetMe case final porte?) return porte.future;
    if (profilAuCoffre case final profil?) return Future.value(profil);

    // Ni réponse posée, ni profil au coffre : un jeton d'avant cette version
    // sans rien pour le compléter. Le notifier rattraperait une erreur muette
    // en « Impossible de vérifier votre session », et le banc lirait un état
    // qu'il n'a pas voulu. Mieux vaut le dire.
    throw StateError(
      'FauxDepotPartenaire.getMe() : aucune réponse posée (reponseGetMe ou '
      'porteGetMe) et aucun profil au coffre. Un coffre sans profil doit dire '
      'ce que le serveur répondra.',
    );
  }

  @override
  Future<PartnerProfile> login(String identifiant, String password) async {
    appels.add('login');
    connexions.add((identifiant: identifiant, motDePasse: password));

    final profil = reponseLogin != null
        ? await reponseLogin!()
        : profilAuCoffre;

    // Sans réponse posée ni compte au coffre, le serveur ne connaît personne :
    // c'est son refus qui est rendu, et non une erreur de banc, parce que
    // c'est ce que la page affiche en production — et un banc qui attendait
    // une session ouverte tombe sur « Identifiants incorrects », pas sur un
    // écran vert par accident.
    if (profil == null) {
      throw const PartnerApiException(
        'Identifiants incorrects.',
        statusCode: 422,
      );
    }

    // La session part au coffre avec le jeton, comme dans `_authenticate()`.
    profilAuCoffre = profil;

    return profil;
  }

  @override
  Future<PartnerProfile> register(Map<String, dynamic> fields) async {
    appels.add('register');
    inscription = fields;

    // Le profil reflète ce qui a été saisi, en attente : c'est ce que le
    // serveur renvoie, et ce que la page montre ensuite.
    final profil = profilDeBanc(
      status: 'pending',
      company: fields['company_name']?.toString(),
      contact: fields['contact_name']?.toString() ?? 'Awa Exemple',
    );
    profilAuCoffre = profil;

    return profil;
  }

  @override
  Future<void> logout() async {
    appels.add('logout');
    coffre = null;
    if (porteDeconnexion case final porte?) await porte.future;
  }

  @override
  Future<int> notificationsNonLues() async {
    appels.add('nonLues');
    if (reponseNonLues case final reponse?) return reponse();

    return nonLues;
  }

  @override
  Future<List<Map<String, dynamic>>> notifications() async {
    appels.add('notifications');

    return lignesNotifications;
  }

  @override
  Future<PartnerDashboard> dashboard() async {
    appels.add('dashboard');
    if (reponseTableauDeBord case final reponse?) return reponse();

    return tableauDeBord ?? tableauDeBordDeBanc();
  }

  @override
  Future<PartnerListingPage> listListings(
    PartnerListingKind kind, {
    int page = 1,
    String? query,
  }) async {
    appels.add('listings:${kind.name}');
    final items = annonces[kind] ?? const [];

    return PartnerListingPage(
      items: items,
      page: 1,
      lastPage: 1,
      total: items.length,
    );
  }
}

/// Un profil partenaire de banc, avec les clés que le serveur envoie.
///
/// [company] nul pour un revendeur sans raison sociale : le profil privé rend
/// bien `null` — à dessein, pour que le titulaire voie que le champ est vide —
/// et c'est l'affichage qui se replie sur [contact]. [reviewReason] n'a de
/// sens qu'avec un statut `rejected`, et la clé n'est posée que si on le
/// donne : absent et vide ne sont pas la même chose pour `reviewReason`.
PartnerProfile profilDeBanc({
  String status = 'approved',
  String? company = 'Garage Exemple',
  String contact = 'Awa Exemple',
  String? reviewReason,
  Map<String, dynamic> boutique = const {},
}) => PartnerProfile(
  user: {'role': 'partner', 'id': 7, 'name': contact},
  account: {
    'company_name': company,
    'contact_name': contact,
    'status': status,
    'review_reason': ?reviewReason,
  },
  boutique: boutique,
);

/// Un tableau de bord de banc, construit TYPÉ : un `PartnerDashboardCounts`
/// par inventaire et la pastille, sans passer par le JSON.
///
/// Les compteurs se donnent par leur classe et non par une liste d'entiers
/// nommés : `PartnerDashboardCounts` porte huit champs tous à zéro par défaut,
/// et le lot en cours en ajoute encore. Une signature qui les recopierait
/// serait à retoucher à chaque champ — et un banc qui en oublierait un ne le
/// saurait pas.
PartnerDashboard tableauDeBordDeBanc({
  PartnerDashboardCounts vehicules = const PartnerDashboardCounts(),
  PartnerDashboardCounts pieces = const PartnerDashboardCounts(),
  PartnerDashboardCounts accessoires = const PartnerDashboardCounts(),
  int nonLues = 0,
}) => PartnerDashboard(
  counts: {
    PartnerListingKind.vehicles: vehicules,
    PartnerListingKind.parts: pieces,
    PartnerListingKind.accessories: accessoires,
  },
  unreadNotifications: nonLues,
);

/// Un tableau de bord lu depuis un JSON BRUT, par la même fabrique que le
/// dépôt réel.
///
/// C'est l'entrée qui exerce la lecture tolérante de `PartnerDashboard.fromJson`
/// — un compteur manquant vaut zéro, un nombre sérialisé en texte se lit —
/// là où [tableauDeBordDeBanc] la contourne par construction. Un banc qui
/// veut prouver que l'écran survit à un serveur d'une autre version passe par
/// ici, avec la forme que `DashboardController` envoie, abîmée à dessein :
///
///     tableauDeBordDepuisJson({
///       'listings': {
///         'vehicles': {'total': '12.0', 'published': 9},
///         'parts': {},
///       },
///       'unread_notifications': '3',
///     })
///
/// Les clés des compteurs sont celles que `PartnerDashboardCounts.fromJson`
/// lit (`drafts`, `without_photo`, `out_of_stock`, …) : c'est ce fichier-là
/// qui fait foi, pas celui-ci.
PartnerDashboard tableauDeBordDepuisJson(Map<String, dynamic> brut) =>
    PartnerDashboard.fromJson(brut);
