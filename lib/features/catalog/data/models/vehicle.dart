import 'package:equatable/equatable.dart';

// Laravel sérialise decimal:2 en String ("3500000.00") — ces helpers acceptent les deux.
double _d(dynamic v) => v is num ? v.toDouble() : double.parse(v.toString());
double? _dq(dynamic v) => v == null ? null : _d(v);

// ── Feature / équipement ─────────────────────────────────────────────

/// Laravel sérialise les colonnes `decimal` en chaînes — `"9.40"`, pas `9.4`.
/// Un cast direct en `num?` lève une exception qui fait échouer le parsing de
/// tout le catalogue, pas seulement du champ concerné.
double? _asDouble(Object? value) => switch (value) {
  null    => null,
  num n   => n.toDouble(),
  _       => double.tryParse(value.toString()),
};

int? _asInt(Object? value) => switch (value) {
  null    => null,
  int n   => n,
  num n   => n.toInt(),
  _       => int.tryParse(value.toString()),
};

class VehicleFeature extends Equatable {
  final int    id;
  final String name;
  final String category; // 'dotation' | 'confort' | 'securite' | 'multimedia' | 'aide_conduite' | 'autre'

  const VehicleFeature({
    required this.id,
    required this.name,
    required this.category,
  });

  factory VehicleFeature.fromJson(Map<String, dynamic> json) => VehicleFeature(
    id:       json['id']       as int,
    name:     json['name']     as String,
    category: json['category'] as String,
  );

  @override
  List<Object?> get props => [id];
}

/// Modèle principal d'un véhicule tel que retourné par VehicleResource.
class Vehicle extends Equatable {
  final int id;
  final String reference;
  final String? vin;
  final String designation;
  final String registrationStatus; // 'unregistered' | 'registered'
  final String vehicleType;        // 'passenger' | 'utility' | 'heavy'
  final String? bodyStyle;         // 'sedan' | 'suv' | 'pickup' | 'minibus' | 'bus' | …
  final VehicleIdentity identity;
  final VehicleCommercial commercial;
  final VehicleImport? import_;
  final int faultsCount;
  final List<String> mediaUrls;
  final List<VehicleFeature> features;

  /// Kilométrage. L'API le résout côté serveur : compteur de la carte grise
  /// pour un véhicule immatriculé, odomètre relevé à l'import sinon.
  final int? mileageKm;

  /// Consommation mixte, en L/100 km.
  final double? combinedL100km;

  /// Fourchette officielle du modèle, sur la fiche détaillée uniquement.
  ///
  /// Une annonce connaît son modèle et son millésime, rarement sa
  /// motorisation : le vendeur saisit « Toyota Camry 2013 », pas « 2,5 l
  /// quatre cylindres ». Or l'écart entre les moteurs d'un même modèle atteint
  /// couramment un litre et demi aux cent. On annonce donc une fourchette.
  final OfficialConsumption? officialConsumption;

  /// Nombre d'équipements hors dotation standard, calculé par l'API.
  ///
  /// Null dans la liste du catalogue, qui ne charge pas les équipements : le
  /// badge « Full option » ne vit que sur la fiche.
  final int? optionalFeatureCount;

  /// Vrai si le véhicule mérite la mention « full option ».
  ///
  /// Ce n'est pas une finition — aucun constructeur n'en fabrique une qui
  /// porte ce nom. C'est un terme du marché de l'import, que le serveur
  /// recalcule à partir des équipements réellement rattachés, pour que
  /// l'acheteur puisse le vérifier juste en dessous.
  final bool isFullOption;

  const Vehicle({
    required this.id,
    required this.reference,
    this.vin,
    required this.designation,
    required this.registrationStatus,
    this.vehicleType = 'passenger',
    this.bodyStyle,
    required this.identity,
    required this.commercial,
    this.import_,
    required this.faultsCount,
    required this.mediaUrls,
    this.features = const [],
    this.mileageKm,
    this.combinedL100km,
    this.officialConsumption,
    this.optionalFeatureCount,
    this.isFullOption = false,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final status = json['registration_status'];
    return Vehicle(
      id:                 json['id'] as int,
      reference:          json['reference'] as String,
      vin:                json['vin'] as String?,
      designation:        json['designation'] as String,
      registrationStatus: status is Map ? status['value'] as String : status as String,
      vehicleType:        json['vehicle_type'] as String? ?? 'passenger',
      bodyStyle:          json['body_style']   as String?,
      identity:           VehicleIdentity.fromJson(json['identity'] as Map<String, dynamic>),
      commercial:         VehicleCommercial.fromJson(json['commercial'] as Map<String, dynamic>),
      import_:            json['import'] != null
                              ? VehicleImport.fromJson(json['import'] as Map<String, dynamic>)
                              : null,
      faultsCount:        json['faults_count'] as int? ?? 0,
      mediaUrls:          (json['media'] as List?)
                              ?.map((m) => m['url'] as String? ?? '')
                              .where((u) => u.isNotEmpty)
                              .toList() ??
                          [],
      features:           (json['features'] as List?)
                              ?.map((f) => VehicleFeature.fromJson(f as Map<String, dynamic>))
                              .toList() ??
                          [],
      mileageKm:          _asInt((json['technical'] as Map<String, dynamic>?)?['mileage_km']),
      combinedL100km:     _asDouble(
                              (json['consumption'] as Map<String, dynamic>?)?['combined_l_100km']),
      officialConsumption: OfficialConsumption.depuisJson(
                              (json['consumption'] as Map<String, dynamic>?)?['official']),
      optionalFeatureCount: _asInt(json['optional_feature_count']),
      isFullOption:         json['is_full_option'] as bool? ?? false,
    );
  }

  bool get isImported    => registrationStatus == 'unregistered';
  bool get isRegistered  => registrationStatus == 'registered';
  bool get isUtility     => vehicleType == 'utility';
  bool get isHeavy       => vehicleType == 'heavy';
  bool get isPassenger   => vehicleType == 'passenger';

  @override
  List<Object?> get props => [id, reference];
}

// ── Identité ──────────────────────────────────────────────────────

class VehicleIdentity extends Equatable {
  final String brand;

  /// Slug de la marque (`land-rover`, `mercedes-benz`…). Sert à retrouver le
  /// logo : `assets/brands/<slug>.svg`. Le nom affiché ne convient pas comme
  /// nom de fichier une fois accentué ou espacé.
  final String? brandSlug;

  /// Chemin du logo côté serveur, si un jour le staff en téléverse un.
  final String? brandLogoPath;

  final String model;
  final String? generation;
  final String? trim;
  final String? engineType;
  final String? drivetrain;
  final String? color;

  /// Code hexadécimal de la teinte, ex. `#4A4A4A`. Sert à afficher une
  /// pastille : « Bordeaux » ou « Gris titanium » ne se devinent pas.
  final String? colorHex;

  /// Finition de la peinture : `opaque`, `metallise`, `nacre`.
  final String? colorFinish;

  final int? year;

  const VehicleIdentity({
    required this.brand,
    this.brandSlug,
    this.brandLogoPath,
    required this.model,
    this.generation,
    this.trim,
    this.engineType,
    this.drivetrain,
    this.color,
    this.colorHex,
    this.colorFinish,
    this.year,
  });

  factory VehicleIdentity.fromJson(Map<String, dynamic> json) => VehicleIdentity(
    brand:         json['brand']           as String,
    brandSlug:     json['brand_slug']      as String?,
    brandLogoPath: json['brand_logo_path'] as String?,
    model:       json['model']       as String,
    generation:  json['generation']  as String?,
    trim:        json['trim']        as String?,
    engineType:  json['engine_type'] as String?,
    drivetrain:  json['drivetrain']  as String?,
    color:       json['color']       as String?,
    colorHex:    json['color_hex']    as String?,
    colorFinish: json['color_finish'] as String?,
    year:        json['year']        as int?,
  );

  String get fullName => year != null ? '$brand $model ($year)' : '$brand $model';

  @override
  List<Object?> get props => [brand, model, generation, trim, year];
}

// ── Informations commerciales ─────────────────────────────────────

/// Partenaire source d'un véhicule (fournisseur / importateur).
class VehiclePartner {
  final int id;
  final String companyName;
  final String? contactName;
  final String phone;
  final String? whatsapp;

  const VehiclePartner({
    required this.id,
    required this.companyName,
    this.contactName,
    required this.phone,
    this.whatsapp,
  });

  factory VehiclePartner.fromJson(Map<String, dynamic> json) => VehiclePartner(
    id:          json['id']           as int,
    companyName: json['company_name'] as String,
    contactName: json['contact_name'] as String?,
    phone:       json['phone']        as String,
    whatsapp:    json['whatsapp']     as String?,
  );

  String get displayName => contactName != null ? '$companyName — $contactName' : companyName;
  String get callNumber  => whatsapp ?? phone;
}

class VehicleCommercial extends Equatable {
  final String condition;   // 'new' | 'used' | 'damaged'
  final String status;      // 'in_stock' | 'reserved' | 'sold' | 'rented'
  final String availability; // 'sale' | 'rent' | 'both'
  final double? salePrice;
  final double? rentalDailyRate;
  final double? rentalWeeklyRate;
  final double? rentalMonthlyRate;
  final double? rentalDeposit;
  final String currency;
  final bool priceNegotiable;
  final String? site;
  final int? locationId;
  final String? locationName;  // "Showroom Paspanga"
  final String? locationCity;  // "Ouagadougou"
  final VehiclePartner? partner; // partenaire source (staff)

  /// Mise en avant commerciale : `good_deal`, `flash_sale`, `clearance`.
  /// `null` signifie « pas de promotion ».
  final String? dealType;

  /// Libellé traduit du type, fourni par l'API pour éviter de dupliquer la
  /// traduction des trois valeurs côté application.
  final String? dealLabel;

  const VehicleCommercial({
    required this.condition,
    required this.status,
    required this.availability,
    this.salePrice,
    this.rentalDailyRate,
    this.rentalWeeklyRate,
    this.rentalMonthlyRate,
    this.rentalDeposit,
    required this.currency,
    required this.priceNegotiable,
    this.site,
    this.locationId,
    this.locationName,
    this.locationCity,
    this.partner,
    this.dealType,
    this.dealLabel,
  });

  bool get isForSale   => availability == 'sale' || availability == 'both';
  bool get isForRent   => availability == 'rent' || availability == 'both';
  bool get isInStock   => status == 'in_stock';
  bool get isDamaged   => condition == 'damaged';
  bool get isDeal      => dealType != null;

  factory VehicleCommercial.fromJson(Map<String, dynamic> json) => VehicleCommercial(
    condition:        json['condition']    as String,
    status:           json['status']       as String,
    availability:     json['availability'] as String,
    salePrice:        _dq(json['sale_price']),
    rentalDailyRate:  _dq(json['rental_daily_rate']),
    rentalWeeklyRate: _dq(json['rental_weekly_rate']),
    rentalMonthlyRate:_dq(json['rental_monthly_rate']),
    rentalDeposit:    _dq(json['rental_deposit']),
    currency:         json['currency']       as String? ?? 'XOF',
    priceNegotiable:  json['price_negotiable'] as bool? ?? false,
    site:             json['site'] as String?,
    locationId:       json['location_id'] as int?,
    locationName:     (json['location'] as Map<String, dynamic>?)?['name'] as String?,
    locationCity:     (json['location'] as Map<String, dynamic>?)?['city'] as String?,
    partner:          json['partner'] != null
                        ? VehiclePartner.fromJson(json['partner'] as Map<String, dynamic>)
                        : null,
    dealType:         json['deal_type']  as String?,
    dealLabel:        json['deal_label'] as String?,
  );

  /// Label de localisation affiché sur les cartes et fiches.
  String? get locationLabel {
    if (locationName != null && locationCity != null) return '$locationName — $locationCity';
    if (locationCity != null) return locationCity;
    return site; // fallback sur l'ancien champ texte libre
  }

  @override
  List<Object?> get props => [status, availability, salePrice, rentalDailyRate, locationId, partner?.id];
}

// ── Détails import ────────────────────────────────────────────────

class VehicleImport extends Equatable {
  final String? originCountry;
  final bool customsCleared;
  final String? portOfEntry;
  final String? steeringside; // 'left' | 'right'
  final int? odometerAtImportKm;

  const VehicleImport({
    this.originCountry,
    required this.customsCleared,
    this.portOfEntry,
    this.steeringside,
    this.odometerAtImportKm,
  });

  bool get isRightHandDrive => steeringside == 'right';

  factory VehicleImport.fromJson(Map<String, dynamic> json) => VehicleImport(
    originCountry:      json['origin_country']       as String?,
    customsCleared:     json['customs_cleared']      as bool? ?? false,
    portOfEntry:        json['port_of_entry']         as String?,
    steeringside:       json['steering_side']         as String?,
    odometerAtImportKm: json['odometer_at_import_km'] as int?,
  );

  @override
  List<Object?> get props => [originCountry, customsCleared];
}

/// La fourchette de consommation officielle d'un modèle.
///
/// Deux bornes plutôt qu'un chiffre : une annonce connaît son modèle, rarement
/// sa motorisation, et l'écart entre les moteurs d'un même modèle atteint
/// couramment un litre et demi aux cent. Annoncer une valeur unique
/// reviendrait à choisir un moteur au hasard pour le compte de l'acheteur.
class OfficialConsumption {
  final double min;
  final double max;

  /// Nombre de motorisations connues pour ce modèle et ce millésime.
  final int motorisations;

  final int modelYear;
  final String source;
  final String cycle;

  const OfficialConsumption({
    required this.min,
    required this.max,
    required this.motorisations,
    required this.modelYear,
    required this.source,
    required this.cycle,
  });

  static OfficialConsumption? depuisJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;

    final min = _asDouble(json['min']);
    final max = _asDouble(json['max']);
    if (min == null || max == null) return null;

    return OfficialConsumption(
      min:           min,
      max:           max,
      motorisations: _asInt(json['motorisations']) ?? 1,
      modelYear:     _asInt(json['model_year']) ?? 0,
      source:        json['source'] as String? ?? '',
      cycle:         json['cycle']  as String? ?? '',
    );
  }

  /// Vrai quand toutes les motorisations connues donnent la même valeur.
  bool get estUnique => (max - min).abs() < 0.05;

  /// « 8,2 l/100 km » ou « 8,2 à 9,4 l/100 km », en français.
  String get libelle {
    String n(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

    return estUnique ? '${n(min)} l/100 km' : '${n(min)} à ${n(max)} l/100 km';
  }
}
