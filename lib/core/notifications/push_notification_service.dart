import 'dart:developer' as dev;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../network/dio_client.dart';
import '../router/app_router.dart';

/// Background handler — must be a top-level function.
/// Runs in its own isolate: keep it dependency-free (no router/nav here).
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  dev.log(
    '[Push] Background message id=${message.messageId} data=${message.data}',
    name: 'Push',
  );
  final notification = message.notification;
  if (notification != null) {
    final local = FlutterLocalNotificationsPlugin();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await local.initialize(settings: settings);
    await _showHeadsUp(
      local,
      title: notification.title ?? 'Makkal Velicham',
      body: notification.body ?? '',
      postId: message.data['post_id']?.toString(),
    );
  }
}

Future<void> _showHeadsUp(
  FlutterLocalNotificationsPlugin local, {
  required String title,
  required String body,
  String? postId,
}) async {
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      PushService.channelId,
      'Breaking news',
      channelDescription: 'Breaking news alerts from Makkal Velicham',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );
  await local.show(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title: title,
    body: body,
    notificationDetails: details,
    payload: postId,
  );
}

/// Expected backend payload contract (Phase 2 sender must follow this):
///   notification: { title, body }
///   data: { type: 'breaking', post_id: 'post-id-here' }
class PushService {
  PushService._();

  static const channelId = 'breaking_news';

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  /// Post id from the last tapped notification. The home feed shows the
  /// breaking post at the top; a jump-to-article can consume this later.
  static String? pendingPostId;

  static bool _ready = false;
  static bool get isReady => _ready;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      dev.log('[Push] Firebase initialized', name: 'Push');

      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _local.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (response) {
          _onTap(response.payload);
        },
      );

      const channel = AndroidNotificationChannel(
        channelId,
        'Breaking news',
        description: 'Breaking news alerts from Makkal Velicham',
        importance: Importance.high,
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      final permission = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      dev.log(
        '[Push] Permission: ${permission.authorizationStatus}',
        name: 'Push',
      );

      final token = await messaging.getToken();
      if (token == null) {
        dev.log('[Push] ERROR: FCM token is null', name: 'Push');
      } else {
        dev.log(
          '[Push] FCM token: ${token.substring(0, 20)}... (len=${token.length})',
          name: 'Push',
        );
        await _sendTokenToBackend(token);
      }

      messaging.onTokenRefresh.listen((newToken) async {
        dev.log('[Push] Token refreshed, re-syncing', name: 'Push');
        await _sendTokenToBackend(newToken);
      });

      FirebaseMessaging.onMessage.listen((message) async {
        dev.log(
          '[Push] Foreground message id=${message.messageId} '
          'title=${message.notification?.title} data=${message.data}',
          name: 'Push',
        );
        final notification = message.notification;
        if (notification != null) {
          await _showHeadsUp(
            _local,
            title: notification.title ?? 'Makkal Velicham',
            body: notification.body ?? '',
            postId: message.data['post_id']?.toString(),
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        dev.log(
          '[Push] Opened from background id=${message.messageId} data=${message.data}',
          name: 'Push',
        );
        _onTap(message.data['post_id']?.toString());
      });

      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        dev.log(
          '[Push] Launched from terminated via id=${initial.messageId} data=${initial.data}',
          name: 'Push',
        );
        _onTap(initial.data['post_id']?.toString());
      }

      _ready = true;
    } catch (e, s) {
      dev.log('[Push] init failed: $e', name: 'Push', error: e, stackTrace: s);
    }
  }

  static void _onTap(String? postId) {
    pendingPostId = postId;
    dev.log('[Push] Tap post_id=$postId → /home', name: 'Push');
    appRouter.go(AppRoutes.home);
  }

  /// Sends the FCM token to the backend (endpoint lands in Phase 2:
  /// POST /api/v1/device-tokens). Fails soft until then.
  static Future<void> _sendTokenToBackend(String token) async {
    try {
      final dio = DioClient();
      final res = await dio.post<Map<String, dynamic>>(
        '/api/v1/device-tokens',
        data: {'token': token, 'platform': 'android'},
      );
      dev.log(
        '[Push] Token synced status=${res.statusCode}',
        name: 'Push',
      );
    } catch (e) {
      dev.log(
        '[Push] Token sync skipped (backend endpoint pending Phase 2): $e',
        name: 'Push',
      );
    }
  }

  /// Public re-sync, e.g. after login so the token links to the user.
  static Future<void> syncToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _sendTokenToBackend(token);
    } catch (e) {
      dev.log('[Push] syncToken failed: $e', name: 'Push');
    }
  }
}
