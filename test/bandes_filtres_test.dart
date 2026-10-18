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

import 'package:auto/core/utils/currency_format.dart';
import 'package:auto/features/catalog/presentation/widgets/ligne_compatibilite.dart';
import 'package:auto/l10n/app_localizations.dart';

import 'support/langues.dart';
import 'support/mesures.dart';
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
///
/// 7. LES DEUX LANGUES, depuis le lot de traduction. La barre du bas est de la
///    coque, donc traduite, et c'est elle qui portait le défaut du point 6 : la
///    borne d'échelle de `BarreNavigationPrincipale` a été calculée sur des
///    intitulés FRANÇAIS, et rien ne garantissait a priori qu'un intitulé
///    anglais tienne dans les mêmes 80,0 points. Les libellés ne sont plus
///    recopiés dans ce fichier : ils sont LUS dans `AppLocalizations`, donc
///    dans l'`.arb` que l'application sert — un banc qui réécrirait
///    « Vehicles » à la main resterait vert le jour où la traduction change.
///    Le suffixe du tarif de location a rejoint ce point : `formatXofShort`
///    suivait la langue, le « /j » collé derrière restait en dur.
///
/// 8. LA LIGNE DE COMPATIBILITÉ DES CARTES, et son « +N ». C'est la seule
///    section qui mesure le CONTENU d'une carte plutôt que la bande au-dessus,
///    et elle est ici parce que ce fichier portait déjà les deux coques — la
///    liste des pièces et celle des accessoires, peuplées de vraies cartes —
///    que la mesure demande. En créer un troisième banc aurait voulu dire une
///    troisième copie de ces coques, et `support/polices.dart` raconte ce que
///    quatre copies de la même fonction ont coûté. Son commentaire de groupe
///    porte le tableau de densité avant/après, et les trois cases qui perdent
///    une rangée.
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

  /// La coque des véhicules.
  ///
  /// [locale] vaut le français par DÉFAUT, et non par commodité : c'est la
  /// langue que mesuraient les tableaux avant le lot de traduction, et leurs
  /// chiffres sont écrits dans les raisons d'échec. Les cases anglaises la
  /// passent explicitement.
  Future<void> poserVehicules(
    WidgetTester tester, {
    required Size ecran,
    required double echelle,
    required List<Vehicle> vehicules,
    List<String> villes = const [],
    Locale locale = localeFr,
  }) async {
    // Le format des montants est un réglage de module, posé par
    // `AutoParcApp.build` dans l'application. Un banc qui monte son propre
    // `MaterialApp` doit donc le poser lui-même, sinon il mesure une page
    // anglaise avec des prix français — « 99 999 999 FCFA » sous un titre
    // « Vehicles ». Le groupe « Le prix suit la langue » plus bas refuse
    // qu'on l'oublie.
    definirLocaleMontants(locale);

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
            // Les quatre intitulés sont LUS dans les traductions, comme
            // `_AppShell` les lit. La version précédente les recopiait, et
            // c'est ce que le point 7 de l'en-tête reproche.
            child: Builder(
              builder: (context) => Scaffold(
                body: const VehicleListPage(),
                bottomNavigationBar: BarreNavigationPrincipale(
                  selectedIndex: 1,
                  destinations: [
                    for (final d in _destinations(AppLocalizations.of(context)))
                      NavigationDestination(icon: Icon(d.icone), label: d.nom),
                  ],
                ),
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
    Locale locale = localeFr,

    /// Ajoute la barre de navigation du bas, c'est-à-dire la COQUE COMPLÈTE.
    ///
    /// Faux par défaut, et ce défaut est celui de l'historique : les sections 1
    /// à 6 mesurent la bande de filtres et le dégagement du bouton flottant,
    /// qui vivent tous deux dans le `Scaffold` de la page et ne dépendent pas
    /// de ce que la coque prend en bas. Leurs chiffres sont écrits dans leurs
    /// raisons d'échec, et les rendre tous faux pour une symétrie de coque
    /// n'aurait rien mesuré de plus.
    ///
    /// La section 8, elle, compte des CARTES ENTIÈREMENT VISIBLES. Une page
    /// montée sans sa barre du bas lui donne 112 points de plus que
    /// l'application — c'est le défaut que `captures_catalogue_test.dart`
    /// raconte en tête de fichier —, donc un tableau de densité mesuré ainsi
    /// décrirait un téléphone qui n'existe pas.
    bool barreDuBas = false,

    /// La session montée. Le PERSONNEL par défaut, comme tout ce fichier.
    ///
    /// La section 8 monte aussi un CLIENT, mais sur la liste des accessoires
    /// seulement, et la raison n'est pas un oubli : `part_list_page.dart`
    /// insère `_GarageFilterBanner` sous `if (!isStaff)`, et cet état lit ses
    /// notifiers dans `deactivate()` pour écrire APRÈS la trame. Un banc qui
    /// démonte le `ProviderScope` écrit alors dans un conteneur déjà jeté et
    /// lève « Tried to use StateController after dispose ».
    /// `accueil_langues_test.dart` porte le même avertissement, avec la raison
    /// pour laquelle ce n'est PAS un défaut de production : dans
    /// l'application, le `ProviderScope` est la racine et vit aussi longtemps
    /// que le processus.
    AuthState session = const AuthState(
      type: AuthType.staff,
      staffUser: StaffUser(
        id: 1,
        name: 'Administrateur',
        email: 'admin@autoparc.bf',
        role: 'admin',
      ),
    ),
  }) async {
    definirLocaleMontants(locale);

    tester.view.physicalSize = ecran;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.binding.setSurfaceSize(ecran);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          authProvider.overrideWith((_) => _FauxAuth(session)),
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
            child: barreDuBas
                ? Builder(
                    builder: (context) => Scaffold(
                      body: page,
                      bottomNavigationBar: BarreNavigationPrincipale(
                        // L'onglet des pièces : c'est la page que la section 8
                        // mesure le plus souvent, et l'onglet actif ne change
                        // pas la hauteur de la barre.
                        selectedIndex: 3,
                        destinations: [
                          for (final d in _destinations(
                            AppLocalizations.of(context),
                          ))
                            NavigationDestination(
                              icon: Icon(d.icone),
                              label: d.nom,
                            ),
                        ],
                      ),
                    ),
                  )
                : page,
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

  // `voulue`, `recue`, `motLePlusLarge`, `peint`, `texteDe` et `lignesPosees`
  // ne sont plus recopiées ici : elles viennent de `support/mesures.dart`.
  // Ce fichier en portait deux en propre, et l'en-tête de `mesures.dart`
  // posait la condition de la migration — « le lot qui touchera l'un des deux
  // pour une autre raison devra les faire passer par ici ». C'est ce lot : il
  // ajoute la section 8 ci-dessous, qui mesure les cartes du catalogue.

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
        for (final langue in langues.entries) {
        testWidgets(
            '${ecran.key}, texte x$echelle, ${langue.key} : rien n\'est coupé',
            (
          tester,
        ) async {
          await poserVehicules(
            tester,
            ecran: ecran.value,
            echelle: echelle,
            vehicules: List.generate(4, (_) => vehicule()),
            villes: const ['Ouagadougou', 'Bobo-Dioulasso'],
            locale: langue.value,
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
    }
  });

  // ── 6a. LE LIBELLÉ DE NAVIGATION QUI SE CASSAIT EN DEUX ───────────────────

  group('Les intitulés de la barre de navigation', () {
    /// La barre seule, à la largeur demandée et dans la langue demandée.
    ///
    /// Les quatre intitulés viennent de `AppLocalizations`, donc des `.arb` :
    /// ce banc mesure ce que l'application affiche, et non une copie qui
    /// resterait verte après un changement de traduction.
    Future<void> poserBarre(
      WidgetTester tester, {
      required Size ecran,
      required double echelle,
      required bool bornee,
      required Locale locale,
    }) async {
      tester.view.physicalSize = ecran;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.binding.setSurfaceSize(ecran);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: themeAutoParc(Brightness.light),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(
              size: ecran,
              textScaler: TextScaler.linear(echelle),
            ),
            child: Builder(
              builder: (context) {
                final destinations = [
                  for (final d in _destinations(AppLocalizations.of(context)))
                    NavigationDestination(
                      icon: Icon(d.icone),
                      label: d.nom,
                    ),
                ];

                return Scaffold(
                  body: const SizedBox.shrink(),
                  bottomNavigationBar: bornee
                      ? BarreNavigationPrincipale(
                          selectedIndex: 1,
                          destinations: destinations,
                        )
                      // L'état d'AVANT, reconstruit : l'habillage sans la
                      // borne.
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
                );
              },
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
        locale: localeFr,
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
        for (final langue in langues.entries) {
        testWidgets(
          '${ecran.key}, texte x$echelle, ${langue.key} : les quatre sur une '
          'ligne',
          (tester) async {
            await poserBarre(
              tester,
              ecran: ecran.value,
              echelle: echelle,
              bornee: true,
              locale: langue.value,
            );

            // Les quatre noms ATTENDUS, lus dans la traduction et non
            // recopiés : c'est ce qui fait que ce test mesure l'anglais
            // réellement servi plutôt qu'une copie.
            //
            // L'ANGLAIS N'EST PAS PLUS COURT SUR LE LIBELLÉ QUI COMPTE.
            // Mesuré à 320 points et à l'échelle 1,3, en points de largeur
            // demandée :
            //
            //                          fr      en
            //   Accueil / Home       46,8    38,1
            //   Véhicules / Vehicles 62,9    55,0
            //   Accessoires / Access… 77,9    78,1   ← l'anglais est PLUS large
            //   Pièces / Parts       42,5    34,0
            //
            // « Accessories » porte les mêmes lettres que « Accessoires »,
            // « ir » et « ri » permutées, et sort néanmoins 0,13 point plus
            // large. C'est le libellé déjà le plus serré des quatre : le test
            // « la marge des intitulés » ci-dessous verrouille ce qu'il reste.
            final textes = await chargerTextes(langue.value);
            for (final nom in [
              textes.commonHome,
              textes.commonVehicles,
              textes.commonAccessories,
              textes.commonParts,
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
                    '$echelle, en ${langue.key}.',
              );
            }
          },
        );
        }
      }
    }
    testWidgets('la marge des intitulés de navigation, dans les deux langues', (
      tester,
    ) async {
      // LA BORNE D'ÉCHELLE DE 1,15 A ÉTÉ CALCULÉE SUR LE FRANÇAIS. Elle vient
      // d'une mesure : « Accessoires » demandait 68,1 points à l'échelle 1,0
      // pour les 80,0 que sa destination reçoit, donc le rapport qui le fait
      // déborder vaut 1,174, et la borne est posée juste en dessous.
      //
      // Rien ne garantissait qu'un intitulé ANGLAIS tînt dans la même marge, et
      // la première version de ce test, qui exigeait « l'anglais ne demande pas
      // plus que le français », est tombée : « Accessories » demande 78,06
      // points contre 77,93 pour « Accessoires ». Les deux tiennent — c'est le
      // tableau au-dessus qui le dit —, mais la marge qui reste est de DEUX
      // POINTS, et c'est elle qu'un lot de traduction peut manger sans s'en
      // apercevoir.
      //
      // Ce test verrouille donc la marge et non la comparaison des deux
      // langues. Mesuré à 320 points et à l'échelle 1,3 : 2,07 points en
      // français, 1,94 en anglais. Le plancher est posé à 1,0 — assez bas pour
      // ne pas tomber sur une révision de métriques de police, assez haut pour
      // refuser un intitulé plus long d'un seul caractère.
      const plancherMarge = 1.0;

      for (final langue in langues.entries) {
        await poserBarre(
          tester,
          ecran: const Size(320, 640),
          echelle: 1.3,
          bornee: true,
          locale: langue.value,
        );

        final textes = await chargerTextes(langue.value);

        for (final nom in [
          textes.commonHome,
          textes.commonVehicles,
          textes.commonAccessories,
          textes.commonParts,
        ]) {
          final p = tester.renderObject<RenderParagraph>(
            find
                .descendant(
                  of: find.byType(NavigationBar),
                  matching: find.text(nom),
                )
                .first,
          );

          final marge = p.constraints.maxWidth - voulue(p);

          expect(
            marge,
            greaterThanOrEqualTo(plancherMarge),
            reason:
                '« $nom » (${langue.key}) ne laisse que '
                '${marge.toStringAsFixed(2)} point(s) de marge à 320 points et '
                'à l\'échelle 1,3 : ${voulue(p).toStringAsFixed(2)} demandés '
                'pour ${p.constraints.maxWidth.toStringAsFixed(1)} reçus. La '
                'borne d\'échelle de `BarreNavigationPrincipale` a été calculée '
                'sur le français, et il n\'y avait déjà que 2 points de marge. '
                'Un intitulé plus long rouvre le défaut des deux lignes, qui '
                'est celui de la capture du propriétaire.',
          );
        }
      }
    });
  });

  // ── 7. LE PRIX SUIT LA LANGUE, ET LE BANC REFUSE QU'ON L'OUBLIE ──────────

  /// Le format des montants est un réglage de MODULE, posé par
  /// `AutoParcApp.build` dans l'application et par la coque dans ce banc. Une
  /// coque qui l'oublierait mesurerait une page anglaise avec des prix
  /// français, sans que rien ne le signale : les largeurs seraient fausses, et
  /// les tests verts. C'est le même piège que la police de repli.
  group('Le prix suit la langue', () {
    testWidgets('la carte écrit la ponctuation de la langue montée', (
      tester,
    ) async {
      for (final langue in langues.entries) {
        await poserVehicules(
          tester,
          ecran: const Size(411, 923),
          echelle: 1.0,
          vehicules: [vehicule()],
          locale: langue.value,
        );

        final peint =
            (tester
                        .renderObject<RenderParagraph>(
                          find.textContaining('FCFA').first,
                        )
                        .text
                    as TextSpan)
                .toPlainText();

        // 99 999 999 : le prix du gabarit. Le français groupe par une espace
        // fine insécable U+202F, l'anglais par une virgule — mesuré sur
        // `intl` 0.20.3, pas déduit.
        final attendu = langue.value == localeEn
            ? '99,999,999'
            : '99\u202F999\u202F999';

        expect(
          peint,
          contains(attendu),
          reason:
              'La carte écrit « $peint » alors que la coque est montée en '
              '${langue.key} : `definirLocaleMontants` n\'a pas suivi, et '
              'toutes les largeurs de prix de ce fichier et de '
              'carte_geometrie_test.dart mesurent la mauvaise langue.',
        );
      }
    });

    testWidgets('le suffixe du tarif de location suit la langue, lui aussi', (
      tester,
    ) async {
      // LE DÉFAUT CORRIGÉ. `formatXofShort` est passé à la locale active au lot
      // de traduction ; le « /j » collé derrière, dans `_PriceRow` de
      // `vehicle_list_page.dart`, est resté EN DUR. Un anglophone lisait donc
      // « 25,000 FCFA/j » : le nombre traduit, l'unité non. La clé
      // `commonPerDaySuffix` existait déjà — la tuile de la vitrine de
      // l'accueil l'employait depuis le même lot —, ce site-ci avait seulement
      // été oublié.
      //
      // LE SUFFIXE EST LU DANS `AppLocalizations`, et non recopié : « /day »
      // écrit à la main ici resterait vert le jour où la traduction change,
      // c'est-à-dire le jour où ce test doit tomber.
      //
      // La fiche de détail est passée à la MÊME clé dans le même lot : elle
      // écrivait « 25 000 FCFA / jour », donc une seconde forme du même tarif.
      // Le commentaire sur place porte les 32,34 points que le français y perd.
      final json = jsonDecode(jsonEncode(gabarit)) as Map<String, dynamic>;
      final com = json['commercial'] as Map<String, dynamic>;
      com['availability'] = 'rent';
      com['sale_price'] = null;
      com['rental_daily_rate'] = '25000.00';
      json['media'] = <dynamic>[];
      final loueur = Vehicle.fromJson(json);

      for (final langue in langues.entries) {
        await poserVehicules(
          tester,
          ecran: const Size(411, 923),
          echelle: 1.0,
          vehicules: [loueur],
          locale: langue.value,
        );

        final suffixe = (await chargerTextes(langue.value)).commonPerDaySuffix;

        final peint =
            (tester
                        .renderObject<RenderParagraph>(
                          find.textContaining('FCFA').first,
                        )
                        .text
                    as TextSpan)
                .toPlainText();

        expect(
          peint.endsWith(suffixe),
          isTrue,
          reason:
              'La carte écrit « $peint » en ${langue.key}, qui ne finit pas '
              'par « $suffixe » : le suffixe du tarif journalier ne suit plus '
              'la langue. C\'est le défaut exact qu\'un relecteur a relevé — '
              'un montant traduit derrière une unité qui ne l\'est pas.',
        );
      }
    });
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

  // ── 8. LA LIGNE DE COMPATIBILITÉ DES CARTES ───────────────────────────────

  /// LES MODÈLES COMPATIBLES SUR LA CARTE D'UNE PIÈCE ET D'UN ACCESSOIRE.
  ///
  /// Demande du propriétaire : savoir à quoi un article se destine sans ouvrir
  /// sa fiche. Deux lignes au plus, la suite tronquée, et le nombre de modèles
  /// NON affichés compté à côté — « Corolla · Tucson · Rio  +9 ».
  ///
  /// ── LE MODÈLE SEUL, SANS LA MARQUE, ET CE QUE ÇA A RENDU ─────────────────
  ///
  /// La ligne a d'abord porté « Toyota Corolla · Hyundai Tucson · Kia Rio ».
  /// Le propriétaire a tranché pour le modèle nu après avoir vu la première
  /// mesure, et le tableau [nomsPeints] plus bas garde les deux colonnes : à
  /// trois noms de marque-plus-modèle, la carte n'en affichait les trois que
  /// dans 3 cases sur 12 et montrait surtout un « +N ». Le serveur compose
  /// désormais `vehicleModel?->name` seul — `PartResource` et
  /// `AccessoryResource`, qui portent sur place le risque assumé : deux
  /// marques pourraient nommer un modèle pareillement, et le `unique()` les
  /// confondrait, « +N » comprise.
  ///
  /// ── CE QUE CE GROUPE EXISTE POUR EMPÊCHER ─────────────────────────────────
  ///
  /// 1. UN « +N » FAUX D'UNE UNITÉ. Le serveur plafonne `vehicles` à trois noms
  ///    et rend le total dans `count`. Un compte calculé sur `count - 3` est
  ///    donc faux dès que la carte n'affiche que deux noms, ce qui arrive aux
  ///    grandes échelles de texte. Le test compare le compte PEINT au nombre de
  ///    noms PEINTS, case par case : c'est la seule forme qui attrape l'écart
  ///    d'une unité.
  ///
  /// 2. LE COMPTE MANGÉ PAR LA TRONCATURE. S'il était collé au bout du texte,
  ///    l'ellipse l'emporterait en premier. Le test vérifie qu'il est un
  ///    PARAGRAPHE À PART et qu'il reste entier dans les douze cases.
  ///
  /// 3. UNE LIGNE VIDE OU UN SÉPARATEUR ORPHELIN sur un article sans
  ///    compatibilité.
  ///
  /// 4. UNE TRONCATURE AILLEURS SUR LA CARTE. Les cartes du catalogue ont déjà
  ///    coûté une journée de troncatures invisibles — un titre coupé dans 24
  ///    cases, une ville rognée sans ellipse par le `clipBehavior`. On relit
  ///    donc TOUS les paragraphes de la carte, et on compare
  ///    `minIntrinsicWidth` à la contrainte reçue, parce que
  ///    `didExceedMaxLines` ne voit pas le mot plus large que sa ligne.
  ///
  /// 5. LA DENSITÉ PERDUE EN SILENCE. Le tableau avant/après est plus bas, et
  ///    la colonne « avant » n'est pas un souvenir : c'est la même page montée
  ///    avec la clé `compatibility` RETIRÉE de la réponse, ce qui est l'état
  ///    exact d'avant ce lot.
  ///
  /// ── CE QUE LA LIGNE COÛTE, MESURÉ APRÈS LE PASSAGE AU MODÈLE SEUL ────────
  ///
  /// LA HAUTEUR DE CARTE ne suit pas l'échelle : elle suit le nombre de LIGNES
  /// que la mention occupe, qui est un ou deux. Une ligne vaut 12,0 points au
  /// réglage par défaut (corps 10,0 × interligne 1,2), et l'écart qui la
  /// détache du nom en vaut 3,0 de plus.
  ///
  ///              320 pt      360 pt      411 pt
  ///   x1,0       +15,0       +15,0       +15,0     (une ligne partout)
  ///   x1,3       +35,0       +19,0       +19,0
  ///   x1,5       +39,0       +39,0       +21,0
  ///   x2,0       +51,0       +51,0       +51,0     (deux lignes partout)
  ///
  /// LE MODÈLE SEUL A RENDU DE LA HAUTEUR dans sept cases sur douze : à
  /// « Toyota Corolla · … » la ligne prenait DEUX lignes dès le réglage par
  /// défaut, donc +27,0 partout au lieu de +15,0. Mais il en a COÛTÉ dans une :
  /// à 411 × 2,0 un seul nom tenait avant, sur une ligne, pour +27,0 ; les
  /// trois tiennent maintenant, sur deux, pour +51,0. Plus de noms lisibles,
  /// une carte plus haute — c'est l'échange que le propriétaire a demandé, et
  /// il n'est pas gratuit dans cette case-là.
  ///
  /// LE COMPTE D'ANNONCES ENTIÈRES, personnel, avant → après :
  ///
  ///                   pièces        accessoires
  ///   320x640  x1,0    2 → 2          2 → 2
  ///   320x640  x1,3    2 → 2          2 → 2
  ///   320x640  x1,5    2 → 2          2 → 2
  ///   320x640  x2,0    2 → 0          0 → 0
  ///   360x720  x1,0    2 → 2          2 → 2
  ///   360x720  x1,3    2 → 2          2 → 2
  ///   360x720  x1,5    2 → 2          2 → 2
  ///   360x720  x2,0    2 → 2          2 → 2
  ///   411x923  x1,0    4 → 4          4 → 4
  ///   411x923  x1,3    4 → 4          4 → 4
  ///   411x923  x1,5    4 → 4          4 → 4
  ///   411x923  x2,0    4 → 4          4 → 2
  ///
  /// Et pour un CLIENT, sur les accessoires — sa carte porte un
  /// `_AvailabilityBadge` de plus :
  ///
  ///   320x640  x1,0  2 → 2    x1,3  2 → 2    x1,5  2 → 2    x2,0  0 → 0
  ///   360x720  x1,0  2 → 2    x1,3  2 → 2    x1,5  2 → 2    x2,0  2 → 2
  ///   411x923  x1,0  4 → 4    x1,3  4 → 4    x1,5  4 → 4    x2,0  4 → 2
  ///
  /// ── TROIS CASES PERDENT UNE RANGÉE, ET LE MODÈLE SEUL N'EN A REPRIS AUCUNE
  ///
  /// Sur trente-six cases mesurées, TRENTE-TROIS ne bougent pas. Trois perdent
  /// une rangée entière, c'est-à-dire DEUX annonces, et les trois sont au
  /// DERNIER cran d'Android :
  ///
  ///   — les pièces en 320 × 2,0 passent de 2 annonces entières à ZÉRO. La
  ///     carte y passe de 278,0 à 329,0 points, la première rangée commence à
  ///     48,0 et la liste en offre 356,0 : il faut donc 377,0 points pour une
  ///     rangée entière, et il en manque 21,0. Avant la ligne il en fallait
  ///     326,0, et il en restait 30,0.
  ///   — les accessoires en 411 × 2,0 passent de 4 à 2, personnel comme
  ///     client : la carte passe de 273,0 à 324,0 points (277,0 à 328,0 pour
  ///     le client), et la SECONDE rangée franchit le pli — 48,0 + 324,0 + 8,0
  ///     de marge + 324,0 = 704,0 pour 639,0 de liste, soit 65,0 points de
  ///     trop, et 73,0 pour le client.
  ///
  /// CE SONT LES MÊMES TROIS CASES QU'AVANT LE PASSAGE AU MODÈLE SEUL, et il
  /// faut le dire parce qu'on pouvait espérer le contraire : des noms plus
  /// courts ne rendent une rangée que s'ils font tomber la mention de deux
  /// lignes à une, et à l'échelle 2,0 elle en occupe deux dans les trois cas —
  /// 90,38 points reçus à 320, 110,38 à 360, 147,61 à 411, pour une mention de
  /// corps 20,0. Le gain est ailleurs : dans les sept cases où la carte
  /// grandit de 15,0 à 21,0 au lieu de 27,0 à 39,0.
  ///
  /// À 411 × 2,0 le changement a même COÛTÉ 24,0 points de hauteur de carte,
  /// pour la raison qui est tout l'intérêt de la décision : trois noms y
  /// tiennent maintenant là où un seul tenait. Le compte d'annonces entières,
  /// lui, y était déjà tombé à 2 et n'a pas bougé.
  ///
  /// CE N'EST PAS UNE DÉCISION DE BANC. Le propriétaire a demandé la ligne en
  /// sachant qu'elle prend de la place ; ce qu'il ne pouvait pas savoir, c'est
  /// qu'elle coûte une rangée au dernier cran de « Grande police ». Les leviers
  /// existent et aucun n'est gratuit : une seule ligne au lieu de deux rendrait
  /// 24,0 points à l'échelle 2,0 mais perdrait le deuxième nom dans les trois
  /// cases concernées ; borner l'échelle de texte de la ligne, comme
  /// `BarreNavigationPrincipale` borne la sienne, rendrait autant mais figerait
  /// une mention à 10 points pour quelqu'un qui a demandé du texte deux fois
  /// plus grand. Les deux sont des décisions de produit.
  group('La ligne de compatibilité', () {
    /// La maquette du propriétaire : trois noms courts, douze modèles au total.
    Map<String, dynamic> maquette() => {
      'count': 12,
      'vehicles': ['Corolla', 'Tucson', 'Rio'],
    };

    /// LE PIRE RÉSUMÉ QUE LE RÉFÉRENTIEL PUISSE RENDRE, et il n'est pas de
    /// fantaisie : les trois noms sortent de `Referentiel-marques-modeles`,
    /// avec un total à deux chiffres comme en a tout accessoire universel.
    ///
    /// CE SONT DES MODÈLES SEULS, depuis que le serveur a cessé de préfixer la
    /// marque. La version précédente portait « Mercedes-Benz Classe C 220 d »
    /// et ses pareils, c'est-à-dire une chaîne que la ligne ne peut PLUS
    /// recevoir : un pire cas que la production ne produit pas mesure une mise
    /// en page qui n'existe pas. Les noms ci-dessous sont les plus longs que
    /// la colonne « modèle » du référentiel porte réellement.
    Map<String, dynamic> pireCas() => {
      'count': 37,
      'vehicles': [
        'Grand Cherokee Trackhawk',
        'Range Rover Sport',
        'Classe C 220 d',
      ],
    };

    Future<void> poserPieces(
      WidgetTester tester, {
      required Size ecran,
      required double echelle,
      required Locale locale,
      required Map<String, dynamic>? compat,
    }) => poserPage(
      tester,
      ecran: ecran,
      echelle: echelle,
      locale: locale,
      barreDuBas: true,
      page: const PartListPage(),
      surcharges: [
        catalogRepositoryProvider.overrideWithValue(
          _Depot(
            const [],
            pieces: List.generate(
              8,
              (_) => _piece(compatibilite: compat),
            ),
          ),
        ),
        partCategoriesProvider.overrideWith((_) async => deuxBranches),
        categoriesAvecPiecesProvider.overrideWith((_) async => deuxBranches),
      ],
    );

    Future<void> poserAccessoires(
      WidgetTester tester, {
      required Size ecran,
      required double echelle,
      required Locale locale,
      required Map<String, dynamic>? compat,
      AuthState session = const AuthState(
        type: AuthType.staff,
        staffUser: StaffUser(
          id: 1,
          name: 'Administrateur',
          email: 'admin@autoparc.bf',
          role: 'admin',
        ),
      ),
    }) => poserPage(
      tester,
      ecran: ecran,
      echelle: echelle,
      locale: locale,
      barreDuBas: true,
      session: session,
      page: const AccessoryListPage(),
      surcharges: [
        catalogRepositoryProvider.overrideWithValue(
          _Depot(
            const [],
            accessoires: List.generate(
              8,
              (_) => _accessoire(compatibilite: compat),
            ),
          ),
        ),
        categoriesAccessoiresOccupeesProvider.overrideWith(
          (_) async => {'esthetique', 'confort', 'securite'},
        ),
      ],
    );

    final poseurs =
        <
          String,
          Future<void> Function(
            WidgetTester, {
            required Size ecran,
            required double echelle,
            required Locale locale,
            required Map<String, dynamic>? compat,
          })
        >{'pièces': poserPieces, 'accessoires': poserAccessoires};

    /// Les paragraphes de la PREMIÈRE ligne de compatibilité peinte : les noms
    /// d'abord, le compte ensuite quand il y en a un.
    List<RenderParagraph> paragraphesDeLaLigne(WidgetTester tester) => tester
        .renderObjectList<RenderParagraph>(
          find.descendant(
            of: find.byType(LigneCompatibilite).first,
            matching: find.byType(RichText),
          ),
        )
        .toList();

    /// COMBIEN DE NOMS LA CARTE PEINT RÉELLEMENT, case par case.
    ///
    /// ── CE QUE LE PASSAGE AU MODÈLE SEUL A RENDU ───────────────────────────
    ///
    /// Les deux colonnes sont mesurées, la seconde sur le même banc après que
    /// le serveur a cessé de préfixer la marque :
    ///
    ///                    « Toyota Corolla · … »   « Corolla · … »
    ///   320x640  x1,0            2                      3
    ///   320x640  x1,3            2                      3
    ///   320x640  x1,5            1                      3
    ///   320x640  x2,0            1                      2
    ///   360x720  x1,0            3                      3
    ///   360x720  x1,3            2                      3
    ///   360x720  x1,5            2                      3
    ///   360x720  x2,0            1                      2
    ///   411x923  x1,0            3                      3
    ///   411x923  x1,3            3                      3
    ///   411x923  x1,5            2                      3
    ///   411x923  x2,0            1                      3
    ///
    /// Les TROIS noms tiennent maintenant dans DIX cases sur douze, contre
    /// trois avant. Les deux qui restent sont 320 et 360 au dernier cran
    /// d'Android, et elles en affichent DEUX — plus aucune case ne tombe à un
    /// seul nom. C'était tout l'objet de la décision du propriétaire : la
    /// ligne annonçait surtout un « +N », elle nomme désormais des modèles.
    ///
    /// LA LARGEUR REÇUE A BOUGÉ AUSSI, et pas pour la raison qu'on croit : à
    /// 320 points et à l'échelle 1,0 elle passe de 107,32 à 113,30. Le compte
    /// peint est « +9 » au lieu de « +11 », donc un chiffre de moins à droite,
    /// donc autant de rendu à l'`Expanded` des noms. La réserve de place,
    /// elle, n'a pas changé — elle se calcule sur le pire cas `count - 1`.
    ///
    /// ── CE QUE CE TABLEAU VERROUILLE ───────────────────────────────────────
    ///
    /// Le serveur envoie TROIS noms et la carte n'en montre pas toujours
    /// trois : un « +N » calculé sur les trois reçus serait encore faux dans
    /// DEUX cases sur douze. L'écart est d'une unité, et c'est exactement le
    /// genre d'erreur que personne ne vérifie. Le mécanisme du widget reste
    /// donc nécessaire — il l'est simplement dans moins de cases.
    ///
    /// Les chiffres sont identiques pour les pièces et les accessoires, et
    /// identiques dans les deux langues : le séparateur est le même, et les
    /// noms viennent du référentiel du serveur, qui ne traduit pas. La clé ne
    /// porte donc ni la liste ni la langue — l'assertion les parcourt quand
    /// même, parce que c'est justement le genre de coïncidence qui cesse.
    const nomsPeints = <String, int>{
      '320x640-1.0': 3,
      '320x640-1.3': 3,
      '320x640-1.5': 3,
      '320x640-2.0': 2,
      '360x720-1.0': 3,
      '360x720-1.3': 3,
      '360x720-1.5': 3,
      '360x720-2.0': 2,
      '411x923-1.0': 3,
      '411x923-1.3': 3,
      '411x923-1.5': 3,
      '411x923-2.0': 3,
    };

    // ── Le compte est juste, et il est entier ───────────────────────────────

    for (final poseur in poseurs.entries) {
      for (final ecran in ecrans.entries) {
        for (final echelle in echelles) {
          for (final langue in langues.entries) {
            testWidgets(
              '${poseur.key} en ${ecran.key}, texte x$echelle, ${langue.key} : '
              'le « +N » compte ce qui est PEINT',
              (tester) async {
                await poseur.value(
                  tester,
                  ecran: ecran.value,
                  echelle: echelle,
                  locale: langue.value,
                  compat: maquette(),
                );

                final textes = await chargerTextes(langue.value);
                final separateur = textes.catalogCompatibilitySeparator;
                final ps = paragraphesDeLaLigne(tester);

                expect(
                  ps,
                  isNotEmpty,
                  reason:
                      'Aucune ligne de compatibilité peinte : la carte ne la '
                      'rend pas, et ce test ne mesure rien.',
                );

                final noms = texteDe(ps.first).split(separateur);

                expect(
                  noms.length,
                  nomsPeints['${ecran.key}-$echelle'],
                  reason:
                      'La carte peint ${noms.length} nom(s) — '
                      '« ${texteDe(ps.first)} » — pour '
                      '${recue(ps.first).toStringAsFixed(2)} points reçus. Le '
                      'tableau en attendait '
                      '${nomsPeints['${ecran.key}-$echelle']}. Si la mise en '
                      'page a changé, remesurez et corrigez le tableau ; mais '
                      'vérifiez d\'abord que le compte « +N » a suivi, parce '
                      'que c\'est lui qui devient faux en silence.',
                );

                expect(
                  ps.length,
                  2,
                  reason:
                      'La ligne ne porte pas DEUX paragraphes : douze modèles '
                      'pour trois noms reçus, il reste forcément un compte à '
                      'afficher. S\'il a disparu, c\'est qu\'il a été collé au '
                      'texte — et la troncature le mangera.',
                );

                // LE CŒUR DU GROUPE. Le compte annoncé doit valoir le total
                // moins les noms RÉELLEMENT PEINTS, et non moins les trois
                // reçus du serveur.
                expect(
                  texteDe(ps[1]),
                  textes.catalogCompatibilityMore(12 - noms.length),
                  reason:
                      'La carte peint ${noms.length} nom(s) et annonce '
                      '« ${texteDe(ps[1])} » : le compte est calculé sur ce '
                      'que le serveur a envoyé et non sur ce qui tient. '
                      'L\'écart est d\'une unité, et c\'est exactement le '
                      'genre d\'erreur que personne ne vérifie.',
                );

                // Le compte reste ENTIER. C'est l'autre moitié de la décision
                // de le sortir du texte : sorti mais rogné, il ne vaudrait pas
                // mieux.
                expect(
                  ps[1].didExceedMaxLines,
                  isFalse,
                  reason:
                      'Le compte « ${texteDe(ps[1])} » est coupé : '
                      '${voulue(ps[1]).toStringAsFixed(2)} points voulus pour '
                      '${recue(ps[1]).toStringAsFixed(2)} reçus.',
                );
                expect(
                  motLePlusLarge(ps[1]),
                  lessThanOrEqualTo(recue(ps[1]) + 0.01),
                  reason:
                      'Le compte « ${texteDe(ps[1])} » sera rogné SANS '
                      'ellipse : ${motLePlusLarge(ps[1]).toStringAsFixed(2)} '
                      'points pour ${recue(ps[1]).toStringAsFixed(2)} reçus.',
                );

                // Deux lignes au plus, et c'est la demande du propriétaire.
                // Mesuré sur la HAUTEUR PEINTE et non sur `lignesPosees` :
                // celui-ci remet le texte en page sans `maxLines`, donc il
                // compte les lignes que le paragraphe VOUDRAIT et non celles
                // que l'écran montre.
                expect(
                  ps.first.size.height,
                  lessThanOrEqualTo(2 * hauteurDUneLigne(ps.first) + 0.01),
                  reason:
                      'La ligne peint ${ps.first.size.height.toStringAsFixed(2)} '
                      'points de haut pour une ligne de '
                      '${hauteurDUneLigne(ps.first).toStringAsFixed(2)} : elle '
                      'en vole à la carte, et le propriétaire en a demandé '
                      'deux au plus.',
                );

                // Les noms sont des valeurs du référentiel du serveur : ils ont
                // le droit de s'ellipser. Ce qu'ils n'ont pas le droit de
                // faire, c'est de déborder SANS ellipse — voir le point 4 de
                // l'en-tête de ce groupe.
                expect(
                  motLePlusLarge(ps.first),
                  lessThanOrEqualTo(recue(ps.first) + 0.01),
                  reason:
                      'Un nom de « ${texteDe(ps.first)} » fait '
                      '${motLePlusLarge(ps.first).toStringAsFixed(2)} points '
                      'pour ${recue(ps.first).toStringAsFixed(2)} reçus : il '
                      'sera rogné par le `clipBehavior` de la carte, donc en '
                      'silence.',
                );
              },
            );
          }
        }
      }
    }

    // ── La ligne DISPARAÎT quand il n'y a rien à dire ───────────────────────

    /// Les deux façons de n'avoir aucune compatibilité à annoncer, et il faut
    /// les deux : la clé ABSENTE de la réponse — `CompatibilityService` ne
    /// charge pas la relation, donc l'accueil et la page du garage reçoivent
    /// des pièces sans elle — et la clé PRÉSENTE ET VIDE, qui est ce que le
    /// serveur rend pour un article sans fitment et ce que porte la fixture
    /// `parts_list.json` du dépôt.
    final riens = <String, Map<String, dynamic>?>{
      'clé absente': null,
      'résumé vide': {'count': 0, 'vehicles': <String>[]},
    };

    for (final poseur in poseurs.entries) {
      for (final rien in riens.entries) {
        testWidgets(
          '${poseur.key} : ${rien.key} → aucune ligne, aucun séparateur '
          'orphelin',
          (tester) async {
            await poseur.value(
              tester,
              ecran: const Size(320, 640),
              echelle: 1.0,
              locale: localeFr,
              compat: rien.value,
            );

            // Le widget est bien dans l'arbre — c'est ce qui distingue
            // « il s'efface » de « il n'a pas été posé ».
            expect(
              find.byType(LigneCompatibilite),
              findsWidgets,
              reason:
                  'La carte ne pose plus de `LigneCompatibilite` du tout : ce '
                  'test ne vérifie alors plus rien. Il doit mesurer un widget '
                  'PRÉSENT qui rend un `SizedBox.shrink()`.',
            );

            expect(
              paragraphesDeLaLigne(tester),
              isEmpty,
              reason:
                  'La ligne peint encore du texte sans aucun modèle à '
                  'annoncer : « '
                  '${paragraphesDeLaLigne(tester).map(texteDe).join(' | ')} ». '
                  'Un séparateur seul ou un « +0 » est pire qu\'une ligne '
                  'absente — il promet une information qui n\'existe pas.',
            );

            // Hauteur nulle, et non « presque nulle » : l'écart qui détache la
            // ligne du nom est porté par le widget lui-même, précisément pour
            // qu'il disparaisse avec elle.
            expect(
              tester
                  .renderObject<RenderBox>(find.byType(LigneCompatibilite).first)
                  .size
                  .height,
              0.0,
              reason:
                  'La ligne absente occupe quand même de la hauteur : l\'écart '
                  'de 3 points a dû repasser dans la carte, où il reste pour '
                  'les articles sans compatibilité.',
            );
          },
        );
      }
    }

    // ── Le pire contenu du référentiel ──────────────────────────────────────

    for (final poseur in poseurs.entries) {
      for (final ecran in ecrans.entries) {
        for (final echelle in echelles) {
          testWidgets(
            '${poseur.key} en ${ecran.key}, texte x$echelle : les plus longs '
            'modèles ne débordent pas',
            (tester) async {
              // CE QUE CE TEST AJOUTE AU PRÉCÉDENT. La maquette du
              // propriétaire porte des noms de six à sept signes — « Corolla »,
              // « Tucson », « Rio » —, le référentiel en porte de vingt-quatre.
              // Le passage au modèle seul a raccourci la moyenne, pas le
              // maximum : « Trackhawk » reste un mot plus large que sa ligne
              // aux grandes échelles, et c'est le cas qui rogne SANS ellipse —
              // celui que `didExceedMaxLines` ne voit pas.
              await poseur.value(
                tester,
                ecran: ecran.value,
                echelle: echelle,
                locale: localeFr,
                compat: pireCas(),
              );

              final ps = paragraphesDeLaLigne(tester);
              expect(ps, isNotEmpty);

              expect(
                motLePlusLarge(ps.first),
                lessThanOrEqualTo(recue(ps.first) + 0.01),
                reason:
                    'Un segment de « ${texteDe(ps.first)} » fait '
                    '${motLePlusLarge(ps.first).toStringAsFixed(2)} points '
                    'pour ${recue(ps.first).toStringAsFixed(2)} reçus. Il '
                    'sera rogné par le `clipBehavior` de la carte, sans '
                    'ellipse et donc sans que rien n\'avertisse.',
              );

              expect(
                ps.first.size.height,
                lessThanOrEqualTo(2 * hauteurDUneLigne(ps.first) + 0.01),
                reason:
                    'La ligne peint '
                    '${ps.first.size.height.toStringAsFixed(2)} points de haut '
                    'sur le pire contenu, pour une ligne de '
                    '${hauteurDUneLigne(ps.first).toStringAsFixed(2)} : deux '
                    'au plus, c\'est la demande du propriétaire.',
              );

              // UN SEUL NOM TROP LONG S'ELLIPSE, ET C'EST ADMIS. Le plancher
              // de la boucle de mesure est d'un nom, et le `maxLines: 2` du
              // `Text` l'ellipse quand même celui-là ne tient pas. C'est une
              // valeur du référentiel du serveur, dont personne ici ne
              // contrôle la longueur — le même droit que le surnom d'un
              // véhicule ou le nom d'une pièce. Ce qui n'est PAS admis est le
              // débordement sans ellipse, mesuré juste au-dessus.

              // Trente-sept modèles pour au plus trois noms : il reste
              // forcément un compte, et il doit être juste.
              expect(ps.length, 2);
              final noms = texteDe(ps.first).split(' · ');
              expect(
                texteDe(ps[1]),
                '+${37 - noms.length}',
                reason:
                    '${noms.length} nom(s) peint(s) et « ${texteDe(ps[1])} » '
                    'annoncé : le compte ne suit pas ce qui tient.',
              );
            },
          );
        }
      }
    }

    // ── RIEN D'AUTRE SUR LA CARTE NE TRONQUE À CAUSE D'ELLE ─────────────────

    for (final poseur in poseurs.entries) {
      for (final ecran in ecrans.entries) {
        for (final echelle in echelles) {
          testWidgets(
            '${poseur.key} en ${ecran.key}, texte x$echelle : la carte '
            'entière, avant et après',
            (tester) async {
              // LA RÈGLE DE CE TEST. La ligne prend de la LARGEUR à personne —
              // elle est seule sur ses deux lignes — mais elle prend de la
              // HAUTEUR, et une carte plus haute peut replier ce qui tenait.
              // On relit donc TOUS les paragraphes de la première carte, dans
              // les deux états, et on exige que l'état APRÈS ne soit pas pire
              // que l'état AVANT. C'est une comparaison et non un seuil : les
              // cartes du catalogue portent déjà des défauts antérieurs — le
              // prix d'une pièce n'a pas de `FittedBox`, contrairement à celui
              // d'un véhicule —, et ce lot n'a ni causé ni le mandat de
              // corriger ceux-là.
              Future<
                Map<
                  String,
                  (double mot, double recue, bool coupe, double voulue, int lignes)
                >
              >
              lire(Map<String, dynamic>? compat) async {
                await poseur.value(
                  tester,
                  ecran: ecran.value,
                  echelle: echelle,
                  locale: localeFr,
                  compat: compat,
                );

                final carte = find.byType(Card).first;
                final ps = tester
                    .renderObjectList<RenderParagraph>(
                      find.descendant(
                        of: carte,
                        matching: find.byType(RichText),
                      ),
                    )
                    .toList();

                return {
                  for (final p in ps)
                    texteDe(p): (
                      motLePlusLarge(p),
                      recue(p),
                      p.didExceedMaxLines,
                      voulue(p),
                      lignesPosees(p),
                    ),
                };
              }

              final avant = await lire(null);
              final apres = await lire(maquette());

              expect(
                avant,
                isNotEmpty,
                reason:
                    'Aucun paragraphe sur la carte : la liste est restée sur '
                    'son indicateur, et ce test ne mesure rien.',
              );

              // Chaque paragraphe qui existait AVANT doit se retrouver APRÈS,
              // avec la même largeur reçue et le même état de troncature. Les
              // paragraphes nouveaux — les deux de la ligne — sont mesurés par
              // les tests ci-dessus.
              for (final entree in avant.entries) {
                final apresLui = apres[entree.key];
                expect(
                  apresLui,
                  isNotNull,
                  reason:
                      '« ${entree.key} » a disparu de la carte en posant la '
                      'ligne de compatibilité.',
                );

                final memeLargeur =
                    '« ${entree.key} » ne reçoit plus la même largeur : '
                    '${apresLui!.$2} contre ${entree.value.$2} avant la '
                    'ligne. Celle-ci lui a pris de la place, ce qu\'elle ne '
                    'devait pas faire — elle est seule sur ses lignes.';

                // UNE CONTRAINTE INFINIE SE COMPARE À L'IDENTIQUE : `closeTo`
                // ne sait pas encadrer l'infini, et il y en a sur ces cartes —
                // les badges de la vignette sont dans des `Positioned`, qui
                // ne bornent pas la largeur. La première version de ce test
                // tombait sur « a numeric value within <0.01> of <Infinity> »
                // dans les vingt-quatre cases.
                if (entree.value.$2.isInfinite || apresLui.$2.isInfinite) {
                  expect(apresLui.$2, entree.value.$2, reason: memeLargeur);
                } else {
                  expect(
                    apresLui.$2,
                    closeTo(entree.value.$2, 0.01),
                    reason: memeLargeur,
                  );
                }

                // Une comparaison, et non un seuil : ce qui n'était pas coupé
                // avant ne doit pas l'être après. Ce qui l'était déjà reste un
                // défaut antérieur, que ce lot n'a pas causé.
                if (!entree.value.$3) {
                  expect(
                    apresLui.$3,
                    isFalse,
                    reason:
                        '« ${entree.key} » est maintenant COUPÉ, et il ne '
                        'l\'était pas avant la ligne de compatibilité : '
                        '${apresLui.$1.toStringAsFixed(2)} points de segment '
                        'pour ${apresLui.$2.toStringAsFixed(2)} reçus.',
                  );
                }

                expect(
                  apresLui.$1,
                  lessThanOrEqualTo(entree.value.$1 + 0.01),
                  reason:
                      'Le plus long segment de « ${entree.key} » a grandi : '
                      '${apresLui.$1.toStringAsFixed(2)} contre '
                      '${entree.value.$1.toStringAsFixed(2)} avant la ligne.',
                );

                // Le nombre de lignes POSÉES, qui est le seul détecteur du
                // repli mot-par-mot — voir le test de déclaration ci-dessous.
                expect(
                  apresLui.$5,
                  lessThanOrEqualTo(entree.value.$5),
                  reason:
                      '« ${entree.key} » occupe maintenant ${apresLui.$5} '
                      'lignes contre ${entree.value.$5} avant la ligne de '
                      'compatibilité.',
                );
              }
            },
          );
        }
      }
    }

    // ── LE PRIX SE REPLIE DÉJÀ À L'ÉCHELLE 2,0, ET C'EST ANTÉRIEUR ──────────

    /// CE TEST NE PRÉTEND PAS QUE LE DÉFAUT A DISPARU, et il n'est pas de ce
    /// lot — il est écrit ici parce que les captures de la ligne de
    /// compatibilité le montrent, et qu'une capture livrée sans explication
    /// fait corriger le mauvais objet.
    ///
    /// LE DÉFAUT. Le prix d'une carte de PIÈCE ou d'ACCESSOIRE est un `Text`
    /// nu : pas de `FittedBox`, contrairement à la carte d'un véhicule, où
    /// `_PrixAjuste` réduit le corps plutôt que de laisser couper. Or un prix
    /// est un seul segment insécable — U+202F entre les milliers et U+00A0
    /// devant « FCFA » interdisent la coupure, et c'est voulu. Quand il ne
    /// tient pas, Flutter se rabat sur une coupure CARACTÈRE PAR CARACTÈRE :
    /// « 109 500 FCFA » devient « 109 500 FCF » puis « A » seul sur la
    /// deuxième ligne.
    ///
    /// LES TROIS CASES, sur vingt-quatre, toutes au dernier cran d'Android :
    ///
    ///   pièces      320 × 2,0   « 4 500 FCFA »     132,44 voulus / 129,0 reçus
    ///   accessoires 320 × 2,0   « 109 500 FCFA »   162,77 voulus / 129,0 reçus
    ///   accessoires 360 × 2,0   « 109 500 FCFA »   162,77 voulus / 149,0 reçus
    ///
    /// AUCUN DES DEUX DÉTECTEURS HABITUELS NE LE VOIT, et c'est la raison
    /// d'être de ce test. `didExceedMaxLines` reste FAUX — le paragraphe n'a
    /// pas de `maxLines`, donc il se replie au lieu de se déclarer tronqué. Et
    /// `minIntrinsicWidth` rend 17,74 dans deux des trois cases, c'est-à-dire
    /// la largeur d'UN CARACTÈRE : une fois que le moteur a coupé dans le mot,
    /// la largeur minimale du paragraphe devient celle d'une lettre, et la
    /// comparaison « segment insécable contre largeur reçue » passe au vert
    /// sur un prix cassé en deux. Seul le nombre de LIGNES POSÉES le voit.
    ///
    /// CE N'EST PAS CE LOT QUI L'A CAUSÉ : le test « la carte entière, avant
    /// et après » mesure les mêmes 129,0 et 149,0 points reçus avec et sans la
    /// ligne de compatibilité, et le même nombre de lignes. La correction est
    /// la même que pour les véhicules — un `FittedBox` sur le prix — et elle
    /// demande son propre lot de mesures sur les deux cartes.
    for (final cas in <(String, Size, String)>[
      ('pièces', Size(320, 640), '4 500 FCFA'),
      ('accessoires', Size(320, 640), '109 500 FCFA'),
      ('accessoires', Size(360, 720), '109 500 FCFA'),
    ]) {
      testWidgets(
        '${cas.$1} en ${cas.$2.width.toInt()}x${cas.$2.height.toInt()}, texte '
        'x2.0 : le prix se replie déjà, et le chiffre est verrouillé',
        (tester) async {
          await poseurs[cas.$1]!(
            tester,
            ecran: cas.$2,
            echelle: 2.0,
            locale: localeFr,
            compat: maquette(),
          );

          final prix = tester.renderObject<RenderParagraph>(
            find
                .descendant(
                  of: find.byType(Card).first,
                  matching: find.text(cas.$3),
                )
                .first,
          );

          expect(
            lignesPosees(prix),
            2,
            reason:
                'Le prix « ${cas.$3} » n\'occupe plus deux lignes : '
                '${voulue(prix).toStringAsFixed(2)} points voulus pour '
                '${recue(prix).toStringAsFixed(2)} reçus. S\'il a été corrigé '
                '— un `FittedBox` comme sur la carte d\'un véhicule —, '
                'retirez ce test.',
          );

          expect(
            voulue(prix),
            greaterThan(recue(prix)),
            reason:
                'Le prix tient maintenant sur sa ligne : '
                '${voulue(prix).toStringAsFixed(2)} pour '
                '${recue(prix).toStringAsFixed(2)}. Remesurez.',
          );

          expect(
            prix.didExceedMaxLines,
            isFalse,
            reason:
                'Le prix se déclare maintenant tronqué : c\'est une AUTRE '
                'façon de le perdre, et un prix coupé est un prix FAUX là où '
                'un prix replié reste vrai. Remesurez.',
          );
        },
      );
    }

    // ── LE TABLEAU DE DENSITÉ, avant et après, dans la COQUE COMPLÈTE ───────

    /// Ce que la ligne COÛTE en annonces visibles, mesuré et non supposé.
    ///
    /// Le compte est le nombre de cartes ENTIÈREMENT visibles : une carte
    /// coupée par le pli n'est pas une annonce lue. Il est lu sur les
    /// rectangles peints, dans le `Viewport` de la liste, page montée DANS SA
    /// COQUE — barre de titre, barre de recherche, bande de filtres et barre de
    /// navigation du bas comprises.
    ///
    /// « AVANT » n'est pas un souvenir : c'est la même page montée avec la clé
    /// `compatibility` retirée de la réponse, donc l'état exact d'avant ce lot.
    /// Les deux colonnes sortent de la même exécution.
    ///
    /// LE TABLEAU EST IMPRIMÉ PAR LA MESURE, et l'assertion porte sur l'ÉCART
    /// autorisé. C'est au propriétaire d'arbitrer une annonce perdue, pas à ce
    /// banc de la cacher : le test imprime les deux comptes et la hauteur de
    /// carte dans les deux états, et il échoue dès qu'une case perd plus d'une
    /// rangée.
    for (final poseur in poseurs.entries) {
      for (final ecran in ecrans.entries) {
        for (final echelle in echelles) {
          testWidgets(
            '${poseur.key} en ${ecran.key}, texte x$echelle : la densité, '
            'avant et après',
            (tester) async {
              /// Les cartes entièrement visibles dans le `Viewport` de la
              /// liste, et la hauteur de la première.
              Future<
                (
                  int entieres,
                  int posees,
                  double hauteur,
                  double liste,
                  double premiere,
                )
              >
              compter(Map<String, dynamic>? compat) async {
                await poseur.value(
                  tester,
                  ecran: ecran.value,
                  echelle: echelle,
                  locale: localeFr,
                  compat: compat,
                );

                final vue = tester.getRect(find.byType(Viewport).first);

                // Les rectangles sont lus sur les OBJETS DE RENDU et non par
                // un `Finder` par carte : `localToGlobal` dit où la carte est
                // réellement peinte, y compris quand le défilement l'a sortie
                // du pli.
                final cartes = tester
                    .renderObjectList<RenderBox>(
                      find.descendant(
                        of: find.byType(Viewport).first,
                        matching: find.byType(Card),
                      ),
                    )
                    .map(
                      (b) => Rect.fromPoints(
                        b.localToGlobal(Offset.zero),
                        b.localToGlobal(b.size.bottomRight(Offset.zero)),
                      ),
                    )
                    .toList();

                final entieres = cartes
                    .where((r) => r.bottom <= vue.bottom + 0.01)
                    .length;

                return (
                  entieres,
                  cartes.length,
                  cartes.isEmpty ? 0.0 : cartes.first.height,
                  vue.height,
                  cartes.isEmpty ? 0.0 : cartes.first.top - vue.top,
                );
              }

              final avant = await compter(null);
              final apres = await compter(maquette());

              // ignore: avoid_print
              print(
                '@@DENSITÉ ${poseur.key} ${ecran.key} x$echelle : '
                'liste ${avant.$4.toStringAsFixed(1)} ; '
                'première à ${avant.$5.toStringAsFixed(1)} → '
                '${apres.$5.toStringAsFixed(1)} ; '
                'carte ${avant.$3.toStringAsFixed(1)} → '
                '${apres.$3.toStringAsFixed(1)} '
                '(+${(apres.$3 - avant.$3).toStringAsFixed(1)}) ; '
                'entières ${avant.$1} → ${apres.$1} '
                '(posées ${avant.$2} → ${apres.$2})',
              );

              expect(
                avant.$2,
                greaterThan(0),
                reason:
                    'Aucune carte posée : la liste est restée sur son '
                    'indicateur, et ce tableau ne mesure rien.',
              );

              // LA LIGNE NE DOIT PAS COÛTER PLUS D'UNE RANGÉE, c'est-à-dire
              // deux annonces — et le commentaire d'en-tête du groupe porte le
              // chiffre réel, case par case, tel que l'exécution l'imprime. Au
              // delà, ce n'est plus un arbitrage de mise en page mais une
              // décision de produit, et elle revient au propriétaire.
              expect(
                apres.$1,
                greaterThanOrEqualTo(avant.$1 - 2),
                reason:
                    'La ligne de compatibilité coûte '
                    '${avant.$1 - apres.$1} annonce(s) entière(s) en '
                    '${ecran.key} à l\'échelle $echelle, sur les '
                    '${poseur.key} : ${avant.$1} avant, ${apres.$1} après, '
                    'pour ${avant.$4.toStringAsFixed(1)} points de liste et '
                    'une carte passée de ${avant.$3.toStringAsFixed(1)} à '
                    '${apres.$3.toStringAsFixed(1)}. C\'est plus d\'une '
                    'rangée : à dire au propriétaire avant de livrer.',
              );
            },
          );
        }
      }
    }

    // ── LA MÊME MESURE POUR UN CLIENT, qui porte un badge de plus ───────────

    /// LE CLIENT N'A PAS LA MÊME CARTE QUE LE PERSONNEL, et la différence
    /// compte ici : `if (!isStaff)` ajoute un `_AvailabilityBadge` sous le
    /// prix. Le tableau du personnel ci-dessus décrit donc la carte la PLUS
    /// COURTE des deux, et il aurait suffi à faire croire que la ligne coûte
    /// moins qu'elle ne coûte.
    ///
    /// Mesuré sur les ACCESSOIRES seulement. `part_list_page.dart` insère pour
    /// le client un `_GarageFilterBanner` dont l'état écrit dans ses notifiers
    /// depuis `deactivate()` : un test qui monte deux fois puis démonte lève
    /// « Tried to use StateController after dispose ». La fragilité est réelle,
    /// antérieure, sans porteur, et `accueil_langues_test.dart` dit pourquoi
    /// elle n'existe pas en production — le `ProviderScope` y est la racine. La
    /// carte d'une pièce et celle d'un accessoire portent le MÊME badge au même
    /// endroit, donc la mesure des accessoires décrit les deux ; ce qu'elle ne
    /// décrit pas, c'est la hauteur que ce bandeau prend lui-même à la liste
    /// des pièces, et ce n'est pas la ligne de compatibilité qui la change.
    for (final ecran in ecrans.entries) {
      for (final echelle in echelles) {
        testWidgets(
          'accessoires vus par un CLIENT en ${ecran.key}, texte x$echelle : '
          'la densité, avant et après',
          (tester) async {
            Future<(int entieres, int posees, double hauteur, double liste)>
            compter(Map<String, dynamic>? compat) async {
              await poserAccessoires(
                tester,
                ecran: ecran.value,
                echelle: echelle,
                locale: localeFr,
                compat: compat,
                session: const AuthState(type: AuthType.client),
              );

              final vue = tester.getRect(find.byType(Viewport).first);
              final cartes = tester
                  .renderObjectList<RenderBox>(
                    find.descendant(
                      of: find.byType(Viewport).first,
                      matching: find.byType(Card),
                    ),
                  )
                  .map(
                    (b) => Rect.fromPoints(
                      b.localToGlobal(Offset.zero),
                      b.localToGlobal(b.size.bottomRight(Offset.zero)),
                    ),
                  )
                  .toList();

              return (
                cartes.where((r) => r.bottom <= vue.bottom + 0.01).length,
                cartes.length,
                cartes.isEmpty ? 0.0 : cartes.first.height,
                vue.height,
              );
            }

            final avant = await compter(null);
            final apres = await compter(maquette());

            // ignore: avoid_print
            print(
              '@@DENSITÉ client ${ecran.key} x$echelle : '
              'liste ${avant.$4.toStringAsFixed(1)} ; '
              'carte ${avant.$3.toStringAsFixed(1)} → '
              '${apres.$3.toStringAsFixed(1)} '
              '(+${(apres.$3 - avant.$3).toStringAsFixed(1)}) ; '
              'entières ${avant.$1} → ${apres.$1} '
              '(posées ${avant.$2} → ${apres.$2})',
            );

            expect(avant.$2, greaterThan(0));

            expect(
              apres.$1,
              greaterThanOrEqualTo(avant.$1 - 2),
              reason:
                  'La ligne coûte ${avant.$1 - apres.$1} annonce(s) entière(s) '
                  'à un CLIENT en ${ecran.key} à l\'échelle $echelle : '
                  '${avant.$1} avant, ${apres.$1} après, pour '
                  '${avant.$4.toStringAsFixed(1)} points de liste et une carte '
                  'passée de ${avant.$3.toStringAsFixed(1)} à '
                  '${apres.$3.toStringAsFixed(1)}.',
            );
          },
        );
      }
    }
  });
}

/// Une pièce et un accessoire tirés des gabarits du serveur : les listes des
/// pièces et des accessoires doivent porter de VRAIES cartes pour que la mesure
/// du dégagement de bas de liste veuille dire quelque chose.
///
/// [compatibilite] remplace la clé `compatibility` du gabarit. `null` la
/// RETIRE, ce qui est l'état exact d'une réponse dont le contrôleur n'a pas
/// chargé la relation — et c'est l'état « AVANT » du tableau de densité de la
/// section 8 : la carte sans sa ligne de compatibilité.
Part _piece({Map<String, dynamic>? compatibilite = _absente}) =>
    Part.fromJson(_gabaritPiece(compatibilite));

Accessory _accessoire({Map<String, dynamic>? compatibilite = _absente}) =>
    Accessory.fromJson(_gabaritAccessoire(compatibilite));

/// Le marqueur « ne touche pas à la clé du gabarit ».
///
/// Il faut distinguer trois cas et non deux : garder ce que le gabarit porte,
/// RETIRER la clé, ou poser un résumé. `null` ne peut pas en désigner deux, et
/// un `bool` de plus se serait mal lu sur les sites d'appel.
const Map<String, dynamic> _absente = {'@': 'gabarit'};

Map<String, dynamic> _gabaritPiece(Map<String, dynamic>? compatibilite) {
  final json =
      jsonDecode(
            jsonEncode(
              (jsonDecode(File('test/fixtures/parts_list.json').readAsStringSync())
                      as Map<String, dynamic>)['data'][0],
            ),
          )
          as Map<String, dynamic>;
  if (!identical(compatibilite, _absente)) {
    if (compatibilite == null) {
      json.remove('compatibility');
    } else {
      json['compatibility'] = compatibilite;
    }
  }
  return json;
}

Map<String, dynamic> _gabaritAccessoire(Map<String, dynamic>? compatibilite) {
  final json =
      jsonDecode(
            jsonEncode(
              (jsonDecode(
                        File(
                          'test/fixtures/accessories_list.json',
                        ).readAsStringSync(),
                      )
                      as Map<String, dynamic>)['data'][0],
            ),
          )
          as Map<String, dynamic>;
  if (!identical(compatibilite, _absente)) {
    if (compatibilite == null) {
      json.remove('compatibility');
    } else {
      json['compatibility'] = compatibilite;
    }
  }
  return json;
}

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

// ── Les quatre destinations de la barre du bas ──────────────────────────────

/// Icône et intitulé, dans l'ordre de `_AppShell`.
///
/// Les icônes sont recopiées — elles ne sont pas traduisibles et `_tabs` est
/// privé —, mais les INTITULÉS sont lus dans `AppLocalizations` : c'est la
/// seule partie qui pouvait diverger de l'application sans se voir.
List<({IconData icone, String nom})> _destinations(AppLocalizations l10n) => [
  (icone: Icons.home_outlined, nom: l10n.commonHome),
  (icone: Icons.directions_car_outlined, nom: l10n.commonVehicles),
  (icone: Icons.tune_outlined, nom: l10n.commonAccessories),
  (icone: Icons.settings_outlined, nom: l10n.commonParts),
];
