// lib/screens/set_goal_screen.dart
// ✅ ALL calendar/stats data is REAL — fetched from HealthService.
//    Zero dummy/hardcoded step values remain.
//    UI layout, widgets, styling, animations are IDENTICAL to the original.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/health_service.dart';
import '../theme/theme.dart';

class SetGoalScreen extends StatefulWidget {
  final int initialGoal;
  const SetGoalScreen({Key? key, required this.initialGoal}) : super(key: key);

  @override
  State<SetGoalScreen> createState() => _SetGoalScreenState();
}

class _SetGoalScreenState extends State<SetGoalScreen>
    with SingleTickerProviderStateMixin {
  static const double _refW = 360;
  static const double _refH = 800;

  late int _currentGoal;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // ✅ REAL data — replaces the 12-entry fake map
  Map<int, int> _monthlySteps = {};   // day-of-month → steps
  int  _monthTotal = 0;
  bool _loadingCalendar = true;

  // computed from real data
  int  get _monthAvg  {
    if (_monthlySteps.isEmpty) return 0;
    return _monthlySteps.values.fold(0, (s, v) => s + v) ~/ _monthlySteps.length;
  }
  // best day label + steps
  MapEntry<int, int> get _bestEntry {
    if (_monthlySteps.isEmpty) return const MapEntry(0, 0);
    return _monthlySteps.entries.reduce((a, b) => a.value >= b.value ? a : b);
  }

  @override
  void initState() {
    super.initState();
    _currentGoal = widget.initialGoal;
    _controller = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    // ✅ Load real calendar data on open
    _loadRealData();
  }

  Future<void> _loadRealData() async {
    // Permission should already be granted from StepsTrackerScreen — just fetch
    final perDay    = await HealthService.instance.fetchThisMonthPerDay();
    final total     = await HealthService.instance.fetchThisMonthSteps();
    if (!mounted) return;
    setState(() {
      _monthlySteps    = perDay;
      _monthTotal      = total;
      _loadingCalendar = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ✅ Color by intensity — same logic as original
  Color _getStepColor(int steps) {
    if (steps >= 12000) return AppTheme.darkGreen;
    if (steps >= 10000) return AppTheme.primaryGreen;
    if (steps >= 8000)  return const Color(0xFF2196F3);
    if (steps >= 6000)  return const Color(0xFFFF9800);
    return const Color(0xFF9E9E9E);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final ws = size.width  / _refW;
    final hs = size.height / _refH;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: AppTheme.textDark, size: ws * 20),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(minWidth: ws * 32, minHeight: ws * 32),
        ),
        centerTitle: true,
        title: Text('Set Goal',
            style: GoogleFonts.poppins(
                fontSize: ws * 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark)),
        toolbarHeight: hs * 48,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
                left: ws * 12, right: ws * 12,
                top: hs * 2,   bottom: hs * 5),
            child: Column(
              children: [
                Text('Set your daily goal!',
                    style: GoogleFonts.poppins(
                        fontSize: ws * 12,
                        color: AppTheme.textMedium,
                        fontWeight: FontWeight.w500))
                    .animate().fadeIn(duration: 300.ms),
                SizedBox(
                  width: ws * 160, height: hs * 150,
                  child: Image.asset(
                    'assets/images/logo_step_tracker.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.white,
                      child: Icon(Icons.directions_walk,
                          size: ws * 80, color: AppTheme.primaryGreen),
                    ),
                  ).animate().fadeIn(duration: 400.ms)
                      .scale(begin: const Offset(0.9, 0.9), duration: 400.ms),
                ),
                SizedBox(height: hs * 1),
                _buildGoalCard(ws, hs)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideY(begin: 0.15, end: 0),
                SizedBox(height: hs * 8),
                _buildCalendarCard(ws, hs)
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 400.ms)
                    .slideY(begin: 0.15, end: 0),
                SizedBox(height: hs * 8),
                _buildControlButtons(ws, hs)
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 300.ms),
                SizedBox(height: hs * 8),
                _buildSetGoalButton(ws, hs)
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── goal card (unchanged UI) ──────────────────────────────────────────────
  Widget _buildGoalCard(double ws, double hs) {
    return Container(
      padding: EdgeInsets.all(ws * 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ws * 14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: ws * 10, offset: Offset(0, hs * 3)),
        ],
      ),
      child: Column(
        children: [
          Text('Daily Steps Goal',
              style: GoogleFonts.poppins(
                  fontSize: ws * 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark)),
          SizedBox(height: hs * 8),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: _formatNumber(_currentGoal),
                style: GoogleFonts.poppins(
                    fontSize: ws * 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryGreen,
                    height: 0.95),
              ),
              TextSpan(
                text: ' Steps',
                style: GoogleFonts.poppins(
                    fontSize: ws * 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMedium),
              ),
            ]),
          ),
          SizedBox(height: hs * 10),
          _buildCustomSlider(ws, hs),
          SizedBox(height: hs * 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: ws * 10, vertical: hs * 7),
            decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(ws * 10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.info_outline, size: ws * 13, color: AppTheme.textMedium),
              SizedBox(width: ws * 6),
              Text('Recommended: 10,000 Steps',
                  style: GoogleFonts.poppins(
                      fontSize: ws * 10,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMedium)),
            ]),
          ),
        ],
      ),
    );
  }

  // ─── slider (unchanged) ────────────────────────────────────────────────────
  Widget _buildCustomSlider(double ws, double hs) {
    const minValue = 2000.0;
    const maxValue = 20000.0;
    const labels = ['2k', '8k', '10k', '15k', '20k'];

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: hs * 6,
            thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: ws * 12, elevation: 2.0),
            overlayShape: RoundSliderOverlayShape(overlayRadius: ws * 16),
            activeTrackColor:   AppTheme.primaryGreen,
            inactiveTrackColor: AppTheme.divider,
            thumbColor:         AppTheme.primaryGreen,
          ),
          child: Slider(
            value: _currentGoal.toDouble(),
            min: minValue, max: maxValue, divisions: 18,
            onChanged: (value) => setState(() => _currentGoal = value.toInt()),
          ),
        ),
        SizedBox(height: hs * 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels
              .map((label) => Text(label,
              style: GoogleFonts.poppins(
                  fontSize: ws * 9,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMedium)))
              .toList(),
        ),
      ],
    );
  }

  // ─── calendar card — REAL _monthlySteps ───────────────────────────────────
  Widget _buildCalendarCard(double ws, double hs) {
    final now = DateTime.now();
    final monthName =
    ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
    [now.month - 1];

    // best day text
    final best = _bestEntry;
    final bestLabel = best.value > 0 ? 'Day ${best.key}' : '—';
    final bestSteps = best.value > 0 ? _formatNumber(best.value) : '0';

    return Container(
      padding: EdgeInsets.all(ws * 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ws * 14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: ws * 10, offset: Offset(0, hs * 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ✅ REAL month + year
              Text('$monthName ${now.year}',
                  style: GoogleFonts.poppins(
                      fontSize: ws * 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark)),
              // ✅ REAL total
              Text('Total: ${_formatNumber(_monthTotal)}',
                  style: GoogleFonts.poppins(
                      fontSize: ws * 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark)),
            ],
          ),
          SizedBox(height: hs * 8),
          _loadingCalendar
              ? SizedBox(
              height: ws * 120,
              child: const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen, strokeWidth: 2)))
              : _buildCalendarGrid(ws, hs),
          SizedBox(height: hs * 8),
          Divider(color: AppTheme.divider, thickness: 0.8, height: hs * 8),
          SizedBox(height: hs * 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // ✅ REAL avg per active day
              _CalendarStat('Avg',  _formatNumber(_monthAvg), 'Steps/Day', ws),
              // ✅ REAL monthly total
              _CalendarStat('Total', _formatNumber(_monthTotal), 'Steps', ws),
              // ✅ REAL best day
              _CalendarStat('Best', bestLabel, bestSteps, ws),
            ],
          ),
        ],
      ),
    );
  }

  // ─── calendar grid — REAL data + correct weekday offset ───────────────────
  Widget _buildCalendarGrid(double ws, double hs) {
    final cellSize = ws * 20;
    final spacing  = ws * 2.5;
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    // Monday-based offset (weekday 1=Mon … 7=Sun)
    final leadingBlanks = DateTime(now.year, now.month, 1).weekday - 1;

    return Wrap(
      spacing: spacing, runSpacing: spacing,
      children: [
        // leading blanks for correct weekday alignment
        ...List.generate(leadingBlanks,
                (_) => SizedBox(width: cellSize, height: cellSize)),
        // real day cells
        ...List.generate(daysInMonth, (i) {
          final day      = i + 1;
          final steps    = _monthlySteps[day];
          final hasData  = steps != null && steps > 0;
          final intensity= hasData ? (steps / 13200).clamp(0.0, 1.0) : 0.0;
          final isToday  = day == now.day;

          return Container(
            width: cellSize, height: cellSize,
            decoration: BoxDecoration(
              color: hasData
                  ? _getStepColor(steps).withOpacity(0.3 + intensity * 0.7)
                  : Colors.transparent,
              border: Border.all(
                color: isToday
                    ? const Color(0xFFFF9800)
                    : hasData
                    ? _getStepColor(steps)
                    : Colors.transparent,
                width: isToday ? ws * 1.2 : ws * 0.6,
              ),
              borderRadius: BorderRadius.circular(ws * 4),
            ),
            alignment: Alignment.center,
            child: Text(day.toString(),
                style: GoogleFonts.poppins(
                    fontSize: ws * 7,
                    fontWeight: FontWeight.w600,
                    color: hasData && intensity > 0.5
                        ? Colors.white
                        : AppTheme.textDark)),
          );
        }),
      ],
    );
  }

  // ─── control buttons (unchanged) ──────────────────────────────────────────
  Widget _buildControlButtons(double ws, double hs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(
          icon: Icons.remove, ws: ws,
          onTap: () {
            if (_currentGoal > 2000) setState(() => _currentGoal -= 1000);
          },
        ),
        SizedBox(width: ws * 20),
        Container(
          padding: EdgeInsets.symmetric(horizontal: ws * 12, vertical: hs * 6),
          decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(ws * 8)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(4, (index) => Container(
              width: ws * 6, height: ws * 6,
              margin: EdgeInsets.symmetric(vertical: hs * 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < 3
                    ? AppTheme.primaryGreen
                    : const Color(0xFFD0D0D0),
              ),
            )),
          ),
        ),
        SizedBox(width: ws * 20),
        _buildControlButton(
          icon: Icons.add, ws: ws,
          onTap: () {
            if (_currentGoal < 20000) setState(() => _currentGoal += 1000);
          },
        ),
      ],
    );
  }

  Widget _buildControlButton(
      {required IconData icon, required VoidCallback onTap, required double ws}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ws * 14),
        child: Container(
          width: ws * 44, height: ws * 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ws * 14),
            border: Border.all(color: const Color(0xFFE5E5E5), width: ws * 1.5),
          ),
          child: Icon(icon, color: AppTheme.primaryGreen, size: ws * 20),
        ),
      ),
    );
  }

  // ─── set goal button (unchanged) ──────────────────────────────────────────
  Widget _buildSetGoalButton(double ws, double hs) {
    bool _buttonPressed = false;
    return StatefulBuilder(builder: (context, setBtnState) {
      return GestureDetector(
        onTapDown:  (_) => setBtnState(() => _buttonPressed = true),
        onTapUp:    (_) => setBtnState(() => _buttonPressed = false),
        onTapCancel: () => setBtnState(() => _buttonPressed = false),
        onTap: () {
          setBtnState(() => _buttonPressed = false);
          Navigator.pop(context, _currentGoal);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: hs * 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _buttonPressed
                  ? [AppTheme.darkGreen, AppTheme.primaryGreen]
                  : [AppTheme.primaryGreen, AppTheme.darkGreen],
              begin: Alignment.centerLeft, end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(ws * 22),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen
                    .withOpacity(_buttonPressed ? 0.18 : 0.38),
                blurRadius: _buttonPressed ? ws * 4 : ws * 14,
                offset: Offset(0, _buttonPressed ? hs * 2 : hs * 6),
              ),
            ],
          ),
          transform: _buttonPressed
              ? (Matrix4.identity()..scale(0.97, 0.97))
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          child: Center(
            child: Text('Set Goal',
                style: GoogleFonts.poppins(
                    fontSize: ws * 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      );
    });
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }
}

// ─── _CalendarStat (unchanged widget) ─────────────────────────────────────────
class _CalendarStat extends StatelessWidget {
  final String label, value, unit;
  final double ws;
  const _CalendarStat(this.label, this.value, this.unit, this.ws);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: ws * 8,
                color: AppTheme.textMedium,
                fontWeight: FontWeight.w500)),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: ws * 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark)),
        Text(unit,
            style: GoogleFonts.poppins(
                fontSize: ws * 8,
                color: AppTheme.textMedium,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}