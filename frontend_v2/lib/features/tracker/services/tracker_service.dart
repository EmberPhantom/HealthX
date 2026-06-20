import 'package:flutter/foundation.dart';
import '../../../core/models/tracker_models.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/dio_client.dart';

class TrackerService {
  final DioClient _dioClient = DioClient();

  Future<WaterLog> logWater(int amount, [DateTime? date]) async {
    try {
      final response = await _dioClient.post(
        TrackerEndpoints.water,
        data: {
          'amount': amount,
          if (date != null) 'date': date.toIso8601String(),
        },
      );
      return WaterLog.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('❌ logWater failed: $e');
      rethrow;
    }
  }

  Future<List<WaterLog>> getWaterLogs({DateTime? startDate, DateTime? endDate, int page = 1, int limit = 20}) async {
    try {
      final response = await _dioClient.get(
        TrackerEndpoints.water,
        queryParameters: {
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => WaterLog.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getWaterLogs failed: $e');
      rethrow;
    }
  }

  Future<SleepLog> logSleep(DateTime bedtime, DateTime wakeTime, String dateKey) async {
    try {
      final response = await _dioClient.post(
        TrackerEndpoints.sleep,
        data: {
          'bedtime': bedtime.toIso8601String(),
          'wakeTime': wakeTime.toIso8601String(),
          'dateKey': dateKey,
        },
      );
      return SleepLog.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('❌ logSleep failed: $e');
      rethrow;
    }
  }

  Future<List<SleepLog>> getSleepLogs({int page = 1, int limit = 30}) async {
    try {
      final response = await _dioClient.get(
        TrackerEndpoints.sleep,
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => SleepLog.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getSleepLogs failed: $e');
      rethrow;
    }
  }

  Future<StepLog> logSteps(int steps, String dateKey) async {
    try {
      final response = await _dioClient.post(
        TrackerEndpoints.steps,
        data: {
          'steps': steps,
          'dateKey': dateKey,
        },
      );
      return StepLog.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('❌ logSteps failed: $e');
      rethrow;
    }
  }

  Future<List<StepLog>> getStepLogs({String? startDate, String? endDate, int page = 1, int limit = 20}) async {
    try {
      final response = await _dioClient.get(
        TrackerEndpoints.steps,
        queryParameters: {
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => StepLog.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getStepLogs failed: $e');
      rethrow;
    }
  }

  /// Returns a record with the GlucoseLog and an optional AI inline comment.
  /// The inlineComment is non-null only for users with a complete AI health profile
  /// that has diabetes in the conditions list.
  Future<(GlucoseLog, String?)> logGlucose(int level, String readingType, [String? note]) async {
    try {
      final response = await _dioClient.post(
        TrackerEndpoints.glucose,
        data: {
          'level': level,
          'readingType': readingType,
          if (note != null) 'note': note,
        },
      );
      final log = GlucoseLog.fromJson(response.data['data']);
      final inlineComment = response.data['inlineComment'] as String?;
      return (log, inlineComment);
    } catch (e) {
      debugPrint('❌ logGlucose failed: $e');
      rethrow;
    }
  }

  Future<List<GlucoseLog>> getGlucoseLogs({int page = 1, int limit = 20}) async {
    try {
      final response = await _dioClient.get(
        TrackerEndpoints.glucose,
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => GlucoseLog.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getGlucoseLogs failed: $e');
      rethrow;
    }
  }

  Future<bool> deleteGlucose(String id) async {
    try {
      final response = await _dioClient.delete('${TrackerEndpoints.glucose}/$id');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ deleteGlucose failed: $e');
      rethrow;
    }
  }
}
