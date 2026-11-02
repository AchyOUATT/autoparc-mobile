import '../../../private_sales/data/private_listing_repository.dart';
import 'vehicle.dart';

enum CatalogVehicleSource { vehicle, privateListing }

/// An entry in the public vehicle feed. The native identifiers and detail
/// contracts remain separate; only [key] identifies a card across sources.
class CatalogVehicleItem {
  const CatalogVehicleItem.vehicle(Vehicle value)
    : source = CatalogVehicleSource.vehicle,
      vehicle = value,
      privateListing = null;

  const CatalogVehicleItem.privateListing(PrivateListing value)
    : source = CatalogVehicleSource.privateListing,
      vehicle = null,
      privateListing = value;

  final CatalogVehicleSource source;
  final Vehicle? vehicle;
  final PrivateListing? privateListing;

  bool get isPrivate => source == CatalogVehicleSource.privateListing;
  int get sourceId => vehicle?.id ?? privateListing!.id;
  String get key => '${isPrivate ? 'private_listing' : 'vehicle'}:$sourceId';

  factory CatalogVehicleItem.fromJson(Map<String, dynamic> json) {
    final sourceId = json['source_id'];
    final source = json['source'];
    if (sourceId is! int || sourceId <= 0) {
      throw const FormatException('Invalid catalogue source identifier.');
    }
    if (source != 'vehicle' && source != 'private_listing') {
      throw const FormatException('Unknown catalogue vehicle source.');
    }
    if (json['key'] != '$source:$sourceId') {
      throw const FormatException('Inconsistent catalogue item key.');
    }
    final payload = json[source];
    if (payload is! Map<String, dynamic> ||
        payload['id'] is! int ||
        payload['id'] != sourceId) {
      throw const FormatException('Inconsistent catalogue item payload.');
    }

    return source == 'vehicle'
        ? CatalogVehicleItem.vehicle(Vehicle.fromJson(payload))
        : CatalogVehicleItem.privateListing(PrivateListing(payload));
  }
}
