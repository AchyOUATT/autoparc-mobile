/// Données de référence chargées depuis /catalog/sync et /catalog/countries.
/// Utilisées pour peupler les menus déroulants du formulaire d'enregistrement.

class BrandRef {
  final int id;
  final String name;
  final bool isActive;
  const BrandRef({required this.id, required this.name, required this.isActive});

  factory BrandRef.fromJson(Map<String, dynamic> j) => BrandRef(
    id:       j['id']        as int,
    name:     j['name']      as String,
    isActive: j['is_active'] as bool? ?? true,
  );
}

class ModelRef {
  final int id;
  final int brandId;
  final String name;
  final String? generation;
  /// Type de carrosserie stocké sur le modèle (peut être libre ou une valeur
  /// normalisée : 'sedan' | 'suv' | 'pickup' | 'hatchback' | 'van' | 'minibus' |
  /// 'bus' | 'estate' | 'coupe' | 'convertible' | 'truck' | 'other').
  final String? bodyType;

  /// Valeurs par défaut renseignées dans la base (priment sur l'inférence).
  final String? defaultVehicleType;  // passenger | utility | heavy
  final int?    defaultSeats;
  final int?    defaultDoors;
  final String? defaultTransmission; // manual | automatic | cvt
  final int?    defaultPowerHp;

  const ModelRef({
    required this.id,
    required this.brandId,
    required this.name,
    this.generation,
    this.bodyType,
    this.defaultVehicleType,
    this.defaultSeats,
    this.defaultDoors,
    this.defaultTransmission,
    this.defaultPowerHp,
  });

  factory ModelRef.fromJson(Map<String, dynamic> j) => ModelRef(
    id:                  j['id']                   as int,
    brandId:             j['brand_id']              as int,
    name:                j['name']                  as String,
    generation:          j['generation']             as String?,
    bodyType:            j['body_type']              as String?,
    defaultVehicleType:  j['default_vehicle_type']  as String?,
    defaultSeats:        j['default_seats']          as int?,
    defaultDoors:        j['default_doors']          as int?,
    defaultTransmission: j['default_transmission']  as String?,
    defaultPowerHp:      j['default_power_hp']       as int?,
  );

  String get displayName => generation != null ? '$name ($generation)' : name;

  /// Déduit la valeur normalisée de `body_style` (enum véhicule) à partir du
  /// `body_type` stocké sur le modèle. Couvre les valeurs normalisées ET les
  /// termes français encore présents dans certaines bases.
  String? get inferredBodyStyle {
    if (bodyType == null) return null;
    final bt = bodyType!.toLowerCase().replaceAll('-', ' ').trim();

    // Valeurs déjà normalisées (après tinker de migration)
    const normalized = {
      'sedan', 'hatchback', 'suv', 'pickup', 'van',
      'minibus', 'bus', 'estate', 'coupe', 'convertible', 'truck', 'other',
    };
    if (normalized.contains(bt)) return bt;

    // Termes français / variantes non normalisées
    if (bt.contains('berline'))                                         return 'sedan';
    if (bt.contains('citadine') || bt.contains('compacte')
                                || bt.contains('hatch'))                return 'hatchback';
    if (bt == 'suv'    || bt.contains('4x4') || bt.contains('4×4')
                       || bt.contains('crossover')
                       || bt.contains('tout terrain'))                  return 'suv';
    if (bt.contains('pick up'))                                         return 'pickup';
    if (bt.contains('utilitaire') || bt.contains('fourgon'))            return 'van';
    if (bt.contains('mini bus'))                                        return 'minibus';
    if (bt == 'bus'    || bt == 'car' || bt.contains('autocar'))        return 'bus';
    if (bt.contains('break') || bt.contains('wagon')
                             || bt.contains('estate'))                  return 'estate';
    if (bt.contains('coup'))                                            return 'coupe';
    if (bt.contains('cabriolet') || bt.contains('convertible'))        return 'convertible';
    if (bt.contains('camion') || bt.contains('truck'))                  return 'truck';
    if (bt.contains('monospace') || bt.contains('mpv'))                 return 'van';
    if (bt.contains('autre') || bt.contains('other'))                   return 'other';

    return null; // inconnu → staff choisit manuellement
  }

  /// Retourne le type de véhicule : valeur DB en priorité, sinon inférence.
  String? get resolvedVehicleType => defaultVehicleType ?? inferredVehicleType;

  /// Déduit le type de véhicule ('passenger' | 'utility' | 'heavy') à partir
  /// du body style inféré. Retourne null si inconnu.
  String? get inferredVehicleType {
    switch (inferredBodyStyle) {
      case 'sedan':
      case 'hatchback':
      case 'suv':
      case 'estate':
      case 'coupe':
      case 'convertible':
        return 'passenger';
      case 'pickup':
      case 'van':
      case 'minibus':
        return 'utility';
      case 'bus':
      case 'truck':
        return 'heavy';
      default:
        return null; // 'other' ou inconnu → staff choisit manuellement
    }
  }
}

class TrimRef {
  final int id;
  final int vehicleModelId;
  final String name;
  final int? defaultEngineTypeId;
  const TrimRef({
    required this.id, required this.vehicleModelId, required this.name,
    this.defaultEngineTypeId,
  });

  factory TrimRef.fromJson(Map<String, dynamic> j) => TrimRef(
    id:                   j['id']                    as int,
    vehicleModelId:       j['vehicle_model_id']       as int,
    name:                 j['name']                   as String,
    defaultEngineTypeId:  j['default_engine_type_id'] as int?,
  );
}

class EngineTypeRef {
  final int id;
  final String code;
  final String label;
  final bool usesFuel;
  final bool usesBattery;
  const EngineTypeRef({
    required this.id, required this.code, required this.label,
    required this.usesFuel, required this.usesBattery,
  });

  factory EngineTypeRef.fromJson(Map<String, dynamic> j) => EngineTypeRef(
    id:          j['id']            as int,
    code:        j['code']          as String,
    label:       j['label']         as String,
    usesFuel:    j['uses_fuel']     as bool? ?? true,
    usesBattery: j['uses_battery']  as bool? ?? false,
  );
}

class DrivetrainRef {
  final int id;
  final String code;
  final String label;
  const DrivetrainRef({required this.id, required this.code, required this.label});

  factory DrivetrainRef.fromJson(Map<String, dynamic> j) => DrivetrainRef(
    id:    j['id']    as int,
    code:  j['code']  as String,
    label: j['label'] as String,
  );
}

class ColorRef {
  final int id;
  final String name;
  final String? hexCode;
  const ColorRef({required this.id, required this.name, this.hexCode});

  factory ColorRef.fromJson(Map<String, dynamic> j) => ColorRef(
    id:      j['id']       as int,
    name:    j['name']     as String,
    hexCode: j['hex_code'] as String?,
  );
}

class CountryRef {
  final int id;
  final String name;
  final String? iso2;
  const CountryRef({required this.id, required this.name, this.iso2});

  factory CountryRef.fromJson(Map<String, dynamic> j) => CountryRef(
    id:   j['id']   as int,
    name: j['name'] as String,
    iso2: j['iso2'] as String?,
  );
}

/// Agence / showroom du parc (ville + nom).
class LocationRef {
  final int id;
  final String name;
  final String city;
  final String? address;
  final String? phone;
  const LocationRef({
    required this.id,
    required this.name,
    required this.city,
    this.address,
    this.phone,
  });

  factory LocationRef.fromJson(Map<String, dynamic> j) => LocationRef(
    id:      j['id']       as int,
    name:    j['name']     as String,
    city:    j['city']     as String,
    address: j['address']  as String?,
    phone:   j['phone']    as String?,
  );

  /// Label affiché : "Showroom Paspanga — Ouagadougou"
  String get displayLabel => '$name — $city';
}

/// Équipement / option d'un véhicule (climatisation, GPS, caméra de recul…).
class FeatureRef {
  final int id;
  final String name;
  final String? category; // confort | securite | multimedia | null
  const FeatureRef({required this.id, required this.name, this.category});

  factory FeatureRef.fromJson(Map<String, dynamic> j) => FeatureRef(
    id:       j['id']       as int,
    name:     j['name']     as String,
    category: j['category'] as String?,
  );
}

/// Agrégat de toutes les tables de référence (une seule requête /catalog/sync).
class CatalogRefs {
  final List<BrandRef> brands;
  final List<ModelRef> vehicleModels;
  final List<TrimRef> trims;
  final List<EngineTypeRef> engineTypes;
  final List<DrivetrainRef> drivetrains;
  final List<ColorRef> colors;
  final List<FeatureRef> features;
  final List<LocationRef> locations;

  const CatalogRefs({
    required this.brands,
    required this.vehicleModels,
    required this.trims,
    required this.engineTypes,
    required this.drivetrains,
    required this.colors,
    required this.features,
    required this.locations,
  });

  List<ModelRef> modelsForBrand(int brandId) =>
      vehicleModels.where((m) => m.brandId == brandId).toList();

  List<TrimRef> trimsForModel(int modelId) =>
      trims.where((t) => t.vehicleModelId == modelId).toList();

  /// Locations groupées par ville.
  Map<String, List<LocationRef>> get locationsByCity {
    final result = <String, List<LocationRef>>{};
    for (final l in locations) {
      result.putIfAbsent(l.city, () => []).add(l);
    }
    return result;
  }

  /// Toutes les villes distinctes.
  List<String> get cities => locationsByCity.keys.toList()..sort();

  /// Features groupées par catégorie (clé = catégorie ou 'autre').
  Map<String, List<FeatureRef>> get featuresByCategory {
    final result = <String, List<FeatureRef>>{};
    for (final f in features) {
      final cat = f.category ?? 'autre';
      result.putIfAbsent(cat, () => []).add(f);
    }
    return result;
  }
}
