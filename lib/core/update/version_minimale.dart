import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../api/endpoints.dart';

/// Le plancher de version servi par l'API, et le verdict qu'on en tire.
///
/// Le propriétaire veut qu'une version publiée rende obsolètes les
/// précédentes. Les correctifs partent par vagues et certains dépendent du
/// serveur : une ancienne version qui continue d'appeler l'API affiche des
/// écrans faux — des décimaux sérialisés en chaînes, des champs disparus —
/// sans que personne le sache.
///
/// Le mécanisme est un plancher servi par l'API, et non le flux de mise à
/// jour natif de Play. Trois raisons : il se déclenche par une variable
/// d'environnement du serveur sans republier l'application, il ne dépend pas
/// du délai de propagation de Play, et il est vérifiable en test — ce que
/// l'API native de Play n'est pas, n'existant pas hors d'un appareil.
///
/// ─────────────────────────────────────────────────────────────────────────
/// LA RÈGLE QUI PRIME SUR TOUTES LES AUTRES : on ne bloque JAMAIS sur une
/// erreur. Réseau coupé, API en panne, réponse illisible, délai dépassé,
/// champ absent : on laisse passer. Bloquer tout le parc parce que le serveur
/// tousse serait un défaut bien pire que celui qu'on corrige — et ce serveur
/// s'endort au bout de trente secondes d'inactivité sur son offre gratuite,
/// donc le premier appel du matin met couramment vingt-cinq secondes. On ne
/// bloque que sur une réponse claire et exploitable.
/// ─────────────────────────────────────────────────────────────────────────

/// La réponse de `GET /api/app/version`, lue sans rien exiger.
///
/// Chaque champ peut manquer ou arriver en chaîne de caractères. Ce n'est pas
/// de la prudence gratuite : Laravel sérialise volontiers les nombres en
/// texte, et c'est exactement ce qui avait fait tomber le catalogue entier —
/// « 2450000.00 » lu comme un `num?` donnait
/// `type 'String' is not a subtype of type 'num?'`. Le helper `_double()` de
/// `features/garage/data/models/owned_vehicle.dart` existe pour cette
/// raison ; `_entier()` ci-dessous en est le pendant.
class PlancherDeVersion {
  /// En dessous de ce versionCode, l'application est périmée.
  final int? minVersionCode;

  /// La dernière version publiée. Lue, mais elle ne décide de rien : seul le
  /// plancher bloque. Elle est là parce que le contrat la sert, et qu'un
  /// bandeau « une version plus récente existe » pourra s'y brancher sans
  /// retoucher au modèle.
  final int? latestVersionCode;

  final String? storeUrl;
  final String? message;

  /// L'espace partenaire est-il ouvert ? FERMÉ par défaut.
  ///
  /// C'est le seul interrupteur distant de cette application : il n'existe ni
  /// configuration distante, ni constante de compilation. Il voyage sur la
  /// réponse de version parce que c'est la seule que l'application lise avant
  /// d'afficher quoi que ce soit, et qu'elle est déjà gratuite — pas de base,
  /// pas de jeton.
  ///
  /// LE DÉFAUT EST FERMÉ, ET C'EST VOULU. Un serveur plus ancien, qui ne
  /// connaît pas ce champ, laisse l'espace masqué ; et une réponse perdue —
  /// réseau coupé, réveil d'instance au-delà des cinq secondes — fait de même.
  /// Dans le doute on n'affiche pas une entrée qui mènerait à une erreur.
  ///
  /// Ce drapeau ne fait que RENSEIGNER l'affichage. Ce qui ferme réellement
  /// l'espace est le serveur, qui rend 503 sur tout le groupe de routes
  /// partenaire : un binaire qui ignorerait ce champ se heurterait quand même
  /// au refus.
  final bool espacePartenaireOuvert;

  const PlancherDeVersion({
    this.minVersionCode,
    this.latestVersionCode,
    this.storeUrl,
    this.message,
    this.espacePartenaireOuvert = false,
  });

  factory PlancherDeVersion.fromJson(Map<String, dynamic> json) =>
      PlancherDeVersion(
        minVersionCode: _entier(json['min_version_code']),
        latestVersionCode: _entier(json['latest_version_code']),
        storeUrl: _texte(json['store_url']),
        message: _texte(json['message']),
        espacePartenaireOuvert: _booleen(json['partner_space_open']),
      );
}

/// Lit un entier quelle que soit la forme reçue : 70, « 70 », « 70.0 ».
///
/// `int.tryParse` refuse « 70.0 », que PHP produit dès qu'une valeur a croisé
/// un cast flottant quelque part dans la chaîne. On retombe donc sur
/// `double.tryParse` plutôt que de rendre null : rendre null ici reviendrait
/// à ne jamais bloquer, et le plancher ne servirait plus à rien.
int? _entier(Object? valeur) {
  if (valeur is int) return valeur;
  if (valeur is num) return valeur.toInt();

  final texte = valeur?.toString().trim();
  if (texte == null || texte.isEmpty) return null;

  return int.tryParse(texte) ?? double.tryParse(texte)?.toInt();
}

/// Lit un booléen quelle que soit la forme reçue, et retombe sur FAUX.
///
/// Même motif que `_entier()` : PHP sérialise volontiers un booléen en `1`, en
/// `"1"` ou en `"true"`. Mais le repli n'est pas le même, et c'est le point
/// important — `_entier()` rend null pour ne pas bloquer à tort, tandis
/// qu'ici tout ce qui n'est pas franchement vrai vaut FERMÉ.
///
/// Ce sens-là n'est pas symétrique par hasard : un `true` manqué masque une
/// entrée de menu, ce qui se corrige en rouvrant l'application ; un `false`
/// manqué afficherait une entrée qui mène à un refus du serveur. Et la chaîne
/// `"false"` est précisément le piège qu'un `valeur == true` laxiste laisserait
/// passer du côté vrai.
bool _booleen(Object? valeur) {
  if (valeur is bool) return valeur;
  if (valeur is num) return valeur != 0;

  final texte = valeur?.toString().trim().toLowerCase();

  return texte == 'true' || texte == '1' || texte == 'yes' || texte == 'on';
}

/// Une chaîne vide vaut une chaîne absente : le serveur sert `""` quand la
/// variable d'environnement existe sans avoir été renseignée, et un écran
/// bloquant au message vide serait pire qu'un message par défaut.
String? _texte(Object? valeur) {
  if (valeur == null) return null;
  final texte = valeur.toString().trim();
  return texte.isEmpty ? null : texte;
}

/// Ce que le contrôle a décidé. Deux cas, et deux seulement.
class VerdictMiseAJour {
  final bool exigee;
  final String message;
  final String? urlStore;

  /// Le cas de loin le plus fréquent — et celui de toutes les défaillances.
  const VerdictMiseAJour.rienAFaire()
      : exigee = false,
        message = '',
        urlStore = null;

  const VerdictMiseAJour.exigee({required this.message, this.urlStore})
      : exigee = true;
}

/// Le message affiché quand le serveur n'en fournit aucun.
///
/// Il dit quoi faire, pas ce qui s'est passé : « version obsolète » n'apprend
/// rien à quelqu'un qui doit seulement toucher un bouton.
const String messageMiseAJourParDefaut =
    "Cette version de l'application n'est plus prise en charge. "
    'Installez la dernière version pour continuer.';

/// Interroge le plancher de version et rend un verdict.
///
/// Les deux dépendances sont injectables parce que ni l'une ni l'autre
/// n'existe sous un banc d'essai : `PackageInfo.fromPlatform()` passe par un
/// canal de plateforme, et la route par le réseau. Les cinq cas de
/// défaillance — réseau coupé, HTTP 500, JSON illisible, champ absent,
/// versionCode local illisible — comptent plus que les autres, et c'est
/// seulement ainsi qu'ils deviennent vérifiables.
class ServiceVersionMinimale {
  ServiceVersionMinimale({
    Dio? client,
    Future<int?> Function()? lireVersionInstallee,
  })  : _client = client ?? _clientParDefaut(),
        _lireVersionInstallee =
            lireVersionInstallee ?? _versionInstalleeDeLaPlateforme;

  final Dio _client;
  final Future<int?> Function() _lireVersionInstallee;

  /// Cinq secondes, là où le reste de l'API en attend soixante.
  ///
  /// Les soixante secondes d'`ApiClient` sont justifiées : le service Render
  /// dort sur son offre gratuite et son réveil a été mesuré à 34,8 s sur
  /// `/up` le 2026-10-15. Mais ce délai-là sert des écrans que l'utilisateur
  /// a demandés et attend. Ici personne n'a rien demandé : c'est un contrôle
  /// au démarrage. Lui accorder soixante secondes ne changerait pas le
  /// verdict — un serveur endormi finit par servir le même plancher —, cela
  /// garderait seulement une requête ouverte tout ce temps au moment précis
  /// où l'application démarre. Au-delà de cinq secondes on laisse passer, et
  /// le prochain démarrage retentera.
  static const Duration delai = Duration(seconds: 5);

  /// Le délai de la SECONDE tentative, celle qui attend un serveur endormi.
  ///
  /// ── CE QUE LES CINQ SECONDES COÛTAIENT ──────────────────────────────────
  ///
  /// Le raisonnement ci-dessus est juste sur un point et faux sur l'autre.
  /// Juste : garder une requête ouverte soixante secondes au démarrage ne se
  /// fait pas. Faux : « le prochain démarrage retentera » suppose qu'un
  /// prochain démarrage trouve l'instance éveillée, et rien ne le garantit.
  ///
  /// Mesure du 25/10/2026, après la publication de la version 87 : l'instance
  /// répond en 0,9 s quand elle est chaude, et en 25 à 35 s quand elle dort —
  /// `/up` a mis 25,7 s le même jour. Un téléphone qui ouvre l'application la
  /// première fois de la journée perdait donc la course, et n'apprenait PAS
  /// qu'il était périmé. Or c'est exactement la population qui n'a pas mis à
  /// jour : celle qu'on cherche à prévenir.
  ///
  /// ── CE QUI EST FAIT À LA PLACE ──────────────────────────────────────────
  ///
  /// Deux tentatives, et non un délai allongé. La première garde ses cinq
  /// secondes et ne retarde rien. Si elle n'a REÇU AUCUNE RÉPONSE — et
  /// seulement dans ce cas — une seconde partie en arrière-plan avec ce
  /// budget-ci, et l'écran s'affiche quand la réponse arrive.
  ///
  /// Une réponse obtenue n'est jamais réessayée, même si elle dit « à jour » :
  /// c'est une vraie réponse, et la redemander ne servirait qu'à payer deux
  /// fois le réveil.
  static const Duration delaiPatient = Duration(seconds: 70);

  static Dio _clientParDefaut() => Dio(BaseOptions(
        baseUrl: Endpoints.baseUrl,
        connectTimeout: delai,
        receiveTimeout: delai,
        headers: {
          'Accept': 'application/json',
          if (Endpoints.baseUrl.contains('ngrok'))
            'ngrok-skip-browser-warning': 'true',
        },
      ));

  /// Le client à utiliser pour un budget donné.
  ///
  /// `connectTimeout` ne vit que sur les `BaseOptions` : Dio ne le laisse PAS
  /// surcharger par requête, contrairement à `receiveTimeout` et
  /// `sendTimeout`. Une tentative patiente qui ne surchargerait que ces deux-là
  /// se ferait donc trancher à cinq secondes à la connexion, sans que rien ne
  /// le dise — et le correctif aurait l'air de fonctionner tout en ne changeant
  /// rien.
  ///
  /// On pourrait arguer que Render accepte la connexion tout de suite et ne
  /// fait attendre que la réponse, auquel cas `receiveTimeout` suffirait. C'est
  /// probable, et ce n'est pas mesuré : on ne parie pas là-dessus. Le client
  /// est donc cloné avec les trois délais relevés.
  ///
  /// L'ADAPTATEUR EST REPRIS, et c'est ce qui garde les bancs valides : ils
  /// injectent un Dio dont l'adaptateur rend une réponse fixée sans réseau. Un
  /// `Dio()` neuf perdrait cette mise en scène et la seconde tentative partirait
  /// pour de vrai.
  Dio _clientPour(Duration attente) {
    if (attente == delai) return _client;

    return Dio(_client.options.copyWith(
      connectTimeout: attente,
      receiveTimeout: attente,
      sendTimeout: attente,
    ))
      ..httpClientAdapter = _client.httpClientAdapter;
  }

  /// Le versionCode réellement installé, lu dans le PackageManager.
  ///
  /// `buildNumber` arrive en chaîne et peut être vide : sur une plateforme
  /// sans notion de versionCode, ou sur un build où personne n'a passé
  /// `--build-number`. Illisible vaut « rien à faire ».
  static Future<int?> _versionInstalleeDeLaPlateforme() async {
    final infos = await PackageInfo.fromPlatform();
    return _entier(infos.buildNumber);
  }

  /// Lit la réponse de version. Rend null sur n'importe quelle défaillance.
  ///
  /// ── POURQUOI CETTE LECTURE EST SÉPARÉE DU VERDICT ──────────────────────
  ///
  /// La réponse porte désormais deux choses sans rapport l'une avec l'autre :
  /// le plancher de version, et l'interrupteur de l'espace partenaire. Deux
  /// lecteurs, donc, et un seul appel réseau au démarrage — c'est celui qui
  /// réveille l'instance endormie du plan gratuit, et le dédoubler le ferait
  /// payer deux fois. D'où `lire()` d'un côté, `juger()` de l'autre, et un
  /// provider qui partage le `Future`.
  /// [budget] : le temps accordé à CETTE lecture. `delai` par défaut, pour la
  /// tentative du démarrage ; `delaiPatient` pour celle qui attend un serveur
  /// endormi. Il porte aussi sur la CONNEXION et pas seulement sur la
  /// réception — une instance endormie met plus de cinq secondes à accepter la
  /// connexion, et un `receiveTimeout` seul laisserait `connectTimeout`
  /// trancher à cinq secondes sans qu'on le voie.
  Future<PlancherDeVersion?> lire({Duration? budget}) async {
    final attente = budget ?? delai;

    try {
      final reponse = await _clientPour(attente).get<dynamic>(
        Endpoints.appVersion,
        options: Options(
          receiveTimeout: attente,
          sendTimeout: attente,
          // On lit le code nous-mêmes plutôt que de laisser Dio lever sur un
          // 4xx/5xx. La branche explicite ci-dessous se lit et se teste ; par
          // le chemin des exceptions, un 500 du serveur se confondrait avec
          // un réseau coupé, et les deux cas cesseraient d'être distinguables
          // dans la trace.
          validateStatus: (_) => true,
        ),
      );

      if (reponse.statusCode != 200) return null;

      final corps = reponse.data;
      if (corps is! Map) return null;

      return PlancherDeVersion.fromJson(Map<String, dynamic>.from(corps));
    } catch (e) {
      // Exception réseau, délai dépassé, JSON illisible. La trace dit pourquoi
      // la lecture n'a rien donné — sans elle, un plancher qui ne se déclenche
      // pas est indiscernable d'un plancher jamais configuré.
      debugPrint('[MiseAJour] lecture du plancher abandonnée : $e');
      return null;
    }
  }

  /// Compare la version installée au plancher reçu.
  Future<VerdictMiseAJour> juger(PlancherDeVersion? plancher) async {
    const rienAFaire = VerdictMiseAJour.rienAFaire();

    try {
      if (plancher == null) return rienAFaire;

      final installee = await _lireVersionInstallee();
      if (installee == null) return rienAFaire;

      final minimum = plancher.minVersionCode;
      if (minimum == null) return rienAFaire;

      // L'égalité ne bloque pas : `installee == minimum`, c'est la version
      // plancher elle-même — celle qu'on demanderait justement d'installer.
      if (installee >= minimum) return rienAFaire;

      return VerdictMiseAJour.exigee(
        message: plancher.message ?? messageMiseAJourParDefaut,
        urlStore: plancher.storeUrl,
      );
    } catch (e) {
      // Le canal de plateforme peut manquer sous un banc ou sur une plateforme
      // sans notion de versionCode.
      debugPrint('[MiseAJour] contrôle de version abandonné : $e');
      return rienAFaire;
    }
  }

  Future<VerdictMiseAJour> verifier() async => juger(await lire());
}

final serviceVersionMinimaleProvider =
    Provider<ServiceVersionMinimale>((ref) => ServiceVersionMinimale());

/// Le verdict, calculé une fois au démarrage.
///
/// Un `FutureProvider` et non un `AsyncNotifier` : le contrôle n'expose
/// aucune commande — ni rechargement, ni écriture — et son résultat ne change
/// pas tant que l'application tourne. Pas d'`autoDispose` non plus : on ne
/// veut surtout pas qu'il soit relancé parce que son seul lecteur a cessé un
/// instant de l'écouter.
/// La réponse de version, lue UNE FOIS et partagée.
///
/// Deux lecteurs en dépendent — le verdict de mise à jour et l'entrée de
/// l'espace partenaire — et c'est tout l'intérêt de la faire passer par un
/// provider : l'appel réseau du démarrage, celui qui réveille l'instance,
/// n'a lieu qu'une fois.
final plancherDeVersionProvider = FutureProvider<PlancherDeVersion?>(
  (ref) => ref.watch(serviceVersionMinimaleProvider).lire(),
);

/// Le verdict, qui peut arriver EN DEUX TEMPS.
///
/// ── POURQUOI CE N'EST PLUS UN `FutureProvider` ──────────────────────────────
///
/// Il l'était, et le commentaire d'alors disait vrai : « son résultat ne change
/// pas tant que l'application tourne ». C'est précisément cette prémisse qui
/// était fausse, et elle a coûté une version entière.
///
/// Mesure du 25/10/2026, après la publication de la 87 : la première tentative
/// s'accorde cinq secondes, l'instance endormie en met 25 à 35. Un téléphone
/// qui ouvrait l'application la première fois de la journée n'apprenait donc
/// PAS qu'il était périmé — et ne réessayait qu'au lancement suivant, qui
/// pouvait très bien retomber sur une instance froide. La population visée par
/// le plancher est exactement celle qui ne le voyait jamais.
///
/// Un flux, donc, qui rend d'abord le verdict rapide — rien ne retarde le
/// démarrage — puis, SI ET SEULEMENT SI aucune réponse n'est arrivée, celui de
/// la seconde tentative. L'écran bloquant s'affiche alors de lui-même :
/// `main.dart` lit ce provider par `.asData?.value`, qui suit un flux comme
/// il suivait un futur.
///
/// Ce qu'on ne réessaie PAS : une réponse obtenue, même quand elle dit « à
/// jour ». C'est une vraie réponse, et la redemander ne ferait que payer deux
/// fois le réveil de l'instance. Ni un verdict déjà bloquant, puisqu'il n'y a
/// plus rien à apprendre.
final verdictMiseAJourProvider = StreamProvider<VerdictMiseAJour>((ref) async* {
  final service = ref.watch(serviceVersionMinimaleProvider);

  final plancher = await ref.watch(plancherDeVersionProvider.future);
  yield await service.juger(plancher);

  // Une réponse est arrivée : le verdict ci-dessus est définitif.
  if (plancher != null) return;

  // Aucune réponse en cinq secondes — l'instance dormait. On redemande avec le
  // budget qu'il faut, en arrière-plan, sans que l'utilisateur attende.
  yield await service.juger(
    await service.lire(budget: ServiceVersionMinimale.delaiPatient),
  );
});

/// L'espace partenaire est-il ouvert ? FERMÉ tant qu'on n'en sait rien.
///
/// Ni `AsyncValue` ni `null` en sortie : l'appelant est une condition
/// d'affichage dans un tiroir, qui doit répondre à chaque reconstruction sans
/// attendre. Pendant la lecture, en cas d'échec, et face à un serveur qui
/// ignore le champ, la réponse est la même — faux, donc pas d'entrée.
final espacePartenaireOuvertProvider = Provider<bool>(
  (ref) => ref.watch(plancherDeVersionProvider).maybeWhen(
        data: (plancher) => plancher?.espacePartenaireOuvert ?? false,
        orElse: () => false,
      ),
);
