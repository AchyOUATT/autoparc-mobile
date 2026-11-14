import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/pages/add_vehicle_to_garage_page.dart';
import 'package:auto/features/garage/presentation/widgets/vehicle_card_header.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/data/models/two_wheeler_configuration.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/features/vehicles/presentation/widgets/two_wheeler_configuration.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const yamaha = BrandRef(id: 8, name: 'Yamaha', isActive: true);
const ybr = ModelRef(
  id: 90,
  brandId: 8,
  name: 'YBR125E',
  productionStart: 2020,
  defaultVehicleType: 'two_wheeler',
);

const motoRefs = CatalogRefs(
  brands: [yamaha],
  vehicleModels: [ybr],
  trims: [],
  engineTypes: [],
  drivetrains: [],
  colors: [],
  features: [],
  locations: [],
);

const moto = OwnedVehicle(
  id: 21,
  designation: 'Yamaha YBR125E',
  brandId: 8,
  vehicleModelId: 90,
  vehicleType: 'two_wheeler',
  twoWheelerConfiguration: TwoWheelerConfiguration(
    bodyType: 'motorcycle',
    stroke: 'four_stroke',
    drive: 'chain',
  ),
  year: 2024,
  mileageKm: 3200,
  vin: 'YAMAHAFRAME01',
  identity: OwnedVehicleIdentity(brand: 'Yamaha', model: 'YBR125E'),
  compatibilityReady: true,
);

Widget app(Widget child) => ProviderScope(
  overrides: [catalogRefsProvider.overrideWith((_) async => motoRefs)],
  child: MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  test('owned two-wheeler identity and configuration survive JSON', () {
    final parsed = OwnedVehicle.fromJson({
      'id': 21,
      'designation': 'Yamaha YBR125E',
      'brand_id': 8,
      'vehicle_model_id': 90,
      'vehicle_type': 'two_wheeler',
      'two_wheeler_configuration': {
        'body_type': 'motorcycle',
        'stroke': 'four_stroke',
        'drive': 'chain',
        'sidecar': true,
      },
      'manufacturing_year': 2024,
      'year': 2024,
      'mileage_km': 3200,
      'vin': 'YAMAHAFRAME01',
      'identity': {'brand': 'Yamaha', 'model': 'YBR125E'},
      'compatibility_ready': true,
    });
    expect(parsed.isTwoWheeler, isTrue);
    expect(parsed.vehicleType, 'two_wheeler');
    expect(parsed.twoWheelerConfiguration.bodyType, 'motorcycle');
    expect(parsed.twoWheelerConfiguration.stroke, 'four_stroke');
    expect(parsed.twoWheelerConfiguration.drive, 'chain');
    expect(parsed.vin, 'YAMAHAFRAME01');
  });

  testWidgets('garage card shows the two-wheeler type and body', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const VehicleCardHeader(vehicle: moto, trailing: SizedBox.shrink())),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.two_wheeler_outlined), findsOneWidget);
    expect(find.text('Deux-roues · Moto'), findsOneWidget);
  });

  testWidgets('garage add form offers the two-wheeler type and fields', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [catalogRefsProvider.overrideWith((_) async => motoRefs)],
        child: const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AddVehicleToGaragePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Deux-roues'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Deux-roues'));
    await tester.pumpAndSettle();
    expect(find.byType(TwoWheelerConfigurationFields), findsOneWidget);
    expect(find.byKey(const ValueKey('two-wheeler-body-type')), findsOneWidget);
  });

  testWidgets('garage edit form prefills a motorcycle from the garage', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [catalogRefsProvider.overrideWith((_) async => motoRefs)],
        child: const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AddVehicleToGaragePage(existing: moto),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final twoWheeler = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Deux-roues'),
    );
    expect(twoWheeler.selected, isTrue);
    expect(find.byType(TwoWheelerConfigurationFields), findsOneWidget);
    expect(find.text('Modifier le véhicule'), findsWidgets);
    expect(find.text('YAMAHAFRAME01'), findsWidgets);
    expect(find.text('2024'), findsWidgets);
  });
}
