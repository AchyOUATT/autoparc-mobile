import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/core/local/catalog_local_cache.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/pages/add_vehicle_to_garage_page.dart';
import 'package:auto/features/partners/data/models/partner.dart';
import 'package:auto/features/partners/data/partner_repository.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/data/models/vehicle_classification_selection.dart';
import 'package:auto/features/vehicles/data/vehicle_admin_repository.dart';
import 'package:auto/features/vehicles/presentation/pages/vehicle_register_page.dart';
import 'package:auto/features/vehicles/presentation/widgets/vehicle_reference_dropdown.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/shared/models/paginated_response.dart';
import 'package:auto/l10n/app_localizations.dart';

const toyota = BrandRef(id: 3, name: 'Toyota', isActive: true);
const honda = BrandRef(id: 4, name: 'Honda', isActive: true);
const mercedes = BrandRef(id: 7, name: 'Mercedes-Benz', isActive: true);
const actros = ModelRef(id: 14, brandId: 7, name: 'Actros', bodyType: 'truck', defaultVehicleType: 'heavy');
const diesel = EngineTypeRef(id: 8, code: 'diesel', label: 'Diesel', usesFuel: true, usesBattery: false);
const ancienne = ModelRef(id: 10, brandId: 3, name: 'Corolla', generation: 'E140');
const existante = ModelRef(id: 11, brandId: 3, name: 'Corolla', generation: 'E180');
const civic = ModelRef(id: 12, brandId: 4, name: 'Civic');
const finition = TrimRef(id: 20, vehicleModelId: 11, name: 'LE');
const essence = EngineTypeRef(
  id: 5, code: 'petrol', label: 'Essence', usesFuel: true, usesBattery: false,
);
const traction = DrivetrainRef(id: 6, code: 'FWD', label: 'Traction');
const refs = CatalogRefs(
  brands: [toyota, honda, mercedes], vehicleModels: [ancienne, existante, civic, actros],
  trims: [finition], engineTypes: [essence, diesel], drivetrains: [traction],
  colors: [], features: [], locations: [],
);

const knownSedan = ModelRef(id: 21, brandId: 3, name: 'Camry', bodyType: 'berline');
const knownSuv = ModelRef(id: 22, brandId: 3, name: 'RAV4', bodyType: 'suv');
const knownSedanTrim = TrimRef(id: 31, vehicleModelId: 21, name: 'Sedan trim');
final bodyFilterRefs = CatalogRefs(
  brands: refs.brands,
  vehicleModels: [...refs.vehicleModels, knownSedan, knownSuv],
  trims: [...refs.trims, knownSedanTrim],
  engineTypes: refs.engineTypes, drivetrains: refs.drivetrains,
  colors: refs.colors, features: refs.features, locations: refs.locations,
);

VehicleClassificationSelection selection() =>
    VehicleClassificationSelection.fromIds(
      refs, brandId: 3, modelId: 11, trimId: 20,
      engineTypeId: 5, drivetrainId: 6, engineCode: '2ZR-FE',
    );

Map<String, dynamic> vehicleJson() {
  final payload = (jsonDecode(File('test/fixtures/vehicle_detail.json').readAsStringSync())
      as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  payload.addAll({
    'brand_id': 3, 'vehicle_model_id': 11, 'trim_id': 20,
    'engine_type_id': 5, 'drivetrain_id': 6,
  });
  (payload['identity'] as Map<String, dynamic>).addAll({
    // Labels intentionally differ: editing must use the raw relationships.
    'brand': 'ancien libelle', 'model': 'Corolla', 'trim': 'ancien nom',
    'year': 2016,
  });
  (payload['technical'] as Map<String, dynamic>)['engine_code'] = '2ZR-FE';
  return payload;
}

Finder dropdown<T>() => find.byWidgetPredicate(
  (widget) => widget is DropdownButtonFormField<T>, skipOffstage: false,
);

T? selected<T>(WidgetTester tester) =>
    tester.state<FormFieldState<T>>(dropdown<T>()).value;

Future<void> choose<T>(WidgetTester tester, T? value) async {
  tester.widget<DropdownButtonFormField<T>>(dropdown<T>()).onChanged!(value);
  await tester.pumpAndSettle();
}

void main() {
  test('restores exact generation IDs without matching names', () {
    expect(selection().model?.id, 11);
    expect(selection().trim?.id, 20);
    final missing = VehicleClassificationSelection.fromIds(refs);
    expect(missing.brand, isNull);
    expect(missing.model, isNull);
    final wrongParent = VehicleClassificationSelection.fromIds(
      refs, brandId: 4, modelId: 11, trimId: 20,
    );
    expect(wrongParent.model, isNull);
    expect(wrongParent.trim, isNull);
  });

  test('changed brand clears model, trim and old technical identity', () {
    final draft = selection()..selectBrand(honda);
    expect(draft.toPayload(editing: true), {
      'brand_id': 4, 'vehicle_model_id': null, 'trim_id': null,
      'engine_type_id': null, 'drivetrain_id': null, 'engine_code': null,
    });
  });

  test('changed generation sends explicit removals in an update', () {
    final draft = selection()..selectModel(ancienne);
    expect(draft.toPayload(editing: true), {
      'brand_id': 3, 'vehicle_model_id': 10, 'trim_id': null,
      'engine_type_id': null, 'drivetrain_id': null, 'engine_code': null,
    });
  });

  test('selecting the same generation preserves its confirmed identity', () {
    final draft = selection()..selectModel(existante)..selectBrand(toyota);
    expect(draft.trim?.id, 20);
    expect(draft.engineCode, '2ZR-FE');
    expect(draft.drivetrain?.id, 6);
  });

  test('free model does not submit the former model, trim or VIN engine code', () {
    final draft = selection()..selectModel(null);
    final payload = draft.toPayload(
      editing: false, allowFreeModel: true, modelLibre: '  CX-9  ',
    );
    expect(payload['vehicle_model_id'], isNull);
    expect(payload['model_libre'], 'CX-9');
    expect(payload.containsKey('trim_id'), isFalse);
    expect(payload.containsKey('engine_code'), isFalse);
    draft.selectModel(ancienne);
    expect(draft.toPayload(editing: false, allowFreeModel: true,
      modelLibre: 'CX-9')['model_libre'], isNull);
  });

  test('vehicle resource raw IDs survive parsing', () {
    final vehicle = Vehicle.fromJson(vehicleJson());
    expect(vehicle.brandId, 3);
    expect(vehicle.vehicleModelId, 11);
    expect(vehicle.trimId, 20);
    expect(vehicle.engineTypeId, 5);
    expect(vehicle.drivetrainId, 6);
  });

  test('public partner vehicle tolerates private reference and IDs being absent', () {
    final json = vehicleJson();
    for (final key in ['reference', 'brand_id', 'vehicle_model_id', 'trim_id',
      'engine_type_id', 'drivetrain_id', 'color_id']) {
      json.remove(key);
    }
    final vehicle = Vehicle.fromJson(json);
    expect(vehicle.reference, '');
    expect(vehicle.brandId, isNull);
    expect(vehicle.vehicleModelId, isNull);
    expect(vehicle.trimId, isNull);
  });

  test('garage resource keeps its raw optional IDs and free model', () {
    final json = (jsonDecode(File('test/fixtures/my_vehicles.json').readAsStringSync())
        as Map<String, dynamic>)['data'] as List;
    final row = Map<String, dynamic>.from(json.first as Map)..addAll({
      'trim_id': 20, 'engine_type_id': 5, 'drivetrain_id': 6, 'color_id': 7,
      'vehicle_model_id': null, 'model_libre': 'CX-9',
    });
    final vehicle = OwnedVehicle.fromJson(row);
    expect(vehicle.trimId, 20);
    expect(vehicle.engineTypeId, 5);
    expect(vehicle.drivetrainId, 6);
    expect(vehicle.colorId, 7);
    expect(vehicle.vehicleModelId, isNull);
    expect(vehicle.modelLibre, 'CX-9');
  });

  Future<void> showRegistration(WidgetTester tester, _VehicleRepository repo,
      {Map<String, dynamic>? existingJson, bool creatingNew = false,
      CatalogRefs references = refs, String language = 'fr'}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogRefsProvider.overrideWith((_) async => references),
        countriesProvider.overrideWith((_) async => []),
        vehicleAdminRepositoryProvider.overrideWithValue(repo),
        partnerRepositoryProvider.overrideWithValue(_PartnerRepository()),
      ],
      child: MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: VehicleRegisterPage(existing: creatingNew ? null : Vehicle.fromJson(existingJson ?? vehicleJson()))),
    ));
    await tester.pumpAndSettle();
  }

  Finder bodyStyleField() => find.byWidgetPredicate(
    (widget) => widget is DropdownButtonFormField<String> &&
        widget.key is ValueKey<String> &&
        (widget.key! as ValueKey<String>).value.startsWith('vehicle-body-style-'),
    skipOffstage: false,
  );

  Future<void> chooseBody(WidgetTester tester, String value) async {
    tester.widget<DropdownButtonFormField<String>>(bodyStyleField()).onChanged!(value);
    await tester.pumpAndSettle();
  }

  String? bodyStyle(WidgetTester tester) =>
      tester.state<FormFieldState<String>>(bodyStyleField()).value;

  Finder categoryChip(String label) => find.byWidgetPredicate(
    (widget) => widget is ChoiceChip && widget.label is Text &&
        (widget.label as Text).data == label,
    skipOffstage: false,
  );

  Future<void> chooseCategory(WidgetTester tester, String label) async {
    tester.widget<ChoiceChip>(categoryChip(label)).onSelected!(true);
    await tester.pumpAndSettle();
  }

  void expectCategory(WidgetTester tester, String label) =>
      expect(tester.widget<ChoiceChip>(categoryChip(label)).selected, isTrue);

  TextField technicalField(WidgetTester tester, String label) =>
      tester.widget<TextField>(find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration?.labelText == label,
        skipOffstage: false,
      ));

  void editTechnicalField(WidgetTester tester, String label, String value) {
    final field = technicalField(tester, label);
    field.controller!.text = value;
    field.onChanged!(value);
  }

  List<ModelRef> availableModels(WidgetTester tester) =>
      tester.widget<VehicleReferenceDropdown<ModelRef>>(find.byWidgetPredicate(
        (widget) => widget is VehicleReferenceDropdown<ModelRef>, skipOffstage: false,
      )).items;

  Future<void> toggleModelBodyFilter(WidgetTester tester) async {
    tester.widget<TextButton>(find.byKey(const ValueKey('vehicle-model-body-filter'), skipOffstage: false)).onPressed!();
    await tester.pumpAndSettle();
  }

  Map<String, dynamic> knownSedanJson() => vehicleJson()..addAll({
    'vehicle_model_id': knownSedan.id, 'trim_id': knownSedanTrim.id,
    'body_style': 'sedan', 'vehicle_type': 'passenger',
  });

  for (final language in ['fr', 'en']) {
    testWidgets('body selection proposes matching models and clears stale technical identity in $language', (tester) async {
      await showRegistration(tester, _VehicleRepository(), existingJson: knownSedanJson(),
          references: bodyFilterRefs, language: language);
      expect(availableModels(tester).map((m) => m.id), [knownSedan.id]);
      expect(selected<ModelRef>(tester)?.id, knownSedan.id);
      await chooseBody(tester, 'suv');
      expect(availableModels(tester).map((m) => m.id), [knownSuv.id]);
      expect(selected<ModelRef>(tester), isNull);
      expect(selected<EngineTypeRef>(tester), isNull);
      expect(selected<DrivetrainRef>(tester), isNull);
      expect(dropdown<TrimRef>(), findsNothing);
      expect(selected<BrandRef>(tester)?.id, toyota.id);
      await choose<ModelRef>(tester, knownSuv);
      expect(selected<ModelRef>(tester)?.id, knownSuv.id);
      expect(bodyStyle(tester), 'suv');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('no matching model explains the empty result and offers all models', (tester) async {
    await showRegistration(tester, _VehicleRepository(), existingJson: knownSedanJson(), references: bodyFilterRefs);
    await choose<BrandRef>(tester, mercedes);
    expect(availableModels(tester), isEmpty);
    expect(find.byKey(const ValueKey('vehicle-model-body-empty'), skipOffstage: false), findsOneWidget);
    await toggleModelBodyFilter(tester);
    expect(availableModels(tester).map((m) => m.id), [actros.id]);
    await choose<ModelRef>(tester, actros);
    expect(selected<ModelRef>(tester)?.id, actros.id);
    expect(bodyStyle(tester), 'truck');
    expectCategory(tester, 'Poids lourd');
    expect(tester.takeException(), isNull);
  });

  testWidgets('unknown catalogue bodies remain accessible without pretending they match', (tester) async {
    await showRegistration(tester, _VehicleRepository(), existingJson: knownSedanJson(), references: bodyFilterRefs);
    expect(availableModels(tester).map((m) => m.id), [knownSedan.id]);
    await toggleModelBodyFilter(tester);
    expect(availableModels(tester), contains(existante));
    expect(availableModels(tester), contains(knownSuv));
    await choose<ModelRef>(tester, existante);
    expect(bodyStyle(tester), 'sedan');
    await toggleModelBodyFilter(tester);
    expect(selected<ModelRef>(tester)?.id, existante.id);
    expect(availableModels(tester), contains(existante));
    expect(availableModels(tester), isNot(contains(knownSuv)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing retains a historical model whose catalogue body conflicts', (tester) async {
    final json = knownSedanJson()..addAll({'vehicle_model_id': knownSuv.id, 'trim_id': null});
    await showRegistration(tester, _VehicleRepository(), existingJson: json, references: bodyFilterRefs);
    expect(selected<ModelRef>(tester)?.id, knownSuv.id);
    expect(availableModels(tester), contains(knownSedan));
    expect(availableModels(tester), contains(knownSuv));
    expect(bodyStyle(tester), 'sedan');
    expect(tester.takeException(), isNull);
  });

  testWidgets('other body removes the strict model filter', (tester) async {
    await showRegistration(tester, _VehicleRepository(), existingJson: knownSedanJson(), references: bodyFilterRefs);
    await chooseBody(tester, 'other');
    expect(availableModels(tester), contains(knownSedan));
    expect(availableModels(tester), contains(knownSuv));
    expect(availableModels(tester), contains(existante));
    expect(selected<ModelRef>(tester)?.id, knownSedan.id);
    expect(tester.takeException(), isNull);
  });

  testWidgets('manual truck body selects heavy and preserves the existing vehicle identity', (tester) async {
    final repo = _VehicleRepository();
    await showRegistration(tester, repo);
    await chooseBody(tester, 'truck');
    expectCategory(tester, 'Poids lourd');
    expect(bodyStyle(tester), 'truck');
    expect(selected<BrandRef>(tester)?.id, toyota.id);
    expect(selected<ModelRef>(tester)?.id, existante.id);
    expect(selected<TrimRef>(tester)?.id, finition.id);
    expect(selected<EngineTypeRef>(tester)?.id, essence.id);
    expect(selected<DrivetrainRef>(tester)?.id, traction.id);
    expect(technicalField(tester, 'Places').controller!.text, '7');
    expect(technicalField(tester, 'Portes').controller!.text, '4');
    for (var step = 0; step < 4; step++) {
      tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
      await tester.pumpAndSettle();
    }
    expect(repo.payload!['vehicle_type'], 'heavy');
    expect(repo.payload!['body_style'], 'truck');
    expect(repo.payload!['engine_code'], '2ZR-FE');
    expect(repo.payload!['seats'], 7);
    expect(repo.payload!['doors'], 4);
  });

  testWidgets('manual heavy category clears an incompatible body without inventing a truck', (tester) async {
    final json = vehicleJson()..['body_style'] = 'sedan';
    await showRegistration(tester, _VehicleRepository(), existingJson: json);
    await chooseCategory(tester, 'Poids lourd');
    expectCategory(tester, 'Poids lourd');
    expect(bodyStyle(tester), isNull);
    expect(technicalField(tester, 'Places').controller!.text, '7');
    expect(technicalField(tester, 'Portes').controller!.text, '4');
    expect(selected<ModelRef>(tester)?.id, existante.id);
    expect(selected<TrimRef>(tester)?.id, finition.id);
    expect(selected<EngineTypeRef>(tester)?.id, essence.id);
  });

  testWidgets('reselecting a legacy truck body repairs its inconsistent passenger category', (tester) async {
    final json = vehicleJson()..['body_style'] = 'truck';
    await showRegistration(tester, _VehicleRepository(), existingJson: json);
    expectCategory(tester, 'Particulier');
    expect(bodyStyle(tester), 'truck');
    await chooseBody(tester, 'truck');
    expectCategory(tester, 'Poids lourd');
    expect(bodyStyle(tester), 'truck');
    expect(technicalField(tester, 'Places').controller!.text, '7');
    expect(technicalField(tester, 'Portes').controller!.text, '4');
  });

  testWidgets('new truck removes only the unconfirmed passenger seat and door defaults', (tester) async {
    await showRegistration(tester, _VehicleRepository(), creatingNew: true);
    expect(technicalField(tester, 'Places').controller!.text, '5');
    expect(technicalField(tester, 'Portes').controller!.text, '4');
    await chooseBody(tester, 'truck');
    expectCategory(tester, 'Poids lourd');
    expect(technicalField(tester, 'Places').controller!.text, isEmpty);
    expect(technicalField(tester, 'Portes').controller!.text, isEmpty);
  });

  testWidgets('explicit seat and door input survives entering heavy and repeated selections', (tester) async {
    await showRegistration(tester, _VehicleRepository(), creatingNew: true);
    // These values equal the initial defaults, but their explicit entry matters.
    editTechnicalField(tester, 'Places', '5');
    editTechnicalField(tester, 'Portes', '4');
    await chooseBody(tester, 'truck');
    await chooseCategory(tester, 'Poids lourd');
    await chooseBody(tester, 'truck');
    expect(technicalField(tester, 'Places').controller!.text, '5');
    expect(technicalField(tester, 'Portes').controller!.text, '4');
  });

  testWidgets('bus remains a bus when heavy is selected again, and sedan returns to passenger', (tester) async {
    await showRegistration(tester, _VehicleRepository());
    await chooseBody(tester, 'bus');
    expectCategory(tester, 'Poids lourd');
    await chooseCategory(tester, 'Poids lourd');
    expect(bodyStyle(tester), 'bus');
    await chooseBody(tester, 'sedan');
    expectCategory(tester, 'Particulier');
    expect(bodyStyle(tester), 'sedan');
    await chooseBody(tester, 'truck');
    await chooseCategory(tester, 'Particulier');
    expect(bodyStyle(tester), isNull);
  });

  testWidgets('utility bodies select utility and compatible manual categories keep the body', (tester) async {
    await showRegistration(tester, _VehicleRepository());
    for (final body in ['pickup', 'van', 'minibus']) {
      await chooseBody(tester, body);
      expectCategory(tester, 'Utilitaire');
      await chooseCategory(tester, 'Utilitaire');
      expect(bodyStyle(tester), body);
    }
    await chooseCategory(tester, 'Poids lourd');
    expect(bodyStyle(tester), isNull);
  });

  testWidgets('other body preserves the manually selected category', (tester) async {
    await showRegistration(tester, _VehicleRepository());
    await chooseBody(tester, 'truck');
    await chooseBody(tester, 'other');
    expectCategory(tester, 'Poids lourd');
    expect(bodyStyle(tester), 'other');
    await chooseCategory(tester, 'Utilitaire');
    expect(bodyStyle(tester), 'other');
    expectCategory(tester, 'Utilitaire');
  });

  testWidgets('editing keeps exact generation and trim, then resets dependents', (tester) async {
    await showRegistration(tester, _VehicleRepository());
    expect(selected<ModelRef>(tester)?.id, 11);
    expect(selected<TrimRef>(tester)?.id, 20);
    expect(selected<EngineTypeRef>(tester)?.id, 5);
    await choose<ModelRef>(tester, ancienne);
    expect(selected<ModelRef>(tester)?.id, 10);
    expect(selected<EngineTypeRef>(tester), isNull);
    expect(selected<DrivetrainRef>(tester), isNull);
  });

  testWidgets('the existing form classifies and saves an Actros as a heavy truck', (tester) async {
    final repo = _VehicleRepository();
    await showRegistration(tester, repo);
    await choose<BrandRef>(tester, mercedes);
    await choose<ModelRef>(tester, actros);
    await choose<EngineTypeRef>(tester, diesel);
    for (var step = 0; step < 4; step++) {
      tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
      await tester.pumpAndSettle();
    }
    expect(repo.payload, isNotNull);
    expect(repo.payload!['brand_id'], mercedes.id);
    expect(repo.payload!['vehicle_model_id'], actros.id);
    expect(repo.payload!['vehicle_type'], 'heavy');
    expect(repo.payload!['body_style'], 'truck');
    expect(repo.payload!['seats'], isNull);
    expect(repo.payload!['doors'], isNull);
    expect(repo.payload!['trim_id'], isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing sends null trim and clears stale consumption after model change', (tester) async {
    final repo = _VehicleRepository();
    await showRegistration(tester, repo);
    await choose<ModelRef>(tester, ancienne);
    await choose<EngineTypeRef>(tester, essence);
    for (var step = 0; step < 4; step++) {
      tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
      await tester.pumpAndSettle();
    }
    expect(repo.payload, isNotNull);
    expect(repo.payload!['vehicle_model_id'], 10);
    expect(repo.payload!.containsKey('trim_id'), isTrue);
    expect(repo.payload!['trim_id'], isNull);
    expect(repo.payload!['drivetrain_id'], isNull);
    expect(repo.payload!['engine_code'], isNull);
    expect(repo.payload!.containsKey('consumption_combined'), isTrue);
    expect(repo.payload!['consumption_combined'], isNull);
  });

  for (final monthlyOnly in [true, false]) {
    testWidgets('rental accepts ${monthlyOnly ? 'monthly' : 'daily'} rate alone and clears the removed rate', (tester) async {
      final json = vehicleJson();
      (json['commercial'] as Map<String, dynamic>).addAll({
        'availability': 'rent',
        'rental_daily_rate': '25000.00',
        'rental_monthly_rate': '450000.00',
      });
      final repo = _VehicleRepository();
      await showRegistration(tester, repo, existingJson: json);
      final clearedRate = find.byWidgetPredicate((widget) => widget is TextField &&
        widget.decoration?.labelText == (monthlyOnly ? 'Tarif journalier' : 'Tarif mensuel'),
        skipOffstage: false);
      tester.widget<TextField>(clearedRate).controller!.clear();
      for (var step = 0; step < 4; step++) {
        tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
        await tester.pumpAndSettle();
      }
      expect(repo.payload, isNotNull);
      expect(repo.payload!['rental_daily_rate'], monthlyOnly ? null : 25000);
      expect(repo.payload!['rental_monthly_rate'], monthlyOnly ? 450000 : null);
      expect(repo.payload!.containsKey('rental_daily_rate'), isTrue);
      expect(repo.payload!.containsKey('rental_monthly_rate'), isTrue);
    });
  }

  testWidgets('rental refuses submission when daily and monthly rates are empty', (tester) async {
    final json = vehicleJson();
    (json['commercial'] as Map<String, dynamic>).addAll({
      'availability': 'rent', 'rental_daily_rate': null, 'rental_monthly_rate': null,
    });
    final repo = _VehicleRepository();
    await showRegistration(tester, repo, existingJson: json);
    for (var step = 0; step < 4; step++) {
      tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
      await tester.pumpAndSettle();
    }
    expect(repo.payload, isNull);

    // Le refus est désormais SOUS le champ, et non dans une bannière qui
    // passe. La règle est la même ; c'est son `validator:` qui la porte,
    // maintenant que chaque étape a son propre `Form` et qu'il s'exécute.
    //
    // Deux occurrences : la règle vaut pour le tarif journalier comme pour
    // le mensuel, et chacun porte son message. C'est voulu — corriger l'un
    // suffit, et laisser l'autre muet désignerait un seul coupable.
    expect(find.text('Saisissez un tarif journalier ou mensuel'), findsWidgets);
  });

  testWidgets('changing brand in garage clears its previous model and fuel', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [catalogRefsProvider.overrideWith((_) async => refs)],
      child: const MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AddVehicleToGaragePage()),
    ));
    await tester.pumpAndSettle();
    await choose<BrandRef>(tester, toyota);
    await choose<ModelRef>(tester, existante);
    await choose<TrimRef>(tester, finition);
    await choose<EngineTypeRef>(tester, essence);
    await choose<BrandRef>(tester, honda);
    expect(selected<ModelRef>(tester), isNull);
    expect(selected<EngineTypeRef>(tester), isNull);
    expect(find.byWidgetPredicate((w) => w is DropdownButtonFormField<TrimRef>,
      skipOffstage: false), findsNothing);
  });
}

class _VehicleRepository extends VehicleAdminRepository {
  Map<String, dynamic>? payload;
  _VehicleRepository() : super(ApiClient(), CatalogLocalCache());

  @override
  Future<Vehicle> updateVehicle(int id, Map<String, dynamic> data) async {
    payload = Map<String, dynamic>.from(data);
    // Capture the real form submission while retaining the page for checks.
    throw const ApiException(message: 'Captured test request', statusCode: 422);
  }
}

class _PartnerRepository extends PartnerRepository {
  _PartnerRepository() : super(ApiClient());

  @override
  Future<PaginatedResponse<Partner>> getPartners({int page = 1, int perPage = 50,
      String? search, bool includeInactive = false}) async =>
      const PaginatedResponse(data: [], currentPage: 1, lastPage: 1, total: 0, perPage: 50);
}
