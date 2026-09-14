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
/// `daysLeft` est négatif une fois l'échéance passée, ce qui suffit à ordonner
/// l'ensemble : une visite technique dépassée de 11 jours (-11) passe devant
/// une assurance dépassée de 2 jours (-2), elle-même devant un contrôle dans 4
/// jours. Une première version renvoyait une même valeur pour tout ce qui
/// était dépassé — deux voitures en retard devenaient alors indiscernables, et
/// c'était la moins urgente qui s'affichait.
int urgencyOf(OwnedVehicle vehicle) {
  final prochaine = vehicle.nextDeadline;

  if (prochaine == null) return 1 << 30;
  if (prochaine.daysLeft != null) return prochaine.daysLeft!;

  // La vidange se compte en kilomètres : impossible de la comparer à des
  // jours. Dépassée, elle passe devant ce qui est encore à venir ; sinon elle
  // ferme la marche.
  return prochaine.overdue ? -1 : 1 << 29;
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
