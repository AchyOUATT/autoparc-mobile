import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import 'models/app_notification.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) {
    final client  = ref.read(apiClientProvider);
    final isStaff = ref.read(authProvider).isStaff;
    return NotificationsRepository(client, isStaff: isStaff);
  },
);

class NotificationsRepository {
  final ApiClient _client;
  final bool _isStaff;

  const NotificationsRepository(this._client, {required bool isStaff})
      : _isStaff = isStaff;

  String get _basePath =>
      _isStaff ? '/notifications' : '/my/notifications';

  Future<List<AppNotification>> getNotifications() async {
    final json = await _client.get(_basePath);
    final list = (json['data'] as List<dynamic>);
    return list
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final json = await _client.get('$_basePath/unread-count');
    return json['count'] as int? ?? 0;
  }

  Future<void> markRead(int id) async {
    await _client.post('$_basePath/$id/read');
  }

  Future<void> markAllRead() async {
    await _client.post('$_basePath/read-all');
  }

  /// Broadcast tip — staff uniquement
  Future<void> broadcastTip({
    required String title,
    required String body,
  }) async {
    await _client.post('/broadcast-tip', data: {
      'title': title,
      'body':  body,
    });
  }
}
