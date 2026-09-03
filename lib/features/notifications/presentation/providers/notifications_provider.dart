import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_notification.dart';
import '../../data/notifications_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Liste complète des notifications (rechargée à la demande).
final notificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) {
  return ref.read(notificationsRepositoryProvider).getNotifications();
});

/// Compteur de non-lus — uniquement pour les clients Firebase.
/// Retourne 0 pour le staff (route Firebase inaccessible avec token Sanctum)
/// et pour les utilisateurs non connectés.
final unreadCountProvider = FutureProvider.autoDispose<int>((ref) {
  final auth = ref.watch(authProvider);
  if (!auth.isClient) return Future.value(0);
  return ref.read(notificationsRepositoryProvider).getUnreadCount();
});
