import 'package:equatable/equatable.dart';

/// Owner-declared configuration. A label is never decoded into technical facts.
class HeavyVehicleConfiguration extends Equatable {
  const HeavyVehicleConfiguration({
    this.versionLabel,
    this.cabLabel,
    this.axleConfiguration,
    this.chassisType,
    this.bodyUse,
    this.emissionStandard,
    this.ptacKg,
    this.ptraKg,
  });

  final String? versionLabel;
  final String? cabLabel;
  final String? axleConfiguration;
  final String? chassisType;
  final String? bodyUse;
  final String? emissionStandard;
  final int? ptacKg;
  final int? ptraKg;

  factory HeavyVehicleConfiguration.fromJson(Map<String, dynamic> json) =>
      HeavyVehicleConfiguration(
        versionLabel: _text(json['version_label']),
        cabLabel: _text(json['cab_label']),
        axleConfiguration: _text(json['axle_configuration']),
        chassisType: _text(json['chassis_type']),
        bodyUse: _text(json['body_use']),
        emissionStandard: _text(json['emission_standard']),
        ptacKg: _positiveInteger(json['ptac_kg']),
        ptraKg: _positiveInteger(json['ptra_kg']),
      );

  bool get isEmpty => toJson().values.every((value) => value == null);

  @override
  List<Object?> get props => [
    versionLabel,
    cabLabel,
    axleConfiguration,
    chassisType,
    bodyUse,
    emissionStandard,
    ptacKg,
    ptraKg,
  ];

  Map<String, dynamic> toJson() => {
    'version_label': _text(versionLabel),
    'cab_label': _text(cabLabel),
    'axle_configuration': _text(axleConfiguration),
    'chassis_type': _text(chassisType),
    'body_use': _text(bodyUse),
    'emission_standard': _text(emissionStandard),
    'ptac_kg': ptacKg,
    'ptra_kg': ptraKg,
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
