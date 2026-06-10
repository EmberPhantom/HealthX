import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../providers/food_log_store.dart';
import '../theme/theme.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen>
    with SingleTickerProviderStateMixin {
  static const double _refW = 360;
  static const double _refH = 800;

  late final TextEditingController _proteinCtrl;
  late final TextEditingController _fatCtrl;
  late final TextEditingController _carbCtrl;

  late AnimationController _donutController;
  late Animation<double> _donutAnimation;

  int _protein = 0;
  int _fat = 0;
  int _carbs = 0;

  int get _calories => (_protein * 4) + (_fat * 9) + (_carbs * 4);
  int get _totalG => _protein + _fat + _carbs;

  @override
  void initState() {
    super.initState();

    final goal = FoodLogStore.instance.goalFor(DateTime.now());
    _protein = goal.protein;
    _fat = goal.fat;
    _carbs = goal.carbs;

    _proteinCtrl = TextEditingController(text: '$_protein');
    _fatCtrl = TextEditingController(text: '$_fat');
    _carbCtrl = TextEditingController(text: '$_carbs');

    _donutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _donutAnimation = CurvedAnimation(
      parent: _donutController,
      curve: Curves.easeOutCubic,
    );

    for (final ctrl in [_proteinCtrl, _fatCtrl, _carbCtrl]) {
      ctrl.addListener(_onChanged);
    }
    _donutController.forward();
  }

  void _onChanged() {
    setState(() {
      _protein = int.tryParse(_proteinCtrl.text) ?? 0;
      _fat = int.tryParse(_fatCtrl.text) ?? 0;
      _carbs = int.tryParse(_carbCtrl.text) ?? 0;
    });
    _donutController.forward(from: 0);
  }

  @override
  void dispose() {
    _proteinCtrl.dispose();
    _fatCtrl.dispose();
    _carbCtrl.dispose();
    _donutController.dispose();
    super.dispose();
  }

  void _onSetGoal() {
    if (_calories == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter at least one macro value',
              style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: const Color(0xFFFF5252),
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    FoodLogStore.instance.setGoal(
      DailyGoal(
        calories: _calories,
        protein: _protein,
        fat: _fat,
        carbs: _carbs,
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Daily goal set — $_calories kcal target',
            style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final ws = mq.size.width / _refW;
    final hs = mq.size.height / _refH;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(ws * 18, hs * 10, ws * 18, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: ws * 20, color: AppTheme.textDark),
                  ),
                  SizedBox(width: ws * 12),
                  Expanded(
                    child: Text(
                      'Set Daily Goal',
                      style: GoogleFonts.poppins(
                        fontSize: ws * 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Subtitle ────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(ws * 18, hs * 4, ws * 18, 0),
              child: Text(
                'Set your daily macro targets. Calories are calculated automatically.',
                style: GoogleFonts.poppins(
                  fontSize: ws * 12,
                  color: const Color(0xFF9CA3AF),
                  height: 1.4,
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    ws * 18, hs * 10, ws * 18, mq.padding.bottom + hs * 8),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // ── Live donut preview ──────────────────────────
                      AnimatedBuilder(
                        animation: _donutAnimation,
                        builder: (_, __) => _GoalDonutCard(
                          protein: _protein,
                          fat: _fat,
                          carbs: _carbs,
                          calories: _calories,
                          totalG: _totalG,
                          progress: _donutAnimation.value,
                          ws: ws,
                          hs: hs,
                        ),
                      ),
                      SizedBox(height: hs * 10),

                      // ── Protein ─────────────────────────────────────
                      _MacroInputTile(
                        label: 'Protein (g)',
                        sublabel: '1g = 4 kcal',
                        color: AppTheme.lightGreen,
                        accentColor: AppTheme.primaryGreen,
                        controller: _proteinCtrl,
                        ws: ws,
                        hs: hs,
                      ),
                      SizedBox(height: hs * 6),

                      Row(
                        children: [
                          Expanded(
                            child: _MacroInputTile(
                              label: 'Fat (g)',
                              sublabel: '1g = 9 kcal',
                              color: const Color(0xFFFFEBEE),
                              accentColor: const Color(0xFFFF5252),
                              controller: _fatCtrl,
                              ws: ws,
                              hs: hs,
                            ),
                          ),
                          SizedBox(width: ws * 10),
                          Expanded(
                            child: _MacroInputTile(
                              label: 'Carb (g)',
                              sublabel: '1g = 4 kcal',
                              color: const Color(0xFFEDE7F6),
                              accentColor: const Color(0xFF7E57C2),
                              controller: _carbCtrl,
                              ws: ws,
                              hs: hs,
                            ),
                          ),
                        ],
                      ),

                      // ── Calorie result card ─────────────────────────
                      if (_calories > 0) ...[
                        SizedBox(height: hs * 8),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                              horizontal: ws * 14, vertical: hs * 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppTheme.darkGreen, AppTheme.primaryGreen], begin: Alignment.centerLeft, end: Alignment.centerRight),
                            borderRadius: BorderRadius.circular(ws * 14),
                          ),
                          child: Row(
                            children: [
                              Text('🎯',
                                  style: TextStyle(fontSize: ws * 16)),
                              SizedBox(width: ws * 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Daily Calorie Goal',
                                    style: GoogleFonts.poppins(
                                      fontSize: ws * 10,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                  Text(
                                    '$_calories kcal / day',
                                    style: GoogleFonts.poppins(
                                      fontSize: ws * 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: hs * 4),
                        Text(
                          'Protein × 4  +  Fat × 9  +  Carbs × 4',
                          style: GoogleFonts.poppins(
                            fontSize: ws * 10,
                            color: const Color(0xFF9CA3AF),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: hs * 164),
                      ],

                      // ── Set Goal button ─────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _calories > 0 ? _onSetGoal : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            disabledBackgroundColor: AppTheme.divider,
                            foregroundColor: Colors.white,
                            disabledForegroundColor: AppTheme.textMedium,
                            padding: EdgeInsets.symmetric(vertical: hs * 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ws * 12),
                            ),
                            elevation: 3,
                            shadowColor: AppTheme.primaryGreen.withOpacity(0.4),
                          ),
                          child: Text(
                            'Set Goal',
                            style: GoogleFonts.poppins(
                              fontSize: ws * 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Goal Donut Card ─────────────────────────────────────────────────────────
class _GoalDonutCard extends StatelessWidget {
  final int protein, fat, carbs, calories, totalG;
  final double progress;
  final double ws;
  final double hs;

  const _GoalDonutCard({
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.calories,
    required this.totalG,
    required this.progress,
    required this.ws,
    required this.hs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ws * 14),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(ws * 12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: ws * 80,
            height: ws * 80,
            child: CustomPaint(
              painter: _GoalDonutPainter(
                protein: protein,
                fat: fat,
                carbs: carbs,
                totalG: totalG,
                progress: progress,
              ),
              child: Center(
                child: calories > 0
                    ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$calories',
                      style: GoogleFonts.poppins(
                        fontSize: ws * 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      'kcal',
                      style: GoogleFonts.poppins(
                        fontSize: ws * 9,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                )
                    : Icon(Icons.track_changes_rounded,
                    size: ws * 26, color: const Color(0xFF9CA3AF)),
              ),
            ),
          ),
          SizedBox(width: ws * 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendItem(
                    color: AppTheme.primaryGreen,
                    label: 'Protein',
                    value: protein,
                    ws: ws),
                SizedBox(height: hs * 8),
                _LegendItem(
                    color: const Color(0xFFFF5252),
                    label: 'Fat',
                    value: fat,
                    ws: ws),
                SizedBox(height: hs * 8),
                _LegendItem(
                    color: const Color(0xFF5C6BC0),
                    label: 'Carbs',
                    value: carbs,
                    ws: ws),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  final double ws;

  const _LegendItem(
      {required this.color,
        required this.label,
        required this.value,
        required this.ws});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: ws * 10,
          height: ws * 10,
          decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(ws * 5)),
        ),
        SizedBox(width: ws * 8),
        Expanded(
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: ws * 10, color: const Color(0xFF6B7280))),
        ),
        Text('${value}g',
            style: GoogleFonts.poppins(
                fontSize: ws * 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A2E))),
      ],
    );
  }
}

// ─── Donut Painter ────────────────────────────────────────────────────────────
class _GoalDonutPainter extends CustomPainter {
  final int protein, fat, carbs, totalG;
  final double progress;

  _GoalDonutPainter({
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.totalG,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sw = size.width * (10 / 80);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - sw) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xFFE5E7EB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw);

    if (totalG == 0) return;

    final total = 2 * math.pi * progress;
    double start = -math.pi / 2;

    void draw(int g, Color c) {
      final sweep = total * (g / totalG);
      if (sweep <= 0) return;
      canvas.drawArc(
          rect,
          start,
          sweep,
          false,
          Paint()
            ..color = c
            ..style = PaintingStyle.stroke
            ..strokeWidth = sw
            ..strokeCap = StrokeCap.round);
      start += sweep;
    }

    draw(protein, AppTheme.primaryGreen);
    draw(fat, const Color(0xFFFF5252));
    draw(carbs, const Color(0xFF5C6BC0));
  }

  @override
  bool shouldRepaint(covariant _GoalDonutPainter old) => true;
}

// ─── Macro Input Tile ─────────────────────────────────────────────────────────
class _MacroInputTile extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final Color accentColor;
  final TextEditingController controller;
  final double ws;
  final double hs;

  const _MacroInputTile({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.accentColor,
    required this.controller,
    required this.ws,
    required this.hs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.5),
        borderRadius: BorderRadius.circular(ws * 14),
        border: Border.all(color: accentColor.withOpacity(0.4), width: ws * 1.5),
      ),
      padding: EdgeInsets.fromLTRB(ws * 10, hs * 6, ws * 10, hs * 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: ws * 10,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
              const Spacer(),
              Text(
                sublabel,
                style: GoogleFonts.poppins(
                  fontSize: ws * 9,
                  color: accentColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
          SizedBox(height: hs * 3),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: ws * 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ws * 8),
                borderSide: BorderSide(
                    color: AppTheme.primaryGreen.withOpacity(0.3), width: ws * 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ws * 8),
                borderSide: BorderSide(
                    color: AppTheme.primaryGreen.withOpacity(0.3), width: ws * 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ws * 8),
                borderSide: BorderSide(
                    color: AppTheme.primaryGreen, width: ws * 2.0),
              ),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                  vertical: hs * 8, horizontal: ws * 10),
            ),
            onTap: () {
              if (controller.text == '0') controller.clear();
            },
          ),
        ],
      ),
    );
  }
}