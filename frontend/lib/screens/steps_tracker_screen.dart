// lib/screens/steps_tracker_screen.dart
// ✅ Calendar: perfectly aligned using LayoutBuilder — equal 7-column grid
// ✅ Goal: loaded from SharedPreferences on init (persists across app restarts)
// ✅ Motivational progress ring with gradient & glow
// ✅ All original functionality preserved

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'set_goal_screen.dart';
import '../theme/theme.dart';
import '../services/health_service.dart';
import '../services/step_counter_service.dart';
import '../services/api/api_service.dart';
import '../providers/rewards_provider.dart';

class StepsTrackerScreen extends StatelessWidget {
  const StepsTrackerScreen({super.key});
  @override
  Widget build(BuildContext context) => const StepsTrackerHome();
}

// ─── Colours ──────────────────────────────────────────────────────────────────
class _C {
  _C._();
  static const Color bg        = Color(0xFFF0F6F3); // soft green-tinted bg
  static const Color card      = Colors.white;
  static Color get primary     => AppTheme.primaryGreen;
  static Color get accent      => AppTheme.darkGreen;
  static const Color orange    = Color(0xFFFF9800);
  static Color get teal        => AppTheme.primaryGreen;
  static Color get green       => AppTheme.primaryGreen;
  static const Color textDark  = Color(0xFF1A2E35);
  static const Color textMed   = Color(0xFF5A7A6B);
  static const Color textLight = Color(0xFF9BBFB0);
  static const Color ringTrack = Color(0xFFD1FAE5);

  static List<BoxShadow> cardShadow = [
    BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 3)),
    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 1)),
  ];
}

const _barColors = [
  Color(0xFF10B981), Color(0xFFFF9800), Color(0xFF059669),
  Color(0xFF34D399), Color(0xFFFF9800), Color(0xFF10B981),
  Color(0xFFFDD835),
];

const String _prefKeyGoal = 'daily_step_goal';

// ─── Main Widget ──────────────────────────────────────────────────────────────
class StepsTrackerHome extends StatefulWidget {
  const StepsTrackerHome({super.key});
  @override
  State<StepsTrackerHome> createState() => _StepsTrackerHomeState();
}

class _StepsTrackerHomeState extends State<StepsTrackerHome>
    with TickerProviderStateMixin {

  int _mainTabIndex  = 0;

  int            _dailySteps    = 0;
  int            _dailyGoal     = 10000;
  int            _weeklySteps   = 0;
  int            _monthlySteps  = 0;
  List<DaySteps> _weekData      = _emptyWeek();
  List<DaySteps> _monthAllDays  = [];
  Map<int, int>  _calendarSteps = {};
  DaySteps?      _monthBestDay;

  DateTime?      _selectedDate;
  int            _selectedSteps = 0;

  late AnimationController _ringController;
  late Animation<double>   _ringAnimation;
  late ScrollController    _graphScrollController;
  Timer? _refreshTimer;

  // ── computed getters ──────────────────────────────────────────────────────

  int get _displaySteps {
    if (_selectedDate != null) return _selectedSteps;
    if (_mainTabIndex == 0) return _dailySteps;
    if (_mainTabIndex == 1) return _weeklySteps;
    return _monthlySteps;
  }

  int get _displayGoal {
    if (_selectedDate != null) return _dailyGoal;
    if (_mainTabIndex == 0) return _dailyGoal;
    if (_mainTabIndex == 1) return _dailyGoal * 7;
    return _dailyGoal * 30;
  }

  int get _displayCalories => HealthService.stepsToCalories(_displaySteps);

  String get _card1Title {
    if (_selectedDate != null) return 'Daily Steps';
    if (_mainTabIndex == 0) return 'Daily Steps';
    if (_mainTabIndex == 1) return 'Weekly Steps';
    return 'Monthly Steps';
  }

  int get _card1Steps {
    if (_selectedDate != null) return _selectedSteps;
    if (_mainTabIndex == 0) return _dailySteps;
    if (_mainTabIndex == 1) return _weeklySteps;
    return _monthlySteps;
  }

  String get _card2Title {
    if (_selectedDate != null) return 'Daily Calories';
    if (_mainTabIndex == 0) return 'Daily Calories';
    if (_mainTabIndex == 1) return 'Weekly Calories';
    return 'Monthly Calories';
  }

  DaySteps get _weekBestDay {
    final active = _weekData.where((d) => d.steps > 0).toList();
    if (active.isEmpty) return DaySteps('—', 0, DateTime.now());
    return active.reduce((a, b) => a.steps >= b.steps ? a : b);
  }

  static List<DaySteps> _emptyWeek() {
    final now    = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final m      = DateTime(monday.year, monday.month, monday.day);
    return List.generate(7, (i) =>
        DaySteps(['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][i], 0,
            m.add(Duration(days: i))));
  }

  // ── init ──────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this);
    _ringAnimation  = Tween<double>(begin: 0.0, end: 0.0).animate(
        CurvedAnimation(parent: _ringController, curve: Curves.easeOutCubic));
    _graphScrollController = ScrollController();
    _loadPersistedGoal();
    _initService();
    _refreshTimer = Timer.periodic(
        const Duration(seconds: 10), (_) => _loadAllData());
  }

  // ✅ Load the goal that was saved by SetGoalScreen
  Future<void> _loadPersistedGoal() async {
    try {
      final response = await ApiService().getUserSettings();
      if (response.isSuccess && response.data != null) {
        final backendGoal = response.data!['dailyStepGoal'] as int?;
        if (backendGoal != null) {
          if (mounted) {
            setState(() => _dailyGoal = backendGoal);
            _animateRing();
          }
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_prefKeyGoal, backendGoal);
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading step goal from backend: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_prefKeyGoal);
      if (saved != null && saved != _dailyGoal && mounted) {
        setState(() => _dailyGoal = saved);
      }
    } catch (_) {}
  }

  Future<void> _initService() async {
    await HealthService.instance.requestPermissions();
    await StepCounterService.instance.startService();
    await _loadAllData();
  }

  Future<void> _loadAllData() async {
    await HealthService.instance.saveTodayToHistory();

    final results = await Future.wait([
      HealthService.instance.fetchTodaySteps(),
      HealthService.instance.fetchThisWeekPerDay(),
      HealthService.instance.fetchThisMonthAllDays(),
      HealthService.instance.fetchThisMonthSteps(),
      HealthService.instance.fetchMonthBestDay(),
    ]);

    if (!mounted) return;
    setState(() {
      _dailySteps   = results[0] as int;
      _weekData     = results[1] as List<DaySteps>;
      _weeklySteps  = HealthService.weekTotal(_weekData);
      _monthAllDays = results[2] as List<DaySteps>;
      _calendarSteps = {
        for (final d in _monthAllDays)
          if (d.steps > 0) d.date.day: d.steps
      };
      _monthlySteps = results[3] as int;
      _monthBestDay = results[4] as DaySteps;

      if (_selectedDate != null) {
        final match = _monthAllDays.where(
                (d) => d.date.day == _selectedDate!.day).toList();
        if (match.isNotEmpty) _selectedSteps = match.first.steps;
      }
    });

    _animateRing();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollGraphToCurrentWeek());
  }

  Future<void> _selectDate(DateTime date) async {
    final steps = await HealthService.instance.fetchStepsForDate(date);
    if (!mounted) return;
    setState(() {
      _selectedDate  = date;
      _selectedSteps = steps;
    });
    _animateRing();
  }

  void _clearSelection() {
    setState(() {
      _selectedDate  = null;
      _selectedSteps = 0;
    });
    _animateRing();
  }

  void _animateRing() {
    final goal   = _displayGoal > 0 ? _displayGoal : 1;
    final target = (_displaySteps / goal).clamp(0.0, 1.0);
    _ringAnimation = Tween<double>(
      begin: _ringAnimation.value,
      end:   target,
    ).animate(CurvedAnimation(parent: _ringController, curve: Curves.easeOutCubic));
    _ringController..reset()..forward();
  }

  void _scrollGraphToCurrentWeek() {
    if (!_graphScrollController.hasClients) return;
    final now          = DateTime.now();
    final dayIndex     = now.day - 1;
    const barWidth     = 44.0;
    final screenWidth  = MediaQuery.of(context).size.width - 40;
    final targetOffset = (dayIndex * barWidth) - (screenWidth / 2) + barWidth * 3.5;
    _graphScrollController.animateTo(
      targetOffset.clamp(0.0, _graphScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _ringController.dispose();
    _graphScrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    _clearSelection();
    await _loadAllData();
  }

  // ─── build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final ws = constraints.maxWidth / 360.0;
      final hs = MediaQuery.of(context).size.height / 800.0;

      return Scaffold(
        backgroundColor: const Color(0xFFF0F6F3),
        body: SafeArea(child: Column(children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12*ws, 4*hs, 12*ws, 5*hs),
            child: _buildHeader(ws, hs),
          ),
          Expanded(
            child: RefreshIndicator(
              displacement: 20,
              color: AppTheme.primaryGreen,
              backgroundColor: Colors.white,
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics()),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10*ws),
                  child: Column(children: [
                    SizedBox(height: 6*hs),
                    _buildMainTabs(ws, hs).animate().fadeIn(duration: 300.ms, delay: 80.ms),
                    SizedBox(height: 4*hs),
                    _buildProgressCard(ws, hs).animate().fadeIn(duration: 400.ms, delay: 160.ms),
                    SizedBox(height: 5*hs),
                    _buildSummaryCards(ws, hs).animate().fadeIn(duration: 400.ms, delay: 280.ms),
                    SizedBox(height: 5*hs),
                    _buildGraphCard(ws, hs).animate().fadeIn(duration: 500.ms, delay: 340.ms),
                    SizedBox(height: 5*hs),
                    _buildCalendarSection(ws, hs).animate().fadeIn(duration: 400.ms, delay: 400.ms),
                    SizedBox(height: 5*hs),
                    _buildFunFact(ws, hs).animate().fadeIn(duration: 300.ms, delay: 460.ms),
                    SizedBox(height: 5*hs),
                    _buildSetGoalButton(ws, hs).animate().fadeIn(duration: 400.ms, delay: 520.ms),
                    SizedBox(height: 8*hs),
                  ]),
                ),
              ),
            ),
          ),
        ])),
      );
    });
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(double ws, double hs) {
    return Row(children: [
      Container(
        width: 28*ws, height: 28*ws,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter),
          borderRadius: BorderRadius.circular(7*ws),
        ),
        child: Icon(Icons.local_fire_department, color: Colors.white, size: 16*ws),
      ),
      SizedBox(width: 7*ws),
      Text('Steps Tracker',
          style: GoogleFonts.poppins(
              fontSize: 16*ws, fontWeight: FontWeight.w700, color: _C.textDark)),
      const Spacer(),
      if (_selectedDate != null)
        GestureDetector(
          onTap: _clearSelection,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8*ws, vertical: 4*hs),
            decoration: BoxDecoration(
                color: _C.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20*ws)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.close, size: 12*ws, color: _C.orange),
              SizedBox(width: 3*ws),
              Text(_formatDate(_selectedDate!),
                  style: GoogleFonts.poppins(
                      fontSize: 10*ws, color: _C.orange, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      SizedBox(width: 6*ws),
      Container(
        width: 32*ws, height: 32*ws,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8*ws),
            boxShadow: _C.cardShadow),
        child: Icon(Icons.notifications_none_rounded, color: _C.textMed, size: 16*ws),
      ),
    ]).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
  }

  // ─── Main Tabs ────────────────────────────────────────────────────────────
  Widget _buildMainTabs(double ws, double hs) {
    const tabs = ['Daily', 'Weekly', 'Monthly'];
    return Container(
      height: 30*hs,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26*ws),
          boxShadow: _C.cardShadow),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final sel = i == _mainTabIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _mainTabIndex = i);
                _clearSelection();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.all(2*ws),
                decoration: BoxDecoration(
                    color: sel ? AppTheme.primaryGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(26*ws)),
                alignment: Alignment.center,
                child: Text(tabs[i],
                    style: GoogleFonts.poppins(
                        fontSize: 11*ws, fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : _C.textMed)),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Progress Ring Card ───────────────────────────────────────────────────
  Widget _buildProgressCard(double ws, double hs) {
    final goal    = _displayGoal > 0 ? _displayGoal : 1;
    final label   = _selectedDate != null
        ? _formatDate(_selectedDate!)
        : _mainTabIndex == 0 ? "Today's steps"
        : _mainTabIndex == 1 ? "This week"
        : "This month";

    return Container(
      padding: EdgeInsets.all(10*ws),
      decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(14*ws),
          boxShadow: _C.cardShadow),
      child: Row(children: [
        SizedBox(
          width: 78*ws, height: 78*ws,
          child: AnimatedBuilder(
            animation: _ringAnimation,
            builder: (_, __) => CustomPaint(
              painter: _CircularProgressPainter(
                  progress: _ringAnimation.value,
                  trackColor: _C.ringTrack,
                  progressColor: _C.primary,
                  strokeWidth: 8),
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_formatNumber((_ringAnimation.value * goal).round()),
                    style: GoogleFonts.poppins(
                        fontSize: 15*ws, fontWeight: FontWeight.w700, color: _C.textDark)),
                Text('${_formatNumber(goal)} Steps',
                    style: GoogleFonts.poppins(
                        fontSize: 6*ws, fontWeight: FontWeight.w500, color: _C.textLight)),
              ])),
            ),
          ),
        ),
        SizedBox(width: 13*ws),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11*ws, fontWeight: FontWeight.w500, color: _C.accent)),
          SizedBox(height: 1*hs),
          Text(_formatNumber(_displaySteps),
              style: GoogleFonts.poppins(
                  fontSize: 20*ws, fontWeight: FontWeight.w700,
                  color: _C.textDark, height: 0.95)),
          SizedBox(height: 4*hs),
          Row(children: [
            Container(
              width: 18*ws, height: 18*ws,
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFFF5722)]),
                  borderRadius: BorderRadius.circular(5*ws)),
              child: Icon(Icons.local_fire_department, color: Colors.white, size: 12*ws),
            ),
            SizedBox(width: 5*ws),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Calories:',
                  style: GoogleFonts.poppins(
                      fontSize: 8*ws, color: _C.textMed, fontWeight: FontWeight.w500)),
              Text('$_displayCalories kcal',
                  style: GoogleFonts.poppins(
                      fontSize: 12*ws, fontWeight: FontWeight.w700, color: _C.orange)),
            ]),
          ]),
        ])),

      ]),
    );
  }

  // ─── Summary Cards ────────────────────────────────────────────────────────
  Widget _buildSummaryCards(double ws, double hs) {
    // ── Daily tab ──────────────────────────────────────────────────────────
    if (_mainTabIndex == 0 || _selectedDate != null) {
      final steps    = _selectedDate != null ? _selectedSteps : _dailySteps;
      final calories = HealthService.stepsToCalories(steps);
      final goalPct  = _dailyGoal > 0
          ? ((steps / _dailyGoal) * 100).round()
          : 0;
      return Row(children: [
        _SummaryTile(
            title: _selectedDate != null ? 'Steps' : "Today's Steps",
            value: _formatNumber(steps),
            unit:  'Steps',
            ws: ws, hs: hs),
        SizedBox(width: 6*ws),
        _SummaryTile(
            title: _selectedDate != null ? 'Calories' : "Today's Cal",
            value: '$calories',
            unit:  'kcal',
            ws: ws, hs: hs),
        SizedBox(width: 6*ws),
        _SummaryTile(
            title: 'Goal',
            value: goalPct >= 100 ? '✓ Done' : '$goalPct%',
            unit:  '${_formatNumber(_dailyGoal)} target',
            ws: ws, hs: hs),
      ]);
    }

    // ── Weekly tab ─────────────────────────────────────────────────────────
    if (_mainTabIndex == 1) {
      final best      = _weekBestDay;
      final bestLabel = best.steps > 0 ? best.label : '—';
      final bestUnit  = best.steps > 0 ? _formatNumber(best.steps) : '0 steps';
      return Row(children: [
        _SummaryTile(
            title: 'Weekly Steps',
            value: _formatNumber(_weeklySteps),
            unit:  'Steps',
            ws: ws, hs: hs),
        SizedBox(width: 6*ws),
        _SummaryTile(
            title: 'Weekly Cal',
            value: '${HealthService.stepsToCalories(_weeklySteps)}',
            unit:  'kcal',
            ws: ws, hs: hs),
        SizedBox(width: 6*ws),
        _SummaryTile(
            title: 'Best Day',
            value: bestLabel,
            unit:  bestUnit,
            ws: ws, hs: hs),
      ]);
    }

    // ── Monthly tab ────────────────────────────────────────────────────────
    final best       = _monthBestDay ?? DaySteps('—', 0, DateTime.now());
    final bestLabel  = best.steps > 0 ? best.label : '—';
    final bestUnit   = best.steps > 0 ? _formatNumber(best.steps) : '0 steps';
    final activeDays = _calendarSteps.length;
    return Row(children: [
      _SummaryTile(
          title: 'Monthly Steps',
          value: _formatNumber(_monthlySteps),
          unit:  'Steps',
          ws: ws, hs: hs),
      SizedBox(width: 6*ws),
      _SummaryTile(
          title: 'Monthly Cal',
          value: '${HealthService.stepsToCalories(_monthlySteps)}',
          unit:  'kcal',
          ws: ws, hs: hs),
      SizedBox(width: 6*ws),
      _SummaryTile(
          title: 'Best Day',
          value: bestLabel,
          unit:  '$bestUnit • ${activeDays}d',
          ws: ws, hs: hs),
    ]);
  }

  // ─── Graph Card ───────────────────────────────────────────────────────────
  Widget _buildGraphCard(double ws, double hs) {
    final now  = DateTime.now();
    final data = _monthAllDays;
    if (data.isEmpty) return const SizedBox.shrink();

    final maxSteps = data.fold<double>(
        _dailyGoal.toDouble(), (m, d) => math.max(m, d.steps.toDouble()));
    final maxY = (maxSteps / 1000).ceilToDouble() + 1;

    const barW    = 28.0;
    const spacing = 8.0;
    const unitW   = barW + spacing;

    return Container(
      padding: EdgeInsets.fromLTRB(10*ws, 8*hs, 10*ws, 4*hs),
      decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(14*ws),
          boxShadow: _C.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(
              _selectedDate != null
                  ? _formatDate(_selectedDate!)
                  : '${_monthName(now.month)} ${now.year}',
              style: GoogleFonts.poppins(
                  fontSize: 11*ws, fontWeight: FontWeight.w700, color: _C.textDark)),
          const Spacer(),
          Text('Steps (k)',
              style: GoogleFonts.poppins(
                  fontSize: 9*ws, color: _C.textLight, fontWeight: FontWeight.w500)),
        ]),
        SizedBox(height: 5*hs),
        SizedBox(
          height: 88*hs,
          child: SingleChildScrollView(
            controller: _graphScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: data.length * unitW,
              child: BarChart(BarChartData(
                maxY: maxY,
                barGroups: List.generate(data.length, (i) {
                  final d       = data[i];
                  final isToday = d.date.day == now.day;
                  final isSel   = _selectedDate != null &&
                      d.date.day == _selectedDate!.day;
                  final color   = isSel
                      ? _C.orange
                      : isToday
                      ? AppTheme.primaryGreen
                      : _barColors[i % _barColors.length];
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: d.steps > 0 ? d.steps / 1000 : 0.1,
                      color: color.withOpacity(d.steps > 0 ? 1.0 : 0.15),
                      width: barW,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(4*ws),
                          topRight: Radius.circular(4*ws)),
                    ),
                  ]);
                }),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 18,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= data.length) return const SizedBox.shrink();
                      final d     = data[i];
                      final isSel = _selectedDate != null &&
                          d.date.day == _selectedDate!.day;
                      return Text(d.label,
                          style: GoogleFonts.poppins(
                              fontSize: 7.5*ws,
                              color: isSel ? _C.orange : _C.textMed,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500));
                    },
                  )),
                  leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData:   FlBorderData(show: false),
                gridData:     FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.black.withOpacity(0.05), strokeWidth: 1),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent && response?.spot != null) {
                      final i = response!.spot!.touchedBarGroupIndex;
                      if (i >= 0 && i < data.length) {
                        _selectDate(data[i].date);
                      }
                    }
                  },
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final d = data[groupIndex];
                      return BarTooltipItem(
                        '${d.label}\n${_formatNumber(d.steps)} steps',
                        GoogleFonts.poppins(
                            fontSize: 9*ws,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ),
              )),
            ),
          ),
        ),
      ]),
    );
  }

  // ─── PERFECTLY ALIGNED Calendar Section ───────────────────────────────────
  Widget _buildCalendarSection(double ws, double hs) {
    final now          = DateTime.now();
    final daysInMonth  = DateTimeHelper.daysInMonth(now.year, now.month);
    final leadingBlanks= DateTime(now.year, now.month, 1).weekday - 1; // Mon=1
    final monthName    = _monthName(now.month);

    final showTotal    = _selectedDate != null ? _selectedSteps : _monthlySteps;
    final activeCount  = _selectedDate != null
        ? (_selectedSteps > 0 ? 1 : 0)
        : _calendarSteps.length;
    final avgSteps     = _selectedDate != null
        ? _selectedSteps
        : (_calendarSteps.isEmpty
        ? 0
        : _calendarSteps.values.fold<int>(0, (s, v) => s + v) ~/
        _calendarSteps.length);

    const weekDayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: EdgeInsets.fromLTRB(10*ws, 8*hs, 10*ws, 8*hs),
      decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(14*ws),
          boxShadow: _C.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header ─────────────────────────────────────────────────────────
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$monthName ${now.year}',
              style: GoogleFonts.poppins(
                  fontSize: 12*ws, fontWeight: FontWeight.w700, color: _C.textDark)),
          if (_selectedDate != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8*ws, vertical: 3*hs),
              decoration: BoxDecoration(
                  color: _C.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20*ws),
                  border: Border.all(color: _C.orange.withOpacity(0.3))),
              child: Text(_formatDate(_selectedDate!),
                  style: GoogleFonts.poppins(
                      fontSize: 9*ws, color: _C.orange, fontWeight: FontWeight.w700)),
            ),
        ]),
        SizedBox(height: 5*hs),
        LayoutBuilder(builder: (ctx, constraints) {
          const cols      = 7;
          final spacing   = ws * 2.5;
          final totalGap  = spacing * (cols - 1);
          final cellW     = (constraints.maxWidth - totalGap) / cols;
          final cellH     = cellW * 0.58; // ultra-compact pill-style cells

          return Column(children: [
            // Weekday labels row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weekDayLabels.asMap().entries.map((e) {
                final isSun = e.key == 6;
                final isSat = e.key == 5;
                return SizedBox(
                  width: cellW,
                  child: Center(
                    child: Text(e.value,
                        style: GoogleFonts.poppins(
                            fontSize: ws * 7.5,
                            fontWeight: FontWeight.w600,
                            color: (isSun || isSat)
                                ? _C.primary.withOpacity(0.55)
                                : _C.textLight)),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: ws * 2),

            // Day cells
            Wrap(
              spacing: spacing,
              runSpacing: spacing * 0.75,
              children: [
                // Leading blank cells
                ...List.generate(leadingBlanks,
                        (_) => SizedBox(width: cellW, height: cellH)),

                // Actual day cells
                ...List.generate(daysInMonth, (i) {
                  final day       = i + 1;
                  final steps     = _calendarSteps[day];
                  final hasData   = steps != null && steps > 0;
                  final intensity = hasData ? (steps / 12000).clamp(0.0, 1.0) : 0.0;
                  final isToday   = day == now.day && _selectedDate == null;
                  final isSelected= _selectedDate?.day == day;
                  final isFuture  = day > now.day;

                  Color borderColor;
                  Color bgColor;
                  Color textColor;

                  if (isSelected) {
                    borderColor = _C.orange;
                    bgColor     = _C.orange.withOpacity(0.88);
                    textColor   = Colors.white;
                  } else if (isToday) {
                    borderColor = AppTheme.primaryGreen;
                    bgColor     = AppTheme.primaryGreen.withOpacity(0.12);
                    textColor   = AppTheme.primaryGreen;
                  } else if (hasData) {
                    borderColor = Colors.transparent;
                    bgColor     = AppTheme.primaryGreen.withOpacity(0.08 + intensity * 0.55);
                    textColor   = intensity > 0.6 ? Colors.white : _C.textDark;
                  } else {
                    borderColor = Colors.transparent;
                    bgColor     = isFuture
                        ? Colors.transparent
                        : const Color(0xFFF5F5F5);
                    textColor   = isFuture ? _C.textLight : _C.textMed;
                  }

                  return GestureDetector(
                    onTap: isFuture ? null : () {
                      final tapped = DateTime(now.year, now.month, day);
                      if (isSelected) {
                        _clearSelection();
                      } else {
                        _selectDate(tapped);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: cellW, height: cellH,
                      decoration: BoxDecoration(
                        color: bgColor,
                        border: (isSelected || isToday) ? Border.all(
                            color: borderColor, width: 1.4) : null,
                        borderRadius: BorderRadius.circular(ws * 5),
                      ),
                      alignment: Alignment.center,
                      child: Text(day.toString(),
                          style: GoogleFonts.poppins(
                              fontSize: ws * 7.5,
                              fontWeight: (isSelected || isToday)
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: textColor)),
                    ),
                  );
                }),
              ],
            ),
          ]);
        }),

        SizedBox(height: 6*hs),
        Divider(color: Colors.black.withOpacity(0.05), height: 1),
        SizedBox(height: 6*hs),

        // ── Stats row ──────────────────────────────────────────────────────
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _CalendarStat(
              _selectedDate != null ? 'Steps' : 'Total',
              _formatNumber(showTotal), 'Steps', ws, hs),
          Container(height: 28*hs, width: 1, color: Colors.black.withOpacity(0.06)),
          _CalendarStat(
              _selectedDate != null ? 'Calories' : 'Avg',
              _selectedDate != null
                  ? '${HealthService.stepsToCalories(showTotal)}'
                  : _formatNumber(avgSteps),
              _selectedDate != null ? 'kcal' : 'Steps/Day', ws, hs),
          Container(height: 28*hs, width: 1, color: Colors.black.withOpacity(0.06)),
          _CalendarStat(
              _selectedDate != null ? 'Goal %' : 'Active',
              _selectedDate != null
                  ? (_selectedSteps >= _dailyGoal
                  ? '✓ Done'
                  : '${((_selectedSteps / _dailyGoal) * 100).round()}%')
                  : activeCount.toString(),
              _selectedDate != null ? '' : 'Days', ws, hs),
        ]),
      ]),
    );
  }

  // ─── Fun Fact ─────────────────────────────────────────────────────────────
  Widget _buildFunFact(double ws, double hs) {
    return Container(
      padding: EdgeInsets.all(10*ws),
      decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(14*ws),
          boxShadow: _C.cardShadow),
      child: Row(children: [
        Expanded(child: Text(
            'You burned ${HealthService.stepsToCalories(_displaySteps)} kcal',
            style: GoogleFonts.poppins(
                fontSize: 10*ws, color: _C.textMed, fontWeight: FontWeight.w500))),
        SizedBox(width: 3*ws),
        Icon(Icons.arrow_forward, size: 12*ws, color: AppTheme.primaryGreen),
        SizedBox(width: 4*ws),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6*ws, vertical: 3*hs),
          decoration: BoxDecoration(
              color: _C.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(5*ws)),
          child: Text('🍫 chocolate',
              style: GoogleFonts.poppins(
                  fontSize: 9*ws, color: _C.orange, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  // ─── Set Goal Button ──────────────────────────────────────────────────────
  Widget _buildSetGoalButton(double ws, double hs) {
    bool pressed = false;
    return StatefulBuilder(builder: (context, setBtn) {
      return GestureDetector(
        onTapDown:   (_) => setBtn(() => pressed = true),
        onTapUp:     (_) => setBtn(() => pressed = false),
        onTapCancel: ()  => setBtn(() => pressed = false),
        onTap: () async {
          setBtn(() => pressed = false);
          final newGoal = await Navigator.push<int>(
            context,
            MaterialPageRoute(builder: (_) => SetGoalScreen(initialGoal: _dailyGoal)),
          );
          if (newGoal != null && newGoal != _dailyGoal) {
            setState(() => _dailyGoal = newGoal);
            _animateRing();
            // ✅ Persist so goal survives app kill/reopen
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt(_prefKeyGoal, newGoal);
            } catch (_) {}
            // ✅ Sync goal to RewardsProvider and backend settings API
            try {
              if (context.mounted) {
                await context.read<RewardsProvider>().setStepsGoal(newGoal);
              }
            } catch (e) {
              debugPrint('Error syncing step goal: $e');
            }
            // ✅ Sync goal to native StepCountService so notifications use correct value
            try {
              await StepCounterService.instance.setGoal(newGoal);
            } catch (_) {}
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 10*hs),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: pressed
                  ? [AppTheme.darkGreen, AppTheme.primaryGreen]
                  : [AppTheme.primaryGreen, AppTheme.darkGreen],
              begin: Alignment.centerLeft, end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(26*ws),
            boxShadow: [BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(pressed ? 0.18 : 0.38),
                blurRadius: pressed ? 4 : 10,
                offset: Offset(0, pressed ? 2 : 6))],
          ),
          transform: pressed
              ? (Matrix4.identity()..scale(0.97, 0.97))
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          child: Center(child: Text('Set Daily Goal',
              style: GoogleFonts.poppins(
                  fontSize: 14*ws, fontWeight: FontWeight.w700,
                  color: Colors.white, letterSpacing: 0.5))),
        ),
      );
    });
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String _formatNumber(int n) {
    if (n < 1000) return n.toString();
    final s  = n.toString();
    final sb = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) sb.write(',');
      sb.write(s[i]);
    }
    return sb.toString();
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month-1]} ${d.day}';
  }

  String _monthName(int m) => const [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ][m - 1];
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SummaryTile extends StatelessWidget {
  final String title, value, unit;
  final double ws, hs;
  const _SummaryTile({required this.title, required this.value,
    required this.unit, required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6*ws, vertical: 6*hs),
        decoration: BoxDecoration(
            color: _C.card, borderRadius: BorderRadius.circular(10*ws),
            boxShadow: _C.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 8*ws, fontWeight: FontWeight.w600, color: _C.textLight),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 2*hs),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 11*ws, fontWeight: FontWeight.w700, color: _C.textDark),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(unit,
              style: GoogleFonts.poppins(
                  fontSize: 8*ws, color: _C.textMed, fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

class _CalendarStat extends StatelessWidget {
  final String label, value, unit;
  final double ws, hs;
  const _CalendarStat(this.label, this.value, this.unit, this.ws, this.hs);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(label, style: GoogleFonts.poppins(
          fontSize: 8*ws, color: _C.textLight, fontWeight: FontWeight.w500)),
      Text(value, style: GoogleFonts.poppins(
          fontSize: 12*ws, fontWeight: FontWeight.w800, color: _C.textDark)),
      if (unit.isNotEmpty)
        Text(unit, style: GoogleFonts.poppins(
            fontSize: 7.5*ws, color: _C.textMed, fontWeight: FontWeight.w500)),
    ]);
  }
}

// ─── Ring Painter ─────────────────────────────────────────────────────────────
class _CircularProgressPainter extends CustomPainter {
  final double progress, strokeWidth;
  final Color trackColor, progressColor;
  _CircularProgressPainter({
    required this.progress, required this.trackColor,
    required this.progressColor, required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    canvas.drawCircle(center, radius, Paint()
      ..color = trackColor ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth ..strokeCap = StrokeCap.round);

    if (progress > 0) {
      final rect       = Rect.fromCircle(center: center, radius: radius);
      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

      // Glow layer
      canvas.drawArc(rect, startAngle, sweepAngle, false, Paint()
        ..color = progressColor.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

      // Main arc with gradient
      canvas.drawArc(rect, startAngle, sweepAngle, false, Paint()
        ..style = PaintingStyle.stroke ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: startAngle, endAngle: startAngle + sweepAngle,
          colors: [progressColor.withOpacity(0.8), progressColor],
          stops: const [0.0, 1.0],
        ).createShader(rect));

      // End dot
      final dotAngle  = startAngle + sweepAngle;
      final dotCenter = Offset(
          center.dx + radius * math.cos(dotAngle),
          center.dy + radius * math.sin(dotAngle));
      canvas.drawCircle(dotCenter, strokeWidth/2+1, Paint()..color = Colors.white);
      canvas.drawCircle(dotCenter, strokeWidth/2-0.8, Paint()..color = progressColor);
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter o) => o.progress != progress;
}