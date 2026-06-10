// lib/services/step_counter_service.dart
// ✅ Channel name matches MainActivity.kt exactly → com.healthx.app/step_service

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepCounterService {
  StepCounterService._();
  static final StepCounterService instance = StepCounterService._();

  static const _channel = MethodChannel('com.healthxworld.app/step_service');

  static const _keySteps = 'today_steps';

  // ─── Start the foreground service ─────────────────────────────────────────
  Future<void> startService() async {
    try {
      await _channel.invokeMethod('startStepService');
    } catch (_) {
      // Already running — safe to ignore
    }
  }

  // ─── Read today's steps ───────────────────────────────────────────────────
  Future<int> getTodaySteps() async {
    try {
      final steps = await _channel.invokeMethod<int>('getTodaySteps');
      return steps ?? 0;
    } catch (_) {
      return await _fallbackSteps();
    }
  }

  Future<int> _fallbackSteps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      return prefs.getInt(_keySteps) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // ─── Sync goal to native SharedPreferences ───────────────────────────────
  /// Call this every time the user saves a new goal.
  /// Ensures StepCountService (Kotlin) reads the correct goal for notifications.
  Future<void> setGoal(int goal) async {
    try {
      await _channel.invokeMethod('setStepGoal', {'goal': goal});
    } catch (_) {
      // Fallback: at least persist in Flutter prefs (already done by caller)
    }
  }

  // ─── Calories helper ──────────────────────────────────────────────────────
  static int stepsToCalories(int steps) => (steps * 0.04).round();
}