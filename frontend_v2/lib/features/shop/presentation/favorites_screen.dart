import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/shop_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/shop_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final shopState = ref.watch(shopProvider);

    final favoriteIds = authState.user?.favorites ?? [];
    final favoriteProducts = shopState.products.where((p) => favoriteIds.contains(p.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.secondary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Favorites',
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Text(
              favoriteProducts.isNotEmpty
                  ? '${favoriteProducts.length} item${favoriteProducts.length > 1 ? 's' : ''} saved'
                  : 'Your liked items',
              style: const TextStyle(
                color: AppColors.neutral,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF1F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                PhosphorIconsFill.heart,
                color: AppColors.error,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: favoriteProducts.isEmpty
          ? _EmptyFavorites(ws: 1.0)
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: favoriteProducts.length,
              itemBuilder: (context, index) {
                final product = favoriteProducts[index];
                return _FavoriteItemCard(product: product);
              },
            ),
    );
  }
}

class _FavoriteItemCard extends ConsumerWidget {
  final ShopProduct product;

  const _FavoriteItemCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopState = ref.watch(shopProvider);
    final cartCount = shopState.cart[product.id] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('/shop/product/${product.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(
                            product.imageUrl,
                            width: 82,
                            height: 82,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _PlaceholderBox(),
                          )
                        : _PlaceholderBox(),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        ref.read(authProvider.notifier).toggleFavorite(product.id);
                      },
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(
                          PhosphorIconsFill.heart,
                          size: 14,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _VegIndicator(isVeg: product.isVeg),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: const TextStyle(
                        color: AppColors.neutral,
                        fontSize: 11,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(PhosphorIconsFill.star,
                            color: AppColors.warning, size: 13),
                        const SizedBox(width: 2),
                        Text(
                          '${product.rating}',
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppColors.border,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${product.calories} kcal',
                          style: const TextStyle(
                            color: AppColors.neutral,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${product.price.toInt()}',
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        cartCount == 0
                            ? GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  ref.read(shopProvider.notifier).addToCart(product.id);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.secondary, width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(PhosphorIconsRegular.plus,
                                          color: AppColors.secondary, size: 13),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Add',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        ref.read(shopProvider.notifier).removeFromCart(product.id);
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 6),
                                        child: Icon(PhosphorIconsRegular.minus,
                                            size: 14, color: Colors.white),
                                      ),
                                    ),
                                    Text(
                                      '$cartCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        ref.read(shopProvider.notifier).addToCart(product.id);
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 6),
                                        child: Icon(PhosphorIconsRegular.plus,
                                            size: 14, color: Colors.white),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _VegIndicator extends StatelessWidget {
  final bool isVeg;
  const _VegIndicator({required this.isVeg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        border: Border.all(
          color: isVeg ? const Color(0xFF00E676) : AppColors.error,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: isVeg ? const Color(0xFF00E676) : AppColors.error,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _PlaceholderBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: const Center(
        child: Text('🥗', style: TextStyle(fontSize: 32)),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  final double ws;
  const _EmptyFavorites({required this.ws});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF1F2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                PhosphorIconsRegular.heartBreak,
                color: AppColors.error,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No favorites yet',
            style: TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the heart on any item to\nsave it here for quick access',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.neutral,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.secondary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.secondary, width: 1.5),
              ),
            ),
            onPressed: () => context.pop(),
            icon: const Icon(PhosphorIconsRegular.arrowLeft, size: 18),
            label: const Text(
              'Explore Shop',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
