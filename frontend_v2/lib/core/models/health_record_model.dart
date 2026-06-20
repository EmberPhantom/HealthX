import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

enum RecordType { labTests, prescription, scans, other }

extension RecordTypeExtension on RecordType {
  String get label {
    switch (this) {
      case RecordType.labTests:
        return 'Lab Tests';
      case RecordType.prescription:
        return 'Prescription';
      case RecordType.scans:
        return 'Scans';
      case RecordType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case RecordType.labTests:
        return PhosphorIconsRegular.activity;
      case RecordType.prescription:
        return PhosphorIconsRegular.prescription;
      case RecordType.scans:
        return PhosphorIconsRegular.fileSearch;
      case RecordType.other:
        return PhosphorIconsRegular.folder;
    }
  }

  Color get color {
    switch (this) {
      case RecordType.labTests:
        return const Color(0xFF2196F3);
      case RecordType.prescription:
        return const Color(0xFF4CAF50);
      case RecordType.scans:
        return const Color(0xFF9C27B0);
      case RecordType.other:
        return const Color(0xFFFF9800);
    }
  }
}

class HealthRecord {
  final String id;
  final String name;
  final RecordType type;
  final DateTime date;
  final List<String> fileUrls;
  final String specialist;

  const HealthRecord({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    required this.fileUrls,
    this.specialist = '',
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'other';
    RecordType rType;
    switch (typeStr) {
      case 'labTests':
        rType = RecordType.labTests;
        break;
      case 'prescription':
        rType = RecordType.prescription;
        break;
      case 'scans':
        rType = RecordType.scans;
        break;
      default:
        rType = RecordType.other;
    }

    return HealthRecord(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      type: rType,
      date: json['date'] != null ? DateTime.tryParse(json['date']) ?? DateTime.now() : DateTime.now(),
      fileUrls: List<String>.from(json['fileUrls'] ?? []),
      specialist: json['specialist'] ?? '',
    );
  }
}
