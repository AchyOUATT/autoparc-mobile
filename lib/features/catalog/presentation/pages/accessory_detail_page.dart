import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/accessory.dart';
import '../../data/catalog_repository.dart';
import '../providers/catalog_providers.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../features/cart/data/models/cart_item.dart';
import '../../../../features/cart/presentation/pages/cart_page.dart';
import '../../../../features/cart/presentation/providers/cart_provider.dart';
import '../../../../features/partners/presentation/widgets/product_partners_section.dart';
import '../../../../core/api/api_exception.dart';

class AccessoryDetailPage extends ConsumerWidget {
  final int accessoryId;
  final Accessory? initialAccessory;

  const AccessoryDetailPage({
    super.key,
    required this.accessoryId,
    this.initialAccessory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(accessoryDetailProvider(accessoryId));
    final accessory   = detailAsync.valueOrNull ?? initialAccessory;

    if (accessory == null) {
      return Scaffold(
        appBar: AppBar(),
        body: detailAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text(messageFor(e))),
          data:    (_) => const SizedBox.shrink(),
        ),
      );
    }

    return _AccessoryDetailView(accessory: accessory);
  }
}

class _AccessoryDetailView extends ConsumerWidget {
  final Accessory accessory;
  const _AccessoryDetailView({required this.accessory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs      = Theme.of(context).colorScheme;
    final auth    = ref.watch(authProvider);
    final isStaff = auth.isStaff;
    final p       = accessory.pricing;

    Future<void> deleteAccessory() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Supprimer cet accessoire ?'),
          content: Text('« ${accessory.name} » sera supprimé définitivement.'),
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
        await ref.read(catalogRepositoryProvider).deleteAccessory(accessory.id);
        ref.invalidate(accessoryListProvider);
        if (context.mounted) context.pop();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(messageFor(e)), backgroundColor: cs.error),
          );
        }
      }
    }
    final s       = accessory.stock;
    final inCart  = ref.watch(cartProvider.select(
      (items) => items.any(
        (i) => i.id == accessory.id && i.itemType == CartItemType.accessory,
      ),
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text(accessory.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          // Badge catégorie
          Chip(
            label: Text(accessory.categoryLabel,
                style: const TextStyle(fontSize: 11)),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          if (auth.canManageCatalog)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Modifier',
              onPressed: () => context
                  .push('/accessories/${accessory.id}/edit', extra: accessory)
                  .then((_) => ref.invalidate(accessoryDetailProvider(accessory.id))),
            ),
          if (auth.canDeleteCatalog)
            IconButton(
              icon: Icon(Icons.delete_outline, color: cs.error),
              tooltip: 'Supprimer',
              onPressed: deleteAccessory,
            ),
          if (!isStaff) const CartIconButton(),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Placeholder image ─────────────────────────────────
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _categoryIcon(accessory.categoryValue),
              size: 72,
              color: cs.primary.withAlpha(180),
            ),
          ),
          const SizedBox(height: 20),

          // ── Prix ──────────────────────────────────────────────
          _PriceCard(pricing: p),
          const SizedBox(height: 20),

          // ── Stock ─────────────────────────────────────────────
          _StockCard(stock: s),
          const SizedBox(height: 20),

          // ── Informations ──────────────────────────────────────
          Text('Informations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 10),
          if (accessory.sku != null) _InfoRow('SKU', accessory.sku!),
          if (accessory.manufacturer != null)
            _InfoRow('Fabricant',  accessory.manufacturer!),
          // garantie désactivée temporairement
          // if (accessory.warrantyMonths != null)
          //   _InfoRow('Garantie', '${accessory.warrantyMonths} mois'),
          if (accessory.description != null && accessory.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Description',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(accessory.description!,
                style: Theme.of(context).textTheme.bodyMedium),
          ],

          // ── Partenaires (visible staff uniquement) ────────────
          AccessoryPartnersSection(accessoryId: accessory.id),

          const SizedBox(height: 80),
        ],
      ),

      // ── Bouton commander (clients uniquement) ─────────────────
      bottomNavigationBar: isStaff ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: s.quantity > 0
                ? () {
                    ref
                        .read(cartProvider.notifier)
                        .add(CartItem.fromAccessory(accessory));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${accessory.name} ajouté au panier'),
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
                : Icons.add_shopping_cart),
            label: Text(
              s.quantity > 0
                  ? (inCart ? 'Ajouter à nouveau' : 'Ajouter au panier')
                  : 'Indisponible',
            ),
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) => switch (category) {
    'esthetique' => Icons.auto_awesome,
    'confort'    => Icons.airline_seat_recline_normal,
    'securite'   => Icons.shield,
    'multimedia' => Icons.speaker,
    'utilitaire' => Icons.build,
    _            => Icons.tune,
  };
}

// ── Carte prix ─────────────────────────────────────────────────────

class _PriceCard extends StatelessWidget {
  final AccessoryPricing pricing;
  const _PriceCard({required this.pricing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        formatXof(pricing.sellingPrice),
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: cs.primary,
        ),
      ),
    );
  }
}

// ── Carte stock ────────────────────────────────────────────────────

class _StockCard extends StatelessWidget {
  final AccessoryStock stock;
  const _StockCard({required this.stock});

  @override
  Widget build(BuildContext context) {
    final inStock = stock.quantity > 0;
    final color   = inStock ? Colors.green.shade700 : Colors.red.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(80)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(inStock ? Icons.check_circle : Icons.cancel, color: color),
          const SizedBox(width: 12),
          Text(
            inStock ? '${stock.quantity} en stock' : 'Rupture de stock',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (stock.isLow && inStock) ...[
            const Spacer(),
            Chip(
              label: const Text('Stock bas', style: TextStyle(fontSize: 11)),
              backgroundColor: Colors.orange.shade100,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Helper UI ──────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              )),
        ),
        Expanded(
          child: Text(value,
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    ),
  );
}
