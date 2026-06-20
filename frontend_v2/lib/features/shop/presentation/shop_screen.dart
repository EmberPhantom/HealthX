import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/error_view.dart';
import '../providers/subscription_provider.dart';
import '../../../core/models/subscription_models.dart';
import '../providers/shop_provider.dart';
import '../../../core/models/shop_models.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> with AutomaticKeepAliveClientMixin {
  String _selectedCategory = 'All';

  @override
  bool get wantKeepAlive => true;

  Future<void> _checkoutPlan(BuildContext context, WidgetRef ref, String planId, double price, String planName) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Confirm Purchase', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You are subscribing to:', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 4),
              Text(planName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.secondary)),
              const SizedBox(height: 8),
              Text('Price: ₹${price.toInt()} / month', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              const Text('Demo mode — no real payment will be processed.', style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: AppColors.neutral)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.secondary,
              ),
              onPressed: () async {
                final success = await ref.read(subscriptionProvider.notifier).subscribe(planId, price, planName);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Successfully subscribed to $planName!' : 'Failed to subscribe'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('PAY & SUBSCRIBE'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmCancelSubscription(BuildContext context, WidgetRef ref, String id) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Cancel Subscription', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to cancel your active subscription? You will lose access to premium tracking features and consults.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('NO', style: TextStyle(color: AppColors.neutral)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                final success = await ref.read(subscriptionProvider.notifier).cancel(id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Subscription cancelled successfully' : 'Failed to cancel subscription'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('YES, CANCEL'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmPauseSubscription(BuildContext context, WidgetRef ref, String id) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Pause Subscription', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to pause your active subscription? You can resume it at any time.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('NO', style: TextStyle(color: AppColors.neutral)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              onPressed: () async {
                final success = await ref.read(subscriptionProvider.notifier).pause(id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Subscription paused successfully' : 'Failed to pause subscription'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('YES, PAUSE'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, ShopProduct product) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/shop/product/${product.id}');
      },
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: AppColors.tertiary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    color: AppColors.primary.withValues(alpha: 0.05),
                    image: product.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(product.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: product.imageUrl.isEmpty
                      ? Center(child: Text(product.emoji, style: const TextStyle(fontSize: 48)))
                      : null,
                ),
                if (product.rating >= 4.8)
                  const Positioned(
                    top: 8,
                    left: 8,
                    child: StatusBadge(
                      text: 'BESTSELLER',
                      dotColor: AppColors.secondary,
                      backgroundColor: AppColors.primary,
                      textColor: AppColors.secondary,
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
                    '${product.calories} kcal • ${product.isVeg ? 'Veg' : 'Non-Veg'}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                      GestureDetector(
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

  Widget _buildActiveSubCard(BuildContext context, WidgetRef ref, UserSubscription sub) {
    final isCancelled = sub.status.toLowerCase() == 'cancelled';
    final isPaused = sub.status.toLowerCase() == 'paused';

    final statusColor = isCancelled
        ? Colors.red
        : isPaused
            ? Colors.orange
            : const Color(0xFF10B981);
    final statusBg = isCancelled
        ? const Color(0xFFFFEFE6)
        : isPaused
            ? const Color(0xFFFEF9C3)
            : const Color(0xFFD1FAE5);

    final expiryText = DateFormat('MMMM d, yyyy').format(sub.endDate);

    return CustomCard(
      backgroundColor: const Color(0xFFFCFDF2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR ACTIVE SUBSCRIPTION',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              StatusBadge(
                text: sub.status.toUpperCase(),
                dotColor: statusColor,
                backgroundColor: statusBg,
                textColor: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            sub.planName.toUpperCase(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Billed ${sub.billingPeriod} • Price: ₹${sub.price}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            'Valid until: $expiryText',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
          ),
          if (!isCancelled && !isPaused) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.neutral, width: 1),
                      foregroundColor: AppColors.neutral,
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _confirmPauseSubscription(context, ref, sub.id),
                    child: const Text('PAUSE PLAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 1),
                      foregroundColor: Colors.red,
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _confirmCancelSubscription(context, ref, sub.id),
                    child: const Text('CANCEL PLAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required WidgetRef ref,
    required String planId,
    required String planName,
    required double price,
    required List<String> features,
    bool isBestseller = false,
    UserSubscription? activeSub,
  }) {
    final hasActiveSub = activeSub != null;
    final isActiveThisPlan = hasActiveSub && activeSub.planId == planId && activeSub.status == 'active';

    return CustomCard(
      backgroundColor: isActiveThisPlan ? const Color(0xFFFCFDF2) : AppColors.tertiary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                planName.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              if (isActiveThisPlan)
                const StatusBadge(
                  text: 'ACTIVE',
                  dotColor: Color(0xFF10B981),
                  backgroundColor: Color(0xFFD1FAE5),
                  textColor: Color(0xFF10B981),
                )
              else if (isBestseller)
                const StatusBadge(
                  text: 'BESTSELLER',
                  dotColor: AppColors.secondary,
                  backgroundColor: AppColors.primary,
                  textColor: AppColors.secondary,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${price.toInt()} / month',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.secondary),
          ),
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(PhosphorIconsFill.checkCircle, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          if (isActiveThisPlan)
            const Text(
              'Currently active.',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 12),
            )
          else
            PrimaryButton(
              text: hasActiveSub ? 'SWITCH TO PLAN' : 'SUBSCRIBE NOW',
              height: 38,
              onPressed: () => _checkoutPlan(context, ref, planId, price, planName),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final subState = ref.watch(subscriptionProvider);
    final activeSub = subState.activeSubscription;
    final subscriptionPlansAsync = ref.watch(subscriptionPlansProvider);

    final shopState = ref.watch(shopProvider);
    final cartCount = shopState.cartCount;
    final cartTotal = shopState.cartSubtotal;

    // Filter products dynamically
    final filteredProducts = shopState.products.where((p) {
      if (_selectedCategory == 'All') return true;
      return p.category.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
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
      body: shopState.isLoading && shopState.products.isEmpty
          ? _buildShimmer()
          : shopState.error != null && shopState.products.isEmpty
              ? ErrorView(
                  message: shopState.error!,
                  onRetry: () => ref.read(shopProvider.notifier).fetchCatalog(),
                )
              : RefreshIndicator(
              onRefresh: () async {
                await ref.read(subscriptionProvider.notifier).fetchSubscriptions();
                await ref.read(shopProvider.notifier).fetchCatalog();
                ref.invalidate(subscriptionPlansProvider);
              },
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shop Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shop',
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fuel your performance and recovery.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        if (cartTotal > 0)
                          Text(
                            '₹${cartTotal.toInt()}',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Shop Shortcuts
                    Row(
                      children: [
                        Expanded(
                          child: _buildShortcutCard(
                            context,
                            icon: PhosphorIconsRegular.bowlSteam,
                            label: 'Menu',
                            color: const Color(0xFFE8F5E9),
                            onTap: () => context.push('/shop/menu'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildShortcutCard(
                            context,
                            icon: PhosphorIconsRegular.sparkle,
                            label: 'Snacks',
                            color: const Color(0xFFEFF6FF),
                            onTap: () => context.push('/shop/ready-to-eat'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildShortcutCard(
                            context,
                            icon: PhosphorIconsRegular.calendar,
                            label: 'Meal Plans',
                            color: const Color(0xFFFFF7ED),
                            onTap: () => context.push('/shop/meal-plan'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildShortcutCard(
                            context,
                            icon: PhosphorIconsRegular.heart,
                            label: 'Liked',
                            color: const Color(0xFFFFF1F2),
                            onTap: () => context.push('/shop/favorites'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Custom Bowl Builder Banner
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/shop/custom-bowl');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                PhosphorIconsRegular.bowlFood,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Build Your Custom Bowl',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Pick your base, protein, veggies, and dressings. Calculated live!',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              PhosphorIconsRegular.arrowRight,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Active subscription banner if exists
                    if (activeSub != null) ...[
                      _buildActiveSubCard(context, ref, activeSub),
                      const SizedBox(height: 20),
                    ],

                    // Subscription Plans Section
                    Text(
                      'SUBSCRIPTION PLANS',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 12),
                    subscriptionPlansAsync.when(
                      data: (plans) {
                        return Column(
                          children: [
                            ...plans.map((plan) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: _buildPlanCard(
                                  context: context,
                                  ref: ref,
                                  planId: plan.planId,
                                  planName: plan.planName,
                                  price: plan.price,
                                  features: plan.features,
                                  isBestseller: plan.isBestseller,
                                  activeSub: activeSub,
                                ),
                              );
                            }),
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      ),
                      error: (err, stack) => ErrorView(
                        message: 'Error loading plans: $err',
                        onRetry: () => ref.invalidate(subscriptionPlansProvider),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Category Filters Row
                    const Text(
                      'PRODUCT CATEGORIES',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildCategoryChip('All'),
                          ...shopState.categories.map((cat) => _buildCategoryChip(cat)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Catalog items section
                    Text(
                      _selectedCategory == 'All' ? 'HEALTHY FOODS & SUPPLEMENTS' : '${_selectedCategory.toUpperCase()} ITEMS',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 12),
                    
                    if (filteredProducts.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Text('No products found in this category.', style: TextStyle(color: AppColors.neutral)),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final prod = filteredProducts[index];
                          return _buildProductCard(context, prod);
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildShimmer() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoading(height: 28, width: 80),
          const SizedBox(height: 6),
          const ShimmerLoading(height: 16, width: 200),
          const SizedBox(height: 24),
          const ShimmerLoading(height: 120),
          const SizedBox(height: 20),
          const ShimmerLoading(height: 16, width: 140),
          const SizedBox(height: 12),
          const ShimmerLoading(height: 120),
          const SizedBox(height: 16),
          const ShimmerLoading(height: 120),
          const SizedBox(height: 24),
          const ShimmerLoading(height: 16, width: 160),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(5, (_) => const Padding(
                padding: EdgeInsets.only(right: 8),
                child: ShimmerLoading(width: 70, height: 38, borderRadius: 20),
              )),
            ),
          ),
          const SizedBox(height: 20),
          const ShimmerLoading(height: 16, width: 180),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: 4,
            itemBuilder: (_, __) => const ShimmerLoading(height: 180, borderRadius: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String categoryName) {
    final isSelected = _selectedCategory == categoryName;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(categoryName),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: Colors.grey.shade100,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.secondary : AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        onSelected: (val) {
          if (val) {
            setState(() => _selectedCategory = categoryName);
          }
        },
      ),
    );
  }

  Widget _buildShortcutCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.secondary, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
