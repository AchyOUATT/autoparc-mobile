import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../notifications/data/models/app_notification.dart';
import '../data/partner_repository.dart';

/// La boîte aux lettres du partenaire.
///
/// ── POURQUOI UN ÉCRAN À PART DE CELUI DU PERSONNEL ────────────────────────
///
/// Ce ne sont pas les mêmes routes, pas le même jeton, pas le même coffre.
/// L'espace partenaire a son propre `PartnerRepository`, son propre
/// `partner_sanctum_token`, et ses routes vivent sous `/api/partner/`. Faire
/// passer l'écran du personnel par ce dépôt reviendrait à lui donner deux
/// sources d'authentification selon qui regarde — et c'est exactement le genre
/// de branchement qui finit par envoyer le mauvais jeton.
///
/// ── CE QU'UN PARTENAIRE Y LIT ─────────────────────────────────────────────
///
/// Les demandes clients que le personnel a approuvées et diffusées : le type,
/// la description, le budget et les critères.
///
/// PAS le contact du client. Il ne part pas du serveur — voir
/// `CustomerNeedController::pourPartenaire()` — et c'est délibéré : ce client
/// s'est adressé à la boutique, pas à quinze vendeurs. Le partenaire répond à
/// la boutique, qui rappelle le client.
final partnerNotificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final page = await ref.watch(partnerRepositoryProvider).notifications();

  return page
      .map((brut) => AppNotification.fromJson(Map<String, dynamic>.from(brut)))
      .toList();
});

/// Le compteur de non-lues, pour la pastille de l'espace partenaire.
final partnerUnreadCountProvider = FutureProvider.autoDispose<int>((ref) =>
    ref.watch(partnerRepositoryProvider).notificationsNonLues());

class PartnerNotificationsPage extends ConsumerWidget {
  const PartnerNotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(partnerNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes clients'),
        actions: [
          notifs.maybeWhen(
            data: (liste) => liste.any((n) => !n.isRead)
                ? TextButton(
                    key: const Key('partner-notifs-tout-lire'),
                    onPressed: () async {
                      await ref.read(partnerRepositoryProvider).marquerToutLu();
                      ref.invalidate(partnerNotificationsProvider);
                      ref.invalidate(partnerUnreadCountProvider);
                    },
                    child: const Text('Tout lire'),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () {
              ref.invalidate(partnerNotificationsProvider);
              ref.invalidate(partnerUnreadCountProvider);
            },
          ),
        ],
      ),
      body: notifs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (erreur, _) => _Erreur(
          message: messageFor(erreur),
          onRetry: () => ref.invalidate(partnerNotificationsProvider),
        ),
        data: (liste) => liste.isEmpty
            ? const _Vide()
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(partnerNotificationsProvider);
                  ref.invalidate(partnerUnreadCountProvider);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: liste.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _Ligne(notification: liste[index]),
                ),
              ),
      ),
    );
  }
}

class _Ligne extends ConsumerWidget {
  const _Ligne({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couleurs = Theme.of(context).colorScheme;
    final besoin = notification.data?['besoin'];

    return ListTile(
      key: ValueKey('partner-notif-${notification.id}'),
      leading: CircleAvatar(
        backgroundColor: Color(notification.iconColor).withValues(alpha: 0.15),
        child: Icon(notification.iconData, color: Color(notification.iconColor)),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w700,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.body),
          if (besoin is Map) ...[
            const SizedBox(height: 4),
            Text(
              _criteres(Map<String, dynamic>.from(besoin)),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: couleurs.onSurfaceVariant),
            ),
          ],
        ],
      ),
      isThreeLine: besoin is Map,
      trailing: notification.isRead
          ? null
          : Container(
              key: const Key('partner-notif-pastille'),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: couleurs.primary,
                shape: BoxShape.circle,
              ),
            ),
      onTap: notification.isRead
          ? null
          : () async {
              await ref
                  .read(partnerRepositoryProvider)
                  .marquerLu(notification.id);
              ref.invalidate(partnerNotificationsProvider);
              ref.invalidate(partnerUnreadCountProvider);
            },
    );
  }

  /// Les critères en une ligne, dans l'ordre où un vendeur les cherche.
  ///
  /// Rien n'est inventé : un critère absent ne laisse pas de trace, pas même
  /// un séparateur orphelin — c'est le défaut que la ligne à trois valeurs des
  /// fiches véhicule avait payé.
  String _criteres(Map<String, dynamic> besoin) => [
        besoin['brand_name'],
        besoin['vehicle_model_name'],
        besoin['part_category_name'],
        besoin['oem_number'],
        besoin['need_manufacturer_name'],
        besoin['accessory_category'],
      ].whereType<String>().where((v) => v.trim().isNotEmpty).join(' · ');
}

class _Vide extends StatelessWidget {
  const _Vide();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              const Text(
                'Aucune demande pour le moment.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Les demandes des clients vous parviennent ici dès que la '
                'boutique les transmet.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
}

class _Erreur extends StatelessWidget {
  const _Erreur({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
}
