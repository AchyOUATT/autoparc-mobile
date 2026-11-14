import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/data/models/two_wheeler_configuration.dart';
import 'package:auto/features/vehicles/presentation/widgets/two_wheeler_configuration.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(Widget child) => MaterialApp(
  locale: const Locale('fr'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  ),
);

void main() {
  test('declared two-wheeler values round-trip and ignore unknown keys', () {
    const configuration = TwoWheelerConfiguration(
      bodyType: 'motorcycle',
      stroke: 'four_stroke',
      cooling: 'air',
      starter: 'both',
      drive: 'chain',
      transmission: 'manual',
    );
    expect(
      TwoWheelerConfiguration.fromJson({
        ...configuration.toJson(),
        'tricycle_layout': 'cargo',
        'body_type': ' motorcycle ',
      }).toJson(),
      configuration.toJson(),
    );
    expect(const TwoWheelerConfiguration().isEmpty, isTrue);
  });

  test('two_wheeler listings are not treated as passenger cars', () {
    final vehicle = Vehicle.fromJson({
      'id': 90,
      'reference': 'VH-MOTO',
      'designation': 'Yamaha YBR125E',
      'vehicle_type': 'two_wheeler',
      'body_style': null,
      'vin': 'YAMAHAFRAME01',
      'registration_status': 'registered',
      'identity': {'brand': 'Yamaha', 'model': 'YBR125E', 'year': 2024},
      'commercial': {
        'condition': 'used',
        'status': 'in_stock',
        'availability': 'sale',
      },
      'technical': {
        'engine_displacement_cc': 125,
        'power_hp': 10,
        'two_wheeler_configuration': {
          'body_type': 'motorcycle',
          'stroke': 'four_stroke',
        },
      },
      'seller': {
        'id': 27,
        'company_name': 'Garage du vendeur',
        'phone': '+226 70 00 22 44',
      },
    });
    expect(vehicle.isTwoWheeler, isTrue);
    expect(vehicle.isPassenger, isFalse);
    expect(vehicle.isHeavy, isFalse);
    expect(vehicle.isUtility, isFalse);
    expect(vehicle.bodyStyle, isNull);
    expect(vehicle.engineDisplacementCc, 125);
    expect(vehicle.twoWheelerConfiguration.bodyType, 'motorcycle');
    expect(vehicle.vin, 'YAMAHAFRAME01');
  });

  test('Honda cars and motorcycles stay in their own type lists', () {
    const civic = ModelRef(id: 1, brandId: 9, name: 'Civic', bodyType: 'sedan');
    const cg110 = ModelRef(
      id: 2,
      brandId: 9,
      name: 'CG110',
      defaultVehicleType: 'two_wheeler',
    );
    const untyped = ModelRef(id: 3, brandId: 9, name: 'Legacy');
    const refs = CatalogRefs(
      brands: [],
      vehicleModels: [civic, cg110, untyped],
      trims: [],
      engineTypes: [],
      drivetrains: [],
      colors: [],
      features: [],
      locations: [],
    );
    expect(refs.modelsForBrand(9).map((m) => m.id), [1, 2, 3]);
    expect(refs.modelsForBrand(9, vehicleType: 'passenger').map((m) => m.id), [
      1,
      3,
    ]);
    expect(
      refs.modelsForBrand(9, vehicleType: 'two_wheeler').map((m) => m.id),
      [2],
    );
    expect(refs.modelsForBrand(9, vehicleType: 'heavy').map((m) => m.id), [3]);
    expect(refs.modelsForBrand(9, vehicleType: 'utility').map((m) => m.id), [
      3,
    ]);
  });

  testWidgets('two-wheeler fields stay optional', (tester) async {
    final controller = TwoWheelerConfigurationController();
    addTearDown(controller.dispose);
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(
      app(
        Form(
          key: form,
          child: TwoWheelerConfigurationFields(controller: controller),
        ),
      ),
    );
    expect(form.currentState!.validate(), isTrue);
    expect(controller.toValue().isEmpty, isTrue);

    await tester.tap(find.byKey(const ValueKey('two-wheeler-body-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moto').last);
    await tester.pumpAndSettle();
    expect(controller.bodyType, 'motorcycle');
    expect(controller.toValue().isEmpty, isFalse);
  });
}
