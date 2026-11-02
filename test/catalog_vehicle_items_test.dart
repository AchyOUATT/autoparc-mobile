import 'dart:convert';
import 'dart:io';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/core/api/endpoints.dart';
import 'package:auto/core/local/catalog_local_cache.dart';
import 'package:auto/features/catalog/data/catalog_repository.dart';
import 'package:auto/features/catalog/data/models/catalog_vehicle_item.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:auto/features/private_sales/data/private_listing_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> stockPayload() => Map<String, dynamic>.from(
  (jsonDecode(File('test/fixtures/vehicles_list.json').readAsStringSync())
          as Map<String, dynamic>)['data'][0]
      as Map<String, dynamic>,
);

Map<String, dynamic> privatePayload({int id = 1}) => {
  'id': id,
  'seller_type': 'private',
  'title': 'Toyota Camry',
  'vehicle_identity': {'brand': 'Toyota', 'model': 'Camry'},
  'year': 2013,
  'mileage_km': 85000,
  'price': 3500000,
  'currency': 'XOF',
  'city': 'Ouagadougou',
  'photos': <Map<String, dynamic>>[],
};

Map<String, dynamic> stockItem() {
  final vehicle = stockPayload();
  return {
    'key': 'vehicle:${vehicle['id']}',
    'source': 'vehicle',
    'source_id': vehicle['id'],
    'vehicle': vehicle,
  };
}

Map<String, dynamic> privateItem() => {
  'key': 'private_listing:1',
  'source': 'private_listing',
  'source_id': 1,
  'private_listing': privatePayload(),
};

Map<String, dynamic> page(
  List<Map<String, dynamic>> items, {
  int current = 1,
  int last = 1,
  int? total,
}) => {
  'data': items,
  'meta': {
    'current_page': current,
    'last_page': last,
    'total': total ?? items.length,
    'per_page': 20,
  },
  'links': {'next': current < last ? '/next-page' : null},
};

class _Client extends ApiClient {
  final calls = <({String path, Map<String, dynamic>? params})>[];
  late Future<Map<String, dynamic>> Function(
    String path,
    Map<String, dynamic>? params,
  )
  respond;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) {
    calls.add((path: path, params: params));
    return respond(path, params);
  }
}

void main() {
  group('Typed public catalogue entries', () {
    test('identical numeric ids remain distinct across sources', () {
      final stock = CatalogVehicleItem.fromJson(stockItem());
      final private = CatalogVehicleItem.fromJson(privateItem());

      expect(stock.sourceId, private.sourceId);
      expect(stock.key, 'vehicle:1');
      expect(private.key, 'private_listing:1');
      expect(stock.vehicle!.id, isA<int>());
      expect(private.privateListing!.id, isA<int>());
      expect(stock.source, CatalogVehicleSource.vehicle);
      expect(private.source, CatalogVehicleSource.privateListing);
      expect(stock.isPrivate, isFalse);
      expect(private.isPrivate, isTrue);
      expect(stock.privateListing, isNull);
      expect(private.vehicle, isNull);
    });

    test(
      'private snapshot does not manufacture a stock identity or status',
      () {
        final entry = CatalogVehicleItem.fromJson(privateItem());
        final listing = entry.privateListing!;

        expect(listing.identityText('brand'), 'Toyota');
        expect(listing.identityText('model'), 'Camry');
        expect(listing.fields.containsKey('registration_status'), isFalse);
        expect(entry.vehicle, isNull);
      },
    );

    test('native constructors keep their detail payload', () {
      final vehicle = Vehicle.fromJson(stockPayload());
      final listing = PrivateListing(privatePayload());
      expect(CatalogVehicleItem.vehicle(vehicle).vehicle, same(vehicle));
      expect(
        CatalogVehicleItem.privateListing(listing).privateListing,
        same(listing),
      );
    });

    test(
      'reject unknown source instead of dispatching to the wrong detail',
      () {
        expect(
          () => CatalogVehicleItem.fromJson({
            ...privateItem(),
            'source': 'other',
          }),
          throwsFormatException,
        );
      },
    );

    test('reject id and key mismatches', () {
      for (final bad in [
        {...privateItem(), 'key': 'vehicle:1'},
        {...privateItem(), 'source_id': '1'},
        {...privateItem(), 'source_id': 0},
        {...privateItem(), 'private_listing': privatePayload(id: 2)},
        {
          ...privateItem(),
          'private_listing': {...privatePayload(), 'id': 1.0},
        },
        {...privateItem(), 'private_listing': null},
      ]) {
        expect(
          () => CatalogVehicleItem.fromJson(bad),
          throwsFormatException,
          reason: '$bad',
        );
      }
    });
  });

  group('Public catalogue repository', () {
    late _Client client;
    late CatalogRepository repository;
    setUp(() {
      client = _Client();
      client.respond = (_, _) async => page([]);
      repository = CatalogRepository(client, CatalogLocalCache());
    });

    test('forwards filters to the unified endpoint', () async {
      await repository.getVehicleListings(
        page: 2,
        perPage: 12,
        search: 'Camry',
        availability: 'sale',
        vehicleType: 'utility',
        bodyStyle: 'pickup',
        brandId: '3',
        yearMin: 2010,
        yearMax: 2020,
        priceMax: 4500000,
        condition: 'used',
        originCountryId: '4',
        city: 'Ouagadougou',
        locationId: 5,
        customsCleared: true,
        deal: true,
        registrationStatus: 'registered',
        includePrivate: true,
      );

      expect(client.calls.single.path, Endpoints.catalogVehicleListings);
      expect(client.calls.single.params, {
        'page': 2,
        'per_page': 12,
        'q': 'Camry',
        'availability': 'sale',
        'vehicle_type': 'utility',
        'body_style': 'pickup',
        'brand_id': '3',
        'year_min': 2010,
        'year_max': 2020,
        'price_max': 4500000,
        'condition': 'used',
        'origin_country_id': '4',
        'city': 'Ouagadougou',
        'location_id': 5,
        'customs_cleared': '1',
        'deal': '1',
        'registration_status': 'registered',
        'include_private': '1',
      });
    });

    test(
      'default private visibility follows the existing build switch',
      () async {
        await repository.getVehicleListings();
        expect(
          client.calls.single.params!['include_private'],
          privateSalesEnabled ? '1' : '0',
        );
      },
    );

    test('rental and private opt-out reach the server', () async {
      await repository.getVehicleListings(
        availability: 'rent',
        includePrivate: false,
      );
      expect(client.calls.single.params!['available_for_rent'], '1');
      expect(client.calls.single.params!['include_private'], '0');
      expect(client.calls.single.params!.containsKey('availability'), isFalse);
    });

    test('keeps native payloads and server pagination', () async {
      client.respond = (_, _) async =>
          page([privateItem(), stockItem()], current: 2, last: 3, total: 45);
      final result = await repository.getVehicleListings(includePrivate: true);
      expect(result.data.map((item) => item.key), [
        'private_listing:1',
        'vehicle:1',
      ]);
      expect(result.currentPage, 2);
      expect(result.lastPage, 3);
      expect(result.total, 45);
      expect(result.hasNextPage, isTrue);
      expect(result.nextUrl, '/next-page');
    });

    test('legacy stock callers keep their old endpoint and shape', () async {
      client.respond = (_, _) async => page([stockPayload()]);
      final result = await repository.getVehicles();
      expect(client.calls.single.path, Endpoints.catalogVehicles);
      expect(
        client.calls.single.params!.containsKey('include_private'),
        isFalse,
      );
      expect(result.data.single.id, 1);
    });

    test(
      '404 falls back to stock with filters and pagination intact',
      () async {
        client.respond = (path, _) async {
          if (path == Endpoints.catalogVehicleListings) {
            throw const ApiException(statusCode: 404, message: 'Not found');
          }
          return page([stockPayload()], current: 2, last: 3, total: 45);
        };
        final result = await repository.getVehicleListings(
          page: 2,
          search: 'Tucson',
          registrationStatus: 'registered',
          city: 'Ouagadougou',
          includePrivate: true,
        );

        expect(client.calls.map((call) => call.path), [
          Endpoints.catalogVehicleListings,
          Endpoints.catalogVehicles,
        ]);
        final fallback = client.calls.last.params!;
        expect(fallback['page'], 2);
        expect(fallback['q'], 'Tucson');
        expect(fallback['city'], 'Ouagadougou');
        expect(fallback['registration_status'], 'registered');
        expect(fallback.containsKey('include_private'), isFalse);
        expect(result.data.single.key, 'vehicle:1');
        expect(result.currentPage, 2);
        expect(result.total, 45);
        expect(result.nextUrl, '/next-page');
      },
    );

    test(
      'server and network errors never silently remove private listings',
      () async {
        for (final error in [
          const ApiException(statusCode: 500, message: 'Server error'),
          const ApiException(message: 'Offline', isNetworkFailure: true),
        ]) {
          client.calls.clear();
          client.respond = (_, _) async => throw error;
          await expectLater(
            repository.getVehicleListings(includePrivate: true),
            throwsA(same(error)),
          );
          expect(client.calls, hasLength(1));
        }
      },
    );

    test(
      'a malformed successful feed is not hidden by the legacy fallback',
      () async {
        client.respond = (_, _) async => page([
          {...privateItem(), 'key': 'vehicle:1'},
        ]);
        await expectLater(
          repository.getVehicleListings(includePrivate: true),
          throwsFormatException,
        );
        expect(client.calls, hasLength(1));
      },
    );
  });

  test(
    'vehicle list provider pages the unified feed across equal native ids',
    () async {
      final client = _Client();
      client.respond = (_, params) async => params!['page'] == 1
          ? page([stockItem()], current: 1, last: 2, total: 21)
          : page([privateItem()], current: 2, last: 2, total: 21);
      final container = ProviderContainer(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(
            CatalogRepository(client, CatalogLocalCache()),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(vehicleListProvider, (_, _) {});
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(vehicleListProvider).items.single.key, 'vehicle:1');
      await container.read(vehicleListProvider.notifier).loadMore();
      expect(
        container.read(vehicleListProvider).items.map((item) => item.key),
        ['vehicle:1', 'private_listing:1'],
      );
      expect(container.read(vehicleListProvider).hasMore, isFalse);
      expect(
        client.calls.every(
          (call) => call.path == Endpoints.catalogVehicleListings,
        ),
        isTrue,
      );
    },
  );

  test(
    'overlapping pages keep unique source keys and refresh the existing payload',
    () async {
      final first = stockItem();
      final second = {
        ...stockItem(),
        'key': 'vehicle:2',
        'source_id': 2,
        'vehicle': {...stockPayload(), 'id': 2},
      };
      final updatedFirst = {
        ...first,
        'vehicle': {
          ...stockPayload(),
          'designation': 'Updated vehicle',
          'commercial': {
            ...(stockPayload()['commercial'] as Map<String, dynamic>),
            'sale_price': 1234567,
          },
        },
      };
      final client = _Client();
      client.respond = (_, params) async => params!['page'] == 1
          ? page([first, second], current: 1, last: 2, total: 21)
          : page([updatedFirst, privateItem()], current: 2, last: 2, total: 22);
      final container = ProviderContainer(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(
            CatalogRepository(client, CatalogLocalCache()),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(vehicleListProvider, (_, _) {});
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);

      await container.read(vehicleListProvider.notifier).loadMore();
      final state = container.read(vehicleListProvider);
      expect(state.items.map((item) => item.key), [
        'vehicle:1',
        'vehicle:2',
        'private_listing:1',
      ]);
      expect(state.items.first.vehicle!.designation, 'Updated vehicle');
      expect(state.items.first.vehicle!.commercial.salePrice, 1234567);
      expect(state.items.last.privateListing!.id, 1);
      expect(state.total, 22);
      expect(state.hasMore, isFalse);
      expect(state.isLoadingMore, isFalse);
    },
  );
}
