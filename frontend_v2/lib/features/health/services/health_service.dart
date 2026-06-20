import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/models/tracker_models.dart';
import '../../../core/models/health_record_model.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/dio_client.dart';

class HealthService {
  final DioClient _dioClient = DioClient();

  // ─── Vitals Log API ────────────────────────────────────────────────────────
  Future<VitalsLog> logVitals({
    required String date,
    required String time,
    String? bp,
    int? pulse,
    double? temperature,
    double? weight,
    int? spo2,
    int? exerciseMins,
  }) async {
    try {
      final response = await _dioClient.post(
        TrackerEndpoints.vitals,
        data: {
          'date': date,
          'time': time,
          if (bp != null) 'bp': bp,
          if (pulse != null) 'pulse': pulse,
          if (temperature != null) 'temperature': temperature,
          if (weight != null) 'weight': weight,
          if (spo2 != null) 'spo2': spo2,
          if (exerciseMins != null) 'exerciseMins': exerciseMins,
        },
      );
      final rawData = response.data['data'] ?? response.data;
      return VitalsLog.fromJson(rawData);
    } catch (e) {
      debugPrint('❌ logVitals failed: $e');
      rethrow;
    }
  }

  Future<List<VitalsLog>> getVitalsLogs({int page = 1, int limit = 20}) async {
    try {
      final response = await _dioClient.get(
        TrackerEndpoints.vitals,
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => VitalsLog.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getVitalsLogs failed: $e');
      rethrow;
    }
  }

  Future<bool> deleteVitalsLog(String id) async {
    try {
      final response = await _dioClient.delete('${TrackerEndpoints.vitals}/$id');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ deleteVitalsLog failed: $e');
      rethrow;
    }
  }

  // ─── Measurements Log API ──────────────────────────────────────────────────
  Future<MeasurementLog> logMeasurement({
    double? weight,
    double? height,
    double? chest,
    double? waist,
    double? hips,
    double? bodyFatPercent,
    DateTime? loggedAt,
  }) async {
    try {
      final response = await _dioClient.post(
        TrackerEndpoints.measurements,
        data: {
          if (weight != null) 'weight': weight,
          if (height != null) 'height': height,
          if (chest != null) 'chest': chest,
          if (waist != null) 'waist': waist,
          if (hips != null) 'hips': hips,
          if (bodyFatPercent != null) 'bodyFatPercent': bodyFatPercent,
          if (loggedAt != null) 'loggedAt': loggedAt.toIso8601String(),
        },
      );
      final rawData = response.data['data'] ?? response.data;
      return MeasurementLog.fromJson(rawData);
    } catch (e) {
      debugPrint('❌ logMeasurement failed: $e');
      rethrow;
    }
  }

  Future<List<MeasurementLog>> getMeasurementLogs({int page = 1, int limit = 20}) async {
    try {
      final response = await _dioClient.get(
        TrackerEndpoints.measurements,
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => MeasurementLog.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getMeasurementLogs failed: $e');
      rethrow;
    }
  }

  Future<bool> deleteMeasurementLog(String id) async {
    try {
      final response = await _dioClient.delete('${TrackerEndpoints.measurements}/$id');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ deleteMeasurementLog failed: $e');
      rethrow;
    }
  }

  // ─── Insulin Log API ───────────────────────────────────────────────────────
  Future<InsulinLog> logInsulin({
    required int dose,
    required String insulinType,
    required String injectionSite,
    required String mealContext,
    String? note,
    DateTime? loggedAt,
  }) async {
    try {
      final response = await _dioClient.post(
        TrackerEndpoints.insulin,
        data: {
          'dose': dose,
          'insulinType': insulinType,
          'injectionSite': injectionSite,
          'mealContext': mealContext,
          if (note != null) 'note': note,
          if (loggedAt != null) 'loggedAt': loggedAt.toIso8601String(),
        },
      );
      final rawData = response.data['data'] ?? response.data;
      return InsulinLog.fromJson(rawData);
    } catch (e) {
      debugPrint('❌ logInsulin failed: $e');
      rethrow;
    }
  }

  Future<List<InsulinLog>> getInsulinLogs({int page = 1, int limit = 20}) async {
    try {
      final response = await _dioClient.get(
        TrackerEndpoints.insulin,
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => InsulinLog.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getInsulinLogs failed: $e');
      rethrow;
    }
  }

  Future<bool> deleteInsulinLog(String id) async {
    try {
      final response = await _dioClient.delete('${TrackerEndpoints.insulin}/$id');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ deleteInsulinLog failed: $e');
      rethrow;
    }
  }

  // ─── Health Records API ───────────────────────────────────────────────────
  Future<List<HealthRecord>> getHealthRecords({String? type, String? specialist}) async {
    try {
      final response = await _dioClient.get(
        '/health-records',
        queryParameters: {
          if (type != null) 'type': type,
          if (specialist != null) 'specialist': specialist,
        },
      );
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => HealthRecord.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getHealthRecords failed: $e');
      rethrow;
    }
  }

  Future<HealthRecord> createHealthRecord({
    required String name,
    required String type,
    required String date,
    required String specialist,
    required List<String> filePaths,
  }) async {
    try {
      final List<MultipartFile> files = [];
      for (final path in filePaths) {
        files.add(await MultipartFile.fromFile(path));
      }

      final formData = FormData.fromMap({
        'name': name,
        'type': type,
        'date': date,
        'specialist': specialist,
        'files': files,
      });

      final response = await _dioClient.post(
        '/health-records',
        data: formData,
      );
      final rawData = response.data['data'] ?? response.data;
      return HealthRecord.fromJson(rawData);
    } catch (e) {
      debugPrint('❌ createHealthRecord failed: $e');
      rethrow;
    }
  }

  Future<bool> deleteHealthRecord(String id) async {
    try {
      final response = await _dioClient.delete('/health-records/$id');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ deleteHealthRecord failed: $e');
      rethrow;
    }
  }
}
