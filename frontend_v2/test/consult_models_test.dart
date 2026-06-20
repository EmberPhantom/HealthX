import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_v2/core/models/consult_models.dart';
import 'package:frontend_v2/features/consults/services/consult_service.dart';
import 'package:frontend_v2/features/consults/providers/consults_provider.dart';

void main() {
  group('AvailableSlot', () {
    test('fromJson parses correctly', () {
      final slot = AvailableSlot.fromJson({
        'day': 'Monday',
        'times': ['09:00 AM', '10:00 AM'],
      });
      expect(slot.day, 'Monday');
      expect(slot.times, ['09:00 AM', '10:00 AM']);
    });

    test('fromJson handles missing fields', () {
      final slot = AvailableSlot.fromJson({});
      expect(slot.day, '');
      expect(slot.times, isEmpty);
    });

    test('equality works', () {
      final a = AvailableSlot(day: 'Mon', times: ['9:00']);
      final b = AvailableSlot(day: 'Mon', times: ['9:00']);
      final c = AvailableSlot(day: 'Tue', times: ['9:00']);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('Doctor', () {
    final sampleJson = {
      '_id': 'doc1',
      'name': 'Dr. Sharma',
      'specialty': 'Cardiologist',
      'qualification': 'MD',
      'experience': 15,
      'consultationFee': 800,
      'rating': 4.5,
      'reviewCount': 120,
      'avatarUrl': 'https://example.com/avatar.jpg',
      'clinicName': 'Heart Care Clinic',
      'address': '123 Main St',
      'city': 'Mumbai',
      'languages': ['Hindi', 'English'],
      'availableSlots': [
        {'day': 'Monday', 'times': ['10:00', '11:00']},
      ],
      'isActive': true,
    };

    test('fromJson parses full data', () {
      final doctor = Doctor.fromJson(sampleJson);
      expect(doctor.id, 'doc1');
      expect(doctor.name, 'Dr. Sharma');
      expect(doctor.specialty, 'Cardiologist');
      expect(doctor.qualification, 'MD');
      expect(doctor.experience, 15);
      expect(doctor.consultationFee, 800.0);
      expect(doctor.rating, 4.5);
      expect(doctor.reviewCount, 120);
      expect(doctor.avatarUrl, 'https://example.com/avatar.jpg');
      expect(doctor.clinicName, 'Heart Care Clinic');
      expect(doctor.address, '123 Main St');
      expect(doctor.city, 'Mumbai');
      expect(doctor.languages, ['Hindi', 'English']);
      expect(doctor.availableSlots.length, 1);
      expect(doctor.availableSlots[0].day, 'Monday');
      expect(doctor.isActive, true);
    });

    test('fromJson handles fallback field names', () {
      final doctor = Doctor.fromJson({
        'id': 'doc2',
        'name': 'Dr. Patel',
        'specialty': 'Neurologist',
        'qual': 'DM', // fallback for qualification
        'experience': 10,
        'fee': 1000, // fallback for consultationFee
        'clinic': 'Neuro Center', // fallback for clinicName
        'city': 'Delhi',
        'languages': ['Hindi'],
        'availableSlots': [],
      });
      expect(doctor.id, 'doc2');
      expect(doctor.qualification, 'DM');
      expect(doctor.consultationFee, 1000.0);
      expect(doctor.clinicName, 'Neuro Center');
    });

    test('fromJson handles missing fields', () {
      final doctor = Doctor.fromJson({});
      expect(doctor.id, '');
      expect(doctor.name, '');
      expect(doctor.rating, 5.0);
      expect(doctor.isActive, true);
      expect(doctor.availableSlots, isEmpty);
    });

    test('toJson roundtrip', () {
      final original = Doctor.fromJson(sampleJson);
      final json = original.toJson();
      final restored = Doctor.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.consultationFee, original.consultationFee);
    });
  });

  group('Appointment', () {
    final baseJson = {
      '_id': 'apt1',
      'doctorId': 'doc1',
      'appointmentDate': '2026-06-20T10:00:00.000Z',
      'timeSlot': '10:00 AM',
      'type': 'in-person',
      'status': 'confirmed',
      'symptoms': 'Chest pain',
      'notes': 'Follow-up',
      'consultationFee': 800,
      'isPaid': false,
    };

    test('fromJson parses with doctorId as string', () {
      final appt = Appointment.fromJson(baseJson);
      expect(appt.id, 'apt1');
      expect(appt.doctorId, 'doc1');
      expect(appt.doctor, isNull);
      expect(appt.appointmentDate.year, 2026);
      expect(appt.timeSlot, '10:00 AM');
      expect(appt.status, 'confirmed');
      expect(appt.symptoms, 'Chest pain');
      expect(appt.consultationFee, 800.0);
      expect(appt.isPaid, false);
    });

    test('fromJson parses with doctorId as Map', () {
      final appt = Appointment.fromJson({
        ...baseJson,
        'doctorId': {
          '_id': 'doc1',
          'name': 'Dr. Sharma',
          'specialty': 'Cardiologist',
          'qualification': 'MD',
          'experience': 15,
          'consultationFee': 800,
          'rating': 4.5,
          'reviewCount': 120,
          'clinicName': 'Clinic',
          'address': 'Addr',
          'city': 'Mumbai',
          'languages': ['Hindi'],
          'availableSlots': [],
          'isActive': true,
        },
      });
      expect(appt.doctorId, 'doc1');
      expect(appt.doctor, isNotNull);
      expect(appt.doctor!.name, 'Dr. Sharma');
    });

    test('fromJson parses with doctor field', () {
      final appt = Appointment.fromJson({
        ...baseJson,
        'doctorId': 'doc1',
        'doctor': {
          '_id': 'doc1',
          'name': 'Dr. Sharma',
          'specialty': 'Cardiologist',
          'qualification': 'MD',
          'experience': 15,
          'consultationFee': 800,
          'rating': 4.5,
          'reviewCount': 120,
          'clinicName': 'Clinic',
          'address': 'Addr',
          'city': 'Mumbai',
          'languages': ['Hindi'],
          'availableSlots': [],
          'isActive': true,
        },
      });
      expect(appt.doctorId, 'doc1');
      expect(appt.doctor, isNotNull);
      expect(appt.doctor!.name, 'Dr. Sharma');
    });

    test('fromJson handles missing fields', () {
      final appt = Appointment.fromJson({});
      expect(appt.id, '');
      expect(appt.doctorId, '');
      expect(appt.status, 'pending');
      expect(appt.isPaid, false);
    });

    test('toJson roundtrip', () {
      final original = Appointment.fromJson(baseJson);
      final json = original.toJson();
      final restored = Appointment.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.doctorId, original.doctorId);
      expect(restored.timeSlot, original.timeSlot);
    });
  });

  group('ChatMessage', () {
    test('fromJson parses correctly', () {
      final msg = ChatMessage.fromJson({
        '_id': 'msg1',
        'senderId': 'user1',
        'senderName': 'You',
        'text': 'Hello doctor',
        'timestamp': '2026-06-12T10:00:00.000Z',
      });
      expect(msg.id, 'msg1');
      expect(msg.senderId, 'user1');
      expect(msg.senderName, 'You');
      expect(msg.text, 'Hello doctor');
      expect(msg.timestamp.year, 2026);
    });

    test('fromJson handles missing fields', () {
      final msg = ChatMessage.fromJson({});
      expect(msg.id, '');
      expect(msg.text, '');
    });

    test('toJson returns only text field', () {
      final msg = ChatMessage(id: 'm1', senderId: 'u1', senderName: 'Me', text: 'Hi', timestamp: DateTime(2026));
      final json = msg.toJson();
      expect(json['text'], 'Hi');
      expect(json.containsKey('senderId'), false);
    });
  });

  group('Prescription', () {
    test('fromJson parses correctly', () {
      final p = Prescription.fromJson({
        '_id': 'rx1',
        'appointmentId': 'apt1',
        'doctorNotes': 'Take with food',
        'medications': [
          {'name': 'Aspirin', 'dosage': '100mg', 'frequency': 'Once daily', 'duration': '7 days'},
        ],
        'issuedAt': '2026-06-12T10:00:00.000Z',
      });
      expect(p.id, 'rx1');
      expect(p.doctorNotes, 'Take with food');
      expect(p.medications.length, 1);
      expect(p.medications[0].name, 'Aspirin');
      expect(p.medications[0].dosage, '100mg');
      expect(p.medications[0].frequency, 'Once daily');
      expect(p.medications[0].duration, '7 days');
    });

    test('fromJson handles missing fields', () {
      final p = Prescription.fromJson({});
      expect(p.id, '');
      expect(p.medications, isEmpty);
      expect(p.doctorNotes, isNull);
    });
  });

  group('ConsultsState', () {
    test('default state has all empty/false values', () {
      const state = ConsultsState();
      expect(state.doctors, isEmpty);
      expect(state.appointments, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('copyWith updates specified fields', () {
      const state = ConsultsState();
      final updated = state.copyWith(isLoading: true, error: 'Something went wrong');
      expect(updated.isLoading, true);
      expect(updated.error, 'Something went wrong');
      expect(updated.doctors, isEmpty);
    });

    test('copyWith preserves unset fields', () {
      final state = ConsultsState(
        doctors: [Doctor(
          id: 'd1', name: 'Dr. A', specialty: 'Cardio', qualification: 'MD',
          experience: 10, consultationFee: 500, rating: 4.0, reviewCount: 10,
          clinicName: 'C', address: 'A', city: 'M', languages: ['E'],
          availableSlots: [], isActive: true,
        )],
        appointments: [Appointment(
          id: 'a1', doctorId: 'd1', appointmentDate: DateTime(2026),
          timeSlot: '10AM', type: 'in-person', status: 'confirmed',
          consultationFee: 500, isPaid: false,
        )],
      );
      final updated = state.copyWith(isLoading: true);
      expect(updated.doctors.length, 1);
      expect(updated.appointments.length, 1);
      expect(updated.isLoading, true);
    });
  });
}
