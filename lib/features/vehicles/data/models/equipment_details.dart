import 'package:equatable/equatable.dart';

/// Details declared for one machine; labels do not imply a certified model.
class EquipmentDetails extends Equatable {
  const EquipmentDetails({
    this.brandLabel,
    this.modelLabel,
    this.serialNumber,
    this.registrationNumber,
    this.parkNumber,
    this.operatingHours,
    this.hourReadingDate,
    this.odometerKm,
    this.powerKw,
    this.transmission,
    this.ratedLoadKg,
    this.workingHeightM,
    this.outreachM,
    this.liftHeightM,
    this.operatingWeightKg,
    this.bucketCapacityM3,
    this.ptoRpm,
    this.cabin,
    this.quickCoupler,
    this.attachments,
    this.engineSerialNumber,
  });

  final String? brandLabel;
  final String? modelLabel;
  final String? serialNumber;
  final String? registrationNumber;
  final String? parkNumber;
  final double? operatingHours;
  final String? hourReadingDate;
  final double? odometerKm;
  final double? powerKw;
  final String? transmission;
  final double? ratedLoadKg;
  final double? workingHeightM;
  final double? outreachM;
  final double? liftHeightM;
  final double? operatingWeightKg;
  final double? bucketCapacityM3;
  final int? ptoRpm;
  final String? cabin;
  final bool? quickCoupler;
  final String? attachments;
  final String? engineSerialNumber;

  factory EquipmentDetails.fromJson(Map<String, dynamic> json) =>
      EquipmentDetails(
        brandLabel: _text(json['brand_label']),
        modelLabel: _text(json['model_label']),
        serialNumber: _text(json['serial_number']),
        registrationNumber: _text(json['registration_number']),
        parkNumber: _text(json['park_number']),
        operatingHours: _number(json['operating_hours']),
        hourReadingDate: _text(json['hour_reading_date']),
        odometerKm: _number(json['odometer_km']),
        powerKw: _number(json['power_kw']),
        transmission: _text(json['transmission']),
        ratedLoadKg: _number(json['rated_load_kg']),
        workingHeightM: _number(json['working_height_m']),
        outreachM: _number(json['outreach_m']),
        liftHeightM: _number(json['lift_height_m']),
        operatingWeightKg: _number(json['operating_weight_kg']),
        bucketCapacityM3: _number(json['bucket_capacity_m3']),
        ptoRpm: _integer(json['pto_rpm']),
        cabin: _text(json['cabin']),
        quickCoupler: _boolean(json['quick_coupler']),
        attachments: _text(json['attachments']),
        engineSerialNumber: _text(json['engine_serial_number']),
      );

  bool get isEmpty => toJson().values.every((value) => value == null);

  Map<String, dynamic> toJson() => {
    'brand_label': _text(brandLabel),
    'model_label': _text(modelLabel),
    'serial_number': _text(serialNumber),
    'registration_number': _text(registrationNumber),
    'park_number': _text(parkNumber),
    'operating_hours': operatingHours,
    'hour_reading_date': _text(hourReadingDate),
    'odometer_km': odometerKm,
    'power_kw': powerKw,
    'transmission': _text(transmission),
    'rated_load_kg': ratedLoadKg,
    'working_height_m': workingHeightM,
    'outreach_m': outreachM,
    'lift_height_m': liftHeightM,
    'operating_weight_kg': operatingWeightKg,
    'bucket_capacity_m3': bucketCapacityM3,
    'pto_rpm': ptoRpm,
    'cabin': _text(cabin),
    'quick_coupler': quickCoupler,
    'attachments': _text(attachments),
    'engine_serial_number': _text(engineSerialNumber),
  };

  @override
  List<Object?> get props => [
    brandLabel,
    modelLabel,
    serialNumber,
    registrationNumber,
    parkNumber,
    operatingHours,
    hourReadingDate,
    odometerKm,
    powerKw,
    transmission,
    ratedLoadKg,
    workingHeightM,
    outreachM,
    liftHeightM,
    operatingWeightKg,
    bucketCapacityM3,
    ptoRpm,
    cabin,
    quickCoupler,
    attachments,
    engineSerialNumber,
  ];
}

String? _text(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  return text.isEmpty ? null : text;
}

double? _number(Object? value) {
  final number = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');
  return number != null && number.isFinite && number >= 0 ? number : null;
}

int? _integer(Object? value) {
  final number = _number(value);
  return number != null && number == number.truncateToDouble()
      ? number.toInt()
      : null;
}

bool? _boolean(Object? value) => switch (value) {
  bool boolean => boolean,
  0 || '0' => false,
  1 || '1' => true,
  _ => null,
};
