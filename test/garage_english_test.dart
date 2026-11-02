import 'package:auto/core/l10n/consumption_labels.dart';
import 'package:auto/features/garage/data/garage_repository.dart';
import 'package:auto/features/garage/data/models/fuel_fill.dart';
import 'package:auto/features/garage/data/models/motorisation.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/providers/fuel_fills_provider.dart';
import 'package:auto/features/garage/presentation/widgets/consumption_tile.dart';
import 'package:auto/features/garage/presentation/widgets/engine_prompt.dart';
import 'package:auto/features/garage/presentation/widgets/fuel_fill_dialog.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _vehicle = OwnedVehicle(
  id: 7,
  designation: 'Toyota Camry 2013',
  brandId: 1,
  vehicleModelId: 3,
  year: 2013,
  mileageKm: 97400,
  identity: OwnedVehicleIdentity(brand: 'Toyota', model: 'Camry'),
  compatibilityReady: false,
);

const _refs = CatalogRefs(
  brands: [],
  vehicleModels: [],
  trims: [],
  engineTypes: [
    EngineTypeRef(
      id: 1,
      code: 'petrol',
      label: 'Essence',
      usesFuel: true,
      usesBattery: false,
    ),
    EngineTypeRef(
      id: 2,
      code: 'electric',
      label: 'Électrique',
      usesFuel: false,
      usesBattery: true,
    ),
    EngineTypeRef(
      id: 3,
      code: 'custom',
      label: 'Custom reference',
      usesFuel: true,
      usesBattery: false,
    ),
  ],
  drivetrains: [],
  colors: [],
  features: [],
  locations: [],
);

class _Repository implements GarageRepository {
  @override
  Future<List<Motorisation>> motorisations({
    required int vehicleModelId,
    int? year,
    int? engineTypeId,
    int? drivetrainId,
    int? trimId,
    String? engineCode,
  }) async => [
    Motorisation.fromJson({
      'id': 1,
      'label': '2,5 l 4 cyl. boîte auto. 6',
      'model_year': 2013,
      'engine_l': '2.5',
      'cylinders': 4,
      'fuel': 'Essence ordinaire',
      'consumption': {'combined_l_100km': '8.2'},
      'source': {
        'code': 'nrcan',
        'label': 'Ressources naturelles Canada',
        'cycle': 'essai canadien, cinq cycles',
      },
    }),
    Motorisation.fromJson({
      'id': 2,
      'label': 'Unknown source label',
      'model_year': 2013,
      'engine_l': '3.5',
      'cylinders': 6,
      'transmission_code': 'M6',
      'fuel_code': 'Z',
      'fuel': 'Essence super',
      'consumption': {'combined_l_100km': '9.4'},
      'source': {
        'code': 'eea',
        'label': "Agence europeenne pour l'environnement",
        'cycle_code': 'wltp',
        'cycle': 'norme WLTP',
      },
    }),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoFills extends FuelFillsNotifier {
  @override
  Future<List<FuelFill>> build(int id) async => [];
}

Widget _app(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

void main() {
  test(
    'official reference codes, legacy values and custom labels remain distinct',
    () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final fr = await AppLocalizations.delegate.load(const Locale('fr'));
      const legacy = '2,5 l 4 cyl. boîte auto. 6';
      expect(
        consumptionEngineLabel(legacy, en),
        '2.5 L 4 cyl. 6-speed automatic',
      );
      expect(consumptionEngineLabel(legacy, fr), legacy);
      expect(
        consumptionEngineLabel('Custom engine V8', en),
        'Custom engine V8',
      );
      expect(
        consumptionEngineLabel('Custom engine V8 boîte auto. 6', en),
        'Custom engine V8 boîte auto. 6',
      );
      expect(
        consumptionEngineLabel(
          'Custom label',
          en,
          engineL: 3.5,
          cylinders: 6,
          transmissionCode: 'M6',
        ),
        '3.5 L 6 cyl. 6-speed manual',
      );
      expect(
        consumptionEngineLabel(
          'Custom label',
          en,
          transmissionCode: 'new-code',
        ),
        'Custom label',
      );
      expect(consumptionFuelLabel('Essence ordinaire', en), 'Regular petrol');
      expect(consumptionFuelLabel('Other fuel', en), 'Other fuel');
      expect(
        consumptionFuelLabel('Hybride rechargeable', en, code: 'H'),
        en.garageConsumptionFuelHybridUnspecified,
      );
      expect(
        consumptionFuelLabel('Hybride rechargeable', en),
        en.garageConsumptionFuelPlugInHybrid,
      );
      expect(
        consumptionSourceLabel('Ressources naturelles Canada', en),
        'Natural Resources Canada',
      );
      expect(
        consumptionCycleLabel('legacy server label', en, code: 'wltp'),
        'WLTP standard',
      );
      expect(
        consumptionCycleLabel('Personal test cycle', en),
        'Personal test cycle',
      );
      expect(consumptionRange(8.2, 9.4, en), '8.2–9.4 L/100 km');
      expect(consumptionRange(8.2, 9.4, fr), '8,2 à 9,4 l/100 km');
    },
  );

  testWidgets(
    'English engine prompt renders at narrow width and translates fuel choices',
    (tester) async {
      await tester.pumpWidget(
        _app(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: SizedBox(
              width: 268,
              child: MissingEngineBanner(vehicle: _vehicle),
            ),
          ),
          overrides: [catalogRefsProvider.overrideWith((ref) async => _refs)],
        ),
      );
      await tester.pumpAndSettle();
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(en.garageEngineMissingTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(en.garageCompleteAction));
      await tester.pumpAndSettle();
      expect(find.text('What fuel does this vehicle use?'), findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<EngineTypeRef>));
      await tester.pumpAndSettle();
      expect(find.text('Petrol'), findsWidgets);
      expect(find.text('Electric'), findsWidgets);
      expect(find.text('Custom reference'), findsWidgets);
      expect(find.text('Essence'), findsNothing);
      expect(find.text('Électrique'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('English engine picker translates old and new server responses', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const ConsumptionTile(vehicle: _vehicle),
        overrides: [garageRepositoryProvider.overrideWithValue(_Repository())],
      ),
    );
    await tester.pumpAndSettle();
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.tap(find.text(en.garageConsumptionQuestion));
    await tester.pumpAndSettle();
    expect(
      find.text(en.garageConsumptionVersionTitle('Camry')),
      findsOneWidget,
    );
    expect(find.text('2.5 L 4 cyl. 6-speed automatic'), findsOneWidget);
    expect(find.text('3.5 L 6 cyl. 6-speed manual'), findsOneWidget);
    expect(find.textContaining('Regular petrol'), findsOneWidget);
    expect(
      find.textContaining(en.garageConsumptionSourceValue('8.2')),
      findsOneWidget,
    );
    expect(find.textContaining(en.garageConsumptionLegacy), findsNWidgets(2));
    expect(
      find.textContaining(en.garageConsumptionCycleCanadianFive),
      findsOneWidget,
    );
    expect(find.textContaining('Premium petrol'), findsOneWidget);
    expect(
      find.textContaining(en.garageConsumptionSourceValue('9.4')),
      findsOneWidget,
    );
    expect(find.textContaining('WLTP standard'), findsOneWidget);
    expect(find.textContaining('boîte'), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English legacy reference keeps its source value in details', (
    tester,
  ) async {
    const vehicle = OwnedVehicle(
      id: 7,
      designation: 'Toyota Camry 2013',
      brandId: 1,
      vehicleModelId: 3,
      year: 2013,
      identity: OwnedVehicleIdentity(brand: 'Toyota', model: 'Camry'),
      compatibilityReady: false,
      motorisationId: 1,
      consumption: VehicleConsumption(
        label: '2,5 l 4 cyl. boîte auto. 6',
        combinedL100km: 8.2,
        source: 'Ressources naturelles Canada',
        sourceCode: 'nrcan',
        cycle: 'essai canadien, cinq cycles',
        cycleCode: '5-cycle',
      ),
    );
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(_app(const ConsumptionTile(vehicle: vehicle)));
    await tester.pumpAndSettle();
    expect(find.text(en.garageConsumptionLegacy), findsOneWidget);
    expect(find.textContaining('8.2'), findsNothing);

    await tester.tap(find.text(en.garageConsumptionDetails));
    await tester.pumpAndSettle();
    expect(find.text(en.garageConsumptionSourceValue('8.2')), findsOneWidget);
    expect(find.text(en.garageConsumptionNotVerified), findsOneWidget);
    expect(find.textContaining('Natural Resources Canada'), findsOneWidget);
    expect(
      find.textContaining(en.garageConsumptionCycleCanadianFive),
      findsOneWidget,
    );
    expect(find.textContaining('boîte'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'English refill dialogue calculates quantities and validates before submission',
    (tester) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showFuelFillDialog(context, _vehicle),
              child: const Text('Open refill'),
            ),
          ),
          overrides: [fuelFillsProvider.overrideWith(_NoFills.new)],
        ),
      );
      await tester.tap(find.text('Open refill'));
      await tester.pumpAndSettle();
      expect(find.text('Amount paid'), findsOneWidget);
      expect(find.text('Price per litre'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Price per litre'),
        '730',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Amount paid'),
        '10000',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('13.7 l'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Amount paid'), '');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'The amount and price per litre give an impossible quantity.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
