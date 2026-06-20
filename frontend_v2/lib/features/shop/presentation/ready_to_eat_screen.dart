import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/shop_provider.dart';

class ReadyToEatScreen extends ConsumerStatefulWidget {
  const ReadyToEatScreen({super.key});

  @override
  ConsumerState<ReadyToEatScreen> createState() => _ReadyToEatScreenState();
}

class _ReadyToEatScreenState extends ConsumerState<ReadyToEatScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider);
    final authState = ref.watch(authProvider);
    final cartCount = shopState.cartCount;

    // Filter products: type must be 'ReadyToEat'
    final rteProducts = shopState.products.where((p) => p.type == 'ReadyToEat').toList();

    final filtered = rteProducts.where((p) {
      final matchCat = _selectedCategory == 'All' || p.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();

    // Curated categories for ready to eat snacks
    final categories = ['All', 'Energy Bars', 'Protein Bars', 'Chikki'];

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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ready to Eat Snacks',
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            Text(
              'Sugar Free · Preservative Free',
              style: TextStyle(
                color: AppColors.neutral,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          context.push('/shop/cart');
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.secondary, width: 1.5),
        ),
        child: Badge(
          label: Text('$cartCount'),
          isLabelVisible: cartCount > 0,
          child: const Icon(
            PhosphorIconsRegular.shoppingCart,
            size: 26,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search input
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(PhosphorIconsRegular.magnifyingGlass, color: AppColors.neutral, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search energy bars, protein shakes...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: AppColors.neutral,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(PhosphorIconsRegular.xCircle, color: AppColors.neutral, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                ],
              ),
            ),
          ),

          // Filters and list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(shopProvider.notifier).fetchCatalog();
              },
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                children: [
                  // Category chips
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length,
                      itemBuilder: (ctx, i) {
                        final catName = categories[i];
                        final isSelected = _selectedCategory == catName;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(catName),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? AppColors.secondary : AppColors.border,
                                width: 0.8,
                              ),
                            ),
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.secondary : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setState(() => _selectedCategory = catName);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _selectedCategory == 'All'
                          ? 'AVAILABLE SNACKS (${filtered.length})'
                          : '${_selectedCategory.toUpperCase()} (${filtered.length})',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (filtered.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(PhosphorIconsRegular.shoppingBagOpen, size: 48, color: AppColors.neutral),
                            SizedBox(height: 12),
                            Text(
                              'No products found',
                              style: TextStyle(color: AppColors.neutral, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        final isFavorite = authState.user?.favorites.contains(product.id) ?? false;
                        final cartCountOnItem = shopState.cart[product.id] ?? 0;

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border, width: 0.5),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.push('/shop/product/${product.id}');
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      height: 110,
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                        color: AppColors.primary.withValues(alpha: 0.05),
                                        image: product.imageUrl.isNotEmpty
                                            ? DecorationImage(
                                                image: NetworkImage(product.imageUrl),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: product.imageUrl.isEmpty
                                          ? Center(child: Text(product.emoji, style: const TextStyle(fontSize: 44)))
                                          : null,
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () {
                                          HapticFeedback.mediumImpact();
                                          ref.read(authProvider.notifier).toggleFavorite(product.id);
                                        },
                                        child: Container(
                                          width: 26,
                                          height: 26,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isFavorite ? PhosphorIconsFill.heart : PhosphorIconsRegular.heart,
                                            size: 15,
                                            color: isFavorite ? AppColors.error : AppColors.neutral,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (product.rating >= 4.7)
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: AppColors.secondary, width: 0.5),
                                          ),
                                          child: const Text(
                                            'BEST',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.secondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                      ),
                                      Text(
                                        '${product.calories} kcal • Sugar Free',
                                        maxLines: 1,
                                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '₹${product.price.toInt()}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                            ),
                                          ),
                                          cartCountOnItem == 0
                                              ? GestureDetector(
                                                  onTap: () {
                                                    HapticFeedback.lightImpact();
                                                    ref.read(shopProvider.notifier).addToCart(product.id);
                                                    ScaffoldMessenger.of(context).clearSnackBars();
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('${product.name} added to cart!'),
                                                        backgroundColor: AppColors.success,
                                                        duration: const Duration(seconds: 1),
                                                      ),
                                                    );
                                                  },
                                                  child: Container(
                                                    width: 26,
                                                    height: 26,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: AppColors.secondary, width: 1.0),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: const Center(
                                                      child: Icon(Icons.add, size: 16, color: AppColors.secondary),
                                                    ),
                                                  ),
                                                )
                                              : Container(
                                                  height: 26,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.secondary,
                                                    borderRadius: BorderRadius.circular(4),
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
                                                          padding: EdgeInsets.symmetric(horizontal: 4),
                                                          child: Icon(PhosphorIconsRegular.minus, size: 12, color: Colors.white),
                                                        ),
                                                      ),
                                                      Text(
                                                        '$cartCountOnItem',
                                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                      ),
                                                      GestureDetector(
                                                        onTap: () {
                                                          HapticFeedback.lightImpact();
                                                          ref.read(shopProvider.notifier).addToCart(product.id);
                                                        },
                                                        child: const Padding(
                                                          padding: EdgeInsets.symmetric(horizontal: 4),
                                                          child: Icon(PhosphorIconsRegular.plus, size: 12, color: Colors.white),
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
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
