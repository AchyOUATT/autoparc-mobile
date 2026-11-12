import 'package:equatable/equatable.dart';

/// Owner-declared configuration. A label is never decoded into technical facts.
class HeavyVehicleConfiguration extends Equatable {
  const HeavyVehicleConfiguration({
    this.versionLabel,
    this.cabLabel,
    this.axleConfiguration,
    this.chassisType,
    this.bodyType,
    this.bodyUse,
    this.emissionStandard,
    this.ptacKg,
    this.ptraKg,
    this.usefulVolumeM3,
    this.tankCapacityLiters,
    this.payloadKg,
  });

  static const bodyTypes = <String>[
    'tanker',
    'tipper',
    'tractor_unit',
    'flatbed',
    'box',
    'mixer',
    'other',
  ];

  static const usefulVolumeMin = 0.01;
  static const usefulVolumeMax = 500.0;
  static const tankCapacityMin = 1;
  static const tankCapacityMax = 200000;
  static const payloadMin = 1;
  static const payloadMax = 1000000;

  final String? versionLabel;
  final String? cabLabel;
  final String? axleConfiguration;
  final String? chassisType;
  final String? bodyType;
  final String? bodyUse;
  final String? emissionStandard;
  final int? ptacKg;
  final int? ptraKg;
  final double? usefulVolumeM3;
  final int? tankCapacityLiters;
  final int? payloadKg;

  factory HeavyVehicleConfiguration.fromJson(Map<String, dynamic> json) =>
      HeavyVehicleConfiguration(
        versionLabel: _text(json['version_label']),
        cabLabel: _text(json['cab_label']),
        axleConfiguration: _text(json['axle_configuration']),
        chassisType: _text(json['chassis_type']),
        bodyType: _text(json['body_type']),
        bodyUse: _text(json['body_use']),
        emissionStandard: _text(json['emission_standard']),
        ptacKg: _positiveInteger(json['ptac_kg']),
        ptraKg: _positiveInteger(json['ptra_kg']),
        usefulVolumeM3: _positiveVolume(json['useful_volume_m3']),
        tankCapacityLiters: _positiveInteger(json['tank_capacity_liters']),
        payloadKg: _positiveInteger(json['payload_kg']),
      );

  bool get isEmpty => toJson().values.every((value) => value == null);

  @override
  List<Object?> get props => [
    versionLabel,
    cabLabel,
    axleConfiguration,
    chassisType,
    bodyType,
    bodyUse,
    emissionStandard,
    ptacKg,
    ptraKg,
    usefulVolumeM3,
    tankCapacityLiters,
    payloadKg,
  ];

  Map<String, dynamic> toJson() => {
    'version_label': _text(versionLabel),
    'cab_label': _text(cabLabel),
    'axle_configuration': _text(axleConfiguration),
    'chassis_type': _text(chassisType),
    'body_type': _text(bodyType),
    'body_use': _text(bodyUse),
    'emission_standard': _text(emissionStandard),
    'ptac_kg': ptacKg,
    'ptra_kg': ptraKg,
    'useful_volume_m3': usefulVolumeM3,
    'tank_capacity_liters': tankCapacityLiters,
    'payload_kg': payloadKg,
  };
}

String? _text(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int? _positiveInteger(Object? value) {
  final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
  return parsed != null && parsed > 0 ? parsed : null;
}

double? _positiveVolume(Object? value) {
  final parsed = switch (value) {
    null => null,
    num n => n.toDouble(),
    _ => double.tryParse(value.toString().trim().replaceAll(',', '.')),
  };
  if (parsed == null || parsed <= 0) return null;
  return (parsed * 100).round() / 100;
}
