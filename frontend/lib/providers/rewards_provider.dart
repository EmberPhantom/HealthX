import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api/api_service.dart';
import '../services/notification_service.dart';

// ── Pref Keys ─────────────────────────────────────────────────────
const _kTotalPoints        = 'rewards_total_points';
const _kClaimedDate        = 'rewards_claimed_date';       // 'yyyy-MM-dd'
const _kNotifiedDate       = 'rewards_notified_date';      // 'yyyy-MM-dd'
const _kWaterLastLogTs     = 'rewards_water_last_log_ts';  // epoch ms

// Task completion keys (set by each tracker when goal reached)
const _kStepsGoalDate      = 'rewards_steps_goal_date';    // 'yyyy-MM-dd'
const _kSleepGoalDate      = 'rewards_sleep_goal_date';    // 'yyyy-MM-dd'
const _kWaterGoalDate      = 'rewards_water_goal_date';    // 'yyyy-MM-dd'

// ── Points constants ───────────────────────────────────────────────
const int kStepsPoints  = 50;
const int kSleepPoints  = 25;
const int kWaterPoints  = 25;
const int kDailyTotal   = 100; // steps + sleep + water
const int kStepsGoal    = 8000; // daily step goal

// 100 coins = ₹10
const double kCoinsPerRupee = 10.0;

// ──────────────────────────────────────────────────────────────────

class RewardsProvider extends ChangeNotifier {
  int    _totalPoints      = 0;
  bool   _stepsGoalToday   = false;
  bool   _sleepGoalToday   = false;
  bool   _waterGoalToday   = false;
  bool   _claimedToday     = false;
  bool   _allTasksDone     = false;
  int    _currentSteps     = 0;
  int    _stepsGoal        = kStepsGoal;

  int    get stepsGoal     => _stepsGoal;

  // Water cooldown — user can log only once per hour
  DateTime? _waterLastLog;

  int    get totalPoints    => _totalPoints;
  bool   get stepsGoalDone  => _stepsGoalToday;
  bool   get sleepGoalDone  => _sleepGoalToday;
  bool   get waterGoalDone  => _waterGoalToday;
  bool   get claimedToday   => _claimedToday;
  bool   get allTasksDone   => _allTasksDone;
  int    get currentSteps   => _currentSteps;

  /// Coins → Rupees value string  e.g. "₹1.50"
  String get rupeeValue =>
      '₹${(_totalPoints / kCoinsPerRupee).toStringAsFixed(2)}';

  /// Can the water log button be tapped right now?
  bool get canLogWater {
    if (_waterLastLog == null) return true;
    return DateTime.now().difference(_waterLastLog!).inMinutes >= 30;
  }

  /// Minutes remaining until next water log is allowed (0 if allowed)
  int get waterCooldownMinutesLeft {
    if (_waterLastLog == null) return 0;
    final diff = 30 - DateTime.now().difference(_waterLastLog!).inMinutes;
    return diff.clamp(0, 30);
  }

  /// Seconds remaining until next water log is allowed (0 if allowed).
  /// Used by WaterTrackerScreen for second-precision countdown display.
  int get waterCooldownSecondsLeft {
    if (_waterLastLog == null) return 0;
    final elapsed = DateTime.now().difference(_waterLastLog!);
    final remaining = const Duration(minutes: 30) - elapsed;
    return remaining.isNegative ? 0 : remaining.inSeconds;
  }

  // ── Init ─────────────────────────────────────────────────────────
  RewardsProvider() {
    Future.microtask(() => _load());
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();

    _totalPoints = prefs.getInt(_kTotalPoints) ?? 0;
    
    // Sync total points from backend if possible
    try {
      final resStats = await ApiService().getProfileStats();
      if (resStats.isSuccess && resStats.data != null) {
        _totalPoints = resStats.data!['points'] ?? _totalPoints;
        await prefs.setInt(_kTotalPoints, _totalPoints);
      }
    } catch (e) {
      debugPrint('RewardsProvider: Error syncing points from backend: $e');
    }

    _claimedToday = (prefs.getString(_kClaimedDate) ?? '') == today;

    _stepsGoalToday = (prefs.getString(_kStepsGoalDate) ?? '') == today;
    _sleepGoalToday = (prefs.getString(_kSleepGoalDate) ?? '') == today;
    _waterGoalToday = (prefs.getString(_kWaterGoalDate) ?? '') == today;

    // Sync settings from backend
    try {
      final resSettings = await ApiService().getUserSettings();
      if (resSettings.isSuccess && resSettings.data != null) {
        _stepsGoal = resSettings.data!['dailyStepGoal'] as int? ?? kStepsGoal;
      }
    } catch (e) {
      debugPrint('RewardsProvider: Error syncing settings from backend: $e');
    }

    final lastLogMs = prefs.getInt(_kWaterLastLogTs);
    if (lastLogMs != null) {
      _waterLastLog = DateTime.fromMillisecondsSinceEpoch(lastLogMs);
      // Reset cooldown if it's a new day
      if (_waterLastLog!.day != DateTime.now().day) {
        _waterLastLog = null;
        await prefs.remove(_kWaterLastLogTs);
      }
    }

    _recalcAllDone();
    notifyListeners();

    // Schedule midnight reset check
    _scheduleMidnightReset();
  }

  // ── Task completion setters (called by trackers) ──────────────────

  /// Called by StepCounterService on every step update
  void updateSteps(int steps) {
    _currentSteps = steps;
    notifyListeners();
    if (steps >= _stepsGoal) {
      markStepsGoalDone();
    }
  }

  Future<void> setStepsGoal(int goal) async {
    _stepsGoal = goal.clamp(2000, 20000);
    notifyListeners();
    try {
      await ApiService().updateUserSettings({'dailyStepGoal': _stepsGoal});
    } catch (e) {
      debugPrint('RewardsProvider: Error syncing step goal to backend: $e');
    }
  }

  /// Call this from StepsTrackerScreen / StepCounterService when 8000 steps reached
  Future<void> markStepsGoalDone() async {
    if (_stepsGoalToday) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStepsGoalDate, _todayStr());
    _stepsGoalToday = true;
    _recalcAllDone();
    notifyListeners();
    await _checkAndNotify();
  }

  /// Call this from SleepProvider when ≥8h sleep logged today
  Future<void> markSleepGoalDone() async {
    if (_sleepGoalToday) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSleepGoalDate, _todayStr());
    _sleepGoalToday = true;
    _recalcAllDone();
    notifyListeners();
    await _checkAndNotify();
  }

  /// Call this from WaterProvider when daily goal reached (≥4L)
  /// Also enforces 1-hour cooldown — returns false if on cooldown
  Future<bool> onWaterLogged() async {
    // Enforce cooldown
    if (!canLogWater) return false;

    // Record log time
    _waterLastLog = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _kWaterLastLogTs, _waterLastLog!.millisecondsSinceEpoch);
    notifyListeners();
    return true;
  }

  Future<void> markWaterGoalDone() async {
    if (_waterGoalToday) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWaterGoalDate, _todayStr());
    _waterGoalToday = true;
    _recalcAllDone();
    notifyListeners();
    await _checkAndNotify();
  }

  // ── Claim 100 points ─────────────────────────────────────────────

  /// Returns true if claim was successful
  Future<bool> claimDailyReward() async {
    if (_claimedToday || !_allTasksDone) return false;
    
    try {
      final response = await ApiService().updatePoints(kDailyTotal);
      if (response.isSuccess) {
        final prefs = await SharedPreferences.getInstance();
        _totalPoints = (response.data?['totalPoints'] as num?)?.toInt() ?? (_totalPoints + kDailyTotal);
        _claimedToday = true;
        await prefs.setInt(_kTotalPoints, _totalPoints);
        await prefs.setString(_kClaimedDate, _todayStr());
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error claiming daily reward: $e');
    }
    return false;
  }

  // ── Internal helpers ──────────────────────────────────────────────

  void _recalcAllDone() {
    _allTasksDone = _stepsGoalToday && _sleepGoalToday && _waterGoalToday;
  }

  /// Fire the claim notification once per day when all tasks are done
  Future<void> _checkAndNotify() async {
    if (!_allTasksDone || _claimedToday) return;
    final prefs = await SharedPreferences.getInstance();
    final notifiedDate = prefs.getString(_kNotifiedDate) ?? '';
    if (notifiedDate == _todayStr()) return; // already notified today
    await prefs.setString(_kNotifiedDate, _todayStr());
    await showClaimRewardNotification();
  }

  Timer? _resetTimer;

  /// Schedule a check at midnight to reset today's state
  void _scheduleMidnightReset() {
    _resetTimer?.cancel();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final diff = midnight.difference(now);
    _resetTimer = Timer(diff, () async {
      await _load(); // reload clears old day's flags
    });
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
  }

  /// For testing / dev — manually refresh state from prefs
  Future<void> refresh() => _load();
}