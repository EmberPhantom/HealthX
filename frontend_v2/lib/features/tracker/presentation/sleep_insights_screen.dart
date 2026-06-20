import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/tracker_models.dart';
import '../providers/tracker_provider.dart';

class SleepInsightsScreen extends ConsumerStatefulWidget {
  const SleepInsightsScreen({super.key});

  @override
  ConsumerState<SleepInsightsScreen> createState() => _SleepInsightsScreenState();
}

class _SleepInsightsScreenState extends ConsumerState<SleepInsightsScreen>
    with TickerProviderStateMixin {

  late AnimationController _fadeCtrl;
  late AnimationController _scoreCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<double>   _scoreAnim;

  // ── Computed stats ──────────────────────────────────────────────────────
  double  _weekAvg = 0.0;
  double  _sleepDebt = 0.0;     // hours below 7h10m target
  int     _consistencyScore = 75;
  int     _daysOnTarget = 0;
  double  _bestNight = 0.0;
  double  _worstNight = 0.0;
  int     _streak = 0;        // consecutive nights ≥ 7h
  String  _sleepType = '—';     // Early Bird / Night Owl / Balanced
  String  _recommendation = 'No sleep data available yet. Start logging your sleep to get personalized insights.';

  @override
  void initState() {
    super.initState();

    _fadeCtrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900));
    _scoreCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1400));

    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl,  curve: Curves.easeOut);
    _scoreAnim = CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutCubic);

    _fadeCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _scoreCtrl.forward();
    });
  }

  void _computeStats(List<SleepLog> sleepLogs) {
    if (sleepLogs.isEmpty) return;

    // Filter past 7 days logs
    
    // Sort logs descending to easily get streak
    final logs = List<SleepLog>.from(sleepLogs);
    logs.sort((a, b) => b.dateKey.compareTo(a.dateKey));

    final valid = logs.take(7).where((e) {
      final hours = e.wakeTime.difference(e.bedtime).inMinutes / 60.0;
      return hours > 0;
    }).toList();

    const target = 7.1667; // 7h 10m

    final actualHoursList = valid.map((e) => e.wakeTime.difference(e.bedtime).inMinutes / 60.0).toList();

    _weekAvg = valid.isEmpty ? 0.0
        : actualHoursList.reduce((a, b) => a + b) / valid.length;

    _sleepDebt = valid.isEmpty ? 0.0
        : actualHoursList.map((h) => math.max(0.0, target - h)).reduce((a, b) => a + b);

    _daysOnTarget = actualHoursList.where((h) => h >= target).length;

    _bestNight  = valid.isEmpty ? 0.0 : actualHoursList.reduce(math.max);
    _worstNight = valid.isEmpty ? 0.0 : actualHoursList.reduce(math.min);

    // Consistency = how tightly clustered the hours are (lower variance = better)
    if (valid.length < 2) {
      _consistencyScore = 75;
    } else {
      final mean = _weekAvg;
      final variance = actualHoursList.map((h) => math.pow(h - mean, 2)).reduce((a, b) => a + b) / valid.length;
      final stdDev = math.sqrt(variance);
      // stdDev 0 = 100%, stdDev 2+ = 0%
      _consistencyScore = ((1 - (stdDev / 2.0).clamp(0.0, 1.0)) * 100).round();
    }

    // Streak
    int streak = 0;
    for (var log in logs) {
      final h = log.wakeTime.difference(log.bedtime).inMinutes / 60.0;
      if (h >= target) {
        streak++;
      } else {
        break;
      }
    }
    _streak = streak;

    // Sleep type from latest bedtime
    if (logs.isNotEmpty) {
      final bh = logs.first.bedtime.hour;
      if (bh >= 21 && bh <= 23) {
        _sleepType = 'Early Bird 🌅';
      } else if (bh >= 0 && bh <= 1) {
        _sleepType = 'Night Owl 🦉';
      } else {
        _sleepType = 'Balanced 🌙';
      }
    } else {
      _sleepType = '—';
    }

    // Personalized recommendation
    if (_weekAvg < 5.0) {
      _recommendation = 'Critical: You\'re severely sleep-deprived. Aim for 7h 10m every night. Consider an earlier bedtime this week.';
    } else if (_weekAvg < 6.5) {
      _recommendation = 'You\'re running a ${_sleepDebt.toStringAsFixed(1)}h sleep debt. Shift bedtime 30 min earlier for one week to recover.';
    } else if (_weekAvg >= 7.0 && _weekAvg <= 7.5) {
      _recommendation = 'Excellent! You\'re hitting your target. Keep your bedtime consistent to lock in the habit.';
    } else if (_weekAvg > 9.0) {
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

  String _formatTimeLabel(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour12:${m.toString().padLeft(2, '0')} $period'.toLowerCase();
  }

  int _calculateQualityScore(Duration duration) {
    final mins = duration.inMinutes;
    if (mins <= 0) return 0;
    if (mins < 240) {
      return ((mins / 240.0) * 30).round();
    }
    if (mins < 430) {
      return (30 + ((mins - 240) / (430 - 240)) * 70).round();
    }
    if (mins == 430) return 100;
    if (mins <= 480) {
      return (100 - ((mins - 430) / (480 - 430)) * 5).round();
    }
    if (mins <= 540) {
      return (95 - ((mins - 480) / (540 - 480)) * 10).round();
    }
    if (mins <= 660) {
      return (85 - ((mins - 540) / (660 - 540)) * 25).round();
    }
    return 60;
  }

  String _qualityLabel(int score) {
    if (score >= 95) return 'Perfect';
    if (score >= 85) return 'Great';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Fair';
    if (score >= 30) return 'Poor';
    return 'Very Poor';
  }

  @override
  Widget build(BuildContext context) {
    final trackerState = ref.watch(trackerProvider);
    final sleepLogs = trackerState.sleepLogs;

    _computeStats(sleepLogs);

    final todayLog = sleepLogs.isNotEmpty ? sleepLogs.first : null;
    final todayDuration = todayLog != null ? todayLog.wakeTime.difference(todayLog.bedtime) : Duration.zero;
    final todayScore = todayLog != null ? _calculateQualityScore(todayDuration) : 0;
    final todayHours = todayDuration.inMinutes / 60.0;

    return LayoutBuilder(builder: (context, constraints) {
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

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(children: [

                // ── Header ──────────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(20 * ws, 12 * hs, 20 * ws, 0),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 38 * ws, height: 38 * ws,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Icon(PhosphorIconsRegular.arrowLeft,
                            color: Colors.white, size: 18 * ws),
                      ),
                    ),
                    SizedBox(width: 14 * ws),
                    Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sleep Insights',
                              style: TextStyle(color: Colors.white,
                                  fontSize: 18 * ws, fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3)),
                          Text('Last 7 days analysis',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 11 * ws,
                                  fontWeight: FontWeight.w500)),
                        ]),
                    const Spacer(),
                    Text('🌙', style: TextStyle(fontSize: 22 * ws)),
                  ]),
                ),

                SizedBox(height: 16 * hs),

                // ── Scrollable content ──────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16 * ws),
                    child: Column(children: [

                      // ── Big Score Card ────────────────────────────────────
                      _buildScoreCard(todayLog, todayScore, todayHours, ws, hs),
                      SizedBox(height: 12 * hs),

                      // ── Stats Row ─────────────────────────────────────────
                      _buildStatsRow(ws, hs),
                      SizedBox(height: 12 * hs),

                      // ── Weekly Bar Chart ──────────────────────────────────
                      _buildWeeklyChart(sleepLogs, ws, hs),
                      SizedBox(height: 12 * hs),

                      // ── Sleep Debt + Consistency row ──────────────────────
                      _buildDebtConsistencyRow(ws, hs),
                      SizedBox(height: 12 * hs),

                      // ── Sleep Phase Breakdown ─────────────────────────────
                      _buildPhaseBreakdown(todayLog, todayDuration, ws, hs),
                      SizedBox(height: 12 * hs),

                      // ── Sleep Profile card ────────────────────────────────
                      _buildSleepProfile(ws, hs),
                      SizedBox(height: 12 * hs),

                      // ── Recommendation card ───────────────────────────────
                      _buildRecommendation(ws, hs),
                      SizedBox(height: 24 * hs),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      );
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _card({
    required double ws, 
    required double hs,
    required Widget child, 
    EdgeInsetsGeometry? padding,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(16 * ws),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D2240).withValues(alpha: 0.8),
            const Color(0xFF071425).withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16 * ws),
        border: Border.all(
            color: borderColor ?? AppColors.sleepAccent.withValues(alpha: 0.30)),
      ),
      child: child,
    );
  }

  // ── Big Score Card ────────────────────────────────────────────────────────
  Widget _buildScoreCard(SleepLog? todayLog, int score, double hours, double ws, double hs) {
    final hasData = todayLog != null && hours > 0;

    return _card(
      ws: ws, hs: hs,
      borderColor: AppColors.sleepAccent.withValues(alpha: 0.5),
      padding: EdgeInsets.all(20 * ws),
      child: Row(children: [

        // Circular score gauge
        SizedBox(
          width: 90 * ws, height: 90 * ws,
          child: AnimatedBuilder(
            animation: _scoreAnim,
            builder: (context, child) => CustomPaint(
              painter: _ScoreGaugePainter(
                  progress: hasData ? _scoreAnim.value * score / 100 : 0.0,
                  score: (hasData ? _scoreAnim.value * score : 0).round()),
            ),
          ),
        ),

        SizedBox(width: 20 * ws),

        // Right side info
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tonight's Score", style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55), fontSize: 11 * ws, fontWeight: FontWeight.bold)),
            SizedBox(height: 4 * hs),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(hasData ? _hoursLabel(hours) : '—',
                  style: TextStyle(color: Colors.white,
                      fontSize: 24 * ws, fontWeight: FontWeight.w800,
                      height: 1.0)),
              SizedBox(width: 6 * ws),
              Padding(
                padding: EdgeInsets.only(bottom: 2 * hs),
                child: Text(hasData ? _qualityLabel(score) : '',
                    style: TextStyle(
                        color: _scoreColor(score), fontSize: 12 * ws,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
            SizedBox(height: 10 * hs),
            // Mini metric row
            Row(children: [
              _miniMetric('🌙', 'Bed', hasData
                  ? _formatTimeLabel(todayLog.bedtime) : '—', ws, hs),
              SizedBox(width: 16 * ws),
              _miniMetric('☀️', 'Wake', hasData
                  ? _formatTimeLabel(todayLog.wakeTime) : '—', ws, hs),
            ]),
            SizedBox(height: 8 * hs),
            // 7h10m target bar
            _targetBar(hasData ? hours : 0.0, ws, hs),
          ],
        )),
      ]),
    );
  }

  Widget _miniMetric(String icon, String label, String value,
      double ws, double hs) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$icon $label', style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4), fontSize: 9.5 * ws, fontWeight: FontWeight.w600)),
      Text(value, style: TextStyle(color: Colors.white,
          fontSize: 11 * ws, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _targetBar(double hours, double ws, double hs) {
    const target = 7.1667;
    final pct = (hours / target).clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Target: 7h 10m', style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4), fontSize: 9.5 * ws, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text('${(pct * 100).round()}%', style: TextStyle(
            color: _scoreColor((pct * 100).round()),
            fontSize: 9.5 * ws, fontWeight: FontWeight.bold)),
      ]),
      SizedBox(height: 4 * hs),
      ClipRRect(
        borderRadius: BorderRadius.circular(4 * ws),
        child: Stack(children: [
          Container(height: 5 * hs,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4 * ws))),
          FractionallySizedBox(widthFactor: pct,
            child: Container(height: 5 * hs,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    _scoreColor((pct * 100).round()),
                    _scoreColor((pct * 100).round()).withValues(alpha: 0.7),
                  ]),
                  borderRadius: BorderRadius.circular(4 * ws),
                )),
          ),
        ]),
      ),
    ]);
  }

  Color _scoreColor(int score) {
    if (score >= 90) return AppColors.success;
    if (score >= 70) return AppColors.sleepAccent;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  // ── Stats Row (4 tiles) ───────────────────────────────────────────────────
  Widget _buildStatsRow(double ws, double hs) {
    return Row(children: [
      _statTile('📊', 'Weekly Avg', _hoursLabel(_weekAvg), ws, hs),
      SizedBox(width: 8 * ws),
      _statTile('🎯', 'On Target', '$_daysOnTarget/7 days', ws, hs),
      SizedBox(width: 8 * ws),
      _statTile('🔥', 'Streak', '$_streak days', ws, hs),
      SizedBox(width: 8 * ws),
      _statTile('⭐', 'Best Night', _hoursLabel(_bestNight), ws, hs),
    ]);
  }

  Widget _statTile(String icon, String label, String value,
      double ws, double hs) {
    return Expanded(child: Container(
      padding: EdgeInsets.symmetric(vertical: 12 * hs, horizontal: 8 * ws),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D2240).withValues(alpha: 0.8),
            const Color(0xFF071425).withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(12 * ws),
        border: Border.all(color: AppColors.sleepAccent.withValues(alpha: 0.20)),
      ),
      child: Column(children: [
        Text(icon, style: TextStyle(fontSize: 16 * ws)),
        SizedBox(height: 6 * hs),
        Text(value, style: TextStyle(color: Colors.white,
            fontSize: 11 * ws, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        SizedBox(height: 2 * hs),
        Text(label, style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 8.5 * ws, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
      ]),
    ));
  }

  // ── Weekly Bar Chart ──────────────────────────────────────────────────────
  Widget _buildWeeklyChart(List<SleepLog> sleepLogs, double ws, double hs) {
    final now = DateTime.now();
    final labels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return ['M','T','W','T','F','S','S'][d.weekday - 1];
    });

    // Extract hours for past 7 days in order
    final hours = List<double>.filled(7, 0.0);
    for (int i = 0; i < 7; i++) {
      final targetDate = now.subtract(Duration(days: 6 - i));
      final targetKey = DateFormat('yyyy-MM-dd').format(targetDate);
      final log = sleepLogs.firstWhere(
        (e) => e.dateKey == targetKey,
        orElse: () => SleepLog(id: '', bedtime: DateTime.fromMillisecondsSinceEpoch(0), wakeTime: DateTime.fromMillisecondsSinceEpoch(0), dateKey: ''),
      );
      if (log.id.isNotEmpty) {
        hours[i] = log.wakeTime.difference(log.bedtime).inMinutes / 60.0;
      }
    }

    const target = 7.1667;

    return _card(ws: ws, hs: hs, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Sleep This Week', style: TextStyle(color: Colors.white,
              fontSize: 13 * ws, fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8 * ws, vertical: 3 * hs),
            decoration: BoxDecoration(
              color: AppColors.sleepAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8 * ws),
              border: Border.all(
                  color: AppColors.sleepAccent.withValues(alpha: 0.3)),
            ),
            child: Text('Target: 7h 10m', style: TextStyle(
                color: AppColors.sleepAccent, fontSize: 9 * ws,
                fontWeight: FontWeight.bold)),
          ),
        ]),
        SizedBox(height: 16 * hs),

        // Chart
        SizedBox(
          height: 120 * hs,
          child: AnimatedBuilder(
            animation: _scoreAnim,
            builder: (context, child) => CustomPaint(
              size: Size(double.infinity, 120 * hs),
              painter: _WeeklyBarChartPainter(
                  hoursData: hours,
                  animProgress: _scoreAnim.value,
                  target: target,
                  scale: ws),
            ),
          ),
        ),
        SizedBox(height: 8 * hs),

        // Day labels
        Row(
          children: List.generate(7, (i) => Expanded(
            child: Center(child: Text(labels[i], style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 10 * ws, fontWeight: FontWeight.bold))),
          )),
        ),
        SizedBox(height: 8 * hs),

        // Legend
        Row(children: [
          _legendDot(AppColors.sleepAccent), SizedBox(width: 4 * ws),
          Text('Actual', style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5), fontSize: 9 * ws, fontWeight: FontWeight.bold)),
          SizedBox(width: 12 * ws),
          _legendDot(AppColors.sleepAccent, isDash: true),
          SizedBox(width: 4 * ws),
          Text('Target', style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5), fontSize: 9 * ws, fontWeight: FontWeight.bold)),
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
        borderColor: _sleepDebt > 3.0
            ? AppColors.error.withValues(alpha: 0.5)
            : AppColors.sleepAccent.withValues(alpha: 0.30),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('😴', style: TextStyle(fontSize: 14 * ws)),
            SizedBox(width: 6 * ws),
            Text('Sleep Debt', style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55), fontSize: 11 * ws, fontWeight: FontWeight.bold)),
          ]),
          SizedBox(height: 10 * hs),
          Text(_sleepDebt > 0 ? '-${_hoursLabel(_sleepDebt)}' : '0h',
              style: TextStyle(
                  color: _sleepDebt > 0
                      ? AppColors.error : AppColors.success,
                  fontSize: 20 * ws, fontWeight: FontWeight.w800)),
          SizedBox(height: 4 * hs),
          Text(_sleepDebt <= 0.0 ? 'No debt! 🎉'
              : _sleepDebt < 3.0 ? 'Manageable'
              : 'Recovery needed',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 9.5 * ws, fontWeight: FontWeight.bold)),
        ]),
      )),

      SizedBox(width: 10 * ws),

      // Consistency
      Expanded(child: _card(ws: ws, hs: hs,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('📐', style: TextStyle(fontSize: 14 * ws)),
            SizedBox(width: 6 * ws),
            Text('Consistency', style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55), fontSize: 11 * ws, fontWeight: FontWeight.bold)),
          ]),
          SizedBox(height: 10 * hs),
          AnimatedBuilder(
            animation: _scoreAnim,
            builder: (context, child) {
              final v = (_scoreAnim.value * _consistencyScore).round();
              return Text('$v%', style: TextStyle(color: Colors.white,
                  fontSize: 20 * ws, fontWeight: FontWeight.w800));
            },
          ),
          SizedBox(height: 4 * hs),
          // Mini bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3 * ws),
            child: AnimatedBuilder(
              animation: _scoreAnim,
              builder: (context, child) => Stack(children: [
                Container(height: 4 * hs,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(3 * ws))),
                FractionallySizedBox(
                  widthFactor: _scoreAnim.value * _consistencyScore / 100,
                  child: Container(height: 4 * hs,
                      decoration: BoxDecoration(
                          color: AppColors.sleepAccent,
                          borderRadius: BorderRadius.circular(3 * ws))),
                ),
              ]),
            ),
          ),
        ]),
      )),
    ]);
  }

  // ── Sleep Phase Breakdown ─────────────────────────────────────────────────
  Widget _buildPhaseBreakdown(SleepLog? todayLog, Duration duration, double ws, double hs) {
    final total = duration.inMinutes;

    final deepMinutes = (total * 0.22).round();
    final lightMinutes = (total * 0.53).round();
    final remMinutes = (total * 0.20).round();
    final awakeMinutes = math.max(0, total - deepMinutes - lightMinutes - remMinutes);

    final phases = [
      _PhaseData('Deep Sleep',   '🟣', deepMinutes, total, const Color(0xFF818CF8)),
      _PhaseData('Light Sleep',  '🔵', lightMinutes, total, AppColors.sleepAccent),
      _PhaseData('REM Sleep',    '🟡', remMinutes, total, const Color(0xFFFBBF24)),
      _PhaseData('Awake',        '⚪', awakeMinutes, total, const Color(0xFF6B7280)),
    ];

    return _card(ws: ws, hs: hs, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sleep Phase Breakdown', style: TextStyle(color: Colors.white,
            fontSize: 13 * ws, fontWeight: FontWeight.bold)),
        SizedBox(height: 4 * hs),
        Text('Based on last night\'s sleep', style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4), fontSize: 10 * ws, fontWeight: FontWeight.w500)),
        SizedBox(height: 14 * hs),

        // Segmented bar
        if (total > 0) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(6 * ws),
            child: SizedBox(
              height: 10 * hs,
              child: AnimatedBuilder(
                animation: _scoreAnim,
                builder: (context, child) => Row(
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
          SizedBox(height: 14 * hs),
        ],

        // Phase list
        ...phases.map((p) => Padding(
          padding: EdgeInsets.only(bottom: 10 * hs),
          child: Row(children: [
            Container(width: 10 * ws, height: 10 * ws,
                decoration: BoxDecoration(
                    color: p.color, borderRadius: BorderRadius.circular(3 * ws))),
            SizedBox(width: 8 * ws),
            Expanded(child: Text(p.name,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12 * ws, fontWeight: FontWeight.w500))),
            Text(
                total > 0 ? _minsLabel(p.minutes) : '—',
                style: TextStyle(color: Colors.white,
                    fontSize: 12 * ws, fontWeight: FontWeight.bold)),
            SizedBox(width: 8 * ws),
            SizedBox(
              width: 50 * ws,
              child: Text(
                  total > 0 ? '${(p.minutes / total * 100).round()}%' : '—',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11 * ws, fontWeight: FontWeight.bold),
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
      borderColor: const Color(0xFFFBBF24).withValues(alpha: 0.35),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Sleep Profile', style: TextStyle(color: Colors.white,
            fontSize: 13 * ws, fontWeight: FontWeight.bold)),
        SizedBox(height: 14 * hs),
        Row(children: [
          _profileStat('Sleep Type',  _sleepType,       '🦉', ws, hs),
          _vDivider(ws),
          _profileStat('Best Night',  _hoursLabel(_bestNight),  '⭐', ws, hs),
          _vDivider(ws),
          _profileStat('Worst Night', _hoursLabel(_worstNight), '😴', ws, hs),
        ]),
        SizedBox(height: 14 * hs),
        Row(children: [
          _profileStat('Days on Target', '$_daysOnTarget/7',  '🎯', ws, hs),
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
      Text(icon, style: TextStyle(fontSize: 18 * ws)),
      SizedBox(height: 5 * hs),
      Text(value, style: TextStyle(color: Colors.white,
          fontSize: 11 * ws, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center),
      SizedBox(height: 2 * hs),
      Text(label, style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4), fontSize: 9 * ws, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center),
    ]));
  }

  Widget _vDivider(double ws) => Container(
      width: 1, height: 50,
      color: AppColors.sleepAccent.withValues(alpha: 0.20));

  // ── Recommendation ────────────────────────────────────────────────────────
  Widget _buildRecommendation(double ws, double hs) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18 * ws),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            const Color(0xFF071628).withValues(alpha: 0.8),
            const Color(0xFF0D1F3C).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16 * ws),
        border: Border.all(
            color: AppColors.sleepAccent.withValues(alpha: 0.45)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36 * ws, height: 36 * ws,
            decoration: BoxDecoration(
              color: AppColors.sleepAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10 * ws),
            ),
            child: Center(child:
            Text('💡', style: TextStyle(fontSize: 16 * ws))),
          ),
          SizedBox(width: 10 * ws),
          Text('Personalized Tip', style: TextStyle(color: Colors.white,
              fontSize: 13 * ws, fontWeight: FontWeight.bold)),
        ]),
        SizedBox(height: 12 * hs),
        Text(_recommendation, style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 12 * ws, height: 1.6, fontWeight: FontWeight.w500)),
        SizedBox(height: 12 * hs),
        // Reminder row
        Row(children: [
          Icon(PhosphorIconsRegular.alarm, color: AppColors.sleepAccent, size: 14 * ws),
          SizedBox(width: 6 * ws),
          Flexible(
            child: Text('Ideal: sleep 10:50 PM → wake 6:00 AM',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 9.5 * ws, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
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
              colors: const [Color(0xFF818CF8), Color(0xFF6366F1), Color(0xFF4F46E5)],
              transform: const GradientRotation(-math.pi/2),
            ).createShader(rect));
    }

    // Center text
    final tp1 = TextPainter(
      text: TextSpan(text: '$score',
          style: TextStyle(color: Colors.white, fontSize: size.width*0.28,
              fontWeight: FontWeight.w800)),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp1.paint(canvas, c - Offset(tp1.width/2, tp1.height/2 + 6));

    final tp2 = TextPainter(
      text: TextSpan(text: 'score',
          style: TextStyle(color: Colors.white.withValues(alpha:0.4),
              fontSize: size.width*0.12, fontWeight: FontWeight.bold)),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset(c.dx - tp2.width/2, c.dy + tp1.height/2 - 4));
  }

  @override bool shouldRepaint(covariant _ScoreGaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.score != score;
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
    final dashP = Paint()..color=AppColors.sleepAccent.withValues(alpha:0.55)
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
                ? [AppColors.sleepAccent, const Color(0xFF312E81)]
                : [AppColors.sleepAccent.withValues(alpha:0.5),
              const Color(0xFF0D3060).withValues(alpha:0.5)],
            [0.0, 1.0],
          ));

      // Hours label on bar
      if (hoursData[i] > 0) {
        final label = '${hoursData[i].floor()}h';
        final tp = TextPainter(
          text: TextSpan(text: label,
              style: TextStyle(color: Colors.white.withValues(alpha:0.7),
                  fontSize: 8*scale, fontWeight: FontWeight.bold)),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        final ty = size.height - barH - tp.height - 3;
        if (ty > 0) tp.paint(canvas, Offset(cx - tp.width/2, ty));
      }
    }
  }

  @override bool shouldRepaint(covariant _WeeklyBarChartPainter oldDelegate) =>
      oldDelegate.animProgress != animProgress;
}
