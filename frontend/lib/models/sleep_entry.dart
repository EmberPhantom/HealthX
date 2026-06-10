// lib/models/sleep_entry.dart

class SleepEntry {
  final DateTime bedtime;
  final DateTime wakeTime;
  final String date;

  SleepEntry({
    required this.bedtime,
    required this.wakeTime,
    required this.date,
  });

  Duration get duration {
    final diff = wakeTime.difference(bedtime);
    return diff.isNegative ? Duration.zero : diff;
  }

  double get totalHours => duration.inMinutes / 60.0;
  int get hours   => duration.inHours;
  int get minutes => duration.inMinutes % 60;

  String get durationLabel {
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  // ─── Quality Score — 7h 10m = 100% (430 mins perfect) ──────────────────
  // Curve: rises linearly to 430 min (100%), drops symmetrically after
  // Below 4h → 0%, Above 11h → capped at 60% (oversleeping penalty)
  int get qualityScore {
    final mins = duration.inMinutes;

    if (mins <= 0)   return 0;
    if (mins < 240)  {
      // < 4h: 0% → 30% linearly
      return ((mins / 240.0) * 30).round();
    }
    if (mins < 430)  {
      // 4h → 7h10m: 30% → 100% linearly
      return (30 + ((mins - 240) / (430 - 240)) * 70).round();
    }
    if (mins == 430) return 100; // ✅ 7h 10m = perfect 100%
    if (mins <= 480) {
      // 7h10m → 8h: 100% → 95% (slightly over but fine)
      return (100 - ((mins - 430) / (480 - 430)) * 5).round();
    }
    if (mins <= 540) {
      // 8h → 9h: 95% → 85%
      return (95 - ((mins - 480) / (540 - 480)) * 10).round();
    }
    if (mins <= 660) {
      // 9h → 11h: 85% → 60% (oversleep penalty)
      return (85 - ((mins - 540) / (660 - 540)) * 25).round();
    }
    // > 11h: capped at 60%
    return 60;
  }

  String get qualityEmoji {
    final q = qualityScore;
    if (q >= 95) return '🌟';
    if (q >= 85) return '😊';
    if (q >= 70) return '😐';
    if (q >= 50) return '😴';
    if (q >= 30) return '😰';
    return '🥱';
  }

  String get qualityLabel {
    final q = qualityScore;
    if (q >= 95) return 'Perfect';
    if (q >= 85) return 'Great';
    if (q >= 70) return 'Good';
    if (q >= 50) return 'Fair';
    if (q >= 30) return 'Poor';
    return 'Very Poor';
  }

  // Sleep phase estimates
  Duration get deepSleep  => Duration(minutes: (duration.inMinutes * 0.22).round());
  Duration get lightSleep => Duration(minutes: (duration.inMinutes * 0.53).round());
  Duration get remSleep   => Duration(minutes: (duration.inMinutes * 0.20).round());

  String _durationStr(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  String get deepSleepLabel  => _durationStr(deepSleep);
  String get lightSleepLabel => _durationStr(lightSleep);
  String get remSleepLabel   => _durationStr(remSleep);

  double get ringProgress => (totalHours / 7.166).clamp(0.0, 1.0); // 7h10m = 100%

  String get bedtimeLabel {
    final h = bedtime.hour;
    final m = bedtime.minute;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${hour12}:${m.toString().padLeft(2, '0')} $period'.toLowerCase();
  }

  String get wakeTimeLabel {
    final h = wakeTime.hour;
    final m = wakeTime.minute;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${hour12}:${m.toString().padLeft(2, '0')} $period'.toLowerCase();
  }

  String get insightText {
    final q = qualityScore;
    final h = totalHours;
    if (q >= 95) return 'Perfect sleep! 7h 10m is your ideal sweet spot. You\'re fully recharged!';
    if (q >= 85) return 'Great sleep! You got quality rest and your body is well recovered.';
    if (q >= 70) return 'Good sleep. You\'re close to your ideal. Try for 7h 10m tonight!';
    if (h < 4)   return 'Very short sleep. Aim for at least 7 hours for optimal health.';
    if (h < 6)   return 'Sleep was short. Your body needs more rest to fully recover.';
    if (h > 9)   return 'You slept a lot! Oversleeping can cause grogginess. 7-8h is ideal.';
    return 'You can improve your sleep. Try a consistent 10 PM bedtime routine.';
  }

  Map<String, dynamic> toJson() => {
    'bedtime':  bedtime.millisecondsSinceEpoch,
    'wakeTime': wakeTime.millisecondsSinceEpoch,
    'date':     date,
  };

  factory SleepEntry.fromJson(Map<String, dynamic> json) => SleepEntry(
    bedtime:  DateTime.fromMillisecondsSinceEpoch(json['bedtime'] as int),
    wakeTime: DateTime.fromMillisecondsSinceEpoch(json['wakeTime'] as int),
    date:     json['date'] as String,
  );

  static String dateKey(DateTime dt) =>
      '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
}