import 'package:auto/core/widgets/catalog_image.dart';
import 'package:auto/core/widgets/product_gallery.dart';
import 'package:auto/features/private_sales/data/private_listing_repository.dart';
import 'package:auto/features/private_sales/presentation/private_listing_detail.dart';
import 'package:auto/features/private_sales/presentation/private_listings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'private_sales_test.dart' as fixture;

PrivateListing listingWithPhotos({bool empty = false}) => PrivateListing({
  ...fixture.listingFields(),
  'photos': empty
      ? <Map<String, dynamic>>[]
      : [
          {'id': 1, 'url': 'https://example.invalid/private-first.jpg'},
          {'id': 2, 'url': 'https://example.invalid/private-second.jpg'},
        ],
});

class _PhotoApi extends fixture.FakeSalesApi {
  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) async => {
    'data': [listingWithPhotos().fields],
    'meta': {'current_page': 1, 'last_page': 1},
  };
}

Future<void> openGallery(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(ProductGallery));
  await tester.tap(find.byType(ProductGallery));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  expect(find.byType(InteractiveViewer), findsWidgets);
  expect(find.text('1 / 2'), findsOneWidget);
  expect(
    tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer).first)
        .maxScale,
    greaterThan(1),
  );

  final fullscreenPages = find.ancestor(
    of: find.byType(InteractiveViewer).first,
    matching: find.byType(PageView),
  ).first;
  await tester.drag(fullscreenPages, const Offset(-500, 0));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  expect(find.text('2 / 2'), findsOneWidget);
  final visibleImages = tester.widgetList<CatalogImage>(
    find.byType(CatalogImage),
  );
  expect(
    visibleImages.any((image) => image.url.endsWith('private-second.jpg')),
    isTrue,
  );

  await tester.tap(find.byType(CloseButton));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  expect(find.byType(InteractiveViewer), findsNothing);
  expect(find.byType(ProductGallery), findsOneWidget);
  expect(tester.takeException(), isNull);
}

void main() {
  test('private photo URLs retain order and omit unusable entries', () {
    const listing = PrivateListing({
      'photos': [
        {'url': ' first.jpg '},
        {'url': null},
        {'url': 123},
        {'url': '  '},
        {'url': 'second.jpg'},
      ],
    });
    expect(listing.photoUrls, ['first.jpg', 'second.jpg']);
  });

  for (final publicListing in [true, false]) {
    testWidgets(
      'private detail photos open and navigate, public=$publicListing',
      (tester) async {
        await fixture.open(
          tester,
          _PhotoApi(),
          PrivateListingDetail(
            listing: listingWithPhotos(),
            publicListing: publicListing,
          ),
        );
        await openGallery(tester);
        expect(find.byType(PrivateListingDetail), findsOneWidget);
      },
    );
  }

  testWidgets('private browse card photo opens the gallery directly', (
    tester,
  ) async {
    await fixture.open(tester, _PhotoApi(), const PrivateListingsPage());
    await openGallery(tester);
    expect(find.byType(PrivateListingsPage), findsOneWidget);
  });

  testWidgets('a listing without photos does not show an empty gallery', (
    tester,
  ) async {
    await fixture.open(
      tester,
      _PhotoApi(),
      PrivateListingDetail(
        listing: listingWithPhotos(empty: true),
        publicListing: false,
      ),
    );
    expect(find.byType(ProductGallery), findsNothing);
    expect(find.byType(PrivateListingDetail), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
