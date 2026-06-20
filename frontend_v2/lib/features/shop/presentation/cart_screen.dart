import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/shop_provider.dart';
import '../../../core/models/shop_models.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopState = ref.watch(shopProvider);
    final cartItems = shopState.cart.entries.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.secondary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Shopping Cart',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
        ),
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(PhosphorIconsRegular.shoppingBagOpen, size: 64, color: AppColors.neutral),
                  const SizedBox(height: 16),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Explore products in the catalog to add items.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'BROWSE CATALOG',
                    isFullWidth: false,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final entry = cartItems[index];
                      final productId = entry.key;
                      final quantity = entry.value;
                      final product = shopState.products.firstWhere(
                        (p) => p.id == productId,
                        orElse: () => const ShopProduct(id: '', name: '', description: '', price: 0, calories: 0, rating: 5, reviewCount: 0, imageUrl: '', emoji: '', category: '', type: 'Regular', tags: [], isVeg: true),
                      );

                      if (product.id.isEmpty) return const SizedBox.shrink();

                      return _buildCartItemTile(context, ref, product, quantity);
                    },
                  ),
                ),

                // Order summary & checkout bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.tertiary,
                    border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('Subtotal', '₹${shopState.cartSubtotal.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Delivery Fee', shopState.cartDeliveryFee == 0 ? 'FREE' : '₹${shopState.cartDeliveryFee.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Tax (GST 5%)', '₹${shopState.cartTax.toStringAsFixed(2)}'),
                      const Divider(height: 24),
                      _buildSummaryRow(
                        'Total',
                        '₹${shopState.cartTotal.toStringAsFixed(2)}',
                        isTitleBold: true,
                        fontSize: 18,
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        text: 'PROCEED TO CHECKOUT',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          context.push('/shop/checkout');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCartItemTile(BuildContext context, WidgetRef ref, ShopProduct product, int quantity) {
    return CustomCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: product.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(product.imageUrl, fit: BoxFit.cover),
                  )
                : Center(child: Text(product.emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${product.price.toInt()} each',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity adjustments
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border, width: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 14),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ref.read(shopProvider.notifier).removeFromCart(product.id);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              '$quantity',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 14),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ref.read(shopProvider.notifier).addToCart(product.id);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    // Item Subtotal
                    Text(
                      '₹${(product.price * quantity).toInt()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTitleBold = false,
    double fontSize = 14,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTitleBold ? FontWeight.bold : FontWeight.normal,
            color: isTitleBold ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: fontSize,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }
}
