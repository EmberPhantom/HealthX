import 'package:equatable/equatable.dart';

class AvailableSlot extends Equatable {
  final String day;
  final List<String> times;

  const AvailableSlot({required this.day, required this.times});

  factory AvailableSlot.fromJson(Map<String, dynamic> json) {
    return AvailableSlot(
      day: json['day'] ?? '',
      times: List<String>.from(json['times'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'day': day,
    'times': times,
  };

  @override
  List<Object?> get props => [day, times];
}

class Doctor extends Equatable {
  final String id;
  final String name;
  final String specialty;
  final String qualification;
  final int experience;
  final double consultationFee;
  final double rating;
  final int reviewCount;
  final String? avatarUrl;
  final String clinicName;
  final String address;
  final String city;
  final List<String> languages;
  final List<AvailableSlot> availableSlots;
  final bool isActive;

  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.qualification,
    required this.experience,
    required this.consultationFee,
    required this.rating,
    required this.reviewCount,
    this.avatarUrl,
    required this.clinicName,
    required this.address,
    required this.city,
    required this.languages,
    required this.availableSlots,
    required this.isActive,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    final slotsList = json['availableSlots'] as List? ?? [];
    return Doctor(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? '',
      qualification: json['qualification'] ?? '',
      experience: json['experience'] ?? 0,
      consultationFee: (json['consultationFee'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: json['reviewCount'] ?? 0,
      avatarUrl: json['avatarUrl'],
      clinicName: json['clinicName'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      languages: List<String>.from(json['languages'] ?? []),
      availableSlots: slotsList.map((s) => AvailableSlot.fromJson(s as Map<String, dynamic>)).toList(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'specialty': specialty,
    'qualification': qualification,
    'experience': experience,
    'consultationFee': consultationFee,
    'rating': rating,
    'reviewCount': reviewCount,
    'avatarUrl': avatarUrl,
    'clinicName': clinicName,
    'address': address,
    'city': city,
    'languages': languages,
    'availableSlots': availableSlots.map((s) => s.toJson()).toList(),
    'isActive': isActive,
  };

  @override
  List<Object?> get props => [
    id, name, specialty, qualification, experience, consultationFee,
    rating, reviewCount, avatarUrl, clinicName, address, city,
    languages, availableSlots, isActive
  ];
}

class Appointment extends Equatable {
  final String id;
  final String doctorId;
  final Doctor? doctor;
  final DateTime appointmentDate;
  final String timeSlot;
  final String type;
  final String status;
  final String? symptoms;
  final String? notes;
  final double consultationFee;
  final bool isPaid;

  const Appointment({
    required this.id,
    required this.doctorId,
    this.doctor,
    required this.appointmentDate,
    required this.timeSlot,
    required this.type,
    required this.status,
    this.symptoms,
    this.notes,
    required this.consultationFee,
    required this.isPaid,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    Doctor? doctorObj;
    String docId = '';
    if (json['doctorId'] is Map<String, dynamic>) {
      doctorObj = Doctor.fromJson(json['doctorId']);
      docId = doctorObj.id;
    } else if (json['doctorId'] is String) {
      docId = json['doctorId'];
    }

    return Appointment(
      id: json['_id'] ?? json['id'] ?? '',
      doctorId: docId,
      doctor: doctorObj,
      appointmentDate: json['appointmentDate'] != null
          ? DateTime.parse(json['appointmentDate']).toLocal()
          : DateTime.now(),
      timeSlot: json['timeSlot'] ?? '',
      type: json['type'] ?? 'in-person',
      status: json['status'] ?? 'pending',
      symptoms: json['symptoms'],
      notes: json['notes'],
      consultationFee: (json['consultationFee'] as num?)?.toDouble() ?? 0.0,
      isPaid: json['isPaid'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'doctorId': doctorId,
    'appointmentDate': appointmentDate.toIso8601String(),
    'timeSlot': timeSlot,
    'type': type,
    'status': status,
    'symptoms': symptoms,
    'notes': notes,
    'consultationFee': consultationFee,
    'isPaid': isPaid,
  };

  @override
  List<Object?> get props => [
    id, doctorId, doctor, appointmentDate, timeSlot, type, status,
    symptoms, notes, consultationFee, isPaid
  ];
}
