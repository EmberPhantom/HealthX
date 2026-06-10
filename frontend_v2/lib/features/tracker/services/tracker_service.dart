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
      final rawData = response.data['data'] ?? response.data;
      return WaterLog.fromJson(rawData);
    } catch (e) {
      debugPrint('❌ logWater failed: $e');
      rethrow;
    }
  }

  Future<List<WaterLog>> getWaterLogs({DateTime? startDate, DateTime? endDate}) async {
    try {
      final response = await _dioClient.get(
        TrackerEndpoints.water,
        queryParameters: {
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
        },
      );
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => WaterLog.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getWaterLogs failed: $e');
      return [];
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
      final rawData = response.data['data'] ?? response.data;
      return SleepLog.fromJson(rawData);
    } catch (e) {
      debugPrint('❌ logSleep failed: $e');
      rethrow;
    }
  }

  Future<List<SleepLog>> getSleepLogs() async {
    try {
      final response = await _dioClient.get(TrackerEndpoints.sleep);
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => SleepLog.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getSleepLogs failed: $e');
      return [];
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
      final rawData = response.data['data'] ?? response.data;
      return StepLog.fromJson(rawData);
    } catch (e) {
      debugPrint('❌ logSteps failed: $e');
      rethrow;
    }
  }

  Future<List<StepLog>> getStepLogs({String? startDate, String? endDate}) async {
    try {
      final response = await _dioClient.get(
        TrackerEndpoints.steps,
        queryParameters: {
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
        },
      );
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => StepLog.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getStepLogs failed: $e');
      return [];
    }
  }

  Future<GlucoseLog> logGlucose(int level, String readingType, [String? note]) async {
    try {
      final response = await _dioClient.post(
        TrackerEndpoints.glucose,
        data: {
          'level': level,
          'readingType': readingType,
          if (note != null) 'note': note,
        },
      );
      final rawData = response.data['data'] ?? response.data;
      return GlucoseLog.fromJson(rawData);
    } catch (e) {
      debugPrint('❌ logGlucose failed: $e');
      rethrow;
    }
  }

  Future<List<GlucoseLog>> getGlucoseLogs() async {
    try {
      final response = await _dioClient.get(TrackerEndpoints.glucose);
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => GlucoseLog.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getGlucoseLogs failed: $e');
      return [];
    }
  }
}
