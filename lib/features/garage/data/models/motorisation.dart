import 'package:equatable/equatable.dart';

import 'owned_vehicle.dart' show VehicleConsumption;

/// Un candidat de référence conservant sa variante, sa source et sa révision.
class Motorisation extends Equatable {
  final int id;
  final String label;
  final int modelYear;
  final String? fuel;
  final double? engineL;
  final int? cylinders;

  /// Les trois cotes, la provenance et le cycle d'essai.
  final VehicleConsumption consumption;

  const Motorisation({
    required this.id,
    required this.label,
    required this.modelYear,
    this.fuel,
    this.engineL,
    this.cylinders,
    required this.consumption,
  });

  factory Motorisation.fromJson(Map<String, dynamic> json) {
    final conso = json['consumption'] is Map<String, dynamic>
        ? json['consumption'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final source = json['source'] is Map<String, dynamic>
        ? json['source'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return Motorisation(
      id: json['id'] as int,
      label: json['label'] as String? ?? '',
      modelYear: json['model_year'] as int? ?? 0,
      fuel: json['fuel'] as String?,
      engineL: _double(json['engine_l']),
      cylinders: json['cylinders'] as int?,
      consumption: VehicleConsumption.fromJson({
        ...json,
        ...conso,
        'label': json['label'],
        'fuel': json['fuel'],
        'source': source['label'],
        'cycle': source['cycle'],
      }),
    );
  }

  @override
  List<Object?> get props => [id];
}

/// Laravel sérialise les décimaux en chaînes : « 2.5 », pas 2.5.
double? _double(Object? value) =>
    value == null ? null : double.tryParse(value.toString());
