import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../theme/theme.dart';
import 'wellness_goals_screen.dart' show OnboardingProvider;

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS & CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

enum _HealthLevel { low, normal, high }

// ─────────────────────────────────────────────────────────────────────────────
// MEASUREMENTS SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class MeasurementsScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const MeasurementsScreen(
      {super.key, required this.onNext, required this.onBack});

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;

  static const double _refW = 360;
  static const double _refH = 800;

  _HealthLevel? _bloodPressure = _HealthLevel.normal;
  _HealthLevel? _bloodGlucose;
  _HealthLevel? _totalCholesterol;
  _HealthLevel? _ldlCholesterol;
  _HealthLevel? _hdlCholesterol;

  static const _allergyOptions = [
    'Milk (Dairy)', 'Peanuts', 'Tree Nuts', 'Soy',
    'Wheat', 'Eggs', 'Fish', 'Shellfish',
  ];
  final Set<String> _selectedAllergies = {};

  int _physicalActivity = 3;

  static const _activityNames = [
    'Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active', 'Extremely Active',
  ];
  static const _activityDescriptions = [
    'Little or no exercise. Mostly sitting throughout the day.',
    'Light exercise 1–3 days/week. Short walks, light chores.',
    'Active 3–5 days/week via brisk walking, yoga or dancing.',
    'Hard exercise 6–7 days/week. Regular gym, cycling or sports.',
    'Very hard exercise twice daily. Athlete-level training.',
  ];
  static const _activityIcons = [
    Icons.weekend_rounded,
    Icons.directions_walk_rounded,
    Icons.directions_run_rounded,
    Icons.fitness_center_rounded,
    Icons.bolt_rounded,
  ];
  static const _activityMultipliers = ['×1.2', '×1.375', '×1.55', '×1.725', '×1.9'];

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380))
      ..forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  double _calcBmi(double weight, double height) {
    if (height <= 0) return 0;
    final hM = height / 100;
    return weight / (hM * hM);
  }

  String _bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal Weight';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return const Color(0xFF3B82F6);
    if (bmi < 25) return const Color(0xFF10B981);
    if (bmi < 30) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    final bmi = _calcBmi(provider.weight, provider.height);

    return LayoutBuilder(builder: (context, constraints) {
      final screenWidth = constraints.maxWidth;
      final screenHeight = MediaQuery.of(context).size.height;
      final ws = screenWidth / _refW;
      final hs = screenHeight / _refH;
      final hp = screenWidth < 600 ? 18.0 * ws : 40.0 * ws;

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFB),
        body: SafeArea(
          child: FadeTransition(
            opacity: _entry,
            child: Column(
              children: [
                // ── Header ───────────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(hp, 12 * hs, hp, 0),
                  child: Row(
                    children: [
                      _BackBtn(onTap: widget.onBack, ws: ws),
                      SizedBox(width: 12 * ws),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Measurements',
                              style: GoogleFonts.inter(
                                fontSize: 19 * ws,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Help us personalise your plan',
                              style: GoogleFonts.inter(
                                fontSize: 12 * ws,
                                color: AppTheme.textDark.withOpacity(0.42),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Scrollable body ──────────────────────────────────────────
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(hp, 14 * hs, hp, 8 * hs),
                    children: [
                      _MeasCard(
                        label: 'Weight',
                        icon: Icons.monitor_weight_outlined,
                        value: provider.weight,
                        min: 30, max: 150, unit: 'kg',
                        accentColor: const Color(0xFF10B981),
                        onChanged: (v) => provider.weight = v,
                        ws: ws, hs: hs,
                      ),
                      SizedBox(height: 10 * hs),

                      _MeasCard(
                        label: 'Height',
                        icon: Icons.height_rounded,
                        value: provider.height,
                        min: 50, max: 272, unit: 'cm',
                        accentColor: const Color(0xFF059669),
                        onChanged: (v) => provider.height = v,
                        ws: ws, hs: hs,
                      ),
                      SizedBox(height: 12 * hs),

                      _BmiCard(
                        bmi: bmi,
                        bmiColor: _bmiColor(bmi),
                        category: _bmiCategory(bmi),
                        ws: ws, hs: hs,
                      ),
                      SizedBox(height: 20 * hs),

                      _SectionLabel(
                          icon: Icons.favorite_border_rounded,
                          label: 'Health Vitals',
                          ws: ws),
                      SizedBox(height: 10 * hs),
                      _HealthVitalsCard(
                        bloodPressure: _bloodPressure,
                        bloodGlucose: _bloodGlucose,
                        totalCholesterol: _totalCholesterol,
                        ldlCholesterol: _ldlCholesterol,
                        hdlCholesterol: _hdlCholesterol,
                        onBPChanged: (v) =>
                            setState(() => _bloodPressure = v),
                        onBGChanged: (v) =>
                            setState(() => _bloodGlucose = v),
                        onTCChanged: (v) =>
                            setState(() => _totalCholesterol = v),
                        onLDLChanged: (v) =>
                            setState(() => _ldlCholesterol = v),
                        onHDLChanged: (v) =>
                            setState(() => _hdlCholesterol = v),
                        ws: ws, hs: hs,
                      ),
                      SizedBox(height: 20 * hs),

                      _SectionLabel(
                          icon: Icons.no_food_outlined,
                          label: 'Food Allergies',
                          ws: ws),
                      SizedBox(height: 10 * hs),
                      _AllergiesCard(
                        options: _allergyOptions,
                        selected: _selectedAllergies,
                        onToggle: (a) => setState(() {
                          if (_selectedAllergies.contains(a)) {
                            _selectedAllergies.remove(a);
                          } else {
                            _selectedAllergies.add(a);
                          }
                        }),
                        ws: ws, hs: hs,
                      ),
                      SizedBox(height: 20 * hs),

                      _SectionLabel(
                          icon: Icons.bolt_rounded,
                          label: 'Activity Level',
                          ws: ws),
                      SizedBox(height: 10 * hs),
                      _ActivitySelectorCard(
                        level: _physicalActivity,
                        names: _activityNames,
                        descriptions: _activityDescriptions,
                        icons: _activityIcons,
                        multipliers: _activityMultipliers,
                        onChanged: (v) {
                          HapticFeedback.lightImpact();
                          setState(() => _physicalActivity = v);
                          provider.activityLevel = v;
                        },
                        ws: ws, hs: hs,
                      ),
                      SizedBox(height: 28 * hs),
                    ],
                  ),
                ),

                // ── Footer ───────────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(hp, 0, hp, 20 * hs),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StepBar(current: 1, total: 4, ws: ws, hs: hs),
                      SizedBox(height: 14 * hs),
                      _NextBtn(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          widget.onNext();
                        },
                        ws: ws, hs: hs,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final double ws;
  const _SectionLabel({required this.icon, required this.label, required this.ws});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3 * ws, height: 16,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF10B981), Color(0xFF047857)],
            ),
            borderRadius: BorderRadius.circular(2 * ws),
          ),
        ),
        SizedBox(width: 7 * ws),
        Icon(icon, size: 15 * ws, color: AppTheme.primaryGreen),
        SizedBox(width: 6 * ws),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14 * ws,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MEASUREMENT CARD
// ─────────────────────────────────────────────────────────────────────────────

class _MeasCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final double value;
  final double min, max;
  final String unit;
  final Color accentColor;
  final ValueChanged<double> onChanged;
  final double ws, hs;

  const _MeasCard({
    required this.label, required this.icon, required this.value,
    required this.min, required this.max, required this.unit,
    required this.accentColor, required this.onChanged,
    required this.ws, required this.hs,
  });

  @override
  State<_MeasCard> createState() => _MeasCardState();
}

class _MeasCardState extends State<_MeasCard> with SingleTickerProviderStateMixin {
  static const double _kPx = 10.0;

  late final ScrollController _scroll;
  late final AnimationController _pop;
  double _display = 0;
  double _popScale = 1.0;
  bool _userDragging = false;
  bool _snapping = false;

  @override
  void initState() {
    super.initState();
    _display = widget.value;
    _pop = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _pop.addListener(() {
      final t = _pop.value;
      setState(() => _popScale = 1.0 + 0.05 * math.sin(t * math.pi));
    });
    _scroll = ScrollController(initialScrollOffset: _toOffset(widget.value));
    _scroll.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _MeasCard old) {
    super.didUpdateWidget(old);
    if (!_userDragging && !_snapping && old.value != widget.value) {
      _display = widget.value;
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _toOffset(widget.value),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _pop.dispose();
    super.dispose();
  }

  double _toOffset(double v) => (v - widget.min) * _kPx;

  void _onScroll() {
    if (!_userDragging || _snapping) return;
    final r = (_scroll.offset / _kPx + widget.min)
        .roundToDouble()
        .clamp(widget.min, widget.max);
    if (r != _display) {
      HapticFeedback.selectionClick();
      setState(() => _display = r);
      widget.onChanged(r);
      _pop.forward(from: 0);
    }
  }

  void _scheduleSnap() {
    if (_snapping) return;
    _snapping = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) {
        _snapping = false;
        return;
      }
      final target = _toOffset(_display);
      if ((_scroll.offset - target).abs() < 0.5) {
        _snapping = false;
        return;
      }
      _scroll
          .animateTo(target,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic)
          .then((_) => _snapping = false);
    });
  }

  void _step(int d) {
    final n = (_display + d).clamp(widget.min, widget.max);
    if (n == _display) return;
    HapticFeedback.selectionClick();
    setState(() => _display = n);
    widget.onChanged(n);
    _pop.forward(from: 0);
    if (_scroll.hasClients && !_snapping) {
      _snapping = true;
      _scroll
          .animateTo(_toOffset(n),
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic)
          .then((_) => _snapping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ws = widget.ws;
    final hs = widget.hs;
    final pct = (_display - widget.min) / (widget.max - widget.min);
    final ticks = (widget.max - widget.min).round();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * ws),
        border: Border.all(color: const Color(0xFFEEF1F5), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14 * ws, 14 * hs, 12 * ws, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34 * ws,
                  height: 34 * ws,
                  decoration: BoxDecoration(
                    color: widget.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10 * ws),
                  ),
                  child: Icon(widget.icon,
                      color: widget.accentColor, size: 17 * ws),
                ),
                SizedBox(width: 8 * ws),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: GoogleFonts.inter(
                          fontSize: 11 * ws,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textDark.withOpacity(0.4),
                        ),
                      ),
                      AnimatedScale(
                        scale: _popScale,
                        duration: const Duration(milliseconds: 180),
                        alignment: Alignment.centerLeft,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: _display.round().toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 28 * ws,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textDark,
                                  letterSpacing: -1,
                                  height: 1.0,
                                ),
                              ),
                              TextSpan(
                                text: ' ${widget.unit}',
                                style: GoogleFonts.inter(
                                  fontSize: 13 * ws,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textDark.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.clip,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    _StepperBtn(
                      icon: Icons.add_rounded,
                      color: widget.accentColor,
                      onTap: () => _step(1),
                      ws: ws,
                    ),
                    SizedBox(height: 4 * hs),
                    _StepperBtn(
                      icon: Icons.remove_rounded,
                      color: widget.accentColor,
                      onTap: () => _step(-1),
                      ws: ws,
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 10 * hs),

          ClipRect(
            child: SizedBox(
              height: 52 * hs,
              child: NotificationListener<ScrollStartNotification>(
                onNotification: (n) {
                  if (n.dragDetails != null) _userDragging = true;
                  return false;
                },
                child: NotificationListener<ScrollEndNotification>(
                  onNotification: (n) {
                    if (_userDragging) {
                      _userDragging = false;
                      _scheduleSnap();
                    }
                    return true;
                  },
                  child: LayoutBuilder(builder: (ctx, bc) {
                    final trackW =
                    bc.maxWidth.isFinite ? bc.maxWidth : 200.0;
                    final half = trackW / 2;
                    return SingleChildScrollView(
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: half),
                        child: RepaintBoundary(
                          child: CustomPaint(
                            size: Size(ticks * _kPx, 52 * hs),
                            painter: _RulerPainter(
                              ticks: ticks,
                              current: (_display - widget.min).round(),
                              accent: widget.accentColor,
                              spacing: _kPx,
                              minVal: widget.min.round(),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(14 * ws, 4 * hs, 14 * ws, 12 * hs),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3 * ws),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 3,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(widget.accentColor),
                  ),
                ),
                SizedBox(height: 4 * hs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${widget.min.round()} ${widget.unit}',
                        style: GoogleFonts.inter(
                            fontSize: 10 * ws,
                            color: AppTheme.textDark.withOpacity(0.28)),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${widget.max.round()} ${widget.unit}',
                        style: GoogleFonts.inter(
                            fontSize: 10 * ws,
                            color: AppTheme.textDark.withOpacity(0.28)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RULER PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _RulerPainter extends CustomPainter {
  final int ticks;
  final int current;
  final Color accent;
  final double spacing;
  final int minVal;

  const _RulerPainter({
    required this.ticks, required this.current, required this.accent,
    required this.spacing, required this.minVal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    for (int i = 0; i <= ticks; i++) {
      final x = i * spacing;
      final val = minVal + i;
      final isCur = i == current;
      final isMaj = val % 10 == 0;
      final isMid = val % 5 == 0 && !isMaj;

      final double h;
      final double w;
      final Color c;

      if (isCur) {
        h = 32; w = 2.5; c = accent;
      } else if (isMaj) {
        h = 20; w = 1.5; c = const Color(0xFFB0B8C4);
      } else if (isMid) {
        h = 12; w = 1.0; c = const Color(0xFFCDD3DB);
      } else {
        h = 7; w = 0.8; c = const Color(0xFFE2E6EB);
      }

      p.color = c;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x - w / 2, 2, w, h), const Radius.circular(2)),
        p,
      );
      if (isCur) {
        p.color = accent;
        canvas.drawCircle(Offset(x, h + 8), 2.2, p);
      }
      if (isMaj) {
        final tp = TextPainter(
          text: TextSpan(
            text: val.toString(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: isCur ? FontWeight.w700 : FontWeight.w500,
              color: isCur ? accent : const Color(0xFFB8BEC7),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, 38));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter old) =>
      old.current != current || old.accent != accent;
}

// ─────────────────────────────────────────────────────────────────────────────
// BMI CARD
// ─────────────────────────────────────────────────────────────────────────────

class _BmiCard extends StatelessWidget {
  final double bmi;
  final Color bmiColor;
  final String category;
  final double ws, hs;

  const _BmiCard(
      {required this.bmi, required this.bmiColor, required this.category,
        required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16 * ws, 14 * hs, 16 * ws, 14 * hs),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * ws),
        border: Border.all(color: const Color(0xFFEEF1F5), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BMI',
                  style: GoogleFonts.inter(
                    fontSize: 11 * ws,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF10B981),
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'Body Mass Index',
                  style: GoogleFonts.inter(
                    fontSize: 10 * ws,
                    color: AppTheme.textDark.withOpacity(0.38),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4 * hs),
                Text(
                  bmi > 0 ? bmi.toStringAsFixed(1) : '--',
                  style: GoogleFonts.inter(
                    fontSize: 32 * ws,
                    fontWeight: FontWeight.w800,
                    color: bmi > 0
                        ? bmiColor
                        : AppTheme.textDark.withOpacity(0.2),
                    letterSpacing: -1.5,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                ),
                if (bmi > 0)
                  Container(
                    margin: EdgeInsets.only(top: 4 * hs),
                    padding: EdgeInsets.symmetric(
                        horizontal: 7 * ws, vertical: 3 * hs),
                    decoration: BoxDecoration(
                      color: bmiColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6 * ws),
                    ),
                    child: Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10.5 * ws,
                        fontWeight: FontWeight.w600,
                        color: bmiColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 12 * ws),
          Expanded(
            flex: 5,
            child: _BmiGaugeCompact(bmi: bmi, ws: ws, hs: hs),
          ),
        ],
      ),
    );
  }
}

class _BmiGaugeCompact extends StatelessWidget {
  final double bmi;
  final double ws, hs;
  const _BmiGaugeCompact({required this.bmi, required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    final pct = ((bmi - 15) / 25).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(builder: (ctx, bc) {
          final trackW =
          (bc.maxWidth.isFinite && bc.maxWidth > 10) ? bc.maxWidth : 100.0;
          final cursorX = (pct * trackW).clamp(3.0, trackW - 3.0);
          return SizedBox(
            height: 20 * hs,
            width: trackW,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  bottom: 4,
                  left: 0, right: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4 * ws),
                    child: Container(
                      height: 8 * hs,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF3B82F6),
                            Color(0xFF10B981),
                            Color(0xFFF59E0B),
                            Color(0xFFEF4444),
                          ],
                          stops: [0.0, 0.233, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                if (bmi > 0)
                  Positioned(
                    bottom: 0,
                    left: cursorX - 3,
                    child: Container(
                      width: 6 * ws,
                      height: 20 * hs,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3 * ws),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.22),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
        SizedBox(height: 5 * hs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['15', '18.5', '25', '30', '40']
              .map((l) => Text(l,
              style: GoogleFonts.inter(
                fontSize: 9 * ws,
                color: AppTheme.textDark.withOpacity(0.38),
              )))
              .toList(),
        ),
        SizedBox(height: 6 * hs),
        Row(
          children: [
            _ZoneChip('Under', const Color(0xFF3B82F6), ws: ws, hs: hs),
            SizedBox(width: 4 * ws),
            _ZoneChip('Normal', const Color(0xFF10B981), ws: ws, hs: hs),
            SizedBox(width: 4 * ws),
            _ZoneChip('Over', const Color(0xFFF59E0B), ws: ws, hs: hs),
            SizedBox(width: 4 * ws),
            _ZoneChip('Obese', const Color(0xFFEF4444), ws: ws, hs: hs),
          ],
        ),
      ],
    );
  }
}

class _ZoneChip extends StatelessWidget {
  final String label;
  final Color color;
  final double ws, hs;
  const _ZoneChip(this.label, this.color, {required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2 * hs),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4 * ws),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 8.5 * ws,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEALTH VITALS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _HealthVitalsCard extends StatelessWidget {
  final _HealthLevel? bloodPressure, bloodGlucose, totalCholesterol,
      ldlCholesterol, hdlCholesterol;
  final ValueChanged<_HealthLevel?> onBPChanged, onBGChanged, onTCChanged,
      onLDLChanged, onHDLChanged;
  final double ws, hs;

  const _HealthVitalsCard({
    required this.bloodPressure, required this.bloodGlucose,
    required this.totalCholesterol, required this.ldlCholesterol,
    required this.hdlCholesterol, required this.onBPChanged,
    required this.onBGChanged, required this.onTCChanged,
    required this.onLDLChanged, required this.onHDLChanged,
    required this.ws, required this.hs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * ws),
        border: Border.all(color: const Color(0xFFEEF1F5), width: 1.0),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          _VitalRow(label: 'Blood Pressure',    icon: Icons.favorite_rounded,      color: const Color(0xFFEF4444), selected: bloodPressure,    onChanged: onBPChanged,  isLast: false, ws: ws, hs: hs),
          _VitalRow(label: 'Blood Glucose',     icon: Icons.water_drop_outlined,    color: const Color(0xFF3B82F6), selected: bloodGlucose,     onChanged: onBGChanged,  isLast: false, ws: ws, hs: hs),
          _VitalRow(label: 'Total Cholesterol', icon: Icons.monitor_heart_outlined, color: const Color(0xFFF59E0B), selected: totalCholesterol, onChanged: onTCChanged,  isLast: false, ws: ws, hs: hs),
          _VitalRow(label: 'LDL Cholesterol',   icon: Icons.trending_down_rounded,  color: const Color(0xFFEF4444), selected: ldlCholesterol,   onChanged: onLDLChanged, isLast: false, ws: ws, hs: hs),
          _VitalRow(label: 'HDL Cholesterol',   icon: Icons.trending_up_rounded,    color: const Color(0xFF10B981), selected: hdlCholesterol,   onChanged: onHDLChanged, isLast: true,  ws: ws, hs: hs),
        ],
      ),
    );
  }
}

class _VitalRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final _HealthLevel? selected;
  final ValueChanged<_HealthLevel?> onChanged;
  final bool isLast;
  final double ws, hs;

  const _VitalRow({
    required this.label, required this.icon, required this.color,
    required this.selected, required this.onChanged, required this.isLast,
    required this.ws, required this.hs,
  });

  static const _levels = [_HealthLevel.low, _HealthLevel.normal, _HealthLevel.high];
  static const _labels = ['Low', 'Normal', 'High'];
  static const _chipColors = [Color(0xFF3B82F6), Color(0xFF10B981), Color(0xFFEF4444)];

  Color _selectedColor() => _chipColors[_levels.indexOf(selected!)];
  String _selectedLabel() => _labels[_levels.indexOf(selected!)];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(14 * ws, 11 * hs, 14 * ws, 11 * hs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 26 * ws, height: 26 * ws,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(7 * ws),
                    ),
                    child: Icon(icon, size: 13 * ws, color: color),
                  ),
                  SizedBox(width: 9 * ws),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13 * ws,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  if (selected != null)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 170),
                      padding: EdgeInsets.symmetric(
                          horizontal: 8 * ws, vertical: 2 * hs),
                      decoration: BoxDecoration(
                        color: _selectedColor().withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20 * ws),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5 * ws, height: 5 * ws,
                            decoration: BoxDecoration(
                              color: _selectedColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 4 * ws),
                          Text(
                            _selectedLabel(),
                            style: GoogleFonts.inter(
                              fontSize: 11 * ws,
                              fontWeight: FontWeight.w600,
                              color: _selectedColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8 * hs),
              SizedBox(
                height: 30 * hs,
                child: Row(
                  children: List.generate(_levels.length, (i) {
                    final lvl = _levels[i];
                    final lbl = _labels[i];
                    final chipColor = _chipColors[i];
                    final isOn = selected == lvl;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onChanged(isOn ? null : lvl);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 170),
                          margin: EdgeInsets.only(left: i == 0 ? 0 : 5 * ws),
                          decoration: BoxDecoration(
                            color: isOn
                                ? chipColor.withOpacity(0.09)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8 * ws),
                            border: Border.all(
                              color: isOn ? chipColor : const Color(0xFFE5E7EB),
                              width: 1.0,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              lbl,
                              style: GoogleFonts.inter(
                                fontSize: 12 * ws,
                                fontWeight: isOn
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isOn
                                    ? chipColor
                                    : AppTheme.textDark.withOpacity(0.38),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
              height: 1,
              thickness: 1,
              color: const Color(0xFFF0F2F5),
              indent: 14 * ws,
              endIndent: 14 * ws),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ALLERGIES CARD
// ─────────────────────────────────────────────────────────────────────────────

class _AllergiesCard extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final double ws, hs;

  const _AllergiesCard(
      {required this.options, required this.selected, required this.onToggle,
        required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14 * ws),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * ws),
        border: Border.all(color: const Color(0xFFEEF1F5), width: 1.0),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Wrap(
        spacing: 7 * ws,
        runSpacing: 7 * hs,
        children: options.map((a) {
          final on = selected.contains(a);
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onToggle(a);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: EdgeInsets.symmetric(
                  horizontal: 11 * ws, vertical: 7 * hs),
              decoration: BoxDecoration(
                color: on
                    ? const Color(0xFF10B981).withOpacity(0.07)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10 * ws),
                border: Border.all(
                  color: on ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 15 * ws, height: 15 * ws,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on ? AppTheme.primaryGreen : Colors.transparent,
                      border: Border.all(
                        color: on
                            ? AppTheme.primaryGreen
                            : const Color(0xFFCDD3DB),
                        width: 1.5,
                      ),
                    ),
                    child: on
                        ? Icon(Icons.check_rounded,
                        size: 9 * ws, color: Colors.white)
                        : null,
                  ),
                  SizedBox(width: 6 * ws),
                  Text(
                    a,
                    style: GoogleFonts.inter(
                      fontSize: 12.5 * ws,
                      fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                      color: on
                          ? AppTheme.primaryGreen
                          : AppTheme.textDark.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVITY SELECTOR CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ActivitySelectorCard extends StatelessWidget {
  final int level;
  final List<String> names;
  final List<String> descriptions;
  final List<IconData> icons;
  final List<String> multipliers;
  final ValueChanged<int> onChanged;
  final double ws, hs;

  const _ActivitySelectorCard({
    required this.level, required this.names, required this.descriptions,
    required this.icons, required this.multipliers, required this.onChanged,
    required this.ws, required this.hs,
  });

  static const _colors = [
    Color(0xFF94A3B8), Color(0xFF34D399), Color(0xFF10B981),
    Color(0xFF059669), Color(0xFFF59E0B),
  ];

  @override
  Widget build(BuildContext context) {
    final idx = (level - 1).clamp(0, names.length - 1);
    final color = _colors[idx];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * ws),
        border: Border.all(color: const Color(0xFFEEF1F5), width: 1.0),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // Icon strip
          Padding(
            padding: EdgeInsets.fromLTRB(10 * ws, 12 * hs, 10 * ws, 0),
            child: Container(
              height: 48 * hs,
              padding: EdgeInsets.all(4 * ws),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14 * ws),
              ),
              child: Row(
                children: List.generate(icons.length, (i) {
                  final on = (i + 1) == level;
                  final c = _colors[i];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(i + 1),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        margin:
                        EdgeInsets.symmetric(horizontal: 1 * ws),
                        decoration: BoxDecoration(
                          color: on ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10 * ws),
                          boxShadow: on
                              ? [
                            BoxShadow(
                                color: c.withOpacity(0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ]
                              : null,
                        ),
                        child: Icon(
                          icons[i],
                          size: on ? 20 * ws : 17 * ws,
                          color: on
                              ? c
                              : AppTheme.textDark.withOpacity(0.28),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Detail row
          Padding(
            padding: EdgeInsets.fromLTRB(14 * ws, 10 * hs, 14 * ws, 14 * hs),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(12 * ws),
              decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(13 * ws),
                border: Border.all(color: color.withOpacity(0.18), width: 1),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40 * ws, height: 40 * ws,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(11 * ws),
                    ),
                    child: Icon(icons[idx], color: color, size: 20 * ws),
                  ),
                  SizedBox(width: 11 * ws),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, anim) =>
                              FadeTransition(opacity: anim, child: child),
                          child: Text(
                            names[idx],
                            key: ValueKey(idx),
                            style: GoogleFonts.inter(
                              fontSize: 13 * ws,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        SizedBox(height: 2 * hs),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, anim) =>
                              FadeTransition(opacity: anim, child: child),
                          child: Text(
                            descriptions[idx],
                            key: ValueKey(idx),
                            style: GoogleFonts.inter(
                              fontSize: 11.5 * ws,
                              height: 1.5,
                              color: AppTheme.textDark.withOpacity(0.52),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8 * ws),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                        horizontal: 8 * ws, vertical: 4 * hs),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8 * ws),
                    ),
                    child: Text(
                      multipliers[idx],
                      style: GoogleFonts.inter(
                        fontSize: 12 * ws,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Slider
          Padding(
            padding: EdgeInsets.fromLTRB(14 * ws, 0, 14 * ws, 14 * hs),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 5,
                    activeTrackColor: color,
                    inactiveTrackColor: const Color(0xFFE2E8F0),
                    thumbColor: color,
                    thumbShape: _ActivityThumb(color: color),
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: level.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      onChanged(v.round());
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10 * ws),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (i) {
                      final isOn = (i + 1) == level;
                      return Text(
                        '${i + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 11 * ws,
                          fontWeight:
                          isOn ? FontWeight.w700 : FontWeight.w400,
                          color: isOn
                              ? color
                              : AppTheme.textDark.withOpacity(0.35),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityThumb extends SliderComponentShape {
  final Color color;
  const _ActivityThumb({required this.color});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(36, 36);

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
        required Animation<double> enableAnimation,
        required bool isDiscrete,
        required TextPainter labelPainter,
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required TextDirection textDirection,
        required double value,
        required double textScaleFactor,
        required Size sizeWithOverflow}) {
    final canvas = context.canvas;
    canvas.drawCircle(
        center + const Offset(0, 2),
        11,
        Paint()
          ..color = color.withOpacity(0.2)
          ..maskFilter =
          const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawCircle(center, 11, Paint()..color = Colors.white);
    canvas.drawCircle(center, 8, Paint()..color = color);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _BackBtn extends StatefulWidget {
  final VoidCallback onTap;
  final double ws;
  const _BackBtn({required this.onTap, required this.ws});
  @override
  State<_BackBtn> createState() => _BackBtnState();
}

class _BackBtnState extends State<_BackBtn> {
  bool _d = false;
  @override
  Widget build(BuildContext context) {
    final ws = widget.ws;
    return GestureDetector(
      onTapDown: (_) => setState(() => _d = true),
      onTapUp: (_) {
        setState(() => _d = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _d = false),
      child: AnimatedScale(
        scale: _d ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: 38 * ws, height: 38 * ws,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11 * ws),
            border: Border.all(color: const Color(0xFFEEF1F5), width: 1.0),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, 2)),
            ],
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              size: 15 * ws, color: AppTheme.textDark),
        ),
      ),
    );
  }
}

class _StepperBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double ws;
  const _StepperBtn(
      {required this.icon, required this.color, required this.onTap, required this.ws});
  @override
  State<_StepperBtn> createState() => _StepperBtnState();
}

class _StepperBtnState extends State<_StepperBtn> {
  bool _d = false;
  @override
  Widget build(BuildContext context) {
    final ws = widget.ws;
    return GestureDetector(
      onTapDown: (_) => setState(() => _d = true),
      onTapUp: (_) {
        setState(() => _d = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _d = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        width: 28 * ws, height: 28 * ws,
        decoration: BoxDecoration(
          color: _d
              ? widget.color.withOpacity(0.2)
              : widget.color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(8 * ws),
        ),
        child: Icon(widget.icon, size: 14 * ws, color: widget.color),
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  final int current;
  final int total;
  final double ws, hs;
  const _StepBar(
      {required this.current, required this.total, required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        total,
            (i) => Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            height: 4 * hs,
            margin: EdgeInsets.only(right: i < total - 1 ? 6 * ws : 0),
            decoration: BoxDecoration(
              color: i <= current
                  ? const Color(0xFF10B981)
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4 * ws),
            ),
          ),
        ),
      ),
    );
  }
}

class _NextBtn extends StatefulWidget {
  final VoidCallback onTap;
  final double ws, hs;
  const _NextBtn({required this.onTap, required this.ws, required this.hs});
  @override
  State<_NextBtn> createState() => _NextBtnState();
}

class _NextBtnState extends State<_NextBtn> {
  bool _d = false;
  @override
  Widget build(BuildContext context) {
    final ws = widget.ws;
    final hs = widget.hs;
    return GestureDetector(
      onTapDown: (_) => setState(() => _d = true),
      onTapUp: (_) {
        setState(() => _d = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _d = false),
      child: AnimatedScale(
        scale: _d ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: double.infinity,
          height: 52 * hs,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF047857)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16 * ws),
            boxShadow: _d
                ? []
                : [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.30),
                blurRadius: 14,
                offset: const Offset(0, 6),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue',
                style: GoogleFonts.inter(
                  fontSize: 15 * ws,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.1,
                ),
              ),
              SizedBox(width: 8 * ws),
              Container(
                width: 26 * ws, height: 26 * ws,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8 * ws),
                ),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 14 * ws, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}