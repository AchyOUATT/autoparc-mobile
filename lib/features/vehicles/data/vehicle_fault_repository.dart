import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import 'models/vehicle_fault.dart';

final vehicleFaultRepositoryProvider = Provider<VehicleFaultRepository>(
  (ref) => VehicleFaultRepository(ref.read(apiClientProvider)),
);

class VehicleFaultRepository {
  final ApiClient _client;
  const VehicleFaultRepository(this._client);

  /// Liste les pannes d'un véhicule.
  Future<List<VehicleFault>> getFaults(int vehicleId, {bool openOnly = false}) async {
    final json = await _client.get(
      '/vehicles/$vehicleId/faults',
      params: openOnly ? {'open_only': '1'} : null,
    );
    // VehicleFaultResource::collection() enveloppe dans {"data": [...]}
    final list = json['data'] as List<dynamic>;
    return list
        .map((e) => VehicleFault.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Déclare une nouvelle panne.
  Future<VehicleFault> createFault(
    int vehicleId,
    Map<String, dynamic> data,
  ) async {
    final json = await _client.post('/vehicles/$vehicleId/faults', data: data);
    return VehicleFault.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Met à jour une panne existante.
  Future<VehicleFault> updateFault(
    int vehicleId,
    int faultId,
    Map<String, dynamic> data,
  ) async {
    final json = await _client.put(
      '/vehicles/$vehicleId/faults/$faultId',
      data: data,
    );
    return VehicleFault.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Clôture une panne après réparation.
  Future<VehicleFault> resolveFault(
    int vehicleId,
    int faultId, {
    double? actualRepairCost,
    String? repairedAt,
  }) async {
    final json = await _client.post(
      '/vehicles/$vehicleId/faults/$faultId/resolve',
      data: {
        if (actualRepairCost != null) 'actual_repair_cost': actualRepairCost,
        if (repairedAt != null) 'repaired_at': repairedAt,
      },
    );
    return VehicleFault.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Supprime une panne.
  Future<void> deleteFault(int vehicleId, int faultId) async {
    await _client.delete('/vehicles/$vehicleId/faults/$faultId');
  }
}
