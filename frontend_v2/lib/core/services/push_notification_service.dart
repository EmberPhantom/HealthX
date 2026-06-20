import 'dart:typed_data';
import 'dart:ui' show Color;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

// ─── Global plugin instance ───────────────────────────────────────────────────

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// ─── Notification Channels ────────────────────────────────────────────────────
// Each channel maps to a backend NotificationCategory value.

const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
  'healthx_channel',
  'HealthX General',
  description: 'General HealthX alerts and health tips',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  enableLights: true,
  ledColor: Color(0xFF10B981),
  showBadge: true,
);

const AndroidNotificationChannel ordersChannel = AndroidNotificationChannel(
  'healthx_orders',
  'HealthX Orders',
  description: 'Order placement, status updates and delivery tracking',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  enableLights: true,
  ledColor: Color(0xFF10B981),
  showBadge: true,
);

const AndroidNotificationChannel appointmentsChannel = AndroidNotificationChannel(
  'healthx_appointments',
  'HealthX Appointments',
  description: 'Appointment confirmations, reminders and cancellations',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  enableLights: true,
  ledColor: Color(0xFF6366F1),
  showBadge: true,
);

const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
  'healthx_chat',
  'HealthX Consultations',
  description: 'Doctor consultation chat messages and prescription alerts',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
  enableLights: true,
  ledColor: Color(0xFF0EA5E9),
  showBadge: true,
);

const AndroidNotificationChannel healthAlertsChannel = AndroidNotificationChannel(
  'healthx_health_alerts',
  'HealthX Health Alerts',
  description: 'Critical health alerts: glucose, blood pressure, SpO₂',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  enableLights: true,
  ledColor: Color(0xFFEF4444),
  showBadge: true,
);

const AndroidNotificationChannel rewardChannel = AndroidNotificationChannel(
  'healthx_rewards',
  'HealthX Rewards',
  description: 'Daily health reward claim alerts',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
  enableLights: true,
  ledColor: Color(0xFFD4A017),
  showBadge: true,
);

const AndroidNotificationChannel promotionsChannel = AndroidNotificationChannel(
  'healthx_promotions',
  'HealthX Offers',
  description: 'Promotions, deals and wellness offers',
  importance: Importance.defaultImportance,
  playSound: false,
  enableVibration: false,
  showBadge: false,
);

// ─── Channel registry ─────────────────────────────────────────────────────────

const List<AndroidNotificationChannel> _allChannels = [
  generalChannel,
  ordersChannel,
  appointmentsChannel,
  chatChannel,
  healthAlertsChannel,
  rewardChannel,
  promotionsChannel,
];

/// Maps FCM `category` data field → channel id
const Map<String, String> _categoryChannelMap = {
  'general': 'healthx_channel',
  'orders': 'healthx_orders',
  'appointments': 'healthx_appointments',
  'chat': 'healthx_chat',
  'health': 'healthx_health_alerts',
  'rewards': 'healthx_rewards',
  'promotions': 'healthx_promotions',
};

/// Maps channel id → LED colour (for local notifications)
const Map<String, Color> _channelLedColor = {
  'healthx_channel': Color(0xFF10B981),
  'healthx_orders': Color(0xFF10B981),
  'healthx_appointments': Color(0xFF6366F1),
  'healthx_chat': Color(0xFF0EA5E9),
  'healthx_health_alerts': Color(0xFFEF4444),
  'healthx_rewards': Color(0xFFD4A017),
  'healthx_promotions': Color(0xFF9CA3AF),
};

// ─── Notification IDs ─────────────────────────────────────────────────────────

const int _kRewardNotifId = 888;

// ─── Callback type ─────────────────────────────────────────────────────────────

typedef NotificationTapCallback = void Function(String? payload);

// ─── Service ──────────────────────────────────────────────────────────────────

class PushNotificationService {
  final NotificationTapCallback? onTap;

  /// Optional callback invoked after a new FCM token is obtained so the caller
  /// can upload it to the backend.
  final Future<void> Function(String token)? onTokenObtained;

  PushNotificationService({this.onTap, this.onTokenObtained});

  // ── Initialisation ──────────────────────────────────────────────────────────

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (_) {}

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Create all channels
    for (final channel in _allChannels) {
      await androidPlugin?.createNotificationChannel(channel);
    }

    await androidPlugin?.requestNotificationsPermission();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');

    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _onTap,
    );
  }

  // ── FCM setup ───────────────────────────────────────────────────────────────

  Future<void> setupFCM() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await messaging.subscribeToTopic('all_users');

    // Obtain and upload token
    final token = await messaging.getToken();
    if (token != null) {
      debugPrint('✅ FCM Token: ${token.substring(0, 10)}...');
      await onTokenObtained?.call(token);
    }

    // Refresh handler — fires when FCM rotates the token
    messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 FCM token refreshed');
      await onTokenObtained?.call(newToken);
    });
  }

  // ── Show FCM message as local notification ──────────────────────────────────

  /// Call this from both foreground AND background handlers.
  Future<void> showFcmNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final title = notification.title ?? 'HealthX';
    final body = notification.body ?? '';
    final category = message.data['category'] ?? 'general';
    final channelId = _categoryChannelMap[category] ?? generalChannel.id;
    final ledColor = _channelLedColor[channelId] ?? const Color(0xFF10B981);

    final imageUrl = notification.android?.imageUrl ??
        message.data['image'] ??
        message.data['imageUrl'] ??
        notification.apple?.imageUrl;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      await _bigPicture(title, body, imageUrl, channelId, ledColor, message.data);
    } else {
      await _bigText(title, body, channelId, ledColor, message.data);
    }
  }

  // ── Specialised notifications ───────────────────────────────────────────────

  Future<void> showClaimRewardNotification() async {
    await flutterLocalNotificationsPlugin.show(
      _kRewardNotifId,
      'You Earned 100 Points Today!',
      'All daily health goals completed! Tap to claim before 11:59 PM.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          rewardChannel.id,
          rewardChannel.name,
          channelDescription: rewardChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          fullScreenIntent: false,
          visibility: NotificationVisibility.public,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 400, 200, 400, 200, 400]),
          enableLights: true,
          ledColor: const Color(0xFFD4A017),
          ledOnMs: 500,
          ledOffMs: 500,
          icon: '@drawable/ic_notification',
          color: const Color(0xFFD4A017),
          subText: 'HealthX Rewards',
          ticker: 'Daily reward ready to claim!',
          autoCancel: true,
          showWhen: true,
          largeIcon:
              const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
          styleInformation: const BigTextStyleInformation(
            'You walked 8,000+ steps, slept 8+ hours, and drank 3L of water today!\n\nClaim your 100 reward points before midnight — they expire at 11:59 PM!',
            contentTitle: 'Daily Goals Complete!',
            summaryText: '100 pts available',
          ),
        ),
      ),
      payload: 'claim_reward',
    );
  }

  // ── Scheduled (local) notifications ────────────────────────────────────────

  Future<void> scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _buildLocalDetails(
        title: title,
        body: body,
        channelId: generalChannel.id,
        channelName: generalChannel.name,
        channelDesc: generalChannel.description,
        ledColor: const Color(0xFF10B981),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'reminder',
    );
  }

  Future<void> scheduleAppointmentReminder({
    required int id,
    required String doctorName,
    required DateTime appointmentDate,
    required String timeSlot,
    int hoursBefore = 24,
  }) async {
    final reminderTime = appointmentDate.subtract(Duration(hours: hoursBefore));
    if (reminderTime.isBefore(DateTime.now())) return;

    final tzReminder = tz.TZDateTime.from(reminderTime, tz.local);
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Appointment Reminder 📅',
      'You have an appointment with $doctorName at $timeSlot in $hoursBefore hours.',
      tzReminder,
      _buildLocalDetails(
        title: 'Appointment Reminder',
        body: 'Appointment with $doctorName at $timeSlot',
        channelId: appointmentsChannel.id,
        channelName: appointmentsChannel.name,
        channelDesc: appointmentsChannel.description,
        ledColor: const Color(0xFF6366F1),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'appointment_reminder_$id',
    );
  }

  Future<void> cancelScheduledNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  void _onTap(NotificationResponse r) {
    debugPrint('✅ Notification tapped: ${r.payload}');
    onTap?.call(r.payload);
  }

  NotificationDetails _buildLocalDetails({
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required String channelDesc,
    required Color ledColor,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.max,
        priority: Priority.max,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
        enableLights: true,
        ledColor: ledColor,
        ledOnMs: 1000,
        ledOffMs: 500,
        icon: '@drawable/ic_notification',
        color: ledColor,
        subText: 'HealthX',
        ticker: title,
        autoCancel: true,
        showWhen: true,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'HealthX',
        ),
      ),
    );
  }

  Future<void> _bigText(
    String title,
    String body,
    String channelId,
    Color ledColor,
    Map<String, dynamic> data,
  ) async {
    await flutterLocalNotificationsPlugin.show(
      _id(),
      title,
      body,
      _buildLocalDetails(
        title: title,
        body: body,
        channelId: channelId,
        channelName: _allChannels.firstWhere((c) => c.id == channelId, orElse: () => generalChannel).name,
        channelDesc: _allChannels.firstWhere((c) => c.id == channelId, orElse: () => generalChannel).description ?? '',
        ledColor: ledColor,
      ),
      payload: _payload(data),
    );
  }

  Future<void> _bigPicture(
    String title,
    String body,
    String imageUrl,
    String channelId,
    Color ledColor,
    Map<String, dynamic> data,
  ) async {
    final imageBytes = await _download(imageUrl);
    if (imageBytes == null) return _bigText(title, body, channelId, ledColor, data);

    final bitmap = ByteArrayAndroidBitmap(imageBytes);

    await flutterLocalNotificationsPlugin.show(
      _id(),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _allChannels.firstWhere((c) => c.id == channelId, orElse: () => generalChannel).name,
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: ledColor,
          ledOnMs: 1000,
          ledOffMs: 500,
          icon: '@drawable/ic_notification',
          color: ledColor,
          largeIcon: bitmap,
          subText: 'HealthX',
          ticker: title,
          autoCancel: true,
          showWhen: true,
          styleInformation: BigPictureStyleInformation(
            bitmap,
            largeIcon: bitmap,
            contentTitle: title,
            summaryText: body,
            hideExpandedLargeIcon: false,
          ),
        ),
      ),
      payload: _payload(data),
    );
  }
}

// ─── Top-level background handler helper ─────────────────────────────────────
// Call this from the @pragma('vm:entry-point') handler in main.dart.

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  final notification = message.notification;
  if (notification == null) return;

  final title = notification.title ?? 'HealthX';
  final body = notification.body ?? '';
  final category = message.data['category'] ?? 'general';
  final channelId = _categoryChannelMap[category] ?? generalChannel.id;
  final ledColor = _channelLedColor[channelId] ?? const Color(0xFF10B981);

  await flutterLocalNotificationsPlugin.show(
    _id(),
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _allChannels.firstWhere((c) => c.id == channelId, orElse: () => generalChannel).name,
        importance: Importance.max,
        priority: Priority.max,
        icon: '@drawable/ic_notification',
        color: ledColor,
        enableLights: true,
        ledColor: ledColor,
        autoCancel: true,
      ),
    ),
    payload: _payload(message.data),
  );
}

// ─── Utilities ────────────────────────────────────────────────────────────────

Future<Uint8List?> _download(String url) async {
  try {
    final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) return res.bodyBytes;
  } catch (e) {
    debugPrint('Image download failed: $e');
  }
  return null;
}

int _id() => DateTime.now().millisecondsSinceEpoch.remainder(100000);

String _payload(Map<String, dynamic> data) =>
    data.entries.map((e) => '${e.key}=${e.value}').join('&');
