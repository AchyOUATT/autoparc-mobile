import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/garage_repository.dart';
import '../../data/models/owned_vehicle.dart';
import '../../../../features/catalog/data/models/part.dart';
import '../../../../core/utils/currency_format.dart';

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
              Text(e.toString(), textAlign: TextAlign.center),
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

class _EmptyParts extends StatelessWidget {
  final OwnedVehicle? vehicle;
  const _EmptyParts({this.vehicle});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.settings_outlined, size: 64,
            color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 12),
        const Text('Aucune pièce compatible trouvée'),
        if (vehicle?.compatibilityReady == false) ...[
          const SizedBox(height: 8),
          const Text(
            'Ajoutez la motorisation à votre véhicule\npour un meilleur résultat.',
            textAlign: TextAlign.center,
          ),
        ],
      ],
    ),
  );
}
