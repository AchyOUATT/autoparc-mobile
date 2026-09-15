import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../vehicles/data/models/catalog_refs.dart';
import '../../../vehicles/presentation/providers/vehicle_refs_provider.dart';
import '../../data/models/owned_vehicle.dart';
import '../providers/garage_provider.dart';

/// Réclamer la motorisation manquante, là où le manque se voit.
///
/// La compatibilité d'une pièce se décide côté serveur sur
/// `effective_engine_type_id` ou `effective_engine_code` : sans l'un des deux,
/// aucune pièce ne peut être déclarée compatible, et la liste reste vide sans
/// que rien n'explique pourquoi. Le serveur résume cet état dans
/// `compatibility_ready`, et c'est lui qu'on lit — surtout pas « le menu
/// déroulant était vide » : la motorisation peut venir de la finition sans
/// avoir été saisie.
///
/// Le moment choisi n'est pas l'enregistrement. Quelqu'un qui vient de remplir
/// dix champs a gagné son écran de succès ; l'arrêter avec un reproche qu'il ne
/// peut souvent pas satisfaire — beaucoup ignorent leur motorisation de tête —
/// n'apprend qu'à fermer les boîtes de dialogue sans les lire. Le bandeau, lui,
/// attend sur la carte du véhicule : il se représente quand la personne a le
/// temps, éventuellement sa carte grise sous les yeux, et disparaît de lui-même
/// une fois la réponse donnée.

/// Bandeau affiché sur une carte véhicule tant que la motorisation manque.
class MissingEngineBanner extends ConsumerWidget {
  const MissingEngineBanner({super.key, required this.vehicle});

  final OwnedVehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (vehicle.compatibilityReady) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        // Le même ambre que les échéances proches : un manque à combler,
        // pas une erreur. Le rouge est réservé à ce qui est déjà dépassé.
        color: const Color(0xFFFAEEDA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.local_gas_station_outlined,
              size: 18, color: Color(0xFF8A5A00)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Motorisation non renseignée',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A5A00),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sans elle, impossible de savoir quelles pièces vont sur ce véhicule.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: const Color(0xFF8A5A00)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => showEngineTypeDialog(context, ref, vehicle),
            style: TextButton.styleFrom(foregroundColor: cs.primary),
            child: const Text('Compléter'),
          ),
        ],
      ),
    );
  }
}

/// Demande la seule information manquante, et rien d'autre.
///
/// Un formulaire d'édition complet obligerait à relire dix champs corrects pour
/// en corriger un. Le geste reste celui du kilométrage : une question, une
/// réponse, la liste se rafraîchit.
Future<void> showEngineTypeDialog(
  BuildContext context,
  WidgetRef ref,
  OwnedVehicle vehicle,
) async {
  final refs = await ref.read(catalogRefsProvider.future).then<CatalogRefs?>(
        (r) => r,
        onError: (_, __) => null,
      );

  if (!context.mounted) return;

  if (refs == null || refs.engineTypes.isEmpty) {
    _dire(context, 'Liste des motorisations indisponible. Réessayez plus tard.',
        erreur: true);
    return;
  }

  final choix = await showDialog<EngineTypeRef>(
    context: context,
    builder: (ctx) => _EngineTypeDialog(
      vehicle: vehicle,
      engineTypes: refs.engineTypes,
    ),
  );

  if (choix == null || !context.mounted) return;

  final erreur = await ref
      .read(garageProvider.notifier)
      .updateVehicle(vehicle.id, {'engine_type_id': choix.id});

  if (!context.mounted) return;

  _dire(
    context,
    erreur ?? 'Motorisation enregistrée : les pièces compatibles sont à jour.',
    erreur: erreur != null,
  );
}

void _dire(BuildContext context, String message, {required bool erreur}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor:
          erreur ? Theme.of(context).colorScheme.error : null,
    ),
  );
}

class _EngineTypeDialog extends StatefulWidget {
  const _EngineTypeDialog({required this.vehicle, required this.engineTypes});

  final OwnedVehicle vehicle;
  final List<EngineTypeRef> engineTypes;

  @override
  State<_EngineTypeDialog> createState() => _EngineTypeDialogState();
}

class _EngineTypeDialogState extends State<_EngineTypeDialog> {
  EngineTypeRef? _choix;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Motorisation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.vehicle.identity.fullName} · ${widget.vehicle.year}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          // Une question qu'on peut se poser sans document sous les yeux :
          // « je fais le plein de quoi ? ». La formuler en jargon reviendrait
          // à demander d'aller chercher la carte grise.
          const Text('Avec quel carburant roule ce véhicule ?'),
          const SizedBox(height: 12),
          DropdownButtonFormField<EngineTypeRef>(
            value: _choix,
            isExpanded: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            hint: const Text('Sélectionner…'),
            items: widget.engineTypes
                .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                .toList(),
            onChanged: (e) => setState(() => _choix = e),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          // Tant que rien n'est choisi, enregistrer n'aurait rien à écrire.
          onPressed: _choix == null ? null : () => Navigator.pop(context, _choix),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
