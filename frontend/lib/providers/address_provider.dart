import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api/api_service.dart';

class AddressProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<DeliveryAddress> _addresses = [];
  bool _isLoading = false;

  List<DeliveryAddress> get addresses => _addresses;
  bool get isLoading => _isLoading;

  DeliveryAddress? get defaultAddress {
    if (_addresses.isEmpty) return null;
    // Look for default address (first address returned from backend is default sorted if we did isDefault desc)
    // But let's check custom logic or default status
    return _addresses.first;
  }

  Future<void> loadAddresses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getAddresses();
      if (response.isSuccess && response.data != null) {
        _addresses = response.data!
            .map((e) => DeliveryAddress.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading addresses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<DeliveryAddress?> addAddress(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.createAddress(data);
      if (response.isSuccess && response.data != null) {
        final address = DeliveryAddress.fromJson(response.data!);
        await loadAddresses();
        return address;
      }
    } catch (e) {
      debugPrint('Error adding address: $e');
    }
    return null;
  }

  Future<bool> deleteAddress(String id) async {
    try {
      final response = await _apiService.deleteAddress(id);
      if (response.isSuccess) {
        await loadAddresses();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting address: $e');
    }
    return false;
  }

  Future<bool> setDefault(String id) async {
    try {
      final response = await _apiService.setDefaultAddress(id);
      if (response.isSuccess) {
        await loadAddresses();
        return true;
      }
    } catch (e) {
      debugPrint('Error setting default address: $e');
    }
    return false;
  }
}
