import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tracker_service.dart';
import '../../../core/models/tracker_models.dart';
import '../../../core/services/step_counter_service.dart';
import 'package:intl/intl.dart';

class TrackerState {
  final List<WaterLog> waterLogs;
  final List<SleepLog> sleepLogs;
  final List<StepLog> stepLogs;
  final List<GlucoseLog> glucoseLogs;
  final bool isLoading;
  final String? error;

  const TrackerState({
    this.waterLogs = const [],
    this.sleepLogs = const [],
    this.stepLogs = const [],
    this.glucoseLogs = const [],
    this.isLoading = false,
    this.error,
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
  }) {
    return TrackerState(
      waterLogs: waterLogs ?? this.waterLogs,
      sleepLogs: sleepLogs ?? this.sleepLogs,
      stepLogs: stepLogs ?? this.stepLogs,
      glucoseLogs: glucoseLogs ?? this.glucoseLogs,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
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
    Future.microtask(() => fetchAllData());
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      fetchNativeSteps();
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

  Future<void> fetchAllData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day - 7);
      final startStr = DateFormat('yyyy-MM-dd').format(start);
      final endStr = DateFormat('yyyy-MM-dd').format(now);

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
        _service.getWaterLogs(startDate: start, endDate: now),
        _service.getSleepLogs(),
        _service.getStepLogs(startDate: startStr, endDate: endStr),
        _service.getGlucoseLogs(),
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
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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

  Future<bool> addGlucose(int level, String readingType, [String? note]) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final log = await _service.logGlucose(level, readingType, note);
      state = state.copyWith(
        glucoseLogs: [log, ...state.glucoseLogs],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final trackerProvider = NotifierProvider<TrackerNotifier, TrackerState>(TrackerNotifier.new);
