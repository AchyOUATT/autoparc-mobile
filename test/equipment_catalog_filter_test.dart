import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/core/api/endpoints.dart';
import 'package:auto/core/local/catalog_local_cache.dart';
import 'package:auto/core/theme/app_theme.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/catalog_repository.dart';
import 'package:auto/features/catalog/data/models/catalog_vehicle_item.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_list_page.dart';
import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:auto/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/shared/models/paged_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/polices.dart';

const _emptyPage = {
  'data': <Map<String, dynamic>>[],
  'meta': {'current_page': 1, 'last_page': 1, 'total': 0, 'per_page': 20},
  'links': {'next': null},
};

class _Client extends ApiClient {
  final calls = <({String path, Map<String, dynamic>? params})>[];
  bool unifiedNotFound = false;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    calls.add((path: path, params: params));
    if (unifiedNotFound && path == Endpoints.catalogVehicleListings) {
      throw const ApiException(statusCode: 404, message: 'Not found');
    }
    return _emptyPage;
  }
}

class _Guest extends StateNotifier<AuthState> implements AuthNotifier {
  _Guest() : super(const AuthState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyVehicleList extends VehicleListNotifier {
  @override
  PagedState<CatalogVehicleItem> build() {
    ref.watch(vehicleFilterProvider);
    return const PagedState(
      items: [],
      total: 0,
      hasMore: false,
      isLoading: false,
      isLoadingMore: false,
    );
  }
}

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

const _equipment = Vehicle(
  id: 42,
  reference: 'EQUIPMENT-42',
  designation: 'Caterpillar 320',
  registrationStatus: 'unregistered',
  assetKind: 'equipment',
  equipmentType: 'excavator',
  vehicleType: '',
  identity: VehicleIdentity(brand: 'Caterpillar', model: '320'),
  commercial: VehicleCommercial(
    condition: 'used',
    status: 'in_stock',
    availability: 'sale',
    currency: 'XOF',
    priceNegotiable: false,
  ),
  faultsCount: 0,
  mediaUrls: [],
);

void main() {
  setUpAll(chargerPolices);

  test(
    'equipment criteria default to a mixed catalogue and clear independently',
    () {
      const mixed = VehicleFilter();
      expect(mixed.assetKind, isNull);
      expect(mixed.equipmentType, isNull);

      const equipment = VehicleFilter(
        assetKind: 'equipment',
        equipmentType: 'excavator',
        search: 'Caterpillar',
        availability: 'rent',
        city: 'Ouagadougou',
        priceMax: 20000000,
      );
      final copied = equipment.copyWith(city: 'Bobo-Dioulasso');
      expect(copied.assetKind, 'equipment');
      expect(copied.equipmentType, 'excavator');

      final typeCleared = equipment.copyWith(clearEquipmentType: true);
      expect(typeCleared.assetKind, 'equipment');
      expect(typeCleared.equipmentType, isNull);
      final cleared = equipment.copyWith(
        clearAssetKind: true,
        clearEquipmentType: true,
      );
      expect(cleared.assetKind, isNull);
      expect(cleared.equipmentType, isNull);
      expect(cleared.search, 'Caterpillar');
      expect(cleared.availability, 'rent');
      expect(cleared.city, 'Ouagadougou');
      expect(cleared.priceMax, 20000000);
    },
  );

  group('equipment catalogue requests', () {
    late _Client client;
    late CatalogRepository repository;

    setUp(() {
      client = _Client();
      repository = CatalogRepository(client, CatalogLocalCache());
    });

    test(
      'unified feed sends equipment criteria with the existing filters',
      () async {
        await repository.getVehicleListings(
          assetKind: 'equipment',
          equipmentType: 'excavator',
          search: 'Caterpillar',
          availability: 'rent',
          city: 'Ouagadougou',
        );

        expect(client.calls.single.path, Endpoints.catalogVehicleListings);
        expect(
          client.calls.single.params,
          containsPair('asset_kind', 'equipment'),
        );
        expect(
          client.calls.single.params,
          containsPair('equipment_type', 'excavator'),
        );
        expect(client.calls.single.params, containsPair('q', 'Caterpillar'));
        expect(
          client.calls.single.params,
          containsPair('available_for_rent', '1'),
        );
        expect(client.calls.single.params, containsPair('city', 'Ouagadougou'));
        expect(client.calls.single.params, isNot(contains('vehicle_type')));
      },
    );

    test('legacy stock endpoint sends the same criteria', () async {
      await repository.getVehicles(
        assetKind: 'equipment',
        equipmentType: 'forklift',
      );

      expect(client.calls.single.path, Endpoints.catalogVehicles);
      expect(
        client.calls.single.params,
        containsPair('asset_kind', 'equipment'),
      );
      expect(
        client.calls.single.params,
        containsPair('equipment_type', 'forklift'),
      );
    });

    test('404 fallback retains equipment criteria', () async {
      client.unifiedNotFound = true;
      await repository.getVehicleListings(
        assetKind: 'equipment',
        equipmentType: 'generator',
      );

      expect(client.calls.map((call) => call.path), [
        Endpoints.catalogVehicleListings,
        Endpoints.catalogVehicles,
      ]);
      for (final call in client.calls) {
        expect(call.params, containsPair('asset_kind', 'equipment'));
        expect(call.params, containsPair('equipment_type', 'generator'));
      }
    });

    test(
      'mixed catalogue omits both criteria and road filtering remains explicit',
      () async {
        await repository.getVehicleListings();
        await repository.getVehicles(assetKind: 'road_vehicle');

        expect(client.calls.first.params, isNot(contains('asset_kind')));
        expect(client.calls.first.params, isNot(contains('equipment_type')));
        expect(
          client.calls.last.params,
          containsPair('asset_kind', 'road_vehicle'),
        );
        expect(client.calls.last.params, isNot(contains('equipment_type')));
      },
    );
  });

  test(
    'list notifier forwards equipment selection and reset to the repository',
    () async {
      final client = _Client();
      final container = ProviderContainer(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(
            CatalogRepository(client, CatalogLocalCache()),
          ),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(vehicleFilterProvider.notifier)
          .state = const VehicleFilter(
        assetKind: 'equipment',
        equipmentType: 'telehandler',
        city: 'Ouagadougou',
      );
      final subscription = container.listen(vehicleListProvider, (_, _) {});
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);

      expect(
        client.calls.single.params,
        containsPair('asset_kind', 'equipment'),
      );
      expect(
        client.calls.single.params,
        containsPair('equipment_type', 'telehandler'),
      );
      expect(client.calls.single.params, containsPair('city', 'Ouagadougou'));

      container.read(vehicleFilterProvider.notifier).state =
          const VehicleFilter();
      await Future<void>.delayed(Duration.zero);
      expect(client.calls, hasLength(2));
      expect(client.calls.last.params, isNot(contains('asset_kind')));
      expect(client.calls.last.params, isNot(contains('equipment_type')));
    },
  );

  testWidgets('equipment chip and type menu update the real catalogue filter', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((_) => _Guest()),
        vehicleListProvider.overrideWith(_EmptyVehicleList.new),
        dealCountProvider.overrideWith((_) async => 0),
        unreadCountProvider.overrideWith((_) async => 0),
        catalogRefsProvider.overrideWith((_) async => _refs),
      ],
    );
    addTearDown(container.dispose);
    container.read(vehicleFilterProvider.notifier).state = const VehicleFilter(
      vehicleType: 'utility',
      bodyStyle: 'pickup',
      registrationStatus: 'registered',
      customsCleared: true,
      availability: 'rent',
      city: 'Ouagadougou',
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: themeAutoParc(Brightness.light),
          home: const VehicleListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final equipmentChip = find.widgetWithText(
      FilterChip,
      l10n.vehicleRegistrationEquipmentTitle,
    );
    await tester.ensureVisible(equipmentChip);
    await tester.tap(equipmentChip);
    await tester.pumpAndSettle();
    var filter = container.read(vehicleFilterProvider);
    expect(filter.assetKind, 'equipment');
    expect(filter.vehicleType, isNull);
    expect(filter.bodyStyle, isNull);
    expect(filter.registrationStatus, isNull);
    expect(filter.customsCleared, isNull);
    expect(filter.availability, 'rent');
    expect(filter.city, 'Ouagadougou');

    final typeMenu = find.byKey(
      const ValueKey('catalog-equipment-type-filter'),
    );
    await tester.ensureVisible(typeMenu);
    await tester.tap(typeMenu);
    await tester.pumpAndSettle();
    final choices = tester.widgetList<PopupMenuItem<String>>(
      find.byWidgetPredicate((widget) => widget is PopupMenuItem<String>),
    );
    expect(
      choices.map((item) => item.value).whereType<String>(),
      containsAll([
        'agricultural_tractor',
        'aerial_platform',
        'excavator',
        'backhoe_loader',
        'loader',
        'telehandler',
        'forklift',
        'generator',
        'other',
      ]),
    );
    final excavator = find.widgetWithText(
      PopupMenuItem<String>,
      l10n.equipmentTypeExcavator,
    );
    await tester.ensureVisible(excavator);
    await tester.tap(excavator);
    await tester.pumpAndSettle();
    filter = container.read(vehicleFilterProvider);
    expect(filter.assetKind, 'equipment');
    expect(filter.equipmentType, 'excavator');

    for (final (label, status) in [
      (l10n.catalogRegistered, 'registered'),
      (l10n.catalogNotRegistered, 'unregistered'),
    ]) {
      final registrationChip = find.widgetWithText(FilterChip, label);
      await tester.ensureVisible(registrationChip);
      await tester.tap(registrationChip);
      await tester.pumpAndSettle();
      filter = container.read(vehicleFilterProvider);
      expect(filter.assetKind, 'road_vehicle');
      expect(filter.registrationStatus, status);
      expect(filter.equipmentType, isNull);
      expect(filter.availability, 'rent');
      expect(filter.city, 'Ouagadougou');

      await tester.ensureVisible(equipmentChip);
      await tester.tap(equipmentChip);
      await tester.pumpAndSettle();
      filter = container.read(vehicleFilterProvider);
      expect(filter.registrationStatus, isNull);
      expect(filter.customsCleared, isNull);

      await tester.ensureVisible(typeMenu);
      await tester.tap(typeMenu);
      await tester.pumpAndSettle();
      await tester.ensureVisible(excavator);
      await tester.tap(excavator);
      await tester.pumpAndSettle();
      filter = container.read(vehicleFilterProvider);
      expect(filter.assetKind, 'equipment');
      expect(filter.equipmentType, 'excavator');
    }

    final utilityChip = find.widgetWithText(
      FilterChip,
      l10n.catalogVehicleTypeUtility,
    );
    await tester.ensureVisible(utilityChip);
    await tester.tap(utilityChip);
    await tester.pumpAndSettle();
    filter = container.read(vehicleFilterProvider);
    expect(filter.assetKind, 'road_vehicle');
    expect(filter.vehicleType, 'utility');
    expect(filter.equipmentType, isNull);

    await tester.ensureVisible(equipmentChip);
    await tester.tap(equipmentChip);
    await tester.pumpAndSettle();
    final sedanChip = find.widgetWithText(
      FilterChip,
      libelleCarrosserieFiltre(l10n, 'sedan'),
    );
    await tester.ensureVisible(sedanChip);
    await tester.tap(sedanChip);
    await tester.pumpAndSettle();
    filter = container.read(vehicleFilterProvider);
    expect(filter.assetKind, 'road_vehicle');
    expect(filter.bodyStyle, 'sedan');
    expect(filter.equipmentType, isNull);

    final roadChip = find.widgetWithText(
      FilterChip,
      l10n.vehicleRegistrationRoadTitle,
    );
    await tester.ensureVisible(roadChip);
    await tester.tap(roadChip);
    await tester.pumpAndSettle();
    filter = container.read(vehicleFilterProvider);
    expect(filter.assetKind, isNull);
    expect(filter.bodyStyle, isNull);
    expect(filter.vehicleType, isNull);
    expect(filter.registrationStatus, isNull);
    expect(filter.customsCleared, isNull);

    await tester.ensureVisible(equipmentChip);
    await tester.tap(equipmentChip);
    await tester.pumpAndSettle();
    await tester.ensureVisible(equipmentChip);
    await tester.tap(equipmentChip);
    await tester.pumpAndSettle();
    filter = container.read(vehicleFilterProvider);
    expect(filter.assetKind, isNull);
    expect(filter.equipmentType, isNull);
    expect(filter.availability, 'rent');
    expect(filter.city, 'Ouagadougou');
    expect(tester.takeException(), isNull);
  });

  for (final language in ['fr', 'en']) {
    testWidgets(
      'equipment card labels its type without invented year or mileage in $language',
      (tester) async {
        final l10n = await AppLocalizations.delegate.load(Locale(language));
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: themeAutoParc(Brightness.light),
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: SizedBox(
                    width: 180,
                    child: VehicleCard(vehicle: _equipment),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Caterpillar 320'), findsOneWidget);
        expect(
          find.textContaining(l10n.equipmentTypeExcavator),
          findsOneWidget,
        );
        expect(find.textContaining('(0)'), findsNothing);
        expect(find.textContaining('0 km'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
