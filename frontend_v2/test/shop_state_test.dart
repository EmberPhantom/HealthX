import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_v2/core/models/shop_models.dart';
import 'package:frontend_v2/features/shop/providers/shop_provider.dart';

final _sampleProduct = ShopProduct(
  id: 'p1',
  name: 'Test Item',
  description: 'Test description',
  price: 100.0,
  calories: 200,
  rating: 4.5,
  reviewCount: 10,
  imageUrl: '',
  emoji: '🥗',
  category: 'Salads',
  type: 'Regular',
  tags: ['healthy'],
  isVeg: true,
);

void main() {
  group('ShopState', () {
    test('default state has all empty/false values', () {
      const state = ShopState();
      expect(state.products, isEmpty);
      expect(state.categories, isEmpty);
      expect(state.addresses, isEmpty);
      expect(state.orders, isEmpty);
      expect(state.cart, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.isLoadingMore, false);
      expect(state.hasMoreOrders, true);
      expect(state.ordersPage, 1);
    });

    test('copyWith updates only specified fields', () {
      const state = ShopState();
      final updated = state.copyWith(
        isLoading: true,
        ordersPage: 2,
        hasMoreOrders: false,
      );

      expect(updated.isLoading, true);
      expect(updated.ordersPage, 2);
      expect(updated.hasMoreOrders, false);
      // Unchanged fields
      expect(updated.products, isEmpty);
      expect(updated.error, isNull);
    });

    test('cartCount returns total items', () {
      final state = ShopState(
        products: [_sampleProduct],
        cart: {'p1': 3},
      );
      expect(state.cartCount, 3);
    });

    test('cartCount returns 0 when cart is empty', () {
      const state = ShopState();
      expect(state.cartCount, 0);
    });

    test('cartSubtotal calculates correctly', () {
      final state = ShopState(
        products: [_sampleProduct],
        cart: {'p1': 3},
      );
      // 100 * 3 = 300
      expect(state.cartSubtotal, 300.0);
    });

    test('cartSubtotal returns 0 when product not found', () {
      final state = ShopState(
        products: [_sampleProduct],
        cart: {'unknown_id': 2},
      );
      expect(state.cartSubtotal, 0.0);
    });

    test('cartDeliveryFee is 50 when subtotal under 500', () {
      final state = ShopState(
        products: [_sampleProduct],
        cart: {'p1': 1},
      );
      expect(state.cartDeliveryFee, 50.0);
    });

    test('cartDeliveryFee is 0 when subtotal is 500 or more', () {
      final state = ShopState(
        products: [_sampleProduct],
        cart: {'p1': 5},
      );
      expect(state.cartDeliveryFee, 0.0);
    });

    test('cartDeliveryFee is 0 when cart is empty', () {
      const state = ShopState();
      expect(state.cartDeliveryFee, 0.0);
    });

    test('cartTax is 5% of subtotal', () {
      final state = ShopState(
        products: [_sampleProduct],
        cart: {'p1': 2},
      );
      // 200 * 0.05 = 10
      expect(state.cartTax, 10.0);
    });

    test('cartTotal is subtotal + delivery + tax', () {
      final state = ShopState(
        products: [_sampleProduct],
        cart: {'p1': 2},
      );
      // subtotal: 200, tax: 10, delivery: 50 (since 200 < 500)
      expect(state.cartTotal, 260.0);
    });

    test('copyWith tracking data', () {
      const state = ShopState();
      final tracking = TrackingData(
        orderId: 'ord1',
        currentStatus: 'placed',
      );
      final updated = state.copyWith(
        trackingData: tracking,
        trackingError: 'something went wrong',
      );

      expect(updated.trackingData?.orderId, 'ord1');
      expect(updated.trackingData?.currentStatus, 'placed');
      expect(updated.trackingError, 'something went wrong');
    });

    test('copyWith preserves tracking data when not provided', () {
      final state = ShopState(
        trackingData: TrackingData(orderId: 'o1', currentStatus: 'placed'),
      );
      final updated = state.copyWith(isLoading: true);
      expect(updated.trackingData?.orderId, 'o1');
      expect(updated.isLoading, true);
    });
  });
}
