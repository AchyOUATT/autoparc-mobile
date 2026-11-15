import 'package:intl/intl.dart';

/// Public buyer-facing range. Never confused with staff `estimated_repair_cost`.
class RepairEstimate {
  static const currency = 'XOF';
  static const sources = ['seller', 'workshop', 'autoparc'];
  static const necessities = ['necessary', 'optional'];

  final int costMin;
  final int costMax;
  final String source;
  final DateTime estimatedAt;
  final bool isStale;

  const RepairEstimate({
    required this.costMin,
    required this.costMax,
    required this.source,
    required this.estimatedAt,
    this.isStale = false,
  });

  factory RepairEstimate.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Invalid repair estimate');
    }
    final min = _integer(value['cost_min']);
    final max = _integer(value['cost_max']);
    final source = value['source'];
    final rawDate = value['estimated_at'];
    if (min == null ||
        max == null ||
        min < 0 ||
        min > max ||
        source is! String ||
        !sources.contains(source) ||
        rawDate is! String) {
      throw const FormatException('Invalid repair estimate');
    }
    final date = DateTime.tryParse(rawDate);
    if (date == null) {
      throw const FormatException('Invalid repair estimate');
    }
    return RepairEstimate(
      costMin: min,
      costMax: max,
      source: source,
      estimatedAt: date,
      isStale: value['is_stale'] == true || _isStale(date),
    );
  }

  bool get isValid =>
      costMin >= 0 && costMax >= costMin && sources.contains(source);

  Map<String, dynamic> toJson() => {
    'cost_min': costMin,
    'cost_max': costMax,
    'source': source,
    'estimated_at': DateFormat('yyyy-MM-dd').format(estimatedAt),
  };

  static bool _isStale(DateTime date, [DateTime? today]) {
    final now = today ?? DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final anniversary = DateTime(date.year, date.month + 6, date.day);
    return !anniversary.isAfter(start);
  }
}

class RepairBudget {
  final String status;
  final int? costMin;
  final int? costMax;
  final int estimatedCount;
  final int unestimatedCount;
  final List<RepairBudgetOptional> optional;

  const RepairBudget({
    this.status = 'none',
    this.costMin,
    this.costMax,
    this.estimatedCount = 0,
    this.unestimatedCount = 0,
    this.optional = const [],
  });

  factory RepairBudget.fromJson(Object? value) {
    if (value is! Map) return const RepairBudget();
    final optional = value['optional'];
    return RepairBudget(
      status: value['status'] is String ? value['status'] as String : 'none',
      costMin: _integer(value['cost_min']),
      costMax: _integer(value['cost_max']),
      estimatedCount: _integer(value['estimated_count']) ?? 0,
      unestimatedCount: _integer(value['unestimated_count']) ?? 0,
      optional: optional is List
          ? optional
                .whereType<Map>()
                .map(
                  (row) => RepairBudgetOptional.fromJson(
                    Map<String, dynamic>.from(row),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }

  bool get isEmpty => status == 'none' && optional.isEmpty;
}

class RepairBudgetOptional {
  final int? id;
  final String title;
  final RepairEstimate? estimate;

  const RepairBudgetOptional({this.id, required this.title, this.estimate});

  factory RepairBudgetOptional.fromJson(Map<String, dynamic> json) =>
      RepairBudgetOptional(
        id: _integer(json['id']),
        title: json['title'] is String ? json['title'] as String : '',
        estimate: json['repair_estimate'] == null
            ? null
            : RepairEstimate.fromJson(json['repair_estimate']),
      );
}

class PrivateRepairQuote {
  final int id;
  final String? originalName;
  final String? mimeType;
  final int? size;
  final DateTime? uploadedAt;

  const PrivateRepairQuote({
    required this.id,
    this.originalName,
    this.mimeType,
    this.size,
    this.uploadedAt,
  });

  factory PrivateRepairQuote.fromJson(Object? value) {
    if (value is! Map || value['id'] == null) {
      throw const FormatException('Invalid private quote');
    }
    final uploaded = value['uploaded_at'];
    return PrivateRepairQuote(
      id: _integer(value['id']) ?? 0,
      originalName: value['original_name'] is String
          ? value['original_name'] as String
          : null,
      mimeType: value['mime_type'] is String
          ? value['mime_type'] as String
          : null,
      size: _integer(value['size']),
      uploadedAt: uploaded is String ? DateTime.tryParse(uploaded) : null,
    );
  }
}

class PublishedRepairQuote {
  final int id;
  final String? url;
  final String? mimeType;

  const PublishedRepairQuote({required this.id, this.url, this.mimeType});

  factory PublishedRepairQuote.fromJson(Object? value) {
    if (value is! Map || value['id'] == null) {
      throw const FormatException('Invalid published quote');
    }
    return PublishedRepairQuote(
      id: _integer(value['id']) ?? 0,
      url: value['url'] is String ? value['url'] as String : null,
      mimeType: value['mime_type'] is String
          ? value['mime_type'] as String
          : null,
    );
  }
}

String formatCfa(int amount, {String locale = 'fr'}) =>
    '${NumberFormat.decimalPattern(locale).format(amount)} F CFA';

String formatCfaRange(int min, int max, {String locale = 'fr'}) => min == max
    ? formatCfa(min, locale: locale)
    : '${NumberFormat.decimalPattern(locale).format(min)} à ${formatCfa(max, locale: locale)}';

int? _integer(Object? value) => value is int
    ? value
    : value is String
    ? int.tryParse(value)
    : null;
