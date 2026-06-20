import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/tracker_provider.dart';

class SetGoalScreen extends ConsumerStatefulWidget {
  const SetGoalScreen({super.key});

  @override
  ConsumerState<SetGoalScreen> createState() => _SetGoalScreenState();
}

class _SetGoalScreenState extends ConsumerState<SetGoalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Slider/Goal State values
  int _stepGoal = 8000;
  int _waterGoal = 2000;
  int _calorieGoal = 2000;
  int _proteinGoal = 120;
  int _carbGoal = 200;
  int _fatGoal = 70;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => _loadInitialGoals());
  }

  void _loadInitialGoals() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      setState(() {
        _stepGoal = user.dailyStepGoal;
        _waterGoal = user.dailyWaterGoalMl;
        _calorieGoal = user.dailyCalorieGoal;
        _proteinGoal = user.dailyProteinGoalG;
        _carbGoal = user.dailyCarbGoalG;
        _fatGoal = user.dailyFatGoalG;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveGoals() async {
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final success = await ref.read(authProvider.notifier).updateUserSettings(
          dailyWaterGoalMl: _waterGoal,
          dailyStepGoal: _stepGoal,
          dailyCalorieGoal: _calorieGoal,
          dailyProteinGoalG: _proteinGoal,
          dailyCarbGoalG: _carbGoal,
          dailyFatGoalG: _fatGoal,
        );

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Daily goals saved successfully!' : 'Failed to save daily goals'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      if (success) {
        Navigator.pop(context);
      }
    }
  }

  Color _getStepIntensityColor(int steps) {
    if (steps >= 12000) return AppColors.stepsAccent;
    if (steps >= 10000) return AppColors.success;
    if (steps >= 8000) return AppColors.sleepAccent;
    if (steps >= 6000) return AppColors.warning;
    return AppColors.neutral;
  }

  @override
  Widget build(BuildContext context) {
    final trackerState = ref.watch(trackerProvider);
    
    // Compute monthly steps
    final now = DateTime.now();
    final monthName = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][now.month - 1];

    final Map<int, int> monthlySteps = {};
    int monthTotal = 0;
    for (var log in trackerState.stepLogs) {
      try {
        final date = DateFormat('yyyy-MM-dd').parse(log.dateKey);
        if (date.month == now.month && date.year == now.year) {
          monthlySteps[date.day] = log.steps;
          monthTotal += log.steps;
        }
      } catch (_) {}
    }

    final monthAvg = monthlySteps.isEmpty ? 0 : monthTotal ~/ monthlySteps.length;
    
    int bestDay = 0;
    int bestSteps = 0;
    monthlySteps.forEach((day, steps) {
      if (steps > bestSteps) {
        bestSteps = steps;
        bestDay = day;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.secondary, size: 22),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Daily Goal Settings',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
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
                  Tab(text: 'Configure Goals'),
                  Tab(text: 'Monthly Calendar'),
                ],
              ),
              const Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: CONFIGURE GOALS
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Steps Card
                _buildGoalSliderCard(
                  title: 'DAILY STEPS GOAL',
                  value: _stepGoal,
                  unit: 'steps',
                  min: 2000,
                  max: 20000,
                  step: 1000,
                  icon: PhosphorIconsFill.footprints,
                  accentColor: AppColors.stepsAccent,
                  recommendation: 'Recommended: 10,000 steps',
                  onChanged: (val) => setState(() => _stepGoal = val),
                ),
                const SizedBox(height: 16),

                // Water Card
                _buildGoalSliderCard(
                  title: 'DAILY HYDRATION GOAL',
                  value: _waterGoal,
                  unit: 'mL',
                  min: 1000,
                  max: 5000,
                  step: 250,
                  icon: PhosphorIconsFill.drop,
                  accentColor: AppColors.waterAccent,
                  recommendation: 'Recommended: 2,500 mL',
                  onChanged: (val) => setState(() => _waterGoal = val),
                ),
                const SizedBox(height: 16),

                // Calories Card
                _buildGoalSliderCard(
                  title: 'DAILY CALORIE GOAL',
                  value: _calorieGoal,
                  unit: 'kcal',
                  min: 1000,
                  max: 5000,
                  step: 100,
                  icon: PhosphorIconsFill.fire,
                  accentColor: AppColors.glucoseAccent,
                  recommendation: 'Recommended: 2,000 kcal',
                  onChanged: (val) => setState(() => _calorieGoal = val),
                ),
                const SizedBox(height: 16),

                // Nutrition Split Card
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(PhosphorIconsFill.chartPie, color: AppColors.vitalsAccent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'MACRONUTRIENT TARGETS',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildMacroRow('Protein', _proteinGoal, 'g', 30, 250, (val) => setState(() => _proteinGoal = val), AppColors.vitalsAccent),
                      const SizedBox(height: 16),
                      _buildMacroRow('Carbs', _carbGoal, 'g', 50, 500, (val) => setState(() => _carbGoal = val), AppColors.glucoseAccent),
                      const SizedBox(height: 16),
                      _buildMacroRow('Fat', _fatGoal, 'g', 20, 150, (val) => setState(() => _fatGoal = val), AppColors.stepsAccent),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                PrimaryButton(
                  text: 'SAVE DAILY TARGETS',
                  isLoading: _isSaving,
                  onPressed: _saveGoals,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // TAB 2: MONTHLY CALENDAR
          trackerState.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$monthName ${now.year} Activity Grid',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.secondary),
                                ),
                                Text(
                                  'Total: ${NumberFormat('#,###').format(monthTotal)} steps',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.neutral),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildCalendarGrid(monthlySteps, now, context),
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildCalendarStat('Month Avg', NumberFormat('#,###').format(monthAvg), 'Steps/Day'),
                                _buildCalendarStat('Month Total', NumberFormat('#,###').format(monthTotal), 'Steps'),
                                _buildCalendarStat('Best Day', bestDay > 0 ? 'Day $bestDay' : '—', bestDay > 0 ? NumberFormat('#,###').format(bestSteps) : '0'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildGoalSliderCard({
    required String title,
    required int value,
    required String unit,
    required double min,
    required double max,
    required double step,
    required IconData icon,
    required Color accentColor,
    required String recommendation,
    required ValueChanged<int> onChanged,
  }) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: accentColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10, letterSpacing: 0.5),
                  ),
                ],
              ),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 18),
                  children: [
                    TextSpan(text: NumberFormat('#,###').format(value)),
                    TextSpan(text: ' $unit', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: AppColors.neutral)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              activeTrackColor: accentColor,
              inactiveTrackColor: AppColors.border,
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: value.toDouble(),
              min: min,
              max: max,
              divisions: ((max - min) / step).round(),
              onChanged: (val) => onChanged(val.round()),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(NumberFormat('#,###').format(min), style: const TextStyle(fontSize: 10, color: AppColors.neutral)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(recommendation, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.neutral)),
              ),
              Text(NumberFormat('#,###').format(max), style: const TextStyle(fontSize: 10, color: AppColors.neutral)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow(String label, int value, String unit, double min, double max, ValueChanged<int> onChanged, Color barColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text('$value $unit', style: TextStyle(fontWeight: FontWeight.w900, color: barColor, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: barColor,
            inactiveTrackColor: AppColors.border,
            thumbColor: barColor,
            overlayColor: barColor.withValues(alpha: 0.12),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value.toDouble(),
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: (val) => onChanged(val.round()),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(Map<int, int> monthlySteps, DateTime now, BuildContext context) {
    final double gridWidth = MediaQuery.of(context).size.width - 64; // Accounts for paddings
    final double cellSize = (gridWidth / 7) - 4; // 7 columns
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final leadingBlanks = DateTime(now.year, now.month, 1).weekday - 1;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        // Blanks for calendar weekday offset alignment
        ...List.generate(leadingBlanks, (_) => SizedBox(width: cellSize, height: cellSize)),

        // Render days
        ...List.generate(daysInMonth, (i) {
          final day = i + 1;
          final steps = monthlySteps[day];
          final hasData = steps != null && steps > 0;
          final isToday = day == now.day;
          final intensity = hasData ? (steps / 15000).clamp(0.0, 1.0) : 0.0;

          return Container(
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
              color: hasData
                  ? _getStepIntensityColor(steps).withValues(alpha: 0.2 + intensity * 0.8)
                  : Colors.transparent,
              border: Border.all(
                color: isToday
                    ? Colors.orange
                    : hasData
                        ? _getStepIntensityColor(steps)
                        : AppColors.border.withValues(alpha: 0.5),
                width: isToday ? 2.0 : 0.8,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: hasData && intensity > 0.4 ? Colors.white : AppColors.secondary,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCalendarStat(String label, String value, String unit) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.neutral, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.secondary)),
        const SizedBox(height: 1),
        Text(unit, style: const TextStyle(fontSize: 9, color: AppColors.neutral)),
      ],
    );
  }
}
