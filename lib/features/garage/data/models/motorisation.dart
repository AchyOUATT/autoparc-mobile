import 'package:equatable/equatable.dart';

import 'owned_vehicle.dart' show VehicleConsumption;

/// Une motorisation proposée au choix du propriétaire.
///
/// Ce qu'il doit reconnaître, c'est son moteur — « 2,5 l 4 cyl., boîte auto.
/// 6 » — et non une finition : « LE » et « XLE » ne changent la consommation
/// que sur les hybrides, où le poids des équipements pèse.
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
    final conso  = json['consumption'] as Map<String, dynamic>? ?? const {};
    final source = json['source'] as Map<String, dynamic>? ?? const {};

    return Motorisation(
      id:        json['id']         as int,
      label:     json['label']      as String? ?? '',
      modelYear: json['model_year'] as int? ?? 0,
      fuel:      json['fuel']       as String?,
      engineL:   _double(json['engine_l']),
      cylinders: json['cylinders']  as int?,
      consumption: VehicleConsumption.fromJson({
        'label':            json['label'],
        'fuel':             json['fuel'],
        'city_l_100km':     conso['city_l_100km'],
        'highway_l_100km':  conso['highway_l_100km'],
        'combined_l_100km': conso['combined_l_100km'],
        'source':           source['label'],
        'cycle':            source['cycle'],
      }),
    );
  }

  @override
  List<Object?> get props => [id];
}

/// Laravel sérialise les décimaux en chaînes : « 2.5 », pas 2.5.
double? _double(Object? value) =>
    value == null ? null : double.tryParse(value.toString());
