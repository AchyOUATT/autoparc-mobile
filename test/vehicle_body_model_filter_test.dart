import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:flutter_test/flutter_test.dart';

const _sedan = ModelRef(id: 1, brandId: 7, name: 'Berline A', bodyType: 'berline');
const _normalizedSedan = ModelRef(id: 2, brandId: 7, name: 'Berline B', bodyType: 'sedan');
const _suv = ModelRef(id: 3, brandId: 7, name: 'SUV', bodyType: 'SUV');
const _truck = ModelRef(id: 4, brandId: 7, name: 'Camion', bodyType: 'camion');
const _unknown = ModelRef(id: 5, brandId: 7, name: 'Unknown');
const _inactive = ModelRef(id: 6, brandId: 7, name: 'Inactive', bodyType: 'sedan', isActive: false);
const _foreign = ModelRef(id: 7, brandId: 8, name: 'Other make', bodyType: 'sedan');
const _refs = CatalogRefs(
  brands: [],
  vehicleModels: [_sedan, _normalizedSedan, _suv, _truck, _unknown, _inactive, _foreign],
  trims: [], engineTypes: [], drivetrains: [], colors: [], features: [], locations: [],
);

void main() {
  test('existing unfiltered brand selection remains unchanged', () {
    expect(_refs.modelsForBrand(7).map((m) => m.id), [1, 2, 3, 4, 5]);
    expect(_refs.modelsForBrand(8).map((m) => m.id), [7]);
  });

  test('sedan filter handles normalized and French catalogue body labels', () {
    expect(_refs.modelsForBrand(7, bodyStyle: 'sedan').map((m) => m.id), [1, 2]);
    expect(_refs.modelsForBrand(7, bodyStyle: 'suv').map((m) => m.id), [3]);
    expect(_refs.modelsForBrand(7, bodyStyle: 'truck').map((m) => m.id), [4]);
  });

  test('unknown bodies and inactive models cannot masquerade as strict matches', () {
    expect(_refs.modelsForBrand(7, bodyStyle: 'bus'), isEmpty);
    expect(_refs.modelsForBrand(7, bodyStyle: 'sedan'), isNot(contains(_unknown)));
    expect(_refs.modelsForBrand(7, bodyStyle: 'sedan'), isNot(contains(_inactive)));
    expect(_refs.vehicleModels, hasLength(7), reason: 'Filtering must not destroy cached or historical references.');
  });

  test('other body is an escape from the strict body filter', () {
    expect(_refs.modelsForBrand(7, bodyStyle: 'other').map((m) => m.id), [1, 2, 3, 4, 5]);
  });
}
