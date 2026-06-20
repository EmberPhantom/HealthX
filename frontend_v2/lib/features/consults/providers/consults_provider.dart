import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/consult_service.dart';
import '../../../core/models/consult_models.dart';
import '../../../main.dart' show pushNotificationServiceProvider;
import '../../auth/providers/auth_provider.dart';

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
    final session = ref.watch(sessionProvider);
    if (session != null) {
      Future.microtask(() => refreshAll());
    }
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
      _scheduleReminders(appointment);
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
      _cancelReminders(id);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> rescheduleAppointment(String id, DateTime newDate, String timeSlot) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final rescheduled = await _service.rescheduleAppointment(id, newDate, timeSlot);
      final updated = state.appointments.map((a) {
        if (a.id == id) {
          return rescheduled;
        }
        return a;
      }).toList();

      state = state.copyWith(
        appointments: updated,
        isLoading: false,
      );
      _cancelReminders(id);
      _scheduleReminders(rescheduled);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void _scheduleReminders(Appointment appointment) {
    final now = DateTime.now();
    final diff = appointment.appointmentDate.difference(now);
    final doctorName = appointment.doctor?.name ?? 'your doctor';

    final pushService = ref.read(pushNotificationServiceProvider);
    final idBase = appointment.id.hashCode;

    if (diff.inHours > 24) {
      pushService.scheduleAppointmentReminder(
        id: idBase ^ 1,
        doctorName: doctorName,
        appointmentDate: appointment.appointmentDate,
        timeSlot: appointment.timeSlot,
        hoursBefore: 24,
      );
    }
    if (diff.inHours > 1) {
      pushService.scheduleAppointmentReminder(
        id: idBase ^ 2,
        doctorName: doctorName,
        appointmentDate: appointment.appointmentDate,
        timeSlot: appointment.timeSlot,
        hoursBefore: 1,
      );
    }
  }

  void _cancelReminders(String appointmentId) {
    final pushService = ref.read(pushNotificationServiceProvider);
    final idBase = appointmentId.hashCode;
    pushService.cancelScheduledNotification(idBase ^ 1);
    pushService.cancelScheduledNotification(idBase ^ 2);
  }
}

final consultsProvider = NotifierProvider<ConsultsNotifier, ConsultsState>(ConsultsNotifier.new);

final specialtiesProvider = FutureProvider<List<String>>((ref) async {
  return ConsultService().getSpecialties();
});

