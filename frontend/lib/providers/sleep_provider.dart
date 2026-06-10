// lib/providers/sleep_provider.dart
// ✅ Calls SleepNotificationService.scheduleSleepNotifications() on every logSleep
// ✅ Snooze: adjusts bedtime display by +15 or +30 min
// ✅ Daily auto-reschedule: same times every day until user re-edits

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sleep_entry.dart';
import '../services/api/api_service.dart';
import '../services/sleep_notification_service.dart';
import 'rewards_provider.dart';

class SleepProvider extends ChangeNotifier {
  static const String _prefKey    = 'sleep_history_v1';
  static const String _prefSnooze = 'sleep_active_snooze_mins';

  SleepEntry?            _todayEntry;
  final List<SleepEntry> _history = [];

  // ✅ RewardsProvider reference — injected after creation via setRewards()
  RewardsProvider? _rewards;
  void setRewards(RewardsProvider r) => _rewards = r;

  SleepProvider() {
    Future.microtask(() => loadFromStorage());
  }

  bool _isLoading       = true;
  bool _isSaving        = false;
  int  _activeSnoozeMins = 0;

  SleepEntry? get todayEntry    => _todayEntry;
  bool get hasToday             => _todayEntry != null;
  bool get isLoading            => _isLoading;
  bool get isSaving             => _isSaving;
  int  get activeSnoozeMins     => _activeSnoozeMins;

  DateTime? get snoozedBedtime {
    if (_todayEntry == null || _activeSnoozeMins == 0) return null;
    return _todayEntry!.bedtime.add(Duration(minutes: _activeSnoozeMins));
  }

  List<SleepEntry> get last7Days {
    final result = <SleepEntry>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final d   = now.subtract(Duration(days: i));
      final key = SleepEntry.dateKey(d);
      final match = _history.where((e) => e.date == key).toList();
      result.add(match.isNotEmpty
          ? match.first
          : SleepEntry(
        bedtime:  DateTime(d.year, d.month, d.day, 23, 0),
        wakeTime: DateTime(d.year, d.month, d.day, 23, 0),
        date:     key,
      ));
    }
    return result;
  }

  double get weeklyAvgHours {
    final week = last7Days.where((e) => e.totalHours > 0).toList();
    if (week.isEmpty) return 0.0;
    return week.map((e) => e.totalHours).reduce((a, b) => a + b) / week.length;
  }

  int get daysGoalMet =>
      last7Days.where((e) => e.totalHours >= 7.0).length;

  // ── Load from SharedPreferences ──────────────────────────────────────────
  Future<void> loadFromStorage() async {
    _isLoading = true;
    notifyListeners();

    try {
      // First try to load from backend
      final response = await ApiService().getSleepLogs();
      
      if (response.isSuccess && response.data != null) {
        final list = response.data!
            .map((e) => SleepEntry.fromJson({
                  'bedtime': e['bedtime'],
                  'wakeTime': e['wakeTime'],
                  'date': e['dateKey'],
                }))
            .toList();
            
        _history
          ..clear()
          ..addAll(list);

        final todayKey  = SleepEntry.dateKey(DateTime.now());
        final todayList = _history.where((e) => e.date == todayKey).toList();
        _todayEntry     = todayList.isNotEmpty ? todayList.first : null;
      } else {
        // Fallback to local storage if backend fails
        final prefs = await SharedPreferences.getInstance();
        final raw   = prefs.getString(_prefKey);

        if (raw != null) {
          final list = (jsonDecode(raw) as List)
              .map((e) => SleepEntry.fromJson(e as Map<String, dynamic>))
              .toList();
          _history
            ..clear()
            ..addAll(list);

          final todayKey  = SleepEntry.dateKey(DateTime.now());
          final todayList = _history.where((e) => e.date == todayKey).toList();
          _todayEntry     = todayList.isNotEmpty ? todayList.first : null;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      _activeSnoozeMins = prefs.getInt(_prefSnooze) ?? 0;
    } catch (e) {
      debugPrint('SleepProvider.loadFromStorage error: $e');
    }

    _isLoading = false;
    notifyListeners();

    // Restore notifications after reboot
    await SleepNotificationService.instance.restoreAfterBoot();
  }

  // ── Log Sleep — saves entry + schedules all 4 notifications ─────────────
  Future<bool> logSleep({
    required DateTime bedtime,
    required DateTime wakeTime,
  }) async {
    if (!wakeTime.isAfter(bedtime)) return false;

    _isSaving = true;
    notifyListeners();

    final todayKey = SleepEntry.dateKey(DateTime.now());
    
    try {
      // Save to backend
      final response = await ApiService().logSleep(
        bedtime: bedtime,
        wakeTime: wakeTime,
        dateKey: todayKey,
      );

      if (response.isSuccess) {
        final entry = SleepEntry(bedtime: bedtime, wakeTime: wakeTime, date: todayKey);

        _history.removeWhere((e) => e.date == todayKey);
        _history.insert(0, entry);
        _todayEntry       = entry;
        _activeSnoozeMins = 0;

        if (_history.length > 30) _history.removeRange(30, _history.length);

        // Also save to local prefs as cache
        await _saveToPrefs();

        try {
          await SleepNotificationService.instance.scheduleSleepNotifications(
            bedtimeHour:   bedtime.hour,
            bedtimeMinute: bedtime.minute,
            wakeHour:      wakeTime.hour,
            wakeMinute:    wakeTime.minute,
          );
        } catch (e) {
          debugPrint('SleepProvider: notification scheduling error: $e');
        }

        // ✅ Mark sleep goal done in RewardsProvider if ≥8h slept
        if (entry.totalHours >= 8.0) {
          await _rewards?.markSleepGoalDone();
        }
        
        _isSaving = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('SleepProvider.logSleep error: $e');
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  // ── Snooze bedtime by +15 or +30 min ────────────────────────────────────
  Future<void> snoozeBedtime({required int addMinutes}) async {
    _activeSnoozeMins = addMinutes;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefSnooze, addMinutes);

    try {
      await SleepNotificationService.instance.snoozeBedtime(
          addMinutes: addMinutes);
    } catch (e) {
      debugPrint('SleepProvider.snoozeBedtime error: $e');
    }

    notifyListeners();
  }

  Future<void> clearSnooze() async {
    _activeSnoozeMins = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefSnooze);
    notifyListeners();
  }

  Future<void> deleteTodayEntry() async {
    final todayKey = SleepEntry.dateKey(DateTime.now());
    _history.removeWhere((e) => e.date == todayKey);
    _todayEntry = null;
    await _saveToPrefs();
    await SleepNotificationService.instance.cancelAllSleepNotifications();
    notifyListeners();
  }

  Future<bool> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _prefKey, jsonEncode(_history.map((e) => e.toJson()).toList()));
      return true;
    } catch (e) {
      debugPrint('SleepProvider._saveToPrefs error: $e');
      return false;
    }
  }
}