import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/health_record_model.dart';
import '../services/health_service.dart';
import '../../auth/providers/auth_provider.dart';

class HealthRecordsState {
  final List<HealthRecord> records;
  final bool isLoading;
  final String? error;

  const HealthRecordsState({
    this.records = const [],
    this.isLoading = false,
    this.error,
  });

  HealthRecordsState copyWith({
    List<HealthRecord>? records,
    bool? isLoading,
    String? error,
  }) {
    return HealthRecordsState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class HealthRecordsNotifier extends Notifier<HealthRecordsState> {
  final HealthService _service = HealthService();

  @override
  HealthRecordsState build() {
    final session = ref.watch(sessionProvider);
    if (session != null) {
      Future.microtask(() => fetchRecords());
    }
    return const HealthRecordsState();
  }

  Future<void> fetchRecords({String? type, String? specialist}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _service.getHealthRecords(type: type, specialist: specialist);
      state = HealthRecordsState(
        records: list,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> uploadRecord({
    required String name,
    required String type,
    required String date,
    required String specialist,
    required List<String> filePaths,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final record = await _service.createHealthRecord(
        name: name,
        type: type,
        date: date,
        specialist: specialist,
        filePaths: filePaths,
      );
      state = state.copyWith(
        records: [record, ...state.records],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteRecord(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _service.deleteHealthRecord(id);
      if (success) {
        state = state.copyWith(
          records: state.records.where((r) => r.id != id).toList(),
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

final healthRecordsProvider = NotifierProvider<HealthRecordsNotifier, HealthRecordsState>(HealthRecordsNotifier.new);
