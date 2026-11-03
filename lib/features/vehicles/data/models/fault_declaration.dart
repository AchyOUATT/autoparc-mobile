/// Seller-declared condition, separate from a physical AutoParc inspection.
/// No Flutter or networking dependency: resources and forms share this DTO.
class FaultDeclaration {
  final String state;
  final DateTime? declaredAt;
  final List<DeclaredVehicleFault> faults;
  final int unresolvedCount;

  const FaultDeclaration.unknown()
    : state = 'unknown',
      declaredAt = null,
      faults = const [],
      unresolvedCount = 0;

  FaultDeclaration({
    this.state = 'unknown',
    this.declaredAt,
    List<DeclaredVehicleFault> faults = const [],
    int? unresolvedCount,
  }) : faults = List.unmodifiable(faults),
       unresolvedCount = _unresolvedCount(faults, unresolvedCount);

  /// Missing legacy data stays unknown. A list's emptiness never means that
  /// the seller affirmatively declared the absence of faults.
  factory FaultDeclaration.fromJson(Object? value) {
    if (value is! Map) return const FaultDeclaration.unknown();
    final state = value['state'];
    final rows = value['faults'];
    if (!const ['unknown', 'none', 'has_faults'].contains(state) ||
        rows is! List) {
      return const FaultDeclaration.unknown();
    }
    try {
      final faults = rows
          .map((row) {
            if (row is! Map) {
              throw const FormatException('Invalid declared fault');
            }
            return DeclaredVehicleFault.fromJson(
              Map<String, dynamic>.from(row),
            );
          })
          .toList(growable: false);
      final rawDate = value['declared_at'];
      final count = _integer(value['unresolved_count']);
      // Even inconsistent metadata cannot erase existing fault rows or create
      // an affirmative "none" declaration. Editing may need to resolve it.
      final safeState =
          state == 'none' && (faults.isNotEmpty || (count ?? 0) > 0)
          ? 'unknown'
          : state as String;
      return FaultDeclaration(
        state: safeState,
        declaredAt: rawDate is String ? DateTime.tryParse(rawDate) : null,
        faults: faults,
        unresolvedCount: count != null && count >= 0 ? count : null,
      );
    } on Object {
      return const FaultDeclaration.unknown();
    }
  }

  bool get canSubmit => switch (state) {
    'none' => faults.isEmpty && unresolvedCount == 0,
    'has_faults' =>
      faults.isNotEmpty &&
          faults.length <= 100 &&
          faults
              .where((fault) => fault.editable)
              .every((fault) => fault.isValid),
    _ => false,
  };

  bool get hasReadOnlyFaults => faults.any((fault) => !fault.editable);

  FaultDeclaration copyWith({
    String? state,
    List<DeclaredVehicleFault>? faults,
  }) => FaultDeclaration(
    state: state ?? this.state,
    declaredAt: declaredAt,
    faults: faults ?? this.faults,
    unresolvedCount: faults == null ? unresolvedCount : null,
  );

  /// Dates, authorship, edit permissions and inspection claims are server-owned.
  /// Partner payloads omit staff-owned rows; the server retains those rows.
  Map<String, dynamic> toPayload() => {
    'fault_declaration_state': state,
    'faults': faults
        .where((fault) => fault.editable)
        .map((fault) => fault.toJson())
        .toList(growable: false),
  };
}

class DeclaredVehicleFault {
  static const categories = [
    'engine',
    'transmission',
    'electrical',
    'braking',
    'suspension',
    'steering',
    'cooling',
    'air_conditioning',
    'bodywork',
    'interior',
    'electronics',
    'tyres',
    'other',
  ];
  static const severities = ['minor', 'moderate', 'major', 'critical'];
  static const privateStatuses = ['declared', 'repaired', 'wont_fix'];
  static const staffStatuses = [
    'declared',
    'diagnosed',
    'quoted',
    'repairing',
    'repaired',
    'wont_fix',
  ];

  final int? id;
  final String category;
  final String title;
  final String? description;
  final String severity;
  final String status;
  final bool isOpen;
  final bool affectsDrivability;
  final bool isSafetyCritical;
  final bool disclosedToBuyer;
  final bool editable;

  const DeclaredVehicleFault({
    this.id,
    required this.category,
    required this.title,
    this.description,
    this.severity = 'minor',
    this.status = 'declared',
    bool? isOpen,
    this.affectsDrivability = false,
    this.isSafetyCritical = false,
    this.disclosedToBuyer = true,
    this.editable = true,
  }) : isOpen = isOpen ?? (status != 'repaired' && status != 'wont_fix');

  factory DeclaredVehicleFault.fromJson(Map<String, dynamic> json) {
    if (json['category'] is! String ||
        json['title'] is! String ||
        json['severity'] is! String ||
        json['status'] is! String) {
      throw const FormatException('Invalid declared fault');
    }
    return DeclaredVehicleFault(
      id: _integer(json['id']),
      category: json['category'] as String,
      title: json['title'] as String,
      description: json['description'] is String
          ? json['description'] as String
          : null,
      severity: json['severity'] as String,
      status: json['status'] as String,
      isOpen: json['is_open'] is bool ? json['is_open'] as bool : null,
      affectsDrivability: json['affects_drivability'] == true,
      isSafetyCritical: json['is_safety_critical'] == true,
      disclosedToBuyer: json['disclosed_to_buyer'] != false,
      editable: json['editable'] != false,
    );
  }

  /// Maintenance can be closed without a repair (wont_fix). The public filter
  /// means "unrepaired", so it must never rely on isOpen.
  bool get isUnresolved => status != 'repaired';

  bool get isValid =>
      categories.contains(category) &&
      severities.contains(severity) &&
      staffStatuses.contains(status) &&
      title.trim().isNotEmpty &&
      title.runes.length <= 180 &&
      (description?.runes.length ?? 0) <= 5000;

  DeclaredVehicleFault copyWith({
    String? category,
    String? title,
    String? description,
    String? severity,
    String? status,
    bool? affectsDrivability,
    bool? isSafetyCritical,
    bool? disclosedToBuyer,
  }) => DeclaredVehicleFault(
    id: id,
    category: category ?? this.category,
    title: title ?? this.title,
    description: description ?? this.description,
    severity: severity ?? this.severity,
    status: status ?? this.status,
    affectsDrivability: affectsDrivability ?? this.affectsDrivability,
    isSafetyCritical: isSafetyCritical ?? this.isSafetyCritical,
    disclosedToBuyer: disclosedToBuyer ?? this.disclosedToBuyer,
    editable: editable,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'category': category,
    'title': title.trim(),
    'description': description?.trim().isNotEmpty == true
        ? description!.trim()
        : null,
    'severity': severity,
    'status': status,
    'affects_drivability': affectsDrivability,
    'is_safety_critical': isSafetyCritical,
    'disclosed_to_buyer': disclosedToBuyer,
  };
}

int? _integer(Object? value) => value is int
    ? value
    : value is String
    ? int.tryParse(value)
    : null;

int _unresolvedCount(List<DeclaredVehicleFault> faults, int? count) {
  final visible = faults.where((fault) => fault.isUnresolved).length;
  return count != null && count > visible ? count : visible;
}
