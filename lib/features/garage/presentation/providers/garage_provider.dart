import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/garage_repository.dart';
import '../../data/models/owned_vehicle.dart';
import '../../../../core/api/api_exception.dart';

// ── Notifier ──────────────────────────────────────────────────────────

class GarageNotifier extends AsyncNotifier<List<OwnedVehicle>> {
  GarageRepository get _repo => ref.read(garageRepositoryProvider);

  @override
  Future<List<OwnedVehicle>> build() => _repo.getVehicles();

  /// Ajoute un véhicule et l'insère en tête de liste sans recharger.
  Future<String?> addVehicle(Map<String, dynamic> payload) async {
    try {
      final vehicle = await _repo.addVehicle(payload);
      state = AsyncData([vehicle, ...state.valueOrNull ?? []]);
      return null; // succès
    } on ApiException catch (e) {
      return e.errors?.values.first.first ?? e.message;
    } catch (e) {
      return messageFor(e);
    }
  }

  /// Met à jour un véhicule (kilométrage, surnom) localement + serveur.
  Future<String?> updateVehicle(int id, Map<String, dynamic> payload) async {
    try {
      final updated = await _repo.updateVehicle(id, payload);
      state = AsyncData(
        (state.valueOrNull ?? []).map((v) => v.id == id ? updated : v).toList(),
      );
      return null;
    } on ApiException catch (e) {
      return e.errors?.values.first.first ?? e.message;
    } catch (e) {
      return messageFor(e);
    }
  }

  /// Supprime un véhicule localement dès que l'API confirme.
  Future<String?> deleteVehicle(int id) async {
    try {
      await _repo.deleteVehicle(id);
      state = AsyncData(
        (state.valueOrNull ?? []).where((v) => v.id != id).toList(),
      );
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return messageFor(e);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getVehicles());
  }
}

final garageProvider =
    AsyncNotifierProvider<GarageNotifier, List<OwnedVehicle>>(
  GarageNotifier.new,
);

/// Véhicule du garage actuellement sélectionné pour marquer les pièces
/// compatibles dans la liste de pièces détachées.
/// null = aucun filtre actif, pas de badge affiché.
final selectedGarageVehicleProvider =
    StateProvider<OwnedVehicle?>((ref) => null);
