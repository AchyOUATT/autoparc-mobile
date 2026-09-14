import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/owned_vehicle.dart';
import '../providers/garage_provider.dart';

/// Met à jour le kilométrage d'un véhicule du garage.
///
/// Extrait de la page garage pour être appelé aussi depuis l'accueil : c'est
/// le geste le plus important de l'application côté propriétaire. Le rappel de
/// vidange se calcule à partir du kilométrage courant — sans mise à jour, il
/// ne part jamais. Le mettre à deux endroits multiplie les occasions de le
/// faire ; le dupliquer multiplierait les occasions de le voir diverger.
Future<void> showMileageDialog(
  BuildContext context,
  WidgetRef ref,
  OwnedVehicle vehicle,
) async {
  final ctrl = TextEditingController(text: vehicle.mileageKm?.toString() ?? '');

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Mettre à jour'),
      content: TextField(
        controller: ctrl,
        decoration: const InputDecoration(
          labelText: 'Kilométrage actuel',
          suffixText: 'km',
        ),
        keyboardType: TextInputType.number,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, {
            'mileage_km': int.tryParse(ctrl.text) ?? vehicle.mileageKm,
          }),
          child: const Text('Sauvegarder'),
        ),
      ],
    ),
  );

  ctrl.dispose();

  if (result == null || !context.mounted) return;

  final erreur = await ref.read(garageProvider.notifier).updateVehicle(vehicle.id, result);

  if (erreur != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(erreur),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
