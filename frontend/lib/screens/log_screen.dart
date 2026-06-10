import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:io';
import '../theme/theme.dart';
import 'meal_type_sheet.dart';
import '../providers/food_log_store.dart';
import 'nutrition_screen.dart';
import '../services/api/api_service.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  late DateTime _today;
  late DateTime _selectedDate;
  late ScrollController _dateScrollController;
  // Show 60 days window: 30 before today + today + 29 after
  static const int _daysBefore = 30;
  static const int _daysTotal = 60;
  // approximate item width for centering today
  static const double _itemWidth = 46.0;

  List<FoodEntry> _meals = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    _selectedDate = _today;
    _dateScrollController = ScrollController();

    // Listen to store changes and rebuild
    FoodLogStore.instance.addListener(_onStoreChanged);

    // Scroll to today after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
    _fetchMeals();
  }

  Future<void> _fetchMeals() async {
    setState(() => _isLoading = true);
    final response = await ApiService().getMeals(_selectedDate);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (response.isSuccess && response.data != null) {
        _meals = response.data!.map((m) {
          return FoodEntry(
            id: m['_id'] as String?,
            meal: m['mealType'] as String? ?? 'Breakfast',
            name: m['foodName'] as String? ?? '',
            protein: (m['protein'] as num?)?.toInt() ?? 0,
            fat: (m['fat'] as num?)?.toInt() ?? 0,
            carbs: (m['carbs'] as num?)?.toInt() ?? 0,
            calories: (m['calories'] as num?)?.toInt() ?? 0,
            loggedAt: m['loggedAt'] != null ? DateTime.parse(m['loggedAt'] as String) : DateTime.now(),
          );
        }).toList();
      }
    });
  }

  void _onStoreChanged() {
    _fetchMeals();
  }

  @override
  void dispose() {
    FoodLogStore.instance.removeListener(_onStoreChanged);
    _dateScrollController.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    if (!_dateScrollController.hasClients) return;
    final offset = _daysBefore * _itemWidth - 8;
    _dateScrollController.animateTo(
      offset.clamp(0.0, _dateScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  DateTime _dateAtIndex(int i) =>
      _today.subtract(Duration(days: _daysBefore - i));

  // Short day labels: Mon, Tue…
  static const List<String> _dayNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  String _dayLabel(DateTime d) => _dayNames[d.weekday - 1];

  // Whether a date has any logged entries
  bool _hasEntries(DateTime d) =>
      FoodLogStore.instance.entriesFor(d).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final entries = _meals;
    final totalCal = entries.fold(0, (s, e) => s + e.calories);
    final _dailyGoal = FoodLogStore.instance.goalFor(_selectedDate);
    final int goalCal = _dailyGoal.calories;
    final int goalProtein = _dailyGoal.protein;
    final int goalFat = _dailyGoal.fat;
    final int goalCarbs = _dailyGoal.carbs;
    final int calLeft = (goalCal - totalCal).clamp(0, goalCal);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context),
                _buildDateStrip(),
                if (_isLoading)
                  const LinearProgressIndicator(
                    color: AppTheme.primaryGreen,
                    backgroundColor: Colors.transparent,
                    minHeight: 2,
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCalorieMacroRow(
                            entries, calLeft, goalCal, goalProtein, goalFat, goalCarbs, totalCal),
                        const SizedBox(height: 18),
                        _buildFoodIntakeHeader(totalCal),
                        const SizedBox(height: 12),
                        if (entries.isEmpty)
                          _buildEmptyState()
                        else
                          ..._buildFoodCards(entries),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // FAB
            Positioned(
              right: 20,
              bottom: 20,
              child: GestureDetector(
                onTap: () => _openMealTypePicker(context),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child:
                  const Icon(Icons.add, color: Colors.white, size: 26),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.lightGreen.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: Color(0xFF1A1A2E)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Log',
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const Spacer(),
          // Show selected date if not today
          if (_selectedDate != _today)
            GestureDetector(
              onTap: () {
                setState(() => _selectedDate = _today);
                _scrollToToday();
                _fetchMeals();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Today',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.lightGreen.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_month_outlined,
                size: 18, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.orange,
              borderRadius: BorderRadius.circular(18),
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NutritionScreen(),
                  ),
                );
              },
              child: const Icon(Icons.local_fire_department_rounded,
                  size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── Real-time scrollable date strip ────────────────────────────────────────
  Widget _buildDateStrip() {
    return SizedBox(
      height: 68,
      child: ListView.builder(
        controller: _dateScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _daysTotal,
        itemBuilder: (_, i) {
          final date = _dateAtIndex(i);
          final isToday = date == _today;
          final isSelected = date == _selectedDate;
          final hasDot = _hasEntries(date) && !isSelected;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
              _fetchMeals();
            },
            child: SizedBox(
              width: _itemWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Day name
                  Text(
                    _dayLabel(date),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: isToday
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : isToday
                          ? AppTheme.darkGreen
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Date circle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : isToday
                          ? AppTheme.primaryGreen.withOpacity(0.10)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(17),
                      border: isToday && !isSelected
                          ? Border.all(
                          color: AppTheme.primaryGreen.withOpacity(0.45),
                          width: 1.5)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${date.day}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: isSelected || isToday
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Dot if entries exist
                  AnimatedOpacity(
                    opacity: hasDot ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppTheme.orange,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Calorie + Macro row ────────────────────────────────────────────────────
  Widget _buildCalorieMacroRow(
      List<FoodEntry> entries, int calLeft, int goalCal,
      int goalProtein, int goalFat, int goalCarbs, int totalCal) {
    // Aggregate macros from entries
    int protein = entries.fold(0, (s, e) => s + e.protein);
    int fat = entries.fold(0, (s, e) => s + e.fat);
    int carbs = entries.fold(0, (s, e) => s + e.carbs);

    // Dynamic goals from user-set daily goal
    final int proteinGoal = goalProtein;
    final int fatGoal = goalFat;
    final int carbsGoal = goalCarbs;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Donut
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(120, 120),
                painter: _DonutPainter(
                  value: goalCal > 0
                      ? (totalCal / goalCal).clamp(0.0, 1.0)
                      : 0,
                  color: AppTheme.primaryGreen,
                  trackColor: AppTheme.lightGreen,
                  strokeWidth: 10,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(calLeft > 0 ? '🔥' : '🔥',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    calLeft > 0 ? '$calLeft' : '$totalCal',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                      height: 1.1,
                    ),
                  ),
                  Text(
                    calLeft > 0 ? 'kcal left' : 'kcal eaten',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        // Macros
        Expanded(
          child: Column(
            children: [
              _MacroRow(
                emoji: '🥩',
                label: 'Protein',
                current: protein,
                max: proteinGoal,
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(height: 10),
              _MacroRow(
                emoji: '💧',
                label: 'Fat',
                current: fat,
                max: fatGoal,
                color: const Color(0xFFFF5252),
              ),
              const SizedBox(height: 10),
              _MacroRow(
                emoji: '🌾',
                label: 'Carbs',
                current: carbs,
                max: carbsGoal,
                color: const Color(0xFF5C6BC0),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Food intake header ─────────────────────────────────────────────────────
  Widget _buildFoodIntakeHeader(int totalCal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Food intake',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        Text(
          '$totalCal kcal',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppTheme.textMedium,
          ),
        ),
      ],
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'No meals logged yet',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + to log your first meal',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Food cards ─────────────────────────────────────────────────────────────
  List<Widget> _buildFoodCards(List<FoodEntry> entries) {
    // Group by meal type
    final Map<String, List<FoodEntry>> grouped = {};
    for (final e in entries) {
      grouped.putIfAbsent(e.meal, () => []).add(e);
    }

    // Order: Breakfast, Lunch, Dinner, Snack, others
    const order = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
    final keys = [
      ...order.where((k) => grouped.containsKey(k)),
      ...grouped.keys.where((k) => !order.contains(k)),
    ];

    final widgets = <Widget>[];
    for (final mealType in keys) {
      final mealEntries = grouped[mealType]!;

      // Meal label chip with color per type
      widgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _mealColor(mealType),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            mealType,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
      widgets.add(const SizedBox(height: 8));

      for (final food in mealEntries) {
        widgets.add(_FoodCard(
          food: food,
          onDelete: () async {
            if (food.id != null) {
              final response = await ApiService().deleteMeal(food.id!);
              if (response.isSuccess) {
                _fetchMeals();
              }
            } else {
              FoodLogStore.instance.removeEntry(food);
            }
          },
        ));
        widgets.add(const SizedBox(height: 10));
      }
      widgets.add(const SizedBox(height: 4));
    }

    return widgets;
  }

  Color _mealColor(String meal) {
    switch (meal) {
      case 'Breakfast':
        return const Color(0xFFFBC02D);
      case 'Lunch':
        return AppTheme.primaryGreen;
      case 'Dinner':
        return AppTheme.darkGreen;
      case 'Snack':
        return const Color(0xFFFF6B35);
      default:
        return const Color(0xFF6B7280);
    }
  }

  void _openMealTypePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const MealTypeSheet(),
    );
  }
}

// ─── Food Card Widget ─────────────────────────────────────────────────────────
class _FoodCard extends StatelessWidget {
  final FoodEntry food;
  final VoidCallback onDelete;

  const _FoodCard({required this.food, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image or emoji thumbnail ──────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: food.imageFile != null
                ? Image.file(
              food.imageFile!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _emojiThumb(),
            )
                : _emojiThumb(),
          ),
          const SizedBox(width: 12),

          // ── Name + macros ─────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    _MacroChip(
                        emoji: '🥩',
                        value: '${food.protein}g',
                        color: AppTheme.primaryGreen),
                    _MacroChip(
                        emoji: '💧',
                        value: '${food.fat}g',
                        color: const Color(0xFFFF5252)),
                    _MacroChip(
                        emoji: '🌾',
                        value: '${food.carbs}g',
                        color: const Color(0xFF5C6BC0)),
                    _MacroChip(
                        emoji: '',
                        value: '${food.calories} kcal',
                        color: const Color(0xFF6B7280)),
                  ],
                ),
              ],
            ),
          ),

          // ── Delete ────────────────────────────────────────────────
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: Color(0xFF6B7280)),
            padding: EdgeInsets.zero,
            constraints:
            const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  Widget _emojiThumb() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.lightGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          size: 26,
          color: AppTheme.primaryGreen,
        ),
      ),
    );
  }
}

// ─── Macro Row ────────────────────────────────────────────────────────────────
class _MacroRow extends StatelessWidget {
  final String emoji;
  final String label;
  final int current;
  final int max;
  final Color color;

  const _MacroRow({
    required this.emoji,
    required this.label,
    required this.current,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$emoji $label',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: const Color(0xFF1A1A2E)),
            ),
            Text(
              '$current/$max g',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: const Color(0xFF6B7280)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: max > 0 ? (current / max).clamp(0.0, 1.0) : 0,
            minHeight: 5,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ─── Macro Chip ───────────────────────────────────────────────────────────────
class _MacroChip extends StatelessWidget {
  final String emoji;
  final String value;
  final Color color;

  const _MacroChip(
      {required this.emoji, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$emoji $value'.trim(),
      style: GoogleFonts.poppins(fontSize: 10, color: color),
    );
  }
}

// ─── Donut Painter ────────────────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _DonutPainter({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round);

    if (value > 0) {
      canvas.drawArc(
          rect,
          -math.pi / 2,
          2 * math.pi * value,
          false,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}