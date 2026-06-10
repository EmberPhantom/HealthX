// lib/screens/sleep_insights_screen.dart
// Professional Sleep Insights Screen
// ✅ Deep analytics: score breakdown, trend analysis, sleep debt, consistency
// ✅ Luxury dark astronomical theme — matches sleep tracker aesthetic
// ✅ Smooth animations on entry

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/sleep_entry.dart';
import '../theme/theme.dart';

class SleepInsightsScreen extends StatefulWidget {
  final SleepEntry?       todayEntry;
  final List<SleepEntry>  last7Days;

  const SleepInsightsScreen({
    super.key,
    required this.todayEntry,
    required this.last7Days,
  });

  @override
  State<SleepInsightsScreen> createState() => _SleepInsightsScreenState();
}

class _SleepInsightsScreenState extends State<SleepInsightsScreen>
    with TickerProviderStateMixin {

  late AnimationController _fadeCtrl;
  late AnimationController _scoreCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<double>   _scoreAnim;

  // ── Computed stats ──────────────────────────────────────────────────────
  late final double  _weekAvg;
  late final double  _sleepDebt;     // hours below 7h10m target
  late final int     _consistencyScore;
  late final int     _daysOnTarget;
  late final double  _bestNight;
  late final double  _worstNight;
  late final int     _streak;        // consecutive nights ≥ 7h
  late final String  _sleepType;     // Early Bird / Night Owl
  late final String  _recommendation;

  @override
  void initState() {
    super.initState();

    _computeStats();

    _fadeCtrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900));
    _scoreCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1400));

    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl,  curve: Curves.easeOut);
    _scoreAnim = CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutCubic);

    _fadeCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300),
            () => _scoreCtrl.forward());
  }

  void _computeStats() {
    final valid = widget.last7Days.where((e) => e.totalHours > 0).toList();
    const target = 7.1667; // 7h 10m

    _weekAvg = valid.isEmpty ? 0.0
        : valid.map((e) => e.totalHours).reduce((a,b) => a+b) / valid.length;

    _sleepDebt = valid.isEmpty ? 0.0
        : valid.map((e) => math.max(0.0, target - e.totalHours))
        .reduce((a,b) => a+b);

    _daysOnTarget = valid.where((e) => e.totalHours >= target).length;

    _bestNight  = valid.isEmpty ? 0.0
        : valid.map((e) => e.totalHours).reduce(math.max);
    _worstNight = valid.isEmpty ? 0.0
        : valid.map((e) => e.totalHours).reduce(math.min);

    // Consistency = how tightly clustered the hours are (lower variance = better)
    if (valid.length < 2) {
      _consistencyScore = 75;
    } else {
      final mean = _weekAvg;
      final variance = valid.map((e) => math.pow(e.totalHours - mean, 2))
          .reduce((a,b) => a+b) / valid.length;
      final stdDev = math.sqrt(variance);
      // stdDev 0 = 100%, stdDev 2+ = 0%
      _consistencyScore = ((1 - (stdDev / 2.0).clamp(0.0, 1.0)) * 100).round();
    }

    // Streak
    int streak = 0;
    for (int i = widget.last7Days.length - 1; i >= 0; i--) {
      if (widget.last7Days[i].totalHours >= target) { streak++; }
      else { break; }
    }
    _streak = streak;

    // Sleep type from bedtime
    final entry = widget.todayEntry;
    if (entry != null) {
      final bh = entry.bedtime.hour;
      if (bh >= 21 && bh <= 23) _sleepType = 'Early Bird 🌅';
      else if (bh >= 0 && bh <= 1) _sleepType = 'Night Owl 🦉';
      else _sleepType = 'Balanced 🌙';
    } else {
      _sleepType = '—';
    }

    // Personalized recommendation
    if (_weekAvg < 5) {
      _recommendation = 'Critical: You\'re severely sleep-deprived. Aim for 7h 10m every night. Consider an earlier bedtime this week.';
    } else if (_weekAvg < 6.5) {
      _recommendation = 'You\'re running a ${_sleepDebt.toStringAsFixed(1)}h sleep debt. Shift bedtime 30 min earlier for one week to recover.';
    } else if (_weekAvg >= 7.0 && _weekAvg <= 7.5) {
      _recommendation = 'Excellent! You\'re hitting your target. Keep your bedtime consistent to lock in the habit.';
    } else if (_weekAvg > 9) {
      _recommendation = 'You\'re oversleeping slightly. Try getting up at the same time daily — even weekends.';
    } else if (_consistencyScore < 60) {
      _recommendation = 'Your sleep hours are inconsistent. A fixed bedtime builds better sleep quality over time.';
    } else {
      _recommendation = 'Good sleep habits! Your consistency score is strong. Keep it up!';
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scoreCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  String _hoursLabel(double h) {
    if (h <= 0) return '—';
    final hh = h.floor();
    final mm = ((h - hh) * 60).round();
    if (mm == 0) return '${hh}h';
    return '${hh}h ${mm}m';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final ws = constraints.maxWidth / 360.0;
      final hs = MediaQuery.of(context).size.height / 800.0;

      return Scaffold(
        body: Stack(children: [
          // Background
          Positioned.fill(child: CustomPaint(painter: _NightSkyPainter())),

          // Subtle radial glow top-center
          Positioned(
            top: -80, left: 0, right: 0,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter, radius: 0.8,
                  colors: [
                    const Color(0xFF0D1F3C).withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(children: [

              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(20*ws, 12*hs, 20*ws, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38*ws, height: 38*ws,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 16*ws),
                    ),
                  ),
                  SizedBox(width: 14*ws),
                  Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sleep Insights',
                            style: TextStyle(color: Colors.white,
                                fontSize: 20*ws, fontWeight: FontWeight.w700,
                                letterSpacing: 0.3)),
                        Text('Last 7 days analysis',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 11*ws)),
                      ]),
                  const Spacer(),
                  // Moon phase decoration
                  Text('🌙', style: TextStyle(fontSize: 24*ws)),
                ]),
              ),

              SizedBox(height: 16*hs),

              // ── Scrollable content ──────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16*ws),
                  child: Column(children: [

                    // ── Big Score Card ────────────────────────────────────
                    _buildScoreCard(ws, hs),
                    SizedBox(height: 12*hs),

                    // ── Stats Row ─────────────────────────────────────────
                    _buildStatsRow(ws, hs),
                    SizedBox(height: 12*hs),

                    // ── Weekly Bar Chart ──────────────────────────────────
                    _buildWeeklyChart(ws, hs),
                    SizedBox(height: 12*hs),

                    // ── Sleep Debt + Consistency row ──────────────────────
                    _buildDebtConsistencyRow(ws, hs),
                    SizedBox(height: 12*hs),

                    // ── Sleep Phase Breakdown ─────────────────────────────
                    _buildPhaseBreakdown(ws, hs),
                    SizedBox(height: 12*hs),

                    // ── Sleep Profile card ────────────────────────────────
                    _buildSleepProfile(ws, hs),
                    SizedBox(height: 12*hs),

                    // ── Recommendation card ───────────────────────────────
                    _buildRecommendation(ws, hs),
                    SizedBox(height: 20*hs),
                  ]),
                ),
              ),
            ]),
          )),
        ]),
      );
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _card({required double ws, required double hs,
    required Widget child, EdgeInsetsGeometry? padding,
    Color? borderColor}) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(16*ws),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D2240).withValues(alpha: 0.7),
            const Color(0xFF071425).withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20*ws),
        border: Border.all(
            color: borderColor ?? AppTheme.primaryGreen.withValues(alpha: 0.30)),
      ),
      child: child,
    );
  }

  // ── Big Score Card ────────────────────────────────────────────────────────
  Widget _buildScoreCard(double ws, double hs) {
    final score = widget.todayEntry?.qualityScore ?? 0;
    final hasData = widget.todayEntry != null && widget.todayEntry!.totalHours > 0;

    return _card(
      ws: ws, hs: hs,
      borderColor: AppTheme.primaryGreen.withValues(alpha: 0.5),
      padding: EdgeInsets.all(20*ws),
      child: Row(children: [

        // Circular score gauge
        SizedBox(
          width: 100*ws, height: 100*ws,
          child: AnimatedBuilder(
            animation: _scoreAnim,
            builder: (_, __) => CustomPaint(
              painter: _ScoreGaugePainter(
                  progress: hasData ? _scoreAnim.value * score / 100 : 0.0,
                  score: (hasData ? _scoreAnim.value * score : 0).round()),
            ),
          ),
        ),

        SizedBox(width: 20*ws),

        // Right side info
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tonight's Score", style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55), fontSize: 11*ws)),
            SizedBox(height: 4*hs),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(hasData ? '${widget.todayEntry!.durationLabel}' : '—',
                  style: TextStyle(color: Colors.white,
                      fontSize: 28*ws, fontWeight: FontWeight.w800,
                      height: 1.0)),
              SizedBox(width: 6*ws),
              Padding(
                padding: EdgeInsets.only(bottom: 3*hs),
                child: Text(hasData ? widget.todayEntry!.qualityLabel : '',
                    style: TextStyle(
                        color: _scoreColor(score), fontSize: 12*ws,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
            SizedBox(height: 10*hs),
            // Mini metric row
            Row(children: [
              _miniMetric('🌙', 'Bed', hasData
                  ? widget.todayEntry!.bedtimeLabel : '—', ws, hs),
              SizedBox(width: 16*ws),
              _miniMetric('☀️', 'Wake', hasData
                  ? widget.todayEntry!.wakeTimeLabel : '—', ws, hs),
            ]),
            SizedBox(height: 8*hs),
            // 7h10m target bar
            _targetBar(hasData ? widget.todayEntry!.totalHours : 0, ws, hs),
          ],
        )),
      ]),
    );
  }

  Widget _miniMetric(String icon, String label, String value,
      double ws, double hs) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$icon $label', style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4), fontSize: 9.5*ws)),
      Text(value, style: TextStyle(color: Colors.white,
          fontSize: 12*ws, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _targetBar(double hours, double ws, double hs) {
    const target = 7.1667;
    final pct = (hours / target).clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Target: 7h 10m', style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4), fontSize: 9.5*ws)),
        const Spacer(),
        Text('${(pct * 100).round()}%', style: TextStyle(
            color: _scoreColor((pct * 100).round()),
            fontSize: 9.5*ws, fontWeight: FontWeight.w600)),
      ]),
      SizedBox(height: 4*hs),
      ClipRRect(
        borderRadius: BorderRadius.circular(4*ws),
        child: Stack(children: [
          Container(height: 5*hs,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4*ws))),
          FractionallySizedBox(widthFactor: pct,
            child: Container(height: 5*hs,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    _scoreColor((pct*100).round()),
                    _scoreColor((pct*100).round()).withValues(alpha: 0.7),
                  ]),
                  borderRadius: BorderRadius.circular(4*ws),
                )),
          ),
        ]),
      ),
    ]);
  }

  Color _scoreColor(int score) {
    if (score >= 90) return AppTheme.primaryGreen;
    if (score >= 70) return AppTheme.darkGreen;
    if (score >= 50) return const Color(0xFFFFB74D);
    return const Color(0xFFEF5350);
  }

  // ── Stats Row (4 tiles) ───────────────────────────────────────────────────
  Widget _buildStatsRow(double ws, double hs) {
    return Row(children: [
      _statTile('📊', 'Weekly Avg', _hoursLabel(_weekAvg), ws, hs),
      SizedBox(width: 8*ws),
      _statTile('🎯', 'On Target', '$_daysOnTarget / 7 days', ws, hs),
      SizedBox(width: 8*ws),
      _statTile('🔥', 'Streak', '$_streak days', ws, hs),
      SizedBox(width: 8*ws),
      _statTile('⭐', 'Best Night', _hoursLabel(_bestNight), ws, hs),
    ]);
  }

  Widget _statTile(String icon, String label, String value,
      double ws, double hs) {
    return Expanded(child: Container(
      padding: EdgeInsets.symmetric(vertical: 12*hs, horizontal: 8*ws),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D2240).withValues(alpha: 0.7),
            const Color(0xFF071425).withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16*ws),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.28)),
      ),
      child: Column(children: [
        Text(icon, style: TextStyle(fontSize: 18*ws)),
        SizedBox(height: 6*hs),
        Text(value, style: TextStyle(color: Colors.white,
            fontSize: 11*ws, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        SizedBox(height: 2*hs),
        Text(label, style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 8.5*ws), textAlign: TextAlign.center),
      ]),
    ));
  }

  // ── Weekly Bar Chart ──────────────────────────────────────────────────────
  Widget _buildWeeklyChart(double ws, double hs) {
    final now    = DateTime.now();
    final labels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6-i));
      return ['M','T','W','T','F','S','S'][d.weekday-1];
    });
    final hours  = widget.last7Days.map((e) => e.totalHours).toList();
    const target = 7.1667;

    return _card(ws: ws, hs: hs, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Sleep This Week', style: TextStyle(color: Colors.white,
              fontSize: 13*ws, fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8*ws, vertical: 3*hs),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8*ws),
              border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
            ),
            child: Text('Target: 7h 10m', style: TextStyle(
                color: AppTheme.primaryGreen, fontSize: 9*ws,
                fontWeight: FontWeight.w600)),
          ),
        ]),
        SizedBox(height: 16*hs),

        // Chart
        SizedBox(
          height: 120*hs,
          child: AnimatedBuilder(
            animation: _scoreAnim,
            builder: (_, __) => CustomPaint(
              size: Size(double.infinity, 120*hs),
              painter: _WeeklyBarChartPainter(
                  hoursData: hours,
                  animProgress: _scoreAnim.value,
                  target: target,
                  scale: ws),
            ),
          ),
        ),
        SizedBox(height: 8*hs),

        // Day labels
        Row(
          children: List.generate(7, (i) => Expanded(
            child: Center(child: Text(labels[i], style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 10*ws, fontWeight: FontWeight.w500))),
          )),
        ),
        SizedBox(height: 8*hs),

        // Legend
        Row(children: [
          _legendDot(AppTheme.primaryGreen), SizedBox(width: 4*ws),
          Text('Actual', style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5), fontSize: 9*ws)),
          SizedBox(width: 12*ws),
          _legendDot(AppTheme.primaryGreen, isDash: true),
          SizedBox(width: 4*ws),
          Text('Target', style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5), fontSize: 9*ws)),
        ]),
      ],
    ));
  }

  Widget _legendDot(Color color, {bool isDash = false}) {
    return Container(
      width: isDash ? 14 : 8, height: isDash ? 2 : 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(isDash ? 1 : 4),
      ),
    );
  }

  // ── Sleep Debt + Consistency ──────────────────────────────────────────────
  Widget _buildDebtConsistencyRow(double ws, double hs) {
    return Row(children: [

      // Sleep Debt
      Expanded(child: _card(ws: ws, hs: hs,
        borderColor: _sleepDebt > 3
            ? const Color(0xFFEF5350).withValues(alpha: 0.5)
            : AppTheme.primaryGreen.withValues(alpha: 0.30),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('😴', style: TextStyle(fontSize: 16*ws)),
            SizedBox(width: 6*ws),
            Text('Sleep Debt', style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55), fontSize: 11*ws)),
          ]),
          SizedBox(height: 10*hs),
          Text(_sleepDebt > 0 ? '-${_hoursLabel(_sleepDebt)}' : '0h',
              style: TextStyle(
                  color: _sleepDebt > 0
                      ? const Color(0xFFEF5350) : AppTheme.primaryGreen,
                  fontSize: 22*ws, fontWeight: FontWeight.w800)),
          SizedBox(height: 4*hs),
          Text(_sleepDebt <= 0 ? 'No debt! 🎉'
              : _sleepDebt < 3 ? 'Manageable'
              : 'Recovery needed',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 9.5*ws)),
        ]),
      )),

      SizedBox(width: 10*ws),

      // Consistency
      Expanded(child: _card(ws: ws, hs: hs,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('📐', style: TextStyle(fontSize: 16*ws)),
            SizedBox(width: 6*ws),
            Text('Consistency', style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55), fontSize: 11*ws)),
          ]),
          SizedBox(height: 10*hs),
          AnimatedBuilder(
            animation: _scoreAnim,
            builder: (_, __) {
              final v = (_scoreAnim.value * _consistencyScore).round();
              return Text('$v%', style: TextStyle(color: Colors.white,
                  fontSize: 22*ws, fontWeight: FontWeight.w800));
            },
          ),
          SizedBox(height: 4*hs),
          // Mini bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3*ws),
            child: AnimatedBuilder(
              animation: _scoreAnim,
              builder: (_, __) => Stack(children: [
                Container(height: 4*hs,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(3*ws))),
                FractionallySizedBox(
                  widthFactor: _scoreAnim.value * _consistencyScore / 100,
                  child: Container(height: 4*hs,
                      decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(3*ws))),
                ),
              ]),
            ),
          ),
        ]),
      )),
    ]);
  }

  // ── Sleep Phase Breakdown ─────────────────────────────────────────────────
  Widget _buildPhaseBreakdown(double ws, double hs) {
    final entry = widget.todayEntry;
    final total = entry?.duration.inMinutes ?? 0;

    final phases = [
      _PhaseData('Deep Sleep',   '🟣', entry?.deepSleep.inMinutes  ?? 0, total, AppTheme.darkGreen),
      _PhaseData('Light Sleep',  '🔵', entry?.lightSleep.inMinutes ?? 0, total, AppTheme.primaryGreen),
      _PhaseData('REM Sleep',    '🟡', entry?.remSleep.inMinutes   ?? 0, total, const Color(0xFFE8B84B)),
      _PhaseData('Awake',        '⚪', math.max(0, total - (entry?.deepSleep.inMinutes ?? 0)
          - (entry?.lightSleep.inMinutes ?? 0) - (entry?.remSleep.inMinutes ?? 0)),
          total, const Color(0xFF4B5568)),
    ];

    return _card(ws: ws, hs: hs, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sleep Phase Breakdown', style: TextStyle(color: Colors.white,
            fontSize: 13*ws, fontWeight: FontWeight.w700)),
        SizedBox(height: 4*hs),
        Text('Based on last night\'s sleep', style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4), fontSize: 10*ws)),
        SizedBox(height: 14*hs),

        // Segmented bar
        if (total > 0) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(6*ws),
            child: SizedBox(
              height: 10*hs,
              child: AnimatedBuilder(
                animation: _scoreAnim,
                builder: (_, __) => Row(
                  children: phases.map((p) {
                    final frac = total > 0 ? p.minutes / total : 0.0;
                    return Flexible(
                      flex: (frac * 1000).round(),
                      child: Container(color: p.color),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          SizedBox(height: 14*hs),
        ],

        // Phase list
        ...phases.map((p) => Padding(
          padding: EdgeInsets.only(bottom: 10*hs),
          child: Row(children: [
            Container(width: 10*ws, height: 10*ws,
                decoration: BoxDecoration(
                    color: p.color, borderRadius: BorderRadius.circular(3*ws))),
            SizedBox(width: 8*ws),
            Expanded(child: Text(p.name,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12*ws))),
            Text(
                total > 0 ? _minsLabel(p.minutes) : '—',
                style: TextStyle(color: Colors.white,
                    fontSize: 12*ws, fontWeight: FontWeight.w700)),
            SizedBox(width: 8*ws),
            SizedBox(
              width: 50*ws,
              child: Text(
                  total > 0 ? '${(p.minutes/total*100).round()}%' : '—',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11*ws),
                  textAlign: TextAlign.end),
            ),
          ]),
        )),
      ],
    ));
  }

  String _minsLabel(int mins) {
    if (mins <= 0) return '0m';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  // ── Sleep Profile ─────────────────────────────────────────────────────────
  Widget _buildSleepProfile(double ws, double hs) {
    return _card(ws: ws, hs: hs,
      borderColor: const Color(0xFFE8B84B).withValues(alpha: 0.35),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Sleep Profile', style: TextStyle(color: Colors.white,
            fontSize: 13*ws, fontWeight: FontWeight.w700)),
        SizedBox(height: 14*hs),
        Row(children: [
          _profileStat('Sleep Type',  _sleepType,       '🦉', ws, hs),
          _vDivider(ws),
          _profileStat('Best Night',  _hoursLabel(_bestNight),  '⭐', ws, hs),
          _vDivider(ws),
          _profileStat('Worst Night', _hoursLabel(_worstNight), '😴', ws, hs),
        ]),
        SizedBox(height: 14*hs),
        Row(children: [
          _profileStat('Days on Target', '$_daysOnTarget / 7',  '🎯', ws, hs),
          _vDivider(ws),
          _profileStat('Weekly Avg',  _hoursLabel(_weekAvg),    '📊', ws, hs),
          _vDivider(ws),
          _profileStat('Streak',      '$_streak days',           '🔥', ws, hs),
        ]),
      ]),
    );
  }

  Widget _profileStat(String label, String value, String icon,
      double ws, double hs) {
    return Expanded(child: Column(children: [
      Text(icon, style: TextStyle(fontSize: 18*ws)),
      SizedBox(height: 5*hs),
      Text(value, style: TextStyle(color: Colors.white,
          fontSize: 11*ws, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center),
      SizedBox(height: 2*hs),
      Text(label, style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4), fontSize: 9*ws),
          textAlign: TextAlign.center),
    ]));
  }

  Widget _vDivider(double ws) => Container(
      width: 1, height: 50,
      color: AppTheme.primaryGreen.withValues(alpha: 0.28));

  // ── Recommendation ────────────────────────────────────────────────────────
  Widget _buildRecommendation(double ws, double hs) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18*ws),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            const Color(0xFF071628).withValues(alpha: 0.8),
            const Color(0xFF0D1F3C).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20*ws),
        border: Border.all(
            color: AppTheme.primaryGreen.withValues(alpha: 0.45)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36*ws, height: 36*ws,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10*ws),
            ),
            child: Center(child:
            Text('💡', style: TextStyle(fontSize: 18*ws))),
          ),
          SizedBox(width: 10*ws),
          Text('Personalized Tip', style: TextStyle(color: Colors.white,
              fontSize: 13*ws, fontWeight: FontWeight.w700)),
        ]),
        SizedBox(height: 12*hs),
        Text(_recommendation, style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 12*ws, height: 1.6)),
        SizedBox(height: 12*hs),
        // Reminder row
        Row(children: [
          Icon(Icons.alarm, color: AppTheme.primaryGreen, size: 14*ws),
          SizedBox(width: 6*ws),
          Flexible(
            child: Text('Ideal: sleep 10:50 PM → wake 6:00 AM',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 9.5*ws, fontStyle: FontStyle.italic),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
          ),
        ]),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Data class
// ══════════════════════════════════════════════════════════════════════════════
class _PhaseData {
  final String name;
  final String icon;
  final int    minutes;
  final int    totalMinutes;
  final Color  color;
  const _PhaseData(this.name, this.icon, this.minutes,
      this.totalMinutes, this.color);
}

// ══════════════════════════════════════════════════════════════════════════════
//  Custom Painters
// ══════════════════════════════════════════════════════════════════════════════

class _NightSkyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0,0,size.width,size.height),
        Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0,size.height),
            [const Color(0xFF030C18),const Color(0xFF040F1E),
              const Color(0xFF071628),const Color(0xFF040D1C)],
            [0.0,0.3,0.7,1.0]));
    final rng = math.Random(77);
    final p   = Paint();
    for (int i = 0; i < 140; i++) {
      final alpha = rng.nextDouble()*0.55 + 0.15;
      p.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(
          Offset(rng.nextDouble()*size.width, rng.nextDouble()*size.height),
          rng.nextDouble()*1.3+0.2, p);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _ScoreGaugePainter extends CustomPainter {
  final double progress;
  final int    score;
  _ScoreGaugePainter({required this.progress, required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width/2, size.height/2);
    final r = size.width/2 - 8;

    // Track
    canvas.drawCircle(c, r,
        Paint()..color=const Color(0xFF0A2040).withValues(alpha:0.6)
          ..style=PaintingStyle.stroke..strokeWidth=8..strokeCap=StrokeCap.round);

    // Arc
    if (progress > 0) {
      final rect = Rect.fromCircle(center: c, radius: r);
      canvas.drawArc(rect, -math.pi/2, 2*math.pi*progress, false,
          Paint()..style=PaintingStyle.stroke..strokeWidth=8..strokeCap=StrokeCap.round
            ..shader=SweepGradient(
              startAngle: -math.pi/2, endAngle: -math.pi/2 + 2*math.pi*progress,
              colors: const [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
              transform: const GradientRotation(-math.pi/2),
            ).createShader(rect));
    }

    // Center text
    final tp1 = TextPainter(
      text: TextSpan(text: '$score',
          style: TextStyle(color: Colors.white, fontSize: size.width*0.28,
              fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp1.paint(canvas, c - Offset(tp1.width/2, tp1.height/2 + 6));

    final tp2 = TextPainter(
      text: TextSpan(text: 'score',
          style: TextStyle(color: Colors.white.withValues(alpha:0.4),
              fontSize: size.width*0.12)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset(c.dx - tp2.width/2, c.dy + tp1.height/2 - 4));
  }

  @override bool shouldRepaint(covariant _ScoreGaugePainter o) =>
      o.progress != progress || o.score != score;
}

class _WeeklyBarChartPainter extends CustomPainter {
  final List<double> hoursData;
  final double       animProgress;
  final double       target;
  final double       scale;

  _WeeklyBarChartPainter({required this.hoursData, required this.animProgress,
    required this.target, required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    const maxH  = 10.0;
    final gw    = size.width / 7;
    final bw    = gw * 0.45;
    final tY    = size.height * (1 - (target/maxH).clamp(0,1));

    // Target dashed line
    final dashP = Paint()..color=const Color(0xFF10B981).withValues(alpha:0.55)
      ..strokeWidth=1.2;
    double dx = 0;
    while (dx < size.width) {
      canvas.drawLine(Offset(dx, tY), Offset(dx+5, tY), dashP);
      dx += 9;
    }

    // Bars
    for (int i = 0; i < 7; i++) {
      final h    = hoursData[i] * animProgress;
      if (h <= 0) continue;
      final norm = (h / maxH).clamp(0.0, 1.0);
      final barH = norm * size.height;
      final cx   = (i + 0.5) * gw;
      final onTarget = hoursData[i] >= target;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - bw/2, size.height - barH, bw, barH),
        Radius.circular(4*scale),
      );

      canvas.drawRRect(rect,
          Paint()..shader = ui.Gradient.linear(
            Offset(0, size.height - barH), Offset(0, size.height),
            onTarget
                ? [const Color(0xFF10B981), const Color(0xFF064E3B)]
                : [const Color(0xFF34D399).withValues(alpha:0.5),
              const Color(0xFF0D3060).withValues(alpha:0.5)],
            [0.0, 1.0],
          ));

      // Hours label on bar
      if (hoursData[i] > 0) {
        final label = '${hoursData[i].floor()}h';
        final tp = TextPainter(
          text: TextSpan(text: label,
              style: TextStyle(color: Colors.white.withValues(alpha:0.7),
                  fontSize: 8*scale, fontWeight: FontWeight.w600)),
          textDirection: TextDirection.ltr,
        )..layout();
        final ty = size.height - barH - tp.height - 3;
        if (ty > 0) tp.paint(canvas, Offset(cx - tp.width/2, ty));
      }
    }
  }

  @override bool shouldRepaint(covariant _WeeklyBarChartPainter o) =>
      o.animProgress != animProgress;
}