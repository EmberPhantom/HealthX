import 'package:flutter/foundation.dart';
import '../../../core/models/notification_models.dart';
import '../../../core/network/dio_client.dart';

class NotificationService {
  final DioClient _dioClient = DioClient();

  static const String _basePath = '/notifications';

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _dioClient.get(_basePath);
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => NotificationModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getNotifications failed: $e');
      rethrow;
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _dioClient.get('$_basePath/unread-count');
      return (response.data['data']['count'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('❌ getUnreadCount failed: $e');
      return 0;
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      await _dioClient.patch('$_basePath/$id/read');
      return true;
    } catch (e) {
      debugPrint('❌ markAsRead failed: $e');
      rethrow;
    }
  }

  Future<bool> markAllRead() async {
    try {
      await _dioClient.patch('$_basePath/read-all');
      return true;
    } catch (e) {
      debugPrint('❌ markAllRead failed: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(String id) async {
    try {
      await _dioClient.delete('$_basePath/$id');
      return true;
    } catch (e) {
      debugPrint('❌ deleteNotification failed: $e');
      rethrow;
    }
  }

  /// Register or refresh the FCM device token with the backend.
  Future<void> registerFcmToken(String token) async {
    try {
      await _dioClient.post('$_basePath/fcm-token', data: {'token': token});
      debugPrint('✅ FCM token registered with backend');
    } catch (e) {
      debugPrint('⚠️ FCM token registration failed (non-fatal): $e');
      // Non-fatal — local notifications still work
    }
  }

  /// Remove FCM token from backend on logout.
  Future<void> removeFcmToken() async {
    try {
      await _dioClient.delete('$_basePath/fcm-token');
    } catch (_) {}
  }
}
