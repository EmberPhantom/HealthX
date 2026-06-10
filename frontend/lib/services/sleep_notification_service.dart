// lib/services/sleep_notification_service.dart
//
// ✅ Native Kotlin AlarmManager approach — same as StepCountService
// ✅ Calls MainActivity via MethodChannel → SleepAlarmReceiver.kt
// ✅ NO flutter_local_notifications, NO timezone package needed
// ✅ Works when app is completely closed — guaranteed like step notifications

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SleepNotificationService {
  SleepNotificationService._();
  static final SleepNotificationService instance = SleepNotificationService._();

  static const MethodChannel _channel =
  MethodChannel('com.healthxworld.app/sleep_service');

  // ── Schedule all 4 sleep alarms ──────────────────────────────────────────
  // Called by SleepProvider.logSleep() every time user logs/edits sleep
  Future<void> scheduleSleepNotifications({
    required int bedtimeHour,
    required int bedtimeMinute,
    required int wakeHour,
    required int wakeMinute,
  }) async {
    try {
      await _channel.invokeMethod('scheduleSleepAlarms', {
        'bedtimeHour':   bedtimeHour,
        'bedtimeMinute': bedtimeMinute,
        'wakeHour':      wakeHour,
        'wakeMinute':    wakeMinute,
      });
      debugPrint('✅ Sleep alarms scheduled via native: '
          'Bedtime $bedtimeHour:${bedtimeMinute.toString().padLeft(2,'0')} | '
          'Wake $wakeHour:${wakeMinute.toString().padLeft(2,'0')}');
    } on PlatformException catch (e) {
      debugPrint('SleepNotificationService.schedule error: ${e.message}');
    }
  }

  // ── Cancel all sleep alarms ───────────────────────────────────────────────
  Future<void> cancelAllSleepNotifications() async {
    try {
      await _channel.invokeMethod('cancelSleepAlarms');
      debugPrint('✅ Sleep alarms cancelled');
    } on PlatformException catch (e) {
      debugPrint('SleepNotificationService.cancel error: ${e.message}');
    }
  }

  // ── Snooze bedtime by +15 or +30 min ─────────────────────────────────────
  Future<void> snoozeBedtime({required int addMinutes}) async {
    try {
      await _channel.invokeMethod('snoozeSleepAlarm', {
        'addMinutes': addMinutes,
      });
      debugPrint('✅ Bedtime snoozed by +$addMinutes min');
    } on PlatformException catch (e) {
      debugPrint('SleepNotificationService.snooze error: ${e.message}');
    }
  }

  // ── Restore after boot (called from SleepProvider.loadFromStorage) ────────
  // Native side (BootReceiver) already handles this automatically.
  // This is a no-op — kept for API compatibility with SleepProvider.
  Future<void> restoreAfterBoot() async {
    // BootReceiver.kt → SleepAlarmReceiver.restoreAfterBoot() handles this
    // No Flutter-side action needed
    debugPrint('ℹ️ Sleep alarms restored by native BootReceiver');
  }
}