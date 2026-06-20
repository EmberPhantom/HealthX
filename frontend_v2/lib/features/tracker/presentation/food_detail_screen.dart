import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/meal_provider.dart';

class FoodDetailScreen extends ConsumerStatefulWidget {
  final String meal;
  final String? imagePath;
  final bool isTextBased;
  final Map<String, dynamic> nutritionData;

  const FoodDetailScreen({
    super.key,
    required this.meal,
    this.imagePath,
    this.isTextBased = false,
    required this.nutritionData,
  });

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late String _name;
  late int _protein;
  late int _fat;
  late int _carbs;
  late int _calories;
  late List<String> _ingredients;
  late List<_HP> _healthPoints;
  late List<String> _vitamins;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));

    _name = widget.nutritionData['foodName'] ?? widget.nutritionData['name'] ?? 'Identified Food';
    _protein = (widget.nutritionData['protein'] as num?)?.toInt() ?? 0;
    _fat = (widget.nutritionData['fat'] as num?)?.toInt() ?? 0;
    _carbs = (widget.nutritionData['carbs'] as num?)?.toInt() ?? 0;
    _calories = (widget.nutritionData['calories'] as num?)?.toInt() ?? 0;

    _ingredients = (widget.nutritionData['ingredients'] as List?)?.map((e) => e.toString()).toList() ?? [];
    
    final points = widget.nutritionData['healthPoints'] as List?;
    if (points != null) {
      _healthPoints = points.map((p) => _HP(p['text'] ?? '', p['ok'] ?? true)).toList();
    } else {
      _healthPoints = [];
    }

    _vitamins = (widget.nutritionData['vitamins'] as List?)?.map((e) => e.toString()).toList() ?? [];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logFood() async {
    HapticFeedback.mediumImpact();
    final warning = await ref.read(mealProvider.notifier).addMealLog(
          _name,
          widget.meal,
          _calories,
          _protein,
          _carbs,
          _fat,
          ingredients: _ingredients,
        );

    if (!mounted) return;

    final hasError = ref.read(mealProvider).error != null;
    if (!hasError) {
      if (warning != null && warning.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_outlined, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(warning, style: const TextStyle(fontSize: 13, color: Colors.white))),
              ],
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.meal} logged successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Pop back to the tracker/nutrition screen
      // We popped some screens during correct ingredients / counting calories,
      // so let's pop until we are back to nutrition tracker screen.
      // Wait, we can navigate directly back to /tracker/nutrition or pop.
      // GoRouter allows us to go back or pop.
      // Let's use context.go('/tracker/nutrition') to make it extremely clean and robust!
      context.go('/home'); // Or we can use context.pushReplacement or context.go.
      // Wait, since nutrition is inside tracker home/sub-screens, context.go('/home') or pop is clean.
      // Let's use Navigator.popUntil to go back to the top of GoRouter navigation state or context.pop() multiple times.
      // Wait, context.go('/home') will reset the stack to home, which is clean, or we can use pop until we get back to nutrition tracker.
      // Let's check how other screens do it: they just call Navigator.pop or context.pop.
      // In V1, it popped twice. Let's do context.pop() twice or navigate.
      // Actually, since GoRouter is used, the cleanest is context.go('/home') or pop back.
      // Let's do a try-catch for pop or context.go.
      try {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (_) {
        context.go('/home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to log meal. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = !widget.isTextBased && widget.imagePath != null && widget.imagePath!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image and Navigation Actions Header
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.3,
                child: hasImage
                    ? Image.file(
                        File(widget.imagePath!),
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        child: const Center(
                          child: Icon(PhosphorIconsRegular.bowlFood, size: 60, color: AppColors.stepsAccent),
                        ),
                      ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black38,
                  child: IconButton(
                    icon: const Icon(PhosphorIconsRegular.arrowLeft, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.meal.toUpperCase(),
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

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '$_calories kcal',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.stepsAccent,
                  ),
                ),
              ],
            ),
          ),

          // Macros display row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                _buildMacroPill('Protein', '$_protein g', AppColors.stepsAccent),
                const SizedBox(width: 8),
                _buildMacroPill('Carbs', '$_carbs g', AppColors.glucoseAccent),
                const SizedBox(width: 8),
                _buildMacroPill('Fat', '$_fat g', AppColors.vitalsAccent),
              ],
            ),
          ),

          // Custom Tab Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'Nutrition'),
                  Tab(text: 'Ingredients'),
                ],
              ),
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Nutrition & Remarks
                _buildNutritionTab(),
                // Tab 2: Ingredients list
                _buildIngredientsTab(),
              ],
            ),
          ),

          // Action Button
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            child: PrimaryButton(
              text: 'LOG MEAL',
              onPressed: _logFood,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionTab() {
    final healthScore = (widget.nutritionData['healthScore'] as num?)?.toInt() ?? 8;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(PhosphorIconsRegular.heartBreak, color: AppColors.vitalsAccent, size: 20),
                        SizedBox(width: 8),
                        Text('Health Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    Text('$healthScore / 10', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                // Score bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: healthScore / 10.0,
                    minHeight: 8,
                    backgroundColor: AppColors.border,
                    color: healthScore >= 7 ? AppColors.success : AppColors.warning,
                  ),
                ),
                const SizedBox(height: 16),
                if (_healthPoints.isNotEmpty)
                  ..._healthPoints.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              p.ok ? PhosphorIconsRegular.checkCircle : PhosphorIconsRegular.warningCircle,
                              color: p.ok ? AppColors.success : AppColors.error,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                p.text,
                                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ))
                else
                  const Text('No health remarks available for this meal.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Vitamins & Minerals
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(PhosphorIconsRegular.flask, color: AppColors.stepsAccent, size: 20),
                    SizedBox(width: 8),
                    Text('Vitamins & Minerals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const Divider(height: 24),
                if (_vitamins.isEmpty)
                  const Text('No vitamins listed.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
                else
                  ..._vitamins.map((v) => _buildVitaminsRow(v)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitaminsRow(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Unlock', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.stepsAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingredients Used', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Divider(height: 24),
            if (_ingredients.isEmpty)
              const Text('No ingredients specified.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
            else
              ...List.generate(_ingredients.length, (index) {
                final item = _ingredients[index];
                final parts = item.split(' - ');
                final name = parts[0];
                final qty = parts.length > 1 ? parts[1] : '1 serving';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(name, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                      ),
                      Text(qty, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _HP {
  final String text;
  final bool ok;
  const _HP(this.text, this.ok);
}
