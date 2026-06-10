import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import 'wellness_goals_screen.dart' show OnboardingProvider, StepProgressIndicator;

class AgePrakritiScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSaveAndSubmit;

  const AgePrakritiScreen({
    super.key,
    required this.onBack,
    required this.onSaveAndSubmit,
  });

  @override
  State<AgePrakritiScreen> createState() => _AgePrakritiScreenState();
}

class _AgePrakritiScreenState extends State<AgePrakritiScreen> {
  static const _multipliers = [1.2, 1.375, 1.55, 1.725, 1.9];

  static const double _refW = 360;
  static const double _refH = 800;

  double _calcTdee(double weight, double height, int age, int activityIdx) {
    final bmr = 10 * weight + 6.25 * height - 5 * age - 78;
    final multiplier = _multipliers[activityIdx.clamp(0, 4)];
    return bmr * multiplier;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    final size = MediaQuery.sizeOf(context);
    final ws = size.width / _refW;
    final hs = size.height / _refH;
    final hp = size.width < 600 ? ws * 16 : ws * 24;
    final currentYear = DateTime.now().year;

    final age = provider.calculatedAge;
    final canCalc = age != null && provider.weight > 0 && provider.height > 0;
    final tdee = canCalc
        ? _calcTdee(provider.weight, provider.height, age, provider.activityLevel)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hp, hs * 8, hp, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      width: ws * 40,
                      height: ws * 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.lightGrey),
                      ),
                      child: Icon(Icons.arrow_back_ios_new,
                          size: ws * 16, color: AppTheme.darkGrey),
                    ),
                  ),
                  SizedBox(width: ws * 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Year of Birth',
                          style: GoogleFonts.poppins(
                            fontSize: size.width < 600 ? ws * 20 : ws * 24,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'To better understand your life stage',
                          style: GoogleFonts.inter(
                            fontSize: ws * 13,
                            color: AppTheme.mediumGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable content ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(hp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: hs * 20),

                    // Year dropdown
                    DropdownButtonFormField<int>(
                      value: provider.yearOfBirth,
                      hint: Text(
                        'Select your year of birth',
                        style: GoogleFonts.inter(
                            fontSize: ws * 15, color: const Color(0xFF999999)),
                      ),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: ws * 16, vertical: hs * 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ws * 12),
                          borderSide: const BorderSide(
                              color: const Color(0xFFE2E8F0), width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ws * 12),
                          borderSide: const BorderSide(
                              color: const Color(0xFFE2E8F0), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ws * 12),
                          borderSide: const BorderSide(
                              color: const Color(0xFF10B981), width: 2),
                        ),
                      ),
                      icon: Icon(Icons.keyboard_arrow_down,
                          color: AppTheme.mediumGrey, size: ws * 24),
                      menuMaxHeight: hs * 300,
                      items: List.generate(100, (i) {
                        final year = currentYear - i;
                        return DropdownMenuItem(
                          value: year,
                          child: Text(
                            year.toString(),
                            style: GoogleFonts.inter(
                              fontSize: ws * 15,
                              fontWeight: provider.yearOfBirth == year
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: AppTheme.darkGrey,
                            ),
                          ),
                        );
                      }),
                      onChanged: (val) => provider.yearOfBirth = val,
                    ),

                    // Age display
                    if (age != null) ...[
                      SizedBox(height: hs * 10),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: ws * 10, vertical: hs * 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(ws * 20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.cake_outlined,
                                    size: ws * 14, color: const Color(0xFF059669)),
                                SizedBox(width: ws * 5),
                                Text(
                                  'Age: $age years',
                                  style: GoogleFonts.inter(
                                    fontSize: ws * 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    SizedBox(height: hs * 28),

                    // ── TDEE Section ─────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(ws * 16),
                        border: Border.all(color: const Color(0xFFEEF1F5), width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.06),
                            blurRadius: ws * 16,
                            offset: Offset(0, hs * 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: ws * 8,
                            offset: Offset(0, hs * 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card header
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                                ws * 16, hs * 14, ws * 16, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Approximate TDEE',
                                        style: GoogleFonts.poppins(
                                          fontSize: ws * 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.darkGrey,
                                        ),
                                      ),
                                      Text(
                                        '(Total Daily Energy Expenditure)',
                                        style: GoogleFonts.inter(
                                          fontSize: ws * 11.5,
                                          color: AppTheme.mediumGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() {}),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: ws * 11,
                                        vertical: hs * 7),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: hs * 14),

                          // TDEE value box
                          Padding(
                            padding:
                            EdgeInsets.symmetric(horizontal: ws * 16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                  horizontal: ws * 16,
                                  vertical: hs * 14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFFECFDF5), Color(0xFFF0FDF4)],
                                ),
                                borderRadius: BorderRadius.circular(ws * 12),
                                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2), width: 1.0),
                              ),
                              child: tdee != null
                                  ? Row(
                                children: [
                                  Text(
                                    tdee.toStringAsFixed(2),
                                    style: GoogleFonts.inter(
                                      fontSize: ws * 22,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF047857),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(width: ws * 6),
                                  Text(
                                    'kcal / day',
                                    style: GoogleFonts.inter(
                                      fontSize: ws * 12,
                                      color: AppTheme.mediumGrey,
                                    ),
                                  ),
                                ],
                              )
                                  : Text(
                                provider.yearOfBirth == null
                                    ? 'Select your year of birth above'
                                    : 'Set your measurements to calculate',
                                style: GoogleFonts.inter(
                                  fontSize: ws * 13,
                                  color: AppTheme.mediumGrey,
                                ),
                              ),
                            ),
                          ),

                          // Breakdown chips (only when calculated)
                          if (tdee != null) ...[
                            SizedBox(height: hs * 10),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: ws * 16),
                              child: Row(
                                children: [
                                  _TdeeChip(
                                      label: 'BMR',
                                      value:
                                      '${(10 * provider.weight + 6.25 * provider.height - 5 * age! - 78).toStringAsFixed(0)} kcal',
                                      color: const Color(0xFF10B981),
                                      ws: ws,
                                      hs: hs),
                                  SizedBox(width: ws * 8),
                                  _TdeeChip(
                                      label: 'Activity',
                                      value:
                                      '×${_multipliers[provider.activityLevel.clamp(0, 4)]}',
                                      color: const Color(0xFF059669),
                                      ws: ws,
                                      hs: hs),
                                  SizedBox(width: ws * 8),
                                  _TdeeChip(
                                      label: 'Age',
                                      value: '$age yrs',
                                      color: const Color(0xFF228B22),
                                      ws: ws,
                                      hs: hs),
                                ],
                              ),
                            ),
                          ],

                          SizedBox(height: hs * 14),

                          // Disclaimer box
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                                ws * 16, 0, ws * 16, hs * 16),
                            child: Container(
                              padding: EdgeInsets.fromLTRB(
                                  ws * 12, hs * 11, ws * 12, hs * 11),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius:
                                BorderRadius.circular(ws * 12),
                                border: Border.all(
                                    color: const Color(0xFF10B981)
                                        .withOpacity(0.3)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('🌿',
                                      style:
                                      TextStyle(fontSize: ws * 15)),
                                  SizedBox(width: ws * 9),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.inter(
                                          fontSize: ws * 12,
                                          height: 1.6,
                                          color: const Color(0xFF065F46),
                                        ),
                                        children: const [
                                          TextSpan(text: 'We use your '),
                                          TextSpan(
                                              text:
                                              'height, weight, cholesterol,',
                                              style: TextStyle(
                                                  fontWeight:
                                                  FontWeight.w700)),
                                          TextSpan(
                                              text:
                                              ' and other details to personalize your diet. '
                                                  'These suggestions are intended for general wellness '
                                                  'and are not a substitute for professional medical advice. '
                                                  'For any medical conditions, please consult your doctor '
                                                  'before making dietary changes.'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: hs * 24),
                  ],
                ),
              ),
            ),

            // ── Footer ──────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(hp, hs * 12, hp, hs * 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEF1F5), width: 1)),
                boxShadow: [
                  BoxShadow(
                    offset: Offset(0, -2),
                    blurRadius: 12,
                    color: Color(0x08000000),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const StepProgressIndicator(currentStep: 2, totalSteps: 3),
                  SizedBox(height: hs * 14),
                  SizedBox(
                    width: double.infinity,
                    height: hs * 52,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: provider.yearOfBirth != null ? 1.0 : 0.5,
                      child: ElevatedButton(
                        onPressed: provider.yearOfBirth != null
                            ? () {
                          HapticFeedback.mediumImpact();
                          widget.onSaveAndSubmit();
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ws * 14),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: provider.yearOfBirth != null
                                  ? const [Color(0xFF10B981), Color(0xFF047857)]
                                  : [Colors.grey.shade300, Colors.grey.shade400],
                            ),
                            borderRadius: BorderRadius.circular(ws * 14),
                          ),
                          child: Container(
                            width: double.infinity,
                            height: hs * 52,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: ws * 28, height: ws * 28,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(ws * 8),
                                  ),
                                  child: Icon(Icons.check_rounded, size: ws * 16, color: Colors.white),
                                ),
                                SizedBox(width: ws * 10),
                                Text(
                                  'Save & Submit',
                                  style: GoogleFonts.poppins(
                                      fontSize: ws * 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── TDEE Breakdown Chip ──────────────────────────────────────────────────────

class _TdeeChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double ws;
  final double hs;

  const _TdeeChip({
    required this.label,
    required this.value,
    required this.color,
    required this.ws,
    required this.hs,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: hs * 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(ws * 9),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: ws * 10,
                  fontWeight: FontWeight.w500,
                  color: color.withOpacity(0.75)),
            ),
            SizedBox(height: hs * 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.inter(
                    fontSize: ws * 12,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}