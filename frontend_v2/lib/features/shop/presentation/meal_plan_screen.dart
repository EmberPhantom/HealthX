import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/shop_models.dart';
import '../providers/shop_provider.dart';
import '../providers/subscription_provider.dart';
import '../../../core/models/subscription_models.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/status_badge.dart';

class MealPlanScreen extends ConsumerWidget {
  const MealPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealPlansAsync = ref.watch(mealPlansProvider);
    final subState = ref.watch(subscriptionProvider);
    final activeSub = subState.activeSubscription;

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
        title: const Text(
          'Meal Subscriptions',
          style: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: mealPlansAsync.when(
        data: (plans) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(mealPlansProvider);
              await ref.read(subscriptionProvider.notifier).fetchSubscriptions();
            },
            color: AppColors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              children: [
                if (activeSub != null) ...[
                  _ActiveSubscriptionCard(sub: activeSub),
                  const SizedBox(height: 20),
                ],
                const Text(
                  'AVAILABLE PLANS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                ...plans.map((plan) {
                  final isActive = activeSub != null && activeSub.planId == plan.id && activeSub.status == 'active';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _MealPlanCard(plan: plan, isActive: isActive),
                  );
                }),
              ],
            ),
          );
        },
        loading: () => const _MealPlansShimmer(),
        error: (err, stack) => Center(
          child: Text(
            'Error loading meal plans: $err',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}

class _ActiveSubscriptionCard extends ConsumerWidget {
  final UserSubscription sub;
  const _ActiveSubscriptionCard({required this.sub});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPaused = sub.status.toLowerCase() == 'paused';
    final expiryText = DateFormat('MMMM d, yyyy').format(sub.endDate);

    return CustomCard(
      backgroundColor: const Color(0xFFFCFDF2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'YOUR ACTIVE SUBSCRIPTION',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              StatusBadge(
                text: sub.status.toUpperCase(),
                dotColor: isPaused ? Colors.orange : const Color(0xFF10B981),
                backgroundColor: isPaused ? const Color(0xFFFEF9C3) : const Color(0xFFD1FAE5),
                textColor: isPaused ? Colors.orange : const Color(0xFF10B981),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            sub.planName.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Billed ${sub.billingPeriod} • Price: ${sub.price}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            'Valid until: $expiryText',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (!isPaused) ...[
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.neutral, width: 1),
                      foregroundColor: AppColors.neutral,
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final confirm = await _showConfirmDialog(context, 'Pause Subscription', 'Are you sure you want to pause your active subscription? You can resume it at any time.');
                      if (confirm == true) {
                        await ref.read(subscriptionProvider.notifier).pause(sub.id);
                      }
                    },
                    child: const Text('PAUSE PLAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error, width: 1),
                    foregroundColor: AppColors.error,
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final confirm = await _showConfirmDialog(context, 'Cancel Subscription', 'Are you sure you want to cancel your active subscription? You will lose access to premium tracking features and consults.');
                    if (confirm == true) {
                      await ref.read(subscriptionProvider.notifier).cancel(sub.id);
                    }
                  },
                  child: const Text('CANCEL PLAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(BuildContext context, String title, String body) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('NO', style: TextStyle(color: AppColors.neutral)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: title.startsWith('Cancel') ? AppColors.error : Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('YES, CONFIRM'),
          ),
        ],
      ),
    );
  }
}

class _MealPlanCard extends StatelessWidget {
  final MealPlan plan;
  final bool isActive;

  const _MealPlanCard({required this.plan, required this.isActive});

  @override
  Widget build(BuildContext context) {
    Color accentColor = AppColors.primary;
    try {
      if (plan.accentColor.startsWith('0xFF')) {
        accentColor = Color(int.parse(plan.accentColor));
      }
    } catch (_) {}

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? AppColors.secondary : AppColors.border, width: isActive ? 1.5 : 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner image
                Container(
                  height: 120,
                  width: double.infinity,
                  color: accentColor.withValues(alpha: 0.1),
                  child: plan.imageUrl.isNotEmpty
                      ? Image.network(plan.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildFallbackImage())
                      : _buildFallbackImage(),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            plan.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.secondary,
                            ),
                          ),
                          if (isActive)
                            const StatusBadge(
                              text: 'ACTIVE',
                              dotColor: Color(0xFF10B981),
                              backgroundColor: Color(0xFFD1FAE5),
                              textColor: Color(0xFF10B981),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.neutral,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${plan.price}${plan.priceSuffix}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.secondary,
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.secondary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: AppColors.secondary, width: 1.0),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MealPlanDetailScreen(plan: plan),
                                ),
                              );
                            },
                            child: const Text(
                              'VIEW DETAILS',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (plan.badgeLabel != null && plan.badgeLabel!.isNotEmpty)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    plan.badgeLabel!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Center(
      child: Icon(
        PhosphorIconsRegular.bowlSteam,
        size: 44,
        color: AppColors.secondary.withValues(alpha: 0.4),
      ),
    );
  }
}

class MealPlanDetailScreen extends ConsumerWidget {
  final MealPlan plan;

  const MealPlanDetailScreen({super.key, required this.plan});

  double _parsePrice(String priceStr) {
    final clean = priceStr.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subState = ref.watch(subscriptionProvider);
    final hasActiveSubThisPlan = subState.subscriptions.any((s) => s.planId == plan.id && s.status == 'active');

    // Dynamic details based on plan type/destination
    List<String> features = [];
    List<String> includes = [];
    Map<String, String> focus = {};

    if (plan.destination == 'healthy_bowl') {
      features = ['Personalized Nutrition', 'Progress Analytics', 'Expert Advice'];
      includes = [
        'Weekly meal plans customized to your dietary goals',
        'Nutritious recipes crafted to support muscle growth',
        'Flexible cancellation at any time'
      ];
      focus = {'Calories': '2,000 kcal', 'Protein': '100g', 'Water': '3L'};
    } else if (plan.destination == 'zym_bowl') {
      features = ['Muscle Power', 'Workout Support', 'Gains Tracking'];
      includes = [
        'High protein meal plans rich in amino acids',
        'Custom pre/post workout nutrition guidance',
        'Weekly gains & weight reports'
      ];
      focus = {'Calories': '2,500 kcal', 'Protein': '180g', 'Water': '4L'};
    } else if (plan.destination == 'diabetic_care') {
      features = ['Sugar Control', 'Low Glycemic', 'Doctor Monitored'];
      includes = [
        'Low carb, high fiber diet tailored for blood sugar control',
        'Insulin trend synchronization alerts',
        'Hba1c impact estimation models'
      ];
      focus = {'Calories': '1,800 kcal', 'Carbs': 'Under 130g', 'Water': '2.5L'};
    } else {
      features = ['Corporate Tie-Up', 'Bulk Savings', 'HR Wellness Logs'];
      includes = [
        'Bulk healthy bowls delivered directly to your office',
        'Tax savings & HR wellness compliance reports',
        'Easy team allocations'
      ];
      focus = {'Calories': '1,900 kcal', 'Protein': '90g', 'Water': '2.5L'};
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.secondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    plan.name,
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Image Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: plan.imageUrl.isNotEmpty
                            ? Image.network(plan.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(PhosphorIconsRegular.image, size: 48))
                            : const Icon(PhosphorIconsRegular.image, size: 48),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title Section
                    Text(
                      plan.name.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.secondary),
                    ),
                    Text(
                      plan.subtitle,
                      style: const TextStyle(fontSize: 14, color: AppColors.neutral, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),

                    // Price tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.secondary, width: 1),
                      ),
                      child: Text(
                        '${plan.price}${plan.priceSuffix}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondary),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Feature badges
                    const Text('KEY ADVANTAGES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0)),
                    const SizedBox(height: 10),
                    Row(
                      children: features.map((f) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border, width: 0.5),
                            ),
                            child: Column(
                              children: [
                                const Icon(PhosphorIconsRegular.shieldCheck, color: AppColors.secondary, size: 20),
                                const SizedBox(height: 6),
                                Text(
                                  f,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // What's included checklist
                    const Text("WHAT'S INCLUDED", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0)),
                    const SizedBox(height: 10),
                    ...includes.map((inc) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(PhosphorIconsFill.checkCircle, color: AppColors.primary, size: 18),
                            const SizedBox(width: 10),
                            Expanded(child: Text(inc, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),

                    // Today's Focus
                    const Text("DAILY METRIC FOCUS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0)),
                    const SizedBox(height: 10),
                    Row(
                      children: focus.entries.map((entry) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border, width: 0.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.key, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.neutral)),
                                const SizedBox(height: 2),
                                Text(entry.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.secondary)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 36),

                    // CTA Button
                    if (hasActiveSubThisPlan)
                      const Center(
                        child: Text(
                          'Currently Subscribed and Active',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                      )
                    else
                      PrimaryButton(
                        text: 'SUBSCRIBE & CHECKOUT',
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          _checkout(context, ref);
                        },
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _checkout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Confirm Subscription', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You are subscribing to:', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 4),
              Text(plan.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.secondary)),
              const SizedBox(height: 8),
              Text('Price: ${plan.price}${plan.priceSuffix}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              const Text('Demo mode — no real payment will be processed.', style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: AppColors.neutral)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.secondary,
              ),
              onPressed: () async {
                Navigator.pop(ctx); // Dismiss confirm dialog
                final priceNum = _parsePrice(plan.price);
                
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
                  ),
                );

                final success = await ref.read(subscriptionProvider.notifier).subscribe(plan.id, priceNum, plan.name);
                
                if (context.mounted) {
                  Navigator.pop(context); // Dismiss loading spinner
                  
                  if (success) {
                    _showSuccessDialog(context, plan.name);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Subscription failed. Please try again.'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text('PAY & SUBSCRIBE'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context, String planName) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF43A047), size: 32),
              ),
              const SizedBox(height: 14),
              const Text('Plan Subscribed!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondary, decoration: TextDecoration.none), textAlign: TextAlign.center),
              const SizedBox(height: 7),
              Text("Your subscription to $planName is active. Let's build healthy habits!", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.neutral, height: 1.5, decoration: TextDecoration.none), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop(); // Go back to plans list
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.secondary, width: 1.5),
                  ),
                  child: const Center(
                    child: Text(
                      "Awesome!",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondary, decoration: TextDecoration.none),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealPlansShimmer extends StatelessWidget {
  const _MealPlansShimmer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoading(height: 16, width: 100),
          const SizedBox(height: 12),
          const ShimmerLoading(height: 220, borderRadius: 16),
          const SizedBox(height: 16),
          const ShimmerLoading(height: 220, borderRadius: 16),
        ],
      ),
    );
  }
}
