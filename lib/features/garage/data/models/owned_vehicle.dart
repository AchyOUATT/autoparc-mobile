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

  /// Motorisation choisie par le propriétaire, et sa cote officielle.
  ///
  /// Nulle tant qu'il ne l'a pas choisie : le catalogue connaît le modèle,
  /// mais rien ne dit lequel des moteurs se trouve sous le capot. Une Camry
  /// 2013 consomme 8,2 ou 9,4 l/100 selon qu'elle a le 2,5 l quatre cylindres
  /// ou le 3,5 l V6.
  final int? motorisationId;
  final VehicleConsumption? consumption;

  /// Échéances d'entretien, de la plus urgente à la moins urgente.
  ///
  /// Calculées par le serveur, jamais ici : la tâche de rappel et l'affichage
  /// doivent s'appuyer sur exactement le même calcul, sinon l'application
  /// annoncera une date que la notification contredira.
  final List<VehicleDeadline> deadlines;

  /// Champs bruts, pour le formulaire de saisie.
  final DateTime? technicalInspectionExpiry;
  final DateTime? insuranceExpiry;
  final int? lastServiceMileageKm;
  final int? serviceIntervalKm;

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
    this.motorisationId,
    this.consumption,
    this.deadlines = const [],
    this.technicalInspectionExpiry,
    this.insuranceExpiry,
    this.lastServiceMileageKm,
    this.serviceIntervalKm,
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
    motorisationId:    json['motorisation_id']   as int?,
    consumption:       json['consumption'] == null
                           ? null
                           : VehicleConsumption.fromJson(
                               json['consumption'] as Map<String, dynamic>),
    deadlines:         (json['deadlines'] as List?)
                           ?.map((d) => VehicleDeadline.fromJson(d as Map<String, dynamic>))
                           .toList() ??
                       const [],
    technicalInspectionExpiry: _date(json['technical_inspection_expiry']),
    insuranceExpiry:           _date(json['insurance_expiry']),
    lastServiceMileageKm:      json['last_service_mileage_km'] as int?,
    serviceIntervalKm:         json['service_interval_km']     as int?,
  );

  @override
  List<Object?> get props => [id];

  /// Vrai si au moins une donnée technique est connue (moteur ou code moteur).
  bool get hasEngineData => engineCode != null || identity.engineType != null;

  /// Échéance la plus urgente, dépassée ou non. `null` si rien n'est suivi.
  VehicleDeadline? get nextDeadline =>
      deadlines.isEmpty ? null : deadlines.first;
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());

/// La cote de consommation officielle d'une motorisation.
///
/// Toujours accompagnée de sa provenance et de son cycle d'essai : la même
/// voiture se lit 8,2 l/100 selon la méthode canadienne et 6,4 selon la norme
/// européenne. Afficher le chiffre seul ferait passer deux protocoles pour une
/// contradiction.
class VehicleConsumption extends Equatable {
  /// La motorisation, telle que le propriétaire doit la reconnaître :
  /// « 2,5 l 4 cyl. boîte auto. 6 ».
  final String label;
  final String? fuel;
  final double? cityL100km;
  final double? highwayL100km;
  final double? combinedL100km;
  final String source;
  final String cycle;

  const VehicleConsumption({
    required this.label,
    this.fuel,
    this.cityL100km,
    this.highwayL100km,
    this.combinedL100km,
    required this.source,
    required this.cycle,
  });

  factory VehicleConsumption.fromJson(Map<String, dynamic> json) =>
      VehicleConsumption(
        label:          json['label']  as String? ?? '',
        fuel:           json['fuel']   as String?,
        cityL100km:     _double(json['city_l_100km']),
        highwayL100km:  _double(json['highway_l_100km']),
        combinedL100km: _double(json['combined_l_100km']),
        source:         json['source'] as String? ?? '',
        cycle:          json['cycle']  as String? ?? '',
      );

  @override
  List<Object?> get props => [label, combinedL100km, source, cycle];
}

/// Laravel sérialise les décimaux en chaînes : « 8.20 », pas 8.2.
double? _double(Object? value) =>
    value == null ? null : double.tryParse(value.toString());

/// Une échéance d'entretien : visite technique, assurance ou vidange.
class VehicleDeadline {
  /// `technical_inspection`, `insurance` ou `service`.
  final String kind;

  /// Libellé prêt à afficher, fourni par le serveur.
  final String label;

  /// Date d'expiration. Nulle pour la vidange, suivie au kilométrage.
  final DateTime? dueOn;

  /// Jours restants, négatif si dépassée. Nul pour la vidange.
  final int? daysLeft;

  final bool overdue;

  /// Précision libre, ex. « Dans 300 km ». Utilisée pour la vidange.
  final String? detail;

  const VehicleDeadline({
    required this.kind,
    required this.label,
    this.dueOn,
    this.daysLeft,
    required this.overdue,
    this.detail,
  });

  factory VehicleDeadline.fromJson(Map<String, dynamic> json) => VehicleDeadline(
    kind:     json['kind']   as String,
    label:    json['label']  as String,
    dueOn:    _date(json['due_on']),
    daysLeft: json['days_left'] as int?,
    overdue:  json['overdue'] as bool? ?? false,
    detail:   json['detail'] as String?,
  );

  /// Texte court résumant l'urgence, prêt pour une pastille.
  String get summary {
    if (detail != null) return detail!;
    if (daysLeft == null) return label;
    if (overdue) return 'Dépassée de ${daysLeft!.abs()} j';
    if (daysLeft == 0) return "Expire aujourd'hui";
    return 'Dans $daysLeft j';
  }
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
