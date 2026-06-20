import 'package:flutter/services.dart';

class SleepTrackerService {
  SleepTrackerService._();
  static final SleepTrackerService instance = SleepTrackerService._();

  static const _channel = MethodChannel('com.healthxworld.app/sleep_service');

  // ─── Get pending offline calculated sleep log ──────────────────────────────
  Future<Map<String, dynamic>?> getPendingSleepLog() async {
    try {
      final String? logStr = await _channel.invokeMethod<String>('getPendingSleepLog');
      if (logStr == null || logStr.isEmpty) return null;

      // Parse format: "startTimeMillis|endTimeMillis|dateKey"
      final parts = logStr.split('|');
      if (parts.length == 3) {
        final startTime = int.tryParse(parts[0]);
        final endTime = int.tryParse(parts[1]);
        final dateKey = parts[2];

        if (startTime != null && endTime != null) {
          return {
            'bedtime': DateTime.fromMillisecondsSinceEpoch(startTime),
            'wakeTime': DateTime.fromMillisecondsSinceEpoch(endTime),
            'dateKey': dateKey,
          };
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── Clear pending sleep log ───────────────────────────────────────────────
  Future<void> clearPendingSleepLog() async {
    try {
      await _channel.invokeMethod('clearPendingSleepLog');
    } catch (_) {}
  }

  // ─── Schedule all 4 sleep alarms ───────────────────────────────────────────
  Future<void> scheduleSleepNotifications({
    required int bedtimeHour,
    required int bedtimeMinute,
    required int wakeHour,
    required int wakeMinute,
  }) async {
    try {
      await _channel.invokeMethod('scheduleSleepAlarms', {
        'bedtimeHour': bedtimeHour,
        'bedtimeMinute': bedtimeMinute,
        'wakeHour': wakeHour,
        'wakeMinute': wakeMinute,
      });
    } on PlatformException catch (_) {}
  }

  // ─── Cancel all sleep alarms ───────────────────────────────────────────────
  Future<void> cancelAllSleepNotifications() async {
    try {
      await _channel.invokeMethod('cancelSleepAlarms');
    } on PlatformException catch (_) {}
  }

  // ─── Snooze bedtime alert notification ─────────────────────────────────────
  Future<void> snoozeBedtime({required int addMinutes}) async {
    try {
      await _channel.invokeMethod('snoozeSleepAlarm', {
        'addMinutes': addMinutes,
      });
    } on PlatformException catch (_) {}
  }
}
