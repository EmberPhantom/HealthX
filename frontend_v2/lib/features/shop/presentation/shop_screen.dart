import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/subscription_provider.dart';
import '../../../core/models/subscription_models.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> with AutomaticKeepAliveClientMixin {
  int _cartCount = 0;

  @override
  bool get wantKeepAlive => true;
  double _cartTotal = 0.0;

  void _addToCart(double price, String name) {
    setState(() {
      _cartCount++;
      _cartTotal += price;
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name added to cart!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _checkoutCart() {
    if (_cartCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty. Add items first!'), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Checkout Cart', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Items in Cart: $_cartCount', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Total Price: ₹${_cartTotal.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondary)),
              const SizedBox(height: 12),
              const Text('This is a mock transaction. No money will be charged.', style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)),
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
              onPressed: () {
                setState(() {
                  _cartCount = 0;
                  _cartTotal = 0.0;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order placed successfully! Thank you for shopping.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('PLACE ORDER'),
            ),
          ],
        );
      },
    );
  }

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
              const Text('This is a mock transaction. No real money will be charged.', style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)),
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
                final success = await ref.read(subscriptionProvider.notifier).cancel(id); // Use cancel as pause mock
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

  Widget _buildCategoryCard({
    required BuildContext context,
    required String title,
    required String imageUrl,
    bool isArrow = false,
  }) {
    if (isArrow) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('All categories are displayed.'), duration: Duration(milliseconds: 700)),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                PhosphorIconsRegular.arrowRight,
                color: AppColors.secondary,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                'VIEW ALL',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 10,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.1),
              Colors.black.withValues(alpha: 0.6),
            ],
          ),
        ),
        padding: const EdgeInsets.all(12),
        alignment: Alignment.bottomLeft,
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
        ),
      ),
    );
  }

  Widget _buildProductCard({
    required BuildContext context,
    required String name,
    required String size,
    required double price,
    required String imageUrl,
    bool isBestseller = false,
  }) {
    return Container(
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
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (isBestseller)
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
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                ),
                Text(
                  size,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${price.toInt()}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                    ),
                    GestureDetector(
                      onTap: () => _addToCart(price, name),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.secondary, width: 1.0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Icon(Icons.add, size: 18, color: AppColors.secondary),
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
                  fontSize: 22,
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
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
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
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.secondary),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _checkoutCart,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.secondary, width: 1.5),
        ),
        child: Badge(
          label: Text('$_cartCount'),
          isLabelVisible: _cartCount > 0,
          child: const Icon(
            PhosphorIconsRegular.shoppingCart,
            size: 26,
          ),
        ),
      ),
      body: subState.isLoading && subState.subscriptions.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(subscriptionProvider.notifier).fetchSubscriptions();
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
                                'Fuel your performance.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${_cartTotal.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Active subscription banner if exists
                    if (activeSub != null) ...[
                      _buildActiveSubCard(context, ref, activeSub),
                      const SizedBox(height: 20),
                    ],

                    // Featured Card Banner
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: const DecorationImage(
                          image: NetworkImage('https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?fit=crop&w=400&h=200'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withValues(alpha: 0.8),
                              Colors.black.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'FEATURED',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Premium Subscriptions',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            PrimaryButton(
                              text: 'VIEW OPTIONS BELOW',
                              isFullWidth: false,
                              height: 36,
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Subscription Plans Section
                    Text(
                      'SUBSCRIPTION PLANS',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 12),
                    _buildPlanCard(
                      context: context,
                      ref: ref,
                      planId: 'basic',
                      planName: 'Basic Plan',
                      price: 499,
                      features: const [
                        'Daily step and sleep log tracking',
                        'Basic health analytics report',
                        '1 doctor consultation per month',
                      ],
                      activeSub: activeSub,
                    ),
                    const SizedBox(height: 16),
                    _buildPlanCard(
                      context: context,
                      ref: ref,
                      planId: 'pro',
                      planName: 'Pro Plan',
                      price: 999,
                      features: const [
                        'Advanced glucose and metrics logging',
                        'Detailed trend analysis charts',
                        'Unlimited doctor consult bookings',
                        'Priority support queue access',
                      ],
                      isBestseller: true,
                      activeSub: activeSub,
                    ),
                    const SizedBox(height: 16),
                    _buildPlanCard(
                      context: context,
                      ref: ref,
                      planId: 'elite',
                      planName: 'Elite Plan',
                      price: 1999,
                      features: const [
                        'Personal nutritionist and wellness coach',
                        '24/7 priority emergency doctor helpline',
                        'Monthly customized supplement box delivery',
                        'Complete health panel reviews',
                      ],
                      activeSub: activeSub,
                    ),
                    const SizedBox(height: 24),

                    // Categories Section
                    Text(
                      'PRODUCT CATEGORIES',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.25,
                      children: [
                        _buildCategoryCard(
                          context: context,
                          title: 'Daily Meals',
                          imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?fit=crop&w=150&h=100',
                        ),
                        _buildCategoryCard(
                          context: context,
                          title: 'Healthy Breakfast',
                          imageUrl: 'https://images.unsplash.com/photo-1497534446932-c925b458314e?fit=crop&w=150&h=100',
                        ),
                        _buildCategoryCard(
                          context: context,
                          title: 'Snacks & Treats',
                          imageUrl: 'https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?fit=crop&w=150&h=100',
                        ),
                        _buildCategoryCard(
                          context: context,
                          title: 'View All',
                          imageUrl: '',
                          isArrow: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Trending Now Section
                    Text(
                      'TRENDING NOW',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildProductCard(
                            context: context,
                            name: 'Whey Isolate Pro',
                            size: '30 Servings',
                            price: 2499,
                            imageUrl: 'https://images.unsplash.com/photo-1579758629938-03607ccdbaba?fit=crop&w=150&h=120',
                            isBestseller: true,
                          ),
                          const SizedBox(width: 16),
                          _buildProductCard(
                            context: context,
                            name: 'Keto Energy Bars',
                            size: 'Box of 12',
                            price: 899,
                            imageUrl: 'https://images.unsplash.com/photo-1568254183919-78a4f43a2877?fit=crop&w=150&h=120',
                          ),
                          const SizedBox(width: 16),
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
