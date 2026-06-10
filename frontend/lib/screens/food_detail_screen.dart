import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../services/api/api_service.dart';
import '../providers/food_log_store.dart';

class FoodDetailScreen extends StatefulWidget {
  final File imageFile;
  final String meal;
  final bool isTextBased;
  final Map<String, dynamic> nutritionData;

  const FoodDetailScreen({
    super.key,
    required this.imageFile,
    required this.meal,
    this.isTextBased = false,
    required this.nutritionData,
  });

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen>
    with SingleTickerProviderStateMixin {
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
    final mealData = {
      'mealType': widget.meal,
      'foodName': _name,
      'protein': _protein,
      'fat': _fat,
      'carbs': _carbs,
      'calories': _calories,
      'ingredients': _ingredients,
      'loggedAt': DateTime.now().toIso8601String(),
    };

    final response = await ApiService().logMeal(mealData);

    if (!mounted) return;

    if (response.isSuccess) {
      // Also update local store if still used for immediate UI updates
      FoodLogStore.instance.addEntry(
        FoodEntry(
          meal: widget.meal,
          name: _name,
          protein: _protein,
          fat: _fat,
          carbs: _carbs,
          calories: _calories,
          imageFile: widget.isTextBased || widget.imageFile.path.isEmpty
              ? null
              : widget.imageFile,
          loggedAt: DateTime.now(),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.meal} logged successfully!',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Pop back to LogScreen
      int _count = 0;
      Navigator.of(context).popUntil((route) {
        _count++;
        return _count >= 2;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.errorMessage ?? 'Failed to log meal')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Image with back button ────────────────────────────────
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: mq.size.height * 0.34,
                child: widget.isTextBased ||
                    !widget.imageFile.existsSync() ||
                    widget.imageFile.path.isEmpty
                    ? Container(
                  color: const Color(0xFFF0F5F0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Icon(
                            Icons.restaurant_menu_rounded,
                            size: 40,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Text-based entry',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : Image.file(
                  widget.imageFile,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFE0F2F1),
                    child: const Center(
                      child: Text('🥗', style: TextStyle(fontSize: 72)),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: mq.padding.top + 12,
                left: 14,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.38),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
              // Meal type badge on the image
              Positioned(
                top: mq.padding.top + 12,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _mealColor(widget.meal),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.meal,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Title ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _name,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Custom tab bar ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _TabButton(
                    label: 'Nutrition',
                    isSelected: _tabController.index == 0,
                    onTap: () => _tabController.animateTo(0),
                  ),
                  _TabButton(
                    label: 'Ingredients',
                    isSelected: _tabController.index == 1,
                    onTap: () => _tabController.animateTo(1),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),

          // ── Tab content ───────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _NutritionTab(
                  healthScore: (widget.nutritionData['healthScore'] as num?)?.toInt() ?? 8,
                  healthPoints: _healthPoints,
                  vitamins: _vitamins,
                ),
                _IngredientsTab(
                  ingredients: _ingredients,
                ),
              ],
            ),
          ),

          // ── Log Food button ───────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
                18, 8, 18, mq.padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logFood,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Log Food',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _mealColor(String meal) {
    switch (meal) {
      case 'Breakfast':
        return const Color(0xFFFBC02D);
      case 'Lunch':
        return const Color(0xFF10B981);
      case 'Dinner':
        return const Color(0xFF1E2646);
      case 'Snack':
        return const Color(0xFFFF6B35);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

// ─── Tab Button ───────────────────────────────────────────────────────────────
class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF10B981)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Nutrition Tab ────────────────────────────────────────────────────────────
class _NutritionTab extends StatelessWidget {
  final int healthScore;
  final List<_HP> healthPoints;
  final List<String> vitamins;

  const _NutritionTab({
    required this.healthScore,
    required this.healthPoints,
    required this.vitamins,
  });

  static const _minerals = [
    'Calcium', 'Iron', 'Magnesium', 'Phosphorus',
    'Potassium', 'Sodium', 'Zinc',
  ];

  static const _additional = ['Water Content', 'Calorie Density'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      child: Column(
        children: [
          // Health Score card
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded,
                        color: Color(0xFFFF5252), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Health Score',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    Text(
                      '$healthScore/10',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (ctx, constraints) => _HealthScoreBar(
                    score: healthScore.toDouble(),
                    totalWidth: constraints.maxWidth,
                  ),
                ),
                const SizedBox(height: 14),
                if (healthPoints.isNotEmpty)
                  ...healthPoints.map((p) => _HealthPointRow(point: p))
                else
                  Text(
                    'No health remarks available.',
                    style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Vitamins & Minerals
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('⚗️', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      'Vitamins & Minerals',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SectionLabel('Vitamins'),
                if (vitamins.isNotEmpty)
                  ...vitamins.map((v) => _UnlockRow(label: v))
                else
                  Text(
                    'No vitamins listed.',
                    style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280)),
                  ),
                const SizedBox(height: 12),
                _SectionLabel('Minerals'),
                ..._minerals.map((m) => _UnlockRow(label: m)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Additional Info
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFF6B7280), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Additional Information',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ..._additional.map((a) => _UnlockRow(label: a)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ingredients Tab ──────────────────────────────────────────────────────────
class _IngredientsTab extends StatelessWidget {
  final List<String> ingredients;

  const _IngredientsTab({required this.ingredients});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ingredients',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  'For 1 serving',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...List.generate(ingredients.length, (i) {
              final str = ingredients[i];
              final parts = str.split(' - ');
              final name = parts[0];
              final qty = parts.length >= 2 ? parts[1] : '1 serving';

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF1A1A2E),
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          qty,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < ingredients.length - 1)
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A1A2E),
        ),
      ),
    );
  }
}

class _HealthScoreBar extends StatelessWidget {
  final double score;
  final double totalWidth;

  const _HealthScoreBar(
      {required this.score, required this.totalWidth});

  @override
  Widget build(BuildContext context) {
    final thumbPos = (score / 10) * totalWidth - 10;
    return SizedBox(
      height: 22,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 2,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Container(
                height: 18,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFF5252),
                      Color(0xFFFBC02D),
                      Color(0xFF10B981)
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 1,
            left: thumbPos.clamp(0.0, totalWidth - 20),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFDDDDDD), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthPointRow extends StatelessWidget {
  final _HP point;
  const _HealthPointRow({required this.point});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: point.ok
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              point.ok
                  ? Icons.check_rounded
                  : Icons.priority_high_rounded,
              size: 11,
              color: point.ok
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFFF5252),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              point.text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF1A1A2E),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockRow extends StatelessWidget {
  final String label;
  const _UnlockRow({required this.label});

  @override
  Widget build(BuildContext context) {
    final isIndented =
        label.startsWith('Vitamin B') && label.length > 9;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(isIndented ? 12.0 : 0, 7, 0, 7),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Unlock',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
      ],
    );
  }
}

class _HP {
  final String text;
  final bool ok;
  const _HP(this.text, this.ok);
}