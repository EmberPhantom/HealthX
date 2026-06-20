class PrakritiOption {
  final String key;
  final String text;

  const PrakritiOption({
    required this.key,
    required this.text,
  });

  factory PrakritiOption.fromJson(Map<String, dynamic> json) {
    return PrakritiOption(
      key: json['key'] ?? '',
      text: json['text'] ?? '',
    );
  }
}

class PrakritiQuestion {
  final String id;
  final String text;
  final List<PrakritiOption> options;

  const PrakritiQuestion({
    required this.id,
    required this.text,
    required this.options,
  });

  factory PrakritiQuestion.fromJson(Map<String, dynamic> json) {
    final list = json['options'] as List? ?? [];
    return PrakritiQuestion(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      options: list.map((item) => PrakritiOption.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}

class DoshaScores {
  final int vata;
  final int pitta;
  final int kapha;
  final int vataPct;
  final int pittaPct;
  final int kaphaPct;

  const DoshaScores({
    required this.vata,
    required this.pitta,
    required this.kapha,
    required this.vataPct,
    required this.pittaPct,
    required this.kaphaPct,
  });

  factory DoshaScores.fromJson(Map<String, dynamic> json) {
    return DoshaScores(
      vata: json['vata'] ?? 0,
      pitta: json['pitta'] ?? 0,
      kapha: json['kapha'] ?? 0,
      vataPct: json['vataPct'] ?? 0,
      pittaPct: json['pittaPct'] ?? 0,
      kaphaPct: json['kaphaPct'] ?? 0,
    );
  }
}

class DoshaProfile {
  final String title;
  final String description;
  final String advice;

  const DoshaProfile({
    required this.title,
    required this.description,
    required this.advice,
  });

  factory DoshaProfile.fromJson(Map<String, dynamic> json) {
    return DoshaProfile(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      advice: json['advice'] ?? '',
    );
  }
}

class PrakritiAssessmentResult {
  final String dominantDosha;
  final DoshaScores scores;
  final DoshaProfile profile;

  const PrakritiAssessmentResult({
    required this.dominantDosha,
    required this.scores,
    required this.profile,
  });

  factory PrakritiAssessmentResult.fromJson(Map<String, dynamic> json) {
    return PrakritiAssessmentResult(
      dominantDosha: json['dominantDosha'] ?? '',
      scores: DoshaScores.fromJson(json['scores'] ?? {}),
      profile: DoshaProfile.fromJson(json['profile'] ?? {}),
    );
  }
}
