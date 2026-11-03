import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/theme/app_theme.dart';
import 'package:auto/features/catalog/data/models/catalog_vehicle_item.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_list_page.dart';
import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:auto/features/private_sales/data/private_listing_repository.dart';
import 'package:auto/features/private_sales/presentation/private_listing_detail.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/shared/models/paged_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/polices.dart';

const stock = Vehicle(
  id: 1,
  reference: 'STOCK-1',
  designation: 'Toyota Camry',
  registrationStatus: 'registered',
  identity: VehicleIdentity(brand: 'Toyota', model: 'Camry', year: 2013),
  commercial: VehicleCommercial(
    condition: 'used',
    status: 'in_stock',
    availability: 'sale',
    salePrice: 4500000,
    currency: 'XOF',
    priceNegotiable: false,
  ),
  faultsCount: 0,
  mediaUrls: [],
);

PrivateListing privateListing(int id) => PrivateListing({
  'id': id,
  'seller_type': 'private',
  'title': 'Honda Accord',
  'vehicle_identity': {'brand': 'Honda', 'model': 'Accord'},
  'year': 2014,
  'mileage_km': 85000,
  'price': 3500000,
  'currency': 'XOF',
  'city': 'Bobo-Dioulasso',
  'description': 'Véhicule personnel',
  'seller_name': 'Vendeur particulier',
  'phone_verified': true,
  'whatsapp_enabled': true,
  'share_url': 'https://example.invalid/annonces/$id',
  'photos': <Map<String, dynamic>>[],
});

class PrivateDetailApi extends ApiClient {
  final paths = <String>[];

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    paths.add(path);
    return {
      'data': {...privateListing(1).fields, 'phone': '+22670000000'},
    };
  }
}

class CityTestAuth extends StateNotifier<AuthState> implements AuthNotifier {
  CityTestAuth() : super(const AuthState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CityTestVehicleList extends VehicleListNotifier {
  @override
  PagedState<CatalogVehicleItem> build() {
    final filter = ref.watch(vehicleFilterProvider);
    final items = filter.city == null
        ? [
            CatalogVehicleItem.privateListing(
              PrivateListing({
                ...privateListing(1).fields,
                'city': ' Banfora ',
              }),
            ),
            CatalogVehicleItem.privateListing(
              PrivateListing({...privateListing(2).fields, 'city': 'Banfora'}),
            ),
          ]
        : <CatalogVehicleItem>[];
    return PagedState(
      items: items,
      total: items.length,
      hasMore: false,
      isLoading: false,
      isLoadingMore: false,
    );
  }
}

Widget grid(List<CatalogVehicleItem> items, ScrollController controller) =>
    VehicleGrid.catalog(
      items: items,
      total: items.length,
      hasMore: false,
      isLoadingMore: false,
      scrollCtrl: controller,
    );

Future<void> showGrid(
  WidgetTester tester,
  List<CatalogVehicleItem> items,
  ScrollController controller, {
  Locale locale = const Locale('fr'),
  double textScale = 1,
  PrivateDetailApi? api,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (api != null)
          privateListingRepositoryProvider.overrideWithValue(
            PrivateListingRepository(api),
          ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: themeAutoParc(Brightness.light),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(body: grid(items, controller)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(chargerPolices);

  testWidgets('private cities appear once and selected city stays clearable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((_) => CityTestAuth()),
        vehicleListProvider.overrideWith(CityTestVehicleList.new),
        dealCountProvider.overrideWith((_) async => 0),
        unreadCountProvider.overrideWith((_) async => 0),
        catalogRefsProvider.overrideWith(
          (_) async => const CatalogRefs(
            brands: [],
            vehicleModels: [],
            trims: [],
            engineTypes: [],
            drivetrains: [],
            colors: [],
            features: [],
            locations: [
              LocationRef(id: 1, name: 'Agence', city: 'Ouagadougou'),
              LocationRef(id: 2, name: 'Autre agence', city: 'Ouagadougou'),
              LocationRef(id: 3, name: 'Sans ville', city: ' '),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('fr'),
          theme: themeAutoParc(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const VehicleListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final privateCity = find.widgetWithText(FilterChip, 'Banfora');
    expect(privateCity, findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Ouagadougou'), findsOneWidget);
    final chipLabels = tester
        .widgetList<FilterChip>(find.byType(FilterChip))
        .map((chip) => (chip.label as Text).data)
        .toList();
    expect(
      chipLabels.indexOf('Banfora'),
      lessThan(chipLabels.indexOf('Ouagadougou')),
    );
    await tester.ensureVisible(privateCity);
    await tester.tap(privateCity);
    await tester.pumpAndSettle();
    expect(container.read(vehicleFilterProvider).city, 'Banfora');
    expect(container.read(vehicleListProvider).items, isEmpty);
    expect(privateCity, findsOneWidget);
    expect(tester.widget<FilterChip>(privateCity).selected, isTrue);

    await tester.ensureVisible(privateCity);
    await tester.tap(privateCity);
    await tester.pumpAndSettle();
    expect(container.read(vehicleFilterProvider).city, isNull);
    expect(container.read(vehicleListProvider).items, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('mixed cards keep server order and qualify equal numeric IDs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await showGrid(tester, [
      CatalogVehicleItem.privateListing(privateListing(1)),
      const CatalogVehicleItem.vehicle(stock),
      CatalogVehicleItem.privateListing(privateListing(2)),
    ], controller);

    final first = find.byKey(const ValueKey('private_listing:1'));
    final second = find.byKey(const ValueKey('vehicle:1'));
    final third = find.byKey(const ValueKey('private_listing:2'));
    expect(first, findsOneWidget);
    expect(second, findsOneWidget);
    expect(third, findsOneWidget);
    expect(tester.getTopLeft(first).dy, tester.getTopLeft(second).dy);
    expect(tester.getTopLeft(first).dx, lessThan(tester.getTopLeft(second).dx));
    expect(
      tester.getTopLeft(third).dy,
      greaterThan(tester.getTopLeft(first).dy),
    );
    expect(find.text('Particulier'), findsNWidgets(2));
    expect(find.byType(VehicleCard), findsOneWidget);
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(find.text(l10n.catalogPricesIncludeVat), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('private tap opens its native detail with AutoParc contact', (
    tester,
  ) async {
    final controller = ScrollController();
    final api = PrivateDetailApi();
    addTearDown(controller.dispose);
    await showGrid(
      tester,
      [
        CatalogVehicleItem.privateListing(privateListing(1)),
        const CatalogVehicleItem.vehicle(stock),
      ],
      controller,
      api: api,
    );

    await tester.tap(find.byKey(const ValueKey('private_listing:1')));
    await tester.pumpAndSettle();

    expect(find.byType(PrivateListingDetail), findsOneWidget);
    final detail = tester.widget<PrivateListingDetail>(
      find.byType(PrivateListingDetail),
    );
    expect(detail.publicListing, isTrue);
    expect(detail.listing.id, 1);
    expect(detail.listing.text('share_url'), endsWith('/annonces/1'));
    expect(api.paths, isEmpty);
    expect(find.text('Appeler AutoParc'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stock tap retains its numeric vehicle detail route', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: grid([const CatalogVehicleItem.vehicle(stock)], controller),
          ),
        ),
        GoRoute(
          path: '/vehicles/:id',
          builder: (_, state) => Scaffold(
            body: Text('stock detail ${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('vehicle:1')));
    await tester.pumpAndSettle();
    expect(find.text('stock detail 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final locale in [const Locale('fr'), const Locale('en')]) {
    for (final width in [320.0, 411.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('private card fits ${locale.languageCode}/$width/$scale', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 1100);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final controller = ScrollController();
          addTearDown(controller.dispose);
          await showGrid(
            tester,
            [
              CatalogVehicleItem.privateListing(privateListing(1)),
              const CatalogVehicleItem.vehicle(stock),
            ],
            controller,
            locale: locale,
            textScale: scale,
          );
          expect(find.byType(PrivateCatalogVehicleCard), findsOneWidget);
          expect(tester.takeException(), isNull);
          final bounds = tester.getRect(find.byType(PrivateCatalogVehicleCard));
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(bounds.right, lessThanOrEqualTo(width));
          for (final richText
              in find
                  .descendant(
                    of: find.byType(PrivateCatalogVehicleCard),
                    matching: find.byType(RichText),
                  )
                  .evaluate()) {
            final paragraph = richText.renderObject! as RenderParagraph;
            expect(paragraph.didExceedMaxLines, isFalse);
            final text = paragraph.text.toPlainText();
            final boxes = paragraph.getBoxesForSelection(
              TextSelection(baseOffset: 0, extentOffset: text.length),
            );
            for (final box in boxes) {
              expect(
                box.right,
                lessThanOrEqualTo(paragraph.size.width + 1),
                reason: 'Painted text must fit: $text',
              );
            }
          }
        });
      }
    }
  }
}
