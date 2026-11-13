import 'package:equatable/equatable.dart';

/// Owner-declared two-wheeler facts, kept off `vehicles.body_style`.
class TwoWheelerConfiguration extends Equatable {
  const TwoWheelerConfiguration({
    this.bodyType,
    this.stroke,
    this.cooling,
    this.starter,
    this.drive,
    this.transmission,
  });

  static const bodyTypes = <String>['motorcycle', 'scooter', 'moped', 'other'];
  static const strokes = <String>['two_stroke', 'four_stroke'];
  static const coolings = <String>['air', 'liquid'];
  static const starters = <String>['kick', 'electric', 'both'];
  static const drives = <String>['chain', 'belt', 'shaft'];
  static const transmissions = <String>['manual', 'semi_automatic', 'cvt'];
  static const vinMin = 5;
  static const vinMax = 32;

  final String? bodyType;
  final String? stroke;
  final String? cooling;
  final String? starter;
  final String? drive;
  final String? transmission;

  factory TwoWheelerConfiguration.fromJson(Map<String, dynamic> json) =>
      TwoWheelerConfiguration(
        bodyType: _text(json['body_type']),
        stroke: _text(json['stroke']),
        cooling: _text(json['cooling']),
        starter: _text(json['starter']),
        drive: _text(json['drive']),
        transmission: _text(json['transmission']),
      );

  bool get isEmpty => toJson().values.every((value) => value == null);

  @override
  List<Object?> get props => [
    bodyType,
    stroke,
    cooling,
    starter,
    drive,
    transmission,
  ];

  Map<String, dynamic> toJson() => {
    'body_type': _text(bodyType),
    'stroke': _text(stroke),
    'cooling': _text(cooling),
    'starter': _text(starter),
    'drive': _text(drive),
    'transmission': _text(transmission),
  };
}

String? _text(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
