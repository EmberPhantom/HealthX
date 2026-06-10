import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'theme/theme.dart';
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/sleep_provider.dart';
import 'providers/water_provider.dart';
import 'providers/rewards_provider.dart';
import 'providers/address_provider.dart';
import 'providers/order_provider.dart';
import 'screens/login_screen.dart';
import 'screens/health_rewards_screen.dart';
import 'widgets/app_shell.dart';
import 'screens/splash_screen.dart';
import 'screens/wellness_goals_screen.dart';
import 'screens/wellness_goals_screen.dart' show OnboardingProvider;
import 'screens/measurements_screen.dart';
import 'screens/age_prakriti_screen.dart';
import 'screens/signup_screen.dart';
import 'config/app_router.dart';
import 'utils/web_utils.dart' as web_utils;

// ══════════════════════════════════════════════════════════════════
//  Background handler — must be top-level
// ══════════════════════════════════════════════════════════════════
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // Silently ignore if already initialized
    debugPrint('Firebase already initialized in background handler');
  }
  debugPrint('📨 BG message: ${message.notification?.title}');
}

// ══════════════════════════════════════════════════════════════════
//  Permission bootstrap
// ══════════════════════════════════════════════════════════════════
Future<void> _requestAppPermissions() async {
  // Activity Recognition and Exact Alarms are mobile-only and crash the web engine.
  if (kIsWeb) return;

  final permissions = [
    Permission.notification,
    Permission.activityRecognition,
    Permission.camera,
  ];

  for (final permission in permissions) {
    final status = await permission.status;
    if (status.isDenied) {
      await permission.request();
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  if (androidPlugin != null) {
    final granted = await androidPlugin.requestExactAlarmsPermission();
    debugPrint('✅ Exact alarm permission: $granted');
    final notifGranted = await androidPlugin.requestNotificationsPermission();
    debugPrint('✅ Notification permission via plugin: $notifGranted');
  }
}

// ══════════════════════════════════════════════════════════════════
//  MAIN
// ══════════════════════════════════════════════════════════════════
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // If it's already initialized (happens during Hot Restart or logic races), just continue
    if (e.toString().contains('duplicate-app')) {
      debugPrint('Firebase already initialized (duplicate-app)');
    } else {
      rethrow;
    }
  }
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  await _requestAppPermissions();
  await initNotificationService();

  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);
  await messaging.setForegroundNotificationPresentationOptions(
    alert: true, badge: true, sound: true,
  );

  await messaging.subscribeToTopic('all_users');
  final token = await messaging.getToken();
  debugPrint('✅ FCM Token: $token');

  // Remove native web splash if running on web
  web_utils.removeSplashFromWeb();

  runApp(const HealthXApp());
}

// ══════════════════════════════════════════════════════════════════
//  APP
// ══════════════════════════════════════════════════════════════════
class HealthXApp extends StatelessWidget {
  const HealthXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ Auth & User Management (Phase 4)
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        
        // ✅ User data provider watches AuthProvider for changes
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (_) => UserProvider(),
          update: (_, authProvider, userProvider) {
            // Sync user from auth provider to user provider.
            // If authenticated but the auth user is temporarily null (due to network timeout),
            // retain the cached user details in UserProvider. Only clear when logged out.
            if (authProvider.isAuthenticated) {
              if (authProvider.user != null) {
                userProvider?.syncWithAuth(authProvider.user);
              }
            } else {
              userProvider?.clearUser();
            }
            return userProvider ?? UserProvider();
          },
        ),
        
        // ✅ App-wide state management
        // AppProvider listens to AuthProvider: fetches all content the moment
        // the user logs in (so DioClient has the token ready before the fetch).
        ChangeNotifierProxyProvider<AuthProvider, AppProvider>(
          create: (_) => AppProvider(),
          update: (_, authProvider, appProvider) {
            if (authProvider.isAuthenticated && !(appProvider?.isInitialized ?? false)) {
              // Delay slightly so DioClient has time to persist the token to headers
              Future.microtask(() => appProvider?.initializeData());
            } else if (!authProvider.isAuthenticated) {
              // Clear dynamic content on logout
              appProvider?.onLogout();
            }
            return appProvider ?? AppProvider();
          },
        ),
        
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        
        // ✅ RewardsProvider created first so others can reference it
        ChangeNotifierProvider(create: (_) => RewardsProvider()),
        
        // ✅ SleepProvider gets RewardsProvider injected via ProxyProvider
        ChangeNotifierProxyProvider<RewardsProvider, SleepProvider>(
          create: (_) => SleepProvider(),
          update: (_, rewards, sleep) {
            sleep!.setRewards(rewards);
            return sleep;
          },
        ),
        
        // ✅ WaterProvider gets RewardsProvider injected via ProxyProvider
        ChangeNotifierProxyProvider<RewardsProvider, WaterProvider>(
          create: (_) => WaterProvider(),
          update: (_, rewards, water) {
            water!.setRewards(rewards);
            return water;
          },
        ),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Create router with auth provider
          final router = createRouter(authProvider);
          
          return NotificationHandler(
            child: MaterialApp.router(
              title: 'HealthX',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              routerConfig: router,
              builder: (context, child) => ResponsiveBreakpoints.builder(
                child: child!,
                breakpoints: const [
                  Breakpoint(start: 0,    end: 450,            name: MOBILE),
                  Breakpoint(start: 451,  end: 800,            name: TABLET),
                  Breakpoint(start: 801,  end: 1700,           name: DESKTOP),
                  Breakpoint(start: 1701, end: double.infinity, name: '4K'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Notification Handler — Foreground listener
// ══════════════════════════════════════════════════════════════════
class NotificationHandler extends StatefulWidget {
  final Widget child;
  const NotificationHandler({super.key, required this.child});

  @override
  State<NotificationHandler> createState() => _NotificationHandlerState();
}

class _NotificationHandlerState extends State<NotificationHandler> {
  @override
  void initState() {
    super.initState();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔥 onMessage: ${message.notification?.title}');
      showFlipkartNotification(message);
    });

    // Handle FCM tap when app is in background (opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Tapped: ${message.notification?.title}');
      // Note: navigation from notification taps can be handled via
      // FirebaseMessaging.instance.getInitialMessage() or deep links
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}