import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../api/api_client.dart';

// ── Handler background (top-level obligatoire) ────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Pas besoin d'initialiser Firebase ici — flutter_local_notifications
  // affichera la notification via le système Android automatiquement.
  debugPrint('[FCM] Background message: ${message.messageId}');
}

// ── Canal Android ─────────────────────────────────────────────────────
const _androidChannel = AndroidNotificationChannel(
  'autoparc_high',          // id
  'AutoParc — Notifications', // name
  description: 'Notifications importantes AutoParc',
  importance: Importance.high,
);

// ════════════════════════════════════════════════════════════════════

class FcmAppService {
  FcmAppService._();
  static final FcmAppService instance = FcmAppService._();

  final _messaging    = FirebaseMessaging.instance;
  final _localNotifs  = FlutterLocalNotificationsPlugin();

  /// Callback appelé quand l'utilisateur tape une notification
  /// (reçue en background ou quand l'app était fermée).
  /// Fournit le payload `data` du message.
  ValueChanged<Map<String, dynamic>>? onNotificationTap;

  // ── Initialisation ────────────────────────────────────────────────

  Future<void> initialize({
    required ApiClient apiClient,
    ValueChanged<Map<String, dynamic>>? onTap,
  }) async {
    onNotificationTap = onTap;

    // 1. Handler background (doit être top-level)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Demande la permission (Android 13+ / iOS)
    final settings = await _messaging.requestPermission(
      alert:         true,
      badge:         true,
      sound:         true,
      announcement:  false,
      criticalAlert: false,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // 3. Création du canal Android haute priorité
    await _localNotifs
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // 4. Init flutter_local_notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS:     DarwinInitializationSettings(),
    );
    await _localNotifs.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload != null
            ? Map<String, dynamic>.from(
                jsonDecode(resp.payload!) as Map)
            : <String, dynamic>{};
        onNotificationTap?.call(payload);
      },
    );

    // 5. Messages foreground → afficher la notif localement
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // 6. Tap sur notif quand app en background (pas fermée)
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      onNotificationTap?.call(Map<String, dynamic>.from(msg.data));
    });

    // 7. Vérification si l'app a été ouverte via une notif (app fermée)
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      // Légère pause pour laisser le routeur s'initialiser
      Future.delayed(const Duration(milliseconds: 500), () {
        onNotificationTap?.call(Map<String, dynamic>.from(initial.data));
      });
    }

    // 8. Enregistrement du token FCM
    await _registerToken(apiClient);

    // 9. Rafraîchissement automatique du token
    _messaging.onTokenRefresh.listen(
      (token) => _saveToken(apiClient, token),
    );
  }

  // ── Affichage local (foreground) ─────────────────────────────────

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;

    await _localNotifs.show(
      message.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority:   Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ── Enregistrement du token ────────────────────────────────────────

  Future<void> _registerToken(ApiClient apiClient) async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await _saveToken(apiClient, token);
  }

  Future<void> _saveToken(ApiClient apiClient, String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Client Firebase connecté
        await apiClient.post('/fcm-token/client', data: {
          'firebase_uid': user.uid,
          'fcm_token':    token,
        });
      } else {
        // Staff connecté via Sanctum — le token Sanctum est déjà dans ApiClient
        // Essai silencieux ; si pas authentifié, 401 ignoré
        try {
          await apiClient.post('/fcm-token', data: {'fcm_token': token});
        } catch (_) {}
      }

      debugPrint('[FCM] Token enregistré');
    } catch (e) {
      debugPrint('[FCM] Erreur enregistrement token : $e');
    }
  }
}
