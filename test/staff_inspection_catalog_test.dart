import 'dart:convert';
import 'dart:io';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/theme/app_theme.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/models/catalog_vehicle_item.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_list_page.dart';
import 'package:auto/features/inspections/presentation/staff_inspection_widgets.dart';
import 'package:auto/features/private_sales/data/private_listing_repository.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'catalog_vehicle_grid_test.dart' as fixtures;
import 'support/polices.dart';

Map<String, dynamic> _inspection({int id = 42, String result = 'clear'}) => {
  'id': id,
  'inspected_at': '2026-11-01T09:00:00Z',
  'mileage_km': 85000,
  'result': result,
  'checked_count': 2,
  'attention_count': result == 'attention' ? 1 : 0,
  'blocking_count': result == 'blocked' ? 1 : 0,
  'valid_until': null,
};

Vehicle _vehicle({Map<String, dynamic>? inspection}) {
  final json =
      (jsonDecode(File('test/fixtures/vehicle_detail.json').readAsStringSync())
              as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
  json['inspection'] = inspection;
  return Vehicle.fromJson(json);
}

PrivateListing _private({Map<String, dynamic>? inspection}) => PrivateListing({
  ...fixtures.privateListing(1).fields,
  'inspection': inspection,
});

class _Anonymous extends StateNotifier<AuthState> implements AuthNotifier {
  _Anonymous() : super(const AuthState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ReportApi extends ApiClient {
  final paths = <String>[];

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    paths.add(path);
    return {
      'data': {
        ..._inspection(),
        'source': 'vehicle',
        'source_id': 1,
        'summary': 'Contrôle physique effectué',
        'items': [
          {'label': 'Freins', 'status': 'ok', 'note': 'Essai effectué'},
          {'label': 'Pneus', 'status': 'ok'},
        ],
      },
    };
  }
}

Future<void> _show(
  WidgetTester tester,
  List<CatalogVehicleItem> items, {
  Locale locale = const Locale('fr'),
  double width = 360,
  double scale = 1,
  _ReportApi? api,
}) async {
  tester.view.physicalSize = Size(width, 1300);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final controller = ScrollController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((_) => _Anonymous()),
        if (api != null) apiClientProvider.overrideWithValue(api),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: themeAutoParc(Brightness.light),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: VehicleGrid.catalog(
            items: items,
            total: items.length,
            hasMore: false,
            isLoadingMore: false,
            scrollCtrl: controller,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(chargerPolices);

  test('older responses do not acquire a staff inspection from moderation', () {
    expect(_vehicle().inspection, isNull);
    expect(_private().inspection, isNull);
    expect(_vehicle(inspection: _inspection()).inspection?.id, 42);
    expect(_private(inspection: _inspection()).inspection?.id, 42);
  });

  testWidgets(
    'published and phone-verified listings have no inspection by default',
    (tester) async {
      await _show(tester, [
        CatalogVehicleItem.vehicle(_vehicle()),
        CatalogVehicleItem.privateListing(_private()),
      ]);
      expect(find.byType(StaffInspectionBadge), findsNothing);
      expect(find.byIcon(Icons.verified_user_outlined), findsNothing);
    },
  );

  for (final locale in [const Locale('fr'), const Locale('en')]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'both native cards show icon and label at 320/${locale.languageCode}/$scale',
        (tester) async {
          await _show(
            tester,
            [
              CatalogVehicleItem.vehicle(_vehicle(inspection: _inspection())),
              CatalogVehicleItem.privateListing(
                _private(inspection: _inspection(id: 43)),
              ),
            ],
            locale: locale,
            width: 320,
            scale: scale,
          );
          expect(find.byType(StaffInspectionBadge), findsNWidgets(2));
          expect(find.byIcon(Icons.verified_user_outlined), findsNWidgets(2));
          expect(
            find.text(
              locale.languageCode == 'fr'
                  ? 'Inspecté par AutoParc'
                  : 'Inspected by AutoParc',
            ),
            findsNWidgets(2),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'the card badge opens its report without opening the vehicle route',
    (tester) async {
      final api = _ReportApi();
      await _show(tester, [
        CatalogVehicleItem.vehicle(_vehicle(inspection: _inspection())),
      ], api: api);
      await tester.tap(find.byType(StaffInspectionBadge));
      await tester.pumpAndSettle();
      expect(api.paths, ['/catalog/vehicle-inspections/42']);
      expect(find.text('Contrôle physique effectué'), findsOneWidget);
      expect(find.text('Freins'), findsOneWidget);
      expect(find.text('Essai effectué'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
