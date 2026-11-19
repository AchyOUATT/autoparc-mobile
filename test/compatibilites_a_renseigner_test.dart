import 'dart:convert';
import 'dart:io';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/endpoints.dart';
import 'package:auto/core/local/catalog_local_cache.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/catalog_repository.dart';
import 'package:auto/features/catalog/data/models/compatibility_summary.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/providers/garage_provider.dart';
import 'package:auto/features/catalog/presentation/pages/accessory_list_page.dart';
import 'package:auto/features/catalog/presentation/pages/part_list_page.dart';
import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:auto/features/catalog/presentation/widgets/fitments_section.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/langues.dart';

class _GarageVide extends GarageNotifier {
  @override
  Future<List<OwnedVehicle>> build() async => const [];
}

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth(super.state);
  void change(AuthState value) => state = value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _admin = AuthState(
  type: AuthType.staff,
  staffUser: StaffUser(
    id: 1,
    name: 'Administrateur',
    email: 'admin@autoparc.bf',
    role: 'admin',
  ),
);

const _magasin = AuthState(
  type: AuthType.staff,
  staffUser: StaffUser(
    id: 2,
    name: 'Magasinier',
    email: 'stock@autoparc.bf',
    role: 'warehouse',
  ),
);

const _refs = CatalogRefs(
  brands: [BrandRef(id: 3, name: 'Toyota', isActive: true)],
  vehicleModels: [ModelRef(id: 11, brandId: 3, name: 'Corolla')],
  trims: [],
  engineTypes: [
    EngineTypeRef(
      id: 8,
      code: 'petrol',
      label: 'Essence',
      usesFuel: true,
      usesBattery: false,
    ),
  ],
  drivetrains: [DrivetrainRef(id: 2, code: 'fwd', label: 'Traction')],
  colors: [],
  features: [],
  locations: [],
);

Map<String, dynamic> _piece({
  int id = 1,
  bool active = true,
  String? name,
  int compatCount = 0,
  List<Map<String, dynamic>>? fitments,
}) {
  final fixture =
      jsonDecode(File('test/fixtures/parts_list.json').readAsStringSync())
          as Map<String, dynamic>;
  final piece = Map<String, dynamic>.from(
    (fixture['data'] as List).first as Map<String, dynamic>,
  );
  piece['id'] = id;
  piece['is_active'] = active;
  if (name != null) piece['name'] = name;
  piece['compatibility'] = {
    'count': compatCount,
    'vehicles': compatCount > 0 ? ['Corolla'] : [],
  };
  piece['fitments'] =
      fitments ??
      (compatCount > 0
          ? [
              {'vehicle_model_id': 11},
            ]
          : []);
  return piece;
}

Map<String, dynamic> _accessoire({
  int id = 1,
  bool active = true,
  String? name,
  int compatCount = 0,
}) {
  final fixture =
      jsonDecode(File('test/fixtures/accessories_list.json').readAsStringSync())
          as Map<String, dynamic>;
  final article = Map<String, dynamic>.from(
    (fixture['data'] as List).first as Map<String, dynamic>,
  );
  article['id'] = id;
  article['is_active'] = active;
  if (name != null) article['name'] = name;
  article['compatibility'] = {
    'count': compatCount,
    'vehicles': compatCount > 0 ? ['Corolla'] : [],
  };
  article['fitments'] = compatCount > 0
      ? [
          {'vehicle_model_id': 11},
        ]
      : [];
  return article;
}

Map<String, dynamic> _page(List<Map<String, dynamic>> items) => {
  'data': items,
  'meta': {
    'current_page': 1,
    'last_page': 1,
    'total': items.length,
    'per_page': 20,
  },
  'links': {'next': null},
};

class _Client extends ApiClient {
  final calls = <({String path, Map<String, dynamic>? params})>[];
  Future<Map<String, dynamic>> Function(String, Map<String, dynamic>?)? respond;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    calls.add((path: path, params: params));
    if (respond != null) return respond!(path, params);
    return _page(const []);
  }
}

List<Override> _surcharges({
  required _Auth auth,
  required CatalogRepository depot,
  PartFilter? filtrePiece,
  AccessoryFilter? filtreAccessoire,
}) => [
  authProvider.overrideWith((_) => auth),
  catalogRepositoryProvider.overrideWithValue(depot),
  catalogRefsProvider.overrideWith((_) async => _refs),
  categoriesAvecPiecesProvider.overrideWith((_) async => const []),
  categoriesAccessoiresOccupeesProvider.overrideWith((_) async => <String>{}),
  garageProvider.overrideWith(_GarageVide.new),
  if (filtrePiece != null) partFilterProvider.overrideWith((_) => filtrePiece),
  if (filtreAccessoire != null)
    accessoryFilterProvider.overrideWith((_) => filtreAccessoire),
];

void main() {
  test('aRenseigner s\'appuie sur le résumé, sinon sur les fitments', () {
    expect(
      CompatibilitySummary.aRenseigner(
        resume: const CompatibilitySummary(count: 0, vehicles: []),
        fitments: [
          {'vehicle_model_id': 1},
        ],
      ),
      isTrue,
      reason: 'Le résumé vide prime : il compte aussi les applications OEM.',
    );
    expect(
      CompatibilitySummary.aRenseigner(
        resume: const CompatibilitySummary(count: 2, vehicles: ['Corolla']),
      ),
      isFalse,
    );
    expect(CompatibilitySummary.aRenseigner(fitments: const []), isTrue);
    expect(
      CompatibilitySummary.aRenseigner(
        fitments: [
          {'vehicle_model_id': 1},
        ],
      ),
      isFalse,
    );
    expect(
      CompatibilitySummary.aRenseigner(),
      isFalse,
      reason: 'Sans information, on n\'affiche pas le badge.',
    );
  });

  test('le personnel envoie without_fitments seulement sur sa route', () async {
    final client = _Client();
    final repository = CatalogRepository(client, CatalogLocalCache());

    await repository.getParts(withoutFitments: true);
    expect(client.calls.single.path, Endpoints.catalogParts);
    expect(
      client.calls.single.params?.containsKey('without_fitments'),
      isFalse,
    );

    await repository.getParts(forStaff: true, withoutFitments: true);
    expect(client.calls.last.path, Endpoints.staffParts);
    expect(client.calls.last.params?['without_fitments'], 1);

    await repository.getAccessories(forStaff: true, withoutFitments: true);
    expect(client.calls.last.path, Endpoints.staffAccessories);
    expect(client.calls.last.params?['without_fitments'], 1);
  });

  test(
    'la liste du personnel envoie without_fitments quand le filtre est posé',
    () async {
      final client = _Client();
      client.respond = (_, _) async =>
          _page([_piece(id: 11, name: 'Filtre sans application')]);
      final container = ProviderContainer(
        overrides: _surcharges(
          auth: _Auth(_admin),
          depot: CatalogRepository(client, CatalogLocalCache()),
          filtrePiece: const PartFilter(withoutFitments: true),
        ),
      );
      addTearDown(container.dispose);
      final subscription = container.listen(partListProvider, (_, _) {});
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);
      expect(client.calls.single.path, Endpoints.staffParts);
      expect(client.calls.single.params?['without_fitments'], 1);
      expect(
        container.read(partListProvider).items.single.name,
        'Filtre sans application',
      );
    },
  );

  test(
    'un serveur qui ignore without_fitments est filtré côté client',
    () async {
      final client = _Client();
      client.respond = (_, _) async => _page([
        _piece(id: 1, name: 'Filtre sans application', compatCount: 0),
        _piece(id: 2, name: 'Filtre déjà renseigné', compatCount: 1),
      ]);
      final container = ProviderContainer(
        overrides: _surcharges(
          auth: _Auth(_admin),
          depot: CatalogRepository(client, CatalogLocalCache()),
          filtrePiece: const PartFilter(withoutFitments: true),
        ),
      );
      addTearDown(container.dispose);
      final subscription = container.listen(partListProvider, (_, _) {});
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);
      final noms = container.read(partListProvider).items.map((p) => p.name);
      expect(noms, ['Filtre sans application']);
    },
  );

  Future<ProviderContainer> ouvrir(
    WidgetTester tester, {
    required Widget page,
    required AuthState etat,
    List<Map<String, dynamic>> articles = const [],
    Locale locale = localeFr,
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final client = _Client();
    client.respond = (path, _) async {
      if (path.contains('accessories') || path.contains('parts')) {
        return _page(articles);
      }
      return _page(const []);
    };
    final container = ProviderContainer(
      overrides: _surcharges(
        auth: _Auth(etat),
        depot: CatalogRepository(client, CatalogLocalCache()),
      ),
    );
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: page,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return container;
  }

  testWidgets(
    'la pastille À renseigner apparaît pour un admin sur les pièces',
    (tester) async {
      await ouvrir(tester, page: const PartListPage(), etat: _admin);
      expect(find.widgetWithText(FilterChip, 'À renseigner'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('la pastille apparaît aussi sur les accessoires', (tester) async {
    await ouvrir(tester, page: const AccessoryListPage(), etat: _admin);
    expect(find.widgetWithText(FilterChip, 'À renseigner'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('un magasinier ne voit pas la pastille À renseigner', (
    tester,
  ) async {
    await ouvrir(tester, page: const PartListPage(), etat: _magasin);
    expect(find.widgetWithText(FilterChip, 'À renseigner'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('un client ne voit ni la pastille ni le badge', (tester) async {
    await ouvrir(
      tester,
      page: const PartListPage(),
      etat: const AuthState(type: AuthType.client),
      articles: [_piece(id: 4, name: 'Filtre public', compatCount: 0)],
    );
    expect(find.widgetWithText(FilterChip, 'À renseigner'), findsNothing);
    expect(find.text('Filtre public'), findsOneWidget);
    expect(find.text('À renseigner'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('poser la pastille filtre la liste et pose le badge', (
    tester,
  ) async {
    final container = await ouvrir(
      tester,
      page: const PartListPage(),
      etat: _admin,
      articles: [
        _piece(id: 2, name: 'Filtre sans application', compatCount: 0),
      ],
    );

    await tester.tap(find.widgetWithText(FilterChip, 'À renseigner'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(container.read(partFilterProvider).withoutFitments, isTrue);
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'À renseigner'))
          .selected,
      isTrue,
    );
    expect(find.text('Filtre sans application'), findsOneWidget);
    expect(find.text('À renseigner'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'le badge apparaît sur la carte d\'un accessoire sans compatibilité',
    (tester) async {
      await ouvrir(
        tester,
        page: const AccessoryListPage(),
        etat: _admin,
        articles: [
          _accessoire(id: 9, name: 'Coffre sans application', compatCount: 0),
        ],
      );
      expect(find.text('Coffre sans application'), findsOneWidget);
      expect(find.text('À renseigner'), findsWidgets);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('une pièce déjà compatible n\'a pas le badge', (tester) async {
    await ouvrir(
      tester,
      page: const PartListPage(),
      etat: _admin,
      articles: [_piece(id: 8, name: 'Filtre renseigné', compatCount: 2)],
    );
    expect(find.text('Filtre renseigné'), findsOneWidget);
    expect(find.text('À renseigner'), findsOneWidget); // la pastille seule
    expect(find.widgetWithText(FilterChip, 'À renseigner'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('les libellés anglais de la pastille et du badge', (
    tester,
  ) async {
    await ouvrir(
      tester,
      page: const PartListPage(),
      etat: _admin,
      articles: [_piece(id: 3, name: 'Oil filter', compatCount: 0)],
      locale: localeEn,
    );
    expect(find.widgetWithText(FilterChip, 'Needs fitment'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Needs fitment'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Oil filter'), findsOneWidget);
    expect(find.text('Needs fitment'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  group('Formulaire de compatibilité', () {
    late AppLocalizations textesFr;
    setUpAll(() async {
      textesFr = await chargerTextes(localeFr);
    });

    Widget hote({bool recommanderCodeMoteur = false}) => MaterialApp(
      locale: localeFr,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: FitmentsSection(
            refs: _refs,
            showPosition: true,
            recommanderCodeMoteur: recommanderCodeMoteur,
            initiales: const [],
            onChanged: (_) {},
          ),
        ),
      ),
    );

    Future<void> pomper(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('il propose le code moteur, la motorisation et la transmission', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(hote());
      await pomper(tester);
      await tester.tap(find.text('Ajouter une compatibilité'));
      await pomper(tester);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Code moteur'), findsOneWidget);
      expect(find.text('Motorisation'), findsOneWidget);
      expect(find.text('Transmission'), findsOneWidget);
      expect(
        find.text(
          'Pour un filtre à huile, le code moteur permet de distinguer deux références sur un même modèle.',
        ),
        findsNothing,
      );
    });

    testWidgets('un filtre à huile voit l\'aide sur le code moteur', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(hote(recommanderCodeMoteur: true));
      await pomper(tester);
      await tester.tap(find.text('Ajouter une compatibilité'));
      await pomper(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.ensureVisible(find.text('Code moteur'));
      await pomper(tester);
      expect(
        find.text(
          'Pour un filtre à huile, le code moteur permet de distinguer deux références sur un même modèle.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('on peut enregistrer une ligne avec le code moteur, ou sans', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final recues = <FitmentEntry>[];
      await tester.pumpWidget(
        MaterialApp(
          locale: localeFr,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: FitmentsSection(
                refs: _refs,
                showPosition: true,
                recommanderCodeMoteur: true,
                initiales: const [],
                onChanged: recues.addAll,
              ),
            ),
          ),
        ),
      );
      await pomper(tester);
      await tester.tap(find.text('Ajouter une compatibilité'));
      await pomper(tester);
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Marque *'));
      await pomper(tester);
      await tester.tap(find.text('Toyota').last);
      await pomper(tester);
      await tester.tap(find.text('Modèle *'));
      await pomper(tester);
      await tester.tap(find.text('Corolla').last);
      await pomper(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Code moteur'),
        '1ZZ-FE',
      );
      await tester.ensureVisible(find.text('Ajouter cette compatibilité'));
      await tester.tap(find.text('Ajouter cette compatibilité'));
      await pomper(tester);

      expect(recues, hasLength(1));
      expect(recues.single.engineCode, '1ZZ-FE');
      expect(recues.single.toJson()['engine_code'], '1ZZ-FE');
      expect(recues.single.labelDans(textesFr), contains('1ZZ-FE'));
    });

    test('FitmentEntry.saisie envoie motorisation et transmission', () async {
      const marque = BrandRef(id: 3, name: 'Toyota', isActive: true);
      const modele = ModelRef(id: 11, brandId: 3, name: 'Corolla');
      final textes = await chargerTextes(localeFr);
      final avecCode = FitmentEntry.saisie(
        brand: marque,
        model: modele,
        engineTypeId: 8,
        drivetrainId: 2,
        engineCode: '2ZR-FXE',
      );
      expect(avecCode.toJson(), {
        'vehicle_model_id': 11,
        'engine_type_id': 8,
        'drivetrain_id': 2,
        'engine_code': '2ZR-FXE',
      });
      expect(avecCode.labelDans(textes), contains('2ZR-FXE'));

      final sansCode = FitmentEntry.saisie(brand: marque, model: modele);
      expect(sansCode.toJson(), {'vehicle_model_id': 11});
    });
  });
}
