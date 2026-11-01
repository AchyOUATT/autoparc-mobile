import 'package:equatable/equatable.dart';

import 'fuel_fill.dart';
import 'vehicle_check.dart';

class OwnedVehicle extends Equatable {
  final int id;
  final String designation;
  final String? nickname;
  final int brandId;
  final int? trimId;
  final int? engineTypeId;
  final int? drivetrainId;
  final int? colorId;

  /// Le modèle du catalogue, quand il y était.
  ///
  /// Nul pour un véhicule dont le modèle a été tapé à la main — le référentiel
  /// est bâti sur les flux d'occasion européens, et le parc vient aussi des
  /// États-Unis, du Golfe et du Japon. `null as int` levait une exception sur
  /// la liste entière du garage : un seul véhicule au modèle libre rendait
  /// l'écran inutilisable.
  final int? vehicleModelId;

  /// Le modèle tel que le propriétaire l'a tapé, faute de l'avoir trouvé.
  final String? modelLibre;
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

  /// La consommation réellement mesurée aux passages à la pompe, à côté de la
  /// cote d'homologation que porte [consumption]. Les deux ne se remplacent
  /// pas : l'une est le chiffre du laboratoire, l'autre celui de la piste.
  ///
  /// Nulle quand la réponse ne porte pas la clé — un serveur pas encore
  /// déployé. Le serveur à jour la rend toujours, compteurs à zéro quand
  /// aucun passage n'a été saisi : c'est ainsi que l'écran distingue « aucun
  /// passage » de « pas demandé », et `null` doit rester réservé au second.
  final FuelTracking? fuelTracking;

  /// Le dernier contrôle avant voyage, en résumé. Nul tant qu'aucun n'a été
  /// fait : la fiche propose alors d'en faire un, plutôt que d'afficher un
  /// état qu'elle ne connaît pas.
  final LastCheck? lastCheck;

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
    this.trimId,
    this.engineTypeId,
    this.drivetrainId,
    this.colorId,
    this.vehicleModelId,
    this.modelLibre,
    this.vin,
    this.engineCode,
    this.plateNumber,
    this.mileageKm,
    required this.year,
    required this.identity,
    required this.compatibilityReady,
    this.motorisationId,
    this.consumption,
    this.fuelTracking,
    this.lastCheck,
    this.deadlines = const [],
    this.technicalInspectionExpiry,
    this.insuranceExpiry,
    this.lastServiceMileageKm,
    this.serviceIntervalKm,
  });

  /// Nom affiché : le surnom en priorité, sinon la désignation complète.
  String get displayName =>
      nickname?.isNotEmpty == true ? nickname! : designation;

  factory OwnedVehicle.fromJson(Map<String, dynamic> json) => OwnedVehicle(
    id: json['id'] as int,
    designation: json['designation'] as String,
    nickname: json['nickname'] as String?,
    brandId: json['brand_id'] as int,
    trimId: json['trim_id'] as int?,
    engineTypeId: json['engine_type_id'] as int?,
    drivetrainId: json['drivetrain_id'] as int?,
    colorId: json['color_id'] as int?,
    vehicleModelId: json['vehicle_model_id'] as int?,
    modelLibre: json['model_libre'] as String?,
    vin: json['vin'] as String?,
    engineCode: json['engine_code'] as String?,
    plateNumber: json['plate_number'] as String?,
    mileageKm: json['mileage_km'] as int?,
    year: json['year'] as int,
    identity: OwnedVehicleIdentity.fromJson(
      json['identity'] as Map<String, dynamic>,
    ),
    compatibilityReady: json['compatibility_ready'] as bool? ?? false,
    motorisationId: json['motorisation_id'] as int?,
    consumption: json['consumption'] == null
        ? null
        : VehicleConsumption.fromJson(
            json['consumption'] as Map<String, dynamic>,
          ),
    fuelTracking: json['fuel_tracking'] == null
        ? null
        : FuelTracking.fromJson(json['fuel_tracking'] as Map<String, dynamic>),
    lastCheck: json['last_check'] == null
        ? null
        : LastCheck.fromJson(json['last_check'] as Map<String, dynamic>),
    deadlines:
        (json['deadlines'] as List?)
            ?.map((d) => VehicleDeadline.fromJson(d as Map<String, dynamic>))
            .toList() ??
        const [],
    technicalInspectionExpiry: _date(json['technical_inspection_expiry']),
    insuranceExpiry: _date(json['insurance_expiry']),
    lastServiceMileageKm: json['last_service_mileage_km'] as int?,
    serviceIntervalKm: json['service_interval_km'] as int?,
  );

  @override
  List<Object?> get props => [id];

  /// Vrai si au moins une donnée technique est connue (moteur ou code moteur).
  ///
  /// Un modèle hors catalogue l'emporte sur tout le reste : les compatibilités
  /// sont déclarées par modèle, et aucune ne peut correspondre. Répondre vrai
  /// ferait passer un « on ne sait pas » pour un résultat.
  bool get hasEngineData =>
      vehicleModelId != null &&
      (engineCode != null || identity.engineType != null);

  /// Vrai quand le modèle a été tapé à la main : la recherche de pièces
  /// compatibles est indisponible pour ce véhicule, et rien ne la débloquera
  /// tant que le modèle n'est pas entré au catalogue.
  bool get modeleHorsCatalogue => vehicleModelId == null;

  /// Échéance la plus urgente, dépassée ou non. `null` si rien n'est suivi.
  VehicleDeadline? get nextDeadline =>
      deadlines.isEmpty ? null : deadlines.first;
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());

/// Une référence de consommation avec son domaine d'applicabilité.
///
/// La valeur source reste consultable même lorsqu'elle ne peut pas être
/// attribuée au véhicule. Une sélection ne vaut pas vérification documentaire.
class VehicleConsumption extends Equatable {
  final String label;
  final String? sourceModel;
  final double? powerKw;
  final String? hybridType;
  final String? fuel;
  final double? cityL100km;
  final double? highwayL100km;
  final double? combinedL100km;
  final double? referenceCityL100km;
  final double? referenceHighwayL100km;
  final double? referenceCombinedL100km;
  final String source;
  final String cycle;
  final String matchLevel;
  final List<String> matchReasons;
  final int? modelYear;
  final int? requestedYear;
  final String yearKind;
  final String? market;
  final String method;
  final String referenceStatus;
  final String? verifiedAt;
  final Map<String, dynamic> provenance;

  const VehicleConsumption({
    required this.label,
    this.sourceModel,
    this.powerKw,
    this.hybridType,
    this.fuel,
    this.cityL100km,
    this.highwayL100km,
    this.combinedL100km,
    this.referenceCityL100km,
    this.referenceHighwayL100km,
    this.referenceCombinedL100km,
    required this.source,
    required this.cycle,
    this.matchLevel = 'incomplete',
    this.matchReasons = const [],
    this.modelYear,
    this.requestedYear,
    this.yearKind = 'unknown',
    this.market,
    this.method = 'unknown',
    this.referenceStatus = 'legacy',
    this.verifiedAt,
    this.provenance = const {},
  });

  factory VehicleConsumption.fromJson(Map<String, dynamic> json) {
    final match = json['match'] is Map<String, dynamic>
        ? json['match'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final level = match['level'];
    return VehicleConsumption(
      label: json['label'] as String? ?? '',
      sourceModel: json['model_raw'] as String?,
      powerKw: _double(json['power_kw']),
      hybridType: json['hybrid_type'] as String?,
      fuel: json['fuel'] as String?,
      cityL100km: _double(json['city_l_100km']),
      highwayL100km: _double(json['highway_l_100km']),
      combinedL100km: _double(json['combined_l_100km']),
      // Older responses only carry the source number. It remains available
      // in details, without becoming a verified vehicle reference.
      referenceCityL100km: _double(
        json['reference_city_l_100km'] ?? json['city_l_100km'],
      ),
      referenceHighwayL100km: _double(
        json['reference_highway_l_100km'] ?? json['highway_l_100km'],
      ),
      referenceCombinedL100km: _double(
        json['reference_combined_l_100km'] ?? json['combined_l_100km'],
      ),
      source: json['source'] as String? ?? '',
      cycle: json['cycle'] as String? ?? '',
      matchLevel:
          const ['corresponding', 'approximate', 'incomplete'].contains(level)
          ? level as String
          : 'incomplete',
      matchReasons:
          (match['reasons'] as List?)?.whereType<String>().toList() ?? const [],
      modelYear: _consumptionInt(json['model_year']),
      requestedYear: _consumptionInt(json['requested_year']),
      yearKind: json['year_kind'] as String? ?? 'unknown',
      market: json['market'] as String?,
      method: json['method'] as String? ?? 'unknown',
      referenceStatus: json['reference_status'] as String? ?? 'legacy',
      verifiedAt: json['verified_at'] as String?,
      provenance: json['provenance'] is Map<String, dynamic>
          ? json['provenance'] as Map<String, dynamic>
          : const {},
    );
  }

  /// An unknown/legacy server cannot silently promote a source value.
  double? get primaryCombinedL100km =>
      matchLevel == 'corresponding' && referenceStatus == 'documented'
      ? combinedL100km
      : null;

  double? get sourceCombinedL100km => referenceCombinedL100km ?? combinedL100km;

  /// Open only web URLs with a real host, never an executable URI or userinfo.
  Uri? get sourceUri {
    for (final field in ['document_url', 'resource_url', 'source_url', 'url']) {
      final value = provenance[field];
      if (value is! String) continue;
      final uri = Uri.tryParse(value);
      if (uri != null &&
          const ['https', 'http'].contains(uri.scheme) &&
          uri.host.isNotEmpty &&
          uri.userInfo.isEmpty) {
        return uri;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [
    label,
    sourceModel,
    powerKw,
    hybridType,
    fuel,
    cityL100km,
    highwayL100km,
    combinedL100km,
    referenceCityL100km,
    referenceHighwayL100km,
    referenceCombinedL100km,
    source,
    cycle,
    matchLevel,
    matchReasons,
    modelYear,
    requestedYear,
    yearKind,
    market,
    method,
    referenceStatus,
    verifiedAt,
    provenance,
  ];
}

int? _consumptionInt(Object? value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '');

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

  factory VehicleDeadline.fromJson(Map<String, dynamic> json) =>
      VehicleDeadline(
        kind: json['kind'] as String,
        label: json['label'] as String,
        dueOn: _date(json['due_on']),
        daysLeft: json['days_left'] as int?,
        overdue: json['overdue'] as bool? ?? false,
        detail: json['detail'] as String?,
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

  /// Slug de la marque, tel que l'API le renvoie — il nomme le fichier de logo.
  ///
  /// Fourni par le serveur plutôt que dérivé du nom : une dérivation locale
  /// transformait « Citroën » en « citro-n » et faisait disparaître son logo.
  final String? brandSlug;

  final String? model;
  final String? trim;
  final String? engineType;
  final String? drivetrain;
  final String? color;

  const OwnedVehicleIdentity({
    this.brand,
    this.brandSlug,
    this.model,
    this.trim,
    this.engineType,
    this.drivetrain,
    this.color,
  });

  factory OwnedVehicleIdentity.fromJson(Map<String, dynamic> json) =>
      OwnedVehicleIdentity(
        brand: json['brand'] as String?,
        brandSlug: json['brand_slug'] as String?,
        model: json['model'] as String?,
        trim: json['trim'] as String?,
        engineType: json['engine_type'] as String?,
        drivetrain: json['drivetrain'] as String?,
        color: json['color'] as String?,
      );

  String get fullName {
    final parts = [brand, model, trim].whereType<String>().toList();
    return parts.isEmpty ? '—' : parts.join(' ');
  }

  @override
  List<Object?> get props => [brand, model, trim];
}
