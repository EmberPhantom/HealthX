import 'package:flutter/foundation.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/dio_client.dart';

/// Model for a single Step 5 question returned by the AI.
class AIStep5Question {
  final String id;
  final String text;
  final String type; // 'mcq' | 'boolean' | 'scale' | 'text'
  final List<String>? options; // Only for mcq
  final int? scaleMin;
  final int? scaleMax;
  final String? scaleLabel;

  const AIStep5Question({
    required this.id,
    required this.text,
    required this.type,
    this.options,
    this.scaleMin,
    this.scaleMax,
    this.scaleLabel,
  });

  factory AIStep5Question.fromJson(Map<String, dynamic> json) {
    return AIStep5Question(
      id: json['id'] as String? ?? 'q_unknown',
      text: json['text'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      options: (json['options'] as List?)?.map((e) => e.toString()).toList(),
      scaleMin: json['scaleMin'] as int?,
      scaleMax: json['scaleMax'] as int?,
      scaleLabel: json['scaleLabel'] as String?,
    );
  }
}

/// Model for a single Step 5 response being sent back to the server.
class AIStep5Response {
  final String questionId;
  final String questionText;
  final dynamic answer;

  const AIStep5Response({
    required this.questionId,
    required this.questionText,
    required this.answer,
  });

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'questionText': questionText,
        'answer': answer,
      };
}

/// Lightweight model for AI profile status polling.
class AIProfileStatus {
  final String status; // 'not_started' | 'pending' | 'complete' | 'error'
  final int version;
  final DateTime? generatedAt;

  const AIProfileStatus({
    required this.status,
    required this.version,
    this.generatedAt,
  });

  factory AIProfileStatus.fromJson(Map<String, dynamic> json) {
    return AIProfileStatus(
      status: json['status'] as String? ?? 'not_started',
      version: json['version'] as int? ?? 0,
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'].toString())
          : null,
    );
  }

  bool get isComplete => status == 'complete';
  bool get isPending => status == 'pending';
  bool get isNotStarted => status == 'not_started';
}

class AIHealthService {
  static final AIHealthService _instance = AIHealthService._internal();
  final DioClient _dioClient = DioClient();

  factory AIHealthService() => _instance;
  AIHealthService._internal();

  /// Fetch AI-generated Step 5 onboarding questions.
  /// The Accept-Language header is automatically set by the device locale.
  Future<List<AIStep5Question>> getStep5Questions() async {
    try {
      final response = await _dioClient.get(AIHealthEndpoints.step5Questions);
      final data = response.data;
      final raw = data is Map && data.containsKey('data') ? data['data'] : data;
      final questionsList = (raw['questions'] as List?) ?? [];
      return questionsList
          .map((q) => AIStep5Question.fromJson(q as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ getStep5Questions failed: $e');
      rethrow;
    }
  }

  /// Submit Step 5 responses and trigger background AI analysis.
  /// Returns immediately (HTTP 202) — analysis runs async.
  Future<String> submitAnalysis(List<AIStep5Response> responses) async {
    try {
      final response = await _dioClient.post(
        AIHealthEndpoints.submitAnalysis,
        data: {'responses': responses.map((r) => r.toJson()).toList()},
      );
      final data = response.data;
      final raw = data is Map && data.containsKey('data') ? data['data'] : data;
      return raw['jobId']?.toString() ?? 'queued';
    } catch (e) {
      debugPrint('❌ submitAnalysis failed: $e');
      rethrow;
    }
  }

  /// Poll the analysis status (lightweight — used by Home screen on load).
  Future<AIProfileStatus> getProfileStatus() async {
    try {
      final response = await _dioClient.get(AIHealthEndpoints.profileStatus);
      final data = response.data;
      final raw = data is Map && data.containsKey('data') ? data['data'] : data;
      return AIProfileStatus.fromJson(raw as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ getProfileStatus failed: $e');
      return const AIProfileStatus(status: 'not_started', version: 0);
    }
  }

  /// Get meal inline warning for a specific food item.
  /// Returns null if no warning applies.
  Future<String?> getMealWarning({
    required String foodName,
    List<String>? ingredients,
    double? carbs,
    double? calories,
  }) async {
    try {
      final params = <String, dynamic>{'foodName': foodName};
      if (ingredients != null && ingredients.isNotEmpty) {
        params['ingredients'] = ingredients.join(',');
      }
      if (carbs != null) params['carbs'] = carbs.toString();
      if (calories != null) params['calories'] = calories.toString();

      final response = await _dioClient.get(
        AIHealthEndpoints.mealWarning,
        queryParameters: params,
      );
      final data = response.data;
      final raw = data is Map && data.containsKey('data') ? data['data'] : data;
      return raw['warning'] as String?;
    } catch (e) {
      debugPrint('⚠️ getMealWarning failed (non-critical): $e');
      return null; // Non-critical — silently fail
    }
  }
}
