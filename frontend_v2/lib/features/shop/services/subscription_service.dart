import 'package:flutter/foundation.dart';
import '../../../core/models/subscription_models.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/dio_client.dart';

class SubscriptionService {
  final DioClient _dioClient = DioClient();

  Future<List<UserSubscription>> getActiveSubscriptions() async {
    try {
      final response = await _dioClient.get(SubscriptionEndpoints.me);
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => UserSubscription.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getActiveSubscriptions failed: $e');
      rethrow;
    }
  }

  Future<UserSubscription> subscribeToPlan(String planId, double price, String planName) async {
    try {
      final response = await _dioClient.post(
        SubscriptionEndpoints.subscribe,
        data: {
          'planId': planId,
          'price': price.toString(),
          'planName': planName,
        },
      );
      return UserSubscription.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('❌ subscribeToPlan failed: $e');
      rethrow;
    }
  }

  Future<UserSubscription> cancelSubscription(String id) async {
    try {
      final response = await _dioClient.post(SubscriptionEndpoints.cancel(id));
      return UserSubscription.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('❌ cancelSubscription failed: $e');
      rethrow;
    }
  }

  Future<UserSubscription> pauseSubscription(String id) async {
    try {
      final response = await _dioClient.post(SubscriptionEndpoints.pause(id));
      return UserSubscription.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('❌ pauseSubscription failed: $e');
      rethrow;
    }
  }

  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    try {
      final response = await _dioClient.get('/content/subscription-plans');
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => SubscriptionPlan.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getSubscriptionPlans failed: $e');
      rethrow;
    }
  }
}
