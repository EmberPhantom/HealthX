import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../services/api/api_service.dart';
import 'rewards_provider.dart';

class DayLog {
  final String day;
  final String? time;
  final double amount;

  const DayLog({required this.day, this.time, required this.amount});
}

class WaterProvider extends ChangeNotifier {
  static const String _keyPrefix  = 'water_intake_';
  static const String _keyGoal    = 'water_daily_goal';
  static const String _keyRemHrs  = 'water_reminder_hours';
  static const String _keyRemOn   = 'water_reminder_enabled';
  static const int    _baseNotifId = 2001;

  // ── Notification plugin ────────────────────────────────────────
  final FlutterLocalNotificationsPlugin _notif =
  FlutterLocalNotificationsPlugin();

  // ✅ RewardsProvider reference — injected after creation via setRewards()
  RewardsProvider? _rewards;
  void setRewards(RewardsProvider r) => _rewards = r;

  double  _currentIntake   = 0;
  double  _dailyGoal       = 3000;
  int     _reminderHours   = 2;
  bool    _reminderEnabled = false;
  List<DayLog> _weeklyLogs = [];
  bool    _isLoaded        = false;

  WaterProvider() {
    Future.microtask(() => _init());
  }

  // ── Getters ────────────────────────────────────────────────────
  double  get currentIntake   => _currentIntake;
  double  get dailyGoal       => _dailyGoal;
  int     get reminderHours   => _reminderHours;
  bool    get reminderEnabled => _reminderEnabled;
  List<DayLog> get weeklyLogs => _weeklyLogs;
  bool    get isLoaded        => _isLoaded;

  double  get progress      => (_currentIntake / _dailyGoal).clamp(0.0, 1.0);
  double  get currentLiters => _currentIntake / 1000;
  double  get remainingMl   => (_dailyGoal - _currentIntake).clamp(0, _dailyGoal);
  bool    get goalReached   => _currentIntake >= _dailyGoal;

  String get remainingText {
    if (goalReached) return 'Goal reached! 🎉';
    final rem = remainingMl;
    return rem >= 1000
        ? '${(rem / 1000).toStringAsFixed(1)}L remaining'
        : '${rem.toInt()}ml remaining';
  }

  String get insightMessage {
    if (goalReached)    return "Amazing! You've reached your daily goal! 🎉";
    if (progress > 0.7) return "Great hydration! Stay on track to meet your goal.";
    if (progress > 0.4) return "Good progress! Keep drinking to reach your goal.";
    return "Time to hydrate! Drink more water today.";
  }

  // ── Init ───────────────────────────────────────────────────────
  Future<void> _init() async {
    await _initNotifications();   // must come first
    await _loadFromPrefs();
    _isLoaded = true;
    notifyListeners();
  }

  // ── FIX #1: Correct flutter_local_notifications v18 init ──────
  // Creates Android channels HERE so they exist before any notify() call.
  Future<void> _initNotifications() async {
    // tz init required for zonedSchedule
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _notif.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // ── FIX #2: Create the Android channel BEFORE scheduling ─────
    // This is required on Android 8+ (API 26+).
    // Without this, notifications silently drop even if scheduled.
    const channel = AndroidNotificationChannel(
      'water_reminder_channel',        // must match channel id used in builder
      'Water Reminders',
      description: 'Reminds you to drink water throughout the day',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    await _notif
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ── Load ───────────────────────────────────────────────────────
  Future<void> _loadFromPrefs() async {
    final prefs   = await SharedPreferences.getInstance();
    _dailyGoal      = prefs.getDouble(_keyGoal)   ?? 3000;
    _reminderHours  = prefs.getInt(_keyRemHrs)    ?? 2;
    _reminderEnabled = prefs.getBool(_keyRemOn)   ?? false;
    
    // Fetch current intake and settings from backend
    await _fetchCurrentIntakeFromBackend();
    await _loadSettingsFromBackend();
    
    await _rebuildWeeklyLogs(prefs);

    // Reschedule reminder on cold start if it was enabled
    if (_reminderEnabled) await _scheduleReminders();
  }

  Future<void> _loadSettingsFromBackend() async {
    try {
      final response = await ApiService().getUserSettings();
      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        _dailyGoal = (data['dailyWaterGoalMl'] as num?)?.toDouble() ?? 3000;
        _reminderEnabled = data['reminderEnabled'] as bool? ?? false;
        
        // Update SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(_keyGoal, _dailyGoal);
        await prefs.setBool(_keyRemOn, _reminderEnabled);
      }
    } catch (e) {
      debugPrint('Error loading water settings from backend: $e');
    }
  }

  Future<void> _fetchCurrentIntakeFromBackend() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final response = await ApiService().getWaterLogs(
        startDate: startOfDay,
        endDate: endOfDay,
      );

      if (response.isSuccess && response.data != null) {
        _currentIntake = response.data!.fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching water intake from backend: $e');
    }
  }

  // ── Real 7-day weekly logs ─────────────────────────────────────
  Future<void> _rebuildWeeklyLogs(SharedPreferences prefs) async {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now  = DateTime.now();
    final logs = <DayLog>[];

    try {
      final startDate = now.subtract(const Duration(days: 6));
      final response = await ApiService().getWaterLogs(
        startDate: DateTime(startDate.year, startDate.month, startDate.day),
      );

      if (response.isSuccess && response.data != null) {
        final allLogs = response.data!;
        
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final dayName = days[date.weekday - 1];
          
          final dayAmount = allLogs
              .where((item) {
                final logDate = DateTime.parse(item['loggedAt']);
                return logDate.year == date.year && 
                       logDate.month == date.month && 
                       logDate.day == date.day;
              })
              .fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());
          
          logs.add(DayLog(day: dayName, amount: dayAmount));
        }
      }
    } catch (e) {
      debugPrint('Error rebuilding weekly logs from backend: $e');
      // Fallback to empty logs if backend fails
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        logs.add(DayLog(day: days[date.weekday - 1], amount: 0.0));
      }
    }
    
    _weeklyLogs = logs;
    notifyListeners();
  }

  // ── Save today ─────────────────────────────────────────────────
  Future<void> _saveToPrefs() async {
    // We now save to backend in addWater()
    final prefs = await SharedPreferences.getInstance();
    await _rebuildWeeklyLogs(prefs);
  }

  // ── Public API ─────────────────────────────────────────────────
  Future<void> addWater(double ml) async {
    // ✅ Enforce 1-hour cooldown via RewardsProvider (only for positive logs)
    if (ml > 0 && _rewards != null) {
      final allowed = await _rewards!.onWaterLogged();
      if (!allowed) {
        debugPrint('⏳ Water log blocked — cooldown ${_rewards!.waterCooldownMinutesLeft} min left');
        return;
      }
    }

    try {
      // Save to backend
      final response = await ApiService().logWater(amount: ml);
      
      if (response.isSuccess) {
        _currentIntake = (_currentIntake + ml).clamp(0, _dailyGoal * 2);
        final prefs = await SharedPreferences.getInstance();
        await _rebuildWeeklyLogs(prefs);
        notifyListeners();

        // ✅ Mark water goal done in RewardsProvider when daily goal reached
        if (goalReached && _rewards != null) {
          await _rewards!.markWaterGoalDone();
        }
      } else {
        debugPrint('Failed to log water to backend: ${response.errorMessage}');
      }
    } catch (e) {
      debugPrint('Error logging water to backend: $e');
    }
  }

  Future<void> undoLastLog() async => addWater(-250);

  Future<void> resetToday() async {
    _currentIntake = 0;
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> setGoal(double ml) async {
    _dailyGoal = ml.clamp(500, 5000);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyGoal, _dailyGoal);
    try {
      await ApiService().updateUserSettings({'dailyWaterGoalMl': _dailyGoal});
    } catch (e) {
      debugPrint('Error syncing water goal to backend: $e');
    }
    notifyListeners();
  }

  Future<void> setReminderHours(int hours) async {
    _reminderHours = hours.clamp(1, 8);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRemHrs, _reminderHours);
    if (_reminderEnabled) await _scheduleReminders();
    notifyListeners();
  }

  Future<void> toggleReminder(bool enabled) async {
    _reminderEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRemOn, enabled);
    try {
      await ApiService().updateUserSettings({'reminderEnabled': enabled});
    } catch (e) {
      debugPrint('Error syncing reminder status to backend: $e');
    }
    if (enabled) {
      await _scheduleReminders();
    } else {
      await _cancelReminders();
    }
    notifyListeners();
  }

  // ── FIX #3: Use zonedSchedule() — the CORRECT API for v18 ─────
  //
  //  Schedules water reminders every 30 minutes from 8:00 AM to 9:00 PM.
  //  Each slot gets a unique notifId. Repeats daily via matchDateTimeComponents.
  //
  Future<void> _scheduleReminders() async {
    await _cancelReminders(); // clear existing before rescheduling

    const androidDetails = AndroidNotificationDetails(
      'water_reminder_channel',         // ← same channel created in _initNotifications
      'Water Reminders',
      channelDescription: 'Reminds you to drink water throughout the day',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Schedule notifications every 30 minutes from 8:00 AM to 9:00 PM
    // Total slots: (13 hours × 2) + 1 = 27 slots (8:00, 8:30, 9:00 … 21:00)
    final now = tz.TZDateTime.now(tz.local);
    int notifId = _baseNotifId;
    int totalMinutes = 8 * 60; // start at 8:00 AM = 480 minutes from midnight

    while (totalMinutes <= 21 * 60) { // end at 9:00 PM = 1260 minutes
      final hour   = totalMinutes ~/ 60;
      final minute = totalMinutes % 60;

      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year, now.month, now.day,
        hour, minute, 0,
      );
      // If this time has already passed today, schedule for tomorrow
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      await _notif.zonedSchedule(
        notifId++,
        '💧 Time to Hydrate!',
        'You\'ve had ${currentLiters.toStringAsFixed(1)}L today. $remainingText',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );

      totalMinutes += 30; // every 30 minutes
    }

    debugPrint('✅ Water reminders scheduled: every 30 min from 8:00am to 9:00pm');
  }

  Future<void> _cancelReminders() async {
    // Cancel all water reminder notification IDs (27 slots max: 8:00–21:00 every 30min)
    int notifId = _baseNotifId;
    int totalMinutes = 8 * 60;
    while (totalMinutes <= 21 * 60) {
      await _notif.cancel(notifId++);
      totalMinutes += 30;
    }
  }

  // ── Chart helper ───────────────────────────────────────────────
  double getGlassFillPercent(int index) {
    if (index >= _weeklyLogs.length) return 0;
    return (_weeklyLogs[index].amount / _dailyGoal).clamp(0.0, 1.0);
  }

  // ── Date helpers ───────────────────────────────────────────────
  String _todayStr() => _dateStr(DateTime.now());
  String _dateStr(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
}