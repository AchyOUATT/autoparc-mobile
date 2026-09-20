import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/garage_repository.dart';
import '../../data/models/motorisation.dart';
import '../../data/models/owned_vehicle.dart';
import '../providers/garage_provider.dart';

/// La consommation du véhicule, ou l'invitation à la connaître.
///
/// Le chiffre ne s'affiche jamais seul : il porte sa provenance et son cycle
/// d'essai. Une même voiture se lit 8,2 l/100 selon la méthode canadienne et
/// 6,4 selon la norme européenne — sans cette mention, le propriétaire qui
/// compare deux véhicules croirait à une différence de moteur.
class ConsumptionTile extends ConsumerWidget {
  final OwnedVehicle vehicle;

  const ConsumptionTile({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conso = vehicle.consumption;
    final cs    = Theme.of(context).colorScheme;

    if (conso == null) {
      return _Invitation(vehicle: vehicle);
    }

    final mixte = conso.combinedL100km;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.local_gas_station_outlined, size: 18, color: cs.outline),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mixte == null
                      ? conso.label
                      : '${_nombre(mixte)} l/100 km — ${conso.label}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (conso.cityL100km != null && conso.highwayL100km != null)
                  Text(
                    'ville ${_nombre(conso.cityL100km!)} · '
                    'route ${_nombre(conso.highwayL100km!)}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: cs.outline),
                  ),
                Text(
                  '${conso.source} — ${conso.cycle}',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: cs.outline),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => choisirMotorisation(context, ref, vehicle),
            child: const Text('Changer'),
          ),
        ],
      ),
    );
  }
}

/// Ce que voit un propriétaire dont la motorisation est inconnue.
class _Invitation extends ConsumerWidget {
  final OwnedVehicle vehicle;

  const _Invitation({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => choisirMotorisation(context, ref, vehicle),
        icon: const Icon(Icons.local_gas_station_outlined, size: 18),
        label: const Text('Quelle est ma consommation ?'),
      ),
    );
  }
}

/// Demande sa motorisation au propriétaire, puis enregistre son choix.
///
/// On ne demande ni la finition ni la puissance : ce qui détermine la
/// consommation, c'est le moteur et la boîte. Une Camry 2013 existe en 2,5 l
/// quatre cylindres et en 3,5 l V6 — 8,2 contre 9,4 l/100.
Future<void> choisirMotorisation(
  BuildContext context,
  WidgetRef ref,
  OwnedVehicle vehicle,
) async {
  List<Motorisation> options;

  try {
    options = await ref.read(garageRepositoryProvider).motorisations(
          vehicleModelId: vehicle.vehicleModelId,
          year: vehicle.year,
        );
  } catch (_) {
    if (!context.mounted) return;
    _dire(context, 'Liste des motorisations indisponible. Réessayez plus tard.',
        erreur: true);
    return;
  }

  if (!context.mounted) return;

  if (options.isEmpty) {
    // Aucune source publique ne couvre ce modèle — Fortuner, Prado, D-Max et
    // les autres, vendus ni en Amérique du Nord ni en Europe. Le dire
    // franchement vaut mieux qu'une liste vide sans explication.
    _dire(
      context,
      'Aucune donnée officielle de consommation pour ce modèle.',
      erreur: false,
    );
    return;
  }

  final choix = await showDialog<Motorisation>(
    context: context,
    builder: (ctx) => _DialogueMotorisation(
      vehicle: vehicle,
      options: options,
    ),
  );

  if (choix == null || !context.mounted) return;

  final erreur = await ref
      .read(garageProvider.notifier)
      .updateVehicle(vehicle.id, {'motorisation_id': choix.id});

  if (!context.mounted) return;

  _dire(
    context,
    erreur ?? 'Motorisation enregistrée.',
    erreur: erreur != null,
  );
}

class _DialogueMotorisation extends StatelessWidget {
  final OwnedVehicle vehicle;
  final List<Motorisation> options;

  const _DialogueMotorisation({required this.vehicle, required this.options});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text('Motorisation de votre ${vehicle.identity.model ?? 'véhicule'}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choisissez le moteur qui se trouve sous le capot. '
              'La finition ne change pas la consommation.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final m = options[i];
                  final mixte = m.consumption.combinedL100km;

                  final choisie = m.id == vehicle.motorisationId;

                  return ListTile(
                    onTap: () => Navigator.pop(context, m),
                    title: Text(m.label),
                    // Le cycle d'essai accompagne chaque ligne, pas seulement
                    // celle qui sera choisie : la liste melange des cotes
                    // canadiennes et europeennes, et 5,2 l/100 en WLTP ne se
                    // compare pas a 8,9 en cinq cycles. Sans cette mention,
                    // l'ecart passerait pour une difference de moteur.
                    subtitle: Text([
                      if (m.fuel != null) m.fuel!,
                      if (mixte != null) '${_nombre(mixte)} l/100 km',
                      if (m.consumption.cycle.isNotEmpty) m.consumption.cycle,
                    ].join(' · ')),
                    trailing: choisie
                        ? Icon(Icons.check, color: cs.primary)
                        : null,
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}

/// « 8,2 » et non « 8.2 » : la virgule décimale est celle du français.
String _nombre(double valeur) =>
    valeur.toStringAsFixed(1).replaceAll('.', ',');

void _dire(BuildContext context, String message, {required bool erreur}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: erreur ? Theme.of(context).colorScheme.error : null,
    ),
  );
}
