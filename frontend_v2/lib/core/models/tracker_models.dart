import 'package:equatable/equatable.dart';

class WaterLog extends Equatable {
  final String id;
  final int amount;
  final DateTime loggedAt;

  const WaterLog({
    required this.id,
    required this.amount,
    required this.loggedAt,
  });

  factory WaterLog.fromJson(Map<String, dynamic> json) {
    return WaterLog(
      id: json['_id'] ?? json['id'] ?? '',
      amount: json['amount'] ?? 0,
      loggedAt: json['loggedAt'] != null ? DateTime.parse(json['loggedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'loggedAt': loggedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, amount, loggedAt];
}

class SleepLog extends Equatable {
  final String id;
  final DateTime bedtime;
  final DateTime wakeTime;
  final String dateKey;

  const SleepLog({
    required this.id,
    required this.bedtime,
    required this.wakeTime,
    required this.dateKey,
  });

  factory SleepLog.fromJson(Map<String, dynamic> json) {
    return SleepLog(
      id: json['_id'] ?? json['id'] ?? '',
      bedtime: json['bedtime'] != null ? DateTime.parse(json['bedtime']).toLocal() : DateTime.now(),
      wakeTime: json['wakeTime'] != null ? DateTime.parse(json['wakeTime']).toLocal() : DateTime.now(),
      dateKey: json['dateKey'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bedtime': bedtime.toIso8601String(),
    'wakeTime': wakeTime.toIso8601String(),
    'dateKey': dateKey,
  };

  @override
  List<Object?> get props => [id, bedtime, wakeTime, dateKey];
}

class StepLog extends Equatable {
  final String id;
  final int steps;
  final String dateKey;

  const StepLog({
    required this.id,
    required this.steps,
    required this.dateKey,
  });

  factory StepLog.fromJson(Map<String, dynamic> json) {
    return StepLog(
      id: json['_id'] ?? json['id'] ?? '',
      steps: json['steps'] ?? 0,
      dateKey: json['dateKey'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'steps': steps,
    'dateKey': dateKey,
  };

  @override
  List<Object?> get props => [id, steps, dateKey];
}

class GlucoseLog extends Equatable {
  final String id;
  final int level;
  final String readingType;
  final String? note;
  final DateTime loggedAt;

  const GlucoseLog({
    required this.id,
    required this.level,
    required this.readingType,
    this.note,
    required this.loggedAt,
  });

  factory GlucoseLog.fromJson(Map<String, dynamic> json) {
    return GlucoseLog(
      id: json['_id'] ?? json['id'] ?? '',
      level: json['level'] ?? 0,
      readingType: json['readingType'] ?? 'random',
      note: json['note'],
      loggedAt: json['loggedAt'] != null ? DateTime.parse(json['loggedAt']).toLocal() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'level': level,
    'readingType': readingType,
    'note': note,
    'loggedAt': loggedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, level, readingType, note, loggedAt];
}
