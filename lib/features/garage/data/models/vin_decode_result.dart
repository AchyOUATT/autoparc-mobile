// Modèle de réponse de GET /catalog/vin-decode/{vin}.

class VinDecodeResult {
  final String vin;
  final bool valid;
  final List<int> yearCandidates;
  final String? engineCode;
  final VinNhtsaSummary? nhtsa;
  final VinSimpleRef? brand;
  final VinModelRef? vehicleModel;
  final VinEngineTypeRef? engineType;
  final VinSimpleRef? drivetrain;

  /// 'high' | 'medium' | 'low' | 'none'
  final String confidence;
  final List<String> warnings;

  const VinDecodeResult({
    required this.vin,
    required this.valid,
    required this.yearCandidates,
    this.engineCode,
    this.nhtsa,
    this.brand,
    this.vehicleModel,
    this.engineType,
    this.drivetrain,
    required this.confidence,
    required this.warnings,
  });

  /// Première année candidate (la plus probable selon NHTSA ou char 10).
  int? get bestYear => yearCandidates.isNotEmpty ? yearCandidates.first : null;

  bool get hasMatches => brand != null || vehicleModel != null;

  factory VinDecodeResult.fromJson(Map<String, dynamic> j) => VinDecodeResult(
        vin:            j['vin']         as String,
        valid:          j['valid']       as bool,
        yearCandidates: (j['year_candidates'] as List<dynamic>? ?? [])
            .map((e) => e as int)
            .toList(),
        engineCode:   j['engine_code']  as String?,
        nhtsa:        j['nhtsa'] != null
            ? VinNhtsaSummary.fromJson(j['nhtsa'] as Map<String, dynamic>)
            : null,
        brand:        j['brand'] != null
            ? VinSimpleRef.fromJson(j['brand'] as Map<String, dynamic>)
            : null,
        vehicleModel: j['vehicle_model'] != null
            ? VinModelRef.fromJson(j['vehicle_model'] as Map<String, dynamic>)
            : null,
        engineType:   j['engine_type'] != null
            ? VinEngineTypeRef.fromJson(j['engine_type'] as Map<String, dynamic>)
            : null,
        drivetrain:   j['drivetrain'] != null
            ? VinSimpleRef.fromJson(j['drivetrain'] as Map<String, dynamic>)
            : null,
        confidence: j['confidence'] as String? ?? 'none',
        warnings:   (j['warnings'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
      );
}

/// Référence simple : id + code + label (drivetrain, brand…).
class VinSimpleRef {
  final int id;
  final String name;

  const VinSimpleRef({required this.id, required this.name});

  factory VinSimpleRef.fromJson(Map<String, dynamic> j) => VinSimpleRef(
        id:   j['id']   as int,
        name: (j['name'] ?? j['label'] ?? j['code'] ?? '') as String,
      );
}

/// Référence modèle avec champs supplémentaires.
class VinModelRef {
  final int id;
  final String name;
  final String? generation;
  final String? bodyType;

  const VinModelRef({
    required this.id,
    required this.name,
    this.generation,
    this.bodyType,
  });

  factory VinModelRef.fromJson(Map<String, dynamic> j) => VinModelRef(
        id:         j['id']         as int,
        name:       j['name']       as String,
        generation: j['generation'] as String?,
        bodyType:   j['body_type']  as String?,
      );

  String get displayName =>
      generation != null ? '$name ($generation)' : name;
}

/// Référence motorisation avec flags carburant/batterie.
class VinEngineTypeRef {
  final int id;
  final String code;
  final String label;
  final bool usesFuel;
  final bool usesBattery;

  const VinEngineTypeRef({
    required this.id,
    required this.code,
    required this.label,
    required this.usesFuel,
    required this.usesBattery,
  });

  factory VinEngineTypeRef.fromJson(Map<String, dynamic> j) => VinEngineTypeRef(
        id:          j['id']           as int,
        code:        j['code']         as String,
        label:       j['label']        as String,
        usesFuel:    j['uses_fuel']    as bool? ?? true,
        usesBattery: j['uses_battery'] as bool? ?? false,
      );
}

/// Données brutes NHTSA (pré-remplissage de champs hors-base côté UI).
class VinNhtsaSummary {
  final String? make;
  final String? model;
  final int? year;
  final String? bodyClass;
  final String? fuelType;
  final String? driveType;
  final int? displacementCc;
  final int? cylinders;
  final String? transmissionStyle;
  /// Code moteur retourné par NHTSA (ex: "1NZ", "K20", "OM651").
  /// Plus complet que le char 8 du VIN — utilisé pour la recherche de pièces.
  final String? engineCodeNhtsa;

  const VinNhtsaSummary({
    this.make,
    this.model,
    this.year,
    this.bodyClass,
    this.fuelType,
    this.driveType,
    this.displacementCc,
    this.cylinders,
    this.transmissionStyle,
    this.engineCodeNhtsa,
  });

  factory VinNhtsaSummary.fromJson(Map<String, dynamic> j) => VinNhtsaSummary(
        make:              j['make']               as String?,
        model:             j['model']              as String?,
        year:              j['year']               as int?,
        bodyClass:         j['body_class']         as String?,
        fuelType:          j['fuel_type']          as String?,
        driveType:         j['drive_type']         as String?,
        displacementCc:    j['displacement_cc']    as int?,
        cylinders:         j['cylinders']          as int?,
        transmissionStyle: j['transmission_style'] as String?,
        engineCodeNhtsa:   j['engine_code_nhtsa']  as String?,
      );
}
