import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/cart_item.dart';
import '../../data/order_repository.dart';
import '../providers/cart_provider.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/whatsapp_helper.dart';
import '../../../../core/contact/autoparc_contact_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../l10n/app_localizations.dart';

// ── Page ──────────────────────────────────────────────────────────────

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          items.isEmpty
              ? l10n.cartTitle
              : l10n.cartTitleCount(items.fold(0, (s, i) => s + i.quantity)),
        ),
        centerTitle: false,
        actions: [
          if (items.isNotEmpty)
            TextButton.icon(
              onPressed: () => _confirmClear(context, ref),
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: Text(l10n.cartClear),
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
      bottomNavigationBar: items.isEmpty ? null : _CheckoutBar(items: items),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.cartClearTitle),
        content: Text(l10n.cartClearBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.cartClear),
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
    final cs = Theme.of(context).colorScheme;
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
                  AppLocalizations.of(context).cartLineTotal(
                    formatXofShort(item.unitPriceHt),
                    item.quantity,
                    formatXof(item.lineTotalHt),
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.primary),
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
    final totalHt = items.fold(0.0, (s, i) => s + i.lineTotalHt);
    final totalTtc = items.fold(0.0, (s, i) => s + i.lineTotalTtc);
    final tva = totalTtc - totalHt;
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _SummaryRow(l10n.cartSubtotalExclTax, formatXof(totalHt)),
          const SizedBox(height: 4),
          _SummaryRow(l10n.cartVat, formatXof(tva)),
          const Divider(height: 16),
          _SummaryRow(
            l10n.cartTotalInclTax,
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
  const _SummaryRow(this.label, this.value, {this.bold = false, this.color});

  // ── LE LIBELLÉ SE REPLIE, LE MONTANT JAMAIS ────────────────────────────
  //
  // Les deux textes étaient posés bruts dans un `Row` : chacun réclamait sa
  // largeur naturelle, et rien ne les repliait. À 320 points et à l'échelle
  // 1,5, les trois lignes du récapitulatif dépassaient —
  //
  //     A RenderFlex overflowed by 26 pixels on the right.
  //
  // EN FRANÇAIS COMME EN ANGLAIS, donc antérieurement à la traduction ; c'est
  // le banc « Les écrans de la vague 2 » qui regarde cet écran pour la
  // première fois. L'anglais y est tout de même plus large — « Subtotal excl.
  // VAT » contre « Sous-total HT » —, et c'est lui qui tombe le premier.
  //
  // `Expanded` SUR LE LIBELLÉ SEUL, et c'est tout l'arbitrage : le libellé est
  // une phrase, il se replie sur deux lignes sans rien perdre ; le montant est
  // un nombre, et un nombre replié dans son segment insécable devient un AUTRE
  // nombre — voir `porteUnNombre` dans test/support/echelles.dart. Il garde
  // donc sa largeur naturelle, et c'est le libellé qui cède.
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: bold ? FontWeight.bold : null,
            color: color,
          ),
        ),
      ),
      const SizedBox(width: 12),
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
    final l10n = AppLocalizations.of(context);

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
                      label: Text(l10n.cartInvoice),
                    ),
                  ),
                ],
              )
            : FilledButton.icon(
                onPressed: _launching ? null : () => _openWhatsApp(context),
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
                label: Text(
                  _launching ? l10n.cartOpening : l10n.cartOrderViaWhatsApp,
                ),
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
    // LE MESSAGE EST LU AVANT L'`await`, POUR LA MÊME RAISON QUE LE MESSENGER :
    // `AppLocalizations.of` lit le `BuildContext`, et le lire après une
    // attente asynchrone est précisément ce que l'avertissement
    // `use_build_context_synchronously` dénonce. La chaîne, elle, ne périme
    // pas : la langue ne peut pas changer pendant le lancement de WhatsApp
    // sans reconstruire tout l'arbre, donc ce widget.
    final l10n = AppLocalizations.of(context);
    final introuvable = l10n.cartWhatsAppMissing;

    // LES CINQ CHAÎNES DU MESSAGE SE LISENT ICI, et pas dans l'utilitaire qui
    // le compose : `buildWhatsAppMessage` n'a pas de `BuildContext` et ne doit
    // pas en avoir, c'est ce qui la rend vérifiable sans monter d'arbre de
    // widgets. Le même arbitrage que `composerMessagePartage`, qui porte sa
    // mention de boutique en paramètre pour la même raison.
    //
    // Les trois intitulés du décompte sont les MÊMES CLÉS que le récapitulatif
    // affiché juste au-dessus : le message dit exactement ce que le client
    // vient de lire, et les deux ne peuvent pas diverger.
    final libelles = LibellesCommande(
      entete: l10n.cartWhatsAppHeader,
      sousTotal: l10n.cartSubtotalExclTax,
      taxe: l10n.cartVat,
      total: l10n.cartTotalInclTax,
      pied: l10n.cartWhatsAppFooter,
    );

    final ok = await launchWhatsApp(
      widget.items,
      libelles,
      contact: ref.read(autoparcContactProvider),
    );
    if (!mounted) return;
    setState(() => _launching = false);
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(introuvable), backgroundColor: Colors.red),
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
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
              l10n.cartCustomerSection,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.cartCustomerName,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.cartFieldRequired
                  : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _phoneCtrl,
              decoration: InputDecoration(
                labelText: l10n.cartCustomerPhone,
                hintText: l10n.cartPhoneHint,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            // Résumé compact
            Text(
              l10n.cartItemCountSummary(
                widget.items.fold<int>(0, (s, i) => s + i.quantity),
                formatXof(
                  widget.items.fold<double>(0.0, (s, i) => s + i.lineTotalTtc),
                ),
              ),
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
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(
                _submitting ? l10n.cartSubmitting : l10n.cartConfirmOrder,
              ),
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

    final error = await ref
        .read(orderRepositoryProvider)
        .submitOrder(
          customerName: _nameCtrl.text,
          customerPhone: _phoneCtrl.text,
          items: widget.items,
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
          SnackBar(
            content: Text(AppLocalizations.of(context).cartOrderSaved),
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
          AppLocalizations.of(context).cartEmptyTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).cartEmptyBody,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // Wrap et non Row : les deux boutons cote a cote ne tiennent pas sur
        // un ecran de 320 points, et moins encore avec les caracteres grossis.
        // Ils passent alors l'un sous l'autre, au lieu de sortir de l'ecran —
        // ce sont les deux seules issues d'un panier vide.
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => context.go('/accessories'),
              icon: const Icon(Icons.tune_outlined, size: 16),
              label: Text(AppLocalizations.of(context).commonAccessories),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/parts'),
              icon: const Icon(Icons.settings_outlined, size: 16),
              label: Text(AppLocalizations.of(context).commonParts),
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
          tooltip: AppLocalizations.of(context).cartTitle,
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
