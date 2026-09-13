import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/part.dart';
import '../../data/catalog_repository.dart';
import '../providers/catalog_providers.dart';
import '../../../../features/garage/data/models/garage_compatibility.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../features/cart/data/models/cart_item.dart';
import '../../../../features/cart/presentation/pages/cart_page.dart';
import '../../../../features/cart/presentation/providers/cart_provider.dart';
import '../../../../features/partners/presentation/widgets/product_partners_section.dart';
import '../../../../core/api/api_exception.dart';

const _typeLabels = {
  'oem':         'OEM — Constructeur d\'origine',
  'oes':         'OES — Équipementier agréé',
  'aftermarket': 'Aftermarket — Marché libre',
  'salvage':     'Récupération / Occasion',
};

const _conditionLabels = {
  'new':         'Neuf',
  'refurbished': 'Reconditionné',
  'used':        'Usagé',
};

class PartDetailPage extends ConsumerWidget {
  final int partId;
  final Part? initialPart;

  const PartDetailPage({
    super.key,
    required this.partId,
    this.initialPart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partAsync = ref.watch(partDetailProvider(partId));

    // Affichage immédiat avec les données de la liste, mise à jour dès que
    // la requête complète est disponible.
    final part = partAsync.valueOrNull ?? initialPart;

    if (part == null) {
      return Scaffold(
        appBar: AppBar(),
        body: partAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(messageFor(e))),
          data: (_) => const SizedBox.shrink(),
        ),
      );
    }

    final cs      = Theme.of(context).colorScheme;
    final auth    = ref.watch(authProvider);
    final isStaff = auth.isStaff;
    final inStock = part.stock.quantity > 0;

    Future<void> deletePart() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Supprimer cette pièce ?'),
          content: Text('« ${part.name} » sera supprimée définitivement.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: cs.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
      try {
        await ref.read(catalogRepositoryProvider).deletePart(part.id);
        ref.invalidate(partListProvider);
        if (context.mounted) context.pop();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(messageFor(e)), backgroundColor: cs.error),
          );
        }
      }
    }
    final inCart  = ref.watch(cartProvider.select(
      (items) => items.any(
        (i) => i.id == part.id && i.itemType == CartItemType.part,
      ),
    ));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── AppBar ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            actions: [
              if (auth.canManageCatalog)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Modifier',
                  onPressed: () => context
                      .push('/parts/${part.id}/edit', extra: part)
                      .then((_) => ref.invalidate(partDetailProvider(part.id))),
                ),
              if (auth.canDeleteCatalog)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: cs.error),
                  tooltip: 'Supprimer',
                  onPressed: deletePart,
                ),
              if (!isStaff) const CartIconButton(),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                part.name,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              background: Container(
                color: cs.surfaceContainerHighest,
                child: Center(
                  child: Icon(
                    Icons.settings_outlined,
                    size: 72,
                    color: cs.outline.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── SKU + Badge type ──────────────────────────────────
                Row(
                  children: [
                    if (part.sku != null)
                      Chip(
                        label: Text(
                          part.sku!,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                        avatar: const Icon(Icons.tag, size: 16),
                      ),
                    if (part.sku != null) const SizedBox(width: 8),
                    if (part.isOem)
                      Chip(
                        label: const Text('OEM'),
                        backgroundColor: cs.primaryContainer,
                        labelStyle: TextStyle(color: cs.onPrimaryContainer),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Prix ──────────────────────────────────────────────
                _PriceCard(pricing: part.pricing),
                const SizedBox(height: 12),

                // ── Stock ─────────────────────────────────────────────
                _StockCard(stock: part.stock, inStock: inStock),
                const SizedBox(height: 12),

                // ── Infos produit ─────────────────────────────────────
                _InfoCard(part: part),
                const SizedBox(height: 12),

                // ── Description ───────────────────────────────────────
                if (part.description != null && part.description!.isNotEmpty) ...[
                  Text('Description',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(
                    part.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Compatibilité avec le garage (clients uniquement) ─
                if (!isStaff) _GarageCompatibilitySection(partId: part.id),

                // ── Partenaires (visible staff uniquement) ────────────
                PartPartnersSection(partId: part.id),

                // ── Chargement en arrière-plan ────────────────────────
                if (partAsync.isLoading)
                  const LinearProgressIndicator(),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),

      // ── Bouton Commander (clients uniquement) ─────────────────────
      bottomNavigationBar: isStaff ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: inStock
                ? () {
                    ref
                        .read(cartProvider.notifier)
                        .add(CartItem.fromPart(part));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${part.name} ajouté au panier'),
                        behavior: SnackBarBehavior.floating,
                        action: SnackBarAction(
                          label: 'Voir',
                          onPressed: () => context.push('/cart'),
                        ),
                      ),
                    );
                  }
                : null,
            icon: Icon(inCart
                ? Icons.shopping_cart
                : Icons.shopping_cart_outlined),
            label: Text(
              inStock
                  ? (inCart ? 'Ajouter à nouveau' : 'Ajouter au panier')
                  : 'Rupture de stock',
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Carte prix ────────────────────────────────────────────────────────

class _PriceCard extends StatelessWidget {
  final PartPricing pricing;
  const _PriceCard({required this.pricing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prix', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Prix de vente',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  formatXof(pricing.sellingPrice),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Carte stock ───────────────────────────────────────────────────────

class _StockCard extends StatelessWidget {
  final PartStock stock;
  final bool inStock;
  const _StockCard({required this.stock, required this.inStock});

  @override
  Widget build(BuildContext context) {
    final color = inStock
        ? (stock.isLow ? Colors.orange : Colors.green)
        : Colors.red;
    final label = inStock
        ? (stock.isLow
            ? '${stock.quantity} en stock — stock faible'
            : '${stock.quantity} en stock')
        : 'Rupture de stock';

    return Card(
      color: color.withValues(alpha: 0.1),
      child: ListTile(
        leading: Icon(
          inStock ? (stock.isLow ? Icons.warning_amber : Icons.check_circle) : Icons.cancel,
          color: color,
        ),
        title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        subtitle: stock.location != null
            ? Text('Emplacement : ${stock.location}')
            : null,
      ),
    );
  }
}

// ── Carte infos produit ───────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final Part part;
  const _InfoCard({required this.part});

  @override
  Widget build(BuildContext context) {
    final typeLabel      = _typeLabels[part.type] ?? part.type;
    final conditionLabel = _conditionLabels[part.condition] ?? part.condition;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informations', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            _InfoRow('Type',       typeLabel),
            _InfoRow('État',       conditionLabel),
            if (part.categoryName != null)
              _InfoRow('Catégorie',  part.categoryName!),
            if (part.manufacturer != null)
              _InfoRow('Fabricant',  part.manufacturer!),
            // garantie désactivée temporairement
            // if (part.warrantyMonths != null)
            //   _InfoRow('Garantie', '${part.warrantyMonths} mois'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              )),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    ),
  );
}

// ── Section compatibilité garage ──────────────────────────────────────

/// Affiche, pour chaque véhicule du garage du client, si la pièce est compatible.
///
/// Chargée en arrière-plan — silencieuse en cas d'erreur (ex. : utilisateur
/// non connecté via Firebase). Ne bloque pas l'affichage de la fiche.
class _GarageCompatibilitySection extends ConsumerWidget {
  final int partId;
  const _GarageCompatibilitySection({required this.partId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compatAsync = ref.watch(garageCompatibilityProvider(partId));

    return compatAsync.when(
      // Chargement discret — ne pas décaler la mise en page.
      loading: () => const SizedBox.shrink(),
      // Erreur silencieuse (non connecté, réseau, etc.).
      error: (e, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vos véhicules',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, indent: 56, endIndent: 0),
                    _CompatibilityTile(item: items[i]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _CompatibilityTile extends StatelessWidget {
  final GarageCompatibility item;
  const _CompatibilityTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color, String label) = item.compatible
        ? (Icons.check_circle, Colors.green, 'Compatible')
        : item.compatibilityReady
            ? (Icons.cancel, Colors.red, 'Non compatible')
            : (Icons.help_outline, Colors.amber.shade700, 'Non déterminé');

    return ListTile(
      dense: true,
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        '${item.displayName} (${item.year})',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
