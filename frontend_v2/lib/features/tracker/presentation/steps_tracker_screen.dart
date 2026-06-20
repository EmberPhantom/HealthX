import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/tracker_provider.dart';
import '../../../core/services/step_counter_service.dart';
import '../../../core/models/tracker_models.dart';

class StepsTrackerScreen extends ConsumerStatefulWidget {
  const StepsTrackerScreen({super.key});

  @override
  ConsumerState<StepsTrackerScreen> createState() => _StepsTrackerScreenState();
}

class _StepsTrackerScreenState extends ConsumerState<StepsTrackerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _stepGoal = 8000;
  bool _isLoadingGoal = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _stepGoal = prefs.getInt('step_goal') ?? 8000;
        _isLoadingGoal = false;
      });
    } catch (_) {
      setState(() => _isLoadingGoal = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackerState = ref.watch(trackerProvider);
    final todaySteps = trackerState.todaySteps;
    final progress = (todaySteps / _stepGoal).clamp(0.0, 1.0);
    final calories = StepCounterService.stepsToCalories(todaySteps);
    final distance = (todaySteps * 0.00075).toStringAsFixed(2);
    final activeMinutes = (todaySteps * 0.008).round();

    // Calculate Best Day from logs
    int maxSteps = todaySteps;
    String maxDayStr = 'Today';
    for (var log in trackerState.stepLogs) {
      if (log.steps > maxSteps) {
        maxSteps = log.steps;
        try {
          final date = DateFormat('yyyy-MM-dd').parse(log.dateKey);
          maxDayStr = DateFormat('MMM d').format(date);
        } catch (_) {
          maxDayStr = log.dateKey;
        }
      }
    }

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
          'Steps Tracker',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49.0),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.secondary,
                unselectedLabelColor: AppColors.neutral,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                tabs: const [
                  Tab(text: 'Today'),
                  Tab(text: 'Weekly'),
                  Tab(text: 'Monthly'),
                ],
              ),
              const Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
            ],
          ),
        ),
      ),
      body: trackerState.isLoading || _isLoadingGoal
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                // 1. TODAY TAB
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CustomCard(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 200,
                                    height: 200,
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 16,
                                      backgroundColor: Colors.grey.shade100,
                                      color: AppColors.stepsAccent,
                                      strokeCap: StrokeCap.round,
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(PhosphorIconsFill.footprints, color: AppColors.stepsAccent, size: 20),
                                      const SizedBox(height: 8),
                                      Text(
                                        NumberFormat('#,###').format(todaySteps),
                                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                              fontSize: 38,
                                              fontWeight: FontWeight.w900,
                                              height: 1.1,
                                            ),
                                      ),
                                      Text(
                                        'Goal: ${NumberFormat('#,###').format(_stepGoal)}',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildMetricItem(
                                  context: context,
                                  icon: PhosphorIconsFill.fire,
                                  value: '$calories',
                                  unit: 'kcal',
                                  label: 'Burned',
                                  color: Colors.orange,
                                ),
                                _buildDivider(),
                                _buildMetricItem(
                                  context: context,
                                  icon: PhosphorIconsFill.mapPinArea,
                                  value: distance,
                                  unit: 'km',
                                  label: 'Distance',
                                  color: Colors.blue,
                                ),
                                _buildDivider(),
                                _buildMetricItem(
                                  context: context,
                                  icon: PhosphorIconsFill.clock,
                                  value: '$activeMinutes',
                                  unit: 'mins',
                                  label: 'Active',
                                  color: AppColors.stepsAccent,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        text: 'SET DAILY GOAL',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          context.push('/tracker/goals');
                        },
                      ),
                      const SizedBox(height: 20),
                      CustomCard(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.stepsAccent.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(PhosphorIconsFill.trophy, color: AppColors.stepsAccent, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PERSONAL BEST',
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${NumberFormat('#,###').format(maxSteps)} Steps',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  Text(
                                    'Achieved on $maxDayStr',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. WEEKLY TAB
                _buildWeeklyView(trackerState.stepLogs),

                // 3. MONTHLY TAB
                _buildMonthlyView(trackerState.stepLogs),
              ],
            ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.border,
    );
  }

  Widget _buildMetricItem({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String unit,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
            children: [
              TextSpan(text: value),
              TextSpan(
                text: ' $unit',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: AppColors.neutral),
              ),
            ],
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildWeeklyView(List<StepLog> logs) {
    // Take past 7 logs or populate empty ones
    final List<StepLog> displayLogs = List.from(logs);
    if (displayLogs.isEmpty) {
      final now = DateTime.now();
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        displayLogs.add(StepLog(id: '', steps: 0, dateKey: DateFormat('yyyy-MM-dd').format(date)));
      }
    } else {
      // Sort chronologically
      displayLogs.sort((a, b) => a.dateKey.compareTo(b.dateKey));
      if (displayLogs.length > 7) {
        displayLogs.removeRange(0, displayLogs.length - 7);
      }
    }

    final double maxVal = displayLogs.fold<double>(
      _stepGoal.toDouble(),
      (prev, log) => log.steps > prev ? log.steps.toDouble() : prev,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '7-DAY ACTIVITY TREND',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxVal * 1.15,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.secondary,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final dateKey = displayLogs[group.x.toInt()].dateKey;
                            String formattedDate = dateKey;
                            try {
                              formattedDate = DateFormat('E, MMM d').format(DateFormat('yyyy-MM-dd').parse(dateKey));
                            } catch (_) {}
                            return BarTooltipItem(
                              '$formattedDate\n',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                              children: [
                                TextSpan(
                                  text: '${NumberFormat('#,###').format(rod.toY.toInt())} steps',
                                  style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final int index = value.toInt();
                              if (index < 0 || index >= displayLogs.length) return const SizedBox();
                              final dateKey = displayLogs[index].dateKey;
                              String dayName = '';
                              try {
                                dayName = DateFormat('E').format(DateFormat('yyyy-MM-dd').parse(dateKey))[0];
                              } catch (_) {}
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 8,
                                child: Text(dayName, style: const TextStyle(color: AppColors.neutral, fontWeight: FontWeight.bold, fontSize: 12)),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(displayLogs.length, (index) {
                        final log = displayLogs[index];
                        final isToday = log.dateKey == DateFormat('yyyy-MM-dd').format(DateTime.now());
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: log.steps.toDouble(),
                              color: isToday ? AppColors.primary : AppColors.secondary,
                              width: 14,
                              borderRadius: BorderRadius.circular(4),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxVal * 1.1,
                                color: Colors.grey.shade100,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Weekly History',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(displayLogs.length, (index) {
              final log = displayLogs[displayLogs.length - 1 - index];
              String formattedDate = log.dateKey;
              try {
                formattedDate = DateFormat('EEEE, MMM d').format(DateFormat('yyyy-MM-dd').parse(log.dateKey));
              } catch (_) {}
              final pct = (log.steps / _stepGoal * 100).round();

              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: CustomCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            '${NumberFormat('#,###').format(log.steps)} steps (${pct}% of goal)',
                            style: const TextStyle(color: AppColors.neutral, fontSize: 12),
                          ),
                        ],
                      ),
                      StatusBadge(
                        text: log.steps >= _stepGoal ? 'COMPLETED' : 'INCOMPLETE',
                        dotColor: log.steps >= _stepGoal ? AppColors.stepsAccent : Colors.orange,
                        backgroundColor: log.steps >= _stepGoal ? const Color(0xFFE6FDF4) : const Color(0xFFFFF7ED),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyView(List<StepLog> logs) {
    // Past 30 days
    final List<StepLog> displayLogs = List.from(logs);
    displayLogs.sort((a, b) => a.dateKey.compareTo(b.dateKey));

    if (displayLogs.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('No steps logged in the past month.', style: TextStyle(color: AppColors.neutral))));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '30-DAY STEPS LOGS',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppColors.secondary,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final log = displayLogs[spot.x.toInt()];
                              return LineTooltipItem(
                                '${log.dateKey}\n${NumberFormat('#,###').format(spot.y.toInt())} steps',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(displayLogs.length, (index) {
                            return FlSpot(index.toDouble(), displayLogs[index].steps.toDouble());
                          }),
                          isCurved: true,
                          color: AppColors.stepsAccent,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.stepsAccent.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'All Logs',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(displayLogs.length, (index) {
              final log = displayLogs[displayLogs.length - 1 - index];
              String formattedDate = log.dateKey;
              try {
                formattedDate = DateFormat('MMM d, yyyy').format(DateFormat('yyyy-MM-dd').parse(log.dateKey));
              } catch (_) {}
              final pct = (log.steps / _stepGoal * 100).round();

              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: CustomCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            '${NumberFormat('#,###').format(log.steps)} steps (${pct}% of goal)',
                            style: const TextStyle(color: AppColors.neutral, fontSize: 12),
                          ),
                        ],
                      ),
                      StatusBadge(
                        text: log.steps >= _stepGoal ? 'COMPLETED' : 'INCOMPLETE',
                        dotColor: log.steps >= _stepGoal ? AppColors.stepsAccent : Colors.orange,
                        backgroundColor: log.steps >= _stepGoal ? const Color(0xFFE6FDF4) : const Color(0xFFFFF7ED),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
