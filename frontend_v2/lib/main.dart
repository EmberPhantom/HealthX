import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/navigation_service.dart' show rootNavigatorKey, routerProvider;
import 'core/services/push_notification_service.dart';
import 'features/notifications/services/notification_service.dart';
import 'firebase_options.dart';

// ─── FCM background handler ───────────────────────────────────────────────────
// Must be a top-level function annotated with @pragma('vm:entry-point').

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}

  // Initialise local notifications plugin for the background isolate
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@drawable/ic_notification');
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: androidSettings),
  );

  // Show the notification in the system tray
  await handleBackgroundMessage(message);
}

// ─── Deep-link tap handler ────────────────────────────────────────────────────

void _handleNotificationPayload(String? payload) {
  if (payload == null || payload.isEmpty) return;

  // Special single-token payloads
  if (payload == 'claim_reward') {
    rootNavigatorKey.currentState?.pushNamed('/rewards');
    return;
  }
  if (payload == 'reminder') {
    return; // generic reminder — no navigation
  }

  // Parse query-string style payload: key=val&key2=val2
  final params = <String, String>{};
  for (final pair in payload.split('&')) {
    final parts = pair.split('=');
    if (parts.length == 2) {
      params[parts[0]] = parts[1];
    }
  }

  final type = params['type'] ?? '';

  switch (type) {
    case 'order_update':
      final orderId = params['order_id'] ?? '';
      if (orderId.isNotEmpty) {
        rootNavigatorKey.currentState?.pushNamed('/shop/orders/$orderId/track');
      }
      break;

    case 'appointment_update':
    case 'appointment_reminder':
    case 'prescription_ready':
      final appointmentId = params['appointment_id'] ?? '';
      if (appointmentId.isNotEmpty) {
        rootNavigatorKey.currentState?.pushNamed('/consults/appointments/$appointmentId');
      } else {
        rootNavigatorKey.currentState?.pushNamed('/consults');
      }
      break;

    case 'chat_message':
      final appointmentId = params['appointment_id'] ?? '';
      if (appointmentId.isNotEmpty) {
        rootNavigatorKey.currentState?.pushNamed('/consults/chat/$appointmentId');
      }
      break;

    case 'health_alert':
      rootNavigatorKey.currentState?.pushNamed('/health');
      break;

    default:
      // Fall back to the notifications screen
      rootNavigatorKey.currentState?.pushNamed('/notifications');
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final _notificationApiService = NotificationService();

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(
    onTap: _handleNotificationPayload,
    onTokenObtained: (token) async {
      // Upload the FCM token to the backend so server can push to this device
      await _notificationApiService.registerFcmToken(token);
    },
  );
});

// ─── Entry point ──────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final store = FMTCStore('osm_tiles');
    if (!await store.manage.ready) {
      await store.manage.create();
    }
  } catch (e) {
    debugPrint('TileCache init skipped: $e');
  }

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint('Firebase already initialized');
    } else {
      rethrow;
    }
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  final pushService = PushNotificationService(
    onTap: _handleNotificationPayload,
    onTokenObtained: (token) async {
      await _notificationApiService.registerFcmToken(token);
    },
  );
  await pushService.initialize();
  await pushService.setupFCM();

  const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 1.0;
      },
      appRunner: () => runApp(
        ProviderScope(
          overrides: [
            pushNotificationServiceProvider.overrideWithValue(pushService),
          ],
          child: const MyApp(),
        ),
      ),
    );
  } else {
    runApp(
      ProviderScope(
        overrides: [
          pushNotificationServiceProvider.overrideWithValue(pushService),
        ],
        child: const MyApp(),
      ),
    );
  }
}

// ─── Root widget ──────────────────────────────────────────────────────────────

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    final pushService = ref.read(pushNotificationServiceProvider);

    // Foreground FCM messages → show as local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      pushService.showFcmNotification(message);
    });

    // When the user taps a notification that was shown while the app was
    // in the background (but not fully terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final type = message.data['type'] ?? '';
      final payload = message.data.entries.map((e) => '${e.key}=${e.value}').join('&');
      _handleNotificationPayload(payload.isEmpty ? type : payload);
    });

    // Handle notification that launched a terminated app
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        final payload = message.data.entries.map((e) => '${e.key}=${e.value}').join('&');
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNotificationPayload(payload);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'HealthX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
