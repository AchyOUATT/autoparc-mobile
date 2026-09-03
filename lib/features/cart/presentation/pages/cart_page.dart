import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/cart_item.dart';
import '../../data/order_repository.dart';
import '../providers/cart_provider.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/whatsapp_helper.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ── Page ──────────────────────────────────────────────────────────────

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          items.isEmpty
              ? 'Panier'
              : 'Panier (${items.fold(0, (s, i) => s + i.quantity)})',
        ),
        centerTitle: false,
        actions: [
          if (items.isNotEmpty)
            TextButton.icon(
              onPressed: () => _confirmClear(context, ref),
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: const Text('Vider'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
        ],
      ),
      body: items.isEmpty
          ? const _EmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _CartItemTile(item: items[i]),
                  ),
                ),
                _SummaryCard(items: items),
              ],
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : _CheckoutBar(items: items),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Vider le panier ?'),
        content: const Text('Tous les articles seront retirés.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(cartProvider.notifier).clear();
  }
}

// ── Tuile article ─────────────────────────────────────────────────────

class _CartItemTile extends ConsumerWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs    = Theme.of(context).colorScheme;
    final notif = ref.read(cartProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône type
          CircleAvatar(
            radius: 20,
            backgroundColor: (item.itemType == CartItemType.accessory
                    ? cs.tertiaryContainer
                    : cs.secondaryContainer),
            child: Icon(
              item.itemType == CartItemType.accessory
                  ? Icons.tune_outlined
                  : Icons.settings_outlined,
              size: 18,
              color: item.itemType == CartItemType.accessory
                  ? cs.onTertiaryContainer
                  : cs.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 12),

          // Nom + SKU
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                if (item.sku != null)
                  Text(
                    item.sku!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: cs.outline,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${formatXofShort(item.unitPriceHt)} × ${item.quantity} = '
                  '${formatXof(item.lineTotalHt)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.primary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Contrôles quantité + suppression
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Bouton supprimer
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => notif.remove(item),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16, color: cs.outline),
                ),
              ),
              const SizedBox(height: 4),
              // +/-
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QtyButton(
                    icon: Icons.remove,
                    onTap: () => notif.decrement(item),
                  ),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${item.quantity}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _QtyButton(
                    icon: Icons.add,
                    onTap: () => notif.increment(item),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Icon(icon, size: 14),
    ),
  );
}

// ── Récapitulatif ─────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final List<CartItem> items;
  const _SummaryCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final totalHt  = items.fold(0.0, (s, i) => s + i.lineTotalHt);
    final totalTtc = items.fold(0.0, (s, i) => s + i.lineTotalTtc);
    final tva      = totalTtc - totalHt;
    final cs       = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _SummaryRow('Sous-total HT', formatXof(totalHt)),
          const SizedBox(height: 4),
          _SummaryRow('TVA',           formatXof(tva)),
          const Divider(height: 16),
          _SummaryRow(
            'Total TTC',
            formatXof(totalTtc),
            bold: true,
            color: cs.primary,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;
  const _SummaryRow(this.label, this.value,
      {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: bold ? FontWeight.bold : null,
          color: color,
        ),
      ),
      Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: bold ? FontWeight.bold : null,
          color: color,
        ),
      ),
    ],
  );
}

// ── Barre de commande ─────────────────────────────────────────────────

class _CheckoutBar extends ConsumerStatefulWidget {
  final List<CartItem> items;
  const _CheckoutBar({required this.items});

  @override
  ConsumerState<_CheckoutBar> createState() => _CheckoutBarState();
}

class _CheckoutBarState extends ConsumerState<_CheckoutBar> {
  bool _launching = false;

  @override
  Widget build(BuildContext context) {
    final isStaff = ref.watch(authProvider).isStaff;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: isStaff
            ? Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _launching
                          ? null
                          : () => _openWhatsApp(context),
                      icon: _launching
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chat_outlined, size: 18),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () => _showStaffSheet(context),
                      icon: const Icon(Icons.receipt_long_outlined, size: 18),
                      label: const Text('Facturer'),
                    ),
                  ),
                ],
              )
            : FilledButton.icon(
                onPressed: _launching
                    ? null
                    : () => _openWhatsApp(context),
                icon: _launching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.chat),
                label: Text(_launching ? 'Ouverture…' : 'Commander via WhatsApp'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
      ),
    );
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    setState(() => _launching = true);
    // Capture le messenger avant l'await pour éviter l'async-gap warning.
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchWhatsApp(widget.items);
    if (!mounted) return;
    setState(() => _launching = false);
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('WhatsApp n\'est pas installé sur cet appareil.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showStaffSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _StaffOrderSheet(items: widget.items),
    );
  }
}

// ── Feuille de commande staff ─────────────────────────────────────────

class _StaffOrderSheet extends ConsumerStatefulWidget {
  final List<CartItem> items;
  const _StaffOrderSheet({required this.items});

  @override
  ConsumerState<_StaffOrderSheet> createState() => _StaffOrderSheetState();
}

class _StaffOrderSheetState extends ConsumerState<_StaffOrderSheet> {
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool  _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poignée
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              'Informations client',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom du client *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Champ obligatoire' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                hintText: '+226 xx xx xx xx',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            // Résumé compact
            Text(
              '${widget.items.fold<int>(0, (s, i) => s + i.quantity)} article(s) · '
              '${formatXof(widget.items.fold<double>(0.0, (s, i) => s + i.lineTotalTtc))} TTC',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
              label: Text(_submitting ? 'Envoi en cours…' : 'Confirmer la commande'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final error = await ref.read(orderRepositoryProvider).submitOrder(
      customerName:  _nameCtrl.text,
      customerPhone: _phoneCtrl.text,
      items:         widget.items,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Succès : vider le panier + fermer + notification
      ref.read(cartProvider.notifier).clear();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande enregistrée avec succès ✓'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ── État vide ─────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.shopping_cart_outlined,
          size: 80,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(height: 16),
        Text(
          'Votre panier est vide',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Ajoutez des accessoires ou des pièces\ndepuis le catalogue.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: () => context.go('/accessories'),
              icon: const Icon(Icons.tune_outlined, size: 16),
              label: const Text('Accessoires'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/parts'),
              icon: const Icon(Icons.settings_outlined, size: 16),
              label: const Text('Pièces'),
            ),
          ],
        ),
      ],
    ),
  );
}

// ── Widget réutilisable : icône panier avec badge ─────────────────────

/// À ajouter dans les `actions:` des AppBar qui ont un catalogue commandable.
class CartIconButton extends ConsumerWidget {
  const CartIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider);
    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined),
          tooltip: 'Panier',
          onPressed: () => context.push('/cart'),
        ),
        if (count > 0)
          Positioned(
            top: 6,
            right: 6,
            child: IgnorePointer(
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
