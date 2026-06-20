import 'package:flutter/services.dart';

class WaterTrackerService {
  WaterTrackerService._();
  static final WaterTrackerService instance = WaterTrackerService._();

  static const _channel = MethodChannel('com.healthxworld.app/water_service');

  // ─── Start reminders ───────────────────────────────────────────────────────
  Future<void> startWaterReminders(int intervalMinutes) async {
    try {
      await _channel.invokeMethod('startWaterReminders', {
        'intervalMinutes': intervalMinutes,
      });
    } catch (_) {}
  }

  // ─── Stop reminders ────────────────────────────────────────────────────────
  Future<void> stopWaterReminders() async {
    try {
      await _channel.invokeMethod('stopWaterReminders');
    } catch (_) {}
  }

  // ─── Get native today total ────────────────────────────────────────────────
  Future<int> getTodayWater() async {
    try {
      final amount = await _channel.invokeMethod<int>('getTodayWater');
      return amount ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // ─── Sync goal ─────────────────────────────────────────────────────────────
  Future<void> setWaterGoal(int goal) async {
    try {
      await _channel.invokeMethod('setWaterGoal', {'goal': goal});
    } catch (_) {}
  }

  // ─── Sync today's total from Flutter to Native ─────────────────────────────
  Future<void> syncTodayWater(int todayTotal) async {
    try {
      await _channel.invokeMethod('syncTodayWater', {'todayTotal': todayTotal});
    } catch (_) {}
  }

  // ─── Get pending offline quick logs ────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getPendingWaterLogs() async {
    try {
      final String? logsStr = await _channel.invokeMethod<String>('getPendingWaterLogs');
      if (logsStr == null || logsStr.isEmpty) return const [];

      // Parse format: "amount|timestamp,amount|timestamp"
      final List<Map<String, dynamic>> parsedLogs = [];
      final parts = logsStr.split(',');
      for (final part in parts) {
        final subParts = part.split('|');
        if (subParts.length == 2) {
          final amount = int.tryParse(subParts[0]);
          final timestamp = int.tryParse(subParts[1]);
          if (amount != null && timestamp != null) {
            parsedLogs.add({
              'amount': amount,
              'timestamp': DateTime.fromMillisecondsSinceEpoch(timestamp),
            });
          }
        }
      }
      return parsedLogs;
    } catch (_) {
      return const [];
    }
  }

  // ─── Clear pending quick logs ──────────────────────────────────────────────
  Future<void> clearPendingWaterLogs() async {
    try {
      await _channel.invokeMethod('clearPendingWaterLogs');
    } catch (_) {}
  }
}
