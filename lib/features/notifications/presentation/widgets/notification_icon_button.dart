import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/notifications_provider.dart';

/// Icône cloche avec badge du nombre de notifications non lues.
/// À placer dans les `actions` d'un AppBar.
class NotificationIconButton extends ConsumerWidget {
  const NotificationIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;

    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => context.push('/notifications'),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(
          unread > 99 ? '99+' : '$unread',
          style: const TextStyle(fontSize: 10),
        ),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
