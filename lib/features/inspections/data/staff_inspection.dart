/// A staff inspection is independent of listing moderation and garage checks.
/// These DTOs deliberately have no Flutter, authentication or HTTP dependency.
class StaffInspectionSummary {
  final int id;
  final DateTime inspectedAt;
  final int mileageKm;
  final String result;
  final int checkedCount;
  final int attentionCount;
  final int blockingCount;
  final DateTime? validUntil;

  const StaffInspectionSummary({
    required this.id,
    required this.inspectedAt,
    required this.mileageKm,
    required this.result,
    required this.checkedCount,
    required this.attentionCount,
    required this.blockingCount,
    this.validUntil,
  });

  factory StaffInspectionSummary.fromJson(Map<String, dynamic> json) {
    final id = _integer(json['id']);
    final date = _date(json['inspected_at']);
    final mileage = _integer(json['mileage_km']);
    final checked = _integer(json['checked_count']);
    final attention = _integer(json['attention_count']);
    final blocking = _integer(json['blocking_count']);
    final result = json['result'];
    final until = _date(json['valid_until']);
    if (id == null ||
        id <= 0 ||
        date == null ||
        mileage == null ||
        mileage < 0 ||
        checked == null ||
        checked < 1 ||
        attention == null ||
        attention < 0 ||
        blocking == null ||
        blocking < 0 ||
        attention + blocking > checked ||
        !const ['clear', 'attention', 'blocked'].contains(result) ||
        (json['valid_until'] != null && until == null) ||
        (until != null && !until.isAfter(date)) ||
        (result == 'clear' && (attention > 0 || blocking > 0)) ||
        (result == 'attention' && (attention == 0 || blocking > 0)) ||
        (result == 'blocked' && blocking == 0)) {
      throw const FormatException('Invalid staff inspection summary');
    }
    return StaffInspectionSummary(
      id: id,
      inspectedAt: date,
      mileageKm: mileage,
      result: result as String,
      checkedCount: checked,
      attentionCount: attention,
      blockingCount: blocking,
      validUntil: until,
    );
  }

  /// Fail closed: an absent or malformed response must never create a badge.
  static StaffInspectionSummary? parse(Object? value) {
    final json = _map(value);
    if (json == null) return null;
    try {
      return StaffInspectionSummary.fromJson(json);
    } on FormatException {
      return null;
    }
  }

  bool get hasFindings => attentionCount > 0 || blockingCount > 0;

  bool isCurrent([DateTime? now]) =>
      validUntil == null || validUntil!.isAfter(now ?? DateTime.now());
}

class StaffInspectionItem {
  static const statuses = ['ok', 'attention', 'blocking', 'not_checked'];
  final String label;
  final String status;
  final String? note;

  const StaffInspectionItem({
    required this.label,
    required this.status,
    this.note,
  });

  factory StaffInspectionItem.fromJson(Map<String, dynamic> json) {
    final label = json['label'];
    final status = json['status'];
    if (label is! String ||
        label.trim().isEmpty ||
        !statuses.contains(status)) {
      throw const FormatException('Invalid staff inspection item');
    }
    return StaffInspectionItem(
      label: label,
      status: status as String,
      note: json['note'] is String ? json['note'] as String : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label.trim(),
    'status': status,
    if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
  };
}

class StaffInspectionReport {
  final StaffInspectionSummary inspection;
  final String source;
  final int sourceId;
  final String summary;
  final List<StaffInspectionItem> items;

  /// Present on staff history; public reports may omit it.
  final String state;
  final String? withdrawalReason;

  const StaffInspectionReport({
    required this.inspection,
    required this.source,
    required this.sourceId,
    required this.summary,
    required this.items,
    this.state = 'active',
    this.withdrawalReason,
  });

  /// `outdated` remains active in storage, but no longer earns a public badge.
  /// Staff can still explicitly withdraw this historical record.
  bool get canWithdraw => const ['active', 'outdated'].contains(state);

  factory StaffInspectionReport.fromJson(Map<String, dynamic> json) {
    final source = json['source'];
    final sourceId = _integer(json['source_id']);
    final summary = json['summary'];
    final rawItems = json['items'];
    if (!const ['vehicle', 'private_listing'].contains(source) ||
        sourceId == null ||
        sourceId <= 0 ||
        summary is! String ||
        rawItems is! List ||
        rawItems.isEmpty) {
      throw const FormatException('Invalid staff inspection report');
    }
    final items = rawItems
        .map((item) {
          final map = _map(item);
          if (map == null) {
            throw const FormatException('Invalid inspection item');
          }
          return StaffInspectionItem.fromJson(map);
        })
        .toList(growable: false);
    final inspection = StaffInspectionSummary.fromJson(json);
    // A partial/corrupt report must not hide findings behind a clear summary.
    if (items.where((item) => item.status != 'not_checked').length !=
            inspection.checkedCount ||
        items.where((item) => item.status == 'attention').length !=
            inspection.attentionCount ||
        items.where((item) => item.status == 'blocking').length !=
            inspection.blockingCount) {
      throw const FormatException('Inconsistent inspection findings');
    }
    return StaffInspectionReport(
      inspection: inspection,
      source: source as String,
      sourceId: sourceId,
      summary: summary,
      items: List.unmodifiable(items),
      state: json['state'] is String ? json['state'] as String : 'active',
      withdrawalReason: json['withdrawal_reason'] is String
          ? json['withdrawal_reason'] as String
          : null,
    );
  }
}

int? _integer(Object? value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

Map<String, dynamic>? _map(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) return null;
  return Map<String, dynamic>.from(value);
}
