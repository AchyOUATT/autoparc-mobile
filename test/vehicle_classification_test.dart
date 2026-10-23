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
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/shared/models/paginated_response.dart';

const toyota = BrandRef(id: 3, name: 'Toyota', isActive: true);
const honda = BrandRef(id: 4, name: 'Honda', isActive: true);
const ancienne = ModelRef(id: 10, brandId: 3, name: 'Corolla', generation: 'E140');
const existante = ModelRef(id: 11, brandId: 3, name: 'Corolla', generation: 'E180');
const civic = ModelRef(id: 12, brandId: 4, name: 'Civic');
const finition = TrimRef(id: 20, vehicleModelId: 11, name: 'LE');
const essence = EngineTypeRef(
  id: 5, code: 'petrol', label: 'Essence', usesFuel: true, usesBattery: false,
);
const traction = DrivetrainRef(id: 6, code: 'FWD', label: 'Traction');
const refs = CatalogRefs(
  brands: [toyota, honda], vehicleModels: [ancienne, existante, civic],
  trims: [finition], engineTypes: [essence], drivetrains: [traction],
  colors: [], features: [], locations: [],
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
      {Map<String, dynamic>? existingJson}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogRefsProvider.overrideWith((_) async => refs),
        countriesProvider.overrideWith((_) async => []),
        vehicleAdminRepositoryProvider.overrideWithValue(repo),
        partnerRepositoryProvider.overrideWithValue(_PartnerRepository()),
      ],
      child: MaterialApp(home: VehicleRegisterPage(existing: Vehicle.fromJson(existingJson ?? vehicleJson()))),
    ));
    await tester.pumpAndSettle();
  }

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
    expect(find.text('Saisissez un tarif journalier ou mensuel.'), findsOneWidget);
  });

  testWidgets('changing brand in garage clears its previous model and fuel', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [catalogRefsProvider.overrideWith((_) async => refs)],
      child: const MaterialApp(home: AddVehicleToGaragePage()),
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
