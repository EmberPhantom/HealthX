import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/consult_service.dart';
import '../../../core/models/consult_models.dart';

class ConsultsState {
  final List<Doctor> doctors;
  final List<Appointment> appointments;
  final bool isLoading;
  final String? error;

  const ConsultsState({
    this.doctors = const [],
    this.appointments = const [],
    this.isLoading = false,
    this.error,
  });

  ConsultsState copyWith({
    List<Doctor>? doctors,
    List<Appointment>? appointments,
    bool? isLoading,
    String? error,
  }) {
    return ConsultsState(
      doctors: doctors ?? this.doctors,
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ConsultsNotifier extends Notifier<ConsultsState> {
  final ConsultService _service = ConsultService();

  @override
  ConsultsState build() {
    Future.microtask(() => refreshAll());
    return const ConsultsState();
  }

  Future<void> refreshAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final doctorsList = await _service.getDoctors();
      final appointmentsList = await _service.getAppointments();
      state = ConsultsState(
        doctors: doctorsList,
        appointments: appointmentsList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> bookDoctorSlot(String doctorId, DateTime date, String timeSlot, {String? symptoms, String? notes}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final appointment = await _service.bookAppointment(doctorId, date, timeSlot, symptoms: symptoms, notes: notes);
      state = state.copyWith(
        appointments: [appointment, ...state.appointments],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> cancelUserAppointment(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cancelled = await _service.cancelAppointment(id);
      
      final updated = state.appointments.map((a) {
        if (a.id == id) {
          return cancelled;
        }
        return a;
      }).toList();

      state = state.copyWith(
        appointments: updated,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final consultsProvider = NotifierProvider<ConsultsNotifier, ConsultsState>(ConsultsNotifier.new);
