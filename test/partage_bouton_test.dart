import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto/core/utils/contact_info.dart';
import 'package:auto/core/utils/currency_format.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/catalog_repository.dart';
import 'package:auto/features/catalog/data/models/accessory.dart';
import 'package:auto/features/catalog/data/models/part.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/pages/accessory_detail_page.dart';
import 'package:auto/features/catalog/presentation/pages/part_detail_page.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_detail_page.dart';
import 'package:auto/l10n/app_localizations.dart';

import 'support/langues.dart';

/// Le bouton « Partager » sur les trois fiches : quand il est là, quand il
/// n'y est pas, et ce qu'il envoie.
///
/// Deux conditions, qu'il ne faut pas confondre. Le partage ne dépend d'AUCUNE
/// CAPACITÉ — c'est un client, voire un visiteur, qui partage — mais il dépend
/// de l'EXISTENCE DE LA PAGE : le message porte désormais l'adresse de
/// l'article, et un article sans page publique fabrique un lien qui rend 404.
/// Voir le groupe « le bouton est absent… », qui est la régression à empêcher.
///
/// Le point qui compte vraiment est le second : le partage n'est pas une
/// action de gestion. Les trois barres de titre concernées portent déjà des
/// commandes réservées au personnel — photos, modification, suppression — et
/// la fiche d'un véhicule n'en portait **aucune** pour qui n'est pas connecté.
/// Glisser le partage derrière une capacité, par mimétisme avec ses voisines,
/// l'aurait rendu invisible à presque tous ceux qui s'en servent : c'est un
/// client qui envoie une fiche à un proche, pas un vendeur.
///
/// Contrairement à `partage_test.dart`, ce fichier touche la plateforme : il
/// pose un faux gestionnaire sur le canal de `share_plus` et lit ce que
/// l'application lui a réellement passé. C'est le seul moyen de vérifier le
/// message tel qu'il part de la fiche, et non tel qu'on aurait aimé qu'il
/// soit composé.
///
/// ── LE MESSAGE EST COURT, ET C'EST ICI QUE ÇA SE GARDE ─────────────────────
///
/// Il tient en deux lignes :
///
///     *Hyundai Tucson (2023)* — sur AutoParc
///     https://<racine>/v/305
///
/// Il en portait six. Le propriétaire a signalé que « le partage duplique les
/// informations de l'article » : depuis que le lien mène à la page publique et
/// non plus au magasin d'applications, WhatsApp lit les balises Open Graph de
/// cette page et affiche sous le message une vignette qui dit DÉJÀ le nom, le
/// prix et les caractéristiques. Le prix et les précisions arrivaient donc deux
/// fois dans la même bulle.
///
/// **C'est le seul fichier où cette duplication se mesure pour de vrai**, et
/// c'est ce qui rend ses assertions d'absence indispensables : les valeurs
/// interdites ne sont pas choisies par le test, elles sont lues sur les modèles
/// que les fiches affichent. Si quelqu'un trouve le message trop maigre et
/// rebranche le prix, le groupe « le message ne redit ni le prix ni les
/// caractéristiques » tombe. Sans lui, la duplication revient EN SILENCE :
/// aucun écran de l'application ne la montre, elle ne se voit que dans la
/// conversation du destinataire.
///
/// C'est aussi le seul endroit où l'absence de pièce jointe se vérifie. Sur
/// WhatsApp, une image jointe produit un message IMAGE dont le texte devient
/// la légende, et les aperçus de lien ne se rendent pas dans une légende :
/// rejoindre une photo ferait silencieusement disparaître toutes les
/// vignettes, sans qu'aucun autre test ne s'en aperçoive. La carte d'arguments
/// du canal ne porte `paths` et `mimeTypes` que lorsque `ShareParams.files`
/// est renseigné — leur absence est donc la mesure exacte.
void main() {
  /// Les trois infobulles de la barre de titre d'une fiche, LUES dans les
  /// `.arb`.
  ///
  /// Elles y étaient en dur, treize fois dans ce seul fichier, et la
  /// vague 2 les a traduites. Le groupe « la mention du message suit la langue
  /// de l'application » est tombé sur sa colonne ANGLAISE, avec la bonne raison
  /// : « Found 0 widgets », parce qu'une fiche anglaise affiche « Share ». Les
  /// lire ici les fait suivre le fichier de traduction.
  ///
  /// Les CHAÎNES ATTENDUES du message partagé, elles, restent écrites en clair
  /// dans leur groupe : c'est le contrat des deux `.arb`, et une assertion qui
  /// relirait la clé resterait verte le jour où l'anglais rendrait du français.
  /// La distinction est la même qu'entre chercher un widget et vérifier un
  /// texte.
  final bulleSuivante =
      <String, ({String partager, String modifier, String supprimer})>{};

  setUpAll(() async {
    for (final langue in langues.entries) {
      final t = await chargerTextes(langue.value);
      bulleSuivante[langue.key] = (
        partager: t.catalogShareTooltip,
        modifier: t.catalogEditTooltip,
        supprimer: t.catalogDeleteAction,
      );
    }
  });

  /// L'infobulle « Partager » en FRANÇAIS, pour les tests qui ne montent qu'une
  /// seule langue — la coque de ce fichier pose `localeFr` par défaut.
  String partagerFr() => bulleSuivante['fr']!.partager;

  // Le nom du canal est écrit en clair plutôt qu'importé de
  // `MethodChannelShare.channel` : `share_plus_platform_interface` est une
  // dépendance transitive, et l'importer ici déclencherait
  // `depend_on_referenced_packages`. En contrepartie, si share_plus renommait
  // son canal, ces tests tomberaient — ce qui est le bon sens de l'échec.
  const canalPartage = MethodChannel('dev.fluttercommunity.plus/share');

  /// Ce que l'application a passé à la feuille de partage, appel par appel.
  final envois = <Map<Object?, Object?>>[];

  setUp(() {
    envois.clear();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canalPartage, (appel) async {
          envois.add(appel.arguments as Map<Object?, Object?>);
          // La valeur que renvoie le canal natif quand l'utilisateur a choisi une
          // application. `partagerArticle` ne la lit pas, mais `share_plus` la
          // décode : rendre `null` la ferait passer pour « unavailable ».
          return 'dev.fluttercommunity.plus/share/success';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canalPartage, null);
  });

  /// Pose une fiche avec la session demandée, sans réseau ni Firebase.
  ///
  /// [locale] a une valeur par défaut, mais la coque NOMME toujours la sienne à
  /// `MaterialApp` : sans `locale:`, la résolution part de
  /// `platformDispatcher.locales`, qui vaut `[en_US]` dans un banc, et
  /// `supportedLocales` commence par `Locale('en')`. Le message serait composé
  /// en anglais pendant que les assertions parlent français — une mesure fausse
  /// et verte. Voir test/support/langues.dart.
  Future<void> poser(
    WidgetTester tester,
    Widget fiche, {
    required AuthState session,
    Locale locale = localeFr,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((_) => _FauxAuth(session)),
          catalogRepositoryProvider.overrideWithValue(_DepotMuet()),
        ],
        child: MaterialApp(
          locale: locale,
          // Les délégués sont nécessaires au PARTAGE lui-même, pas seulement à
          // l'affichage : la mention du message vient de
          // `partageMentionBoutique`, et `partagerArticle` est le seul maillon de
          // ce chemin à disposer d'un `BuildContext` — la composition, elle, est
          // pure. Sans eux, `AppLocalizations.of` lève au moment du tap.
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: fiche,
        ),
      ),
    );

    // Plusieurs passes avec du temps qui s'écoule, et non un simple `pump()`.
    //
    // Ces fiches lancent des requêtes que le dépôt muet ne sert pas : la
    // compatibilité garage sur la fiche d'une pièce, les partenaires sur celle
    // d'un accessoire vue par le personnel. Dio pose un minuteur pour chacune,
    // et le banc d'essai de Flutter échoue sur « A Timer is still pending »
    // quand l'arbre est démonté avant qu'il n'ait expiré. Laisser le temps
    // passer les fait tomber en erreur, ce qu'ils font déjà en silence à
    // l'écran. Même procédé que `responsive_test.dart`.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Les trois fiches, construites sur les données de la liste — comme quand
  /// on arrive dessus depuis le catalogue, avant que le détail ne réponde.
  final fiches = <String, Widget>{
    'pièce': PartDetailPage(partId: _idPiece, initialPart: _piece()),
    'accessoire': AccessoryDetailPage(
      accessoryId: _idAccessoire,
      initialAccessory: _accessoire(),
    ),
    'véhicule': VehicleDetailPage(
      vehicleId: _idVehicule,
      initialVehicle: _vehicule(),
    ),
  };

  /// Le type de page attendu pour chaque fiche, et la clef primaire de son
  /// article. Trois identifiants distincts, et non « 1 » partout : c'est ce
  /// qui distingue un identifiant lu sur le modèle d'un identifiant écrit en
  /// dur dans la fiche.
  final adressesAttendues = <String, String>{
    'pièce': adresseArticle(TypeArticle.piece, _idPiece),
    'accessoire': adresseArticle(TypeArticle.accessoire, _idAccessoire),
    'véhicule': adresseArticle(TypeArticle.vehicule, _idVehicule),
  };

  // ── Présence ──────────────────────────────────────────────────────────────

  group('Le bouton « Partager » est sur les trois fiches', () {
    for (final fiche in fiches.entries) {
      testWidgets('fiche d\'une ${fiche.key}', (tester) async {
        await poser(tester, fiche.value, session: _client());

        expect(find.byIcon(Icons.share_outlined), findsOneWidget);
        // Le libellé n'apparaît qu'au survol ou au lecteur d'écran : une icône
        // d'engrenage, de crayon ou de flèche ne se devine pas.
        expect(find.byTooltip(partagerFr()), findsOneWidget);
      });
    }
  });

  /// Le point central. Trois sessions, dont celle qui n'existe pas :
  /// `AuthType.none`, c'est-à-dire l'application ouverte sans s'être connecté
  /// — l'état dans lequel se trouve le visiteur qui parcourt le catalogue.
  group('Le partage ne dépend d\'aucune session', () {
    final sessions = <String, AuthState>{
      'aucune session': const AuthState(),
      'client connecté': _client(),
      'administrateur': _admin(),
    };

    for (final fiche in fiches.entries) {
      for (final session in sessions.entries) {
        testWidgets('fiche d\'une ${fiche.key}, ${session.key}', (
          tester,
        ) async {
          await poser(tester, fiche.value, session: session.value);

          expect(
            find.byTooltip(partagerFr()),
            findsOneWidget,
            reason:
                'Partager n\'est pas une action de gestion : c\'est '
                'surtout un client, voire un visiteur, qui partage.',
          );
        });
      }
    }
  });

  /// L'administrateur voit le plus de commandes — c'est le cas où le partage
  /// risquait d'être poussé hors de la barre.
  testWidgets('le partage reste visible à côté des commandes du personnel', (
    tester,
  ) async {
    await poser(tester, fiches['pièce']!, session: _admin());

    expect(find.byTooltip(partagerFr()), findsOneWidget);
    expect(find.byTooltip(bulleSuivante['fr']!.modifier), findsOneWidget);
    expect(find.byTooltip(bulleSuivante['fr']!.supprimer), findsOneWidget);
  });

  // ── Absence : l'article n'a pas de page publique ───────────────────────────

  /// **La régression à empêcher.** Le message porte l'adresse de l'article
  /// depuis que le lien du magasin d'applications a été retiré, et le bouton
  /// était posé sans aucune condition. Or `/api/catalog/vehicles` liste aussi
  /// les véhicules vendus, archivés et jamais publiés, dont les pages rendent
  /// 404 : le destinataire recevait un lien mort. Avant ce changement, le lien
  /// menait toujours quelque part — la régression est nouvelle, et c'est à
  /// l'écran de la fermer, l'API ne disant pas « cet article a une page ».
  ///
  /// Un cas par `abort_if` du serveur, et pas un de plus : voir
  /// `autoparc-backend/app/Http/Controllers/Web/ArticleController`. Le statut
  /// `reserved` n'est volontairement pas de la liste — la page d'un véhicule
  /// réservé reste ouverte, parce qu'une réservation tombe et que le lien déjà
  /// envoyé est par où le client suivant arrive.
  ///
  /// `marqueur` n'est pas une politesse : une fiche restée sur son indicateur
  /// de chargement ne porte aucun bouton, et le test passerait sans avoir rien
  /// mesuré. Même procédé que `responsive_test.dart`.
  group('le bouton est absent quand l\'article n\'a pas de page publique', () {
    final sansPage = <String, (Widget, String)>{
      'véhicule vendu': (
        VehicleDetailPage(
          vehicleId: _idVehicule,
          initialVehicle: _vehicule(statut: 'sold'),
        ),
        'Hyundai Tucson',
      ),
      'véhicule archivé': (
        VehicleDetailPage(
          vehicleId: _idVehicule,
          initialVehicle: _vehicule(statut: 'archived'),
        ),
        'Hyundai Tucson',
      ),
      // « véhicule jamais publié » A ÉTÉ RETIRÉ DE CETTE LISTE, et le cas
      // inverse est asserté plus bas : un véhicule non publié DOIT porter le
      // bouton.
      //
      // Ce cas-là était le défaut, pas la garde. Personne ne pose jamais
      // `published_at` — l'action existe côté serveur mais aucun écran ne
      // l'appelle —, donc exiger ce champ masquait le bouton sur TOUS les
      // véhicules. Trouvé par le propriétaire en testant le partage sur la
      // production : sa seule annonce, une Mazda `in_stock` et à vendre,
      // n'avait pas de bouton et rendait 404.
      //
      // Le serveur a bougé le premier : `catalogueMontre()` ne regarde plus
      // que le statut.
      'pièce désactivée': (
        PartDetailPage(partId: _idPiece, initialPart: _piece(actif: false)),
        'Filtre à huile',
      ),
      'accessoire désactivé': (
        AccessoryDetailPage(
          accessoryId: _idAccessoire,
          initialAccessory: _accessoire(actif: false),
        ),
        'Tapis de sol',
      ),
      'accessoire indisponible': (
        AccessoryDetailPage(
          accessoryId: _idAccessoire,
          initialAccessory: _accessoire(disponible: false),
        ),
        'Tapis de sol',
      ),
    };

    for (final cas in sansPage.entries) {
      testWidgets(cas.key, (tester) async {
        await poser(tester, cas.value.$1, session: _client());

        expect(
          find.textContaining(cas.value.$2, findRichText: true),
          findsWidgets,
          reason: 'La fiche ne s\'est pas dessinée : rien n\'a été mesuré.',
        );

        expect(
          find.byTooltip(partagerFr()),
          findsNothing,
          reason:
              'Partager ${cas.key} fabrique un lien qui rend 404 chez le '
              'destinataire. Le bouton doit disparaître, pas rester inerte.',
        );
        expect(find.byIcon(Icons.share_outlined), findsNothing);
      });
    }

    testWidgets('mais un véhicule JAMAIS PUBLIÉ garde le sien', (tester) async {
      // Le cas qui a coûté la fonction entière, retourné en garde.
      //
      // Exiger `published_at` masquait le bouton sur TOUS les véhicules,
      // puisque rien ne pose jamais ce champ. Si quelqu'un remet un jour
      // cette condition — elle a l'air raisonnable, et c'est ce qui la rend
      // dangereuse —, ce test tombe au lieu de laisser la fonction mourir en
      // silence une seconde fois.
      await poser(
        tester,
        VehicleDetailPage(
          vehicleId: _idVehicule,
          initialVehicle: _vehicule(publie: false),
        ),
        session: _client(),
      );

      expect(
        find.textContaining('Hyundai Tucson', findRichText: true),
        findsWidgets,
        reason: 'La fiche ne s\'est pas dessinée : rien n\'a été mesuré.',
      );

      expect(
        find.byTooltip(partagerFr()),
        findsOneWidget,
        reason:
            'Le bouton a de nouveau disparu sur un véhicule non publié. '
            'Sa page existe — `catalogueMontre()` ne regarde que le statut — '
            'et aucun écran de cette application ne sait publier quoi que ce '
            'soit : exiger ce champ rend le partage mort pour tout le parc.',
      );
    });
  });

  /// Le pendant du groupe ci-dessus, sur le seul cas qui lui ressemble sans en
  /// être : un véhicule réservé garde sa page, donc son bouton. Sans ce test,
  /// une condition trop large — « tout ce qui n'est pas en stock » — passerait.
  testWidgets('un véhicule réservé garde son bouton : sa page existe', (
    tester,
  ) async {
    await poser(
      tester,
      VehicleDetailPage(
        vehicleId: _idVehicule,
        initialVehicle: _vehicule(statut: 'reserved'),
      ),
      session: _client(),
    );

    expect(find.byTooltip(partagerFr()), findsOneWidget);
  });

  // ── Le message d'un véhicule ──────────────────────────────────────────────

  /// Ce qui arrive réellement dans la conversation WhatsApp du destinataire.
  ///
  /// La désignation est désormais la SEULE information du message, et elle
  /// suffit : la vignette que WhatsApp construit sur les balises Open Graph de
  /// `/v/{id}` porte la photo, le prix et les caractéristiques, et elle en dit
  /// plus que le texte n'en disait — elle ajoute l'année et l'état. Ce test
  /// fige donc la forme en entier, deux lignes comprises : c'est l'égalité du
  /// nombre de lignes qui fait tomber le test le jour où une information
  /// revient, quelle qu'elle soit.
  testWidgets(
    'le message d\'un véhicule porte sa désignation, et rien de plus',
    (tester) async {
      await poser(tester, fiches['véhicule']!, session: _client());

      await tester.tap(find.byTooltip(partagerFr()));
      await tester.pumpAndSettle();

      expect(
        envois,
        hasLength(1),
        reason: 'Le bouton doit ouvrir la feuille de partage, une fois.',
      );

      final texte = envois.single['text'] as String;

      // La désignation telle que le bandeau de la fiche l'affiche : marque,
      // modèle, année. Le message ne peut pas contredire l'écran.
      expect(texte, contains('Hyundai Tucson (2023)'));
      expect(texte, endsWith(adressesAttendues['véhicule']!));
      expect(texte.split('\n'), hasLength(2));

      // Les champs du modèle rendent `null` quand ils manquent ; les interpoler
      // sans les filtrer écrivait « null » dans la conversation. Le message n'en
      // porte plus aucun, mais l'assertion reste : c'est le titre qui en vient
      // maintenant, et une désignation sans année passe par le même chemin.
      expect(texte.toLowerCase(), isNot(contains('null')));
    },
  );

  // ── La garde : ce que la vignette dit déjà ne part plus dans le texte ─────

  /// **Le point de ce lot, et la seule mesure qui l'atteste.** Les valeurs
  /// interdites sont celles des trois modèles de ce fichier, aux libellés que
  /// l'écran affiche — « SUV / 4×4 » et non « suv », « Automatique » et non
  /// « automatic ». Ce sont exactement les champs que le message portait avant,
  /// et que la vignette de la page publique porte maintenant.
  ///
  /// Vérifié sur les trois types : la page en dit PLUS que le message n'en
  /// disait dans chacun — elle ajoute le fabricant, la garantie et la ville
  /// pour une pièce, l'année et l'état pour un véhicule. Le texte n'apportait
  /// donc rien, il redoublait.
  ///
  /// Ce qu'on perd est assumé : quand l'instance gratuite de Render dort, son
  /// robot d'aperçu abandonne avant d'avoir lu la page, et le destinataire ne
  /// voit que les deux lignes. Il garde le nom, la provenance et un lien qui
  /// marche. La duplication, elle, se voyait à chaque partage réussi.
  group('le message ne redit ni le prix ni les caractéristiques', () {
    final dejaDansLaVignette = <String, List<String>>{
      // Le prix, la catégorie, l'état et la référence de la pièce. Le SKU est
      // dans le NOM de cet article — c'est le cas des dix filtres à huile du
      // catalogue —, donc c'est la précision « Réf. … » qui doit manquer et
      // non la suite de caractères : l'interdire ferait tomber le test sur le
      // titre lui-même.
      'pièce': ['Filtration', 'Neuf', 'Réf.'],
      'accessoire': ['Confort'],
      // « km » et non « 62 400 km » : la fiche ponctue les milliers avec
      // l'espace insécable étroit de `fr_FR`, et une absence assertée sur
      // l'espace qu'on tape passerait sans rien mesurer. L'unité suffit à
      // identifier la ligne de kilométrage, et aucune désignation ne la porte.
      'véhicule': ['SUV / 4×4', 'Automatique', 'Diesel', 'km'],
    };

    /// Les trois prix des trois modèles, interdits sur les trois fiches : un
    /// prix rebranché par erreur sur le mauvais article serait tout aussi
    /// faux. Ils passent par `formatXof` plutôt que par un montant écrit en
    /// dur, parce que la locale fr_FR sépare les milliers par un espace
    /// insécable étroit — une absence assertée sur un caractère invisible
    /// différent serait verte sans rien mesurer.
    final prix = [formatXof(3000), formatXof(12000), formatXof(2450000)];

    for (final fiche in fiches.entries) {
      testWidgets('fiche d\'une ${fiche.key}', (tester) async {
        await poser(tester, fiche.value, session: _client());

        await tester.tap(find.byTooltip(partagerFr()));
        await tester.pumpAndSettle();

        final texte = envois.single['text'] as String;

        for (final valeur in [...prix, ...dejaDansLaVignette[fiche.key]!]) {
          expect(
            texte,
            isNot(contains(valeur)),
            reason:
                '« $valeur » part déjà dans la vignette que WhatsApp '
                'construit sur la page publique. Le remettre dans le texte, '
                'c\'est la duplication signalée par le propriétaire : elle '
                'n\'apparaît sur aucun écran de l\'application, seulement dans '
                'la conversation du destinataire.',
          );
        }

        // Le symbole seul : un prix rebranché autrement — arrondi, abrégé,
        // formaté à la main — garderait au moins « FCFA ».
        expect(texte, isNot(contains('FCFA')));
        // Le séparateur de l'ancienne ligne de précisions.
        expect(texte, isNot(contains('·')));

        // Deux lignes, et pas une de plus : toute information rebranchée en
        // ajouterait une, où qu'on l'insère.
        expect(texte.split('\n'), hasLength(2));
        expect(texte.split('\n').last, adressesAttendues[fiche.key]!);
      });
    }
  });

  // ── La mention, dans la langue de l'écran ─────────────────────────────────

  /// La mention est tout ce qui reste du texte autour du lien, et elle sert
  /// précisément quand l'aperçu échoue : l'instance gratuite de Render s'endort
  /// au bout de quinze minutes, et le robot d'aperçu abandonne avant la fin de
  /// son réveil. Le destinataire lit alors ces deux lignes et rien d'autre —
  /// une adresse nue ne dirait pas d'où vient le lien.
  ///
  /// Elle est lue dans `partagerArticle`, seul maillon de ce chemin à disposer
  /// d'un `BuildContext` : la composition est pure, et reçoit la chaîne déjà
  /// traduite. C'est donc ici, et nulle part ailleurs, que l'on vérifie que la
  /// langue de l'écran arrive bien jusqu'au message qui part.
  group('la mention du message suit la langue de l\'application', () {
    /// Les deux chaînes attendues, écrites en clair : c'est le CONTRAT des deux
    /// `.arb`. Une assertion qui se contenterait de relire la clé resterait
    /// verte le jour où l'anglais rendrait le texte français.
    const mentions = <String, String>{
      'fr': 'sur AutoParc',
      'en': 'on AutoParc',
    };

    langues.forEach((nom, locale) {
      for (final fiche in fiches.entries) {
        testWidgets('fiche d\'une ${fiche.key}, en $nom', (tester) async {
          await poser(tester, fiche.value, session: _client(), locale: locale);

          // L'INFOBULLE DE LA LANGUE MONTÉE, et non celle du français : c'est
          // ce groupe-ci qui monte les deux langues, et chercher « Partager »
          // sur une fiche anglaise ne trouve rien depuis la vague 2. Cet échec
          // est aussi la non-vacuité du groupe : une coque qui servirait du
          // français en annonçant l'anglais ne porterait pas « Share », donc ce
          // test tomberait au lieu de vérifier la mention dans la mauvaise
          // langue.
          await tester.tap(find.byTooltip(bulleSuivante[nom]!.partager));
          await tester.pumpAndSettle();

          final texte = envois.single['text'] as String;
          final attendue = mentions[nom]!;

          // Le tiret est dans l'assertion : c'est lui qui prouve que la mention
          // est bien à sa place, collée au titre, et non ajoutée ailleurs.
          expect(texte, contains('— $attendue'));
          // La clé relue, pour que l'assertion ne survive pas à un `.arb` qui
          // dirait autre chose.
          expect(
            texte,
            contains((await chargerTextes(locale)).partageMentionBoutique),
          );

          for (final autre in mentions.entries.where((e) => e.key != nom)) {
            expect(
              texte,
              isNot(contains(autre.value)),
              reason:
                  'La mention est restée en ${autre.key} : le message ne '
                  'suit pas la langue de l\'écran.',
            );
          }
        });
      }
    });
  });

  // ── L'adresse qui part réellement ─────────────────────────────────────────

  /// Le défaut que ce lot corrige : le message portait la fiche du magasin
  /// d'applications. Un vendeur partageait une Corolla, et son contact
  /// recevait le titre, le prix, puis un lien Play Store — à lui d'installer
  /// l'application et de retrouver l'article. Les pages publiques existent et
  /// portent les balises Open Graph ; c'est leur adresse qui doit partir,
  /// faute de quoi aucun robot d'aperçu n'a rien à aller chercher — et le
  /// texte allégé ne laisse plus rien à la place.
  group('le message porte l\'adresse de l\'article', () {
    for (final fiche in fiches.entries) {
      testWidgets('fiche d\'une ${fiche.key}', (tester) async {
        await poser(tester, fiche.value, session: _client());

        await tester.tap(find.byTooltip(partagerFr()));
        await tester.pumpAndSettle();

        final texte = envois.single['text'] as String;

        expect(texte, endsWith(adressesAttendues[fiche.key]!));
        // Le lien du magasin menait partout sauf à l'article : sa réapparition
        // annulerait tout le lot, message compris.
        expect(texte, isNot(contains('play.google.com')));
      });
    }
  });

  // ── Le marqueur de version, de bout en bout ───────────────────────────────

  /// **Le défaut que ce lot répare**, signalé par le propriétaire : « un
  /// véhicule déjà partagé ne met pas à jour ses données de partage après
  /// maj ». Le serveur n'y est pour rien — `/v/86` annonce bien
  /// « Mazda CX-9 2018 — 9 500 000 FCFA » et l'API rend `sale_price:
  /// 9500000.00`. Ce qui ne bouge pas, c'est la vignette DÉJÀ CONSTRUITE chez
  /// l'opérateur : WhatsApp clefe la sienne sur l'adresse qu'il a APPELÉE,
  /// donc seule une adresse différente la fait refaire.
  ///
  /// `partage_test.dart` mesure la composition de l'adresse ; ici on mesure la
  /// CHAÎNE ENTIÈRE, et c'est ce qui manquait au lot `publishedAt` : modèle
  /// Dart → fiche → `partagerArticle` → `composerMessagePartage` →
  /// `adresseArticle` → ce qui part vraiment vers `share_plus`. Un maillon
  /// oublié — une fiche qui ne passerait pas `version:` — reste invisible aux
  /// tests unitaires des deux bouts.
  group('le marqueur de version part avec l\'adresse', () {
    /// La forme que le serveur produit : la seconde UNIX d'`updated_at` en
    /// base 36, `base_convert('1760000000', 10, 36)`. Échantillon, pas
    /// contrat — le format appartient à `app/Support/VersionPartage.php`.
    const marqueur = 't3uwow';

    final versionnees = <String, ({Widget fiche, String adresse})>{
      'pièce': (
        fiche: PartDetailPage(
          partId: _idPiece,
          initialPart: _piece(version: marqueur),
        ),
        adresse: '${adresseArticle(TypeArticle.piece, _idPiece)}?m=$marqueur',
      ),
      'accessoire': (
        fiche: AccessoryDetailPage(
          accessoryId: _idAccessoire,
          initialAccessory: _accessoire(version: marqueur),
        ),
        adresse:
            '${adresseArticle(TypeArticle.accessoire, _idAccessoire)}?m=$marqueur',
      ),
      'véhicule': (
        fiche: VehicleDetailPage(
          vehicleId: _idVehicule,
          initialVehicle: _vehicule(version: marqueur),
        ),
        adresse:
            '${adresseArticle(TypeArticle.vehicule, _idVehicule)}?m=$marqueur',
      ),
    };

    for (final entree in versionnees.entries) {
      testWidgets('fiche d\'une ${entree.key}', (tester) async {
        await poser(tester, entree.value.fiche, session: _client());

        await tester.tap(find.byTooltip(partagerFr()));
        await tester.pumpAndSettle();

        final texte = envois.single['text'] as String;

        expect(texte, endsWith(entree.value.adresse));
        // Le marqueur vit dans l'adresse et NULLE PART dans le texte : le
        // destinataire ne doit pas lire une chaîne technique sous le titre.
        expect(texte.split('\n'), hasLength(2));
        expect(texte.split('\n').first, isNot(contains(marqueur)));
      });
    }

    /// **Le repli, et c'est lui que le propriétaire verra en premier si on se
    /// trompe.** Les fiches par défaut n'ont pas la clef `share_version` au
    /// JSON — l'état d'une instance du serveur antérieure à ce lot, ou d'un
    /// chemin d'API qui ne l'expose pas. Le bouton doit rester entier et
    /// l'adresse nue, jamais `?m=null`.
    ///
    /// Ce dépôt a déjà payé ce piège : le partage d'un véhicule a été MORT
    /// pour tout le parc parce qu'une règle exigeait `publishedAt`, que rien
    /// ne peuple. Trois relectures adversariales l'ont manqué ; le
    /// propriétaire l'a vu en une minute.
    for (final fiche in fiches.entries) {
      testWidgets(
        'sans la clef au JSON, la fiche d\'une ${fiche.key} partage l\'adresse nue',
        (tester) async {
          await poser(tester, fiche.value, session: _client());

          // Le bouton existe toujours : un champ cosmétique absent ne doit pas
          // faire disparaître le partage, qui est la fonction de l'écran.
          expect(find.byTooltip(partagerFr()), findsOneWidget);

          await tester.tap(find.byTooltip(partagerFr()));
          await tester.pumpAndSettle();

          final texte = envois.single['text'] as String;
          final adresse = texte.split('\n').last;

          expect(adresse, adressesAttendues[fiche.key]!);
          expect(adresse, isNot(contains('?')));
          expect(adresse, isNot(contains('null')));
          // L'adresse nue mène bien quelque part : c'est tout ce qu'on perd —
          // le rafraîchissement de la vignette, jamais la destination.
          expect(Uri.parse(adresse).hasScheme, isTrue);
        },
      );
    }
  });

  // ── Aucun fichier joint ───────────────────────────────────────────────────

  /// La régression à empêcher, et elle serait muette : rejoindre la photo de
  /// couverture ferait de l'envoi un message IMAGE dont le texte devient la
  /// légende, et WhatsApp ne rend pas d'aperçu de lien dans une légende. Tous
  /// les aperçus disparaîtraient d'un coup — photo, titre, prix, lien
  /// cliquable — sans qu'aucune assertion sur le texte ne bouge. Le coût serait
  /// pire depuis que le texte est court : il ne reste plus rien pour compenser.
  ///
  /// `paths` et `mimeTypes` n'apparaissent dans la carte d'arguments que si
  /// `ShareParams.files` est renseigné : on mesure donc leur absence, et non
  /// une liste vide.
  group('aucun fichier n\'est joint au partage', () {
    for (final fiche in fiches.entries) {
      testWidgets('fiche d\'une ${fiche.key}', (tester) async {
        await poser(tester, fiche.value, session: _client());

        await tester.tap(find.byTooltip(partagerFr()));
        await tester.pumpAndSettle();

        final envoi = envois.single;

        expect(
          envoi.containsKey('paths'),
          isFalse,
          reason:
              'Une pièce jointe supprime l\'aperçu de lien : le texte '
              'deviendrait la légende d\'une image.',
        );
        expect(envoi.containsKey('mimeTypes'), isFalse);
        // Le texte, lui, doit bien être là : « aucun fichier » ne doit pas se
        // confondre avec « rien du tout ».
        expect(envoi['text'], isA<String>());
      });
    }
  });
}

// ── Données de fiche ───────────────────────────────────────────────────────

/// Les clefs primaires des trois articles, volontairement différentes : avec
/// « 1 » partout, une fiche qui écrirait son identifiant en dur passerait les
/// tests.
const _idPiece = 7;
const _idAccessoire = 12;
const _idVehicule = 305;

/// [actif] porte `is_active`, la seule condition de la page `/p/{id}` : le
/// stock n'y entre pas, le catalogue des pièces montrant les ruptures.
/// [version] porte `share_version`. Par défaut la clef est ABSENTE du JSON, et
/// c'est le cas qui compte le plus : c'est ce que rend une instance du serveur
/// antérieure à ce lot, ou un chemin d'API qui ne l'expose pas. Tout le reste
/// de ce fichier mesure donc le repli sur l'adresse nue sans avoir à le dire.
Part _piece({bool actif = true, String? version}) => Part.fromJson({
  'id': _idPiece,
  'share_version': ?version,
  'name': 'Filtre à huile moteur cartouche 04152-YZZA1',
  'sku': '04152-YZZA1',
  'type': 'aftermarket',
  'condition': 'new',
  'category': {'id': 4, 'name': 'Filtration'},
  'pricing': {
    'selling_price': 3000,
    'currency': 'XOF',
    'vat_rate': 0,
    'price_including_vat': 3000,
  },
  'stock': {
    'is_available': true,
    'quantity': 15,
    'alert_threshold': 0,
    'is_low': false,
  },
  'is_active': actif,
});

/// [actif] et [disponible] portent les DEUX conditions de `/a/{id}`.
/// [version] porte `share_version` — voir `_piece`, clef absente par défaut.
Accessory _accessoire({
  bool actif = true,
  bool disponible = true,
  String? version,
}) =>
    Accessory.fromJson({
      'id': _idAccessoire,
      'share_version': ?version,
      'name': 'Tapis de sol caoutchouc toutes saisons, jeu de quatre',
      'sku': 'TAP-4S-001',
      'category': {'value': 'confort', 'label': 'Confort'},
      'pricing': {
        'selling_price': 12000,
        'currency': 'XOF',
        'vat_rate': 0,
        'price_including_vat': 12000,
      },
      'stock': {
        'is_available': disponible,
        'quantity': disponible ? 15 : 0,
        'alert_threshold': 0,
        'is_low': false,
      },
      'is_active': actif,
    });

/// Un véhicule à vendre, dont tous les champs du message sont renseignés :
/// c'est le cas qui permet de vérifier la forme complète.
///
/// Les champs que le message ne porte PLUS restent renseignés, et c'est tout
/// l'intérêt : prix, kilométrage, carrosserie, boîte et motorisation sont les
/// valeurs dont le groupe « le message ne redit ni le prix ni les
/// caractéristiques » mesure l'absence. Un modèle dépouillé rendrait ces
/// assertions vertes sans rien prouver.
///
/// `media` était vide pour une raison qui n'a plus cours : le partage puisait
/// alors la photo de couverture dans le cache d'images, lequel réclame un
/// répertoire système que le banc d'essai n'a pas. Le partage n'ouvre plus le
/// cache et ne joint plus de fichier, donc la liste pourrait désormais porter
/// des photos sans rien changer au message. Elle reste vide : ce qui part vers
/// `share_plus` ne dépend plus des photos, et le prouver demande précisément
/// une fiche où elles ne jouent aucun rôle.
///
/// [statut] et [publie] portent la seule chose qui décide maintenant de la
/// PRÉSENCE du bouton : `published_at` et le statut commercial. Par défaut,
/// un véhicule en stock et publié — le cas partageable.
///
/// [version] porte `share_version` — voir `_piece`, clef absente par défaut.
Vehicle _vehicule({
  String statut = 'in_stock',
  bool publie = true,
  String? version,
}) => Vehicle.fromJson({
  'id': _idVehicule,
  'share_version': ?version,
  'reference': 'VH-WHVQKVHM',
  'designation': 'Hyundai Tucson Base 2023',
  'vehicle_type': 'passenger',
  'body_style': 'suv',
  'registration_status': {'value': 'registered', 'label': 'Immatriculé'},
  'identity': {
    'brand': 'Hyundai',
    'brand_slug': 'hyundai',
    'model': 'Tucson',
    'trim': 'Base',
    'engine_type': 'Diesel',
    'year': 2023,
  },
  'technical': {'transmission': 'automatic', 'mileage_km': 62400, 'seats': 5},
  'commercial': {
    'condition': 'used',
    'status': statut,
    'availability': 'sale',
    'sale_price': '2450000.00',
    'currency': 'XOF',
    'price_negotiable': true,
    'site': 'Ouagadougou',
  },
  'media': const [],
  'features': const [],
  // La forme du serveur : `published_at?->toIso8601String()`, donc la clé
  // est là et vaut `null` tant que la fiche n'a pas été publiée.
  'published_at': publie ? '2026-09-30T18:42:43+00:00' : null,
});

// ── Dépendances neutralisées ───────────────────────────────────────────────

/// Un dépôt qui ne répond jamais : les fiches se dessinent sur les données de
/// la liste, et c'est le bouton qu'on mesure, pas le chargement du détail.
class _DepotMuet implements CatalogRepository {
  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

/// Une session figée, sans Firebase. Le vrai `AuthNotifier` s'y abonne dès son
/// constructeur, ce qu'un test ne peut pas satisfaire.
class _FauxAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FauxAuth(super.etat);

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

AuthState _admin() => const AuthState(
  type: AuthType.staff,
  staffUser: StaffUser(
    id: 1,
    name: 'Administrateur',
    email: 'admin@autoparc.bf',
    role: 'admin',
  ),
);

AuthState _client() => const AuthState(type: AuthType.client);
