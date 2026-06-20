import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/health_service.dart';
import '../../../core/models/tracker_models.dart';
import '../../auth/providers/auth_provider.dart';

class HealthState {
  final List<VitalsLog> vitalsLogs;
  final List<MeasurementLog> measurementLogs;
  final List<InsulinLog> insulinLogs;
  final bool isLoading;
  final String? error;
  final int vitalsPage;
  final bool hasMoreVitals;
  final int measurementPage;
  final bool hasMoreMeasurements;
  final int insulinPage;
  final bool hasMoreInsulin;
  final bool isLoadingMore;

  const HealthState({
    this.vitalsLogs = const [],
    this.measurementLogs = const [],
    this.insulinLogs = const [],
    this.isLoading = false,
    this.error,
    this.vitalsPage = 1,
    this.hasMoreVitals = true,
    this.measurementPage = 1,
    this.hasMoreMeasurements = true,
    this.insulinPage = 1,
    this.hasMoreInsulin = true,
    this.isLoadingMore = false,
  });

  HealthState copyWith({
    List<VitalsLog>? vitalsLogs,
    List<MeasurementLog>? measurementLogs,
    List<InsulinLog>? insulinLogs,
    bool? isLoading,
    String? error,
    int? vitalsPage,
    bool? hasMoreVitals,
    int? measurementPage,
    bool? hasMoreMeasurements,
    int? insulinPage,
    bool? hasMoreInsulin,
    bool? isLoadingMore,
  }) {
    return HealthState(
      vitalsLogs: vitalsLogs ?? this.vitalsLogs,
      measurementLogs: measurementLogs ?? this.measurementLogs,
      insulinLogs: insulinLogs ?? this.insulinLogs,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      vitalsPage: vitalsPage ?? this.vitalsPage,
      hasMoreVitals: hasMoreVitals ?? this.hasMoreVitals,
      measurementPage: measurementPage ?? this.measurementPage,
      hasMoreMeasurements: hasMoreMeasurements ?? this.hasMoreMeasurements,
      insulinPage: insulinPage ?? this.insulinPage,
      hasMoreInsulin: hasMoreInsulin ?? this.hasMoreInsulin,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class HealthNotifier extends Notifier<HealthState> {
  final HealthService _service = HealthService();

  @override
  HealthState build() {
    final session = ref.watch(sessionProvider);
    if (session != null) {
      Future.microtask(() => fetchAllHealthData());
    }
    return const HealthState();
  }

  Future<void> fetchAllHealthData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _service.getVitalsLogs(page: 1, limit: 20),
        _service.getMeasurementLogs(page: 1, limit: 20),
        _service.getInsulinLogs(page: 1, limit: 20),
      ]);

      final vitals = results[0] as List<VitalsLog>;
      final measurements = results[1] as List<MeasurementLog>;
      final insulins = results[2] as List<InsulinLog>;

      state = HealthState(
        vitalsLogs: vitals,
        measurementLogs: measurements,
        insulinLogs: insulins,
        isLoading: false,
        vitalsPage: 1,
        hasMoreVitals: vitals.length >= 20,
        measurementPage: 1,
        hasMoreMeasurements: measurements.length >= 20,
        insulinPage: 1,
        hasMoreInsulin: insulins.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchMoreVitals() async {
    if (state.isLoadingMore || !state.hasMoreVitals) return;
    final nextPage = state.vitalsPage + 1;
    state = state.copyWith(isLoadingMore: true);
    try {
      final logs = await _service.getVitalsLogs(page: nextPage, limit: 20);
      state = state.copyWith(
        vitalsLogs: [...state.vitalsLogs, ...logs],
        vitalsPage: nextPage,
        hasMoreVitals: logs.length >= 20,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> fetchMoreMeasurements() async {
    if (state.isLoadingMore || !state.hasMoreMeasurements) return;
    final nextPage = state.measurementPage + 1;
    state = state.copyWith(isLoadingMore: true);
    try {
      final logs = await _service.getMeasurementLogs(page: nextPage, limit: 20);
      state = state.copyWith(
        measurementLogs: [...state.measurementLogs, ...logs],
        measurementPage: nextPage,
        hasMoreMeasurements: logs.length >= 20,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> fetchMoreInsulin() async {
    if (state.isLoadingMore || !state.hasMoreInsulin) return;
    final nextPage = state.insulinPage + 1;
    state = state.copyWith(isLoadingMore: true);
    try {
      final logs = await _service.getInsulinLogs(page: nextPage, limit: 20);
      state = state.copyWith(
        insulinLogs: [...state.insulinLogs, ...logs],
        insulinPage: nextPage,
        hasMoreInsulin: logs.length >= 20,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  // ─── Vitals Notifiers ──────────────────────────────────────────────────────
  Future<bool> addVitals({
    required String date,
    required String time,
    String? bp,
    int? pulse,
    double? temperature,
    double? weight,
    int? spo2,
    int? exerciseMins,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final log = await _service.logVitals(
        date: date,
        time: time,
        bp: bp,
        pulse: pulse,
        temperature: temperature,
        weight: weight,
        spo2: spo2,
        exerciseMins: exerciseMins,
      );
      state = state.copyWith(
        vitalsLogs: [log, ...state.vitalsLogs],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteVitals(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _service.deleteVitalsLog(id);
      if (success) {
        state = state.copyWith(
          vitalsLogs: state.vitalsLogs.where((v) => v.id != id).toList(),
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

  // ─── Measurements Notifiers ────────────────────────────────────────────────
  Future<bool> addMeasurement({
    double? weight,
    double? height,
    double? chest,
    double? waist,
    double? hips,
    double? bodyFatPercent,
    DateTime? loggedAt,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final log = await _service.logMeasurement(
        weight: weight,
        height: height,
        chest: chest,
        waist: waist,
        hips: hips,
        bodyFatPercent: bodyFatPercent,
        loggedAt: loggedAt,
      );
      state = state.copyWith(
        measurementLogs: [log, ...state.measurementLogs],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteMeasurement(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _service.deleteMeasurementLog(id);
      if (success) {
        state = state.copyWith(
          measurementLogs: state.measurementLogs.where((m) => m.id != id).toList(),
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

  // ─── Insulin Notifiers ─────────────────────────────────────────────────────
  Future<bool> addInsulin({
    required int dose,
    required String insulinType,
    required String injectionSite,
    required String mealContext,
    String? note,
    DateTime? loggedAt,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final log = await _service.logInsulin(
        dose: dose,
        insulinType: insulinType,
        injectionSite: injectionSite,
        mealContext: mealContext,
        note: note,
        loggedAt: loggedAt,
      );
      state = state.copyWith(
        insulinLogs: [log, ...state.insulinLogs],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteInsulin(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _service.deleteInsulinLog(id);
      if (success) {
        state = state.copyWith(
          insulinLogs: state.insulinLogs.where((i) => i.id != id).toList(),
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

final healthProvider = NotifierProvider<HealthNotifier, HealthState>(HealthNotifier.new);
