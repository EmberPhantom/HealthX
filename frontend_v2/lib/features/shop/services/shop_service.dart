import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/models/shop_models.dart';
import '../../../core/network/dio_client.dart';

class ShopService {
  final DioClient _dioClient = DioClient();

  // ─── Catalog API ───────────────────────────────────────────────────────────
  Future<List<ShopProduct>> getProducts({String? type}) async {
    try {
      final response = await _dioClient.get(
        '/content/menu-items',
        queryParameters: type != null ? {'type': type} : null,
      );
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => ShopProduct.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getProducts failed: $e');
      rethrow;
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await _dioClient.get('/content/categories');
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => (item['name'] ?? item).toString()).toList();
    } catch (e) {
      debugPrint('❌ getCategories failed: $e');
      rethrow;
    }
  }

  Future<List<MealPlan>> getMealPlans() async {
    try {
      final response = await _dioClient.get('/content/meal-plans');
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => MealPlan.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getMealPlans failed: $e');
      rethrow;
    }
  }

  // ─── Address CRUD API ──────────────────────────────────────────────────────
  Future<List<AddressModel>> getAddresses() async {
    try {
      final response = await _dioClient.get('/addresses');
      final list = response.data['data'] as List? ?? [];
      return list.map((item) => AddressModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ getAddresses failed: $e');
      rethrow;
    }
  }

  Future<AddressModel?> createAddress({
    required String label,
    required String street,
    required String area,
    required String city,
    required String pincode,
    required bool isDefault,
  }) async {
    try {
      final response = await _dioClient.post(
        '/addresses',
        data: {
          'label': label,
          'street': street,
          'area': area,
          'city': city,
          'pincode': pincode,
          'isDefault': isDefault,
        },
      );
      final rawData = response.data['data'] ?? response.data;
      return AddressModel.fromJson(rawData);
    } catch (e) {
      debugPrint('❌ createAddress failed: $e');
      rethrow;
    }
  }

  Future<AddressModel?> updateAddress(
    String id, {
    required String label,
    required String street,
    required String area,
    required String city,
    required String pincode,
    required bool isDefault,
  }) async {
    try {
      final response = await _dioClient.put(
        '/addresses/$id',
        data: {
          'label': label,
          'street': street,
          'area': area,
          'city': city,
          'pincode': pincode,
          'isDefault': isDefault,
        },
      );
      final rawData = response.data['data'] ?? response.data;
      return AddressModel.fromJson(rawData);
    } catch (e) {
      debugPrint('❌ updateAddress failed: $e');
      rethrow;
    }
  }

  Future<bool> deleteAddress(String id) async {
    try {
      final response = await _dioClient.delete('/addresses/$id');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ deleteAddress failed: $e');
      rethrow;
    }
  }

  Future<bool> setDefaultAddress(String id) async {
    try {
      final response = await _dioClient.patch('/addresses/$id/default');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ setDefaultAddress failed: $e');
      rethrow;
    }
  }

  // ─── Orders API ────────────────────────────────────────────────────────────
  Future<({List<OrderModel> orders, bool hasMore})> getOrders({int page = 1, int limit = 10}) async {
    try {
      final response = await _dioClient.get(
        '/orders',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      final list = response.data['data'] as List? ?? [];
      final total = response.data['total'] as int? ?? list.length;
      final orders = list.map((item) => OrderModel.fromJson(item as Map<String, dynamic>)).toList();
      return (orders: orders, hasMore: (page * limit) < total);
    } catch (e) {
      debugPrint('❌ getOrders failed: $e');
      rethrow;
    }
  }

  Future<OrderModel?> placeOrder({
    required List<Map<String, dynamic>> items,
    required String addressId,
    required String paymentMethod,
  }) async {
    try {
      final response = await _dioClient.post(
        '/orders',
        data: {
          'addressId': addressId,
          'items': items,
          'paymentMethod': paymentMethod,
        },
      );
      final rawData = response.data['data'] ?? response.data;
      return OrderModel.fromJson(rawData);
    } catch (e) {
      debugPrint('❌ placeOrder failed: $e');
      rethrow;
    }
  }

  Future<OrderModel?> cancelOrder(String id, {String? reason}) async {
    try {
      final response = await _dioClient.post(
        '/orders/$id/cancel',
        data: {
          if (reason != null) 'cancelReason': reason,
        },
      );
      final rawData = response.data['data'] ?? response.data;
      return OrderModel.fromJson(rawData);
    } catch (e) {
      debugPrint('❌ cancelOrder failed: $e');
      rethrow;
    }
  }

  // ─── Order Tracking API ───────────────────────────────────────────────────
  Future<TrackingData?> getOrderTracking(String orderId) async {
    try {
      final response = await _dioClient.get('/orders/$orderId/tracking');
      final rawData = response.data['data'] ?? response.data;
      if (rawData is Map<String, dynamic>) {
        return TrackingData.fromJson(rawData);
      }
      return null;
    } catch (e) {
      debugPrint('❌ getOrderTracking failed: $e');
      rethrow;
    }
  }
}
