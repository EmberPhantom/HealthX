import 'package:flutter/foundation.dart';
import '../../../core/models/consult_models.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/dio_client.dart';

class ConsultService {
  final DioClient _dioClient = DioClient();

  Future<List<Doctor>> getDoctors() async {
    try {
      final response = await _dioClient.get(DoctorEndpoints.getDoctors);
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => Doctor.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getDoctors failed: $e');
      return [];
    }
  }

  Future<Doctor> getDoctor(String id) async {
    try {
      final response = await _dioClient.get(DoctorEndpoints.getDoctor(id));
      final rawData = response.data['data'] ?? response.data;
      return Doctor.fromJson(rawData);
    } catch (e) {
      debugPrint('❌ getDoctor failed: $e');
      rethrow;
    }
  }

  Future<List<String>> getDoctorSlots(String doctorId) async {
    try {
      final response = await _dioClient.get(DoctorEndpoints.getDoctorSlots(doctorId));
      final list = response.data['data'] as List? ?? [];
      return List<String>.from(list);
    } catch (e) {
      debugPrint('❌ getDoctorSlots failed: $e');
      return [];
    }
  }

  Future<Appointment> bookAppointment(
    String doctorId,
    DateTime date,
    String timeSlot, {
    String? symptoms,
    String? notes,
  }) async {
    try {
      final response = await _dioClient.post(
        AppointmentEndpoints.base,
        data: {
          'doctorId': doctorId,
          'appointmentDate': date.toIso8601String(),
          'timeSlot': timeSlot,
          'type': 'in-person',
          if (symptoms != null) 'symptoms': symptoms,
          if (notes != null) 'notes': notes,
        },
      );
      final rawData = response.data['data'] ?? response.data;
      return Appointment.fromJson(rawData);
    } catch (e) {
      debugPrint('❌ bookAppointment failed: $e');
      rethrow;
    }
  }

  Future<List<Appointment>> getAppointments() async {
    try {
      final response = await _dioClient.get(AppointmentEndpoints.base);
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => Appointment.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getAppointments failed: $e');
      return [];
    }
  }

  Future<Appointment> cancelAppointment(String id) async {
    try {
      final response = await _dioClient.delete(AppointmentEndpoints.cancelAppointment(id));
      final rawData = response.data['data'] ?? response.data;
      return Appointment.fromJson(rawData);
    } catch (e) {
      debugPrint('❌ cancelAppointment failed: $e');
      rethrow;
    }
  }
}
