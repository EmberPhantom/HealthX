import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/models/meal_models.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'package:intl/intl.dart';

class MealService {
  final DioClient _dioClient = DioClient();

  /// Returns the logged MealLog and an optional AI inline warning.
  /// The warning is non-null only when the meal conflicts with the user's AI health profile.
  Future<(MealLog, String?)> logMeal(Map<String, dynamic> mealData) async {
    try {
      final response = await _dioClient.post(
        MealEndpoints.log,
        data: mealData,
      );
      final log = MealLog.fromJson(response.data['data']);
      final warning = response.data['warning'] as String?;
      return (log, warning);
    } catch (e) {
      debugPrint('❌ logMeal failed: $e');
      rethrow;
    }
  }

  Future<List<MealLog>> getMeals(DateTime date) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final response = await _dioClient.get(
        MealEndpoints.getMeals,
        queryParameters: {'date': dateStr},
      );
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => MealLog.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getMeals failed: $e');
      rethrow;
    }
  }

  Future<bool> deleteMeal(String id) async {
    try {
      final response = await _dioClient.delete(MealEndpoints.delete(id));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ deleteMeal failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> identifyMeal({
    String? text,
    String? imageUrl,
  }) async {
    try {
      final response = await _dioClient.post(
        MealEndpoints.identify,
        data: {
          if (text != null) 'text': text,
          if (imageUrl != null) 'imageUrl': imageUrl,
        },
      );
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ identifyMeal failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> identifyMealFromImage({
    required String imagePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
      });
      final response = await _dioClient.post(
        MealEndpoints.identifyImage,
        data: formData,
      );
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ identifyMealFromImage failed: $e');
      rethrow;
    }
  }
}
