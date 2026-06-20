import 'package:flutter/foundation.dart';
import '../../../core/models/consult_models.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/dio_client.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? json['sender'] ?? '',
      text: json['text'] ?? json['message'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'])?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
  };
}

class Prescription {
  final String id;
  final String appointmentId;
  final String? doctorNotes;
  final List<PrescribedMedication> medications;
  final DateTime issuedAt;

  const Prescription({
    required this.id,
    required this.appointmentId,
    this.doctorNotes,
    required this.medications,
    required this.issuedAt,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    final medsList = json['medications'] as List? ?? [];
    return Prescription(
      id: json['_id'] ?? json['id'] ?? '',
      appointmentId: json['appointmentId'] ?? '',
      doctorNotes: json['doctorNotes'],
      medications: medsList.map((m) => PrescribedMedication.fromJson(m as Map<String, dynamic>)).toList(),
      issuedAt: json['issuedAt'] != null
          ? DateTime.tryParse(json['issuedAt'])?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class PrescribedMedication {
  final String name;
  final String dosage;
  final String frequency;
  final String? duration;

  const PrescribedMedication({
    required this.name,
    required this.dosage,
    required this.frequency,
    this.duration,
  });

  factory PrescribedMedication.fromJson(Map<String, dynamic> json) {
    return PrescribedMedication(
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
      duration: json['duration'],
    );
  }
}

class ConsultService {
  final DioClient _dioClient = DioClient();

  Future<List<Doctor>> getDoctors() async {
    try {
      final response = await _dioClient.get(DoctorEndpoints.getDoctors);
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => Doctor.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getDoctors failed: $e');
      rethrow;
    }
  }

  Future<Doctor> getDoctor(String id) async {
    try {
      final response = await _dioClient.get(DoctorEndpoints.getDoctor(id));
      return Doctor.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('❌ getDoctor failed: $e');
      rethrow;
    }
  }

  Future<List<String>> getDoctorSlots(String doctorId, {required DateTime date}) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await _dioClient.get(
        DoctorEndpoints.getDoctorSlots(doctorId),
        queryParameters: {'date': dateStr},
      );
      final list = response.data['data'] as List? ?? [];
      return List<String>.from(list);
    } catch (e) {
      debugPrint('❌ getDoctorSlots failed: $e');
      rethrow;
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
      return Appointment.fromJson(response.data['data']);
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
      rethrow;
    }
  }

  Future<Appointment> getAppointment(String id) async {
    try {
      final response = await _dioClient.get(AppointmentEndpoints.getAppointment(id));
      return Appointment.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('❌ getAppointment failed: $e');
      rethrow;
    }
  }

  Future<Appointment> cancelAppointment(String id) async {
    try {
      final response = await _dioClient.delete(AppointmentEndpoints.cancelAppointment(id));
      return Appointment.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('❌ cancelAppointment failed: $e');
      rethrow;
    }
  }

  Future<Appointment> rescheduleAppointment(String id, DateTime newDate, String timeSlot) async {
    try {
      final response = await _dioClient.put(
        AppointmentEndpoints.rescheduleAppointment(id),
        data: {
          'appointmentDate': newDate.toIso8601String(),
          'timeSlot': timeSlot,
        },
      );
      return Appointment.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('❌ rescheduleAppointment failed: $e');
      rethrow;
    }
  }

  Future<List<ChatMessage>> getChatMessages(String appointmentId) async {
    try {
      final response = await _dioClient.get(ChatEndpoints.getMessages(appointmentId));
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => ChatMessage.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getChatMessages failed: $e');
      return [];
    }
  }

  Future<ChatMessage?> sendChatMessage(String appointmentId, String text) async {
    try {
      final response = await _dioClient.post(
        ChatEndpoints.sendMessage(appointmentId),
        data: {'text': text},
      );
      return ChatMessage.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('❌ sendChatMessage failed: $e');
      return null;
    }
  }

  Future<Prescription?> getPrescription(String appointmentId) async {
    try {
      final response = await _dioClient.get(PrescriptionEndpoints.getPrescription(appointmentId));
      return Prescription.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('❌ getPrescription failed: $e');
      return null;
    }
  }

  Future<List<String>> getSpecialties() async {
    try {
      final response = await _dioClient.get('/doctors/specialties');
      final list = response.data['data'] as List? ?? [];
      return List<String>.from(list);
    } catch (e) {
      debugPrint('❌ getSpecialties failed: $e');
      return [];
    }
  }
}
