import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';

class WellnessGoalItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const WellnessGoalItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });
}

const List<WellnessGoalItem> _availableGoals = [
  WellnessGoalItem(
    title: 'Lose Weight',
    subtitle: 'Burn fat and improve metabolism',
    icon: PhosphorIconsRegular.trendDown,
    accentColor: AppColors.stepsAccent,
  ),
  WellnessGoalItem(
    title: 'Build Muscle',
    subtitle: 'Increase strength and lean mass',
    icon: PhosphorIconsRegular.barbell,
    accentColor: AppColors.vitalsAccent,
  ),
  WellnessGoalItem(
    title: 'Eat Healthier',
    subtitle: 'Optimize macro & micronutrient intake',
    icon: PhosphorIconsRegular.bowlFood,
    accentColor: AppColors.glucoseAccent,
  ),
  WellnessGoalItem(
    title: 'Improve Sleep',
    subtitle: 'Restore sleep cycles and deep sleep',
    icon: PhosphorIconsRegular.moon,
    accentColor: AppColors.sleepAccent,
  ),
  WellnessGoalItem(
    title: 'Reduce Stress',
    subtitle: 'Calm the mind and lower cortisol',
    icon: PhosphorIconsRegular.brain,
    accentColor: AppColors.waterAccent,
  ),
  WellnessGoalItem(
    title: 'Increase Fertility',
    subtitle: 'Support reproductive wellness',
    icon: PhosphorIconsRegular.flower,
    accentColor: AppColors.vitalsAccent,
  ),
  WellnessGoalItem(
    title: 'Strengthen Joints',
    subtitle: 'Support bones, tendons, and cartilage',
    icon: PhosphorIconsRegular.bone,
    accentColor: AppColors.neutral,
  ),
  WellnessGoalItem(
    title: 'Manage Fatty Liver',
    subtitle: 'Reduce liver fat and improve enzymes',
    icon: PhosphorIconsRegular.heartbeat,
    accentColor: AppColors.vitalsAccent,
  ),
  WellnessGoalItem(
    title: 'Ease Constipation',
    subtitle: 'Improve digestion and gut motility',
    icon: PhosphorIconsRegular.drop,
    accentColor: AppColors.waterAccent,
  ),
  WellnessGoalItem(
    title: 'Yoga & Pranayama',
    subtitle: 'Enrich mind-body breathing exercises',
    icon: PhosphorIconsRegular.activity,
    accentColor: AppColors.stepsAccent,
  ),
  WellnessGoalItem(
    title: 'Manage Cholesterol',
    subtitle: 'Balance lipid profile and heart health',
    icon: PhosphorIconsRegular.chartLineDown,
    accentColor: AppColors.sleepAccent,
  ),
  WellnessGoalItem(
    title: 'Manage Diabetes',
    subtitle: 'Stabilize blood sugar and HbA1c',
    icon: PhosphorIconsRegular.firstAid,
    accentColor: AppColors.glucoseAccent,
  ),
  WellnessGoalItem(
    title: 'Increase Energy',
    subtitle: 'Overcome fatigue and stay active',
    icon: PhosphorIconsRegular.lightning,
    accentColor: AppColors.rewardsAccent,
  ),
  WellnessGoalItem(
    title: 'Relieve Gastric Discomfort',
    subtitle: 'Reduce bloating, acidity, and gas',
    icon: PhosphorIconsRegular.shield,
    accentColor: AppColors.stepsAccent,
  ),
];

class WellnessGoalsScreen extends ConsumerStatefulWidget {
  const WellnessGoalsScreen({super.key});

  @override
  ConsumerState<WellnessGoalsScreen> createState() => _WellnessGoalsScreenState();
}

class _WellnessGoalsScreenState extends ConsumerState<WellnessGoalsScreen> {
  final List<String> _selectedGoals = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = ref.read(authProvider).user;
      if (user != null) {
        setState(() {
          _selectedGoals.addAll(user.wellnessGoals);
        });
      }
    });
  }

  void _toggleGoal(String title) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedGoals.contains(title)) {
        _selectedGoals.remove(title);
      } else {
        if (_selectedGoals.length < 3) {
          _selectedGoals.add(title);
        } else {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can select a maximum of 3 wellness targets.'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 1500),
            ),
          );
        }
      }
    });
  }

  Future<void> _saveGoals() async {
    if (_selectedGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 wellness target.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final success = await ref.read(authProvider.notifier).completeOnboarding(
          wellnessGoals: _selectedGoals,
        );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wellness targets updated successfully! Daily goals recalculated.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        final errorMsg = ref.read(authProvider).error ?? 'Failed to save targets';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Wellness Targets',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.border, width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: PrimaryButton(
            text: _isSaving ? 'SAVING...' : 'SAVE TARGETS (${_selectedGoals.length}/3)',
            onPressed: (_isSaving || _selectedGoals.isEmpty) ? null : _saveGoals,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIconsFill.trophy, color: AppColors.primary, size: 36),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Personalize Your Journey',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Select up to 3 goals. We will configure your calorie, macro, water, and step targets accordingly.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'SELECT TARGETS (${_selectedGoals.length}/3)',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemCount: _availableGoals.length,
              itemBuilder: (context, index) {
                final goal = _availableGoals[index];
                final isSelected = _selectedGoals.contains(goal.title);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.secondary : AppColors.border,
                      width: isSelected ? 2.0 : 0.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: InkWell(
                      onTap: () => _toggleGoal(goal.title),
                      child: Container(
                        color: isSelected
                            ? goal.accentColor.withValues(alpha: 0.08)
                            : AppColors.cardBackground,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? goal.accentColor.withValues(alpha: 0.15)
                                        : Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    goal.icon,
                                    color: isSelected ? goal.accentColor : AppColors.neutral,
                                    size: 20,
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    PhosphorIconsFill.checkCircle,
                                    color: AppColors.secondary,
                                    size: 20,
                                  ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              goal.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isSelected ? AppColors.textPrimary : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              goal.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: isSelected ? AppColors.textSecondary : AppColors.neutral,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
