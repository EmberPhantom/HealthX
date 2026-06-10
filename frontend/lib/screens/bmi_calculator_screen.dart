import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';

class BmiCalculatorScreen extends StatefulWidget {
  const BmiCalculatorScreen({super.key});
  @override
  State<BmiCalculatorScreen> createState() => _BmiCalculatorScreenState();
}

class _BmiCalculatorScreenState extends State<BmiCalculatorScreen>
    with SingleTickerProviderStateMixin {
  // _weight is always stored internally in kg
  double _weight = 70.0;
  bool _useLbs = false;

  double _heightCm = 170.0;
  bool _useFeet = false;
  double? _bmi;
  String _category = '';
  Color _categoryColor = AppTheme.primaryGreen;

  late AnimationController _needleCtrl;
  late Animation<double> _needleAnim;
  double _targetAngle = -math.pi / 2;

  @override
  void initState() {
    super.initState();
    _needleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _needleAnim = Tween<double>(
      begin: -math.pi / 2,
      end: -math.pi / 2,
    ).animate(CurvedAnimation(parent: _needleCtrl, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _needleCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  // Slider operates in the display unit, but _weight is always kg internally
  double get _weightSliderValue => _useLbs ? _weight * 2.20462 : _weight;
  double get _weightSliderMin => _useLbs ? 2.0 : 1.0;
  double get _weightSliderMax => _useLbs ? 440.0 : 200.0;

  String get _weightDisplay {
    if (_useLbs) {
      return '${(_weight * 2.20462).round()} lbs';
    }
    return '${_weight.round()} kg';
  }

  String get _heightDisplay {
    if (_useFeet) {
      final totalInches = _heightCm / 2.54;
      final feet = totalInches ~/ 12;
      final inches = (totalInches % 12).round();
      return "$feet' $inches\"";
    }
    return '${_heightCm.round()} cm';
  }

  void _onWeightChanged(double v) {
    setState(() {
      // convert display unit back to kg for internal storage
      _weight = _useLbs ? v / 2.20462 : v;
    });
  }

  void _calculateBmi() {
    final hm = _heightCm / 100.0;
    final bmi = _weight / (hm * hm);
    String cat;
    Color col;

    final normalized = ((bmi.clamp(10.0, 40.0)) - 10.0) / 30.0;
    final angle = -math.pi + normalized * math.pi;

    if (bmi < 18.5) {
      cat = 'Under Weight';
      col = const Color(0xFF3B82F6);
    } else if (bmi < 25.0) {
      cat = 'Normal';
      col = AppTheme.primaryGreen;
    } else if (bmi < 30.0) {
      cat = 'Over Weight';
      col = AppTheme.orange;
    } else {
      cat = 'Obese';
      col = AppTheme.red;
    }

    _needleAnim = Tween<double>(
      begin: _needleAnim.value,
      end: angle,
    ).animate(CurvedAnimation(parent: _needleCtrl, curve: Curves.easeOutBack));
    _needleCtrl
      ..reset()
      ..forward();

    setState(() {
      _bmi = bmi;
      _category = cat;
      _categoryColor = col;
      _targetAngle = angle;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppTheme.textDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('BMI',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: AppTheme.textDark)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                children: [
                  // ── Gauge Card ────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _needleAnim,
                          builder: (_, __) => CustomPaint(
                            painter: _GaugePainter(
                              needleAngle: _needleAnim.value,
                              hasBmi: _bmi != null,
                            ),
                            size: Size(
                                MediaQuery.of(context).size.width - 60, 160),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_bmi != null) ...[
                          Text(
                            _bmi!.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: _categoryColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 5),
                            decoration: BoxDecoration(
                              color: _categoryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _category,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _categoryColor,
                              ),
                            ),
                          ),
                        ] else ...[
                          Text(
                            '– –',
                            style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textLight),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap Calculate to see your BMI',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: AppTheme.textLight),
                          ),
                        ],
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Weight Card (with kg / lbs toggle) ───────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row with unit chips
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('WEIGHT',
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textMedium,
                                    letterSpacing: 0.8)),
                            Row(children: [
                              _UnitChip(
                                label: 'kg',
                                selected: !_useLbs,
                                onTap: () => setState(() => _useLbs = false),
                              ),
                              const SizedBox(width: 6),
                              _UnitChip(
                                label: 'lbs',
                                selected: _useLbs,
                                onTap: () => setState(() => _useLbs = true),
                              ),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.bgLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: Text(
                              _weightDisplay,
                              style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark),
                            ),
                          ),
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppTheme.primaryGreen,
                            inactiveTrackColor:
                            AppTheme.primaryGreen.withOpacity(0.18),
                            thumbColor: AppTheme.primaryGreen,
                            overlayColor:
                            AppTheme.primaryGreen.withOpacity(0.1),
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 9),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _weightSliderValue.clamp(
                                _weightSliderMin, _weightSliderMax),
                            min: _weightSliderMin,
                            max: _weightSliderMax,
                            onChanged: _onWeightChanged,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Height Card (cm / feet) ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('HEIGHT',
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textMedium,
                                    letterSpacing: 0.8)),
                            Row(children: [
                              _UnitChip(
                                  label: 'cm',
                                  selected: !_useFeet,
                                  onTap: () =>
                                      setState(() => _useFeet = false)),
                              const SizedBox(width: 6),
                              _UnitChip(
                                  label: 'feet',
                                  selected: _useFeet,
                                  onTap: () =>
                                      setState(() => _useFeet = true)),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.bgLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: Text(
                              _heightDisplay,
                              style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark),
                            ),
                          ),
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF3B82F6),
                            inactiveTrackColor:
                            const Color(0xFF3B82F6).withOpacity(0.18),
                            thumbColor: const Color(0xFF3B82F6),
                            overlayColor:
                            const Color(0xFF3B82F6).withOpacity(0.1),
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 9),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _heightCm.clamp(1.0, 250.0),
                            min: 1,
                            max: 250,
                            onChanged: (v) => setState(() => _heightCm = v),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // ── Calculate Button ──────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _calculateBmi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text('Calculate BMI',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Unit Chip ────────────────────────────────────────────────────────────────
class _UnitChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _UnitChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: selected ? AppTheme.primaryGreen : AppTheme.divider),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.textMedium)),
      ),
    );
  }
}

// ─── Gauge Painter ────────────────────────────────────────────────────────────
class _GaugePainter extends CustomPainter {
  final double needleAngle;
  final bool hasBmi;

  _GaugePainter({required this.needleAngle, required this.hasBmi});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.92;
    final r = size.width * 0.38;
    const trackW = 26.0;

    final segs = [
      _Seg('<18.5\nUnder\nWeight', const Color(0xFF3B82F6), 0.00, 0.28),
      _Seg('18.5 - 24.9\nNormal', AppTheme.primaryGreen, 0.28, 0.56),
      _Seg('25 - 29.9\nOver\nWeight', AppTheme.orange, 0.56, 0.78),
      _Seg('>30\nObese', AppTheme.red, 0.78, 1.00),
    ];

    for (final seg in segs) {
      final startAngle = -math.pi + seg.f0 * math.pi;
      final sweepAngle = (seg.f1 - seg.f0) * math.pi;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = seg.color.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = trackW + 6
          ..strokeCap = StrokeCap.butt,
      );

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = seg.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = trackW
          ..strokeCap = StrokeCap.butt,
      );
    }

    for (final seg in segs) {
      for (final f in [seg.f0, seg.f1]) {
        if (f == 0.0 || f == 1.0) continue;
        final angle = -math.pi + f * math.pi;
        final inner = r - trackW / 2 - 3;
        final outer = r + trackW / 2 + 3;
        canvas.drawLine(
          Offset(cx + inner * math.cos(angle), cy + inner * math.sin(angle)),
          Offset(cx + outer * math.cos(angle), cy + outer * math.sin(angle)),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2.5,
        );
      }
    }

    for (final seg in segs) {
      final mid = -math.pi + (seg.f0 + seg.f1) / 2 * math.pi;
      final labelR = r + trackW / 2 + 18;
      final lx = cx + labelR * math.cos(mid);
      final ly = cy + labelR * math.sin(mid);

      final tp = TextPainter(
        text: TextSpan(
          text: seg.label,
          style: TextStyle(
            fontSize: 7.5,
            color: seg.color,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 54);

      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
    }

    if (hasBmi) {
      final needleLen = r - trackW / 2 - 6;

      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + needleLen * math.cos(needleAngle),
            cy + needleLen * math.sin(needleAngle)),
        Paint()
          ..color = Colors.black.withOpacity(0.12)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );

      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + needleLen * math.cos(needleAngle),
            cy + needleLen * math.sin(needleAngle)),
        Paint()
          ..color = const Color(0xFF1D4ED8)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );

      canvas.drawCircle(
        Offset(cx + needleLen * math.cos(needleAngle),
            cy + needleLen * math.sin(needleAngle)),
        4.5,
        Paint()..color = const Color(0xFF1D4ED8),
      );

      canvas.drawCircle(
        Offset(cx, cy),
        9,
        Paint()..color = const Color(0xFF1D4ED8).withOpacity(0.15),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        5,
        Paint()..color = const Color(0xFF1D4ED8),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        2.5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.needleAngle != needleAngle || old.hasBmi != hasBmi;
}

class _Seg {
  final String label;
  final Color color;
  final double f0, f1;
  const _Seg(this.label, this.color, this.f0, this.f1);
}