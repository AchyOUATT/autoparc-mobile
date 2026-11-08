import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/data/models/equipment_details.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> assetJson() => {
  'id': 92,
  'reference': 'EQ-0092',
  'designation': 'Machine déclarée',
  'asset_kind': 'equipment',
  'equipment_type': 'agricultural_tractor',
  'registration_status': 'unregistered',
  'vehicle_type': null,
  'identity': {'brand': null, 'model': null},
  'commercial': {
    'condition': 'used',
    'status': 'in_stock',
    'availability': 'sale',
  },
};

void main() {
  test('equipment decimal strings and tri-state declarations round trip', () {
    final raw = {
      'brand_label': ' Kubota ',
      'model_label': ' M7060 ',
      'serial_number': 'ABC-009',
      'registration_number': 'BK-123',
      'park_number': 'PARC-007',
      'operating_hours': '1250.75',
      'hour_reading_date': '2026-11-03',
      'odometer_km': '42.5',
      'power_kw': '54.5',
      'transmission': 'mechanical',
      'rated_load_kg': '2000.25',
      'working_height_m': '12.4',
      'outreach_m': '7.5',
      'lift_height_m': '5.8',
      'operating_weight_kg': '2400.5',
      'bucket_capacity_m3': '1.25',
      'pto_rpm': '540',
      'cabin': 'closed',
      'quick_coupler': false,
      'attachments': 'Fourches',
      'engine_serial_number': 'ENGINE-5',
    };
    final details = EquipmentDetails.fromJson(raw);
    expect(details.brandLabel, 'Kubota');
    expect(details.modelLabel, 'M7060');
    expect(details.operatingHours, 1250.75);
    expect(details.odometerKm, 42.5);
    expect(details.powerKw, 54.5);
    expect(details.ratedLoadKg, 2000.25);
    expect(details.workingHeightM, 12.4);
    expect(details.outreachM, 7.5);
    expect(details.liftHeightM, 5.8);
    expect(details.operatingWeightKg, 2400.5);
    expect(details.bucketCapacityM3, 1.25);
    expect(details.ptoRpm, 540);
    expect(details.quickCoupler, isFalse);
    expect(details.isEmpty, isFalse);
    expect(EquipmentDetails.fromJson(details.toJson()), details);
    expect(const EquipmentDetails().quickCoupler, isNull);
    expect(const EquipmentDetails(quickCoupler: false).isEmpty, isFalse);
  });

  test('invalid and absent measurements never become zero declarations', () {
    final details = EquipmentDetails.fromJson({
      'operating_hours': 'NaN',
      'power_kw': -1,
      'odometer_km': 'Infinity',
      'pto_rpm': 540.5,
      'quick_coupler': 'unknown',
      'serial_number': '   ',
    });
    expect(details.isEmpty, isTrue);
    expect(
      EquipmentDetails.fromJson({'quick_coupler': 0}).quickCoupler,
      isFalse,
    );
    expect(
      EquipmentDetails.fromJson({'quick_coupler': '1'}).quickCoupler,
      isTrue,
    );
  });

  test('equipment avoids road defaults and accepts uncatalogued identity', () {
    final json = assetJson()
      ..['equipment_details'] = {
        'brand_label': 'Kubota',
        'model_label': 'M7060',
        'operating_hours': '123.5',
      };
    final vehicle = Vehicle.fromJson(json);
    expect(vehicle.isEquipment, isTrue);
    expect(vehicle.vehicleType, isEmpty);
    expect(vehicle.isPassenger, isFalse);
    expect(vehicle.isImported, isFalse);
    expect(vehicle.isRegistered, isFalse);
    expect(vehicle.brandId, isNull);
    expect(vehicle.vehicleModelId, isNull);
    expect(vehicle.identity.fullName, 'Kubota M7060');
    expect(vehicle.equipmentDetails.operatingHours, 123.5);
    final empty = Vehicle.fromJson(assetJson()..['identity'] = null);
    expect(empty.equipmentDetails.isEmpty, isTrue);
    expect(empty.identity.fullName, isEmpty);
    final road = Vehicle.fromJson(assetJson()..remove('asset_kind'));
    expect(road.assetKind, 'road_vehicle');
    expect(road.isPassenger, isTrue);
    expect(road.isImported, isTrue);
  });

  test(
    'reference filtering keeps old road models and isolates machine types',
    () {
      final refs = CatalogRefs(
        brands: const [],
        vehicleModels: [
          ModelRef.fromJson({
            'id': 1,
            'brand_id': 3,
            'name': 'Older road model',
          }),
          ModelRef.fromJson({
            'id': 2,
            'brand_id': 3,
            'name': 'Tractor',
            'equipment_category': 'agricultural_tractor',
          }),
          const ModelRef(
            id: 3,
            brandId: 3,
            name: 'Forklift',
            equipmentCategory: 'forklift',
          ),
          const ModelRef(
            id: 4,
            brandId: 3,
            name: 'Inactive tractor',
            equipmentCategory: 'agricultural_tractor',
            isActive: false,
          ),
        ],
        trims: const [],
        engineTypes: const [],
        drivetrains: const [],
        colors: const [],
        features: const [],
        locations: const [],
      );
      expect(refs.modelsForBrand(3).map((m) => m.id), [1]);
      expect(refs.modelsForBrand(3, assetKind: 'equipment').map((m) => m.id), [
        2,
        3,
      ]);
      expect(
        refs
            .modelsForBrand(
              3,
              assetKind: 'equipment',
              equipmentType: 'agricultural_tractor',
            )
            .map((m) => m.id),
        [2],
      );
      expect(refs.vehicleModels[1].resolvedVehicleType, isNull);
    },
  );
}
