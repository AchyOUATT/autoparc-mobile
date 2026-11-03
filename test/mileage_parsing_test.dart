import 'package:auto/core/utils/mileage.dart';
import 'package:auto/features/garage/data/models/fuel_fill.dart';
import 'package:auto/features/private_sales/data/private_listing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('missing and invalid mileage never become zero', () {
    for (final value in [null, '', ' ', 'unknown', false, -1, 0.4]) {
      expect(parseMileageKm(value), isNull, reason: '$value');
      expect(PrivateListing({'mileage_km': value}).mileageKm, isNull);
    }
    expect(const PrivateListing({}).mileageKm, isNull);
  });

  test('explicit zero and actual readings survive JSON representations', () {
    for (final value in [0, '0', 0.0, '0.0']) {
      expect(PrivateListing({'mileage_km': value}).mileageKm, 0);
    }
    for (final value in [85000, '85000', 85000.0, '85000.0']) {
      expect(parseMileageKm(value), 85000);
    }
  });

  test('fuel fill requires a reading and keeps explicitly recorded zero', () {
    expect(
      () => FuelFill.fromJson({'id': 1, 'litres': 20}),
      throwsFormatException,
    );
    expect(
      FuelFill.fromJson({'id': 1, 'litres': 20, 'mileage_km': 0}).mileageKm,
      0,
    );
  });
}
