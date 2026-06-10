import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/home_provider.dart';
import '../../tracker/providers/tracker_provider.dart';
import '../../../core/models/tracker_models.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _calculateScore(int steps, int water, String sleepStr) {
    int score = 60; // baseline score
    // Add points for steps (up to 15 points)
    score += (steps / 10000 * 15).clamp(0, 15).toInt();
    // Add points for water (up to 15 points)
    score += (water / 2500 * 15).clamp(0, 15).toInt();
    // Add points for sleep duration recorded (up to 10 points)
    if (sleepStr != '0h 0m') {
      score += 10;
    }
    return score.clamp(0, 100);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final homeState = ref.watch(homeProvider);
    final trackerState = ref.watch(trackerProvider);
    final score = _calculateScore(homeState.todaySteps, homeState.todayWater, homeState.sleepDuration);

    final String greeting = DateTime.now().hour < 12
        ? 'Good Morning'
        : DateTime.now().hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: homeState.isLoading && trackerState.waterLogs.isEmpty && trackerState.sleepLogs.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(trackerProvider.notifier).fetchAllData();
              },
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Greeting
                    Text(
                      '$greeting, ${homeState.userName}.',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your vital signs are looking stable today.',
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
                                  onPressed: () {
                                    context.go('/tracker');
                                  },
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
                                      value: score / 100.0,
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
                                        '$score',
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
                              onPressed: () {
                                context.go('/shop');
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Steps Tracker Card
                    GestureDetector(
                      onTap: () => context.go('/tracker'),
                      child: CustomCard(
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
                                  TextSpan(text: '${NumberFormat('#,###').format(homeState.todaySteps)} '),
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
                                value: (homeState.todaySteps / 10000.0).clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade100,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sleep & Hydration row
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.go('/tracker'),
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
                                    homeState.sleepDuration,
                                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        PhosphorIconsBold.moonStars,
                                        color: Colors.indigo,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          trackerState.lastSleep != null
                                              ? 'Last logged sleep'
                                              : 'No sleep log yet',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.go('/tracker'),
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
                                    '${(homeState.todayWater / 1000.0).toStringAsFixed(1)}L',
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
                          onPressed: () {
                            context.go('/tracker');
                          },
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
                          if (trackerState.glucoseLogs.isEmpty &&
                              trackerState.waterLogs.isEmpty &&
                              trackerState.sleepLogs.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Center(
                                child: Text(
                                  'No records logged yet. Start tracking above!',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ),
                            )
                          else ...[
                            if (trackerState.glucoseLogs.isNotEmpty) ...[
                              _buildGlucoseTile(context, trackerState.glucoseLogs.first),
                              if (trackerState.sleepLogs.isNotEmpty || trackerState.waterLogs.isNotEmpty)
                                const Divider(color: AppColors.border, height: 1, thickness: 0.5),
                            ],
                            if (trackerState.sleepLogs.isNotEmpty) ...[
                              _buildSleepTile(context, trackerState.sleepLogs.first),
                              if (trackerState.waterLogs.isNotEmpty)
                                const Divider(color: AppColors.border, height: 1, thickness: 0.5),
                            ],
                            if (trackerState.waterLogs.isNotEmpty)
                              _buildWaterTile(context, trackerState.waterLogs.first),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGlucoseTile(BuildContext context, GlucoseLog log) {
    final status = log.level <= 140 ? 'NORMAL' : 'HIGH';
    final dotColor = log.level <= 140 ? const Color(0xFF10B981) : Colors.orange;
    final bgColor = log.level <= 140 ? const Color(0xFFD1FAE5) : const Color(0xFFFFEFE6);

    return ListTile(
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
        'Glucose Reading (${log.readingType})',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      subtitle: Text(
        'Recorded ${_timeAgo(log.loggedAt)}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
            ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${log.level} ',
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
          const SizedBox(width: 8),
          StatusBadge(
            text: status,
            dotColor: dotColor,
            backgroundColor: bgColor,
            textColor: dotColor,
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildSleepTile(BuildContext context, SleepLog log) {
    final duration = log.wakeTime.difference(log.bedtime);
    final hours = duration.inHours;
    final mins = duration.inMinutes % 60;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          PhosphorIconsFill.moon,
          color: Colors.indigo,
          size: 20,
        ),
      ),
      title: Text(
        'Sleep Log',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      subtitle: Text(
        'Woke up ${_timeAgo(log.wakeTime)}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
            ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${hours}h ${mins}m ',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 8),
          const StatusBadge(
            text: 'RESTED',
            dotColor: Colors.indigo,
            backgroundColor: Color(0xFFE0E7FF),
            textColor: Colors.indigo,
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildWaterTile(BuildContext context, WaterLog log) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          PhosphorIconsFill.drop,
          color: Colors.blue,
          size: 20,
        ),
      ),
      title: Text(
        'Hydration Log',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      subtitle: Text(
        'Logged ${_timeAgo(log.loggedAt)}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
            ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${log.amount} ',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            'mL',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                ),
          ),
          const SizedBox(width: 8),
          const StatusBadge(
            text: 'ON TRACK',
            dotColor: Colors.blue,
            backgroundColor: Color(0xFFE0F2FE),
            textColor: Colors.blue,
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
