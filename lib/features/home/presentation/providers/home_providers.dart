import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../catalog/data/catalog_repository.dart';
import '../../../catalog/data/models/part.dart';
import '../../../catalog/data/models/vehicle.dart';
import '../../../garage/data/garage_repository.dart';
import '../../../garage/data/models/owned_vehicle.dart';
import '../../../garage/presentation/providers/garage_provider.dart';

/// Véhicule choisi à la main dans le sélecteur de l'accueil.
///
/// Null tant que le propriétaire n'a rien choisi : l'accueil met alors en
/// avant le véhicule le plus urgent, plutôt que le premier enregistré.
final homeSelectedVehicleIdProvider = StateProvider<int?>((ref) => null);

/// Véhicule mis en avant sur l'accueil.
final homeVehicleProvider = Provider<OwnedVehicle?>((ref) {
  final vehicles = ref.watch(garageProvider).valueOrNull ?? const <OwnedVehicle>[];
  if (vehicles.isEmpty) return null;

  final choisi = ref.watch(homeSelectedVehicleIdProvider);
  if (choisi != null) {
    for (final v in vehicles) {
      if (v.id == choisi) return v;
    }
  }

  return ([...vehicles]..sort((a, b) => urgencyOf(a).compareTo(urgencyOf(b)))).first;
});

/// Rang d'urgence d'un véhicule : plus la valeur est basse, plus ça presse.
///
/// Une échéance dépassée passe devant tout le reste — c'est la seule chose
/// qu'un propriétaire doit voir en ouvrant l'application. Un véhicule sans
/// échéance datée ferme la marche : la vidange se compte en kilomètres, on ne
/// peut pas la comparer à des jours.
int urgencyOf(OwnedVehicle vehicle) {
  final prochaine = vehicle.nextDeadline;

  if (prochaine == null) return 1 << 30;
  if (prochaine.overdue) return -1 << 20;

  return prochaine.daysLeft ?? (1 << 29);
}

/// Vrai si un autre véhicule que celui affiché réclame de l'attention.
///
/// Sans ce signal, un propriétaire de deux voitures peut ouvrir l'application
/// dix fois sans voir que la seconde a une assurance expirée.
bool needsAttention(OwnedVehicle vehicle) {
  final prochaine = vehicle.nextDeadline;

  return prochaine != null && (prochaine.overdue || (prochaine.daysLeft ?? 999) <= 30);
}

/// Pièces compatibles avec le véhicule mis en avant.
final homeCompatiblePartsProvider =
    FutureProvider.autoDispose.family<List<Part>, int>((ref, ownedVehicleId) async {
  final parts = await ref.read(garageRepositoryProvider).compatibleParts(ownedVehicleId);

  return parts.take(6).toList();
});

/// Véhicules mis en avant — la vitrine.
final homeDealsProvider = FutureProvider.autoDispose<List<Vehicle>>((ref) async {
  final page = await ref.read(catalogRepositoryProvider).getVehicles(
    deal: true,
    perPage: 6,
  );

  return page.data;
});
