import 'package:flutter/foundation.dart';
import '../../../core/models/prakriti_models.dart';
import '../../../core/network/dio_client.dart';

class PrakritiService {
  final DioClient _dioClient = DioClient();

  Future<List<PrakritiQuestion>> getQuestions() async {
    try {
      final response = await _dioClient.get('/prakriti/questions');
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => PrakritiQuestion.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getQuestions failed: $e');
      rethrow;
    }
  }

  Future<PrakritiAssessmentResult> submitAssessment(Map<String, String> answers) async {
    try {
      final response = await _dioClient.post(
        '/prakriti/submit',
        data: {'answers': answers},
      );
      final rawData = response.data['data'] ?? response.data;
      return PrakritiAssessmentResult.fromJson(rawData);
    } catch (e) {
      debugPrint('❌ submitAssessment failed: $e');
      rethrow;
    }
  }

  Future<PrakritiAssessmentResult?> getLatestAssessment() async {
    try {
      final response = await _dioClient.get('/prakriti/latest');
      final rawData = response.data['data'] ?? response.data;
      if (rawData == null) return null;
      return PrakritiAssessmentResult.fromJson(rawData);
    } catch (e) {
      // If 404 is returned (no assessment yet), return null
      if (e.toString().contains('404')) {
        return null;
      }
      debugPrint('❌ getLatestAssessment failed: $e');
      rethrow;
    }
  }
}
