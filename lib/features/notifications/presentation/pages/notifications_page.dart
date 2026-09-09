import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/models/app_notification.dart';
import '../../data/notifications_repository.dart';
import '../providers/notifications_provider.dart';

// ════════════════════════════════════════════════════════════════════

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);
    final isStaff     = ref.watch(authProvider).isStaff;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: false,
        actions: [
          // Bouton "tout marquer comme lu"
          notifsAsync.maybeWhen(
            data: (list) {
              final hasUnread = list.any((n) => !n.isRead);
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () async {
                  await ref
                      .read(notificationsRepositoryProvider)
                      .markAllRead();
                  ref.invalidate(notificationsProvider);
                  ref.invalidate(unreadCountProvider);
                },
                child: const Text('Tout lire'),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          // Bouton broadcast (staff uniquement)
          if (isStaff)
            IconButton(
              icon: const Icon(Icons.campaign_outlined),
              tooltip: 'Envoyer un conseil',
              onPressed: () => _showBroadcastSheet(context, ref),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadCountProvider);
            },
          ),
        ],
      ),
      body: notifsAsync.when(
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
                onPressed: () => ref.invalidate(notificationsProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (notifs) => notifs.isEmpty
            ? _EmptyNotifications()
            : ListView.separated(
                itemCount: notifs.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (_, i) => _NotificationTile(
                  notif: notifs[i],
                  onRead: () {
                    ref.invalidate(notificationsProvider);
                    ref.invalidate(unreadCountProvider);
                  },
                ),
              ),
      ),
    );
  }

  Future<void> _showBroadcastSheet(
      BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _BroadcastSheet(ref: ref),
    );
  }
}

// ── Tuile de notification ─────────────────────────────────────────────

class _NotificationTile extends ConsumerWidget {
  final AppNotification notif;
  final VoidCallback onRead;

  const _NotificationTile({required this.notif, required this.onRead});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(notif.iconColor);

    return ListTile(
      tileColor: notif.isRead
          ? null
          : Theme.of(context).colorScheme.primaryContainer.withAlpha(40),
      leading: CircleAvatar(
        backgroundColor: color.withAlpha(30),
        child: Icon(
          notif.iconData,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        notif.title,
        style: TextStyle(
          fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notif.body, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (notif.createdAt != null)
            Text(
              _formatDate(notif.createdAt!),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
        ],
      ),
      isThreeLine: true,
      trailing: notif.isRead
          ? null
          : Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
      onTap: () => _handleTap(context, ref),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    // Marquer comme lu
    if (!notif.isRead) {
      await ref.read(notificationsRepositoryProvider).markRead(notif.id);
      onRead();
    }
    // Navigation selon le type
    _navigate(context, notif);
  }

  void _navigate(BuildContext context, AppNotification notif) {
    final data = notif.data ?? {};
    switch (notif.type) {
      case 'new_need':
      case 'need_status_update':
        context.push('/needs');
      case 'vehicle_match':
        final vehicleId = int.tryParse(data['vehicle_id']?.toString() ?? '');
        if (vehicleId != null) context.push('/vehicles/$vehicleId');

      // Rappels d'entretien. La destination dépend de ce que le propriétaire
      // a réellement à faire : une vidange se règle en achetant des pièces,
      // une assurance ou une visite technique se règle ailleurs — il revient
      // alors au garage pour saisir la nouvelle date.
      case 'maintenance_service':
        final ownedId = int.tryParse(data['owned_vehicle_id']?.toString() ?? '');
        // Pas de catégorie imposée : une vidange demande l'huile *et* le
        // filtre, en pré-filtrer une seule masquerait l'autre.
        context.push(ownedId != null ? '/garage/$ownedId/parts' : '/garage');

      case 'maintenance_technical_inspection':
      case 'maintenance_insurance':
        context.push('/garage');
      case 'new_order':
        // Selon order_type, on pourrait naviguer vers la commande
        // Pour l'instant, pas encore de page de détail commande
        break;
      case 'tip':
        // Pas de navigation spécifique
        break;
    }
  }

  String _formatDate(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

// ── Vue vide ──────────────────────────────────────────────────────────

class _EmptyNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.notifications_none_outlined,
            size: 64, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Text('Aucune notification',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text('Vous serez notifié ici des activités importantes.',
            textAlign: TextAlign.center),
      ],
    ),
  );
}

// ── Sheet broadcast tip ───────────────────────────────────────────────

class _BroadcastSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _BroadcastSheet({required this.ref});

  @override
  ConsumerState<_BroadcastSheet> createState() => _BroadcastSheetState();
}

class _BroadcastSheetState extends ConsumerState<_BroadcastSheet> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();
  bool _sending    = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Titre et message sont obligatoires.')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(notificationsRepositoryProvider).broadcastTip(
        title: _titleCtrl.text.trim(),
        body:  _bodyCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conseil envoyé à tous les clients ✓'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.campaign_outlined, size: 22),
              const SizedBox(width: 8),
              Text('Conseil aux propriétaires',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ce message sera envoyé par notification push à tous les clients de l\'app.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Titre *',
              hintText: 'Ex. : Vérifiez votre pression des pneus',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLength: 100,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtrl,
            decoration: const InputDecoration(
              labelText: 'Message *',
              hintText:
                  'Ex. : Une bonne pression de gonflage améliore la durée de vie des pneus de 20 %…',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_outlined),
            label: const Text('Envoyer à tous les clients'),
          ),
        ],
      ),
    );
  }
}
