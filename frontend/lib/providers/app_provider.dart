import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api/api_service.dart';

class AppProvider extends ChangeNotifier {
  void onLogout() {
    _cartItems.clear();
    _currentOrder = null;
    _resetTabHistory();
    // Clear dynamic content so stale data from last user isn't shown
    _banners = [];
    _categories = const [MenuCategory(name: 'All', emoji: '🍽️')];
    _mealPlans = [];
    _menuItems.clear();
    _readyToEatItems.clear();
    _isInitialized = false;
    _hasError = false;
    _totalOrdersCount = 0;
    _favoritesCount = 0;
    _userRatingValue = 4.8;
    _notifications = [];
    notifyListeners();
  }

  // Legacy alias kept for any call sites that use the old name
  void logout() => onLogout();

  // === Cart ===
  final List<CartItem> _cartItems = [];
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  int get cartItemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get cartSubtotal =>
      _cartItems.fold(0, (sum, item) => sum + item.subtotal);
  double get deliveryFee => _cartItems.isEmpty ? 0 : 40;
  double get tax => cartSubtotal * 0.05;
  double get cartTotal => cartSubtotal + deliveryFee + tax;

  void addToCart(MenuItem item) {
    final idx = _cartItems.indexWhere((c) => c.menuItem.id == item.id);
    if (idx >= 0) {
      _cartItems[idx].quantity++;
    } else {
      _cartItems.add(CartItem(menuItem: item));
    }
    notifyListeners();
  }

  void removeFromCart(String itemId) {
    _cartItems.removeWhere((c) => c.menuItem.id == itemId);
    notifyListeners();
  }

  void updateQuantity(String itemId, int qty) {
    final idx = _cartItems.indexWhere((c) => c.menuItem.id == itemId);
    if (idx >= 0) {
      if (qty <= 0) {
        _cartItems.removeAt(idx);
      } else {
        _cartItems[idx].quantity = qty;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // === Menu Items ===
  List<MenuItem> _menuItems = [];
  List<MenuItem> get menuItems => _menuItems;

  List<MenuItem> _readyToEatItems = [];
  List<MenuItem> get readyToEatItems => _readyToEatItems;

  List<MenuItem> getFilteredItems(String category) {
    if (category == 'All') return _menuItems;
    return _menuItems.where((i) => i.category == category).toList();
  }

  Future<void> toggleFavorite(String itemId) async {
    try {
      final response = await _apiService.toggleFavorite(itemId);
      if (response.isSuccess) {
        final idx = _menuItems.indexWhere((i) => i.id == itemId);
        if (idx >= 0) {
          _menuItems[idx].isFavorite = !_menuItems[idx].isFavorite;
        }
        
        final rteIdx = _readyToEatItems.indexWhere((i) => i.id == itemId);
        if (rteIdx >= 0) {
          _readyToEatItems[rteIdx].isFavorite = !_readyToEatItems[rteIdx].isFavorite;
        }

        // Update stats count locally
        final isNowFav = response.data?['isFavorite'] ?? false;
        _favoritesCount += isNowFav ? 1 : -1;
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  List<MenuItem> get favoriteItems {
    final all = [..._menuItems, ..._readyToEatItems];
    return all.where((i) => i.isFavorite).toList();
  }

  // === Dynamic API Content ===
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// True once the first successful fetch has completed.
  /// Used by ProxyProvider in main.dart to avoid double-fetching.
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// True if the last fetch attempt failed.
  bool _hasError = false;
  bool get hasError => _hasError;

  List<BannerModel> _banners = [];
  List<BannerModel> get banners => _banners;

  // Start with a single 'All' category as placeholder while loading
  List<MenuCategory> _categories = const [
    MenuCategory(name: 'All', emoji: '🍽️'),
  ];
  List<MenuCategory> get categories => _categories;

  // Start empty — populated from API
  List<MealPlan> _mealPlans = [];
  List<MealPlan> get mealPlans => _mealPlans;

  // === User Stats ===
  int _totalOrdersCount = 0;
  int get totalOrdersCount => _totalOrdersCount;

  int _favoritesCount = 0;
  int get favoritesCount => _favoritesCount;

  double _userRatingValue = 4.8;
  double get userRatingValue => _userRatingValue;

  // === Notifications ===
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => _notifications;

  int get unreadNotificationsCount =>
      _notifications.where((n) => n['isRead'] == false).length;

  /// Called by pull-to-refresh to force a fresh fetch regardless of isInitialized
  void resetForRefresh() {
    _isInitialized = false;
  }

  Future<void> initializeData() async {
    if (_isLoading) return; // Prevent concurrent fetches


    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      // 1. Content
      final resCategories = await _apiService.getCategories();
      if (resCategories.isSuccess && resCategories.data != null) {
        _categories = [
          const MenuCategory(name: 'All', emoji: '🍽️'),
          ...resCategories.data!,
        ];
      }

      final resBanners = await _apiService.getBanners();
      if (resBanners.isSuccess && resBanners.data != null) {
        _banners = resBanners.data!;
      }

      final resMealPlans = await _apiService.getMealPlans();
      if (resMealPlans.isSuccess && resMealPlans.data != null) {
        _mealPlans = resMealPlans.data!;
      }

      // Fetch user profile first to get favorites
      final resProfile = await _apiService.getProfile();
      List<String> favIds = [];
      if (resProfile.success && resProfile.data != null) {
        favIds = (resProfile.data!.rawJson?['favorites'] as List?)?.map((e) => e.toString()).toList() ?? [];
      }

      final resMenuItems = await _apiService.getMenuItems(type: 'Regular');
      if (resMenuItems.isSuccess && resMenuItems.data != null) {
        _menuItems = resMenuItems.data!.map((item) {
          item.isFavorite = favIds.contains(item.id);
          return item;
        }).toList();
      }

      final resReadyToEat = await _apiService.getMenuItems(type: 'ReadyToEat');
      if (resReadyToEat.isSuccess && resReadyToEat.data != null) {
        _readyToEatItems = resReadyToEat.data!.map((item) {
          item.isFavorite = favIds.contains(item.id);
          return item;
        }).toList();
      }

      // 2. Stats
      final resStats = await _apiService.getProfileStats();
      if (resStats.isSuccess && resStats.data != null) {
        _totalOrdersCount = resStats.data!['totalOrders'] ?? 0;
        _favoritesCount = resStats.data!['favoritesCount'] ?? 0;
        _userRatingValue = (resStats.data!['rating'] as num?)?.toDouble() ?? 4.8;
      }

      // 3. Notifications
      final resNotifications = await _apiService.getNotifications();
      if (resNotifications.isSuccess && resNotifications.data != null) {
        _notifications = resNotifications.data!;
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing AppProvider data: $e');
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markNotificationAsRead(String id) async {
    try {
      final response = await _apiService.markNotificationAsRead(id);
      if (response.isSuccess) {
        final index = _notifications.indexWhere((n) => n['_id'] == id);
        if (index != -1) {
          _notifications[index]['isRead'] = true;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      final response = await _apiService.deleteNotification(id);
      if (response.isSuccess) {
        _notifications.removeWhere((n) => n['_id'] == id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> setAppRating(int rating) async {
    try {
      final response = await _apiService.setAppRating(rating);
      if (response.isSuccess) {
        _userRatingValue = rating.toDouble();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error setting app rating: $e');
    }
  }

  // === Orders ===
  Order? _currentOrder;
  Order? get currentOrder => _currentOrder;

  final List<Order> _orderHistory = [];
  List<Order> get orderHistory => List.unmodifiable(_orderHistory);

  final DeliveryAddress _defaultAddress = const DeliveryAddress(
    id: 'a1',
    label: 'Home',
    street: '42, Green Valley Apartments',
    area: 'Koramangala 4th Block',
    city: 'Bangalore',
    pincode: '560034',
  );
  DeliveryAddress get defaultAddress => _defaultAddress;

  String _selectedPayment = 'Credit Card';
  String get selectedPayment => _selectedPayment;
  void setPaymentMethod(String method) {
    _selectedPayment = method;
    notifyListeners();
  }

  bool _isAsapDelivery = true;
  bool get isAsapDelivery => _isAsapDelivery;
  void setDeliveryTime(bool asap) {
    _isAsapDelivery = asap;
    notifyListeners();
  }

  // Allows MyOrdersScreen to open any past order in tracking screen
  void setViewingOrder(Order order) {
    _currentOrder = order;
    notifyListeners();
  }

  void placeOrder() {
    if (_cartItems.isEmpty) return;
    final order = Order(
      id: 'HB${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      items: List.from(_cartItems),
      subtotal: cartSubtotal,
      deliveryFee: deliveryFee,
      tax: tax,
      total: cartTotal,
      address: _defaultAddress,
      paymentMethod: _selectedPayment,
      status: OrderStatus.placed,
      deliveryPartner: const DeliveryPartner(
        name: 'Rahul Kumar',
        rating: 4.9,
        deliveries: 230,
        avatarUrl: 'https://ui-avatars.com/api/?name=Rahul+Kumar&size=200&background=10B981&color=fff',
      ),
      createdAt: DateTime.now(),
      estimatedDelivery: DateTime.now().add(const Duration(minutes: 35)),
    );
    _currentOrder = order;
    _orderHistory.insert(0, order);
    _cartItems.clear();
    notifyListeners();
  }

  // === Bottom Nav ===
  final List<int> _tabHistory = [0];

  int get currentTabIndex => _tabHistory.last;

  void setTabIndex(int idx) {
    if (_tabHistory.last == idx) return;
    _tabHistory.add(idx);
    notifyListeners();
  }
  bool popTab() {
    if (_tabHistory.length > 1) {
      _tabHistory.removeLast();
      notifyListeners();
      return true;
    }
    return false;
  }
  void _resetTabHistory() {
    _tabHistory
      ..clear()
      ..add(0);
  }
}