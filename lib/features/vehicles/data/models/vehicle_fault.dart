// ── Enums miroirs des enums PHP ──────────────────────────────────────

const faultCategories = [
  (value: 'engine',           label: 'Moteur',            icon: 0xe1d5), // Icons.settings
  (value: 'transmission',     label: 'Transmission',      icon: 0xe1b6), // Icons.sync_alt
  (value: 'electrical',       label: 'Électricité',       icon: 0xe24d), // Icons.bolt
  (value: 'braking',          label: 'Freinage',          icon: 0xe1c5), // Icons.stop_circle_outlined → warning
  (value: 'suspension',       label: 'Suspension',        icon: 0xe3e1), // Icons.filter_tilt_shift
  (value: 'steering',         label: 'Direction',         icon: 0xe52f), // Icons.turn_slight_right
  (value: 'cooling',          label: 'Refroidissement',   icon: 0xe24a), // Icons.ac_unit
  (value: 'air_conditioning', label: 'Climatisation',     icon: 0xe1f8), // Icons.thermostat
  (value: 'bodywork',         label: 'Carrosserie',       icon: 0xe59f), // Icons.directions_car
  (value: 'interior',         label: 'Intérieur',         icon: 0xe403), // Icons.weekend
  (value: 'electronics',      label: 'Électronique',      icon: 0xe1e0), // Icons.memory
  (value: 'tyres',            label: 'Pneumatiques',      icon: 0xe3e1), // Icons.circle_outlined
  (value: 'other',            label: 'Autre',             icon: 0xe88f), // Icons.help_outline
];

const faultSeverities = [
  (value: 'minor',    label: 'Mineur',   color: 0xFF4CAF50), // vert
  (value: 'moderate', label: 'Modéré',   color: 0xFFFFA000), // orange
  (value: 'major',    label: 'Majeur',   color: 0xFFE65100), // orange foncé
  (value: 'critical', label: 'Critique', color: 0xFFB71C1C), // rouge
];

const faultStatuses = [
  (value: 'declared',   label: 'Déclaré'),
  (value: 'diagnosed',  label: 'Diagnostiqué'),
  (value: 'quoted',     label: 'Devisé'),
  (value: 'repairing',  label: 'En réparation'),
  (value: 'repaired',   label: 'Réparé'),
  (value: 'wont_fix',   label: 'Sans suite'),
];

// ── Modèle ────────────────────────────────────────────────────────────

class VehicleFault {
  final int    id;
  final String category;
  final String title;
  final String severity;
  final String status;
  final String? code;
  final String? description;
  final bool   affectsDrivability;
  final bool   isSafetyCritical;
  final bool   disclosedToBuyer;
  final DateTime? detectedAt;
  final int?   mileageAtDetectionKm;
  final String? reportedBy;
  final double? estimatedRepairCost;
  final double? actualRepairCost;
  final DateTime? repairedAt;

  const VehicleFault({
    required this.id,
    required this.category,
    required this.title,
    required this.severity,
    required this.status,
    this.code,
    this.description,
    required this.affectsDrivability,
    required this.isSafetyCritical,
    required this.disclosedToBuyer,
    this.detectedAt,
    this.mileageAtDetectionKm,
    this.reportedBy,
    this.estimatedRepairCost,
    this.actualRepairCost,
    this.repairedAt,
  });

  factory VehicleFault.fromJson(Map<String, dynamic> j) => VehicleFault(
    id:                   j['id'] as int,
    category:             j['category'] as String,
    title:                j['title'] as String,
    severity:             j['severity'] as String,
    status:               j['status'] as String,
    code:                 j['code'] as String?,
    description:          j['description'] as String?,
    affectsDrivability:   (j['affects_drivability'] as bool?) ?? false,
    isSafetyCritical:     (j['is_safety_critical'] as bool?) ?? false,
    disclosedToBuyer:     (j['disclosed_to_buyer'] as bool?) ?? false,
    detectedAt:           j['detected_at'] != null
        ? DateTime.tryParse(j['detected_at'] as String) : null,
    mileageAtDetectionKm: j['mileage_at_detection_km'] as int?,
    reportedBy:           j['reported_by'] as String?,
    estimatedRepairCost:  (j['estimated_repair_cost'] as num?)?.toDouble(),
    actualRepairCost:     (j['actual_repair_cost'] as num?)?.toDouble(),
    repairedAt:           j['repaired_at'] != null
        ? DateTime.tryParse(j['repaired_at'] as String) : null,
  );

  // ── Helpers ──────────────────────────────────────────────────────

  bool get isOpen =>
      status != 'repaired' && status != 'wont_fix';

  String get categoryLabel =>
      faultCategories.firstWhere(
        (c) => c.value == category,
        orElse: () => (value: category, label: category, icon: 0xe88f),
      ).label;

  String get severityLabel =>
      faultSeverities.firstWhere(
        (s) => s.value == severity,
        orElse: () => (value: severity, label: severity, color: 0xFF9E9E9E),
      ).label;

  int get severityColor =>
      faultSeverities.firstWhere(
        (s) => s.value == severity,
        orElse: () => (value: severity, label: severity, color: 0xFF9E9E9E),
      ).color;

  String get statusLabel =>
      faultStatuses.firstWhere(
        (s) => s.value == status,
        orElse: () => (value: status, label: status),
      ).label;
}
