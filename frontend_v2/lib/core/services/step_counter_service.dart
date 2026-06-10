import 'package:flutter/services.dart';

class StepCounterService {
  StepCounterService._();
  static final StepCounterService instance = StepCounterService._();

  static const _channel = MethodChannel('com.healthxworld.app/step_service');

  // ─── Start the foreground service ─────────────────────────────────────────
  Future<void> startService() async {
    try {
      await _channel.invokeMethod('startStepService');
    } catch (_) {
      // Already running or non-Android platform — safe to ignore
    }
  }

  // ─── Read today's steps ───────────────────────────────────────────────────
  Future<int> getTodaySteps() async {
    try {
      final steps = await _channel.invokeMethod<int>('getTodaySteps');
      return steps ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // ─── Sync goal to native SharedPreferences ───────────────────────────────
  Future<void> setGoal(int goal) async {
    try {
      await _channel.invokeMethod('setGoal', {'goal': goal});
    } catch (_) {
      // Fallback: at least persist in Flutter prefs
    }
  }

  // ─── Calories helper ──────────────────────────────────────────────────────
  static int stepsToCalories(int steps) => (steps * 0.04).round();
}
