// lib/services/health_service.dart
// ✅ All data from native StepCountService + SharedPreferences history
// ✅ Supports selected-date queries for calendar click
// ✅ Monthly best day computation
// ✅ Per-day data for full month graph scroll

import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api/api_service.dart';
import 'step_counter_service.dart';

class DaySteps {
  final String label; // 'Mon', '1', '15' etc
  final int steps;
  final DateTime date;
  const DaySteps(this.label, this.steps, this.date);
}

class HealthService {
  HealthService._();
  static final HealthService instance = HealthService._();

  static const _historyPrefix = 'history_';

  // ─── Permission ───────────────────────────────────────────────────────────
  Future<bool> requestPermissions() async {
    try {
      final status = await Permission.activityRecognition.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  // ─── Today steps ──────────────────────────────────────────────────────────
  Future<int> fetchTodaySteps() async {
    return await StepCounterService.instance.getTodaySteps();
  }

  // ─── Save today to history (called frequently from Flutter) ───────────────
  Future<void> saveTodayToHistory() async {
    try {
      final steps = await fetchTodaySteps();
      if (steps <= 0) return;
      
      final todayKey = _dateKey(DateTime.now());
      
      // Save to backend
      final response = await ApiService().logSteps(
        steps: steps,
        dateKey: todayKey,
      );

      if (response.isSuccess) {
        // Also cache locally
        final prefs = await SharedPreferences.getInstance();
        final key = _historyPrefix + todayKey;
        final existing = prefs.getInt(key) ?? 0;
        if (steps > existing) await prefs.setInt(key, steps);
      }
    } catch (_) {}
  }

  // ─── Steps for a specific date ────────────────────────────────────────────
  Future<int> fetchStepsForDate(DateTime date) async {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return await fetchTodaySteps();
    
    try {
      final dateKey = _dateKey(date);
      
      // Try backend first
      final response = await ApiService().getStepLogs(
        startDate: dateKey,
        endDate: dateKey,
      );

      if (response.isSuccess && response.data != null && response.data!.isNotEmpty) {
        return response.data!.first['steps'] as int;
      }

      // Fallback to local
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      return prefs.getInt(_historyPrefix + dateKey) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // ─── This week per-day Mon→Sun ─────────────────────────────────────────────
  Future<List<DaySteps>> fetchThisWeekPerDay() async {
    try {
      final now    = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final mondayMidnight = DateTime(monday.year, monday.month, monday.day);
      const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final List<DaySteps> result = [];

      final sunday = mondayMidnight.add(const Duration(days: 6));
      
      // Fetch from backend for the week
      final response = await ApiService().getStepLogs(
        startDate: _dateKey(mondayMidnight),
        endDate: _dateKey(sunday),
      );

      final Map<String, int> backendSteps = {};
      if (response.isSuccess && response.data != null) {
        for (var log in response.data!) {
          backendSteps[log['dateKey']] = log['steps'] as int;
        }
      }

      for (int i = 0; i < 7; i++) {
        final day = mondayMidnight.add(Duration(days: i));
        final key = _dateKey(day);

        if (day.isAfter(now)) {
          result.add(DaySteps(labels[i], 0, day));
          continue;
        }

        int steps = 0;
        if (_isSameDay(day, now)) {
          steps = await StepCounterService.instance.getTodaySteps();
        } else {
          steps = backendSteps[key] ?? 0;
          if (steps == 0) {
            // Check local fallback
            final prefs = await SharedPreferences.getInstance();
            steps = prefs.getInt(_historyPrefix + key) ?? 0;
          }
        }

        result.add(DaySteps(labels[i], steps, day));
      }
      return result;
    } catch (_) {
      // Basic fallback
      final now    = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final m = DateTime(monday.year, monday.month, monday.day);
      return List.generate(7, (i) =>
          DaySteps(['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][i], 0,
              m.add(Duration(days: i))));
    }
  }

  // ─── Full month per-day: all days 1→daysInMonth (0 for future/no data) ────
  Future<List<DaySteps>> fetchThisMonthAllDays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final now          = DateTime.now();
      final daysInMonth  = DateTimeHelper.daysInMonth(now.year, now.month);
      final List<DaySteps> result = [];

      for (int d = 1; d <= daysInMonth; d++) {
        final day = DateTime(now.year, now.month, d);
        int steps = 0;
        if (!day.isAfter(now)) {
          steps = _isSameDay(day, now)
              ? await StepCounterService.instance.getTodaySteps()
              : (prefs.getInt(_historyPrefix + _dateKey(day)) ?? 0);
        }
        result.add(DaySteps(d.toString(), steps, day));
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  // ─── This month per-day map (only days with data) ─────────────────────────
  Future<Map<int, int>> fetchThisMonthPerDay() async {
    final allDays = await fetchThisMonthAllDays();
    final Map<int, int> result = {};
    for (final d in allDays) {
      if (d.steps > 0) result[d.date.day] = d.steps;
    }
    return result;
  }

  // ─── This month total ─────────────────────────────────────────────────────
  Future<int> fetchThisMonthSteps() async {
    final perDay = await fetchThisMonthPerDay();
    return perDay.values.fold<int>(0, (int s, int v) => s + v);
  }

  // ─── Monthly best day (label=day name, steps=best steps) ──────────────────
  Future<DaySteps> fetchMonthBestDay() async {
    final allDays = await fetchThisMonthAllDays();
    final active  = allDays.where((d) => d.steps > 0).toList();
    if (active.isEmpty) {
      return DaySteps('—', 0, DateTime.now());
    }
    return active.reduce((a, b) => a.steps >= b.steps ? a : b);
  }

  // ─── Weekly total from week data ──────────────────────────────────────────
  static int weekTotal(List<DaySteps> weekData) =>
      weekData.fold<int>(0, (s, d) => s + d.steps);

  // ─── Calories helper ──────────────────────────────────────────────────────
  static int stepsToCalories(int steps) => (steps * 0.04).round();

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String _dateKey(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Helper for days in month (no package needed) ─────────────────────────────
class DateTimeHelper {
  static int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}