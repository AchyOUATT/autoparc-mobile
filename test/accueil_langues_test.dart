import 'dart:convert';
import 'dart:io';

import 'package:auto/core/theme/app_theme.dart';
import 'package:auto/core/utils/currency_format.dart';
import 'package:auto/core/widgets/navigation_bar_theme.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/catalog_repository.dart';
import 'package:auto/features/catalog/data/models/accessory.dart';
import 'package:auto/features/catalog/data/models/part.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/pages/accessory_detail_page.dart';
import 'package:auto/features/catalog/presentation/pages/accessory_list_page.dart';
import 'package:auto/features/catalog/presentation/pages/part_detail_page.dart';
import 'package:auto/features/catalog/presentation/pages/part_list_page.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_detail_page.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_list_page.dart';
import 'package:auto/features/auth/presentation/pages/login_page.dart';
import 'package:auto/features/cart/data/models/cart_item.dart';
import 'package:auto/features/cart/presentation/pages/cart_page.dart';
import 'package:auto/features/cart/presentation/providers/cart_provider.dart';
import 'package:auto/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/providers/garage_provider.dart';
import 'package:auto/features/garage/presentation/widgets/engine_prompt.dart';
import 'package:auto/features/home/presentation/pages/home_page.dart';
import 'package:auto/features/home/presentation/providers/home_providers.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/echelles.dart';
import 'support/langues.dart';
import 'support/mesures.dart';
import 'support/polices.dart';
import 'support/troncature.dart';

/// LES ÉCRANS TRADUITS PAR CE LOT NE TRONQUENT PAS EN ANGLAIS.
///
/// ── CE QUE CE FICHIER EXISTE POUR EMPÊCHER ──────────────────────────────────
///
/// Le lot précédent a passé une journée entière sur des troncatures invisibles :
/// un titre coupé dans 24 cases, une ville rognée sans ellipse. La traduction
/// est précisément le genre de changement qui les rouvre, parce qu'elle change
/// la largeur de chaque chaîne sans toucher à une seule mise en page.
///
/// ET L'ANGLAIS N'EST PAS UNIFORMÉMENT PLUS COURT. Mesuré sur ce lot :
///
///   « Accessoires »                  77,93 pt → « Accessories »      78,06 pt
///   « Mettre à jour le kilométrage »          → « Update mileage »    plus court
///   « Visite technique, assurance, … »        → « Roadworthiness … »  plus long
///
/// L'intuition « l'anglais est plus concis » est donc fausse au cas par cas, et
/// c'est le cas par cas qui casse une mise en page.
///
/// ── LES ÉCRANS COUVERTS, ET CEUX QUI NE LE SONT PAS ─────────────────────────
///
/// Couverts ici : l'accueil ENTIER — carte du véhicule, échéances, bande des
/// pièces compatibles, vitrine, tuiles « Parcourir », invitation au besoin — et
/// les barres de titre des trois pages du catalogue, qui sont les quatre
/// chaînes de coque que ce lot traduit.
///
/// La barre de navigation du bas est mesurée par `bandes_filtres_test.dart`,
/// dans les deux langues, avec le détail de la marge qui reste. Les cartes du
/// catalogue le sont par `carte_geometrie_test.dart`, également dans les deux
/// langues.
///
/// NON COUVERTS, et c'est volontaire : les écrans que ce lot ne traduit pas.
/// Leur texte français ne change pas de largeur, et les mesurer en anglais
/// mesurerait du français.
///
/// ── LA MÉTHODE ──────────────────────────────────────────────────────────────
///
/// Les mêmes configurations que le français, et dans la même exécution : trois
/// largeurs d'écran, quatre échelles de texte, les deux langues. On mesure sur
/// les GLYPHES PEINTS — voir `support/mesures.dart` — et la page est montée
/// DANS SA COQUE, avec la barre de navigation qui lui prend ses 112 points,
/// parce qu'une page mesurée sans son chrome mesure un téléphone qui n'existe
/// pas.
///
/// LES QUATRE ÉCHELLES SONT MESURÉES, TROIS SONT ASSERTÉES. La frontière et son
/// raisonnement sont dans `support/echelles.dart` ; ce fichier n'en recopie
/// rien. Jusqu'à 1,5 on exige qu'aucune chaîne de l'application ne se coupe ;
/// à 2,0 on imprime le relevé et on n'exige que les quatre points non
/// négociables, dont celui qui compte : aucun paragraphe portant un CHIFFRE ne
/// se coupe ni ne se replie dans un mot.
void main() {
  setUpAll(() => chargerPolices());

  tearDown(() => definirLocaleMontants(localeFr));

  /// 320 × 640 : le plus petit format encore courant. 360 × 720 : la médiane du
  /// parc Android. 411 × 923 : le Pixel de l'émulateur, donc l'écran sur lequel
  /// un défaut ne se voit pas.
  const ecrans = <String, Size>{
    '320x640': Size(320, 640),
    '360x720': Size(360, 720),
    '411x923': Size(411, 923),
  };

  /// Les quatre échelles, MESURÉES. Ce que chacune autorise à exiger est décidé
  /// par [tenue], et la décision est écrite dans `support/echelles.dart`.
  const echelles = echellesMesurees;

  // ── Le pire contenu que l'accueil puisse recevoir ─────────────────────────

  /// Un véhicule de la vitrine, au pire cas : nom long, ville, prix à huit
  /// chiffres. Le prix est la seule ligne de la tuile dont la LARGEUR change
  /// avec la langue — « 99 999 999 FCFA » contre « 99,999,999 FCFA ».
  Vehicle affaire() => Vehicle.fromJson({
    'id': 1,
    'reference': 'VH-0001',
    'designation': 'Toyota Land Cruiser Prado 2016',
    'registration_status': 'registered',
    'identity': {
      'brand': 'Toyota',
      'brand_slug': 'toyota',
      'model': 'Land Cruiser Prado',
      'year': 2016,
    },
    'commercial': {
      'condition': 'used',
      'status': 'in_stock',
      'availability': 'sale',
      'sale_price': '99999999.00',
      'currency': 'XOF',
      'price_negotiable': true,
      'deal_type': 'good_deal',
      'deal_label': 'Bonne affaire',
      'location': {
        'id': 1,
        'name': 'Showroom Paspanga',
        'city': 'Bobo-Dioulasso',
      },
    },
  });

  Part pieceCompatible() => Part.fromJson({
    'id': 1,
    'name': 'Filtre à huile moteur cartouche 04152-YZZA1',
    'sku': '04152-YZZA1',
    'type': 'aftermarket',
    'condition': 'new',
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
  });

  /// Les trois valeurs de la fixture dont PERSONNE ne contrôle la longueur.
  ///
  /// Le surnom est tapé par le propriétaire ; le nom de modèle et le nom de
  /// pièce viennent du référentiel du serveur. Les textes qui les portent
  /// s'ellipsent par construction, et c'est le seul droit à l'ellipse de cet
  /// écran — voir [aucuneTroncature].
  const valeursSansBorne = <String>{
    'Le Prado du chantier de Bobo',
    'Land Cruiser Prado',
    'Filtre à huile moteur cartouche 04152-YZZA1',
  };

  /// LES DEUX PARAGRAPHES DU BANDEAU DE MOTORISATION, QUI NE SONT PLUS ÉCARTÉS
  /// DE RIEN.
  ///
  /// ── CE QU'ILS ÉTAIENT, ET CE QUI A CHANGÉ ──────────────────────────────────
  ///
  /// Ils étaient exclus du tableau, avec un test dédié qui VERROUILLAIT leur
  /// débordement. Le bandeau posait l'icône, les deux phrases et « Compléter »
  /// dans une seule rangée ; « Compléter » n'est pas repliable, donc
  /// l'`Expanded` des phrases encaissait tout le grossissement du texte et
  /// descendait à 101,07 points reçus à 320 × 1,5, où le seul mot
  /// « Motorisation » en réclame 123,51.
  ///
  /// La règle de `support/echelles.dart` a tranché : 320 × 1,5 est EN DEÇÀ de
  /// la frontière, donc ce n'était pas une dégradation acceptable mais un
  /// défaut à corriger. `engine_prompt.dart` fait maintenant descendre le
  /// bouton sous le texte quand les mots ne tiennent plus — le seuil y est
  /// mesuré, pas deviné. Les deux paragraphes repassent donc sous la règle
  /// générale, aux DOUZE cases, et le test ci-dessous verrouille la correction
  /// au lieu du défaut.
  ///
  /// Les chaînes restent nommées ici parce que le test de la correction les
  /// cherche : `engine_prompt.dart` les écrit en dur, ce bandeau n'étant pas
  /// traduit — il est partagé avec `garage_page.dart`. Les mesures sont
  /// identiques au centième dans les deux langues. Le jour où le bandeau
  /// passera aux `.arb`, ces deux chaînes devront être lues dans
  /// `AppLocalizations` comme le reste du fichier.
  const bandeau = <String>{
    'Motorisation non renseignée',
    'Sans elle, impossible de savoir quelles pièces vont sur ce véhicule.',
  };

  // ── La coque ──────────────────────────────────────────────────────────────

  /// Monte [page] DANS LA COQUE DE L'APPLICATION, à la taille, à l'échelle et
  /// dans la langue demandées.
  ///
  /// La barre de navigation est celle de l'application —
  /// `BarreNavigationPrincipale` —, avec ses intitulés LUS dans les traductions
  /// et non recopiés. Les creux du système sont posés comme ailleurs : 24 en
  /// haut, 48 en bas pour la barre à trois boutons, qui est le cas le plus
  /// contraignant. Sans eux on mesure un appareil sans barre d'état.
  Future<Object?> poser(
    WidgetTester tester, {
    required Widget page,
    required int ongletActif,
    required Size ecran,
    required double echelle,
    required Locale locale,

    /// La session montée. Le client par défaut, parce que c'est lui qui voit
    /// l'accueil ENTIER — le personnel n'a pas de garage, et `_MyVehicleSection`
    /// disparaît pour lui.
    ///
    /// Le groupe des barres de titre monte le PERSONNEL, pour deux raisons.
    /// D'abord parce que c'est le rôle dont les barres de titre sont les plus
    /// chargées : il y gagne un bouton « Ajouter ». Ensuite pour éviter une
    /// fragilité de cycle de vie qui n'a rien à voir avec la traduction :
    /// `part_list_page.dart` insère `_GarageFilterBanner` sous `if (!isStaff)`,
    /// et cet état lit ses notifiers dans `deactivate()` pour écrire APRÈS la
    /// trame — le commentaire sur place explique pourquoi les deux autres
    /// emplacements ne marchaient pas. Quand un banc démonte tout le
    /// `ProviderScope`, le rappel écrit dans un conteneur déjà jeté et lève
    /// « Tried to use StateController after dispose ».
    ///
    /// CE N'EST PAS UN DÉFAUT DE PRODUCTION CONTOURNÉ : dans l'application, le
    /// `ProviderScope` est la racine et vit aussi longtemps que le processus,
    /// donc le conteneur ne peut pas disparaître entre `deactivate()` et la
    /// trame suivante. La fragilité est réelle et sans porteur ; elle est
    /// signalée ici plutôt que tue, et hors du champ d'un lot de traduction.
    AuthState session = const AuthState(type: AuthType.client),
  }) async {
    // Le format des montants est un réglage de module, posé par
    // `AutoParcApp.build` dans l'application. Sans cette ligne, le banc
    // mesurerait une page anglaise avec des prix français.
    definirLocaleMontants(locale);

    tester.view.physicalSize = ecran;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.binding.setSurfaceSize(ecran);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        // Une clé neuve à chaque pose : sans elle, Flutter réutilise l'élément
        // du `ProviderScope`, donc son conteneur, donc l'état déjà chargé des
        // providers — et deux poses dans le même test mesureraient deux fois la
        // première.
        key: UniqueKey(),
        overrides: [
          authProvider.overrideWith((_) => _FauxAuth(session)),
          garageProvider.overrideWith(_GarageDuPrado.new),
          homeDealsProvider.overrideWith((_) async => [affaire()]),
          homeCompatiblePartsProvider.overrideWith(
            (_, __) async => [pieceCompatible(), pieceCompatible()],
          ),
          catalogRepositoryProvider.overrideWithValue(_DepotMuet()),
          catalogRefsProvider.overrideWith(
            (_) async => const CatalogRefs(
              brands: [],
              vehicleModels: [],
              trims: [],
              engineTypes: [],
              drivetrains: [],
              colors: [],
              features: [],
              locations: [],
            ),
          ),
        ],
        child: MaterialApp(
          theme: themeAutoParc(Brightness.light),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(
              size: ecran,
              textScaler: TextScaler.linear(echelle),
              padding: const EdgeInsets.only(top: 24, bottom: 48),
              viewPadding: const EdgeInsets.only(top: 24, bottom: 48),
            ),
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Scaffold(
                  body: page,
                  bottomNavigationBar: BarreNavigationPrincipale(
                    selectedIndex: ongletActif,
                    destinations: [
                      NavigationDestination(
                        icon: const Icon(Icons.home_outlined),
                        label: l10n.commonHome,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.directions_car_outlined),
                        label: l10n.commonVehicles,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.tune_outlined),
                        label: l10n.commonAccessories,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.settings_outlined),
                        label: l10n.commonParts,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Les dépôts répondent sur des microtâches ; six pompes laissent la page
    // passer de ses indicateurs de chargement à son contenu.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    return tester.takeException();
  }

  // L'assertion « rien ne se coupe » vivait ICI, locale à ce fichier. Elle
  // est passée dans test/support/troncature.dart quand la vague 2 lui a
  // donné un second appelant — `bandes_filtres_test.dart`, qui monte les
  // trois listes du catalogue dans les deux langues. Le fichier déplacé
  // porte la raison du déplacement ; rien de la fonction n'a changé.

  // ── L'accueil ─────────────────────────────────────────────────────────────

  group('L\'accueil', () {
    /// « Bonnes affaires » / « Good deals », lus dans les `.arb` plutôt que
    /// recopiés : le tableau les écarte nommément, et une copie en dur
    /// cesserait de les écarter — donc ferait tomber le tableau — le jour où la
    /// traduction change.
    final titreVitrine = <String, String>{};

    setUpAll(() async {
      for (final langue in langues.entries) {
        titreVitrine[langue.key] = (await chargerTextes(
          langue.value,
        )).homeDealsSection;
      }
    });
    for (final ecran in ecrans.entries) {
      for (final echelle in echelles) {
        for (final langue in langues.entries) {
          testWidgets(
            '${ecran.key}, texte x$echelle, ${langue.key} : rien n\'est coupé',
            (tester) async {
              final exception = await poser(
                tester,
                page: const HomePage(),
                ongletActif: 0,
                ecran: ecran.value,
                echelle: echelle,
                locale: langue.value,
              );

              expect(
                exception,
                isNull,
                reason:
                    'Débordement de l\'accueil en ${ecran.key} à l\'échelle '
                    '$echelle, en ${langue.key} : Flutter peint sa bande '
                    'rayée par-dessus le contenu.',
              );

              // ON DÉFILE, et ce n'est pas une précaution : l'accueil est un
              // `ListView`, qui ne CONSTRUIT que ce qui est visible. Mesuré
              // sans défilement, « Vous ne trouvez pas ? Dites-nous ce que
              // vous cherchez » — la ligne la plus longue de la page — n'avait
              // tout simplement pas d'objet de rendu, et le tableau passait au
              // vert sans l'avoir regardée une seule fois. Le défaut a été vu
              // parce que le test de non-vacuité, lui, la cherchait par son
              // texte et ne la trouvait pas.
              // NI `horsChamp` NI `defautsConnus`, et c'est le résultat de ce
              // lot. Le bandeau de motorisation était écarté — deux
              // paragraphes, un débordement verrouillé par un test dédié — et
              // le titre de la vitrine était déclaré « défaut connu ». Les
              // deux sont corrigés : `engine_prompt.dart` fait descendre son
              // bouton quand les mots ne tiennent plus, et `_SectionTitle` ne
              // perd plus la famille de police de son « Tout voir ». TOUS les
              // paragraphes de l'accueil passent désormais sous la règle
              // générale, aux quatre échelles, à la sévérité que [tenue]
              // décide.
              for (var pas = 0; pas < 10; pas++) {
                aucuneTroncature(
                  tester,
                  racine: find.byType(HomePage),
                  ou:
                      'Accueil ${ecran.key} x$echelle ${langue.key}, '
                      'défilement $pas',
                  echelle: echelle,
                  valeursSansBorne: valeursSansBorne,
                );

                final defilable = find.descendant(
                  of: find.byType(HomePage),
                  matching: find.byType(Scrollable),
                );
                if (defilable.evaluate().isEmpty) break;

                await tester.drag(defilable.first, const Offset(0, -240));
                for (var i = 0; i < 3; i++) {
                  await tester.pump(const Duration(milliseconds: 50));
                }
                expect(
                  tester.takeException(),
                  isNull,
                  reason:
                      'Débordement apparu au défilement $pas en '
                      '${ecran.key} à l\'échelle $echelle, en '
                      '${langue.key}.',
                );
              }

              // ÇA DÉFILE, ET C'EST NON NÉGOCIABLE À TOUTE ÉCHELLE. C'est le
              // troisième des quatre points de `support/echelles.dart` : à 2,0
              // la page est moins dense, donc une part plus grande de son
              // contenu passe sous le pli — ce qui ne tient plus doit rester
              // ATTEIGNABLE. Un écran moins dense reste utilisable ; un écran
              // dont le bas est inaccessible ne l'est pas.
              //
              // Lu sur la position du `Scrollable` APRÈS les dix glissements :
              // `pixels > 0` dit que la page a réellement bougé, là où
              // l'absence d'exception ne dit rien.
              final position = tester
                  .state<ScrollableState>(
                    find
                        .descendant(
                          of: find.byType(HomePage),
                          matching: find.byType(Scrollable),
                        )
                        .first,
                  )
                  .position;

              expect(
                position.pixels,
                greaterThan(0.0),
                reason:
                    'L\'accueil n\'a pas défilé d\'un seul point après dix '
                    'glissements en ${ecran.key} à l\'échelle $echelle, en '
                    '${langue.key} : son contenu tient-il vraiment dans '
                    '${position.viewportDimension.toStringAsFixed(1)} points, '
                    'ou le défilement est-il bloqué ? Si le contenu tient, '
                    'c\'est la fixture qui a maigri ; s\'il est bloqué, '
                    'l\'écran est inutilisable au-delà du pli.',
              );
            },
          );
        }
      }
    }

    testWidgets('les textes mesurés sont bien ceux de la langue montée', (
      tester,
    ) async {
      // NON-VACUITÉ DU TABLEAU CI-DESSUS. Sans ce test, une coque dont les
      // délégués seraient mal câblés mesurerait du français dans les deux
      // colonnes, et les douze cases anglaises passeraient au vert en
      // n'éprouvant rien. C'est le défaut exact de la police de repli, raconté
      // dans support/polices.dart : faux et vert.
      for (final langue in langues.entries) {
        await poser(
          tester,
          page: const HomePage(),
          ongletActif: 0,
          ecran: const Size(411, 923),
          echelle: 1.0,
          locale: langue.value,
        );

        final textes = await chargerTextes(langue.value);

        // On descend jusqu'au bas de la page : l'invitation au besoin est le
        // dernier enfant du `ListView` et n'est pas construite tant qu'elle est
        // hors champ.
        for (var i = 0; i < 6; i++) {
          await tester.drag(
            find
                .descendant(
                  of: find.byType(HomePage),
                  matching: find.byType(Scrollable),
                )
                .first,
            const Offset(0, -240),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.pump(const Duration(milliseconds: 50));

        expect(
          find.text(textes.homeDealsSection),
          findsOneWidget,
          reason:
              'Le titre de la vitrine n\'est pas en ${langue.key} : la coque '
              'ne sert pas la langue qu\'elle annonce. Ou bien il a quitté le '
              'champ au défilement, et ce sont les glissements ci-dessus '
              'qu\'il faut revoir.',
        );
        expect(
          find.text(textes.homeNeedPrompt),
          findsOneWidget,
          reason: 'L\'invitation au besoin n\'est pas en ${langue.key}.',
        );
      }
    });

    testWidgets('le titre de section tient jusqu\'à 1,5, et la traduction '
        'n\'aggrave rien', (tester) async {
      // ── CE TEST A CHANGÉ DE SENS, ET C'EST LE CŒUR DU LOT ──────────────────
      //
      // Il VERROUILLAIT un défaut : « le titre de section se coupe déjà », avec
      // 103,0 points reçus à 320 × 2,0 pour 200,1 demandés. Il verrouille
      // maintenant la CORRECTION, parce que le défaut n'en était pas un là où
      // on le croyait.
      //
      // CE QUI A ÉTÉ TROUVÉ EN REMESURANT. Le « Tout voir » de `_SectionTitle`
      // recevait `textStyle: const TextStyle(fontSize: 12.5)`, qui REMPLACE le
      // `labelLarge` du bouton et emporte sa famille de police. Le bouton
      // rendait donc la police de repli, presque deux fois plus large :
      //
      //              bouton « Tout voir »      titre reçu, à 320
      //   avant  x1,0        136,50                  157,50
      //          x1,3        167,85                  126,15   ← COUPÉ
      //          x1,5        188,75                  105,25   ← COUPÉ
      //          x2,0        241,00                   53,00   ← COUPÉ + débordé
      //   après  x1,0         73,34                  220,66
      //          x1,3         85,48                  208,52
      //          x1,5         93,57                  200,43
      //          x2,0        113,79                  180,21   ← coupé seulement
      //
      // Le défaut touchait donc TROIS cases en deçà de 1,5 — 320×1,3, 320×1,5
      // et 360×1,5 — et il était déclaré « connu, à arbitrer » alors qu'il
      // n'était qu'un style mal composé. La règle de `support/echelles.dart`
      // l'a sorti de l'ombre : 1,3 et 1,5 sont du côté où l'on exige.
      //
      // CE QUI RESTE À 2,0, ET QUI EST ACCEPTÉ : à 320 points, « Bonnes
      // affaires » demande 200,07 pour 180,21 reçus et s'ellipse. UNE case sur
      // douze, et c'est une ellipse HONNÊTE — le mot « affaires » (97,80) tient
      // dans la largeur reçue, donc plus rien n'est rogné en silence. À 360 et
      // 411 le titre tient entier même à 2,0.
      //
      // ET LA TRADUCTION N'AGGRAVE RIEN, ce qui va contre l'intuition : c'est
      // le FRANÇAIS le plus large. « Bonnes affaires » demande 200,07 points à
      // 320 × 2,0, « Good deals » 142,2 — l'anglais en réclame 57,9 de MOINS.
      // La seule chose à surveiller est qu'un futur libellé anglais ne repasse
      // pas devant.
      final demandes = <String, double>{};

      Future<RenderParagraph> titreA(
        MapEntry<String, Locale> langue,
        double echelle,
      ) async {
        await poser(
          tester,
          page: const HomePage(),
          ongletActif: 0,
          ecran: const Size(320, 640),
          echelle: echelle,
          locale: langue.value,
        );

        // La vitrine est sous le pli : on descend jusqu'à elle.
        for (var i = 0; i < 6; i++) {
          await tester.drag(
            find
                .descendant(
                  of: find.byType(HomePage),
                  matching: find.byType(Scrollable),
                )
                .first,
            const Offset(0, -240),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }

        return tester.renderObject<RenderParagraph>(
          find.text(titreVitrine[langue.key]!),
        );
      }

      for (final langue in langues.entries) {
        // 320 × 1,5 : LA CASE DE LA CORRECTION. C'est le pire cas de largeur à
        // l'échelle la plus haute que ce dépôt garantit, et le titre y était
        // coupé avant ce lot.
        final a15 = await titreA(langue, echelleTenue);

        expect(
          a15.didExceedMaxLines,
          isFalse,
          reason:
              'Le titre de la vitrine est de nouveau COUPÉ en ${langue.key} à '
              '320 points et à l\'échelle $echelleTenue : '
              '${voulue(a15).toStringAsFixed(2)} points voulus pour '
              '${recue(a15).toStringAsFixed(2)} reçus, il n\'en reste que '
              '« ${peint(a15, recue(a15))} ». Le « Tout voir » a-t-il reperdu '
              'la famille de police de son style — voir `_SectionTitle` — ou '
              'le libellé a-t-il grandi ?',
        );

        // 320 × 2,0 : la dégradation ACCEPTÉE. On la mesure et on l'imprime,
        // on ne l'asserte pas — ni dans un sens ni dans l'autre. L'exiger
        // rendrait ce test rouge le jour où quelqu'un l'améliore, et exiger
        // qu'elle disparaisse serait optimiser pour un cas que le propriétaire
        // a sorti du compte.
        final a20 = await titreA(langue, 2.0);
        demandes[langue.key] = voulue(a20);

        // ignore: avoid_print
        print(
          '@@TITRE VITRINE 320 x2.0 ${langue.key} : '
          '${voulue(a20).toStringAsFixed(2)} voulus / '
          '${recue(a20).toStringAsFixed(2)} reçus, '
          'mot ${motLePlusLarge(a20).toStringAsFixed(2)}, '
          '${a20.didExceedMaxLines ? "ellipsé en «${peint(a20, recue(a20))}»" : "entier"}',
        );

        // CE QUI RESTE NON NÉGOCIABLE À 2,0 : l'ellipse. Un titre ellipsé est
        // incomplet et l'œil le voit ; un mot plus large que sa ligne est
        // ROGNÉ par le `clipBehavior`, sans ellipse et sans que rien
        // n'avertisse. C'est la différence entre une dégradation et un
        // mensonge, et le mot « affaires » est repassé du bon côté avec la
        // correction du style.
        expect(
          motLePlusLarge(a20),
          lessThanOrEqualTo(recue(a20) + 0.01),
          reason:
              'Un mot du titre de la vitrine fait '
              '${motLePlusLarge(a20).toStringAsFixed(2)} points pour '
              '${recue(a20).toStringAsFixed(2)} reçus en ${langue.key} à '
              '320 × 2,0 : il sera rogné SANS ellipse. À 2,0 on accepte un '
              'titre incomplet, jamais un titre rogné en silence.',
        );
      }

      expect(
        demandes['en'],
        lessThanOrEqualTo(demandes['fr']! + 0.01),
        reason:
            'Le titre de la vitrine est devenu PLUS large en anglais '
            '(${demandes['en']!.toStringAsFixed(1)} points) qu\'en français '
            '(${demandes['fr']!.toStringAsFixed(1)}) : la traduction aggrave '
            'une troncature qu\'elle ne causait pas. C\'est précisément ce que '
            'ce lot avait pour consigne de ne pas faire.',
      );
    });

    testWidgets('le bandeau de motorisation fait descendre son bouton quand '
        'les mots ne tiennent plus', (tester) async {
      // ── CE TEST VERROUILLE UNE CORRECTION, LÀ OÙ IL VERROUILLAIT UN DÉFAUT ──
      //
      // L'ÉTAT D'AVANT. `engine_prompt.dart` posait l'icône, les deux phrases
      // et « Compléter » dans une seule rangée. Le bouton n'est pas repliable,
      // donc l'`Expanded` des phrases encaissait tout le grossissement du
      // texte, et un mot plus large que sa ligne était posé seul et débordait
      // HORIZONTALEMENT : `didExceedMaxLines` restait FAUX, aucune ellipse
      // n'apparaissait, et les glyphes passaient sous le bouton.
      //
      // LES SIX CASES, SUR DOUZE, REMESURÉES AVANT LA CORRECTION — les mots
      // contre ce que l'`Expanded` recevait, accueil monté dans sa coque :
      //
      //   « Motorisation » : 83,34 à x1,0 · 107,45 à x1,3 · 123,51 à x1,5 ·
      //                      163,69 à x2,0
      //   « impossible »   : 62,29 · 79,78 · 91,44 · 120,59
      //
      //            reçus    Motorisation   impossible
      //   320 x1,0 129,75        —              —
      //   320 x1,3 112,54        —              —
      //   320 x1,5 101,07      DÉBORDE          —        ← la seule case ≤ 1,5
      //   320 x2,0  72,40      DÉBORDE       DÉBORDE
      //   360 x1,5 141,07        —              —
      //   360 x2,0 112,40      DÉBORDE       DÉBORDE
      //   411 x1,5 192,07        —              —
      //   411 x2,0 163,40      DÉBORDE (de 0,29)  —
      //
      // CE QUE LA RÈGLE A TRANCHÉ. Une seule de ces six cases est en deçà de
      // 1,5 : 320 × 1,5, sur « Motorisation ». C'est elle qui obligeait à
      // corriger — `support/echelles.dart` ne laisse aucune latitude de ce
      // côté-ci de la frontière. « impossible », lui, ne débordait QU'À 2,0 :
      // sous la règle seule, il serait devenu une dégradation acceptée.
      //
      // LA CORRECTION LES RÈGLE TOUS LES SIX, et ce n'est pas un hasard : la
      // cause était unique — le bouton qui prend sa largeur sur le texte — donc
      // la corriger une fois les corrige tous. Empilé, le bloc de texte reçoit
      // 220,00 points à 320, 260,00 à 360 et 311,00 à 411, pour un mot le plus
      // large de 163,69 au dernier cran d'Android.
      //
      // ET LE BANDEAU Y A GAGNÉ DE LA HAUTEUR, ce qui est le contraire de ce
      // qu'on attend d'un empilement : les mots qui débordaient forçaient le
      // paragraphe sur six à treize lignes. Mesuré à 320 points, en trois
      // états — avant la correction, après le seuil de débordement, puis après
      // le seuil de lisibilité que le propriétaire a demandé sur capture :
      //
      //           origine   débordement   lisibilité
      //   x1,0      126,0       126,0        126,0   (côte à côte)
      //   x1,3      205,0       205,0        185,0   (empilé au 3e état)
      //   x1,5      310,0       202,0        202,0   (empilé au 2e)
      //   x2,0      678,0       310,0        310,0   (empilé au 2e)
      //
      // Le bandeau ne coûte donc AUCUNE hauteur au réglage par défaut, qui est
      // ce que presque tout le monde voit, et il en rend partout ailleurs.
      // `engine_prompt.dart` porte le relevé des douze cases et nomme la
      // seconde qui a basculé, 360 × 1,5, que personne n'avait demandée.

      /// Le paragraphe de [texte] du bandeau, sur l'écran monté.
      RenderParagraph duBandeau(String texte) =>
          tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.byType(MissingEngineBanner),
              matching: find.text(texte),
            ),
          );

      /// Les deux lectures que la correction demande, sur un paragraphe donné.
      ///
      /// La seconde n'est pas décorative : un paragraphe qui se déclarerait
      /// tronqué perdrait du texte d'une AUTRE façon, que la mesure du segment
      /// insécable ne voit pas.
      void tient(RenderParagraph p, String ou) {
        expect(
          motLePlusLarge(p),
          lessThanOrEqualTo(recue(p) + 0.01),
          reason:
              'Le bandeau de motorisation déborde de nouveau en $ou, sur '
              '« ${texteDe(p)} » : ${motLePlusLarge(p).toStringAsFixed(2)} '
              'points de segment insécable pour '
              '${recue(p).toStringAsFixed(2)} reçus. Le seuil de '
              '`engine_prompt.dart` ne fait plus descendre le bouton — le '
              'libellé a-t-il changé, ou la réserve de largeur du bouton '
              'est-elle devenue trop courte ?',
        );

        expect(
          p.didExceedMaxLines,
          isFalse,
          reason:
              '$ou : « ${texteDe(p)} » se déclare tronqué. Un `maxLines` a-t-il '
              'été posé sur une chaîne de l\'application ? Ce dépôt refuse de '
              'couper son propre texte.',
        );
      }

      /// Les DOUZE cases, et le relevé imprimé. Le bandeau n'est pas traduit —
      /// il est partagé avec `garage_page.dart` et ses chaînes sont en dur —
      /// donc une seule langue suffit, et les mesures sont identiques au
      /// centième dans l'autre.
      for (final ecran in ecrans.entries) {
        for (final echelle in echelles) {
          await poser(
            tester,
            page: const HomePage(),
            ongletActif: 0,
            ecran: ecran.value,
            echelle: echelle,
            locale: localeFr,
          );

          final ps = [for (final texte in bandeau) duBandeau(texte)];

          // ignore: avoid_print
          print(
            '@@BANDEAU MOTORISATION ${ecran.key} x$echelle : '
            'haut ${tester.renderObject<RenderBox>(find.byType(MissingEngineBanner)).size.height.toStringAsFixed(1)}, '
            '${ps.map((p) => "«${texteDe(p).split(" ").first}…» mot ${motLePlusLarge(p).toStringAsFixed(2)} / ${recue(p).toStringAsFixed(2)} reçus").join(" ; ")}',
          );

          // ASSERTÉ AUX QUATRE ÉCHELLES, 2,0 COMPRISE, et c'est volontaire. La
          // règle de `support/echelles.dart` AUTORISE à ne plus exiger au-delà
          // de 1,5 ; elle n'oblige pas à relâcher ce qui tient. Ici la
          // correction tient aux douze cases, donc on le verrouille aux douze :
          // relâcher une assertion verte, c'est abandonner la seule chose qui
          // dira qu'elle a cessé de l'être.
          for (final p in ps) {
            tient(p, '${ecran.key}×$echelle');
          }
        }
      }
    });

    testWidgets('le libellé d\'échéance mélange la phrase traduite et le '
        'libellé du serveur', (tester) async {
      // CE TEST DIT UN ÉTAT, PAS UN IDÉAL. Les libellés d'échéance — « Visite
      // technique », « Assurance », « Vidange » — et leurs détails sont
      // composés par l'API, et la vague serveur ne fait pas partie de ce lot.
      // En anglais, l'accueil affiche donc « Visite technique overdue by 11
      // days ». C'est volontaire et c'est écrit ici, pour que personne ne le
      // découvre sur une capture d'écran en croyant à un oubli.
      await poser(
        tester,
        page: const HomePage(),
        ongletActif: 0,
        ecran: const Size(411, 923),
        echelle: 1.0,
        locale: localeEn,
      );

      expect(
        find.text('Visite technique overdue by 11 days'),
        findsOneWidget,
        reason:
            'Soit la phrase n\'est plus traduite, soit le serveur est passé à '
            'l\'anglais — et dans ce second cas, c\'est ce test qu\'il faut '
            'mettre à jour, avec la vague serveur.',
      );
    });
  });

  // ── Les barres de titre du catalogue ──────────────────────────────────────

  /// Les trois autres pages de la coque ne sont traduites que par leur BARRE DE
  /// TITRE dans ce lot : leur corps — filtres, badges, cartes — reste français.
  /// On ne mesure donc ici que ce qui a changé, et on le dit : mesurer leur
  /// corps « en anglais » mesurerait du français et donnerait une couverture
  /// imaginaire.
  ///
  /// CES ASSERTIONS RESTENT STRICTES AUX QUATRE ÉCHELLES, 2,0 comprise, et il
  /// faut dire pourquoi puisque la règle de `support/echelles.dart` autoriserait
  /// à les relâcher. Elle AUTORISE, elle n'oblige pas : une barre de titre est
  /// une rangée avec un seul texte et deux icônes, elle tient aux vingt-quatre
  /// cases, et relâcher une assertion verte revient à jeter la seule chose qui
  /// dira qu'elle a cessé de l'être. On ne relâche que là où le défaut EXISTE et
  /// qu'on a décidé de ne plus le payer.
  group('Les barres de titre du catalogue', () {
    final pages = <String, (Widget, int, String Function(AppLocalizations))>{
      'Véhicules': (const VehicleListPage(), 1, (l) => l.commonVehicles),
      'Accessoires': (const AccessoryListPage(), 2, (l) => l.commonAccessories),
      'Pièces': (const PartListPage(), 3, (l) => l.catalogPartListTitle),
    };

    for (final page in pages.entries) {
      for (final ecran in ecrans.entries) {
        for (final echelle in echelles) {
          for (final langue in langues.entries) {
            testWidgets(
              '${page.key} en ${ecran.key}, texte x$echelle, ${langue.key}',
              (tester) async {
                await poser(
                  tester,
                  page: page.value.$1,
                  ongletActif: page.value.$2,
                  ecran: ecran.value,
                  echelle: echelle,
                  locale: langue.value,
                  session: const AuthState(
                    type: AuthType.staff,
                    staffUser: StaffUser(
                      id: 1,
                      name: 'Administrateur',
                      email: 'admin@autoparc.bf',
                      role: 'admin',
                    ),
                  ),
                );

                final attendu = page.value.$3(
                  await chargerTextes(langue.value),
                );

                final titre = tester.renderObject<RenderParagraph>(
                  find.descendant(
                    of: find.byType(AppBar),
                    matching: find.text(attendu),
                  ),
                );

                expect(
                  titre.didExceedMaxLines,
                  isFalse,
                  reason:
                      '« $attendu » est COUPÉ dans la barre de titre en '
                      '${ecran.key} à l\'échelle $echelle : '
                      '${voulue(titre).toStringAsFixed(1)} points voulus pour '
                      '${recue(titre).toStringAsFixed(1)} reçus, il n\'en '
                      'reste que « ${peint(titre, recue(titre))} ».',
                );

                expect(
                  motLePlusLarge(titre),
                  lessThanOrEqualTo(recue(titre) + 0.01),
                  reason:
                      'Un mot de « $attendu » fait '
                      '${motLePlusLarge(titre).toStringAsFixed(1)} points pour '
                      '${recue(titre).toStringAsFixed(1)} reçus : il sera '
                      'rogné sans ellipse.',
                );
              },
            );
          }
        }
      }
    }
  });

  // ── LES ÉCRANS DE LA VAGUE 2 ──────────────────────────────────────────────

  /// Les sept poses des six écrans que la vague 2 a traduits et qui portent
  /// leur PROPRE coque.
  ///
  /// ── POURQUOI UNE SECONDE COQUE DANS CE FICHIER ──────────────────────────
  ///
  /// [poser], plus haut, monte une page DANS la coque de l'application : un
  /// `Scaffold` qui lui prend ses 112 points de barre de navigation. C'est
  /// juste pour l'accueil et pour les trois listes du catalogue, qui sont des
  /// destinations d'onglet. Les écrans ci-dessous n'en sont pas : les trois
  /// fiches, le panier, l'identification et la démonstration de première
  /// utilisation s'ouvrent PAR-DESSUS la coque, portent leur propre `Scaffold`,
  /// et trois d'entre eux ont leur propre barre du bas — la barre d'action
  /// d'une fiche, le bouton de commande du panier. Les monter dans la coque des
  /// onglets leur retirerait 112 points qu'ils ont en vrai, et ferait tomber
  /// des cases que l'application ne produit pas.
  ///
  /// ── CE QUI EST MESURÉ, ET CE QUI EST ÉCARTÉ ─────────────────────────────
  ///
  /// Tous les paragraphes PEINTS de l'écran, par [aucuneTroncature], dans les
  /// deux langues et aux douze configurations de l'accueil. Les valeurs qui
  /// viennent du serveur ou de l'utilisateur sont écartées nommément : un nom de
  /// pièce de 43 signes n'a aucune borne, et sa longueur n'est pas la nôtre.
  ///
  /// La démonstration ne monte QUE sa première diapositive : un `PageView` ne
  /// construit pas celles qui sont hors champ. C'est aussi celle dont le corps
  /// est le plus long des trois, dans les deux langues.
  group('Les écrans de la vague 2', () {
    /// La fiche du Tucson, telle que le serveur la rend : c'est la fixture de
    /// la fiche de détail, donc un véhicule qui porte TOUT le bloc technique —
    /// puissance, cylindrée, couple, consommation, couleur métallisée, import.
    /// Une fiche pauvre ne mesurerait qu'un tiers des lignes traduites.
    Vehicle tucson() => Vehicle.fromJson(
      (jsonDecode(File('test/fixtures/vehicle_detail.json').readAsStringSync())
              as Map<String, dynamic>)['data']
          as Map<String, dynamic>,
    );

    /// Une pièce au nom long À DESSEIN : c'est lui qui pousse la barre de titre
    /// et la confirmation d'ajout au panier. `refurbished` et un stock FAIBLE,
    /// pour que « Reconditionné » et « 2 en stock — stock faible » soient
    /// peints : ce sont les deux valeurs les plus larges de leurs lignes.
    Part piece() => Part.fromJson({
      'id': 1,
      'name': 'Filtre à huile moteur cartouche 04152-YZZA1',
      'sku': '04152-YZZA1',
      'type': 'aftermarket',
      'condition': 'refurbished',
      'description':
          'Cartouche de filtration à haut débit, compatible avec les '
          'moteurs essence et diesel de la gamme.',
      'category_name': 'Filtre à huile',
      'manufacturer': 'Denso',
      'pricing': {
        'selling_price': 3000,
        'currency': 'XOF',
        'vat_rate': 0,
        'price_including_vat': 3000,
      },
      'stock': {
        'is_available': true,
        'quantity': 2,
        'alert_threshold': 5,
        'is_low': true,
        'storage_location': 'Allee B - etagere 3',
      },
      // DEUX LIGNES DE COMPATIBILITÉ, DONT UNE PROPOSÉE : sans elles, le bloc
      // `CompatibilitesDeclarees` rend `SizedBox.shrink()` et la vague 2 n'y
      // mesurerait rien. L'une porte une fourchette d'années et une position,
      // donc les trois connecteurs traduits de `labelDans` ; `source:
      // generated` fait apparaître l'avertissement « {n} sur {total} proposées
      // automatiquement », la plus longue phrase du bloc.
      'fitments': const [
        {
          'vehicle_model_id': 11,
          'vehicle_model': 'Corolla',
          'trim': 'XLE',
          'year_from': 2015,
          'year_to': 2020,
          'position': 'Avant gauche',
          'source': 'manual',
        },
        {
          'vehicle_model_id': 12,
          'vehicle_model': 'Hilux',
          'year_from': 2012,
          'source': 'generated',
        },
      ],
    });

    /// Un accessoire au stock faible, pour la même raison : c'est la pastille
    /// « Stock bas » qui partage la ligne avec la quantité et l'emplacement.
    Accessory accessoire() => Accessory.fromJson({
      'id': 1,
      'name': 'Tapis de sol caoutchouc toutes saisons',
      'sku': 'TAP-4S-001',
      // La catégorie est un OBJET {value, label} : c'est le serveur qui rend le
      // libellé, et c'est lui que la fiche affiche. Les cinq libellés des
      // PUCES de la liste, eux, sont écrits dans l'application et traduits —
      // voir `_libelleCategorie` dans `accessory_list_page.dart`. Les deux ne
      // sont donc pas la même chaîne, et le libellé reçu ici reste français.
      'category': {'value': 'confort', 'label': 'Confort'},
      'manufacturer': 'Novline',
      'description': 'Jeu de quatre tapis moules, rebords hauts.',
      'pricing': {
        'selling_price': 18000,
        'currency': 'XOF',
        'vat_rate': 0,
        'price_including_vat': 18000,
      },
      'stock': {
        'is_available': true,
        'quantity': 3,
        'alert_threshold': 5,
        'is_low': true,
        'storage_location': 'Allee C - etagere 1',
      },
    });

    /// Les valeurs que le SERVEUR ou l'UTILISATEUR écrit, et qui ont donc le
    /// droit de s'ellipser. La règle et son unique exception sont écrites dans
    /// `support/troncature.dart` : c'est volontairement une liste à tenir à
    /// jour plutôt qu'un assouplissement général, pour que le jour où une
    /// chaîne de l'APPLICATION se coupe, elle tombe.
    const sansBorne = <String>{
      'Filtre à huile moteur cartouche 04152-YZZA1',
      'Tapis de sol caoutchouc toutes saisons',
      'Hyundai Tucson',
      'Allee B - etagere 3',
      'Allee C - etagere 1',
      // Les deux SKU, que le personnel saisit : la pastille du panier les rend
      // en monospace, donc en un seul segment insecable que rien ne borne.
      '04152-YZZA1',
      'TAP-4S-001',
      'Cartouche de filtration',
      'Jeu de quatre tapis',
      'Filtre à huile',
      'Denso',
      'Novline',
      // Les lignes de la fiche dont la VALEUR arrive déjà rédigée du
      // référentiel : motorisation, roues motrices, couleur, carburant.
      'Électrique',
      '4WD',
      'Argent',
      // Les deux lignes de compatibilité : le nom du modèle, la finition et la
      // position viennent du référentiel et de la saisie du personnel. Seuls
      // les CONNECTEURS de la ligne sont à nous, et ils sont trop courts pour
      // décider d'une troncature à eux seuls.
      'Corolla',
      'Hilux',
    };

    /// Monte [page] SEULE, dans sa propre coque, à la taille, à l'échelle et
    /// dans la langue demandées.
    Future<Object?> poserEcran(
      WidgetTester tester, {
      required Widget page,
      required Size ecran,
      required double echelle,
      required Locale locale,
      List<Override> surcharges = const [],
      AuthState session = const AuthState(type: AuthType.client),
    }) async {
      // Le format des montants est un réglage de module, posé par
      // `AutoParcApp.build` dans l'application. Sans cette ligne, le panier et
      // les trois fiches mesureraient des prix FRANÇAIS sous une interface
      // anglaise — et le prix est la ligne la plus large de chacun d'eux.
      definirLocaleMontants(locale);

      tester.view.physicalSize = ecran;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.binding.setSurfaceSize(ecran);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          // Une clé neuve à chaque pose : sans elle, Flutter réutilise
          // l'élément du `ProviderScope`, donc son conteneur, donc l'état déjà
          // chargé des providers.
          key: UniqueKey(),
          overrides: [
            authProvider.overrideWith((_) => _FauxAuth(session)),
            catalogRepositoryProvider.overrideWithValue(_DepotMuet()),
            catalogRefsProvider.overrideWith(
              (_) async => const CatalogRefs(
                brands: [],
                vehicleModels: [],
                trims: [],
                engineTypes: [],
                drivetrains: [],
                colors: [],
                features: [],
                locations: [],
              ),
            ),
            ...surcharges,
          ],
          child: MaterialApp(
            theme: themeAutoParc(Brightness.light),
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: MediaQueryData(
                size: ecran,
                textScaler: TextScaler.linear(echelle),
                padding: const EdgeInsets.only(top: 24, bottom: 48),
                viewPadding: const EdgeInsets.only(top: 24, bottom: 48),
              ),
              child: page,
            ),
          ),
        ),
      );

      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      return tester.takeException();
    }

    /// Les sept poses, avec la session et les surcharges que chacune demande.
    ///
    /// TOUTES MONTENT UN CLIENT, et c'est le rôle qui voit le plus de texte sur
    /// ces écrans-là — l'inverse des barres de titre du catalogue, où c'est le
    /// personnel. La fiche d'un véhicule ne porte sa barre d'action « Appeler /
    /// WhatsApp » que pour un client ; les deux autres fiches ne portent leur
    /// bouton « Ajouter au panier » que pour lui, et c'est le plus large de
    /// leur écran.
    final poses = <String, (Widget, List<Override>, AuthState)>{
      'la fiche d\'un véhicule': (
        VehicleDetailPage(vehicleId: 1, initialVehicle: tucson()),
        const <Override>[],
        const AuthState(type: AuthType.client),
      ),
      'la fiche d\'une pièce': (
        PartDetailPage(partId: 1, initialPart: piece()),
        const <Override>[],
        const AuthState(type: AuthType.client),
      ),
      'la fiche d\'un accessoire': (
        AccessoryDetailPage(accessoryId: 1, initialAccessory: accessoire()),
        const <Override>[],
        const AuthState(type: AuthType.client),
      ),
      'le panier': (
        const CartPage(),
        [
          // Deux lignes, et la ligne de calcul « prix × quantité = total » est
          // la plus large du panier. Elle porte TROIS nombres, donc la règle
          // stricte s'y applique à toutes les échelles, 2,0 comprise.
          cartProvider.overrideWith(
            () => _FauxPanier([
              CartItem.fromPart(piece()),
              CartItem.fromAccessory(accessoire()),
            ]),
          ),
        ],
        const AuthState(type: AuthType.client),
      ),
      'le panier vide': (
        const CartPage(),
        [cartProvider.overrideWith(() => _FauxPanier(const []))],
        const AuthState(type: AuthType.client),
      ),
      'l\'identification': (
        const LoginPage(),
        const <Override>[],
        const AuthState(type: AuthType.none),
      ),
      'la démonstration': (
        const OnboardingPage(),
        const <Override>[],
        const AuthState(type: AuthType.none),
      ),
    };

    for (final pose in poses.entries) {
      for (final format in ecrans.entries) {
        for (final echelle in echelles) {
          for (final langue in langues.entries) {
            testWidgets(
              '${pose.key} en ${format.key}, texte x$echelle, ${langue.key}',
              (tester) async {
                final exception = await poserEcran(
                  tester,
                  page: pose.value.$1,
                  ecran: format.value,
                  echelle: echelle,
                  locale: langue.value,
                  surcharges: pose.value.$2,
                  session: pose.value.$3,
                );

                expect(
                  exception,
                  isNull,
                  reason:
                      '${pose.key} JETTE en ${format.key} à l\'échelle '
                      '$echelle, en ${langue.key}. C\'est le point 2 des '
                      'quatre non négociables de support/echelles.dart, et '
                      'l\'échelle 2,0 ne le rachète pas : une bande rayée de '
                      '`RenderFlex` cache ce qui est dessous.',
                );

                aucuneTroncature(
                  tester,
                  racine: find.byType(Scaffold).first,
                  ou:
                      '${pose.key} en ${format.key} à l\'échelle $echelle, '
                      'en ${langue.key}',
                  echelle: echelle,
                  valeursSansBorne: sansBorne,
                );
              },
            );
          }
        }
      }
    }
  });
}

/// Le garage du Prado, sans réseau.
class _GarageDuPrado extends GarageNotifier {
  @override
  Future<List<OwnedVehicle>> build() async => [
    OwnedVehicle.fromJson({
      'id': 1,
      'designation': 'Toyota Land Cruiser Prado 2016 3,0 l boîte automatique',
      'nickname': 'Le Prado du chantier de Bobo',
      'brand_id': 1,
      'vehicle_model_id': 7,
      'year': 2016,
      'mileage_km': 246965,
      'identity': {
        'brand': 'Toyota',
        'brand_slug': 'toyota',
        'model': 'Land Cruiser Prado',
      },
      'compatibility_ready': false,
      'deadlines': [
        {
          'kind': 'technical_inspection',
          'label': 'Visite technique',
          'due_on': null,
          'days_left': -11,
          'overdue': true,
          'detail': null,
        },
        {
          'kind': 'insurance',
          'label': 'Assurance',
          'due_on': null,
          'days_left': 21,
          'overdue': false,
          'detail': null,
        },
        {
          'kind': 'service',
          'label': 'Vidange',
          'due_on': null,
          'days_left': null,
          'overdue': true,
          'detail': 'dépassée de 300 km',
        },
      ],
    }),
  ];
}

/// Un dépôt qui ne répond jamais : les pages du catalogue restent sur leur
/// indicateur, ce qui suffit pour mesurer leur barre de titre.
class _DepotMuet implements CatalogRepository {
  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

/// Une session figée, sans Firebase.
///
/// Le vrai `AuthNotifier` s'abonne à Firebase dès son constructeur, ce qu'un
/// banc ne peut pas satisfaire.
class _FauxAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FauxAuth(super.etat);

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

/// Un panier figé.
///
/// `CartNotifier` construit un panier VIDE — `build() => const []` —, ce qui
/// est juste dans l'application mais ne mesure rien ici : un panier vide ne
/// porte ni ligne de calcul, ni récapitulatif, ni bouton de commande, et ce
/// sont les trois blocs que la vague 2 a traduits. La pose « le panier vide »
/// l'emploie aussi, avec une liste vide, parce que son écran a ses propres
/// chaînes.
class _FauxPanier extends CartNotifier {
  _FauxPanier(this.articles);

  final List<CartItem> articles;

  @override
  List<CartItem> build() => articles;
}
