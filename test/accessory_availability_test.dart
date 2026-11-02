import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/core/api/endpoints.dart';
import 'package:auto/core/local/catalog_local_cache.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/catalog_repository.dart';
import 'package:auto/features/catalog/presentation/pages/accessory_list_page.dart';
import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth(super.state);

  void change(AuthState value) => state = value;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _accessory({bool available = true, int id = 1}) {
  final fixture =
      jsonDecode(File('test/fixtures/accessories_list.json').readAsStringSync())
          as Map<String, dynamic>;
  final accessory = (fixture['data'] as List).first as Map<String, dynamic>;
  accessory['id'] = id;
  (accessory['stock'] as Map<String, dynamic>)['is_available'] = available;
  return accessory;
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
  bool available = true;
  final calls = <({String path, Map<String, dynamic>? params})>[];
  Future<Map<String, dynamic>> Function(String, Map<String, dynamic>?)? respond;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    calls.add((path: path, params: params));
    if (respond != null) return respond!(path, params);
    return _page([
      if (path == Endpoints.staffAccessories || available)
        _accessory(available: available),
    ]);
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    expect(path, Endpoints.accessoryAvailability(1));
    available = !available;
    return {'is_available': available};
  }
}

void main() {
  test(
    'public and staff listings use their own route with the same filters',
    () async {
      final client = _Client();
      final repository = CatalogRepository(client, CatalogLocalCache());
      await repository.getAccessories();
      expect(client.calls.single.path, Endpoints.catalogAccessories);

      await repository.getAccessories(
        forStaff: true,
        page: 2,
        perPage: 10,
        search: 'coffre',
        category: 'utilitaire',
        manufacturerId: '5',
        priceMax: 120000,
        vehicleModelId: 3,
        city: 'Ouagadougou',
        locationId: 4,
      );
      expect(client.calls.last.path, Endpoints.staffAccessories);
      expect(client.calls.last.params, {
        'page': 2,
        'per_page': 10,
        'q': 'coffre',
        'category': 'utilitaire',
        'manufacturer_id': '5',
        'price_max': 120000,
        'vehicle_model_id': 3,
        'city': 'Ouagadougou',
        'location_id': 4,
      });
    },
  );

  test('accessory detail follows the public or staff route', () async {
    final client = _Client();
    client.respond = (_, _) async => {'data': _accessory(available: false)};
    final repository = CatalogRepository(client, CatalogLocalCache());
    await repository.getAccessory(1);
    await repository.getAccessory(1, forStaff: true);
    expect(client.calls.map((call) => call.path), [
      Endpoints.accessoryDetail(1),
      Endpoints.staffAccessoryDetail(1),
    ]);

    final auth = _Auth(const AuthState(type: AuthType.staff));
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((_) => auth),
        catalogRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      accessoryDetailProvider(1),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(accessoryDetailProvider(1).future);
    expect(client.calls.last.path, Endpoints.staffAccessoryDetail(1));
    auth.change(const AuthState());
    await container.read(accessoryDetailProvider(1).future);
    expect(client.calls.last.path, Endpoints.accessoryDetail(1));
  });

  test(
    'staff can find and reactivate an accessory after marking unavailable',
    () async {
      final client = _Client();
      final repository = CatalogRepository(client, CatalogLocalCache());
      final auth = _Auth(const AuthState(type: AuthType.staff));
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((_) => auth),
          catalogRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(accessoryListProvider, (_, _) {});
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(accessoryListProvider).items.single.stock.isAvailable,
        isTrue,
      );
      final notifier = container.read(accessoryListProvider.notifier);
      await repository.toggleAccessoryAvailability(1);
      await notifier.refresh();
      expect(container.read(accessoryListProvider).items.single.id, 1);
      expect(
        container.read(accessoryListProvider).items.single.stock.isAvailable,
        isFalse,
      );
      expect(
        client.calls.every((call) => call.path == Endpoints.staffAccessories),
        isTrue,
      );

      auth.change(const AuthState());
      await Future<void>.delayed(Duration.zero);
      expect(container.read(accessoryListProvider).items, isEmpty);
      expect(client.calls.last.path, Endpoints.catalogAccessories);

      auth.change(const AuthState(type: AuthType.staff));
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(accessoryListProvider).items.single.stock.isAvailable,
        isFalse,
      );
      await repository.toggleAccessoryAvailability(1);
      await container.read(accessoryListProvider.notifier).refresh();
      expect(
        container.read(accessoryListProvider).items.single.stock.isAvailable,
        isTrue,
      );
    },
  );

  for (final fails in [false, true]) {
    test(
      'late staff ${fails ? 'error' : 'response'} cannot overwrite public list',
      () async {
        final pending = Completer<Map<String, dynamic>>();
        final client = _Client();
        client.respond = (path, _) => path == Endpoints.staffAccessories
            ? pending.future
            : Future.value(_page([]));
        final auth = _Auth(const AuthState(type: AuthType.staff));
        final container = ProviderContainer(
          overrides: [
            authProvider.overrideWith((_) => auth),
            catalogRepositoryProvider.overrideWithValue(
              CatalogRepository(client, CatalogLocalCache()),
            ),
          ],
        );
        addTearDown(container.dispose);
        final subscription = container.listen(accessoryListProvider, (_, _) {});
        addTearDown(subscription.close);
        await Future<void>.delayed(Duration.zero);
        expect(client.calls.single.path, Endpoints.staffAccessories);

        auth.change(const AuthState());
        await Future<void>.delayed(Duration.zero);
        expect(client.calls.last.path, Endpoints.catalogAccessories);
        expect(container.read(accessoryListProvider).isEmpty, isTrue);
        if (fails) {
          pending.completeError(
            const ApiException(message: 'Expired staff call'),
          );
        } else {
          pending.complete(_page([_accessory(available: false)]));
        }
        await Future<void>.delayed(Duration.zero);
        final state = container.read(accessoryListProvider);
        expect(state.isEmpty, isTrue);
        expect(state.error, isNull);
        expect(state.isLoading, isFalse);
      },
    );
  }

  test(
    'a late response from the old filter cannot restore its items',
    () async {
      final pending = Completer<Map<String, dynamic>>();
      final client = _Client();
      client.respond = (_, params) => params!['q'] == 'new'
          ? Future.value(_page([_accessory(id: 2)]))
          : pending.future;
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((_) => _Auth(const AuthState())),
          catalogRepositoryProvider.overrideWithValue(
            CatalogRepository(client, CatalogLocalCache()),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(accessoryListProvider, (_, _) {});
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);
      container.read(accessoryFilterProvider.notifier).state =
          const AccessoryFilter(search: 'new');
      await Future<void>.delayed(Duration.zero);
      expect(container.read(accessoryListProvider).items.single.id, 2);
      pending.complete(_page([_accessory(id: 1)]));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(accessoryListProvider).items.single.id, 2);
    },
  );
  testWidgets('staff can keep a category containing only unavailable stock', (
    tester,
  ) async {
    final auth = _Auth(
      const AuthState(
        type: AuthType.staff,
        staffUser: StaffUser(
          id: 1,
          name: 'Administrateur',
          email: 'admin@autoparc.bf',
          role: 'admin',
        ),
      ),
    );
    final client = _Client()..available = false;
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((_) => auth),
        catalogRepositoryProvider.overrideWithValue(
          CatalogRepository(client, CatalogLocalCache()),
        ),
        accessoryFilterProvider.overrideWith(
          (_) => const AccessoryFilter(category: 'utilitaire'),
        ),
        categoriesAccessoiresOccupeesProvider.overrideWith((_) async => {}),
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
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AccessoryListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final chip = find.widgetWithText(FilterChip, 'Utilitaire');
    expect(chip, findsOneWidget);
    expect(tester.widget<FilterChip>(chip).selected, isTrue);
    expect(container.read(accessoryFilterProvider).category, 'utilitaire');

    await tester.tap(find.text('✗'));
    await tester.pumpAndSettle();
    expect(find.text('✓'), findsOneWidget);
    await tester.tap(find.text('✓'));
    await tester.pumpAndSettle();
    expect(find.text('✗'), findsOneWidget);
    expect(
      container.read(accessoryListProvider).items.single.stock.isAvailable,
      isFalse,
    );
    expect(container.read(accessoryFilterProvider).category, 'utilitaire');

    auth.change(const AuthState());
    await tester.pumpAndSettle();
    expect(find.byType(FilterChip), findsNothing);
    expect(container.read(accessoryFilterProvider).category, isNull);
    expect(tester.takeException(), isNull);
  });
}
