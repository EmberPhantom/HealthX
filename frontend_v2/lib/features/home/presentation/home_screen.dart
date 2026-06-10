import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Greeting
            Text(
              'Good Morning, Alex.',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your vital signs are good today.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),

            // Overall Health Card
            CustomCard(
              backgroundColor: const Color(0xFFFCFDF2), // Light gradient/primary tint
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const StatusBadge(
                          text: 'Overall Health',
                          dotColor: AppColors.primary,
                          backgroundColor: Color(0xFFF1F6D0),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your composite score based on sleep, activity, and vitals.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          text: 'VIEW METRICS',
                          isFullWidth: false,
                          height: 40,
                          icon: const Icon(
                            PhosphorIconsBold.arrowRight,
                            color: AppColors.secondary,
                            size: 16,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 110,
                            height: 110,
                            child: CircularProgressIndicator(
                              value: 0.85,
                              strokeWidth: 10,
                              backgroundColor: Colors.grey.shade200,
                              color: AppColors.primary,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '85',
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                    ),
                              ),
                              Text(
                                'SCORE',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontSize: 10,
                                      letterSpacing: 1.0,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Health Shop Banner
            CustomCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      PhosphorIconsFill.storefront,
                      color: Colors.amber.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'HEALTH SHOP',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontSize: 11,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            const StatusBadge(
                              text: 'OFFERS',
                              dotColor: Colors.amber,
                              backgroundColor: Color(0xFFFEF9C3),
                              textColor: Colors.amber,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Supplements',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Starting from ₹499',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade100,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        PhosphorIconsRegular.arrowRight,
                        color: AppColors.secondary,
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Steps Tracker Card
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            PhosphorIconsFill.footprints,
                            color: Color(0xFF10B981),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'STEPS TRACKER',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const StatusBadge(
                        text: 'LIVE',
                        dotColor: Color(0xFF10B981),
                        backgroundColor: Color(0xFFD1FAE5),
                        textColor: Color(0xFF10B981),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                          ),
                      children: [
                        const TextSpan(text: '8,432 '),
                        TextSpan(
                          text: '/ 10,000 steps',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.8432,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade100,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sleep & Hydration row
            Row(
              children: [
                Expanded(
                  child: CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              PhosphorIconsFill.moon,
                              color: Colors.indigo,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'SLEEP',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '6h 45m',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Icon(
                              PhosphorIconsBold.arrowDown,
                              color: Colors.red,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '15m vs avg',
                              style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              PhosphorIconsFill.drop,
                              color: Colors.blue,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'HYDRATION',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '1.2L',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Goal: 2.5L',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Records Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      PhosphorIconsBold.shieldCheck,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'RECENT RECORDS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: Row(
                    children: [
                      Text(
                        'View All',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        PhosphorIconsBold.caretRight,
                        color: AppColors.secondary,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Records List
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        PhosphorIconsFill.drop,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Glucose Reading',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    subtitle: Text(
                      'Last recorded 2h ago',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                          ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '95 ',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'mg/dL',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                              ),
                        ),
                        const SizedBox(width: 12),
                        const StatusBadge(
                          text: 'NORMAL',
                          dotColor: Color(0xFF10B981),
                          backgroundColor: Color(0xFFD1FAE5),
                          textColor: Color(0xFF10B981),
                        ),
                      ],
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  const Divider(color: AppColors.background, height: 1, thickness: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        PhosphorIconsFill.appleLogo,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Daily Macros',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    subtitle: Text(
                      'Lunch logged',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                          ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '1,240 ',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'kcal',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                              ),
                        ),
                        const SizedBox(width: 12),
                        const StatusBadge(
                          text: 'ON TRACK',
                          dotColor: Colors.amber,
                          backgroundColor: Color(0xFFFEF9C3),
                          textColor: Colors.amber,
                        ),
                      ],
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
