import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/home/presentation/pages/home_page.dart';
import 'package:auto/features/home/presentation/providers/home_providers.dart';
import 'package:auto/features/inspections/presentation/staff_inspection_widgets.dart';
import 'package:auto/features/private_sales/data/private_listing_repository.dart';
import 'package:auto/features/private_sales/presentation/private_listing_detail.dart';
import 'package:auto/features/private_sales/presentation/private_listings_page.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'private_sales/private_sales_test.dart' as fixture;

Map<String, dynamic> _inspection({bool findings = false}) => {
  'id': findings ? 5 : 4,
  'inspected_at': '2026-11-01T09:00:00Z',
  'mileage_km': 85000,
  'result': findings ? 'attention' : 'clear',
  'checked_count': 1,
  'attention_count': findings ? 1 : 0,
  'blocking_count': 0,
  'valid_until': null,
};

class _InspectedListingsApi extends fixture.FakeSalesApi {
  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    queries.add((path: path, params: params));
    return {
      'data': [
        {...fixture.listingFields(), 'inspection': _inspection()},
        fixture.listingFields(id: 2),
        {
          ...fixture.listingFields(id: 3),
          'inspection': _inspection(findings: true),
        },
      ],
      'meta': {'current_page': 1, 'last_page': 1},
    };
  }
}

Vehicle _deal({required int id, bool inspected = false}) => Vehicle.fromJson({
  'id': id,
  'reference': 'VH-$id',
  'designation': 'Toyota Corolla 2018',
  'registration_status': 'registered',
  'identity': {'brand': 'Toyota', 'model': 'Corolla', 'year': 2018},
  'commercial': {
    'condition': 'used',
    'status': 'in_stock',
    'availability': 'sale',
    'sale_price': '6500000.00',
    'currency': 'XOF',
    'location': {'id': 1, 'name': 'Showroom', 'city': 'Ouagadougou'},
  },
  if (inspected) 'inspection': _inspection(findings: true),
});

void main() {
  testWidgets('native browse cards badge only staff-inspected listings', (
    tester,
  ) async {
    await fixture.open(
      tester,
      _InspectedListingsApi(),
      const PrivateListingsPage(),
    );
    final badges = tester
        .widgetList<StaffInspectionBadge>(
          find.byType(StaffInspectionBadge, skipOffstage: false),
        )
        .toList();
    expect(badges, hasLength(2));
    expect(badges.map((badge) => badge.inspection.hasFindings), [false, true]);
    expect(tester.takeException(), isNull);
  });

  for (final mode in [PrivateListingMode.mine, PrivateListingMode.review]) {
    testWidgets('${mode.name} cards do not open public inspection reports', (
      tester,
    ) async {
      await fixture.open(
        tester,
        _InspectedListingsApi(),
        PrivateListingsPage(mode: mode),
        auth: mode == PrivateListingMode.review
            ? fixture.manager
            : const AuthState(type: AuthType.client),
      );
      expect(
        find.byType(StaffInspectionBadge, skipOffstage: false),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('returning from a native private detail refreshes the cards', (
    tester,
  ) async {
    final api = _InspectedListingsApi();
    await fixture.open(tester, api, const PrivateListingsPage());
    expect(api.queries, hasLength(1));
    final tile = find.byType(ListTile).first;
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.byType(PrivateListingDetail), findsOneWidget);
    Navigator.of(tester.element(find.byType(PrivateListingDetail))).pop();
    await tester.pumpAndSettle();
    expect(
      api.queries.where((query) => query.path == '/private-listings'),
      hasLength(2),
    );
    expect(tester.takeException(), isNull);
  });

  for (final locale in [const Locale('fr'), const Locale('en')]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets(
        'home cards support inspection labels at 320px ${locale.languageCode} x$scale',
        (tester) async {
          tester.view.physicalSize = const Size(320, 1200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authProvider.overrideWith(
                  (_) => fixture.TestAuth(fixture.manager),
                ),
                homeDealsProvider.overrideWith(
                  (_) async => [_deal(id: 1, inspected: true), _deal(id: 2)],
                ),
              ],
              child: MaterialApp(
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: const HomePage(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final badge = find.byType(StaffInspectionBadge, skipOffstage: false);
          expect(badge, findsOneWidget);
          expect(
            tester.widget<StaffInspectionBadge>(badge).inspection.hasFindings,
            isTrue,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
