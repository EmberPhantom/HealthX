import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api/api_service.dart';

class OrderProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Order> _orders = [];
  bool _isLoading = false;
  Order? _currentOrder;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  Order? get currentOrder => _currentOrder;

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getOrders();
      if (response.isSuccess && response.data != null) {
        _orders = response.data!
            .map((e) => Order.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Order?> getOrderDetails(String id) async {
    try {
      final response = await _apiService.getOrder(id);
      if (response.isSuccess && response.data != null) {
        final order = Order.fromJson(response.data!);
        return order;
      }
    } catch (e) {
      debugPrint('Error loading order details: $e');
    }
    return null;
  }

  Future<bool> placeOrder({
    required List<CartItem> items,
    required String addressId,
    required String paymentMethod,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final itemsJson = items.map((i) => {
        'menuItemId': i.menuItem.id,
        'name': i.menuItem.name,
        'quantity': i.quantity,
        'price': i.menuItem.price,
      }).toList();

      final response = await _apiService.placeOrder({
        'items': itemsJson,
        'addressId': addressId,
        'paymentMethod': paymentMethod,
      });

      if (response.isSuccess && response.data != null) {
        _currentOrder = Order.fromJson(response.data!);
        await loadOrders();
        return true;
      }
    } catch (e) {
      debugPrint('Error placing order: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> cancelOrder(String orderId, {String? cancelReason}) async {
    try {
      final response = await _apiService.cancelOrder(orderId, cancelReason: cancelReason);
      if (response.isSuccess) {
        await loadOrders();
        if (_currentOrder?.id == orderId && response.data != null) {
          _currentOrder = Order.fromJson(response.data!);
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error cancelling order: $e');
    }
    return false;
  }

  void setViewingOrder(Order order) {
    _currentOrder = order;
    notifyListeners();
  }
}
