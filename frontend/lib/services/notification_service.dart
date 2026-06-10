// lib/services/notification_service.dart
// ══════════════════════════════════════════════════════════════════
//  HappyBowl — Notification Service
//  ✅ Added: showClaimRewardNotification()
//  ✅ Added: navigatorKey support for deep-link tap → HealthRewardsScreen
// ══════════════════════════════════════════════════════════════════

import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

// ── Global navigator key — set this in main.dart on MaterialApp ──
// Used so notification taps can navigate even when app is in background
final GlobalKey<NavigatorState> happybowlNavigatorKey =
GlobalKey<NavigatorState>();

const AndroidNotificationChannel happybowlChannel = AndroidNotificationChannel(
  'happybowl_channel',
  'HappyBowl Notifications',
  description: 'HappyBowl deals, orders & health alerts',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  enableLights: true,
  ledColor: Color(0xFF4CAF50),
  showBadge: true,
);

// Dedicated channel for reward claims (high priority, distinct sound)
const AndroidNotificationChannel rewardChannel = AndroidNotificationChannel(
  'happybowl_rewards',
  'HappyBowl Rewards',
  description: 'Daily health reward claim alerts',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  enableLights: true,
  ledColor: Color(0xFFD4A017),
  showBadge: true,
);

// Notification IDs
const int _kRewardNotifId = 888;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// ── INIT — call once in main() ───────────────────────────────────
Future<void> initNotificationService() async {
  tz_data.initializeTimeZones();
  try {
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  } catch (_) {}

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(happybowlChannel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(rewardChannel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: androidSettings),
    onDidReceiveNotificationResponse: _onTap,
  );
}

// ── SHOW FCM notification ────────────────────────────────────────
Future<void> showFlipkartNotification(RemoteMessage message) async {
  final notification = message.notification;
  if (notification == null) return;

  final title    = notification.title ?? 'HappyBowl';
  final body     = notification.body ?? '';
  final imageUrl = notification.android?.imageUrl ??
      message.data['image'] ??
      message.data['imageUrl'] ??
      notification.apple?.imageUrl;

  if (imageUrl != null && imageUrl.isNotEmpty) {
    await _bigPicture(title, body, imageUrl, message.data);
  } else {
    await _bigText(title, body, message.data);
  }
}

// ── CLAIM REWARD NOTIFICATION ────────────────────────────────────
/// Shows the "🎉 Claim your 100 points!" notification.
/// Tapping it deep-links to HealthRewardsScreen via payload 'claim_reward'.
Future<void> showClaimRewardNotification() async {
  await flutterLocalNotificationsPlugin.show(
    _kRewardNotifId,
    '🎉 You Earned 100 Points Today!',
    'All daily health goals completed! Tap to claim before 11:59 PM.',
    NotificationDetails(
      android: AndroidNotificationDetails(
        rewardChannel.id,
        rewardChannel.name,
        channelDescription: rewardChannel.description,
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: false,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 400, 200, 400, 200, 400]),
        enableLights: true,
        ledColor: const Color(0xFFD4A017),
        ledOnMs: 500,
        ledOffMs: 500,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFD4A017),
        subText: 'HappyBowl Rewards',
        ticker: 'Daily reward ready to claim!',
        autoCancel: true,
        showWhen: true,
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: const BigTextStyleInformation(
          'You walked 8,000+ steps, slept 8+ hours, and drank 3L of water today! 🏆\n\nClaim your 100 reward points before midnight — they expire at 11:59 PM!',
          contentTitle: '🎉 Daily Goals Complete!',
          summaryText: '100 pts = ₹1 discount on next order',
        ),
      ),
    ),
    payload: 'claim_reward',
  );
  debugPrint('✅ Claim reward notification shown');
}

// ── SCHEDULE daily local notification ───────────────────────────
Future<void> scheduleLocalNotification({
  required int id,
  required String title,
  required String body,
  required int hour,
  required int minute,
}) async {
  final now = tz.TZDateTime.now(tz.local);
  var scheduled = tz.TZDateTime(
    tz.local, now.year, now.month, now.day, hour, minute,
  );
  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    scheduled,
    NotificationDetails(
      android: AndroidNotificationDetails(
        happybowlChannel.id,
        happybowlChannel.name,
        channelDescription: happybowlChannel.description,
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF10B981),
        enableVibration: true,
        playSound: true,
        autoCancel: true,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'HappyBowl Health',
        ),
      ),
    ),
    uiLocalNotificationDateInterpretation:
    UILocalNotificationDateInterpretation.absoluteTime,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
    payload: 'medicine_reminder',
  );

  debugPrint(
      '✅ Scheduled "$title" daily at $hour:${minute.toString().padLeft(2, "0")} (id=$id)');
}

// ── Big Text ─────────────────────────────────────────────────────
Future<void> _bigText(
    String title, String body, Map<String, dynamic> data) async {
  await flutterLocalNotificationsPlugin.show(
    _id(),
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        happybowlChannel.id,
        happybowlChannel.name,
        channelDescription: happybowlChannel.description,
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
        enableLights: true,
        ledColor: const Color(0xFF4CAF50),
        ledOnMs: 1000,
        ledOffMs: 500,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF4CAF50),
        subText: 'HappyBowl',
        ticker: title,
        autoCancel: true,
        showWhen: true,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'HappyBowl',
        ),
      ),
    ),
    payload: _payload(data),
  );
}

// ── Big Picture ───────────────────────────────────────────────────
Future<void> _bigPicture(String title, String body, String imageUrl,
    Map<String, dynamic> data) async {
  final imageBytes = await _download(imageUrl);
  if (imageBytes == null) return _bigText(title, body, data);

  final bitmap = ByteArrayAndroidBitmap(imageBytes);

  await flutterLocalNotificationsPlugin.show(
    _id(),
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        happybowlChannel.id,
        happybowlChannel.name,
        channelDescription: happybowlChannel.description,
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
        enableLights: true,
        ledColor: const Color(0xFF4CAF50),
        ledOnMs: 1000,
        ledOffMs: 500,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF4CAF50),
        largeIcon: bitmap,
        subText: 'HappyBowl',
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

// ── Helpers ───────────────────────────────────────────────────────
Future<Uint8List?> _download(String url) async {
  try {
    final res =
    await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) return res.bodyBytes;
  } catch (e) {
    debugPrint('🔴 Image download failed: $e');
  }
  return null;
}

int _id() => DateTime.now().millisecondsSinceEpoch.remainder(100000);

String _payload(Map<String, dynamic> data) =>
    data.entries.map((e) => '${e.key}=${e.value}').join('&');

/// Handles notification taps — routes 'claim_reward' to HealthRewardsScreen
void _onTap(NotificationResponse r) {
  debugPrint('✅ Notification tapped: ${r.payload}');
  if (r.payload == 'claim_reward') {
    // Navigate to HealthRewardsScreen using global navigator key
    happybowlNavigatorKey.currentState?.pushNamed('/health_rewards');
  }
}
