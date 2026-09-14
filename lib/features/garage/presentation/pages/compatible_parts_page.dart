import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/garage_repository.dart';
import '../../data/models/owned_vehicle.dart';
import '../../../../features/catalog/data/models/part.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/api/api_exception.dart';

// ── Provider family ──────────────────────────────────────────────────

final _compatiblePartsProvider =
    FutureProvider.autoDispose.family<List<Part>, int>((ref, ownedVehicleId) {
  return ref.read(garageRepositoryProvider).compatibleParts(ownedVehicleId);
});

// ── Page ─────────────────────────────────────────────────────────────

class CompatiblePartsPage extends ConsumerWidget {
  final int ownedVehicleId;
  final OwnedVehicle? vehicle;

  const CompatiblePartsPage({
    super.key,
    required this.ownedVehicleId,
    this.vehicle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partsAsync = ref.watch(_compatiblePartsProvider(ownedVehicleId));
    final title      = vehicle != null
        ? 'Pièces — ${vehicle!.displayName}'
        : 'Pièces compatibles';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: false,
        bottom: vehicle?.compatibilityReady == false
            ? PreferredSize(
                preferredSize: const Size.fromHeight(36),
                child: Container(
                  width: double.infinity,
                  color: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Précision limitée — ajoutez la motorisation pour un résultat plus fin.',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: partsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48),
              const SizedBox(height: 12),
              Text(messageFor(e), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(_compatiblePartsProvider(ownedVehicleId)),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (parts) => parts.isEmpty
            ? _EmptyParts(vehicle: vehicle)
            : _PartsList(parts: parts),
      ),
    );
  }
}

// ── Liste ─────────────────────────────────────────────────────────────

class _PartsList extends StatelessWidget {
  final List<Part> parts;
  const _PartsList({required this.parts});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          sliver: SliverToBoxAdapter(
            child: Text(
              '${parts.length} pièce${parts.length > 1 ? 's' : ''} trouvée${parts.length > 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        SliverList.separated(
          itemCount: parts.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
          itemBuilder: (_, i) => _PartTile(part: parts[i]),
        ),
      ],
    );
  }
}

class _PartTile extends StatelessWidget {
  final Part part;
  const _PartTile({required this.part});

  static const _typeColors = {
    'oem':         Colors.blue,
    'oes':         Colors.teal,
    'aftermarket': Colors.orange,
    'salvage':     Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final color = _typeColors[part.type] ?? Colors.grey;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Text(
          part.type.substring(0, 1).toUpperCase(),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(part.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: part.sku != null
          ? Text(
              part.sku!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: cs.outline,
              ),
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatXofShort(part.pricing.sellingPrice),
            style: TextStyle(fontWeight: FontWeight.w700, color: cs.primary),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                part.stock.quantity > 0 ? Icons.check_circle : Icons.cancel,
                size: 12,
                color: part.stock.quantity > 0 ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 3),
              Text('${part.stock.quantity}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
      onTap: () => context.push('/parts/${part.id}', extra: part),
    );
  }
}

// ── Vide ──────────────────────────────────────────────────────────────

/// Aucun résultat — et l'écran doit dire lequel des deux vides c'est.
///
/// « Aucune pièce compatible trouvée » laissait deviner : le catalogue est-il
/// vide pour ce modèle, ou manque-t-il une information sur le véhicule ? Les
/// deux causes appellent des gestes opposés, et l'une des deux se répare en
/// trente secondes.
///
/// Dans tous les cas on propose une sortie : parcourir le catalogue entier, ou
/// déposer un besoin — ce qui transforme une impasse en signal pour l'équipe,
/// puisque chaque besoin notifie le personnel.
class _EmptyParts extends StatelessWidget {
  final OwnedVehicle? vehicle;
  const _EmptyParts({this.vehicle});

  bool get _motorisationManquante => vehicle?.compatibilityReady == false;

  String get _titre => _motorisationManquante
      ? 'Motorisation inconnue'
      : 'Aucune pièce déclarée pour ce modèle';

  String get _explication {
    if (_motorisationManquante) {
      return 'Sans la motorisation, impossible de savoir quelles pièces vont '
          'sur ce véhicule. Renseignez-la, ou saisissez le numéro de série : '
          'il la retrouve tout seul.';
    }

    final modele = vehicle?.identity.model;

    return modele == null
        ? 'Aucune pièce du catalogue n\'est rattachée à ce véhicule pour le moment.'
        : 'Aucune pièce du catalogue n\'est rattachée à ce modèle — '
            'une $modele — pour le moment.';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _motorisationManquante
                  ? Icons.help_outline
                  : Icons.settings_outlined,
              size: 56,
              color: cs.outline,
            ),
            const SizedBox(height: 14),
            Text(
              _titre,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _explication,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            if (_motorisationManquante)
              FilledButton.icon(
                onPressed: () => context.push('/garage'),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Compléter mon véhicule'),
              ),

            // Le besoin n'est pas un lot de consolation : c'est le seul canal
            // qui prévienne l'équipe qu'une demande existe sans réponse.
            TextButton.icon(
              onPressed: () => context.push('/needs/new?type=part'),
              icon: const Icon(Icons.inbox_outlined, size: 18),
              label: const Text('Dites-nous ce que vous cherchez'),
            ),
            TextButton(
              onPressed: () => context.go('/parts'),
              child: const Text('Parcourir toutes les pièces'),
            ),
          ],
        ),
      ),
    );
  }
}
