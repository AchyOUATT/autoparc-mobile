import '../../../../core/l10n/langue.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/garage_repository.dart';
import '../../data/models/owned_vehicle.dart';
import '../../../../core/api/api_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

(AuthType, String?) _garageIdentity(AuthState auth) =>
    (auth.type, auth.isClient ? auth.firebaseUser?.uid : null);

// ── Notifier ──────────────────────────────────────────────────────────

class GarageNotifier extends AsyncNotifier<List<OwnedVehicle>> {
  GarageRepository get _repo => ref.read(garageRepositoryProvider);
  int _generation = 0;

  @override
  Future<List<OwnedVehicle>> build() {
    ref.watch(langueProvider);
    ref.listen(authProvider.select(_garageIdentity), (previous, next) {
      if (previous == next) return;
      _generation++;
      // Do not retain another account's vehicles or errors while loading.
      state = const AsyncData([]);
    });
    final identity = ref.watch(authProvider.select(_garageIdentity));
    _generation++;
    ref.onDispose(() => _generation++);
    return identity.$1 == AuthType.client
        ? _repo.getVehicles()
        : Future.value(const []);
  }

  /// Ajoute un véhicule et l'insère en tête de liste sans recharger.
  Future<String?> addVehicle(Map<String, dynamic> payload) async {
    final generation = _generation;
    try {
      final vehicle = await _repo.addVehicle(payload);
      if (generation != _generation) return null;
      state = AsyncData([vehicle, ...state.valueOrNull ?? []]);
      return null; // succès
    } on ApiException catch (e) {
      if (generation != _generation) return null;
      return messageFor(
        e,
        l10n: lookupAppLocalizations(ref.read(langueProvider)),
      );
    } catch (e) {
      if (generation != _generation) return null;
      return messageFor(
        e,
        l10n: lookupAppLocalizations(ref.read(langueProvider)),
      );
    }
  }

  /// Met à jour un véhicule (kilométrage, surnom) localement + serveur.
  Future<String?> updateVehicle(int id, Map<String, dynamic> payload) async {
    final generation = _generation;
    try {
      final updated = await _repo.updateVehicle(id, payload);
      if (generation != _generation) return null;
      state = AsyncData(
        (state.valueOrNull ?? []).map((v) => v.id == id ? updated : v).toList(),
      );
      return null;
    } on ApiException catch (e) {
      if (generation != _generation) return null;
      return messageFor(
        e,
        l10n: lookupAppLocalizations(ref.read(langueProvider)),
      );
    } catch (e) {
      if (generation != _generation) return null;
      return messageFor(
        e,
        l10n: lookupAppLocalizations(ref.read(langueProvider)),
      );
    }
  }

  /// Supprime un véhicule localement dès que l'API confirme.
  Future<String?> deleteVehicle(int id) async {
    final generation = _generation;
    try {
      await _repo.deleteVehicle(id);
      if (generation != _generation) return null;
      state = AsyncData(
        (state.valueOrNull ?? []).where((v) => v.id != id).toList(),
      );
      return null;
    } on ApiException catch (e) {
      if (generation != _generation) return null;
      return messageFor(
        e,
        l10n: lookupAppLocalizations(ref.read(langueProvider)),
      );
    } catch (e) {
      if (generation != _generation) return null;
      return messageFor(
        e,
        l10n: lookupAppLocalizations(ref.read(langueProvider)),
      );
    }
  }

  Future<void> refresh() async {
    final generation = _generation;
    if (!ref.read(authProvider).isClient) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    final refreshed = await AsyncValue.guard(() => _repo.getVehicles());
    if (generation == _generation) state = refreshed;
  }
}

final garageProvider =
    AsyncNotifierProvider<GarageNotifier, List<OwnedVehicle>>(
      GarageNotifier.new,
    );

/// Véhicule du garage actuellement sélectionné pour marquer les pièces
/// compatibles dans la liste de pièces détachées.
/// null = aucun filtre actif, pas de badge affiché.
final selectedGarageVehicleProvider = StateProvider<OwnedVehicle?>((ref) {
  ref.watch(authProvider.select(_garageIdentity));
  return null;
});
