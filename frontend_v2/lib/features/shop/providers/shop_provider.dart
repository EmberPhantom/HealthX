import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/shop_service.dart';
import '../../../core/models/shop_models.dart';
import '../../auth/providers/auth_provider.dart';

class ShopState {
  final List<ShopProduct> products;
  final List<String> categories;
  final List<AddressModel> addresses;
  final List<OrderModel> orders;
  final Map<String, int> cart; // productId -> quantity
  final bool isLoading;
  final String? error;
  final bool isLoadingMore;
  final bool hasMoreOrders;
  final int ordersPage;
  final TrackingData? trackingData;
  final String? trackingError;

  const ShopState({
    this.products = const [],
    this.categories = const [],
    this.addresses = const [],
    this.orders = const [],
    this.cart = const {},
    this.isLoading = false,
    this.error,
    this.isLoadingMore = false,
    this.hasMoreOrders = true,
    this.ordersPage = 1,
    this.trackingData,
    this.trackingError,
  });

  ShopState copyWith({
    List<ShopProduct>? products,
    List<String>? categories,
    List<AddressModel>? addresses,
    List<OrderModel>? orders,
    Map<String, int>? cart,
    bool? isLoading,
    String? error,
    bool? isLoadingMore,
    bool? hasMoreOrders,
    int? ordersPage,
    TrackingData? trackingData,
    String? trackingError,
  }) {
    return ShopState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      addresses: addresses ?? this.addresses,
      orders: orders ?? this.orders,
      cart: cart ?? this.cart,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreOrders: hasMoreOrders ?? this.hasMoreOrders,
      ordersPage: ordersPage ?? this.ordersPage,
      trackingData: trackingData ?? this.trackingData,
      trackingError: trackingError ?? this.trackingError,
    );
  }

  // Helper getters
  double get cartSubtotal {
    double sum = 0.0;
    cart.forEach((id, qty) {
      final prod = products.firstWhere((p) => p.id == id, orElse: () => const ShopProduct(id: '', name: '', description: '', price: 0, calories: 0, rating: 5, reviewCount: 0, imageUrl: '', emoji: '', category: '', type: 'Regular', tags: [], isVeg: true));
      if (prod.id.isNotEmpty) {
        sum += prod.price * qty;
      }
    });
    return sum;
  }

  double get cartDeliveryFee => cartSubtotal > 0 && cartSubtotal < 500 ? 50.0 : 0.0;
  double get cartTax => cartSubtotal * 0.05; // 5% GST
  double get cartTotal => cartSubtotal + cartDeliveryFee + cartTax;

  int get cartCount {
    return cart.values.fold(0, (sum, val) => sum + val);
  }
}

class ShopNotifier extends Notifier<ShopState> {
  final ShopService _service = ShopService();

  @override
  ShopState build() {
    final session = ref.watch(sessionProvider);
    if (session != null) {
      Future.microtask(() {
        fetchCatalog();
        fetchAddresses();
        fetchOrders();
      });
    }
    return const ShopState();
  }

  Future<void> fetchCatalog() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prods = await _service.getProducts();
      final cats = await _service.getCategories();
      
      // Preserve custom bowls that are currently in the cart
      final customBowls = state.products.where((p) => p.id.startsWith('custom_bowl_'));
      final combinedProds = [...prods, ...customBowls];

      state = state.copyWith(
        products: combinedProds,
        categories: cats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchAddresses() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _service.getAddresses();
      state = state.copyWith(
        addresses: list,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchOrders() async {
    state = state.copyWith(isLoading: true, error: null, ordersPage: 1);
    try {
      final result = await _service.getOrders(page: 1, limit: 10);
      state = state.copyWith(
        orders: result.orders,
        hasMoreOrders: result.hasMore,
        ordersPage: 1,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchMoreOrders() async {
    if (state.isLoadingMore || !state.hasMoreOrders) return;
    final nextPage = state.ordersPage + 1;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _service.getOrders(page: nextPage, limit: 10);
      state = state.copyWith(
        orders: [...state.orders, ...result.orders],
        hasMoreOrders: result.hasMore,
        ordersPage: nextPage,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  // ─── Cart Management ───────────────────────────────────────────────────────
  void addToCart(String productId) {
    final updatedCart = Map<String, int>.from(state.cart);
    updatedCart[productId] = (updatedCart[productId] ?? 0) + 1;
    state = state.copyWith(cart: updatedCart);
  }

  void removeFromCart(String productId) {
    final updatedCart = Map<String, int>.from(state.cart);
    if (updatedCart.containsKey(productId)) {
      if (updatedCart[productId]! <= 1) {
        updatedCart.remove(productId);
      } else {
        updatedCart[productId] = updatedCart[productId]! - 1;
      }
    }
    state = state.copyWith(cart: updatedCart);
  }

  void updateCartQuantity(String productId, int qty) {
    final updatedCart = Map<String, int>.from(state.cart);
    if (qty <= 0) {
      updatedCart.remove(productId);
    } else {
      updatedCart[productId] = qty;
    }
    state = state.copyWith(cart: updatedCart);
  }

  void clearCart() {
    state = state.copyWith(cart: const {});
  }

  void addCustomBowlToCart({
    required String name,
    required double price,
    required int calories,
    required String description,
  }) {
    final String customId = 'custom_bowl_${DateTime.now().millisecondsSinceEpoch}';
    final customProduct = ShopProduct(
      id: customId,
      name: name,
      description: description,
      price: price,
      calories: calories,
      rating: 5.0,
      reviewCount: 0,
      imageUrl: '',
      emoji: '🥗',
      category: 'Healthy Bowls',
      type: 'Regular',
      tags: const ['Custom'],
      isVeg: !description.toLowerCase().contains('chicken') && !description.toLowerCase().contains('egg'),
    );
    final updatedProducts = [...state.products, customProduct];
    final updatedCart = Map<String, int>.from(state.cart);
    updatedCart[customId] = (updatedCart[customId] ?? 0) + 1;
    state = state.copyWith(
      products: updatedProducts,
      cart: updatedCart,
    );
  }

  // ─── Address CRUD ──────────────────────────────────────────────────────────
  Future<bool> addAddress({
    required String label,
    required String street,
    required String area,
    required String city,
    required String pincode,
    required bool isDefault,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final addr = await _service.createAddress(
        label: label,
        street: street,
        area: area,
        city: city,
        pincode: pincode,
        isDefault: isDefault,
      );
      if (addr != null) {
        // If set default, reload all addresses
        if (isDefault) {
          await fetchAddresses();
        } else {
          state = state.copyWith(
            addresses: [...state.addresses, addr],
            isLoading: false,
          );
        }
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> editAddress(
    String id, {
    required String label,
    required String street,
    required String area,
    required String city,
    required String pincode,
    required bool isDefault,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final addr = await _service.updateAddress(
        id,
        label: label,
        street: street,
        area: area,
        city: city,
        pincode: pincode,
        isDefault: isDefault,
      );
      if (addr != null) {
        await fetchAddresses(); // easiest to refresh and handle default switching
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> removeAddress(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _service.deleteAddress(id);
      if (success) {
        state = state.copyWith(
          addresses: state.addresses.where((a) => a.id != id).toList(),
          isLoading: false,
        );
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> makeAddressDefault(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _service.setDefaultAddress(id);
      if (success) {
        await fetchAddresses();
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ─── Order Placements ──────────────────────────────────────────────────────
  Future<bool> checkout({
    required String addressId,
    required String paymentMethod,
  }) async {
    if (state.cart.isEmpty) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final checkoutItems = <Map<String, dynamic>>[];
      state.cart.forEach((id, qty) {
        final prod = state.products.firstWhere((p) => p.id == id);
        checkoutItems.add({
          'menuItemId': id,
          'name': prod.name,
          'quantity': qty,
          'price': prod.price,
        });
      });

      final order = await _service.placeOrder(
        items: checkoutItems,
        addressId: addressId,
        paymentMethod: paymentMethod,
      );

      if (order != null) {
        state = state.copyWith(
          orders: [order, ...state.orders],
          cart: const {},
          isLoading: false,
        );
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> cancelUserOrder(String orderId, {String? reason}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedOrder = await _service.cancelOrder(orderId, reason: reason);
      if (updatedOrder != null) {
        final updatedList = state.orders.map((o) {
          return o.id == orderId ? updatedOrder : o;
        }).toList();
        state = state.copyWith(
          orders: updatedList,
          isLoading: false,
        );
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ─── Order Tracking ───────────────────────────────────────────────────────
  Future<TrackingData?> fetchTracking(String orderId) async {
    state = state.copyWith(trackingError: null);
    try {
      final data = await _service.getOrderTracking(orderId);
      state = state.copyWith(trackingData: data, trackingError: null);
      return data;
    } catch (e) {
      state = state.copyWith(trackingError: e.toString());
      return null;
    }
  }

  void clearTracking() {
    state = state.copyWith(trackingData: null, trackingError: null);
  }
}

final shopProvider = NotifierProvider<ShopNotifier, ShopState>(ShopNotifier.new);

final mealPlansProvider = FutureProvider<List<MealPlan>>((ref) async {
  return ShopService().getMealPlans();
});
