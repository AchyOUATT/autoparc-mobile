import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../data/garage_repository.dart';
import '../../data/models/fuel_fill.dart';
import 'garage_provider.dart';

/// Les passages à la pompe d'un véhicule.
///
/// Une famille par véhicule, et en `autoDispose` : l'historique n'est consulté
/// que depuis la fiche, et le garder en mémoire pour chaque voiture du parc
/// n'apporterait qu'un risque d'afficher des chiffres périmés.
class FuelFillsNotifier extends AutoDisposeFamilyAsyncNotifier<List<FuelFill>, int> {
  GarageRepository get _repo => ref.read(garageRepositoryProvider);

  @override
  Future<List<FuelFill>> build(int ownedVehicleId) =>
      _repo.fuelFills(ownedVehicleId);

  /// Enregistre un passage, puis recharge tout.
  ///
  /// Pas d'insertion en tête de liste, contrairement à l'ajout d'un véhicule :
  /// un passage saisi en retard se range à son kilométrage et change les
  /// chiffres de ses voisins — l'intervalle qu'il coupe en deux, et celui
  /// qu'il ferme. Seul le serveur sait lesquels, puisque lui seul chaîne les
  /// pleins.
  Future<String?> addFill(Map<String, dynamic> payload) async {
    try {
      await _repo.addFuelFill(arg, payload);
      await _rechargerToutLeGarage();
      return null;
    } catch (e) {
      return messageFor(e);
    }
  }

  /// Efface un passage mal saisi, puis recharge tout — mêmes voisins touchés
  /// qu'à l'ajout.
  Future<String?> deleteFill(int fillId) async {
    try {
      await _repo.deleteFuelFill(fillId);
      await _rechargerToutLeGarage();
      return null;
    } catch (e) {
      return messageFor(e);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.fuelFills(arg));
  }

  /// Le garage entier, pas seulement cette liste : enregistrer un passage
  /// relève `owned_vehicles.mileage_km` quand le compteur saisi est plus haut,
  /// donc déplace l'échéance de vidange affichée sur la fiche, et recalcule
  /// `fuel_tracking`. Sans cette invalidation, la fiche garderait l'ancien
  /// kilométrage pendant que la liste montrerait le nouveau.
  Future<void> _rechargerToutLeGarage() async {
    state = await AsyncValue.guard(() => _repo.fuelFills(arg));
    ref.invalidate(garageProvider);
  }
}

final fuelFillsProvider = AsyncNotifierProvider.autoDispose
    .family<FuelFillsNotifier, List<FuelFill>, int>(FuelFillsNotifier.new);
