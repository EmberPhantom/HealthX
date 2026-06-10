import 'package:flutter/foundation.dart';
import '../../../core/models/notification_models.dart';
import '../../../core/network/dio_client.dart';

class NotificationService {
  final DioClient _dioClient = DioClient();

  static const String _basePath = '/notifications';

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _dioClient.get(_basePath);
      // Backend payload structure might contain { success: true, data: [...] } or just [...]
      final list = response.data['data'] as List? ?? response.data as List? ?? [];
      return list.map((item) => NotificationModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getNotifications failed: $e');
      return [];
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      await _dioClient.patch('$_basePath/$id/read');
      return true;
    } catch (e) {
      debugPrint('❌ markAsRead failed: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(String id) async {
    try {
      await _dioClient.delete('$_basePath/$id');
      return true;
    } catch (e) {
      debugPrint('❌ deleteNotification failed: $e');
      return false;
    }
  }
}
