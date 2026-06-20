import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/utils/health_utils.dart';
import '../providers/tracker_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/meal_provider.dart';
import 'log_meal_sheet.dart';
import '../../../core/models/tracker_models.dart';

class TrackerScreen extends ConsumerStatefulWidget {
  const TrackerScreen({super.key});

  @override
  ConsumerState<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends ConsumerState<TrackerScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _calculateScore(int steps, int water, String sleepStr, {int stepGoal = 8000, int waterGoal = 3000}) {
    return calculateScore(steps, water, sleepStr, stepGoal: stepGoal, waterGoal: waterGoal);
  }

  String _timeAgo(DateTime dt) {
    return timeAgo(dt, showDate: false);
  }



  @override
  Widget build(BuildContext context) {
    super.build(context);
    final trackerState = ref.watch(trackerProvider);
    final mealState = ref.watch(mealProvider);
    final authState = ref.watch(authProvider);
    final userProfile = authState.user;

    final stepTarget = userProfile?.dailyStepGoal ?? 8000;
    final waterTarget = userProfile?.dailyWaterGoalMl ?? 3000;

    final sleepLog = trackerState.lastSleep;
    String sleepDuration = '0h 0m';
    double sleepRatio = 0.0;
    if (sleepLog != null) {
      final diff = sleepLog.wakeTime.difference(sleepLog.bedtime);
      final hours = diff.inHours;
      final mins = diff.inMinutes % 60;
      sleepDuration = '${hours}h ${mins}m';
      sleepRatio = (diff.inMinutes / 480.0).clamp(0.0, 1.0); // 8 hours is target
    }

    final score = _calculateScore(
      trackerState.todaySteps,
      trackerState.todayWaterAmount,
      sleepDuration,
      stepGoal: stepTarget,
      waterGoal: waterTarget,
    );

    // Calculate weekly scores & labels dynamically
    final List<double> weeklyScores = [];
    final List<String> weeklyLabels = [];

    for (int i = 6; i >= 0; i--) {
      final targetDate = DateTime.now().subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(targetDate);
      
      weeklyLabels.add(DateFormat('E').format(targetDate).substring(0, 1));

      final stepLog = trackerState.stepLogs.firstWhere(
        (s) => s.dateKey == dateKey,
        orElse: () => StepLog(id: '', steps: 0, dateKey: dateKey),
      );
      final stepsVal = stepLog.steps;

      final waterVal = trackerState.waterLogs
          .where((log) => DateFormat('yyyy-MM-dd').format(log.loggedAt.toLocal()) == dateKey)
          .fold(0, (sum, log) => sum + log.amount);

      final sleepLogForDay = trackerState.sleepLogs.firstWhere(
        (s) => s.dateKey == dateKey,
        orElse: () => SleepLog(id: '', bedtime: DateTime.now(), wakeTime: DateTime.now(), dateKey: dateKey),
      );
      final sleepDiff = sleepLogForDay.wakeTime.difference(sleepLogForDay.bedtime);
      String sleepDur = '0h 0m';
      if (sleepDiff.inMinutes > 0 && sleepLogForDay.id.isNotEmpty) {
        final hours = sleepDiff.inHours;
        final mins = sleepDiff.inMinutes % 60;
        sleepDur = '${hours}h ${mins}m';
      }

      final dayScore = calculateScore(stepsVal, waterVal, sleepDur, stepGoal: stepTarget, waterGoal: waterTarget);
      weeklyScores.add(dayScore.toDouble());
    }

    final formattedDate = DateFormat('EEEE, MMM d').format(DateTime.now());

    // Calculate dynamic height for today's water mini-bar (max 50)
    final todayWaterHeight = (trackerState.todayWaterAmount / waterTarget * 50.0).clamp(0.0, 50.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: trackerState.isLoading && trackerState.waterLogs.isEmpty && trackerState.sleepLogs.isEmpty
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
                    // Page Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Summary",
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$formattedDate • Focus: Recovery',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const StatusBadge(
                          text: 'OPTIMIZED',
                          dotColor: AppColors.primary,
                          backgroundColor: Color(0xFFFCFDF2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Daily Score Chart Card
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'DAILY SCORE',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              Text(
                                '$score%',
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Custom Line Chart
                          SizedBox(
                            height: 150,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: _LineChartPainter(weeklyScores),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // X Axis Labels
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: weeklyLabels.map((lbl) => Text(
                              lbl,
                              style: const TextStyle(fontSize: 12, color: AppColors.neutral, fontWeight: FontWeight.bold),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),                    // Macros Card
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/tracker/nutrition');
                      },
                      child: CustomCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'MACROS',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    LogMealSheet.show(context);
                                  },
                                  child: Text(
                                    '+ LOG MEAL',
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              textBaseline: TextBaseline.alphabetic,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              children: [
                                Text(
                                  '${mealState.todayCalories}',
                                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 38,
                                      ),
                                ),
                                Text(
                                  ' / ${userProfile?.dailyCalorieGoal ?? 2000} kcal',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontSize: 14,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildMacroRow(
                              context: context,
                              label: 'PROTEIN',
                              current: mealState.todayProtein.toDouble(),
                              target: (userProfile?.dailyProteinGoalG ?? 100).toDouble(),
                              color: AppColors.secondary,
                            ),
                            const SizedBox(height: 16),
                            _buildMacroRow(
                              context: context,
                              label: 'CARBS',
                              current: mealState.todayCarbs.toDouble(),
                              target: (userProfile?.dailyCarbGoalG ?? 250).toDouble(),
                              color: AppColors.secondary,
                            ),
                            const SizedBox(height: 16),
                            _buildMacroRow(
                              context: context,
                              label: 'FAT',
                              current: mealState.todayFat.toDouble(),
                              target: (userProfile?.dailyFatGoalG ?? 65).toDouble(),
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Grid of 4 Items (Steps, Sleep, Hydration, Glucose)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.9,
                      children: [
                        // Steps Card
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.push('/tracker/steps');
                          },
                          child: CustomCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('STEPS', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10)),
                                Center(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 70,
                                        height: 70,
                                        child: CircularProgressIndicator(
                                          value: (trackerState.todaySteps / stepTarget.toDouble()).clamp(0.0, 1.0),
                                          strokeWidth: 8,
                                          backgroundColor: Colors.grey.shade100,
                                          color: AppColors.primary,
                                          strokeCap: StrokeCap.round,
                                        ),
                                      ),
                                      const Icon(PhosphorIconsFill.footprints, color: AppColors.secondary, size: 20),
                                    ],
                                  ),
                                ),
                                Center(
                                  child: Text(
                                    NumberFormat('#,###').format(trackerState.todaySteps),
                                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Sleep Card
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.push('/tracker/sleep');
                          },
                          child: CustomCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('SLEEP', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10)),
                                Center(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 70,
                                        height: 70,
                                        child: CircularProgressIndicator(
                                          value: sleepRatio,
                                          strokeWidth: 8,
                                          backgroundColor: Colors.grey.shade100,
                                          color: AppColors.secondary,
                                          strokeCap: StrokeCap.round,
                                        ),
                                      ),
                                      const Icon(PhosphorIconsFill.moon, color: AppColors.secondary, size: 20),
                                    ],
                                  ),
                                ),
                                Center(
                                  child: Text(
                                    sleepDuration,
                                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Hydration Card
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.push('/tracker/water');
                          },
                          child: CustomCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('HYDRATION', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _buildMiniBar(height: 50, color: AppColors.secondary),
                                    _buildMiniBar(height: 50, color: AppColors.secondary),
                                    _buildMiniBar(height: 50, color: AppColors.secondary),
                                    _buildMiniBar(height: 50, color: AppColors.secondary),
                                    _buildMiniBar(height: todayWaterHeight > 0 ? todayWaterHeight : 10, color: AppColors.primary),
                                    _buildMiniBar(height: 10, color: Colors.grey.shade200),
                                  ],
                                ),
                                Center(
                                  child: RichText(
                                    text: TextSpan(
                                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 22,
                                          ),
                                      children: [
                                        TextSpan(text: '${(trackerState.todayWaterAmount / 1000.0).toStringAsFixed(1)} '),
                                        TextSpan(
                                          text: 'Liters',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Glucose Card
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.push('/tracker/glucose');
                          },
                          child: CustomCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('GLUCOSE', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10)),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      textBaseline: TextBaseline.alphabetic,
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      children: [
                                        Text(
                                          '${trackerState.lastGlucose?.level ?? 95}',
                                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 24,
                                              ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'mg/dL',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontSize: 10,
                                              ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      trackerState.lastGlucose != null
                                          ? 'Last: ${_timeAgo(trackerState.lastGlucose!.loggedAt)} ago'
                                          : 'No reading',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10),
                                    ),
                                  ],
                                ),
                                PrimaryButton(
                                  text: 'LOG READING',
                                  height: 36,
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    context.push('/tracker/glucose');
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          LogMealSheet.show(context);
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(PhosphorIconsRegular.plus, color: AppColors.secondary, size: 18),
        label: const Text(
          'LOG MEAL',
          style: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMacroRow({
    required BuildContext context,
    required String label,
    required double current,
    required double target,
    required Color color,
  }) {
    final double percent = (current / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 11,
                    color: AppColors.textPrimary,
                  ),
            ),
            Text(
              '${current.toInt()}G / ${target.toInt()}G',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: Colors.grey.shade100,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBar({required double height, required Color color}) {
    return Container(
      width: 10,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> scores;

  _LineChartPainter(this.scores);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill;

    final List<double> data = scores.length == 7 ? scores : [60.0, 60.0, 60.0, 60.0, 60.0, 60.0, 60.0];

    final List<Offset> points = [];
    final double stepX = size.width / 6.0;

    for (int i = 0; i < 7; i++) {
      // Score ranges 0 to 100. Lower y means higher value on canvas:
      // normalizedScore goes 0.0 to 1.0. Y goes from size.height * 0.9 (score 0) to size.height * 0.1 (score 100).
      final double normalizedScore = (data[i] / 100.0).clamp(0.0, 1.0);
      final double y = size.height * (0.9 - normalizedScore * 0.8);
      final double x = i * stepX;
      points.add(Offset(x, y));
    }

    final Path path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final double xc = (points[i].dx + points[i + 1].dx) / 2;
      final double yc = (points[i].dy + points[i + 1].dy) / 2;
      path.quadraticBezierTo(points[i].dx, points[i].dy, xc, yc);
    }
    path.lineTo(points.last.dx, points.last.dy);

    final Path fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    fillPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.primary.withValues(alpha: 0.3),
        AppColors.primary.withValues(alpha: 0.0),
      ],
    ).createShader(rect);

    final Paint gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const int gridRows = 3;
    for (int i = 1; i <= gridRows; i++) {
      final double y = size.height * (i / (gridRows + 1));
      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(Offset(startX, y), Offset(startX + 5, y), gridPaint);
        startX += 10;
      }
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final Paint dotPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;

    final Paint dotOutlinePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final Offset point in points) {
      canvas.drawCircle(point, 5, dotPaint);
      canvas.drawCircle(point, 5, dotOutlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    if (oldDelegate.scores.length != scores.length) return true;
    for (int i = 0; i < scores.length; i++) {
      if (oldDelegate.scores[i] != scores[i]) return true;
    }
    return false;
  }
}
