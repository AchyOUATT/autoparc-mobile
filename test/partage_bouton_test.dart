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
/// C'est aussi le seul endroit où l'absence de pièce jointe se vérifie. Sur
/// WhatsApp, une image jointe produit un message IMAGE dont le texte devient
/// la légende, et les aperçus de lien ne se rendent pas dans une légende :
/// rejoindre une photo ferait silencieusement disparaître toutes les
/// vignettes, sans qu'aucun autre test ne s'en aperçoive. La carte d'arguments
/// du canal ne porte `paths` et `mimeTypes` que lorsque `ShareParams.files`
/// est renseigné — leur absence est donc la mesure exacte.
void main() {
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
  Future<void> poser(
    WidgetTester tester,
    Widget fiche, {
    required AuthState session,
  }) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith((_) => _FauxAuth(session)),
        catalogRepositoryProvider.overrideWithValue(_DepotMuet()),
      ],
      child: MaterialApp(home: fiche),
    ));

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
        accessoryId: _idAccessoire, initialAccessory: _accessoire()),
    'véhicule':
        VehicleDetailPage(vehicleId: _idVehicule, initialVehicle: _vehicule()),
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
        expect(find.byTooltip('Partager'), findsOneWidget);
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
        testWidgets('fiche d\'une ${fiche.key}, ${session.key}',
            (tester) async {
          await poser(tester, fiche.value, session: session.value);

          expect(
            find.byTooltip('Partager'),
            findsOneWidget,
            reason: 'Partager n\'est pas une action de gestion : c\'est '
                'surtout un client, voire un visiteur, qui partage.',
          );
        });
      }
    }
  });

  /// L'administrateur voit le plus de commandes — c'est le cas où le partage
  /// risquait d'être poussé hors de la barre.
  testWidgets('le partage reste visible à côté des commandes du personnel',
      (tester) async {
    await poser(tester, fiches['pièce']!, session: _admin());

    expect(find.byTooltip('Partager'), findsOneWidget);
    expect(find.byTooltip('Modifier'), findsOneWidget);
    expect(find.byTooltip('Supprimer'), findsOneWidget);
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
          find.byTooltip('Partager'),
          findsNothing,
          reason: 'Partager ${cas.key} fabrique un lien qui rend 404 chez le '
              'destinataire. Le bouton doit disparaître, pas rester inerte.',
        );
        expect(find.byIcon(Icons.share_outlined), findsNothing);
      });
    }

    testWidgets('mais un véhicule JAMAIS PUBLIÉ garde le sien',
        (tester) async {
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
        find.byTooltip('Partager'),
        findsOneWidget,
        reason: 'Le bouton a de nouveau disparu sur un véhicule non publié. '
            'Sa page existe — `catalogueMontre()` ne regarde que le statut — '
            'et aucun écran de cette application ne sait publier quoi que ce '
            'soit : exiger ce champ rend le partage mort pour tout le parc.',
      );
    });
  });

  /// Le pendant du groupe ci-dessus, sur le seul cas qui lui ressemble sans en
  /// être : un véhicule réservé garde sa page, donc son bouton. Sans ce test,
  /// une condition trop large — « tout ce qui n'est pas en stock » — passerait.
  testWidgets('un véhicule réservé garde son bouton : sa page existe',
      (tester) async {
    await poser(
      tester,
      VehicleDetailPage(
        vehicleId: _idVehicule,
        initialVehicle: _vehicule(statut: 'reserved'),
      ),
      session: _client(),
    );

    expect(find.byTooltip('Partager'), findsOneWidget);
  });

  // ── Le message d'un véhicule ──────────────────────────────────────────────

  /// Ce qui arrive réellement dans la conversation WhatsApp du destinataire.
  ///
  /// La désignation et le prix sont les deux seules informations sans
  /// lesquelles le message ne sert à rien : « Hyundai Tucson » sans prix fait
  /// rappeler l'agence pour rien, et un prix sans désignation ne désigne
  /// aucun véhicule du parc.
  testWidgets('le message d\'un véhicule porte sa désignation et son prix',
      (tester) async {
    await poser(tester, fiches['véhicule']!, session: _client());

    await tester.tap(find.byTooltip('Partager'));
    await tester.pumpAndSettle();

    expect(envois, hasLength(1),
        reason: 'Le bouton doit ouvrir la feuille de partage, une fois.');

    final texte = envois.single['text'] as String;

    // La désignation telle que le bandeau de la fiche l'affiche : marque,
    // modèle, année. Le message ne peut pas contredire l'écran.
    expect(texte, contains('Hyundai Tucson (2023)'));
    // Le prix passe par `formatXof` plutôt que par un montant écrit en dur :
    // la locale fr_FR sépare les milliers par un espace insécable étroit, et
    // la comparaison aurait échoué sur un caractère invisible.
    expect(texte, contains(formatXof(2450000)));

    // Les précisions demandées à la fiche véhicule, aux libellés de l'écran :
    // « automatic » ou « suv » ne se montrent pas à un acheteur.
    expect(texte, contains('SUV / 4×4'));
    expect(texte, contains('Automatique'));
    expect(texte, contains('Diesel'));
    expect(texte, matches(RegExp(r'62\s400 km')));

    expect(texte.toLowerCase(), isNot(contains('null')));
  });

  // ── L'adresse qui part réellement ─────────────────────────────────────────

  /// Le défaut que ce lot corrige : le message portait la fiche du magasin
  /// d'applications. Un vendeur partageait une Corolla, et son contact
  /// recevait le titre, le prix, puis un lien Play Store — à lui d'installer
  /// l'application et de retrouver l'article. Les pages publiques existent et
  /// portent les balises Open Graph ; c'est leur adresse qui doit partir,
  /// faute de quoi aucun robot d'aperçu n'a rien à aller chercher.
  group('le message porte l\'adresse de l\'article', () {
    for (final fiche in fiches.entries) {
      testWidgets('fiche d\'une ${fiche.key}', (tester) async {
        await poser(tester, fiche.value, session: _client());

        await tester.tap(find.byTooltip('Partager'));
        await tester.pumpAndSettle();

        final texte = envois.single['text'] as String;

        expect(texte, endsWith(adressesAttendues[fiche.key]!));
        // Le lien du magasin menait partout sauf à l'article : sa réapparition
        // annulerait tout le lot, message compris.
        expect(texte, isNot(contains('play.google.com')));
      });
    }
  });

  // ── Aucun fichier joint ───────────────────────────────────────────────────

  /// La régression à empêcher, et elle serait muette : rejoindre la photo de
  /// couverture ferait de l'envoi un message IMAGE dont le texte devient la
  /// légende, et WhatsApp ne rend pas d'aperçu de lien dans une légende. Tous
  /// les aperçus disparaîtraient d'un coup — photo, titre, prix, lien
  /// cliquable — sans qu'aucune assertion sur le texte ne bouge.
  ///
  /// `paths` et `mimeTypes` n'apparaissent dans la carte d'arguments que si
  /// `ShareParams.files` est renseigné : on mesure donc leur absence, et non
  /// une liste vide.
  group('aucun fichier n\'est joint au partage', () {
    for (final fiche in fiches.entries) {
      testWidgets('fiche d\'une ${fiche.key}', (tester) async {
        await poser(tester, fiche.value, session: _client());

        await tester.tap(find.byTooltip('Partager'));
        await tester.pumpAndSettle();

        final envoi = envois.single;

        expect(envoi.containsKey('paths'), isFalse,
            reason: 'Une pièce jointe supprime l\'aperçu de lien : le texte '
                'deviendrait la légende d\'une image.');
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
Part _piece({bool actif = true}) => Part.fromJson({
      'id': _idPiece,
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
Accessory _accessoire({bool actif = true, bool disponible = true}) =>
    Accessory.fromJson({
      'id': _idAccessoire,
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
Vehicle _vehicule({String statut = 'in_stock', bool publie = true}) =>
    Vehicle.fromJson({
      'id': _idVehicule,
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
      'technical': {
        'transmission': 'automatic',
        'mileage_km': 62400,
        'seats': 5,
      },
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
