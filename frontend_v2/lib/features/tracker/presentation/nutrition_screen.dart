import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/meal_provider.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  String _selectedMealType = 'Breakfast';

  Future<void> _pickImage(String mealType, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1080,
      );
      if (picked != null && mounted) {
        Navigator.pop(context); // close source sheet
        context.push('/tracker/scan', extra: {
          'imagePath': picked.path,
          'meal': mealType,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImageSourceSheet(String mealType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'SCAN MEAL INTAKE',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SourceButton(
                    icon: PhosphorIconsRegular.camera,
                    label: 'Take Photo',
                    onTap: () => _pickImage(mealType, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SourceButton(
                    icon: PhosphorIconsRegular.image,
                    label: 'Gallery',
                    onTap: () => _pickImage(mealType, ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showLogOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'LOG MEAL OPTIONS',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(PhosphorIconsRegular.pencilSimple, color: AppColors.stepsAccent),
              title: const Text('Log Manually', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Input description and macro split values'),
              onTap: () {
                Navigator.pop(context);
                context.push('/tracker/log-manual?meal=$_selectedMealType');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(PhosphorIconsRegular.microphone, color: AppColors.sleepAccent),
              title: const Text('AI Log from Text', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Type what you had (e.g. "2 boiled eggs")'),
              onTap: () {
                Navigator.pop(context);
                context.push('/tracker/log-text?meal=$_selectedMealType');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(PhosphorIconsRegular.scan, color: AppColors.glucoseAccent),
              title: const Text('AI Scanner', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Analyze meal macros using camera picture'),
              onTap: () {
                Navigator.pop(context);
                _showImageSourceSheet(_selectedMealType);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mealState = ref.watch(mealProvider);
    final user = ref.watch(authProvider).user;

    final calorieGoal = user?.dailyCalorieGoal ?? 2000;
    final proteinGoal = user?.dailyProteinGoalG ?? 120;
    final carbGoal = user?.dailyCarbGoalG ?? 200;
    final fatGoal = user?.dailyFatGoalG ?? 70;

    final curCalories = mealState.todayCalories;
    final curProtein = mealState.todayProtein;
    final curCarbs = mealState.todayCarbs;
    final curFat = mealState.todayFat;

    final totalMacros = curProtein + curCarbs + curFat;
    final caloriePercent = (curCalories / calorieGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nutrition Tracker',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: mealState.isLoading && mealState.todayMeals.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () => ref.read(mealProvider.notifier).fetchTodayMeals(),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Calorie and Macro Donut Summary Card
                    CustomCard(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DAILY CALORIES',
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 4),
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 24),
                                      children: [
                                        TextSpan(text: '$curCalories'),
                                        TextSpan(
                                          text: ' / $calorieGoal kcal',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: caloriePercent >= 1.0 ? AppColors.success.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${(caloriePercent * 100).toInt()}% MET',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: caloriePercent >= 1.0 ? AppColors.success : AppColors.stepsAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              // Radial / Donut Visualizer
                              SizedBox(
                                width: 120,
                                height: 120,
                                child: CustomPaint(
                                  painter: _NutritionDonutPainter(
                                    protein: curProtein,
                                    carbs: curCarbs,
                                    fat: curFat,
                                    totalMacros: totalMacros,
                                    calorieProgress: caloriePercent,
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${(calorieGoal - curCalories).clamp(0, calorieGoal)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
                                        ),
                                        const Text(
                                          'kcal left',
                                          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Custom Legend
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildLegendItem(
                                      label: 'Protein',
                                      current: curProtein,
                                      target: proteinGoal,
                                      color: AppColors.stepsAccent,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildLegendItem(
                                      label: 'Carbs',
                                      current: curCarbs,
                                      target: carbGoal,
                                      color: AppColors.glucoseAccent,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildLegendItem(
                                      label: 'Fat',
                                      current: curFat,
                                      target: fatGoal,
                                      color: AppColors.vitalsAccent,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Meal Logging Interactive Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today's Meals",
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        // Segmented meal selector
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.border.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((type) {
                              final isSelected = _selectedMealType == type;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedMealType = type),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.cardBackground : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    type,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Filter and list meal logs of selected type
                    _buildMealLogsList(mealState.todayMeals, _selectedMealType),

                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'LOG ${_selectedMealType.toUpperCase()}',
                      onPressed: _showLogOptionsSheet,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLegendItem({
    required String label,
    required int current,
    required int target,
    required Color color,
  }) {
    final double percent = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
            Text('$current / $target g', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 4,
            backgroundColor: AppColors.border.withValues(alpha: 0.5),
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMealLogsList(List<dynamic> meals, String type) {
    final filteredMeals = meals.where((m) => m.mealType.toLowerCase() == type.toLowerCase()).toList();

    if (filteredMeals.isEmpty) {
      return CustomCard(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          children: [
            const Icon(PhosphorIconsRegular.bowlFood, size: 40, color: AppColors.neutral),
            const SizedBox(height: 12),
            Text(
              'No $type logged yet',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Keep track of your nutrition to maintain your goals',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: filteredMeals.map((meal) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: CustomCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(PhosphorIconsRegular.bowlFood, color: AppColors.textPrimary, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.foodName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'P: ${meal.protein}g  C: ${meal.carbs}g  F: ${meal.fat}g',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${meal.calories} kcal',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () async {
                        HapticFeedback.heavyImpact();
                        final success = await ref.read(mealProvider.notifier).deleteMealLog(meal.id);
                        if (mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Meal log deleted'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: AppColors.textPrimary),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionDonutPainter extends CustomPainter {
  final int protein;
  final int carbs;
  final int fat;
  final int totalMacros;
  final double calorieProgress;

  _NutritionDonutPainter({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.totalMacros,
    required this.calorieProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.12;
    final radius = (size.width - strokeWidth) / 2;

    // Draw backing circle
    final bgPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // If totalMacros > 0, draw segmented macro distribution
    if (totalMacros > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);

      // Ratios
      final double pRatio = protein / totalMacros;
      final double cRatio = carbs / totalMacros;
      final double fRatio = fat / totalMacros;

      double startAngle = -math.pi / 2;

      // Draw Protein segment
      if (pRatio > 0) {
        final pPaint = Paint()
          ..color = AppColors.stepsAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
        final sweepAngle = pRatio * 2 * math.pi;
        canvas.drawArc(rect, startAngle, sweepAngle, false, pPaint);
        startAngle += sweepAngle;
      }

      // Draw Carbs segment
      if (cRatio > 0) {
        final cPaint = Paint()
          ..color = AppColors.glucoseAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
        final sweepAngle = cRatio * 2 * math.pi;
        canvas.drawArc(rect, startAngle, sweepAngle, false, cPaint);
        startAngle += sweepAngle;
      }

      // Draw Fat segment
      if (fRatio > 0) {
        final fPaint = Paint()
          ..color = AppColors.vitalsAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
        final sweepAngle = fRatio * 2 * math.pi;
        canvas.drawArc(rect, startAngle, sweepAngle, false, fPaint);
      }
    } else {
      // Just draw thin indicator for calories
      final rect = Rect.fromCircle(center: center, radius: radius);
      final pPaint = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -math.pi / 2, calorieProgress * 2 * math.pi, false, pPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NutritionDonutPainter oldDelegate) {
    return oldDelegate.protein != protein ||
        oldDelegate.carbs != carbs ||
        oldDelegate.fat != fat ||
        oldDelegate.calorieProgress != calorieProgress;
  }
}
