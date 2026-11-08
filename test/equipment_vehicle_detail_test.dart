import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_detail_page.dart';
import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:auto/features/vehicles/presentation/widgets/equipment_details_section.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _GuestAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _GuestAuth() : super(const AuthState());

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

Vehicle machine(String type, {Map<String, dynamic> details = const {}}) =>
    Vehicle.fromJson({
      'id': 92,
      'reference': 'EQ-0092',
      'designation': 'Kubota M7060',
      'asset_kind': 'equipment',
      'equipment_type': type,
      'registration_status': 'unregistered',
      'vehicle_type': null,
      'identity': {
        'brand': 'Kubota',
        'model': 'M7060',
        'engine_type': 'Gazole',
        'engine_type_code': 'diesel',
      },
      'equipment_details': details,
      // Historical road-shaped fields must not appear on a machine detail.
      'technical': {'combined_l100km': 9.3, 'seats': 5, 'doors': 4},
      'commercial': {
        'condition': 'used',
        'status': 'in_stock',
        'availability': 'sale',
      },
      'seller': {'id': 27, 'company_name': 'Garage', 'phone': '+226 70002244'},
    });

Future<void> mount(
  WidgetTester tester,
  Vehicle vehicle,
  String language,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((_) => _GuestAuth()),
        vehicleDetailProvider(vehicle.id).overrideWith((_) async => vehicle),
      ],
      child: MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: VehicleDetailPage(vehicleId: vehicle.id),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final language in ['fr', 'en']) {
    testWidgets('real equipment detail $language fits 320px at text scale 2', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(
        tester,
        machine(
          'agricultural_tractor',
          details: {
            'operating_hours': '1250.75',
            'hour_reading_date': '2026-11-03',
            'power_kw': '54.5',
            'pto_rpm': 540,
            'cabin': 'closed',
            'quick_coupler': true,
            'working_height_m': 12,
          },
        ),
        language,
      );
      final l = AppLocalizations.of(
        tester.element(find.byType(VehicleDetailPage)),
      );
      expect(find.byType(EquipmentDetailsSection), findsOneWidget);
      expect(find.text(l.equipmentDeclared), findsOneWidget);
      expect(find.text(l.equipmentTypeAgriculturalTractor), findsOneWidget);
      expect(find.text(l.catalogSectionImport), findsNothing);
      expect(find.text(l.catalogDeclaredConsumption), findsNothing);
      expect(find.text(l.catalogFieldSeats), findsNothing);
      expect(find.text(l.catalogFieldDoors), findsNothing);
      expect(find.text(l.equipmentWorkingHeightM), findsOneWidget);
      expect(find.text(l.equipmentQuickCoupler), findsOneWidget);
      await tester.ensureVisible(find.text('540 rpm'));
      await tester.pumpAndSettle();
      expect(find.text('540 rpm'), findsOneWidget);
      expect(find.textContaining('54'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('machine details retain decimals and explicitly declared false', (
    tester,
  ) async {
    await mount(
      tester,
      machine(
        'excavator',
        details: {
          'operating_hours': 0,
          'bucket_capacity_m3': '1.25',
          'operating_weight_kg': '2400.5',
          'quick_coupler': false,
          'pto_rpm': 540,
        },
      ),
      'en',
    );
    final l = AppLocalizations.of(
      tester.element(find.byType(VehicleDetailPage)),
    );
    await tester.ensureVisible(find.text(l.equipmentQuickCoupler));
    await tester.pumpAndSettle();
    expect(find.text('0 h'), findsOneWidget);
    expect(find.text('1.25 m³'), findsOneWidget);
    expect(find.text('2,400.5 kg'), findsOneWidget);
    expect(find.text(l.equipmentNo), findsOneWidget);
    expect(find.text(l.equipmentPtoRpm), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final type in ['aerial_platform', 'generator']) {
    testWidgets('$type shows all saved common data and fuel', (tester) async {
      await mount(
        tester,
        machine(
          type,
          details: {
            'attachments': 'Fourches amovibles',
            'engine_serial_number': 'ENGINE-42',
            'cabin': 'closed',
            'quick_coupler': false,
          },
        ),
        'en',
      );
      final l = AppLocalizations.of(
        tester.element(find.byType(VehicleDetailPage)),
      );
      expect(find.text(l.equipmentFuelLabel), findsOneWidget);
      expect(find.text('Diesel'), findsOneWidget);
      expect(find.text('Fourches amovibles'), findsOneWidget);
      expect(find.text('ENGINE-42'), findsOneWidget);
      expect(find.text(l.equipmentCabinClosed), findsOneWidget);
      expect(find.text(l.equipmentNo), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
