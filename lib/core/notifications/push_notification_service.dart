import 'dart:developer' as dev;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../network/dio_client.dart';

class PushService {
  static String channelId = 'breaking_news_channel';

  // Static state - accessed from static methods
  static bool _ready = false;
  static String? pendingPostId;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  /// Background handler — must be a top-level function.
  /// Runs in its own isolate: keep it dependency-free (no router/nav here).
  @pragma('vm:entry-point')
  static Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
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

  static Future<void> _showHeadsUp(
    FlutterLocalNotificationsPlugin local, {
    required String title,
    required String body,
    String? postId,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
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

  static Future<void> init() async {
    try {
      dev.log('[Push] Initializing PushService', name: 'Push');

      // Request permission on first launch
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      dev.log(
        '[Push] User requested permission status: ${settings.authorizationStatus}',
        name: 'Push',
      );

      final token = await messaging.getToken();
      if (token != null) {
        dev.log(
          '[Push] FCM token obtained: ${token.substring(0, 20)}... (len=${token.length})',
          name: 'Push',
        );
        await _sendTokenToBackend(token);
      }

      // Set up message listeners
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

      // Handle opened from background/terminated
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
    } catch (e, s) {
      dev.log('[Push] init failed: $e', name: 'Push', error: e, stackTrace: s);
    }
  }

  static Future<void> syncToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _sendTokenToBackend(token);
    } catch (e) {
      dev.log('[Push] syncToken failed: $e', name: 'Push');
    }
  }

  /// Request notification permission contextually and sync FCM token.
  static Future<void> requestPermission() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      dev.log(
        '[Push] User requested permission status: ${settings.authorizationStatus}',
        name: 'Push',
      );

      final token = await messaging.getToken();
      if (token != null) {
        dev.log(
          '[Push] FCM token obtained: ${token.substring(0, 20)}... (len=${token.length})',
          name: 'Push',
        );
        await _sendTokenToBackend(token);
      }
    } catch (e, s) {
      dev.log('[Push] requestPermission error: $e', name: 'Push', error: e, stackTrace: s);
    }
  }

  static String getPermanentDenialInstructions() {
    return '''
Permission permanently denied. 
To re-enable notifications:
1. Go to your device Settings
2. Navigate to {app_name} > Notifications
3. Toggle "Allow notifications" back on
''';
  }

  static void resetPermissionExplained() {
    // Permission explained flag management
  }

  static void clearPendingPostId() {
    pendingPostId = null;
  }

  static void logout() {
    pendingPostId = null;
    dev.log('[Push] User logged out - token disassociated', name: 'Push');
  }

  static void _onTap(String? postId) {
    pendingPostId = postId;
    dev.log('[Push] Tap post_id=$postId → /home', name: 'Push');
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
}