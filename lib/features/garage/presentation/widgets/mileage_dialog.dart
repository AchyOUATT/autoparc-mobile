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
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _MileageDialog(vehicle: vehicle),
  );

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

/// Le contrôleur appartient à la boîte de dialogue, pas à la fonction.
///
/// Il était créé avant `showDialog` et détruit juste après, à la ligne
/// suivante. Or `showDialog` rend la main dès que `Navigator.pop` est appelé :
/// la boîte est alors encore en train de s'animer, et son champ de saisie
/// toujours monté. Le clavier qui se referme modifie les `MediaQuery`,
/// l'overlay se reconstruit, le champ se réabonne à un contrôleur déjà
/// détruit — et Flutter lève « A TextEditingController was used after being
/// disposed », suivi de « '_dependents.isEmpty': is not true » et d'un écran
/// rouge.
///
/// C'est le plantage intermittent qu'on n'arrivait pas à reproduire : il
/// demande que le clavier soit ouvert et que sa fermeture tombe pendant les
/// quelques dixièmes de seconde de l'animation de sortie.
///
/// En confiant le contrôleur à l'état du widget, Flutter le détruit lui-même
/// une fois la route entièrement retirée.
class _MileageDialog extends StatefulWidget {
  final OwnedVehicle vehicle;

  const _MileageDialog({required this.vehicle});

  @override
  State<_MileageDialog> createState() => _MileageDialogState();
}

class _MileageDialogState extends State<_MileageDialog> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.vehicle.mileageKm?.toString() ?? '',
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mettre à jour'),
      content: TextField(
        controller: _ctrl,
        decoration: const InputDecoration(
          labelText: 'Kilométrage actuel',
          suffixText: 'km',
        ),
        keyboardType: TextInputType.number,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, {
            'mileage_km': int.tryParse(_ctrl.text) ?? widget.vehicle.mileageKm,
          }),
          child: const Text('Sauvegarder'),
        ),
      ],
    );
  }
}
