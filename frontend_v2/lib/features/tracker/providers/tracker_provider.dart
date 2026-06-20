import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tracker_service.dart';
import '../../../core/models/tracker_models.dart';
import '../../../core/services/step_counter_service.dart';
import '../../../core/services/water_tracker_service.dart';
import '../../../core/services/sleep_tracker_service.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class TrackerState {
  final List<WaterLog> waterLogs;
  final List<SleepLog> sleepLogs;
  final List<StepLog> stepLogs;
  final List<GlucoseLog> glucoseLogs;
  final bool isLoading;
  final String? error;
  final int waterPage;
  final bool hasMoreWater;
  final int sleepPage;
  final bool hasMoreSleep;
  final int stepPage;
  final bool hasMoreStep;
  final int glucosePage;
  final bool hasMoreGlucose;
  final bool isLoadingMore;

  const TrackerState({
    this.waterLogs = const [],
    this.sleepLogs = const [],
    this.stepLogs = const [],
    this.glucoseLogs = const [],
    this.isLoading = false,
    this.error,
    this.waterPage = 1,
    this.hasMoreWater = true,
    this.sleepPage = 1,
    this.hasMoreSleep = true,
    this.stepPage = 1,
    this.hasMoreStep = true,
    this.glucosePage = 1,
    this.hasMoreGlucose = true,
    this.isLoadingMore = false,
  });

  int get todayWaterAmount {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return waterLogs
        .where((log) => DateFormat('yyyy-MM-dd').format(log.loggedAt.toLocal()) == today)
        .fold(0, (sum, log) => sum + log.amount);
  }

  int get todaySteps {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final log = stepLogs.firstWhere(
      (log) => log.dateKey == today,
      orElse: () => const StepLog(id: '', steps: 0, dateKey: ''),
    );
    return log.steps;
  }

  SleepLog? get lastSleep {
    return sleepLogs.isNotEmpty ? sleepLogs.first : null;
  }

  GlucoseLog? get lastGlucose {
    return glucoseLogs.isNotEmpty ? glucoseLogs.first : null;
  }

  TrackerState copyWith({
    List<WaterLog>? waterLogs,
    List<SleepLog>? sleepLogs,
    List<StepLog>? stepLogs,
    List<GlucoseLog>? glucoseLogs,
    bool? isLoading,
    String? error,
    int? waterPage,
    bool? hasMoreWater,
    int? sleepPage,
    bool? hasMoreSleep,
    int? stepPage,
    bool? hasMoreStep,
    int? glucosePage,
    bool? hasMoreGlucose,
    bool? isLoadingMore,
  }) {
    return TrackerState(
      waterLogs: waterLogs ?? this.waterLogs,
      sleepLogs: sleepLogs ?? this.sleepLogs,
      stepLogs: stepLogs ?? this.stepLogs,
      glucoseLogs: glucoseLogs ?? this.glucoseLogs,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      waterPage: waterPage ?? this.waterPage,
      hasMoreWater: hasMoreWater ?? this.hasMoreWater,
      sleepPage: sleepPage ?? this.sleepPage,
      hasMoreSleep: hasMoreSleep ?? this.hasMoreSleep,
      stepPage: stepPage ?? this.stepPage,
      hasMoreStep: hasMoreStep ?? this.hasMoreStep,
      glucosePage: glucosePage ?? this.glucosePage,
      hasMoreGlucose: hasMoreGlucose ?? this.hasMoreGlucose,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class TrackerNotifier extends Notifier<TrackerState> {
  final TrackerService _service = TrackerService();
  Timer? _syncTimer;

  @override
  TrackerState build() {
    ref.onDispose(() {
      _syncTimer?.cancel();
    });
    final session = ref.watch(sessionProvider);
    if (session != null) {
      Future.microtask(() => fetchAllData());
    }
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      fetchNativeSteps();
      syncOfflineData();
    });
    return const TrackerState();
  }

  Future<void> fetchNativeSteps() async {
    try {
      final nativeSteps = await StepCounterService.instance.getTodaySteps();
      if (nativeSteps > 0) {
        final currentSteps = state.todaySteps;
        if (nativeSteps > currentSteps) {
          await updateSteps(nativeSteps);
        }
      }
    } catch (e) {
      debugPrint('❌ fetchNativeSteps failed: $e');
    }
  }

  Future<void> syncOfflineData() async {
    try {
      // 1. Sync pending sleep log from native calculations
      final pendingSleep = await SleepTrackerService.instance.getPendingSleepLog();
      if (pendingSleep != null) {
        final bedtime = pendingSleep['bedtime'] as DateTime;
        final wakeTime = pendingSleep['wakeTime'] as DateTime;
        final dateKey = pendingSleep['dateKey'] as String;

        try {
          await _service.logSleep(bedtime, wakeTime, dateKey);
          await SleepTrackerService.instance.clearPendingSleepLog();
          debugPrint('✅ Synced offline pending sleep log.');
        } catch (e) {
          debugPrint('❌ Syncing offline sleep log failed: $e');
        }
      }

      // 2. Sync pending water logs from native quick actions
      final pendingWaters = await WaterTrackerService.instance.getPendingWaterLogs();
      if (pendingWaters.isNotEmpty) {
        bool allSuccess = true;
        for (final log in pendingWaters) {
          final amount = log['amount'] as int;
          final timestamp = log['timestamp'] as DateTime;
          try {
            await _service.logWater(amount, timestamp);
          } catch (e) {
            allSuccess = false;
            debugPrint('❌ Syncing offline water log failed: $e');
          }
        }
        if (allSuccess) {
          await WaterTrackerService.instance.clearPendingWaterLogs();
          debugPrint('✅ Synced all offline pending water logs.');
        }
      }
    } catch (e) {
      debugPrint('❌ syncOfflineData failed: $e');
    }
  }

  Future<void> fetchAllData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day - 7);
      final startStr = DateFormat('yyyy-MM-dd').format(start);
      final endStr = DateFormat('yyyy-MM-dd').format(now);

      // Trigger offline synchronization first
      await syncOfflineData();

      await StepCounterService.instance.startService();
      final todayNativeSteps = await StepCounterService.instance.getTodaySteps();

      if (todayNativeSteps > 0) {
        try {
          await _service.logSteps(todayNativeSteps, endStr);
        } catch (e) {
          debugPrint('❌ Syncing native steps failed: $e');
        }
      }

      final results = await Future.wait([
        _service.getWaterLogs(startDate: start, endDate: now, page: 1, limit: 20),
        _service.getSleepLogs(page: 1, limit: 30),
        _service.getStepLogs(startDate: startStr, endDate: endStr, page: 1, limit: 20),
        _service.getGlucoseLogs(page: 1, limit: 20),
      ]);

      final waters = results[0] as List<WaterLog>;
      final sleeps = results[1] as List<SleepLog>;
      final steps = results[2] as List<StepLog>;
      final glucoses = results[3] as List<GlucoseLog>;

      state = TrackerState(
        waterLogs: waters,
        sleepLogs: sleeps,
        stepLogs: steps,
        glucoseLogs: glucoses,
        isLoading: false,
        waterPage: 1,
        hasMoreWater: waters.length >= 20,
        sleepPage: 1,
        hasMoreSleep: sleeps.length >= 30,
        stepPage: 1,
        hasMoreStep: steps.length >= 20,
        glucosePage: 1,
        hasMoreGlucose: glucoses.length >= 20,
      );

      // Sync computed today's total water amount back to native shared prefs
      try {
        await WaterTrackerService.instance.syncTodayWater(state.todayWaterAmount);
      } catch (_) {}
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchMoreWater() async {
    if (state.isLoadingMore || !state.hasMoreWater) return;
    final nextPage = state.waterPage + 1;
    state = state.copyWith(isLoadingMore: true);
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day - 7);
      final logs = await _service.getWaterLogs(startDate: start, endDate: now, page: nextPage, limit: 20);
      state = state.copyWith(
        waterLogs: [...state.waterLogs, ...logs],
        waterPage: nextPage,
        hasMoreWater: logs.length >= 20,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> fetchMoreGlucose() async {
    if (state.isLoadingMore || !state.hasMoreGlucose) return;
    final nextPage = state.glucosePage + 1;
    state = state.copyWith(isLoadingMore: true);
    try {
      final logs = await _service.getGlucoseLogs(page: nextPage, limit: 20);
      state = state.copyWith(
        glucoseLogs: [...state.glucoseLogs, ...logs],
        glucosePage: nextPage,
        hasMoreGlucose: logs.length >= 20,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> fetchMoreSleep() async {
    if (state.isLoadingMore || !state.hasMoreSleep) return;
    final nextPage = state.sleepPage + 1;
    state = state.copyWith(isLoadingMore: true);
    try {
      final logs = await _service.getSleepLogs(page: nextPage, limit: 30);
      state = state.copyWith(
        sleepLogs: [...state.sleepLogs, ...logs],
        sleepPage: nextPage,
        hasMoreSleep: logs.length >= 30,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<bool> addWater(int amount) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final log = await _service.logWater(amount);
      state = state.copyWith(
        waterLogs: [...state.waterLogs, log],
        isLoading: false,
      );
      // Sync updated today total back to native shared prefs
      try {
        await WaterTrackerService.instance.syncTodayWater(state.todayWaterAmount);
      } catch (_) {}
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateSteps(int steps) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final log = await _service.logSteps(steps, today);
      
      final updatedSteps = List<StepLog>.from(state.stepLogs);
      final index = updatedSteps.indexWhere((s) => s.dateKey == today);
      if (index != -1) {
        updatedSteps[index] = log;
      } else {
        updatedSteps.add(log);
      }

      state = state.copyWith(
        stepLogs: updatedSteps,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> addSleep(DateTime bedtime, DateTime wakeTime) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final log = await _service.logSleep(bedtime, wakeTime, today);

      final updatedSleeps = List<SleepLog>.from(state.sleepLogs);
      final index = updatedSleeps.indexWhere((s) => s.dateKey == today);
      if (index != -1) {
        updatedSleeps[index] = log;
      } else {
        updatedSleeps.insert(0, log);
      }

      state = state.copyWith(
        sleepLogs: updatedSleeps,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Returns the AI inline comment if available, or null.
  /// The comment is non-null only for users with a complete AI health profile
  /// and a confirmed diabetes condition.
  Future<String?> addGlucose(int level, String readingType, [String? note]) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final (log, inlineComment) = await _service.logGlucose(level, readingType, note);
      state = state.copyWith(
        glucoseLogs: [log, ...state.glucoseLogs],
        isLoading: false,
      );
      return inlineComment;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> deleteGlucose(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _service.deleteGlucose(id);
      if (success) {
        final updatedGlucoses = state.glucoseLogs.where((g) => g.id != id).toList();
        state = state.copyWith(
          glucoseLogs: updatedGlucoses,
          isLoading: false,
        );
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final trackerProvider = NotifierProvider<TrackerNotifier, TrackerState>(TrackerNotifier.new);
