import 'dart:convert';
import 'dart:io';

import 'package:auto/core/theme/app_theme.dart';
import 'package:auto/core/widgets/bande_filtres.dart';
import 'package:auto/core/widgets/bouton_flottant_effacable.dart';
import 'package:auto/core/widgets/navigation_bar_theme.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/catalog_repository.dart';
import 'package:auto/features/catalog/data/models/accessory.dart';
import 'package:auto/features/catalog/data/models/part.dart';
import 'package:auto/features/catalog/data/models/part_category.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/pages/accessory_list_page.dart';
import 'package:auto/features/catalog/presentation/pages/part_list_page.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_list_page.dart';
import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/shared/models/paginated_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/polices.dart';

/// LES BANDES DE FILTRES DU CATALOGUE : ce qui se tape, ce qui se peint, et ce
/// qu'elles laissent à la liste.
///
/// ── CE QUE CE FICHIER VERROUILLE, ET POURQUOI CHAQUE ASSERTION EXISTE ───────
///
/// 1. LA CIBLE TACTILE DE 48 POINTS, qui est la contrainte dominante du lot.
///    Elle n'est PAS acquise par construction : `RawChip` enveloppe la puce
///    d'un `RenderConstrainedBox` à `minHeight: 48`, et un
///    `RenderConstrainedBox` voit son minimum `enforce`é par la contrainte
///    reçue. La page des véhicules posait ses deux bandes dans des
///    `SizedBox(height: 44)` : la cible tactile mesurait donc 44,0 points, et
///    personne ne l'avait lue. Le test « une bande de 44 points raboterait la
///    cible » reproduit exactement ce cas — sans lui, les assertions de 48
///    points ne prouveraient rien.
///
/// 2. LA HAUTEUR DE LA BANDE, 48,0 points aux échelles 1,0 / 1,3 / 1,5, lue et
///    non posée : la bande n'écrit plus aucune hauteur, elle prend celle de ses
///    puces. À l'échelle 2,0 elle GRANDIT — 52,0 — au lieu d'écraser le
///    libellé, ce que les 44 points faisaient dès l'échelle 1,5.
///
/// 3. UNE SEULE BANDE sur la page des véhicules. Il y en avait deux, de 44
///    points chacune. C'est cette fusion qui rend 40,0 points à la liste, et
///    `carte_geometrie_test.dart` mesure ce que ces 40 points donnent — ou ne
///    donnent pas — en annonces entières.
///
/// 4. LES TROIS PAGES ENSEMBLE. La passe de densité précédente a traité les
///    quatre barres de recherche d'un coup, avec cette raison écrite dans le
///    code : en laisser deux à l'ancienne taille aurait eu l'air d'un défaut.
///
/// 5. AUCUN LIBELLÉ DE PUCE TRONQUÉ, sur les GLYPHES et non sur le champ
///    `data` : `find.text` lit le texte VOULU et laisse passer une ellipse.
///
/// 6. LES DEUX DÉFAUTS VOISINS, chacun avec sa mesure : « Accessoires » se
///    cassait sur deux lignes dans la barre du bas à 320 points et à l'échelle
///    1,3 ; le bouton flottant recouvrait la deuxième carte de la liste.
void main() {
  setUpAll(() => chargerPolices());

  final gabarit =
      (jsonDecode(File('test/fixtures/vehicles_list.json').readAsStringSync())
              as Map<String, dynamic>)['data'][0]
          as Map<String, dynamic>;

  /// Le pire contenu du référentiel, comme dans `carte_geometrie_test.dart` :
  /// une annonce pauvre ferait des rangées courtes et rendrait les mesures de
  /// recouvrement du bouton flottant optimistes.
  Vehicle vehicule() {
    final json = jsonDecode(jsonEncode(gabarit)) as Map<String, dynamic>;
    final id = json['identity'] as Map<String, dynamic>;
    final tec = json['technical'] as Map<String, dynamic>;
    final com = json['commercial'] as Map<String, dynamic>;
    id['brand'] = 'Land Rover';
    id['model'] = 'Range Rover Sport';
    id['year'] = 2018;
    id['trim'] = 'TRD Off-Road';
    id['engine_type'] = 'Électrique';
    tec['transmission'] = 'automatic';
    tec['mileage_km'] = 246965;
    com['availability'] = 'both';
    com['sale_price'] = '99999999.00';
    com['rental_daily_rate'] = null;
    com['deal_label'] = 'Bonne affaire';
    com['location'] = {
      'id': 3,
      'name': 'Showroom Paspanga',
      'city': 'Bobo-Dioulasso',
    };
    com['site'] = null;
    json['media'] = <dynamic>[];
    return Vehicle.fromJson(json);
  }

  /// 320 × 640 : le plus petit format encore courant. 360 × 720 : la médiane du
  /// parc Android. 411 × 923 : le Pixel de l'émulateur, donc l'écran sur lequel
  /// un défaut ne se voit pas.
  const ecrans = <String, Size>{
    '320x640': Size(320, 640),
    '360x720': Size(360, 720),
    '411x923': Size(411, 923),
  };

  /// 1,0 est le réglage par défaut, 1,3 le deuxième cran d'Android (« Grande
  /// police »), 1,5 le troisième, 2,0 le dernier.
  const echelles = <double>[1.0, 1.3, 1.5, 2.0];

  /// La hauteur à laquelle la bande est verrouillée tant que la cible tactile
  /// la domine. Lue dans Flutter plutôt qu'écrite : c'est `kMinInteractiveDimension`
  /// qui la décide, et si le SDK la changeait, ce fichier devrait suivre et non
  /// mentir.
  const double plancherTactile = kMinInteractiveDimension;

  // ── La coque des véhicules, celle de `carte_geometrie_test.dart` ───────────

  Future<void> poserVehicules(
    WidgetTester tester, {
    required Size ecran,
    required double echelle,
    required List<Vehicle> vehicules,
    List<String> villes = const [],
  }) async {
    tester.view.physicalSize = ecran;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.binding.setSurfaceSize(ecran);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          authProvider.overrideWith(
            (_) => _FauxAuth(
              const AuthState(
                type: AuthType.staff,
                staffUser: StaffUser(
                  id: 1,
                  name: 'Administrateur',
                  email: 'admin@autoparc.bf',
                  role: 'admin',
                ),
              ),
            ),
          ),
          catalogRepositoryProvider.overrideWithValue(_Depot(vehicules)),
          catalogRefsProvider.overrideWith(
            (_) async => CatalogRefs(
              brands: const [],
              vehicleModels: const [],
              trims: const [],
              engineTypes: const [],
              drivetrains: const [],
              colors: const [],
              features: const [],
              locations: [
                for (var i = 0; i < villes.length; i++)
                  LocationRef(id: i + 1, name: 'Agence', city: villes[i]),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          theme: themeAutoParc(Brightness.light),
          home: MediaQuery(
            data: MediaQueryData(
              size: ecran,
              textScaler: TextScaler.linear(echelle),
              padding: const EdgeInsets.only(top: 24, bottom: 48),
              viewPadding: const EdgeInsets.only(top: 24, bottom: 48),
            ),
            child: const Scaffold(
              body: VehicleListPage(),
              bottomNavigationBar: BarreNavigationPrincipale(
                selectedIndex: 1,
                destinations: [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    label: 'Accueil',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.directions_car_outlined),
                    label: 'Véhicules',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.tune_outlined),
                    label: 'Accessoires',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    label: 'Pièces',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  // ── Les coques des pièces et des accessoires ──────────────────────────────

  PartCategory cat(int id, String nom, {int? parent, bool propres = false}) =>
      PartCategory(id: id, name: nom, parentId: parent, hasOwnParts: propres);

  /// Deux branches peuplées : il faut que les racines se partagent le catalogue
  /// pour que la bande des pièces propose quelque chose — `niveauDiscriminant`
  /// ne rend rien quand aucun niveau ne le partage.
  final deuxBranches = [
    cat(1, 'Moteur'),
    cat(2, 'Filtres', parent: 1),
    cat(3, 'Filtre à huile', parent: 2, propres: true),
    cat(24, 'Freinage'),
    cat(26, 'Plaquettes avant', parent: 24, propres: true),
  ];

  Future<void> poserPage(
    WidgetTester tester, {
    required Size ecran,
    required double echelle,
    required Widget page,
    required List<Override> surcharges,
  }) async {
    tester.view.physicalSize = ecran;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.binding.setSurfaceSize(ecran);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          authProvider.overrideWith(
            (_) => _FauxAuth(
              const AuthState(
                type: AuthType.staff,
                staffUser: StaffUser(
                  id: 1,
                  name: 'Administrateur',
                  email: 'admin@autoparc.bf',
                  role: 'admin',
                ),
              ),
            ),
          ),
          catalogRepositoryProvider.overrideWithValue(_Depot(const [])),
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
  }

  // ── Les outils de mesure ──────────────────────────────────────────────────

  /// La hauteur de chaque bande posée, LUE sur l'objet de rendu.
  List<double> hauteursDesBandes(WidgetTester tester) => tester
      .renderObjectList<RenderBox>(find.byType(BandeFiltres))
      .map((b) => b.size.height)
      .toList();

  /// La hauteur de la boîte de POINTAGE de chaque puce.
  ///
  /// C'est l'objet de rendu attaché à `FilterChip`, donc le
  /// `_RenderChipRedirectingHitDetection` de `chip.dart` : la zone qui reçoit
  /// réellement le doigt, et non la puce peinte.
  List<double> ciblesTactiles(WidgetTester tester) => tester
      .renderObjectList<RenderBox>(find.byType(FilterChip))
      .map((b) => b.size.height)
      .toList();

  /// La hauteur PEINTE de la première puce : son `Material`, c'est-à-dire le
  /// fond et la bordure que l'œil voit.
  double hauteurPeinte(WidgetTester tester) => tester
      .renderObject<RenderBox>(
        find
            .descendant(
              of: find.byType(FilterChip).first,
              matching: find.byType(Material),
            )
            .first,
      )
      .size
      .height;

  /// La largeur que ce paragraphe DEMANDE sur une seule ligne.
  double voulue(RenderParagraph p) => (TextPainter(
    text: p.text,
    textDirection: p.textDirection,
    textScaler: p.textScaler,
    maxLines: 1,
  )..layout()).width;

  /// Les lignes réellement posées par le `TextPainter` à la largeur reçue.
  int lignesPosees(RenderParagraph p) => (TextPainter(
    text: p.text,
    textDirection: p.textDirection,
    textScaler: p.textScaler,
  )..layout(maxWidth: p.constraints.maxWidth)).computeLineMetrics().length;

  // ── 1. LA CIBLE TACTILE, ET LA PREUVE QU'ELLE SE PERD ─────────────────────

  testWidgets('une bande de 44 points raboterait la cible tactile', (
    tester,
  ) async {
    // NON-VACUITÉ, et c'est le test qui donne leur sens à tous les autres. Si
    // le plancher de 48 points était acquis par construction, les assertions
    // ci-dessous ne protégeraient rien. Il ne l'est pas : la contrainte de
    // `minHeight` de `RawChip` est `enforce`ée par celle qu'il reçoit, donc une
    // bande plus courte que 48 points la rabote. C'est l'état EXACT des deux
    // bandes de la page des véhicules avant ce lot.
    await tester.pumpWidget(
      MaterialApp(
        theme: themeAutoParc(Brightness.light),
        home: Scaffold(
          body: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                FilterChip(label: const Text('À vendre'), onSelected: (_) {}),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      ciblesTactiles(tester).single,
      closeTo(44.0, 0.01),
      reason:
          'Une bande de 44 points ne rabote plus la cible tactile : le '
          'mécanisme a changé dans le SDK, et les assertions de 48 points de '
          'ce fichier ne mesurent plus rien.',
    );
    expect(
      ciblesTactiles(tester).single,
      lessThan(plancherTactile),
      reason: 'Le plancher Material ne vaut plus 48 points.',
    );
  });

  group('La cible tactile des puces', () {
    for (final ecran in ecrans.entries) {
      for (final echelle in echelles) {
        testWidgets('${ecran.key}, texte x$echelle : 48 points au moins', (
          tester,
        ) async {
          await poserVehicules(
            tester,
            ecran: ecran.value,
            echelle: echelle,
            vehicules: List.generate(4, (_) => vehicule()),
            villes: const ['Ouagadougou', 'Bobo-Dioulasso'],
          );

          final cibles = ciblesTactiles(tester);
          expect(cibles, isNotEmpty);

          for (final h in cibles) {
            expect(
              h,
              greaterThanOrEqualTo(plancherTactile - 0.01),
              reason:
                  'Une puce de filtre n\'offre que '
                  '${h.toStringAsFixed(1)} points de zone tapable en '
                  '${ecran.key} à l\'échelle $echelle, pour un plancher '
                  'Material de ${plancherTactile.toStringAsFixed(1)}. Une '
                  'puce est une cible tactile : c\'est le seul chiffre qui '
                  'peut faire refuser ce lot.',
            );
          }
        });
      }
    }
  });

  // ── 2. LA HAUTEUR DE LA BANDE, ET LE FAIT QU'ELLE EST LUE ─────────────────

  group('La hauteur de la bande', () {
    for (final ecran in ecrans.entries) {
      testWidgets('${ecran.key} : 48,0 jusqu\'à l\'échelle 1,5, puis elle '
          'grandit', (tester) async {
        for (final echelle in [1.0, 1.3, 1.5]) {
          await poserVehicules(
            tester,
            ecran: ecran.value,
            echelle: echelle,
            vehicules: List.generate(4, (_) => vehicule()),
          );

          // CHAQUE bande, et non « la » bande : la page des véhicules en porte
          // deux depuis que les carrosseries ont repris leur ligne. Mesurer
          // `.single` ne plantait pas seulement — il laissait la seconde
          // bande sans surveillance, c'est-à-dire libre de retomber à 44.
          for (final h in hauteursDesBandes(tester)) {
            expect(
              h,
              closeTo(plancherTactile, 0.01),
              reason:
                  'Une bande mesure ${h.toStringAsFixed(1)} points en '
                  '${ecran.key} à l\'échelle $echelle au lieu de '
                  '${plancherTactile.toStringAsFixed(1)}. Plus bas, la cible '
                  'tactile tombe avec elle ; plus haut, la liste perd de la '
                  'hauteur sans rien rendre.',
            );
          }
        }

        // À l'échelle 2,0 le libellé fait 40,0 points de haut : la puce en
        // réclame 52,0 avec son remplissage et sa bordure. La bande les lui
        // donne au lieu de l'écraser — les 44 points d'avant l'écrasaient dès
        // l'échelle 1,5.
        await poserVehicules(
          tester,
          ecran: ecran.value,
          echelle: 2.0,
          vehicules: List.generate(4, (_) => vehicule()),
        );

        for (final h in hauteursDesBandes(tester)) {
          expect(
            h,
            greaterThan(plancherTactile + 0.01),
            reason:
                'Une bande reste à ${h.toStringAsFixed(1)} points à '
                'l\'échelle 2,0 : elle impose de nouveau une hauteur, et le '
                'libellé de la puce est rogné dedans.',
          );
        }
      });
    }

    testWidgets('la puce PEINTE est plus mince que sa zone tapable', (
      tester,
    ) async {
      // CE QUI A ÉTÉ AMINCI, et c'est la demande du propriétaire. Material 3
      // donne aux puces un `EdgeInsets.all(8)` : 38,0 points peints à
      // l'échelle 1,0 et 44,0 à l'échelle 1,3, où la bande de 44 les écrasait
      // exactement. Le remplissage vertical de `BandeFiltres` les ramène à
      // 34,0 et 38,0 — mesurés — sans toucher à la zone tapable, qui reste à
      // 48,0. C'est la séparation que Material fait entre le peint et le
      // tapable, et elle passe par le `padding`, jamais par `visualDensity`,
      // qui est SOUSTRAIT du plancher de 48.
      for (final attendu in [(1.0, 34.0), (1.3, 38.0)]) {
        await poserVehicules(
          tester,
          ecran: const Size(360, 720),
          echelle: attendu.$1,
          vehicules: List.generate(2, (_) => vehicule()),
        );

        expect(
          hauteurPeinte(tester),
          closeTo(attendu.$2, 0.01),
          reason:
              'La puce est peinte sur '
              '${hauteurPeinte(tester).toStringAsFixed(1)} points à '
              'l\'échelle ${attendu.$1} au lieu de ${attendu.$2} : le '
              'remplissage de la bande a changé.',
        );
        expect(
          hauteurPeinte(tester),
          lessThan(ciblesTactiles(tester).first),
          reason:
              'La puce peinte remplit toute sa zone tapable : il n\'y a '
              'plus rien à amincir sans rogner ce qu\'on tape.',
        );
      }
    });
  });

  // ── 3. DEUX BANDES, ET LES QUATRE GROUPES DEDANS ──────────────────────────

  group('Les deux bandes des véhicules', () {
    testWidgets('il y en a deux, et elles portent les quatre groupes', (
      tester,
    ) async {
      // TROIS ÉTATS SE SONT SUCCÉDÉ, et le commentaire les garde parce que le
      // deuxième reviendra sur la table dès qu'on reparlera de densité :
      //
      //   deux bandes de 44 points — 88 au-dessus de la liste, et la cible
      //   tactile rabotée à 44 en silence, sous le plancher Material de 48 ;
      //   une seule bande de 48 — 40 points rendus, mais les onze carrosseries
      //   au bout d'un défilement horizontal ;
      //   deux bandes de 48 — 96 points, soit 8 de plus qu'à l'origine.
      //
      // Le propriétaire a tranché pour le troisième : les carrosseries se
      // voient sans geste. Ce qui est DÉFINITIVEMENT acquis des deux premiers
      // états, c'est la cible tactile — 48 points par bande, jamais 44.
      await poserVehicules(
        tester,
        ecran: const Size(360, 720),
        echelle: 1.0,
        vehicules: List.generate(2, (_) => vehicule()),
        villes: const ['Ouagadougou'],
      );

      expect(
        find.byType(BandeFiltres),
        findsNWidgets(2),
        reason:
            'La page des véhicules ne porte plus deux bandes : les onze '
            'carrosseries sont reparties derrière un défilement.',
      );

      for (final groupe in ['OFFRE', 'TYPE', 'VILLE', 'CARROSSERIE']) {
        expect(
          find.descendant(
            of: find.byType(BandeFiltres),
            matching: find.text(groupe),
          ),
          findsOneWidget,
          reason:
              'Le groupe « $groupe » a disparu des bandes : séparer les '
              'carrosseries ne devait rien retirer à l\'utilisateur.',
        );
      }

      // Les onze carrosseries sont toujours proposées, et c'est le point à
      // vérifier : elles ont changé de place, pas de nombre.
      for (final carrosserie in [
        'Berline',
        'SUV / 4×4',
        'Citadine',
        'Pickup',
        'Minibus',
        'Bus / Car',
        'Fourgon',
        'Break',
        'Camion',
        'Cabriolet',
        'Coupé',
      ]) {
        expect(
          find.widgetWithText(FilterChip, carrosserie),
          findsOneWidget,
          reason: 'La carrosserie « $carrosserie » n\'est plus proposée.',
        );
      }
    });

    testWidgets('une puce de carrosserie pose toujours son filtre', (
      tester,
    ) async {
      // La fusion a déplacé les puces d'un widget à l'autre ; leur effet ne
      // doit pas être resté dans l'ancien.
      await poserVehicules(
        tester,
        ecran: const Size(411, 923),
        echelle: 1.0,
        vehicules: List.generate(2, (_) => vehicule()),
      );

      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Berline'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilterChip, 'Berline'));
      await tester.pump();

      final portee = ProviderScope.containerOf(
        tester.element(find.byType(VehicleListPage)),
      );
      expect(
        portee.read(vehicleFilterProvider).bodyStyle,
        'sedan',
        reason: 'La puce de carrosserie ne pose plus son filtre.',
      );
    });
  });

  // ── 4. LES TROIS PAGES ENSEMBLE ───────────────────────────────────────────

  group('Les trois bandes du catalogue', () {
    for (final echelle in echelles) {
      testWidgets('pièces, texte x$echelle : même bande, même plancher', (
        tester,
      ) async {
        await poserPage(
          tester,
          ecran: const Size(320, 640),
          echelle: echelle,
          page: const PartListPage(),
          surcharges: [
            // Une liste PEUPLÉE, et pas par confort : l'écran « aucune pièce
            // trouvée » déborde de 2,0 points à 320 points d'écran et à
            // l'échelle 2,0 — un défaut qui lui est propre, antérieur à ce
            // lot (la bande des pièces mesurait déjà 48 points avant) et qui
            // n'a rien à voir avec ce que ce test mesure. Le mesurer ici
            // ferait échouer le test sur le mauvais objet.
            catalogRepositoryProvider.overrideWithValue(
              _Depot(const [], pieces: List.generate(4, (_) => _piece())),
            ),
            partCategoriesProvider.overrideWith((_) async => deuxBranches),
            categoriesAvecPiecesProvider.overrideWith(
              (_) async => deuxBranches,
            ),
          ],
        );

        expect(find.byType(BandeFiltres), findsOneWidget);
        expect(
          hauteursDesBandes(tester).single,
          greaterThanOrEqualTo(plancherTactile - 0.01),
        );
        for (final h in ciblesTactiles(tester)) {
          expect(
            h,
            greaterThanOrEqualTo(plancherTactile - 0.01),
            reason:
                'Une puce des pièces n\'offre que '
                '${h.toStringAsFixed(1)} points de zone tapable à l\'échelle '
                '$echelle.',
          );
        }
      });

      testWidgets('accessoires, texte x$echelle : même bande, même plancher', (
        tester,
      ) async {
        await poserPage(
          tester,
          ecran: const Size(320, 640),
          echelle: echelle,
          page: const AccessoryListPage(),
          surcharges: [
            catalogRepositoryProvider.overrideWithValue(
              _Depot(
                const [],
                accessoires: List.generate(4, (_) => _accessoire()),
              ),
            ),
            categoriesAccessoiresOccupeesProvider.overrideWith(
              (_) async => {'esthetique', 'confort', 'securite'},
            ),
          ],
        );

        expect(find.byType(BandeFiltres), findsOneWidget);
        expect(
          hauteursDesBandes(tester).single,
          greaterThanOrEqualTo(plancherTactile - 0.01),
        );
        for (final h in ciblesTactiles(tester)) {
          expect(
            h,
            greaterThanOrEqualTo(plancherTactile - 0.01),
            reason:
                'Une puce des accessoires n\'offre que '
                '${h.toStringAsFixed(1)} points de zone tapable à l\'échelle '
                '$echelle.',
          );
        }
      });
    }
  });

  // ── 5. AUCUN LIBELLÉ DE PUCE TRONQUÉ, SUR LES GLYPHES ─────────────────────

  group('Les libellés des puces', () {
    for (final ecran in ecrans.entries) {
      for (final echelle in echelles) {
        testWidgets('${ecran.key}, texte x$echelle : rien n\'est coupé', (
          tester,
        ) async {
          await poserVehicules(
            tester,
            ecran: ecran.value,
            echelle: echelle,
            vehicules: List.generate(4, (_) => vehicule()),
            villes: const ['Ouagadougou', 'Bobo-Dioulasso'],
          );

          final paragraphes = tester
              .renderObjectList<RenderParagraph>(
                find.descendant(
                  of: find.byType(BandeFiltres),
                  matching: find.byType(RichText),
                ),
              )
              .toList();
          expect(paragraphes, isNotEmpty);

          for (final p in paragraphes) {
            final texte = (p.text as TextSpan).toPlainText();
            // `didExceedMaxLines` est l'état que le `TextPainter` a réellement
            // constaté, et non une comparaison de largeurs reconstruite.
            expect(
              p.didExceedMaxLines,
              isFalse,
              reason:
                  '« $texte » est COUPÉ en ${ecran.key} à l\'échelle '
                  '$echelle : ${voulue(p).toStringAsFixed(1)} points voulus '
                  'pour ${p.constraints.maxWidth.toStringAsFixed(1)} reçus.',
            );
            expect(
              lignesPosees(p),
              1,
              reason:
                  '« $texte » est replié sur ${lignesPosees(p)} lignes '
                  'en ${ecran.key} à l\'échelle $echelle : une puce de '
                  'filtre sur deux lignes se lit comme un défaut.',
            );
          }

          // Les deux libellés nommés par la demande, vérifiés par leur nom et
          // pas seulement par le lot. `textContaining` pour « Bonne affaire » :
          // la puce y accole le nombre de promotions quand il y en a, et le
          // dépôt du banc en rend autant qu'il a de véhicules.
          expect(
            find.descendant(
              of: find.byType(BandeFiltres),
              matching: find.textContaining('Bonne affaire'),
            ),
            findsOneWidget,
            reason: '« Bonne affaire » a disparu de la bande.',
          );
          expect(
            find.descendant(
              of: find.byType(BandeFiltres),
              matching: find.text('SUV / 4×4'),
            ),
            findsOneWidget,
            reason: '« SUV / 4×4 » a disparu de la bande.',
          );
        });
      }
    }
  });

  // ── 6a. LE LIBELLÉ DE NAVIGATION QUI SE CASSAIT EN DEUX ───────────────────

  group('Les intitulés de la barre de navigation', () {
    /// La barre seule, à la largeur demandée.
    Future<void> poserBarre(
      WidgetTester tester, {
      required Size ecran,
      required double echelle,
      required bool bornee,
    }) async {
      tester.view.physicalSize = ecran;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.binding.setSurfaceSize(ecran);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const destinations = [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          label: 'Accueil',
        ),
        NavigationDestination(
          icon: Icon(Icons.directions_car_outlined),
          label: 'Véhicules',
        ),
        NavigationDestination(
          icon: Icon(Icons.tune_outlined),
          label: 'Accessoires',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          label: 'Pièces',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: themeAutoParc(Brightness.light),
          home: MediaQuery(
            data: MediaQueryData(
              size: ecran,
              textScaler: TextScaler.linear(echelle),
            ),
            child: Builder(
              builder: (context) => Scaffold(
                body: const SizedBox.shrink(),
                bottomNavigationBar: bornee
                    ? const BarreNavigationPrincipale(
                        selectedIndex: 1,
                        destinations: destinations,
                      )
                    // L'état d'AVANT, reconstruit : l'habillage sans la borne.
                    : Theme(
                        data: Theme.of(context).copyWith(
                          navigationBarTheme: barreNavigationTheme(
                            Theme.of(context).colorScheme,
                          ),
                        ),
                        child: NavigationBar(
                          selectedIndex: 1,
                          labelBehavior:
                              NavigationDestinationLabelBehavior.alwaysShow,
                          destinations: destinations,
                        ),
                      ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('« Accessoires » se cassait bien en deux sans la borne', (
      tester,
    ) async {
      // NON-VACUITÉ. Le défaut vient d'une capture à 320 points et à l'échelle
      // 1,3 : « Accessoires » réclame 87,7 points pour les 80,0 que sa
      // destination reçoit. Si ce test passait au vert, la borne ne corrigerait
      // rien et pourrait être retirée.
      await poserBarre(
        tester,
        ecran: const Size(320, 640),
        echelle: 1.3,
        bornee: false,
      );

      final p = tester.renderObject<RenderParagraph>(
        find
            .descendant(
              of: find.byType(NavigationBar),
              matching: find.text('Accessoires'),
            )
            .first,
      );

      expect(
        lignesPosees(p),
        2,
        reason:
            '« Accessoires » tient désormais sur une ligne SANS la borne '
            '(${voulue(p).toStringAsFixed(1)} points voulus pour '
            '${p.constraints.maxWidth.toStringAsFixed(1)} reçus) : le défaut '
            'a disparu autrement, et la borne d\'échelle n\'a plus de raison '
            'd\'être.',
      );
    });

    for (final ecran in ecrans.entries) {
      for (final echelle in echelles) {
        testWidgets(
          '${ecran.key}, texte x$echelle : les quatre sur une ligne',
          (tester) async {
            await poserBarre(
              tester,
              ecran: ecran.value,
              echelle: echelle,
              bornee: true,
            );

            for (final nom in [
              'Accueil',
              'Véhicules',
              'Accessoires',
              'Pièces',
            ]) {
              final p = tester.renderObject<RenderParagraph>(
                find
                    .descendant(
                      of: find.byType(NavigationBar),
                      matching: find.text(nom),
                    )
                    .first,
              );

              expect(
                lignesPosees(p),
                1,
                reason:
                    '« $nom » est replié sur ${lignesPosees(p)} lignes en '
                    '${ecran.key} à l\'échelle $echelle : '
                    '${voulue(p).toStringAsFixed(1)} points voulus pour '
                    '${p.constraints.maxWidth.toStringAsFixed(1)} reçus. Un '
                    'intitulé de navigation cassé en deux a l\'air d\'un bug.',
              );
              expect(
                p.didExceedMaxLines,
                isFalse,
                reason:
                    '« $nom » est ellipsé en ${ecran.key} à l\'échelle '
                    '$echelle.',
              );
            }
          },
        );
      }
    }
  });

  // ── 6b. LE BOUTON FLOTTANT QUI RECOUVRAIT LA DEUXIÈME CARTE ───────────────

  group('Le bouton flottant', () {
    /// Le facteur d'échelle du bouton, LU dans l'`AnimatedScale` de
    /// `BoutonFlottantEffacable` — la carte du catalogue en porte un aussi, d'où
    /// la descendance explicite.
    double echelleDuBouton(WidgetTester tester) => tester
        .widget<AnimatedScale>(
          find
              .descendant(
                of: find.byType(BoutonFlottantEffacable),
                matching: find.byType(AnimatedScale),
              )
              .first,
        )
        .scale;

    testWidgets('il recouvrait la deuxième carte, et c\'est mesuré', (
      tester,
    ) async {
      // LE DÉFAUT, à la configuration de la capture du propriétaire : 320
      // points, échelle 1,3. Le bouton fait 128,1 × 56,0 points et le
      // `Scaffold` le pose à 16 du bas du corps. Ce test NE PRÉTEND PAS que le
      // recouvrement au repos a disparu — il n'a pas disparu, et c'est écrit
      // dans `BoutonFlottantEffacable`. Il verrouille le chiffre, pour que
      // personne ne croie le contraire sur la foi du lot.
      await poserVehicules(
        tester,
        ecran: const Size(320, 640),
        echelle: 1.3,
        vehicules: List.generate(8, (_) => vehicule()),
      );

      final bouton = tester.renderObject<RenderBox>(
        find.byType(FloatingActionButton).first,
      );
      final hautBouton = bouton.localToGlobal(Offset.zero).dy;
      final gaucheBouton = bouton.localToGlobal(Offset.zero).dx;

      final cartes = tester
          .renderObjectList<RenderBox>(find.byType(VehicleCard))
          .toList();
      expect(cartes.length, greaterThanOrEqualTo(2));

      // LA DEUXIÈME CARTE SE DÉSIGNE PAR SA POSITION, ET PLUS PAR SON RANG DANS
      // L'ARBRE. La grille était un `SliverList` de rangées, donc l'ordre de
      // parcours était l'ordre de lecture et `cartes[1]` était la carte en haut
      // à DROITE — celle que le bouton mord. Depuis la maçonnerie l'arbre porte
      // la colonne de gauche entière avant celle de droite : `cartes[1]` y
      // désignait la deuxième carte de la colonne GAUCHE, qui est à 155,0 points
      // du bord droit quand le bouton commence à 175,9, et le test tombait en
      // disant le contraire de ce qu'il voulait dire. Trié par ordonnée puis par
      // abscisse, le rang 1 redevient l'ordre de lecture.
      cartes.sort((a, b) {
        final da = a.localToGlobal(Offset.zero);
        final db = b.localToGlobal(Offset.zero);
        return da.dy != db.dy ? da.dy.compareTo(db.dy) : da.dx.compareTo(db.dx);
      });

      final deuxieme = cartes[1];
      final basDeuxieme = deuxieme
          .localToGlobal(Offset(0, deuxieme.size.height))
          .dy;
      final droiteDeuxieme = deuxieme
          .localToGlobal(Offset(deuxieme.size.width, 0))
          .dx;

      expect(
        basDeuxieme,
        greaterThan(hautBouton),
        reason:
            'Le bouton ne mord plus sur la deuxième carte au repos : '
            'tant mieux, mais c\'est un changement de géométrie à constater '
            'et à redire, pas un test à laisser mentir.',
      );
      expect(droiteDeuxieme, greaterThan(gaucheBouton));
    });

    testWidgets('il s\'efface quand on descend la liste et revient quand on '
        'remonte', (tester) async {
      await poserVehicules(
        tester,
        ecran: const Size(320, 640),
        echelle: 1.3,
        vehicules: List.generate(8, (_) => vehicule()),
      );

      expect(
        echelleDuBouton(tester),
        1.0,
        reason: 'Le bouton est déjà effacé avant tout geste.',
      );

      // Un glissement vers le HAUT descend la liste : c'est le geste qui doit
      // dégager le prix que le bouton couvrait.
      await tester.drag(find.byType(VehicleGrid), const Offset(0, -120));
      await tester.pumpAndSettle();

      expect(
        echelleDuBouton(tester),
        0.0,
        reason:
            'Le bouton reste en place quand on descend la liste : il '
            'continue de couvrir la carte sous lui.',
      );

      // Et il doit revenir, sinon l\'action d\'ajout devient introuvable.
      await tester.drag(find.byType(VehicleGrid), const Offset(0, 120));
      await tester.pumpAndSettle();

      expect(
        echelleDuBouton(tester),
        1.0,
        reason:
            'Le bouton ne revient pas quand on remonte : l\'action '
            'd\'ajout est devenue introuvable.',
      );
    });

    testWidgets('effacé, il ne répond plus au doigt', (tester) async {
      // Une échelle nulle ne retire pas la boîte du pointage : sans
      // `IgnorePointer`, un bouton invisible ouvrirait quand même le
      // formulaire d'ajout — pire que le recouvrement qu'on corrige.
      await poserVehicules(
        tester,
        ecran: const Size(320, 640),
        echelle: 1.3,
        vehicules: List.generate(8, (_) => vehicule()),
      );

      await tester.drag(find.byType(VehicleGrid), const Offset(0, -120));
      await tester.pumpAndSettle();

      final ignore = tester.widget<IgnorePointer>(
        find
            .descendant(
              of: find.byType(BoutonFlottantEffacable),
              matching: find.byType(IgnorePointer),
            )
            .first,
      );
      expect(
        ignore.ignoring,
        isTrue,
        reason: 'Le bouton effacé reçoit encore le doigt.',
      );
    });

    /// Le bas de la dernière carte, une fois la liste poussée en butée, contre
    /// le haut du bouton flottant.
    ///
    /// LE DÉGAGEMENT DE BAS DE LISTE. La liste des véhicules l'avait — 88
    /// points —, les pièces et les accessoires NON : leur dernière carte
    /// finissait sous le bouton sans qu'aucun défilement ne puisse l'en sortir.
    Future<void> verifierDegagement(
      WidgetTester tester, {
      required Finder liste,
      required Finder cartes,
      required String quoi,
    }) async {
      final bouton = tester.renderObject<RenderBox>(
        find.byType(FloatingActionButton).first,
      );
      final hautBouton = bouton.localToGlobal(Offset.zero).dy;

      // Jusqu'à la butée : plusieurs glissements, le constructeur étant
      // paresseux et la liste pouvant s'allonger à mesure.
      for (var i = 0; i < 12; i++) {
        await tester.drag(liste, const Offset(0, -400));
        await tester.pumpAndSettle();
      }

      final boites = tester.renderObjectList<RenderBox>(cartes).toList();
      expect(boites, isNotEmpty, reason: '$quoi : aucune carte posée.');
      final basDerniere = boites
          .map((c) => c.localToGlobal(Offset(0, c.size.height)).dy)
          .reduce((a, b) => a > b ? a : b);

      expect(
        basDerniere,
        lessThanOrEqualTo(hautBouton + 0.01),
        reason:
            '$quoi : en butée de liste, la dernière carte descend encore '
            'à ${basDerniere.toStringAsFixed(1)} alors que le bouton '
            'commence à ${hautBouton.toStringAsFixed(1)}. Le dégagement de '
            'bas de liste manque ou ne suffit plus.',
      );
    }

    testWidgets('la dernière annonce se dégage du bouton', (tester) async {
      await poserVehicules(
        tester,
        ecran: const Size(320, 640),
        echelle: 1.3,
        vehicules: List.generate(8, (_) => vehicule()),
      );

      await verifierDegagement(
        tester,
        liste: find.byType(VehicleGrid),
        cartes: find.byType(VehicleCard),
        quoi: 'Véhicules',
      );
    });

    testWidgets('la dernière pièce se dégage du bouton', (tester) async {
      await poserPage(
        tester,
        ecran: const Size(320, 640),
        echelle: 1.3,
        page: const PartListPage(),
        surcharges: [
          catalogRepositoryProvider.overrideWithValue(
            _Depot(const [], pieces: List.generate(8, (_) => _piece())),
          ),
          partCategoriesProvider.overrideWith((_) async => deuxBranches),
          categoriesAvecPiecesProvider.overrideWith((_) async => deuxBranches),
        ],
      );

      await verifierDegagement(
        tester,
        liste: find.byType(CustomScrollView),
        cartes: find.byType(Card),
        quoi: 'Pièces',
      );
    });

    testWidgets('le dernier accessoire se dégage du bouton', (tester) async {
      await poserPage(
        tester,
        ecran: const Size(320, 640),
        echelle: 1.3,
        page: const AccessoryListPage(),
        surcharges: [
          catalogRepositoryProvider.overrideWithValue(
            _Depot(
              const [],
              accessoires: List.generate(8, (_) => _accessoire()),
            ),
          ),
          categoriesAccessoiresOccupeesProvider.overrideWith(
            (_) async => {'esthetique', 'confort'},
          ),
        ],
      );

      await verifierDegagement(
        tester,
        liste: find.byType(CustomScrollView),
        cartes: find.byType(Card),
        quoi: 'Accessoires',
      );
    });
  });
}

/// Une pièce et un accessoire tirés des gabarits du serveur : les listes des
/// pièces et des accessoires doivent porter de VRAIES cartes pour que la mesure
/// du dégagement de bas de liste veuille dire quelque chose.
Part _piece() => Part.fromJson(
  (jsonDecode(File('test/fixtures/parts_list.json').readAsStringSync())
          as Map<String, dynamic>)['data'][0]
      as Map<String, dynamic>,
);

Accessory _accessoire() => Accessory.fromJson(
  (jsonDecode(File('test/fixtures/accessories_list.json').readAsStringSync())
          as Map<String, dynamic>)['data'][0]
      as Map<String, dynamic>,
);

/// Un dépôt qui rend des listes fixées, sans réseau.
class _Depot implements CatalogRepository {
  _Depot(this.liste, {this.pieces = const [], this.accessoires = const []});
  final List<Vehicle> liste;
  final List<Part> pieces;
  final List<Accessory> accessoires;

  @override
  Future<PaginatedResponse<Part>> getParts({
    int page = 1,
    int perPage = 20,
    String? search,
    String? oem,
    int? categoryId,
    String? type,
    String? condition,
    bool inStockOnly = false,
    double? priceMax,
    int? vehicleModelId,
    int? year,
    String? city,
    int? locationId,
  }) async => PaginatedResponse<Part>(
    data: pieces,
    currentPage: 1,
    lastPage: 1,
    total: pieces.length,
    perPage: perPage,
  );

  @override
  Future<PaginatedResponse<Accessory>> getAccessories({
    int page = 1,
    int perPage = 20,
    String? search,
    String? category,
    String? manufacturerId,
    double? priceMax,
    int? vehicleModelId,
    String? city,
    int? locationId,
  }) async => PaginatedResponse<Accessory>(
    data: accessoires,
    currentPage: 1,
    lastPage: 1,
    total: accessoires.length,
    perPage: perPage,
  );

  @override
  Future<PaginatedResponse<Vehicle>> getVehicles({
    int page = 1,
    int perPage = 20,
    String? search,
    String? availability,
    String? vehicleType,
    String? bodyStyle,
    String? brandId,
    int? yearMin,
    int? yearMax,
    double? priceMax,
    String? condition,
    String? originCountryId,
    String? city,
    int? locationId,
    bool? customsCleared,
    bool? deal,
  }) async => PaginatedResponse<Vehicle>(
    data: liste,
    currentPage: 1,
    lastPage: 1,
    total: liste.length,
    perPage: perPage,
  );

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

/// Une session figée, sans Firebase : le vrai `AuthNotifier` s'y abonne dès son
/// constructeur, ce qu'un banc d'essai ne peut pas satisfaire.
class _FauxAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FauxAuth(super.etat);

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

/// Charge Roboto et les icônes Material depuis le cache du SDK.
///
/// Sans elles le banc peint chaque caractère comme un carré du corps du texte,
/// et toutes les largeurs de ce fichier seraient fausses — et vertes.
