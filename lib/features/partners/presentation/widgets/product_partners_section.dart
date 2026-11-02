import '../../../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/partner.dart';
import '../../data/partner_repository.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/api/api_exception.dart';

// ── Providers ────────────────────────────────────────────────────────

final _partPartnersProvider = FutureProvider.autoDispose
    .family<List<Partner>, int>(
      (ref, partId) =>
          ref.read(partnerRepositoryProvider).getPartnersForPart(partId),
    );

final _accessoryPartnersProvider = FutureProvider.autoDispose
    .family<List<Partner>, int>(
      (ref, accId) =>
          ref.read(partnerRepositoryProvider).getPartnersForAccessory(accId),
    );

// ════════════════════════════════════════════════════════════════════
// Section "Partenaires" pour la fiche d'une pièce (staff uniquement)
// ════════════════════════════════════════════════════════════════════

class PartPartnersSection extends ConsumerWidget {
  final int partId;
  const PartPartnersSection({super.key, required this.partId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(authProvider).isStaff) return const SizedBox.shrink();

    return _PartnersSection(
      asyncValue: ref.watch(_partPartnersProvider(partId)),
      onRefresh: () => ref.invalidate(_partPartnersProvider(partId)),
      onDetach: (partnerId) async {
        await ref
            .read(partnerRepositoryProvider)
            .detachFromPart(partId, partnerId);
        ref.invalidate(_partPartnersProvider(partId));
      },
      onAttach: (partnerId, role, notes) async {
        await ref
            .read(partnerRepositoryProvider)
            .attachToPart(
              partId: partId,
              partnerId: partnerId,
              role: role,
              notes: notes,
            );
        ref.invalidate(_partPartnersProvider(partId));
      },
    );
  }
}

/// Section "Partenaires" pour la fiche d'un accessoire (staff uniquement).
class AccessoryPartnersSection extends ConsumerWidget {
  final int accessoryId;
  const AccessoryPartnersSection({super.key, required this.accessoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(authProvider).isStaff) return const SizedBox.shrink();

    return _PartnersSection(
      asyncValue: ref.watch(_accessoryPartnersProvider(accessoryId)),
      onRefresh: () => ref.invalidate(_accessoryPartnersProvider(accessoryId)),
      onDetach: (partnerId) async {
        await ref
            .read(partnerRepositoryProvider)
            .detachFromAccessory(accessoryId, partnerId);
        ref.invalidate(_accessoryPartnersProvider(accessoryId));
      },
      onAttach: (partnerId, role, notes) async {
        await ref
            .read(partnerRepositoryProvider)
            .attachToAccessory(
              accessoryId: accessoryId,
              partnerId: partnerId,
              role: role,
              notes: notes,
            );
        ref.invalidate(_accessoryPartnersProvider(accessoryId));
      },
    );
  }
}

// ── Widget commun ────────────────────────────────────────────────────

typedef _AttachFn =
    Future<void> Function(int partnerId, String? role, String? notes);
typedef _DetachFn = Future<void> Function(int partnerId);

class _PartnersSection extends ConsumerWidget {
  final AsyncValue<List<Partner>> asyncValue;
  final VoidCallback onRefresh;
  final _DetachFn onDetach;
  final _AttachFn onAttach;

  const _PartnersSection({
    required this.asyncValue,
    required this.onRefresh,
    required this.onDetach,
    required this.onAttach,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    // L'annuaire se consulte par tout le personnel ; l'associer a un produit
    // reste a la direction.
    final canEdit = ref.watch(authProvider).canManagePartners;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              // Expanded tient le rôle du Spacer qui suivait, et contraint en
              // plus le titre : brut, il réclamait toute sa largeur naturelle
              // et poussait le bouton hors de l'écran.
              Expanded(
                child: Text(
                  AppLocalizations.of(context).shellPartners,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (canEdit)
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(AppLocalizations.of(context).partnersAttach),
                  onPressed: () => _showAttachDialog(context, ref),
                ),
            ],
          ),
        ),
        asyncValue.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              messageFor(e, l10n: AppLocalizations.of(context)),
              style: TextStyle(color: cs.error),
            ),
          ),
          data: (partners) {
            if (partners.isEmpty) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  AppLocalizations.of(context).partnersNoLinkedPartners,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.outline),
                ),
              );
            }
            return Column(
              children: partners
                  .map(
                    (p) => _PartnerRow(
                      partner: p,
                      onDetach: () => onDetach(p.id),
                      canDetach: canEdit,
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const Divider(height: 1),
      ],
    );
  }

  Future<void> _showAttachDialog(BuildContext context, WidgetRef ref) async {
    // Charger l'annuaire
    final all = await ref
        .read(partnerRepositoryProvider)
        .getPartners(perPage: 100);
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) =>
          _AttachPartnerDialog(partenaires: all.data, onAttach: onAttach),
    );
  }
}

/// Les contrôleurs appartiennent à la boîte, pas à la fonction qui l'ouvre.
///
/// Ils étaient créés avant `showDialog` et détruits juste après. Or
/// `showDialog` rend la main dès le `Navigator.pop` : la boîte s'anime encore,
/// ses champs sont toujours montés, et le clavier qui se referme suffit à les
/// faire se réabonner à des contrôleurs détruits — « A TextEditingController
/// was used after being disposed », puis un écran rouge.
///
/// Le même défaut a été trouvé sur la boîte de kilométrage, où il produisait
/// le plantage intermittent qu'on n'arrivait pas à reproduire. Voir
/// mileage_dialog.dart et son test.
class _AttachPartnerDialog extends StatefulWidget {
  final List<Partner> partenaires;
  final _AttachFn onAttach;

  const _AttachPartnerDialog({
    required this.partenaires,
    required this.onAttach,
  });

  @override
  State<_AttachPartnerDialog> createState() => _AttachPartnerDialogState();
}

class _AttachPartnerDialogState extends State<_AttachPartnerDialog> {
  final _roleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  Partner? _selected;

  @override
  void dispose() {
    _roleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).partnersAttachTitle),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Partner>(
              initialValue: _selected,
              // Le nom d'un partenaire peut etre long : sans isExpanded, le
              // menu prend la largeur du plus long et deborde de la boite de
              // dialogue. L'ellipse posee sur l'item ne s'applique qu'une fois
              // la largeur contrainte.
              isExpanded: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).partnersPartnerRequired,
                prefixIcon: Icon(Icons.handshake_outlined),
              ),
              items: widget.partenaires
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        p.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (p) => setState(() => _selected = p),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _roleCtrl,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).partnersRoleOptional,
                hintText: AppLocalizations.of(context).partnersRoleHint,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).partnersNotesOptional,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).commonCancel),
        ),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () {
                  // Le texte se lit avant de fermer : apres le pop, la boite
                  // s'anime encore mais son etat peut etre detruit a tout
                  // moment.
                  final role = _roleCtrl.text.trim();
                  final notes = _notesCtrl.text.trim();
                  final id = _selected!.id;

                  Navigator.pop(context);
                  widget.onAttach(
                    id,
                    role.isEmpty ? null : role,
                    notes.isEmpty ? null : notes,
                  );
                },
          child: Text(AppLocalizations.of(context).partnersAttach),
        ),
      ],
    );
  }
}

// ── Ligne d'un partenaire ─────────────────────────────────────────────

class _PartnerRow extends StatelessWidget {
  final Partner partner;
  final VoidCallback onDetach;

  /// Faux pour un role qui consulte l'annuaire sans pouvoir le modifier.
  final bool canDetach;

  const _PartnerRow({
    required this.partner,
    required this.onDetach,
    required this.canDetach,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: cs.secondaryContainer,
        child: Text(
          partner.companyName[0].toUpperCase(),
          style: TextStyle(
            color: cs.onSecondaryContainer,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(partner.companyName, style: const TextStyle(fontSize: 14)),
      subtitle: partner.role != null
          ? Text(partner.role!, style: Theme.of(context).textTheme.bodySmall)
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // WhatsApp
          IconButton(
            icon: const Icon(Icons.chat_outlined, size: 18),
            color: const Color(0xFF25D366),
            tooltip: 'WhatsApp',
            onPressed: () => _launchWhatsApp(partner.whatsapp ?? partner.phone),
          ),
          // Appel
          IconButton(
            icon: const Icon(Icons.phone_outlined, size: 18),
            color: cs.primary,
            tooltip: AppLocalizations.of(context).catalogCallAction,
            onPressed: () => _launchPhone(partner.phone),
          ),
          // Retirer
          if (canDetach)
            IconButton(
              icon: const Icon(Icons.link_off, size: 18),
              color: cs.error,
              tooltip: AppLocalizations.of(context).partnersRemove,
              onPressed: () => _confirmDetach(context),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDetach(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context).partnersRemoveQuestion),
        content: Text(
          AppLocalizations.of(
            context,
          ).partnersRemoveDescription(partner.companyName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).partnersRemove),
          ),
        ],
      ),
    );
    if (ok == true) onDetach();
  }

  void _launchPhone(String number) {
    launchUrl(Uri.parse('tel:$number'));
  }

  void _launchWhatsApp(String number) {
    final cleaned = number.replaceAll(RegExp(r'[^\d+]'), '');
    launchUrl(Uri.parse('https://wa.me/$cleaned'));
  }
}
