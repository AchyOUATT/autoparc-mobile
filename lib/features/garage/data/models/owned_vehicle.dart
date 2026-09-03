import 'package:equatable/equatable.dart';

class OwnedVehicle extends Equatable {
  final int id;
  final String designation;
  final String? nickname;
  final int brandId;
  final int vehicleModelId;
  final String? vin;
  /// Code moteur (ex: "1NZ", "K20", "OM651") — renseigné via décodage VIN
  /// ou saisi manuellement. Optionnel : améliore la précision de la recherche
  /// de pièces compatibles quand il est présent.
  final String? engineCode;
  final String? plateNumber;
  final int? mileageKm;
  final int year;
  final OwnedVehicleIdentity identity;
  final bool compatibilityReady;

  const OwnedVehicle({
    required this.id,
    required this.designation,
    this.nickname,
    required this.brandId,
    required this.vehicleModelId,
    this.vin,
    this.engineCode,
    this.plateNumber,
    this.mileageKm,
    required this.year,
    required this.identity,
    required this.compatibilityReady,
  });

  /// Nom affiché : le surnom en priorité, sinon la désignation complète.
  String get displayName => nickname?.isNotEmpty == true ? nickname! : designation;

  factory OwnedVehicle.fromJson(Map<String, dynamic> json) => OwnedVehicle(
    id:                json['id']               as int,
    designation:       json['designation']       as String,
    nickname:          json['nickname']          as String?,
    brandId:           json['brand_id']          as int,
    vehicleModelId:    json['vehicle_model_id']  as int,
    vin:               json['vin']               as String?,
    engineCode:        json['engine_code']       as String?,
    plateNumber:       json['plate_number']      as String?,
    mileageKm:         json['mileage_km']        as int?,
    year:              json['year']              as int,
    identity:          OwnedVehicleIdentity.fromJson(
                           json['identity'] as Map<String, dynamic>),
    compatibilityReady: json['compatibility_ready'] as bool? ?? false,
  );

  @override
  List<Object?> get props => [id];

  /// Vrai si au moins une donnée technique est connue (moteur ou code moteur).
  bool get hasEngineData => engineCode != null || identity.engineType != null;
}

class OwnedVehicleIdentity extends Equatable {
  final String? brand;
  final String? model;
  final String? trim;
  final String? engineType;
  final String? drivetrain;
  final String? color;

  const OwnedVehicleIdentity({
    this.brand,
    this.model,
    this.trim,
    this.engineType,
    this.drivetrain,
    this.color,
  });

  factory OwnedVehicleIdentity.fromJson(Map<String, dynamic> json) =>
      OwnedVehicleIdentity(
        brand:      json['brand']       as String?,
        model:      json['model']       as String?,
        trim:       json['trim']        as String?,
        engineType: json['engine_type'] as String?,
        drivetrain: json['drivetrain']  as String?,
        color:      json['color']       as String?,
      );

  String get fullName {
    final parts = [brand, model, trim].whereType<String>().toList();
    return parts.isEmpty ? '—' : parts.join(' ');
  }

  @override
  List<Object?> get props => [brand, model, trim];
}
