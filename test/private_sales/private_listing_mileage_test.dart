import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/models/catalog_vehicle_item.dart';
import 'package:auto/features/private_sales/data/private_listing_repository.dart';
import 'package:auto/features/private_sales/presentation/private_listing_detail.dart';
import 'package:auto/features/private_sales/presentation/private_listing_form.dart';
import 'package:auto/features/private_sales/presentation/private_listings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../catalog_vehicle_grid_test.dart' as catalog;
import '../support/polices.dart';
import 'private_sales_test.dart' as fixture;

PrivateListing listingWithMileage(int id, int? mileage) =>
    PrivateListing({...fixture.listingFields(id: id), 'mileage_km': mileage});

class MileageSalesApi extends fixture.FakeSalesApi {
  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    if (path.endsWith('/private-listings') ||
        path.endsWith('/private-listing-reviews')) {
      return {
        'data': [
          listingWithMileage(1, null).fields,
          listingWithMileage(2, 0).fields,
        ],
        'meta': {'current_page': 1, 'last_page': 1},
      };
    }
    return super.get(path, params: params);
  }
}

void main() {
  setUpAll(chargerPolices);

  for (final locale in [const Locale('fr'), const Locale('en')]) {
    final unknown = locale.languageCode == 'fr'
        ? 'Kilométrage non renseigné'
        : 'Mileage not provided';

    for (final mileage in <int?>[null, 0]) {
      testWidgets('private detail distinguishes $mileage km in $locale', (
        tester,
      ) async {
        await fixture.open(
          tester,
          fixture.FakeSalesApi(),
          PrivateListingDetail(listing: listingWithMileage(1, mileage)),
          locale: locale,
        );
        expect(
          find.text(
            '2018 · ${mileage == null ? unknown : '0 km'} · Ouagadougou',
          ),
          findsOneWidget,
        );
        if (mileage == null) {
          expect(find.textContaining('0 km'), findsNothing);
        } else {
          expect(find.textContaining(unknown), findsNothing);
        }
        expect(tester.takeException(), isNull);
      });
    }

    for (final mode in PrivateListingMode.values) {
      testWidgets('private $mode list preserves unknown and zero in $locale', (
        tester,
      ) async {
        fixture.saleViewport(tester);
        await fixture.open(
          tester,
          MileageSalesApi(),
          PrivateListingsPage(mode: mode),
          auth: mode == PrivateListingMode.review
              ? fixture.manager
              : const AuthState(type: AuthType.client),
          locale: locale,
        );
        expect(find.textContaining(unknown), findsOneWidget);
        expect(
          find.textContaining('2018 · 0 km · Ouagadougou'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
      'catalog private cards distinguish unknown and zero in $locale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await catalog.showGrid(
          tester,
          [
            CatalogVehicleItem.privateListing(listingWithMileage(1, null)),
            CatalogVehicleItem.privateListing(listingWithMileage(2, 0)),
          ],
          controller,
          locale: locale,
          textScale: 2,
        );
        expect(find.text(unknown), findsOneWidget);
        expect(find.text('0 km'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('new private draft sends null for blank mileage', (tester) async {
    fixture.saleViewport(tester);
    final api = fixture.FakeSalesApi();
    await fixture.open(
      tester,
      api,
      PrivateListingForm(vehicle: fixture.garageSaleVehicle()),
    );
    await tester.enterText(
      find.byKey(const ValueKey('private-sale-mileage')),
      '',
    );
    await fixture.fillSaleCommercial(tester);
    await fixture.saveSaleDraft(tester);
    expect(api.saved?.containsKey('mileage_km'), isTrue);
    expect(api.saved?['mileage_km'], isNull);
  });

  testWidgets('clearing known private mileage explicitly saves null', (
    tester,
  ) async {
    fixture.saleViewport(tester);
    final api = fixture.FakeSalesApi();
    await fixture.open(
      tester,
      api,
      PrivateListingForm(existing: listingWithMileage(1, 85000)),
    );
    await tester.enterText(
      find.byKey(const ValueKey('private-sale-mileage')),
      '',
    );
    await fixture.saveSaleDraft(tester);
    expect(api.saved?.containsKey('mileage_km'), isTrue);
    expect(api.saved?['mileage_km'], isNull);
  });

  testWidgets('editing a measured zero does not turn it into unknown', (
    tester,
  ) async {
    fixture.saleViewport(tester);
    final api = fixture.FakeSalesApi();
    await fixture.open(
      tester,
      api,
      PrivateListingForm(existing: listingWithMileage(1, 0)),
    );
    final field = tester.widget<TextFormField>(
      find.byKey(const ValueKey('private-sale-mileage')),
    );
    expect(field.controller?.text, '0');
    await fixture.saveSaleDraft(tester);
    expect(api.saved?['mileage_km'], 0);
  });
}
