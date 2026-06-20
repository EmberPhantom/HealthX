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
      loggedAt: json['loggedAt'] != null ? DateTime.tryParse(json['loggedAt']) ?? DateTime.now() : DateTime.now(),
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
      bedtime: json['bedtime'] != null ? DateTime.tryParse(json['bedtime'])?.toLocal() ?? DateTime.now() : DateTime.now(),
      wakeTime: json['wakeTime'] != null ? DateTime.tryParse(json['wakeTime'])?.toLocal() ?? DateTime.now() : DateTime.now(),
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
      loggedAt: json['loggedAt'] != null ? DateTime.tryParse(json['loggedAt'])?.toLocal() ?? DateTime.now() : DateTime.now(),
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

class VitalsLog extends Equatable {
  final String id;
  final String date;
  final String time;
  final String? bp; // e.g. "120/80"
  final int? pulse;
  final double? temperature;
  final double? weight;
  final int? spo2;
  final int? exerciseMins;

  const VitalsLog({
    required this.id,
    required this.date,
    required this.time,
    this.bp,
    this.pulse,
    this.temperature,
    this.weight,
    this.spo2,
    this.exerciseMins,
  });

  factory VitalsLog.fromJson(Map<String, dynamic> json) {
    return VitalsLog(
      id: json['_id'] ?? json['id'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      bp: json['bp'],
      pulse: json['pulse'] != null ? (json['pulse'] as num).toInt() : null,
      temperature: json['temperature'] != null ? (json['temperature'] as num).toDouble() : null,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      spo2: json['spo2'] != null ? (json['spo2'] as num).toInt() : null,
      exerciseMins: json['exerciseMins'] != null ? (json['exerciseMins'] as num).toInt() : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'time': time,
    'bp': bp,
    'pulse': pulse,
    'temperature': temperature,
    'weight': weight,
    'spo2': spo2,
    'exerciseMins': exerciseMins,
  };

  @override
  List<Object?> get props => [id, date, time, bp, pulse, temperature, weight, spo2, exerciseMins];
}

class MeasurementLog extends Equatable {
  final String id;
  final double? weight;
  final double? height;
  final double? bmi;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? bodyFatPercent;
  final DateTime loggedAt;

  const MeasurementLog({
    required this.id,
    this.weight,
    this.height,
    this.bmi,
    this.chest,
    this.waist,
    this.hips,
    this.bodyFatPercent,
    required this.loggedAt,
  });

  factory MeasurementLog.fromJson(Map<String, dynamic> json) {
    return MeasurementLog(
      id: json['_id'] ?? json['id'] ?? '',
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
      bmi: json['bmi'] != null ? (json['bmi'] as num).toDouble() : null,
      chest: json['chest'] != null ? (json['chest'] as num).toDouble() : null,
      waist: json['waist'] != null ? (json['waist'] as num).toDouble() : null,
      hips: json['hips'] != null ? (json['hips'] as num).toDouble() : null,
      bodyFatPercent: json['bodyFatPercent'] != null ? (json['bodyFatPercent'] as num).toDouble() : null,
      loggedAt: json['loggedAt'] != null ? DateTime.tryParse(json['loggedAt'])?.toLocal() ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'weight': weight,
    'height': height,
    'bmi': bmi,
    'chest': chest,
    'waist': waist,
    'hips': hips,
    'bodyFatPercent': bodyFatPercent,
    'loggedAt': loggedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, weight, height, bmi, chest, waist, hips, bodyFatPercent, loggedAt];
}

class InsulinLog extends Equatable {
  final String id;
  final int dose;
  final String insulinType;
  final String injectionSite;
  final String mealContext;
  final String? note;
  final DateTime loggedAt;

  const InsulinLog({
    required this.id,
    required this.dose,
    required this.insulinType,
    required this.injectionSite,
    required this.mealContext,
    this.note,
    required this.loggedAt,
  });

  factory InsulinLog.fromJson(Map<String, dynamic> json) {
    return InsulinLog(
      id: json['_id'] ?? json['id'] ?? '',
      dose: json['dose'] ?? 0,
      insulinType: json['insulinType'] ?? '',
      injectionSite: json['injectionSite'] ?? '',
      mealContext: json['mealContext'] ?? '',
      note: json['note'],
      loggedAt: json['loggedAt'] != null ? DateTime.tryParse(json['loggedAt'])?.toLocal() ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'dose': dose,
    'insulinType': insulinType,
    'injectionSite': injectionSite,
    'mealContext': mealContext,
    'note': note,
    'loggedAt': loggedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, dose, insulinType, injectionSite, mealContext, note, loggedAt];
}
