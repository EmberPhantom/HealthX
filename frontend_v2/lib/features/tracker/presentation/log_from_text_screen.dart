import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../services/meal_service.dart';

class LogFromTextScreen extends StatefulWidget {
  final String? initialMeal;
  const LogFromTextScreen({super.key, this.initialMeal});

  @override
  State<LogFromTextScreen> createState() => _LogFromTextScreenState();
}

class _LogFromTextScreenState extends State<LogFromTextScreen> {
  final _controller = TextEditingController();
  final _mealService = MealService();
  bool _isLoading = false;
  String _selectedMeal = 'Breakfast';

  @override
  void initState() {
    super.initState();
    if (widget.initialMeal != null) {
      final canonicalMeal = widget.initialMeal!.toLowerCase();
      if (canonicalMeal == 'breakfast') _selectedMeal = 'Breakfast';
      if (canonicalMeal == 'lunch') _selectedMeal = 'Lunch';
      if (canonicalMeal == 'dinner') _selectedMeal = 'Dinner';
      if (canonicalMeal == 'snack' || canonicalMeal == 'other') _selectedMeal = 'Snack';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final result = await _mealService.identifyMeal(text: text);
      
      if (mounted) {
        setState(() => _isLoading = false);
        // Push to Correct Ingredients screen, passing parsed result
        context.push('/tracker/correct-ingredients', extra: {
          'meal': _selectedMeal,
          'mealDescription': text,
          'isTextBased': true,
          'nutritionData': result,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to analyze meal text: $e'),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI Log From Text',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Meal Type Selector Card
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SELECT MEAL TYPE',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedMeal,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(PhosphorIconsRegular.clock, color: AppColors.textSecondary),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Breakfast', child: Text('Breakfast')),
                      DropdownMenuItem(value: 'Lunch', child: Text('Lunch')),
                      DropdownMenuItem(value: 'Dinner', child: Text('Dinner')),
                      DropdownMenuItem(value: 'Snack', child: Text('Snack / Other')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedMeal = val);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Text Area Input Card
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DESCRIBE YOUR MEAL',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'e.g., "I had 2 boiled eggs, a cup of steel-cut oatmeal with sliced bananas, and a cup of black coffee."',
                        hintStyle: TextStyle(color: AppColors.neutral, fontSize: 13),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tips Card
            CustomCard(
              backgroundColor: AppColors.primary.withValues(alpha: 0.05),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(PhosphorIconsRegular.lightbulb, color: AppColors.glucoseAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Logging Tip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
                        SizedBox(height: 4),
                        Text(
                          'Try to specify quantities (e.g. 2 eggs, 1 cup, 100 grams) so Gemini can calculate highly accurate macro values.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            PrimaryButton(
              text: 'ANALYZE MEAL',
              isLoading: _isLoading,
              onPressed: _controller.text.trim().isEmpty ? null : _submitText,
            ),
          ],
        ),
      ),
    );
  }
}
