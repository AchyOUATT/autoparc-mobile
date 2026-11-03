import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import 'staff_inspection.dart';

final staffInspectionRepositoryProvider = Provider<StaffInspectionRepository>(
  (ref) => StaffInspectionRepository(ref.read(apiClientProvider)),
);

class StaffInspectionHistory {
  final List<StaffInspectionReport> reports;
  final int? nextPage;
  const StaffInspectionHistory({required this.reports, this.nextPage});
}

class StaffInspectionRepository {
  final ApiClient _api;
  StaffInspectionRepository(this._api);

  Future<StaffInspectionReport> report(int id) async =>
      _report(await _api.get('/catalog/vehicle-inspections/${_id(id)}'));

  Future<StaffInspectionHistory> history(
    String source,
    int sourceId, {
    int page = 1,
  }) async {
    final response = await _api.get(
      _target(source, sourceId),
      params: {'page': page},
    );
    final data = response['data'];
    if (data is! List) {
      throw const FormatException('Invalid inspection history');
    }
    final meta = response['meta'];
    final current = meta is Map
        ? meta['current_page']
        : response['current_page'];
    final last = meta is Map ? meta['last_page'] : response['last_page'];
    final currentPage = int.tryParse('$current') ?? page;
    final lastPage = int.tryParse('$last') ?? currentPage;
    return StaffInspectionHistory(
      reports: List.unmodifiable(
        data.map(
          (value) => StaffInspectionReport.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        ),
      ),
      nextPage: currentPage < lastPage ? currentPage + 1 : null,
    );
  }

  Future<StaffInspectionReport> create(
    String source,
    int sourceId,
    Map<String, dynamic> data,
  ) async => _report(await _api.post(_target(source, sourceId), data: data));

  Future<StaffInspectionReport> withdraw(int id, String reason) async =>
      _report(
        await _api.post(
          '/vehicle-inspections/${_id(id)}/withdraw',
          data: {'reason': reason.trim()},
        ),
      );

  String _target(String source, int sourceId) {
    if (!const ['vehicle', 'private_listing'].contains(source)) {
      throw ArgumentError.value(source, 'source');
    }
    return '/vehicle-inspections/$source/${_id(sourceId)}';
  }

  int _id(int id) {
    if (id <= 0) throw ArgumentError.value(id, 'id');
    return id;
  }

  StaffInspectionReport _report(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map) {
      throw const FormatException('Invalid inspection response');
    }
    return StaffInspectionReport.fromJson(Map<String, dynamic>.from(data));
  }
}
