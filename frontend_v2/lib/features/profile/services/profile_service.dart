import 'package:flutter/foundation.dart';
import '../../../core/network/dio_client.dart';

class SupportFaq {
  final String question;
  final String answer;

  const SupportFaq({required this.question, required this.answer});

  factory SupportFaq.fromJson(Map<String, dynamic> json) {
    return SupportFaq(
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
    );
  }
}

class SupportInfo {
  final String email;
  final String whatsapp;
  final List<SupportFaq> faqs;

  const SupportInfo({
    required this.email,
    required this.whatsapp,
    required this.faqs,
  });

  factory SupportInfo.fromJson(Map<String, dynamic> json) {
    final faqsList = json['faqs'] as List? ?? [];
    return SupportInfo(
      email: json['email'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
      faqs: faqsList.map((f) => SupportFaq.fromJson(f as Map<String, dynamic>)).toList(),
    );
  }
}

class ProfileService {
  final DioClient _dioClient = DioClient();

  Future<SupportInfo> getSupportInfo() async {
    try {
      final response = await _dioClient.get('/content/support-info');
      return SupportInfo.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('❌ getSupportInfo failed: $e');
      rethrow;
    }
  }
}
