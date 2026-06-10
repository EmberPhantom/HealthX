import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'nutrition_screen.dart';
import '../providers/food_log_store.dart';
import '../theme/theme.dart';
import '../services/api/api_service.dart';

class LogManuallyScreen extends StatefulWidget {
  final String meal;
  const LogManuallyScreen({super.key, required this.meal});

  @override
  State<LogManuallyScreen> createState() => _LogManuallyScreenState();
}

class _LogManuallyScreenState extends State<LogManuallyScreen> {
  final _titleCtrl = TextEditingController();
  File? _pickedImage;
  final List<_IngredientItem> _ingredients = [];
  int _protein = 0, _fat = 0, _carbs = 0;
  bool _hasNutrition = false;
  bool _isSaving = false;

  static const double _refW = 360;
  static const double _refH = 800;

  int get _calories => (_protein * 4) + (_fat * 9) + (_carbs * 4);

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageSourceSheet(),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked != null && mounted) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  void _openNutritionScreen() async {
    final result = await Navigator.push<Map<String, int>>(
      context,
      MaterialPageRoute(
        builder: (_) => _NutritionInputScreen(
          initialProtein: _protein,
          initialFat: _fat,
          initialCarbs: _carbs,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _protein = result['protein'] ?? 0;
        _fat = result['fat'] ?? 0;
        _carbs = result['carbs'] ?? 0;
        _hasNutrition = true;
      });
    }
  }

  void _addIngredient() {
    showDialog(
      context: context,
      builder: (_) => _AddIngredientDialog(
        onAdd: (name, qty) {
          setState(
                  () => _ingredients.add(_IngredientItem(name: name, qty: qty)));
        },
      ),
    );
  }

  void _onNext() async {
    final name = _titleCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
        Text('Please add a title', style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: const Color(0xFFFF5252),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    if (!_hasNutrition || _calories == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please add nutrition info',
            style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: const Color(0xFFFF5252),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    setState(() => _isSaving = true);

    // Call backend API
    final response = await ApiService().logMeal({
      'mealType': widget.meal,
      'foodName': name,
      'protein': _protein,
      'fat': _fat,
      'carbs': _carbs,
      'calories': _calories,
      'ingredients': _ingredients.map((i) => '${i.name} - ${i.qty}').toList(),
      'loggedAt': DateTime.now().toIso8601String(),
    });

    setState(() => _isSaving = false);

    if (response.isSuccess) {
      FoodLogStore.instance.addEntry(FoodEntry(
        meal: widget.meal,
        name: name,
        protein: _protein,
        fat: _fat,
        carbs: _carbs,
        calories: _calories,
        imageFile: _pickedImage,
        loggedAt: DateTime.now(),
      ));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${widget.meal} logged — $_calories kcal',
            style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));

      Navigator.of(context).pop();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response.error ?? 'Failed to log meal to server',
            style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: const Color(0xFFFF5252),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final screenWidth = constraints.maxWidth;
      final screenHeight = MediaQuery.of(context).size.height;
      final ws = screenWidth / _refW;
      final hs = screenHeight / _refH;
      final mq = MediaQuery.of(context);

      return Scaffold(
        backgroundColor: const Color(0xFFF0F6F3),
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ───────────────────────────────────────────────
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(18 * ws, 14 * hs, 18 * ws, 14 * hs),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20 * ws, color: AppTheme.textDark),
                    ),
                    SizedBox(width: 12 * ws),
                    Expanded(
                      child: Text(
                        'Log manually',
                        style: GoogleFonts.poppins(
                          fontSize: 18 * ws,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: GoogleFonts.poppins(
                          fontSize: 14 * ws,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      16 * ws, 16 * hs, 16 * ws, 100 * hs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title + Image Row ──────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14 * ws),
                          border:
                          Border.all(color: AppTheme.divider),
                        ),
                        padding: EdgeInsets.all(12 * ws),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _titleCtrl,
                                style: GoogleFonts.poppins(
                                  fontSize: 14 * ws,
                                  color: const Color(0xFF1A1A2E),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Add title',
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 14 * ws,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 4 * ws, vertical: 2 * hs),
                                ),
                              ),
                            ),
                            SizedBox(width: 8 * ws),
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 48 * ws,
                                height: 48 * ws,
                                decoration: BoxDecoration(
                                  color: AppTheme.lightGreen.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(10 * ws),
                                  border: Border.all(
                                      color: AppTheme.primaryGreen.withOpacity(0.3)),
                                ),
                                child: _pickedImage != null
                                    ? ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(9 * ws),
                                  child: Image.file(_pickedImage!,
                                      fit: BoxFit.cover),
                                )
                                    : Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 22 * ws,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10 * hs),

                      // ── Nutrition row ──────────────────────────────────
                      GestureDetector(
                        onTap: _openNutritionScreen,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14 * ws),
                            border:
                            Border.all(color: AppTheme.divider),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16 * ws, vertical: 14 * hs),
                          child: Row(
                            children: [
                              Container(
                                width: 32 * ws,
                                height: 32 * ws,
                                decoration: BoxDecoration(
                                  color: AppTheme.lightGreen,
                                  borderRadius: BorderRadius.circular(8 * ws),
                                ),
                                child: Icon(
                                  Icons.pie_chart_outline_rounded,
                                  size: 16 * ws,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              SizedBox(width: 12 * ws),
                              Expanded(
                                child: Text(
                                  'Nutrition',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14 * ws,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1A1A2E),
                                  ),
                                ),
                              ),
                              if (_hasNutrition && _calories > 0)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8 * ws, vertical: 3 * hs),
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightGreen,
                                    borderRadius:
                                    BorderRadius.circular(8 * ws),
                                  ),
                                  child: Text(
                                    '$_calories kcal',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11 * ws,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.darkGreen,
                                    ),
                                  ),
                                ),
                              SizedBox(width: 4 * ws),
                              Icon(Icons.chevron_right_rounded,
                                  size: 20 * ws,
                                  color: const Color(0xFF9CA3AF)),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24 * hs),

                      // ── Ingredients ────────────────────────────────────
                      Text(
                        'Ingredients',
                        style: GoogleFonts.poppins(
                          fontSize: 16 * ws,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      SizedBox(height: 10 * hs),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14 * ws),
                          border:
                          Border.all(color: AppTheme.divider),
                        ),
                        child: Column(
                          children: [
                            if (_ingredients.isEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16 * ws, vertical: 14 * hs),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 3 * ws,
                                      height: 20 * hs,
                                      color: AppTheme.primaryGreen,
                                      margin:
                                      EdgeInsets.only(right: 10 * ws),
                                    ),
                                    Text(
                                      'Add at least one ingredient',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13 * ws,
                                        color: const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _ingredients.length,
                                separatorBuilder: (_, __) => const Divider(
                                    height: 1, color: Color(0xFFE5E7EB)),
                                itemBuilder: (_, i) {
                                  final ing = _ingredients[i];
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16 * ws,
                                        vertical: 12 * hs),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            ing.name,
                                            style: GoogleFonts.poppins(
                                              fontSize: 13 * ws,
                                              color: AppTheme.textDark,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          ing.qty,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12 * ws,
                                            color: AppTheme.textMedium,
                                          ),
                                        ),
                                        SizedBox(width: 4 * ws),
                                        GestureDetector(
                                          onTap: () => setState(
                                                  () => _ingredients.removeAt(i)),
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 16 * ws,
                                            color: const Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            const Divider(
                                height: 1, color: Color(0xFFE5E7EB)),
                            GestureDetector(
                              onTap: _addIngredient,
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                    vertical: 14 * hs),
                                decoration: BoxDecoration(
                                  color: AppTheme.lightGreen.withOpacity(0.25),
                                  borderRadius: BorderRadius.vertical(
                                      bottom: Radius.circular(13 * ws)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add,
                                        size: 16 * ws,
                                        color: AppTheme.primaryGreen),
                                    SizedBox(width: 6 * ws),
                                    Text(
                                      'Ingredient',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13 * ws,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Next button ──────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                    18 * ws, 8 * hs, 18 * ws, mq.padding.bottom + 16 * hs),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16 * hs),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14 * ws),
                      ),
                      elevation: 3,
                      shadowColor: AppTheme.primaryGreen.withOpacity(0.4),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Log data',
                            style: GoogleFonts.poppins(
                              fontSize: 15 * ws,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ─── Nutrition Input Sub-Screen ───────────────────────────────────────────────
class _NutritionInputScreen extends StatefulWidget {
  final int initialProtein, initialFat, initialCarbs;
  const _NutritionInputScreen({
    required this.initialProtein,
    required this.initialFat,
    required this.initialCarbs,
  });

  @override
  State<_NutritionInputScreen> createState() => _NutritionInputScreenState();
}

class _NutritionInputScreenState extends State<_NutritionInputScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _fatCtrl;
  late final TextEditingController _carbCtrl;

  late AnimationController _donutCtrl;
  late Animation<double> _donutAnim;

  int _protein = 0, _fat = 0, _carbs = 0;
  int get _calories => (_protein * 4) + (_fat * 9) + (_carbs * 4);
  int get _totalG => _protein + _fat + _carbs;

  static const double _refW = 360;
  static const double _refH = 800;

  @override
  void initState() {
    super.initState();
    _protein = widget.initialProtein;
    _fat = widget.initialFat;
    _carbs = widget.initialCarbs;

    _proteinCtrl =
        TextEditingController(text: _protein == 0 ? '0' : '$_protein');
    _fatCtrl = TextEditingController(text: _fat == 0 ? '0' : '$_fat');
    _carbCtrl = TextEditingController(text: _carbs == 0 ? '0' : '$_carbs');

    _donutCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _donutAnim =
        CurvedAnimation(parent: _donutCtrl, curve: Curves.easeOutCubic);

    for (final ctrl in [_proteinCtrl, _fatCtrl, _carbCtrl]) {
      ctrl.addListener(_onChange);
    }
    _donutCtrl.forward();
  }

  void _onChange() {
    setState(() {
      _protein = int.tryParse(_proteinCtrl.text) ?? 0;
      _fat = int.tryParse(_fatCtrl.text) ?? 0;
      _carbs = int.tryParse(_carbCtrl.text) ?? 0;
    });
    _donutCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _proteinCtrl.dispose();
    _fatCtrl.dispose();
    _carbCtrl.dispose();
    _donutCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final screenWidth = constraints.maxWidth;
      final screenHeight = MediaQuery.of(context).size.height;
      final ws = screenWidth / _refW;
      final hs = screenHeight / _refH;
      final mq = MediaQuery.of(context);

      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(18 * ws, 14 * hs, 18 * ws, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20 * ws, color: AppTheme.textDark),
                    ),
                    SizedBox(width: 12 * ws),
                    Expanded(
                      child: Text(
                        'Nutrition',
                        style: GoogleFonts.poppins(
                          fontSize: 18 * ws,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context, {
                        'protein': _protein,
                        'fat': _fat,
                        'carbs': _carbs,
                      }),
                      child: Text(
                        'Save',
                        style: GoogleFonts.poppins(
                          fontSize: 14 * ws,
                          fontWeight: FontWeight.w700,
                          color: _calories > 0
                              ? AppTheme.primaryGreen
                              : AppTheme.textMedium.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      18 * ws, 20 * hs, 18 * ws, 40 * hs),
                  child: Column(
                    children: [
                      // Donut
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20 * ws),
                        decoration: BoxDecoration(
                          color: AppTheme.bgLight,
                          borderRadius: BorderRadius.circular(16 * ws),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Row(
                          children: [
                            AnimatedBuilder(
                              animation: _donutAnim,
                              builder: (_, __) => SizedBox(
                                width: 100 * ws,
                                height: 100 * ws,
                                child: CustomPaint(
                                  painter: _MacroDonutPainter2(
                                    protein: _protein,
                                    fat: _fat,
                                    carbs: _carbs,
                                    totalG: _totalG,
                                    progress: _donutAnim.value,
                                  ),
                                  child: Center(
                                    child: _calories > 0
                                        ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '$_calories',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16 * ws,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1A1A2E),
                                          ),
                                        ),
                                        Text(
                                          'kcal',
                                          style: GoogleFonts.poppins(
                                            fontSize: 9 * ws,
                                            color:
                                            const Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    )
                                        : Icon(
                                      Icons.lock_open_rounded,
                                      size: 24 * ws,
                                      color: AppTheme.textMedium.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 20 * ws),
                            Expanded(
                              child: Column(
                                children: [
                                  _LegRow(
                                      color: AppTheme.primaryGreen,
                                      label: 'Protein',
                                      value: _protein,
                                      ws: ws),
                                  SizedBox(height: 8 * hs),
                                  _LegRow(
                                      color: const Color(0xFFFF5252),
                                      label: 'Fat',
                                      value: _fat,
                                      ws: ws),
                                  SizedBox(height: 8 * hs),
                                  _LegRow(
                                      color: const Color(0xFF5C6BC0),
                                      label: 'Carbs',
                                      value: _carbs,
                                      ws: ws),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20 * hs),

                      // Protein
                      _InputCard(
                        label: 'Protein (g)',
                        color: AppTheme.lightGreen,
                        textColor: AppTheme.primaryGreen,
                        controller: _proteinCtrl,
                        ws: ws,
                        hs: hs,
                      ),
                      SizedBox(height: 10 * hs),

                      Row(
                        children: [
                          Expanded(
                            child: _InputCard(
                              label: 'Fat (g)',
                              color: const Color(0xFFFFEBEE),
                              textColor: const Color(0xFFFF5252),
                              controller: _fatCtrl,
                              ws: ws,
                              hs: hs,
                            ),
                          ),
                          SizedBox(width: 10 * ws),
                          Expanded(
                            child: _InputCard(
                              label: 'Carb (g)',
                              color: const Color(0xFFEDE7F6),
                              textColor: const Color(0xFF7E57C2),
                              controller: _carbCtrl,
                              ws: ws,
                              hs: hs,
                            ),
                          ),
                        ],
                      ),

                      if (_calories > 0) ...[
                        SizedBox(height: 24 * hs),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20 * ws, vertical: 16 * hs),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppTheme.darkGreen, AppTheme.primaryGreen], begin: Alignment.centerLeft, end: Alignment.centerRight),
                            borderRadius: BorderRadius.circular(14 * ws),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Calories',
                                style: GoogleFonts.poppins(
                                  fontSize: 14 * ws,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              Row(
                                children: [
                                  Text('🔥',
                                      style:
                                      TextStyle(fontSize: 16 * ws)),
                                  SizedBox(width: 6 * ws),
                                  Text(
                                    '$_calories kcal',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18 * ws,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(
                    18 * ws, 8 * hs, 18 * ws, mq.padding.bottom + 16 * hs),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, {
                      'protein': _protein,
                      'fat': _fat,
                      'carbs': _carbs,
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      disabledBackgroundColor: AppTheme.divider,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16 * hs),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14 * ws),
                      ),
                      elevation: 3,
                      shadowColor: AppTheme.primaryGreen.withOpacity(0.4),
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.poppins(
                        fontSize: 15 * ws,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _LegRow extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  final double ws;
  const _LegRow(
      {required this.color,
        required this.label,
        required this.value,
        required this.ws});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10 * ws,
          height: 10 * ws,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(5 * ws)),
        ),
        SizedBox(width: 8 * ws),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12 * ws, color: const Color(0xFF6B7280))),
        const Spacer(),
        Text('${value}g',
            style: GoogleFonts.poppins(
                fontSize: 12 * ws,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A2E))),
      ],
    );
  }
}

class _InputCard extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final TextEditingController controller;
  final double ws;
  final double hs;

  const _InputCard({
    required this.label,
    required this.color,
    required this.textColor,
    required this.controller,
    required this.ws,
    required this.hs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14 * ws),
        border: Border.all(color: color, width: 1.5),
      ),
      padding: EdgeInsets.fromLTRB(16 * ws, 10 * hs, 16 * ws, 10 * hs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12 * ws,
                  fontWeight: FontWeight.w500,
                  color: textColor)),
          SizedBox(height: 4 * hs),
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10 * ws)),
            padding:
            EdgeInsets.symmetric(horizontal: 14 * ws, vertical: 4 * hs),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 22 * ws,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 4 * hs),
              ),
              onTap: () {
                if (controller.text == '0') controller.clear();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroDonutPainter2 extends CustomPainter {
  final int protein, fat, carbs, totalG;
  final double progress;

  _MacroDonutPainter2({
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.totalG,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFE5E7EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

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
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round);
      start += sweep;
    }

    draw(protein, AppTheme.primaryGreen);
    draw(fat, const Color(0xFFFF5252));
    draw(carbs, const Color(0xFF5C6BC0));
  }

  @override
  bool shouldRepaint(covariant _MacroDonutPainter2 old) => true;
}

// ─── Image Source Sheet ───────────────────────────────────────────────────────
class _ImageSourceSheet extends StatelessWidget {
  static const double _refW = 360;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final ws = screenWidth / _refW;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20 * ws, 16, 20 * ws, 20 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36 * ws,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              _SrcTile(
                label: 'Gallery',
                icon: Icons.photo_library_outlined,
                onTap: () => Navigator.pop(context, ImageSource.gallery),
                ws: ws,
              ),
              SizedBox(width: 12 * ws),
              _SrcTile(
                label: 'Camera',
                icon: Icons.camera_alt_outlined,
                onTap: () => Navigator.pop(context, ImageSource.camera),
                ws: ws,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SrcTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double ws;
  const _SrcTile(
      {required this.label,
        required this.icon,
        required this.onTap,
        required this.ws});

  @override
  Widget build(BuildContext context) {
    final hs = MediaQuery.of(context).size.height / 800;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 18 * hs),
          decoration: BoxDecoration(
            color: AppTheme.lightGreen.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14 * ws),
            border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24 * ws, color: AppTheme.primaryGreen),
              SizedBox(height: 6 * hs),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 12 * ws,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textDark)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Add Ingredient Dialog ────────────────────────────────────────────────────
class _AddIngredientDialog extends StatefulWidget {
  final void Function(String name, String qty) onAdd;
  const _AddIngredientDialog({required this.onAdd});

  @override
  State<_AddIngredientDialog> createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends State<_AddIngredientDialog> {
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = MediaQuery.of(context).size.width / 360;
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16 * ws)),
      title: Text(
        'Add Ingredient',
        style: GoogleFonts.poppins(
            fontSize: 16 * ws,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              hintText: 'Ingredient name',
              hintStyle: GoogleFonts.poppins(color: const Color(0xFF9CA3AF)),
              filled: true,
              fillColor: AppTheme.bgLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10 * ws),
                borderSide: BorderSide.none,
              ),
            ),
            style: GoogleFonts.poppins(fontSize: 14 * ws),
          ),
          SizedBox(height: 10 * (MediaQuery.of(context).size.height / 800)),
          TextField(
            controller: _qtyCtrl,
            decoration: InputDecoration(
              hintText: 'Quantity (e.g. 1 cup)',
              hintStyle: GoogleFonts.poppins(color: const Color(0xFF9CA3AF)),
              filled: true,
              fillColor: AppTheme.bgLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10 * ws),
                borderSide: BorderSide.none,
              ),
            ),
            style: GoogleFonts.poppins(fontSize: 14 * ws),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF6B7280))),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameCtrl.text.trim().isNotEmpty) {
              widget.onAdd(_nameCtrl.text.trim(), _qtyCtrl.text.trim());
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10 * ws)),
            elevation: 0,
          ),
          child: Text('Add',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ─── Model ────────────────────────────────────────────────────────────────────
class _IngredientItem {
  final String name;
  final String qty;
  const _IngredientItem({required this.name, required this.qty});
}