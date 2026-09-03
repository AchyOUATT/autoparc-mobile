import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../shared/models/paginated_response.dart';
import 'models/partner.dart';

final partnerRepositoryProvider = Provider<PartnerRepository>(
  (ref) => PartnerRepository(ref.read(apiClientProvider)),
);

class PartnerRepository {
  final ApiClient _client;
  const PartnerRepository(this._client);

  // ── Annuaire ─────────────────────────────────────────────────────

  Future<PaginatedResponse<Partner>> getPartners({
    int page = 1,
    int perPage = 50,
    String? search,
    bool includeInactive = false,
  }) async {
    final json = await _client.get(Endpoints.partners, params: {
      'page':     page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'q': search,
      if (includeInactive) 'all': '1',
    });
    return PaginatedResponse.fromJson(json, Partner.fromJson);
  }

  Future<Partner> getPartner(int id) async {
    final json = await _client.get(Endpoints.partnerDetail(id));
    return Partner.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<Partner> createPartner(Map<String, dynamic> data) async {
    final json = await _client.post(Endpoints.partners, data: data);
    return Partner.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<Partner> updatePartner(int id, Map<String, dynamic> data) async {
    final json = await _client.put(Endpoints.partnerDetail(id), data: data);
    return Partner.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> deletePartner(int id) async {
    await _client.delete(Endpoints.partnerDetail(id));
  }

  // ── Associations ─────────────────────────────────────────────────

  Future<List<Partner>> getPartnersForPart(int partId) async {
    final json = await _client.get(Endpoints.partPartners(partId));
    final data = json['data'] as List<dynamic>;
    return data.map((e) => Partner.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> attachToPart({
    required int partId,
    required int partnerId,
    String? role,
    String? notes,
  }) async {
    await _client.post(Endpoints.partPartners(partId), data: {
      'partner_id': partnerId,
      if (role  != null) 'role':  role,
      if (notes != null) 'notes': notes,
    });
  }

  Future<void> detachFromPart(int partId, int partnerId) async {
    await _client.delete(Endpoints.partPartnerDetach(partId, partnerId));
  }

  Future<List<Partner>> getPartnersForAccessory(int accessoryId) async {
    final json = await _client.get(Endpoints.accessoryPartners(accessoryId));
    final data = json['data'] as List<dynamic>;
    return data.map((e) => Partner.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> attachToAccessory({
    required int accessoryId,
    required int partnerId,
    String? role,
    String? notes,
  }) async {
    await _client.post(Endpoints.accessoryPartners(accessoryId), data: {
      'partner_id': partnerId,
      if (role  != null) 'role':  role,
      if (notes != null) 'notes': notes,
    });
  }

  Future<void> detachFromAccessory(int accessoryId, int partnerId) async {
    await _client.delete(Endpoints.accessoryPartnerDetach(accessoryId, partnerId));
  }

  Future<List<Partner>> getPartnersForVehicle(int vehicleId) async {
    final json = await _client.get(Endpoints.vehiclePartners(vehicleId));
    final data = json['data'] as List<dynamic>;
    return data.map((e) => Partner.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> attachToVehicle({
    required int vehicleId,
    required int partnerId,
    String? role,
    String? notes,
  }) async {
    await _client.post(Endpoints.vehiclePartners(vehicleId), data: {
      'partner_id': partnerId,
      if (role  != null) 'role':  role,
      if (notes != null) 'notes': notes,
    });
  }

  Future<void> detachFromVehicle(int vehicleId, int partnerId) async {
    await _client.delete(Endpoints.vehiclePartnerDetach(vehicleId, partnerId));
  }
}
