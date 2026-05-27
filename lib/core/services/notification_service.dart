import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  NotificationService._();

  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static String? _token;

  static String? get fcmToken => _token;

  static const _channel = AndroidNotificationChannel(
    'czechbmx_default',
    'Czech BMX',
    description: 'Novinky a závody Czech BMX',
    importance: Importance.high,
  );

  static bool _initialized = false;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Firebase not configured — push notifications will be unavailable.
      return;
    }
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // iOS: show notification banner even when app is in foreground.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (details) {
        _handlePayload(details.payload);
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    _token = await _messaging.getToken();
    _messaging.onTokenRefresh.listen((token) => _token = token);

    // Foreground messages → local notification on Android (iOS handled natively).
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data['path'] as String?,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handlePayload(message.data['path'] as String?);
    });

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handlePayload(initial.data['path'] as String?);
    }
  }

  // Returns the current FCM token (null if Firebase not configured or unavailable).
  static Future<String?> getToken() async {
    if (!_initialized) return null;
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  // Registers a callback that fires whenever the token is rotated.
  static void onTokenRefresh(void Function(String token) callback) {
    if (!_initialized) return;
    _messaging.onTokenRefresh.listen(callback);
  }

  // Navigate to the path carried in notification payload: "/news/slug" or "/events/42".
  static void _handlePayload(String? path) {
    if (path == null || path.isEmpty) return;
    appNavigatorKey.currentContext?.go(path);
  }
}
