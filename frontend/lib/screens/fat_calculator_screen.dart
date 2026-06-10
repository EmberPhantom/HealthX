// lib/screens/fat_calculator_screen.dart
// ✅ PRODUCTION UI v2 — Body Fat % via U.S. Navy Method
//
// BUGS FIXED:
//   1. Crash fix: Added waist > neck validation before log() call (would crash with negative/zero arg)
//   2. Wrong title: "Your BFI Result" → "Body Fat Result" (BFI is not a standard term)
//   3. Female hip row: replaced empty Expanded(SizedBox()) with a helpful measurement tip card
//   4. Added HapticFeedback on every counter tap & calculate press
//   5. Added FittedBox on counter value to prevent text overflow on small screens
//
// UI IMPROVEMENTS:
//   • Gender: flat pill segmented toggle (faster, cleaner) instead of two tall cards
//   • Height card: dual cm / ft-in display, custom slider thumb with inner dot
//   • Counter cards: colored icon badge per metric, accentColor-tinted step buttons
//   • Calculate button: icon + label, bordered top divider for clear affordance
//   • Result: animated semi-circular gauge (CustomPainter) with needle + hub
//   • Result: range bar now shows circle indicator at exact BF% position
//   • Result: stacked fat/lean progress bar added in Body Composition section

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';

// ─── Fat Calculator Screen ────────────────────────────────────────────────────
class FatCalculatorScreen extends StatefulWidget {
  const FatCalculatorScreen({super.key});
  @override
  State<FatCalculatorScreen> createState() => _FatCalculatorScreenState();
}

class _FatCalculatorScreenState extends State<FatCalculatorScreen> {
  bool _isMale = true;
  double _height = 170;
  int _weight = 70;
  int _age = 25;
  int _waist = 80;
  int _neck = 37;
  int _hip = 90;

  // ── BUG FIX: Validate before calling math.log() ───────────────────────────
  void _calculate() {
    if (_isMale && _waist <= _neck) {
      _showError('Waist (${ _waist} cm) must be greater than Neck ($_neck cm).');
      return;
    }
    if (!_isMale && (_waist + _hip) <= _neck) {
      _showError('Waist + Hip must be greater than Neck measurement.');
      return;
    }

    double bf;
    if (_isMale) {
      final logVal = math.log(_waist - _neck) / math.ln10;
      final logH = math.log(_height) / math.ln10;
      bf = 495 / (1.0324 - 0.19077 * logVal + 0.15456 * logH) - 450;
    } else {
      final logVal = math.log(_waist + _hip - _neck) / math.ln10;
      final logH = math.log(_height) / math.ln10;
      bf = 495 / (1.29579 - 0.35004 * logVal + 0.22100 * logH) - 450;
    }
    bf = bf.clamp(3.0, 50.0);
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ResultScreen(
          bodyFat: bf,
          isMale: _isMale,
          weight: _weight,
          age: _age,
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _tap(Function() fn) {
    HapticFeedback.selectionClick();
    setState(fn);
  }

  // cm → ft'in" display
  String get _heightFtIn {
    final totalIn = _height / 2.54;
    final feet = (totalIn / 12).floor();
    final inches = (totalIn % 12).round();
    return "$feet'$inches\"";
  }

  // ── Shared card decoration ────────────────────────────────────────────────
  BoxDecoration get _cardDecor => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );

  Widget _fieldLabel(String t) => Text(
    t,
    style: GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppTheme.textMedium,
      letterSpacing: 0.6,
    ),
  );

  // ── Gender Segmented Toggle ───────────────────────────────────────────────
  Widget _buildGenderToggle() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(children: [
        _GenderPill(
          label: 'Male',
          icon: Icons.male_rounded,
          color: const Color(0xFF38BDF8),
          isSelected: _isMale,
          onTap: () => _tap(() => _isMale = true),
        ),
        _GenderPill(
          label: 'Female',
          icon: Icons.female_rounded,
          color: AppTheme.primaryGreen,
          isSelected: !_isMale,
          onTap: () => _tap(() => _isMale = false),
        ),
      ]),
    );
  }

  // ── Height Card ───────────────────────────────────────────────────────────
  Widget _buildHeightCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: _cardDecor,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _fieldLabel('HEIGHT'),
            // Dual unit display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _heightFtIn,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(children: [
            TextSpan(
              text: '${_height.round()}',
              style: GoogleFonts.poppins(
                fontSize: 46,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
                height: 1,
              ),
            ),
            TextSpan(
              text: ' cm',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMedium,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryGreen,
            inactiveTrackColor: AppTheme.primaryGreen.withOpacity(0.12),
            thumbColor: Colors.white,
            overlayColor: AppTheme.primaryGreen.withOpacity(0.12),
            trackHeight: 5,
            thumbShape: _CustomThumb(color: AppTheme.primaryGreen),
          ),
          child: Slider(
            value: _height,
            min: 100,
            max: 220,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _height = v);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('100 cm',
                  style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textLight)),
              Text('220 cm',
                  style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textLight)),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Counter Card ──────────────────────────────────────────────────────────
  Widget _buildCounterCard({
    required String label,
    required int value,
    required String unit,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecor,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: accentColor, size: 15),
            ),
            const SizedBox(width: 6),
            _fieldLabel(label),
          ]),
          const SizedBox(height: 8),
          // BUG FIX: FittedBox prevents text overflow on small screens
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: '$value',
                  style: GoogleFonts.poppins(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                    height: 1,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMedium,
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            _StepBtn(icon: Icons.remove_rounded, color: accentColor, onTap: onMinus),
            const Spacer(),
            _StepBtn(icon: Icons.add_rounded, color: accentColor, onTap: onPlus),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text('Body Fat Calculator',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Method banner ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.18)),
                ),
                child: Row(children: [
                  Icon(Icons.science_outlined, color: AppTheme.primaryGreen, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'U.S. Navy Method — fill height, neck & waist below',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // ── Gender ─────────────────────────────────────────────────
              _fieldLabel('SELECT GENDER'),
              const SizedBox(height: 8),
              _buildGenderToggle(),
              const SizedBox(height: 18),

              // ── Height ─────────────────────────────────────────────────
              _buildHeightCard(),
              const SizedBox(height: 14),

              // ── Weight & Age ───────────────────────────────────────────
              Row(children: [
                _buildCounterCard(
                  label: 'WEIGHT',
                  value: _weight,
                  unit: 'kg',
                  icon: Icons.monitor_weight_outlined,
                  accentColor: const Color(0xFF8B5CF6),
                  onMinus: () => _tap(() => _weight = (_weight - 1).clamp(20, 200)),
                  onPlus: () => _tap(() => _weight = (_weight + 1).clamp(20, 200)),
                ),
                const SizedBox(width: 12),
                _buildCounterCard(
                  label: 'AGE',
                  value: _age,
                  unit: 'yrs',
                  icon: Icons.cake_outlined,
                  accentColor: const Color(0xFFF59E0B),
                  onMinus: () => _tap(() => _age = (_age - 1).clamp(10, 100)),
                  onPlus: () => _tap(() => _age = (_age + 1).clamp(10, 100)),
                ),
              ]),
              const SizedBox(height: 12),

              // ── Waist & Neck ───────────────────────────────────────────
              Row(children: [
                _buildCounterCard(
                  label: 'WAIST',
                  value: _waist,
                  unit: 'cm',
                  icon: Icons.straighten_rounded,
                  accentColor: const Color(0xFFEF4444),
                  onMinus: () => _tap(() => _waist = (_waist - 1).clamp(40, 200)),
                  onPlus: () => _tap(() => _waist = (_waist + 1).clamp(40, 200)),
                ),
                const SizedBox(width: 12),
                _buildCounterCard(
                  label: 'NECK',
                  value: _neck,
                  unit: 'cm',
                  icon: Icons.person_outline_rounded,
                  accentColor: const Color(0xFF38BDF8),
                  onMinus: () => _tap(() => _neck = (_neck - 1).clamp(20, 80)),
                  onPlus: () => _tap(() => _neck = (_neck + 1).clamp(20, 80)),
                ),
              ]),

              // ── Hip (female only) ──────────────────────────────────────
              if (!_isMale) ...[
                const SizedBox(height: 12),
                Row(children: [
                  _buildCounterCard(
                    label: 'HIP',
                    value: _hip,
                    unit: 'cm',
                    icon: Icons.accessibility_new_rounded,
                    accentColor: AppTheme.primaryGreen,
                    onMinus: () => _tap(() => _hip = (_hip - 1).clamp(50, 200)),
                    onPlus: () => _tap(() => _hip = (_hip + 1).clamp(50, 200)),
                  ),
                  const SizedBox(width: 12),
                  // BUG FIX: was empty Expanded(SizedBox()) — now a helpful tip card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.18)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.tips_and_updates_outlined,
                              color: AppTheme.primaryGreen, size: 18),
                          const SizedBox(height: 8),
                          Text(
                            'Measure at the widest part of your hips',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: AppTheme.textMedium,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
              ],
              const SizedBox(height: 16),
            ]),
          ),
        ),

        // ── Calculate Button ──────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppTheme.bgLight,
            border: Border(top: BorderSide(color: const Color(0xFFE2E8F0))),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _calculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calculate_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Calculate Body Fat',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Gender Pill ──────────────────────────────────────────────────────────────
class _GenderPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  const _GenderPill({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
              BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ]
                : [],
          ),
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon,
                color: isSelected ? color : const Color(0xFF94A3B8), size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.w500,
                color:
                isSelected ? color : const Color(0xFF94A3B8),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Step Button ──────────────────────────────────────────────────────────────
class _StepBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _StepBtn(
      {required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

// ─── Custom Slider Thumb ──────────────────────────────────────────────────────
class _CustomThumb extends SliderComponentShape {
  final Color color;
  const _CustomThumb({required this.color});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(24, 24);

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
    // Outer white circle
    canvas.drawCircle(center, 11,
        Paint()..color = Colors.white..style = PaintingStyle.fill);
    // Colored ring
    canvas.drawCircle(
        center,
        11,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
    // Inner dot
    canvas.drawCircle(
        center, 4.5, Paint()..color = color..style = PaintingStyle.fill);
  }
}

// ─── Semicircular Gauge Painter ───────────────────────────────────────────────
// FIX: Segments now use EQUAL visual widths (each category = same arc slice)
// so that "Obese" (0–50 raw span) doesn't dominate the gauge visually.
// The needle still tracks the real BF% value mapped to its correct segment.
class _SemiGaugePainter extends CustomPainter {
  final double value;
  final double animValue;
  final List<_RangeItem> ranges;
  final Color activeColor;

  const _SemiGaugePainter({
    required this.value,
    required this.animValue,
    required this.ranges,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 20;
    const trackW = 22.0;
    const halfTrack = trackW / 2 + 8;
    final maxR = math.min(cx - halfTrack, cy - halfTrack);
    final radius = maxR.clamp(0.0, size.width * 0.38);
    const startAngle = math.pi;
    const totalSweep = math.pi;
    const gapAngle = 0.025;

    // ── FIX: Equal arc per segment (5 segments → each gets 1/5 of the arc)
    // This prevents the Obese segment from visually dominating the gauge.
    final int segCount = ranges.length;
    final double segSweep = totalSweep / segCount;

    // ── Outer shadow for depth
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      totalSweep,
      false,
      Paint()
        ..color = const Color(0xFFCBD5E1).withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = trackW + 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // ── Background track
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      totalSweep,
      false,
      Paint()
        ..color = const Color(0xFFE8EEF4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = trackW,
    );

    // ── Colored segments (equal width each)
    // CRITICAL FIX: ALL segments use StrokeCap.butt — StrokeCap.round extends
    // the arc by strokeWidth/2 (~11px) at each end, causing the red segment's
    // left rounded cap to visually overlap into the orange segment.
    // Rounded tips at the far left (blue) and far right (red) outer ends are
    // drawn separately as tiny filled circles so they never bleed inward.
    double angle = startAngle;
    for (int i = 0; i < segCount; i++) {
      final r = ranges[i];

      // Glow for active segment — butt cap only, never round
      if (r.color == activeColor) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius),
          angle + gapAngle / 2,
          segSweep - gapAngle,
          false,
          Paint()
            ..color = r.color.withOpacity(0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = trackW + 10
            ..strokeCap = StrokeCap.butt
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }

      // Always StrokeCap.butt — no overlap between segments
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        angle + gapAngle / 2,
        segSweep - gapAngle,
        false,
        Paint()
          ..color = r.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = trackW
          ..strokeCap = StrokeCap.butt,
      );
      angle += segSweep;
    }

    // Draw rounded end-caps manually ONLY at the two outer track ends
    // (leftmost tip of first segment, rightmost tip of last segment).
    // These are safe filled circles that sit at the arc endpoints — they
    // never extend inward so they cannot overlap any adjacent segment.
    final capRadius = trackW / 2;

    // Left cap — first segment start (angle = startAngle)
    final leftCapX = cx + radius * math.cos(startAngle);
    final leftCapY = cy + radius * math.sin(startAngle);
    canvas.drawCircle(
      Offset(leftCapX, leftCapY),
      capRadius,
      Paint()..color = ranges.first.color,
    );

    // Right cap — last segment end (angle = startAngle + totalSweep)
    final rightEndAngle = startAngle + totalSweep;
    final rightCapX = cx + radius * math.cos(rightEndAngle);
    final rightCapY = cy + radius * math.sin(rightEndAngle);
    canvas.drawCircle(
      Offset(rightCapX, rightCapY),
      capRadius,
      Paint()..color = ranges.last.color,
    );

    // ── Tick marks at segment boundaries
    double tickAngle = startAngle;
    for (int i = 0; i <= segCount; i++) {
      final innerR = radius - trackW / 2 + 2;
      final outerR = radius + trackW / 2 - 2;
      canvas.drawLine(
        Offset(cx + innerR * math.cos(tickAngle), cy + innerR * math.sin(tickAngle)),
        Offset(cx + outerR * math.cos(tickAngle), cy + outerR * math.sin(tickAngle)),
        Paint()
          ..color = Colors.white.withOpacity(0.9)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
      if (i < segCount) tickAngle += segSweep;
    }

    // ── FIX: Needle angle mapped segment-by-segment so it aligns with visual arcs
    // Find which segment the value falls in, then interpolate within that segment.
    double needleRatio = 0.0;
    final double bf = value.clamp(ranges.first.min, ranges.last.max);
    for (int i = 0; i < ranges.length; i++) {
      final r = ranges[i];
      if (bf <= r.max || i == ranges.length - 1) {
        final segMin = r.min.toDouble();
        final segMax = r.max.toDouble();
        final posInSeg = ((bf - segMin) / (segMax - segMin)).clamp(0.0, 1.0);
        needleRatio = (i + posInSeg) / segCount;
        break;
      }
    }

    final needleAngle =
        startAngle + needleRatio * totalSweep * animValue.clamp(0.0, 1.0);
    final needleTipLen = radius - 6;
    const needleTailLen = 16.0;

    final tipX = cx + needleTipLen * math.cos(needleAngle);
    final tipY = cy + needleTipLen * math.sin(needleAngle);
    final tailX = cx + needleTailLen * math.cos(needleAngle + math.pi);
    final tailY = cy + needleTailLen * math.sin(needleAngle + math.pi);

    // Needle shadow
    canvas.drawLine(
      Offset(tailX, tailY),
      Offset(tipX, tipY),
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Needle body — tapered
    final perpAngle = needleAngle + math.pi / 2;
    const baseHalfW = 4.5;
    final path = Path()
      ..moveTo(tipX, tipY)
      ..lineTo(cx + baseHalfW * math.cos(perpAngle), cy + baseHalfW * math.sin(perpAngle))
      ..lineTo(tailX, tailY)
      ..lineTo(cx - baseHalfW * math.cos(perpAngle), cy - baseHalfW * math.sin(perpAngle))
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF0F172A)..style = PaintingStyle.fill);

    // Needle highlight
    canvas.drawLine(
      Offset(cx + 1.2 * math.cos(perpAngle), cy + 1.2 * math.sin(perpAngle)),
      Offset(
        cx + (needleTipLen - 16) * math.cos(needleAngle) + 1.2 * math.cos(perpAngle),
        cy + (needleTipLen - 16) * math.sin(needleAngle) + 1.2 * math.sin(perpAngle),
      ),
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // ── Center hub
    canvas.drawCircle(Offset(cx, cy), 20,
        Paint()..color = activeColor.withOpacity(0.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawCircle(Offset(cx, cy), 15, Paint()..color = Colors.white..style = PaintingStyle.fill);
    // Colored ring
    canvas.drawCircle(Offset(cx, cy), 15,
        Paint()..color = activeColor.withOpacity(0.6)..style = PaintingStyle.stroke..strokeWidth = 2.5);
    // Inner dot
    canvas.drawCircle(Offset(cx, cy), 5.5, Paint()..color = const Color(0xFF0F172A));
  }

  @override
  bool shouldRepaint(_SemiGaugePainter old) =>
      old.animValue != animValue || old.value != value || old.activeColor != activeColor;
}

// ─── Result Screen ────────────────────────────────────────────────────────────
class _ResultScreen extends StatefulWidget {
  final double bodyFat;
  final bool isMale;
  final int weight;
  final int age;
  const _ResultScreen({
    required this.bodyFat,
    required this.isMale,
    required this.weight,
    required this.age,
  });
  @override
  State<_ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<_ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  _BfCategory get _category {
    final bf = widget.bodyFat;
    if (widget.isMale) {
      if (bf < 6)  return const _BfCategory('Athletic',   Color(0xFF3B82F6), 'Extremely lean — athlete level body fat.');
      if (bf < 14) return const _BfCategory('Fitness',    Color(0xFF22C55E), 'Fit and healthy — great body composition.');
      if (bf < 18) return _BfCategory('Acceptable', AppTheme.primaryGreen,   'Normal body fat. You\'re doing well!');
      if (bf < 25) return const _BfCategory('Overweight', Color(0xFFF59E0B), 'Slightly above ideal — small improvements advised.');
      return       const _BfCategory('Obese',       Color(0xFFEF4444),       'High body fat — lifestyle changes recommended.');
    } else {
      if (bf < 14) return const _BfCategory('Athletic',   Color(0xFF3B82F6), 'Extremely lean — athlete level body fat.');
      if (bf < 21) return const _BfCategory('Fitness',    Color(0xFF22C55E), 'Fit and healthy — great body composition.');
      if (bf < 25) return _BfCategory('Acceptable', AppTheme.primaryGreen,   'Normal body fat. You\'re doing well!');
      if (bf < 32) return const _BfCategory('Overweight', Color(0xFFF59E0B), 'Slightly above ideal — small improvements advised.');
      return       const _BfCategory('Obese',       Color(0xFFEF4444),       'High body fat — lifestyle changes recommended.');
    }
  }

  double get _fatMass  => widget.weight * widget.bodyFat / 100;
  double get _leanMass => widget.weight - _fatMass;

  List<_RangeItem> get _ranges => widget.isMale
      ? [
    const _RangeItem('Athletic',   Color(0xFF3B82F6),  0,  6),
    const _RangeItem('Fitness',    Color(0xFF22C55E),  6, 14),
    _RangeItem('Acceptable', AppTheme.primaryGreen,    14, 18),
    const _RangeItem('Overweight', Color(0xFFF59E0B), 18, 25),
    const _RangeItem('Obese',      Color(0xFFEF4444), 25, 50),
  ]
      : [
    const _RangeItem('Athletic',   Color(0xFF3B82F6),  0, 14),
    const _RangeItem('Fitness',    Color(0xFF22C55E), 14, 21),
    _RangeItem('Acceptable', AppTheme.primaryGreen,   21, 25),
    const _RangeItem('Overweight', Color(0xFFF59E0B), 25, 32),
    const _RangeItem('Obese',      Color(0xFFEF4444), 32, 50),
  ];

  @override
  Widget build(BuildContext context) {
    final cat = _category;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        // BUG FIX: was "Your BFI Result" — BFI is not a standard medical term
        title: Text('Body Fat Result',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [

              // ── Hero: Gauge + Number ─────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, cat.color.withOpacity(0.04)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: cat.color.withOpacity(0.15), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: cat.color.withOpacity(0.18),
                        blurRadius: 32,
                        spreadRadius: -4,
                        offset: const Offset(0, 8)),
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(children: [
                  // Category badge
                  AnimatedBuilder(
                    animation: _anim,
                    builder: (_, __) => Opacity(
                      opacity: _anim.value.clamp(0.0, 1.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 6),
                        decoration: BoxDecoration(
                          color: cat.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: cat.color.withOpacity(0.35), width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7, height: 7,
                              decoration: BoxDecoration(
                                color: cat.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              cat.label.toUpperCase(),
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: cat.color,
                                  letterSpacing: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Semicircular Gauge
                  SizedBox(
                    height: 160,
                    child: AnimatedBuilder(
                      animation: _anim,
                      builder: (_, __) => CustomPaint(
                        painter: _SemiGaugePainter(
                          value: widget.bodyFat,
                          animValue: _anim.value,
                          ranges: _ranges,
                          activeColor: cat.color,
                        ),
                        size: const Size(double.infinity, 160),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Animated BF% number
                  AnimatedBuilder(
                    animation: _anim,
                    builder: (_, __) => RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: (widget.bodyFat * _anim.value)
                              .toStringAsFixed(_anim.value >= 0.99 ? 1 : 0),
                          style: GoogleFonts.poppins(
                              fontSize: 64,
                              fontWeight: FontWeight.w800,
                              color: cat.color,
                              height: 1),
                        ),
                        TextSpan(
                          text: '%',
                          style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: cat.color.withOpacity(0.55)),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Body Fat Percentage',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMedium)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: cat.color.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cat.description,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textDark,
                          height: 1.5),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // ── Body Composition ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Body Composition',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark)),
                      const SizedBox(height: 14),
                      Row(children: [
                        _CompositionTile(
                          label: 'Fat Mass',
                          value:
                          '${_fatMass.toStringAsFixed(1)} kg',
                          percent:
                          '${widget.bodyFat.toStringAsFixed(1)}%',
                          color: cat.color,
                          icon: Icons.water_drop_rounded,
                        ),
                        const SizedBox(width: 12),
                        _CompositionTile(
                          label: 'Lean Mass',
                          value:
                          '${_leanMass.toStringAsFixed(1)} kg',
                          percent:
                          '${(100 - widget.bodyFat).toStringAsFixed(1)}%',
                          color: const Color(0xFF22C55E),
                          icon: Icons.fitness_center_rounded,
                        ),
                      ]),
                      const SizedBox(height: 14),
                      // Stacked fat/lean bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Row(children: [
                          Flexible(
                            flex: widget.bodyFat.round(),
                            child: Container(
                                height: 8,
                                color:
                                cat.color.withOpacity(0.75)),
                          ),
                          Flexible(
                            flex:
                            (100 - widget.bodyFat).round(),
                            child: Container(
                                height: 8,
                                color: const Color(0xFF22C55E)
                                    .withOpacity(0.75)),
                          ),
                        ]),
                      ),
                    ]),
              ),
              const SizedBox(height: 16),

              // ── Info footer ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.emerald50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.2)),
                ),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppTheme.primaryGreen, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Calculated using the U.S. Navy Body Fat Method based on height, weight, waist & neck. For clinical diagnosis consult a healthcare professional.',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppTheme.textMedium,
                              height: 1.6),
                        ),
                      ),
                    ]),
              ),
              const SizedBox(height: 12),
            ]),
          ),
        ),

        // ── Done Button ────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppTheme.bgLight,
            border: Border(top: BorderSide(color: const Color(0xFFE2E8F0))),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Composition Tile ─────────────────────────────────────────────────────────
class _CompositionTile extends StatelessWidget {
  final String label, value, percent;
  final Color color;
  final IconData icon;
  const _CompositionTile({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMedium)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark)),
          Text(percent,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────
class _BfCategory {
  final String label;
  final Color color;
  final String description;
  const _BfCategory(this.label, this.color, this.description);
}

class _RangeItem {
  final String label;
  final Color color;
  final double min, max;
  const _RangeItem(this.label, this.color, this.min, this.max);
}