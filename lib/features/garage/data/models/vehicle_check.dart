import 'package:equatable/equatable.dart';

/// Un point à vérifier, tel que le serveur l'a composé pour CE véhicule.
///
/// Rien ici n'est décidé par l'application, et c'est délibéré. La liste, les
/// raisons, l'état pré-rempli et la sévérité viennent du serveur — comme les
/// échéances. Un seuil recopié côté client finit toujours par contredire le
/// serveur, et l'utilisateur voit alors deux vérités pour une même voiture.
class CheckItem extends Equatable {
  final String code;
  final String category;
  final String categoryLabel;
  final String title;

  /// Où regarder, et ce qu'on risque. C'est la moitié de l'utilité d'un point :
  /// « vérifier les pneus » n'apprend rien, « le témoin d'usure est au fond des
  /// rainures » se lit une fois et se retient.
  final String? help;

  /// `blocking` ou `watch`. Ne sert qu'à l'affichage : c'est le serveur qui en
  /// tire le verdict.
  final String severity;

  /// Pourquoi ce point figure dans cette liste : « 190 000 km au compteur »,
  /// « Diesel », « Trajet de 360 km ». Vide pour les points du noyau, posés à
  /// tout véhicule.
  final List<String> reasons;

  /// L'état que le serveur propose déjà, quand il sait quelque chose : une
  /// assurance expirée, une vidange dépassée. Proposé, jamais imposé — une
  /// assurance peut avoir été renouvelée sans que personne ne l'ait saisi.
  final String? prefillStatus;
  final String? prefillReason;

  /// Catégorie de pièces à ouvrir si le point est en défaut. Nulle quand aucune
  /// catégorie ne correspond — « trace de fuite sous le véhicule » n'en désigne
  /// aucune.
  final int? partCategoryId;

  const CheckItem({
    required this.code,
    required this.category,
    required this.categoryLabel,
    required this.title,
    this.help,
    required this.severity,
    this.reasons = const [],
    this.prefillStatus,
    this.prefillReason,
    this.partCategoryId,
  });

  bool get estBloquant => severity == 'blocking';

  factory CheckItem.fromJson(Map<String, dynamic> json) => CheckItem(
    code:           json['code']           as String,
    category:       json['category']       as String,
    categoryLabel:  json['category_label'] as String? ?? '',
    title:          json['title']          as String,
    help:           json['help']           as String?,
    severity:       json['severity']       as String? ?? 'watch',
    reasons:        (json['reasons'] as List?)?.map((r) => r.toString()).toList() ?? const [],
    prefillStatus:  json['prefill_status'] as String?,
    prefillReason:  json['prefill_reason'] as String?,
    partCategoryId: json['part_category_id'] as int?,
  );

  @override
  List<Object?> get props => [code];
}

/// Un type de contrôle que le serveur propose aujourd'hui.
///
/// Le libellé du saisonnier dépend de la saison en cours, donc du calendrier —
/// qui reste côté serveur. Découpé des deux côtés, il finirait par ne plus
/// tomber au même mois, et l'application proposerait un contrôle d'hivernage
/// que le serveur composerait en saison sèche.
class CheckReasonOption {
  /// `trip` ou `seasonal`.
  final String value;
  final String label;
  final String hint;

  /// `pluies` ou `seche` pour un contrôle de saison, nul sinon.
  final String? season;

  const CheckReasonOption({
    required this.value,
    required this.label,
    required this.hint,
    this.season,
  });

  bool get estVoyage => value == 'trip';

  factory CheckReasonOption.fromJson(Map<String, dynamic> json) => CheckReasonOption(
    value:  json['value']  as String,
    label:  json['label']  as String? ?? '',
    hint:   json['hint']   as String? ?? '',
    season: json['season'] as String?,
  );
}

/// La liste composée, plus le kilométrage connu du véhicule.
class CheckTemplate {
  final String reason;

  /// Le titre de l'écran, rédigé par le serveur : « Avant de partir » ou
  /// « Contrôle d'hivernage » selon le motif et la saison.
  final String title;

  final int? tripDistanceKm;
  final int? mileageKm;
  final List<CheckItem> items;
  final List<CheckReasonOption> availableReasons;

  const CheckTemplate({
    this.reason = 'trip',
    this.title = 'Avant de partir',
    this.tripDistanceKm,
    this.mileageKm,
    required this.items,
    this.availableReasons = const [],
  });

  factory CheckTemplate.fromJson(Map<String, dynamic> json) => CheckTemplate(
    reason:         json['reason'] as String? ?? 'trip',
    title:          json['title']  as String? ?? 'Avant de partir',
    tripDistanceKm: json['trip_distance_km'] as int?,
    mileageKm:      json['mileage_km']       as int?,
    items: (json['items'] as List? ?? const [])
        .map((i) => CheckItem.fromJson(i as Map<String, dynamic>))
        .toList(),
    availableReasons: (json['available_reasons'] as List? ?? const [])
        .map((r) => CheckReasonOption.fromJson(r as Map<String, dynamic>))
        .toList(),
  );

  /// Les points groupés par catégorie, dans l'ordre où le serveur les a posés.
  ///
  /// L'ordre compte : les papiers d'abord, parce qu'à un contrôle de
  /// gendarmerie une attestation périmée ne se discute pas.
  Map<String, List<CheckItem>> get parCategorie {
    final groupes = <String, List<CheckItem>>{};
    for (final item in items) {
      groupes.putIfAbsent(item.categoryLabel, () => []).add(item);
    }
    return groupes;
  }
}

/// Le verdict d'un passage, rédigé par le serveur.
///
/// L'application ne le formule jamais elle-même : elle n'a rien constaté, elle a
/// posé des questions. « Rien à signaler sur les treize points vérifiés » est
/// vrai ; « votre véhicule est en bon état » ne l'est pas.
class CheckVerdict {
  /// `blocked`, `attention` ou `clear`.
  final String value;
  final String label;
  final String detail;

  const CheckVerdict({
    required this.value,
    required this.label,
    required this.detail,
  });

  bool get bloque => value == 'blocked';
  bool get sansSuite => value == 'clear';

  factory CheckVerdict.fromJson(Map<String, dynamic> json) => CheckVerdict(
    value:  json['value']  as String? ?? 'attention',
    label:  json['label']  as String? ?? '',
    detail: json['detail'] as String? ?? '',
  );
}

/// Un point à reprendre après un contrôle, avec de quoi agir.
class CheckPointToFix {
  final String itemCode;
  final String title;
  final String categoryLabel;
  final String? help;
  final String? note;

  /// Vrai pour un défaut sur un point jugé bloquant : c'est ce qui interdit le
  /// départ, par opposition à ce qui peut attendre le retour.
  final bool blocking;

  final int? partCategoryId;

  const CheckPointToFix({
    required this.itemCode,
    required this.title,
    required this.categoryLabel,
    this.help,
    this.note,
    required this.blocking,
    this.partCategoryId,
  });

  factory CheckPointToFix.fromJson(Map<String, dynamic> json) => CheckPointToFix(
    itemCode:       json['item_code']      as String,
    title:          json['title']          as String,
    categoryLabel:  json['category_label'] as String? ?? '',
    help:           json['help']           as String?,
    note:           json['note']           as String?,
    blocking:       json['blocking']       as bool? ?? false,
    partCategoryId: json['part_category_id'] as int?,
  );
}

/// Un passage enregistré.
class VehicleCheck {
  final int id;
  final int ownedVehicleId;
  final int? tripDistanceKm;
  final int? mileageKm;
  final DateTime? performedAt;
  final CheckVerdict verdict;
  final int blockingCount;
  final int watchCount;
  final int checkedCount;
  final List<CheckPointToFix> toFix;

  const VehicleCheck({
    required this.id,
    required this.ownedVehicleId,
    this.tripDistanceKm,
    this.mileageKm,
    this.performedAt,
    required this.verdict,
    required this.blockingCount,
    required this.watchCount,
    required this.checkedCount,
    this.toFix = const [],
  });

  factory VehicleCheck.fromJson(Map<String, dynamic> json) {
    final counts = json['counts'] as Map<String, dynamic>? ?? const {};

    return VehicleCheck(
      id:             json['id']               as int,
      ownedVehicleId: json['owned_vehicle_id'] as int,
      tripDistanceKm: json['trip_distance_km'] as int?,
      mileageKm:      json['mileage_km']       as int?,
      performedAt:    json['performed_at'] == null
                          ? null
                          : DateTime.tryParse(json['performed_at'].toString()),
      verdict: CheckVerdict.fromJson(
          json['verdict'] as Map<String, dynamic>? ?? const {}),
      blockingCount: counts['blocking'] as int? ?? 0,
      watchCount:    counts['watch']    as int? ?? 0,
      checkedCount:  counts['checked']  as int? ?? 0,
      toFix: (json['to_fix'] as List? ?? const [])
          .map((p) => CheckPointToFix.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Ce que la fiche du garage affiche entre deux contrôles.
  List<CheckPointToFix> get bloquants =>
      toFix.where((p) => p.blocking).toList();
}

/// Le résumé du dernier contrôle, tel que la fiche du véhicule le porte.
///
/// Trois nombres et une date : c'est l'écran de contrôle qui dit lesquels.
class LastCheck extends Equatable {
  final int id;
  final DateTime? performedAt;
  final String verdict;
  final String verdictLabel;
  final int blockingCount;
  final int watchCount;

  const LastCheck({
    required this.id,
    this.performedAt,
    required this.verdict,
    required this.verdictLabel,
    required this.blockingCount,
    required this.watchCount,
  });

  bool get bloque => verdict == 'blocked';
  int get aReprendre => blockingCount + watchCount;

  factory LastCheck.fromJson(Map<String, dynamic> json) => LastCheck(
    id:             json['id']             as int,
    performedAt:    json['performed_at'] == null
                        ? null
                        : DateTime.tryParse(json['performed_at'].toString()),
    verdict:        json['verdict']        as String? ?? 'attention',
    verdictLabel:   json['verdict_label']  as String? ?? '',
    blockingCount:  json['blocking_count'] as int? ?? 0,
    watchCount:     json['watch_count']    as int? ?? 0,
  );

  @override
  List<Object?> get props => [id, verdict, blockingCount, watchCount];
}
