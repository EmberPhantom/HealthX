import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/error_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tracker/providers/tracker_provider.dart';
import '../providers/rewards_provider.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final trackerState = ref.watch(trackerProvider);
    final rewardsState = ref.watch(rewardsProvider);
    final tasksAsync = ref.watch(rewardTasksProvider);

    final totalPoints = authState.user?.points ?? 0;

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
          'Health Rewards',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
        ),
      ),
      body: rewardsState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(trackerProvider.notifier).fetchAllData();
                await ref.read(rewardsProvider.notifier).loadClaimsState();
                ref.invalidate(rewardTasksProvider);
              },
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance Header Card
                    CustomCard(
                      backgroundColor: AppColors.secondary,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(PhosphorIconsFill.trophy, color: AppColors.primary, size: 48),
                              const SizedBox(height: 12),
                              const Text(
                                'TOTAL REWARD BALANCE',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$totalPoints',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 42,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Points',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Customize Wellness Targets Link Card
                    CustomCard(
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push('/rewards/wellness-goals');
                        },
                        child: Row(
                          children: [
                            const Icon(PhosphorIconsRegular.sliders, color: AppColors.rewardsAccent, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Customize Wellness Targets',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Update goals to recalculate calories & macros',
                                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(PhosphorIconsRegular.caretRight, size: 16, color: AppColors.neutral),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Daily Tasks Title
                    Text(
                      'DAILY HEALTH TASKS',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: 12),

                    tasksAsync.when(
                      data: (tasks) {
                        // Find steps task
                        final stepsTask = tasks.firstWhere(
                          (t) => t.taskId == 'steps',
                          orElse: () => const RewardTask(taskId: 'steps', title: 'Steps Milestone', points: 50, target: 10000, unit: 'steps'),
                        );

                        // Find sleep task
                        final sleepTask = tasks.firstWhere(
                          (t) => t.taskId == 'sleep',
                          orElse: () => const RewardTask(taskId: 'sleep', title: 'Healthy Sleep', points: 30, target: 420, unit: 'minutes'),
                        );

                        // Find water task
                        final waterTask = tasks.firstWhere(
                          (t) => t.taskId == 'water',
                          orElse: () => const RewardTask(taskId: 'water', title: 'Hydration Target', points: 20, target: 2500, unit: 'ml'),
                        );

                        // Steps details
                        final todaySteps = trackerState.todaySteps;
                        final stepsGoal = authState.user?.dailyStepGoal ?? stepsTask.target;
                        final stepsProgress = (todaySteps / stepsGoal).clamp(0.0, 1.0);
                        final stepsReached = todaySteps >= stepsGoal;

                        // Sleep details
                        final sleepLog = trackerState.lastSleep;
                        int sleepMins = 0;
                        if (sleepLog != null) {
                          sleepMins = sleepLog.wakeTime.difference(sleepLog.bedtime).inMinutes;
                        }
                        final sleepGoalMins = sleepTask.target;
                        final sleepProgress = (sleepMins / sleepGoalMins).clamp(0.0, 1.0);
                        final sleepReached = sleepMins >= sleepGoalMins;

                        // Water details
                        final todayWater = trackerState.todayWaterAmount;
                        final waterGoal = authState.user?.dailyWaterGoalMl ?? waterTask.target;
                        final waterProgress = (todayWater / waterGoal).clamp(0.0, 1.0);
                        final waterReached = todayWater >= waterGoal;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Steps Task
                            _buildTaskCard(
                              context: context,
                              ref: ref,
                              title: stepsTask.title,
                              description: 'Walk ${NumberFormat('#,###').format(stepsGoal)} steps today to earn rewards.',
                              progressText: '$todaySteps / $stepsGoal steps',
                              progress: stepsProgress,
                              pointValue: stepsTask.points,
                              isReached: stepsReached,
                              isClaimed: rewardsState.isStepsClaimed,
                              taskType: 'steps',
                              icon: PhosphorIconsFill.footprints,
                              iconColor: AppColors.stepsAccent,
                            ),
                            const SizedBox(height: 12),

                            // Sleep Task
                            _buildTaskCard(
                              context: context,
                              ref: ref,
                              title: sleepTask.title,
                              description: 'Log ${(sleepGoalMins / 60).toStringAsFixed(0)}+ hours of sleep today to recover.',
                              progressText: '${(sleepMins / 60).floor()}h ${sleepMins % 60}m / ${(sleepGoalMins / 60).floor()}h',
                              progress: sleepProgress,
                              pointValue: sleepTask.points,
                              isReached: sleepReached,
                              isClaimed: rewardsState.isSleepClaimed,
                              taskType: 'sleep',
                              icon: PhosphorIconsFill.moon,
                              iconColor: AppColors.sleepAccent,
                            ),
                            const SizedBox(height: 12),

                            // Water Task
                            _buildTaskCard(
                              context: context,
                              ref: ref,
                              title: waterTask.title,
                              description: 'Drink ${NumberFormat('#,###').format(waterGoal)} mL of water today.',
                              progressText: '$todayWater / $waterGoal mL',
                              progress: waterProgress,
                              pointValue: waterTask.points,
                              isReached: waterReached,
                              isClaimed: rewardsState.isWaterClaimed,
                              taskType: 'water',
                              icon: PhosphorIconsFill.drop,
                              iconColor: AppColors.waterAccent,
                            ),
                          ],
                        );
                      },
                      loading: () => Column(
                        children: const [
                          ShimmerLoading(height: 140),
                          SizedBox(height: 12),
                          ShimmerLoading(height: 140),
                          SizedBox(height: 12),
                          ShimmerLoading(height: 140),
                        ],
                      ),
                      error: (err, stack) => ErrorView(
                        message: 'Error loading rewards configuration: $err',
                        onRetry: () => ref.invalidate(rewardTasksProvider),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTaskCard({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String description,
    required String progressText,
    required double progress,
    required int pointValue,
    required bool isReached,
    required bool isClaimed,
    required String taskType,
    required IconData icon,
    required Color iconColor,
  }) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '+$pointValue PTS',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                progressText,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade100,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildClaimButton(context, ref, isReached, isClaimed, taskType, pointValue),
        ],
      ),
    );
  }

  Widget _buildClaimButton(
    BuildContext context,
    WidgetRef ref,
    bool isReached,
    bool isClaimed,
    String taskType,
    int amount,
  ) {
    if (isClaimed) {
      return PrimaryButton(
        text: 'CLAIMED',
        height: 38,
        onPressed: null, // Disabled style
      );
    }

    if (!isReached) {
      return PrimaryButton(
        text: 'TARGET NOT REACHED',
        height: 38,
        onPressed: null, // Disabled style
      );
    }

    return PrimaryButton(
      text: 'CLAIM $amount POINTS',
      height: 38,
      onPressed: () async {
        HapticFeedback.vibrate();
        final success = await ref.read(rewardsProvider.notifier).claimPoints(taskType, amount);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'Successfully claimed $amount points!' : 'Claim failed'),
              backgroundColor: success ? AppColors.success : AppColors.error,
            ),
          );
        }
      },
    );
  }
}
