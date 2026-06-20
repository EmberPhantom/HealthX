import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/shop_provider.dart';
import '../../../core/models/shop_models.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopState = ref.watch(shopProvider);
    final product = shopState.products.firstWhere(
      (p) => p.id == productId,
      orElse: () => const ShopProduct(
        id: '',
        name: 'Product Not Found',
        description: '',
        price: 0,
        calories: 0,
        rating: 5,
        reviewCount: 0,
        imageUrl: '',
        emoji: '🥗',
        category: '',
        type: 'Regular',
        tags: [],
        isVeg: true,
      ),
    );

    if (product.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Detail')),
        body: const Center(child: Text('Product not found')),
      );
    }

    final cartQty = shopState.cart[product.id] ?? 0;

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
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Hero
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                image: product.imageUrl.isNotEmpty
                    ? DecorationImage(image: NetworkImage(product.imageUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: product.imageUrl.isEmpty
                  ? Center(child: Text(product.emoji, style: const TextStyle(fontSize: 80)))
                  : null,
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Price row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            // Category & Veg Status Badge
                            Row(
                              children: [
                                StatusBadge(
                                  text: product.category.toUpperCase(),
                                  dotColor: AppColors.primary,
                                  backgroundColor: const Color(0xFFFCFDF2),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: product.isVeg ? Colors.green.shade50 : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: product.isVeg ? Colors.green : Colors.red, width: 0.5),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: product.isVeg ? Colors.green : Colors.red,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        product.isVeg ? 'VEG' : 'NON-VEG',
                                        style: TextStyle(
                                          color: product.isVeg ? Colors.green : Colors.red,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${product.price.toInt()}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Nutrition Info
                  CustomCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNutrientTile(PhosphorIconsRegular.fire, 'Calories', '${product.calories} kcal'),
                        _buildNutrientTile(PhosphorIconsRegular.star, 'Rating', '${product.rating} ★'),
                        _buildNutrientTile(PhosphorIconsRegular.chat, 'Reviews', '${product.reviewCount} total'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'DESCRIPTION',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),

                  // Tags
                  if (product.tags.isNotEmpty) ...[
                    const Text(
                      'BENEFITS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border, width: 0.5),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Cart controls
                  if (cartQty == 0)
                    PrimaryButton(
                      text: 'ADD TO CART',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(shopProvider.notifier).addToCart(product.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} added to cart!'),
                            backgroundColor: AppColors.success,
                            duration: const Duration(milliseconds: 700),
                          ),
                        );
                      },
                    )
                  else
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.secondary, width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, color: AppColors.secondary),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  ref.read(shopProvider.notifier).removeFromCart(product.id);
                                },
                              ),
                              Text(
                                '$cartQty',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondary),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, color: AppColors.secondary),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  ref.read(shopProvider.notifier).addToCart(product.id);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: PrimaryButton(
                            text: 'VIEW CART & CHECKOUT',
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              context.push('/shop/cart');
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientTile(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.neutral),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}
