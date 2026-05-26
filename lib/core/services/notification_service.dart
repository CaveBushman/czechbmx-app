// PUSH NOTIFICATIONS — SETUP CHECKLIST
//
// Before enabling this service:
//
//  1. Create a Firebase project at https://console.firebase.google.com/
//  2. Add Android app (package: cz.czechbmx.app) → download google-services.json
//     → place at:  android/app/google-services.json
//  3. Add iOS app (bundle: cz.czechbmx.app) → download GoogleService-Info.plist
//     → place at:  ios/Runner/GoogleService-Info.plist
//  4. Add to pubspec.yaml:
//       firebase_core: ^3.x.x
//       firebase_messaging: ^15.x.x
//       flutter_local_notifications: ^17.x.x
//  5. In android/app/build.gradle.kts add:
//       plugins { id("com.google.gms.google-services") }
//  6. In android/build.gradle.kts add to dependencies:
//       classpath("com.google.gms:google-services:4.4.2")
//  7. Add INTERNET permission to AndroidManifest.xml (if not already present)
//  8. Uncomment the code below and call NotificationService.init() from main().
//
// ─────────────────────────────────────────────────────────────────────────────
// BACKEND
//  The server must send FCM messages to the device token stored in
//  NotificationService._token. Expose a POST endpoint that accepts
//  { "fcm_token": "<token>" } and store it per-user so the backend
//  can call FCM when new articles / events are published.
// ─────────────────────────────────────────────────────────────────────────────

/*
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background messages are handled here (app not running / in background).
}

class NotificationService {
  NotificationService._();

  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static String? _token;

  static String? get fcmToken => _token;

  static Future<void> init() async {
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (iOS / Android 13+).
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Set up local notifications channel (Android 8+).
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (details) {
        _handlePayload(details.payload);
      },
    );

    const channel = AndroidNotificationChannel(
      'czechbmx_default',
      'Czech BMX',
      description: 'Novinky a závody Czech BMX',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Fetch and store the FCM token — send this to your backend.
    _token = await _messaging.getToken();
    _messaging.onTokenRefresh.listen((token) => _token = token);

    // Foreground messages → show as local notification.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data['path'] as String?,
      );
    });

    // App opened from notification (background → foreground).
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handlePayload(message.data['path'] as String?);
    });

    // App opened from a terminated state via notification.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handlePayload(initial.data['path'] as String?);
    }
  }

  // Navigate to the path carried in the notification payload.
  // Expected format: "/news/some-slug" or "/events/42"
  static void _handlePayload(String? path) {
    if (path == null || path.isEmpty) return;
    appNavigatorKey.currentContext?.go(path);
  }
}
*/
