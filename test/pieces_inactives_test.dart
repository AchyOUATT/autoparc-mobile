import 'dart:convert';
import 'dart:io';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/endpoints.dart';
import 'package:auto/core/local/catalog_local_cache.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/catalog_repository.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/providers/garage_provider.dart';
import 'package:auto/features/catalog/presentation/pages/accessory_list_page.dart';
import 'package:auto/features/catalog/presentation/pages/part_list_page.dart';
import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';
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
  brands: [],
  vehicleModels: [],
  trims: [],
  engineTypes: [],
  drivetrains: [],
  colors: [],
  features: [],
  locations: [],
);

Map<String, dynamic> _piece({int id = 1, bool active = true, String? name}) {
  final fixture =
      jsonDecode(File('test/fixtures/parts_list.json').readAsStringSync())
          as Map<String, dynamic>;
  final piece = (fixture['data'] as List).first as Map<String, dynamic>;
  piece['id'] = id;
  piece['is_active'] = active;
  if (name != null) piece['name'] = name;
  return piece;
}

Map<String, dynamic> _accessoire({
  int id = 1,
  bool active = true,
  String? name,
}) {
  final fixture =
      jsonDecode(File('test/fixtures/accessories_list.json').readAsStringSync())
          as Map<String, dynamic>;
  final article = (fixture['data'] as List).first as Map<String, dynamic>;
  article['id'] = id;
  article['is_active'] = active;
  if (name != null) article['name'] = name;
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
}) => [
  authProvider.overrideWith((_) => auth),
  catalogRepositoryProvider.overrideWithValue(depot),
  catalogRefsProvider.overrideWith((_) async => _refs),
  categoriesAvecPiecesProvider.overrideWith((_) async => const []),
  categoriesAccessoiresOccupeesProvider.overrideWith((_) async => <String>{}),
  garageProvider.overrideWith(_GarageVide.new),
];

void main() {
  test('public and staff part listings use their own route', () async {
    final client = _Client();
    final repository = CatalogRepository(client, CatalogLocalCache());

    await repository.getParts();
    expect(client.calls.single.path, Endpoints.catalogParts);
    expect(client.calls.single.params, {'page': 1, 'per_page': 20});

    await repository.getParts(
      forStaff: true,
      page: 2,
      perPage: 10,
      search: 'filtre',
      inactiveOnly: true,
    );
    expect(client.calls.last.path, Endpoints.staffParts);
    expect(client.calls.last.params, {
      'page': 2,
      'per_page': 10,
      'q': 'filtre',
      'active_only': 0,
      'inactive_only': 1,
    });
  });

  test('part detail follows the public or staff route', () async {
    final client = _Client();
    client.respond = (_, _) async => {'data': _piece(active: false)};
    final repository = CatalogRepository(client, CatalogLocalCache());
    await repository.getPart(7);
    await repository.getPart(7, forStaff: true);
    expect(client.calls.map((call) => call.path), [
      Endpoints.partDetail(7),
      Endpoints.staffPartDetail(7),
    ]);
  });

  test(
    'partDetailProvider uses the staff route while signed in as staff',
    () async {
      final client = _Client();
      client.respond = (_, _) async => {'data': _piece(active: false)};
      final repository = CatalogRepository(client, CatalogLocalCache());
      final auth = _Auth(_admin);
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((_) => auth),
          catalogRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(partDetailProvider(7), (_, _) {});
      addTearDown(subscription.close);
      await container.read(partDetailProvider(7).future);
      expect(client.calls.last.path, Endpoints.staffPartDetail(7));

      auth.change(const AuthState());
      await container.read(partDetailProvider(7).future);
      expect(client.calls.last.path, Endpoints.partDetail(7));
    },
  );

  test('staff part list sends inactive_only when the filter is on', () async {
    final client = _Client();
    client.respond = (_, _) async =>
        _page([_piece(id: 11, active: false, name: 'Filtre inactif')]);
    final repository = CatalogRepository(client, CatalogLocalCache());
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((_) => _Auth(_admin)),
        catalogRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(partListProvider, (_, _) {});
    addTearDown(subscription.close);
    await Future<void>.delayed(Duration.zero);
    expect(client.calls.single.path, Endpoints.staffParts);
    expect(client.calls.single.params?['inactive_only'], isNull);

    container.read(partFilterProvider.notifier).state = const PartFilter(
      inactiveOnly: true,
    );
    await Future<void>.delayed(Duration.zero);
    expect(client.calls.last.path, Endpoints.staffParts);
    expect(client.calls.last.params?['inactive_only'], 1);
    expect(client.calls.last.params?['active_only'], 0);
    expect(container.read(partListProvider).items.single.isActive, isFalse);
  });

  test(
    'an old server that mixes active parts is still filtered client-side',
    () async {
      final client = _Client();
      client.respond = (_, _) async => _page([
        _piece(id: 1, active: true, name: 'Actif'),
        _piece(id: 2, active: false, name: 'Inactif'),
      ]);
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((_) => _Auth(_admin)),
          catalogRepositoryProvider.overrideWithValue(
            CatalogRepository(client, CatalogLocalCache()),
          ),
          partFilterProvider.overrideWith(
            (_) => const PartFilter(inactiveOnly: true),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(partListProvider, (_, _) {});
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(partListProvider).items, hasLength(1));
      expect(container.read(partListProvider).items.single.id, 2);
    },
  );

  test('staff accessory list also sends inactive_only', () async {
    final client = _Client();
    client.respond = (_, _) async =>
        _page([_accessoire(id: 4, active: false, name: 'Tapis inactif')]);
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((_) => _Auth(_admin)),
        catalogRepositoryProvider.overrideWithValue(
          CatalogRepository(client, CatalogLocalCache()),
        ),
        accessoryFilterProvider.overrideWith(
          (_) => const AccessoryFilter(inactiveOnly: true),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(accessoryListProvider, (_, _) {});
    addTearDown(subscription.close);
    await Future<void>.delayed(Duration.zero);
    expect(client.calls.single.path, Endpoints.staffAccessories);
    expect(client.calls.single.params?['inactive_only'], 1);
    expect(
      container.read(accessoryListProvider).items.single.isActive,
      isFalse,
    );
  });

  Future<ProviderContainer> ouvrir(
    WidgetTester tester, {
    required Widget page,
    required AuthState etat,
    List<Map<String, dynamic>> articles = const [],
    Locale locale = localeFr,
  }) async {
    // Un pompage precedent peut laisser un Timer (bandeau garage, fetch).
    // On evacue l'arbre avant d'en monter un autre dans le meme test.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final client = _Client();
    client.respond = (path, _) async {
      if (path.contains('accessories') || path.contains('parts')) {
        return _page(articles);
      }
      return _page(const []);
    };
    final auth = _Auth(etat);
    final container = ProviderContainer(
      overrides: _surcharges(
        auth: auth,
        depot: CatalogRepository(client, CatalogLocalCache()),
      ),
    );
    addTearDown(() async {
      container.dispose();
    });
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
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('la pastille Inactives apparait pour un admin sur les pieces', (
    tester,
  ) async {
    await ouvrir(tester, page: const PartListPage(), etat: _admin);
    expect(find.widgetWithText(FilterChip, 'Inactives'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('la pastille Inactives apparait aussi sur les accessoires', (
    tester,
  ) async {
    await ouvrir(tester, page: const AccessoryListPage(), etat: _admin);
    expect(find.widgetWithText(FilterChip, 'Inactives'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('un magasinier ne voit pas la pastille Inactives', (
    tester,
  ) async {
    await ouvrir(tester, page: const PartListPage(), etat: _magasin);
    expect(find.widgetWithText(FilterChip, 'Inactives'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('un client ne voit pas la pastille Inactives', (tester) async {
    await ouvrir(
      tester,
      page: const PartListPage(),
      etat: const AuthState(type: AuthType.client),
    );
    expect(find.widgetWithText(FilterChip, 'Inactives'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('poser la pastille Inactives filtre la liste des pieces', (
    tester,
  ) async {
    final container = await ouvrir(
      tester,
      page: const PartListPage(),
      etat: _admin,
      articles: [
        _piece(id: 2, active: false, name: 'Filtre habitacle inactif'),
      ],
    );

    await tester.tap(find.widgetWithText(FilterChip, 'Inactives'));
    await tester.pumpAndSettle();

    expect(container.read(partFilterProvider).inactiveOnly, isTrue);
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Inactives'))
          .selected,
      isTrue,
    );
    expect(find.text('Filtre habitacle inactif'), findsOneWidget);
    expect(find.text('Inactive'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'le badge Inactive apparait sur la carte d\'un accessoire inactif',
    (tester) async {
      await ouvrir(
        tester,
        page: const AccessoryListPage(),
        etat: _admin,
        articles: [_accessoire(id: 9, active: false, name: 'Tapis inactif')],
      );
      expect(find.text('Tapis inactif'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('un accessoire actif n\'a pas le badge Inactive', (tester) async {
    await ouvrir(
      tester,
      page: const AccessoryListPage(),
      etat: _admin,
      articles: [_accessoire(id: 8, active: true, name: 'Tapis actif')],
    );
    expect(find.text('Tapis actif'), findsOneWidget);
    expect(find.text('Inactive'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('les libelles anglais de la pastille et du badge', (
    tester,
  ) async {
    await ouvrir(
      tester,
      page: const PartListPage(),
      etat: _admin,
      articles: [_piece(id: 3, active: false, name: 'Cabin filter')],
      locale: localeEn,
    );
    expect(find.widgetWithText(FilterChip, 'Inactive'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Inactive'));
    await tester.pumpAndSettle();
    expect(find.text('Cabin filter'), findsOneWidget);
    expect(find.text('Inactive'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
