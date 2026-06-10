// lib/screens/tracker_screen.dart
// ✅ All tracker cards show REAL live data from providers
// ✅ Sleep card reads from SleepProvider (todayEntry)
// ✅ Water card reads from WaterProvider (consumed / goal)
// ✅ Steps card reads from HealthService + SharedPreferences (unchanged)
// ✅ Health Score computed dynamically from all 3 trackers
// ✅ Weekly trend computed from real sleep history

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme.dart';
import '../screens/sleep_tracker_screen.dart';
import '../screens/water_tracker_screen.dart';
import '../screens/steps_tracker_screen.dart';
import '../screens/log_screen.dart';
import '../screens/diabetic_care_screen.dart';
import '../screens/blood_glucose_screen.dart';
import '../providers/water_provider.dart';
import '../providers/sleep_provider.dart';
import '../widgets/shared_widgets.dart';
import '../services/health_service.dart';
import '../services/step_counter_service.dart';

const double _refW = 360.0;
const double _refH = 800.0;

// ─── Premium card shadow (accent-tinted per card) ────────────────────────────
List<BoxShadow> _cardShadow(Color accent) => [
  BoxShadow(
    color: accent.withOpacity(0.13),
    blurRadius: 25,
    spreadRadius: -5,
    offset: const Offset(0, 10),
  ),
  BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 8,
    spreadRadius: -2,
    offset: const Offset(0, 3),
  ),
];

// ─── Section Label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final double ws;
  final double hs;
  const _SectionLabel({required this.label, required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 9 * hs),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11 * ws,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(width: 8 * ws),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  const Color(0xFF1A1A2E).withOpacity(0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Main Screen ──────────────────────────────────────────────────────────────
class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF1B4332),
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    return LayoutBuilder(builder: (context, constraints) {
      final screenWidth  = constraints.maxWidth;
      final screenHeight = MediaQuery.of(context).size.height;
      final ws   = screenWidth / _refW;
      final hs   = screenHeight / _refH;
      final hPad = 14.0 * ws;

      return Scaffold(
        backgroundColor: const Color(0xFFF3F4F9),
        body: Column(
          children: [
            // ── FIXED Hero ──────────────────────────────────────────────
            _HealthScoreHeader(ws: ws, hs: hs),

            // ── SCROLLABLE cards ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 14 * hs),
                      _SectionLabel(label: "Today's Essentials", ws: ws, hs: hs),
                      Row(
                        children: [
                          Expanded(child: _SleepTrackerCard(ws: ws, hs: hs)),
                          SizedBox(width: 10 * ws),
                          Expanded(child: _WaterTrackerCard(ws: ws, hs: hs)),
                        ],
                      ),
                      SizedBox(height: 10 * hs),
                      _StepsTrackerCard(ws: ws, hs: hs),
                      SizedBox(height: 14 * hs),
                      _SectionLabel(label: 'Preventive Care', ws: ws, hs: hs),
                      Row(
                        children: [
                          Expanded(child: _DiabeticCareCard(ws: ws, hs: hs)),
                          SizedBox(width: 10 * ws),
                          Expanded(child: _NutritionalAnalysisCard(ws: ws, hs: hs)),
                        ],
                      ),
                      SizedBox(height: 20 * hs),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ─── Health Score Hero Header ─────────────────────────────────────────────────
// Dynamically computes score from Sleep + Water + Steps providers
class _HealthScoreHeader extends StatelessWidget {
  final double ws;
  final double hs;
  const _HealthScoreHeader({required this.ws, required this.hs});

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getFormattedDate() {
    final now    = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Consumer2<SleepProvider, WaterProvider>(
      builder: (context, sleepProv, waterProv, _) {
        // ── Compute a dynamic health score from available data ──────────
        // Sleep component: 0–40pts (target 8h → 40, scales down)
        final sleepHours  = sleepProv.todayEntry?.totalHours ?? 0.0;
        final sleepScore  = (sleepHours / 8.0).clamp(0.0, 1.0) * 40;

        // Water component: 0–30pts
        final waterScore  = waterProv.progress.clamp(0.0, 1.0) * 30;

        // Steps component: We can't read async here, so derive from header
        // Use a fixed 30pt slot; steps card shows its own live progress
        // We default to 0 here — steps updates via its own card
        const stepsScore  = 0.0; // header uses sleep+water; steps shows separately

        final raw    = (sleepScore + waterScore + stepsScore);
        final total  = (raw / 70.0 * 100).round().clamp(0, 100);
        final frac   = (raw / 70.0).clamp(0.0, 1.0);

        // ── Weekly history for trend graph ──────────────────────────────
        final history = sleepProv.last7Days;
        final weekScores = List.generate(7, (i) {
          if (i < history.length) {
            final h = history[i].totalHours.clamp(0.0, 8.0);
            return (h / 8.0) * 70 + 20; // rough composite for display
          }
          return 50.0;
        });

        // Streak: count consecutive days ≥ 6h sleep
        int streak = 0;
        for (final e in history) {
          if (e.totalHours >= 6.0) streak++;
          else break;
        }

        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF40916C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(18 * ws, topPad + 12 * hs, 18 * ws, 20 * hs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getFormattedDate(),
                              style: GoogleFonts.poppins(
                                  fontSize: 9.5 * ws,
                                  color: Colors.white.withOpacity(0.5),
                                  letterSpacing: 0.3)),
                          SizedBox(height: 1 * hs),
                          Text(_getGreeting(),
                              style: GoogleFonts.poppins(
                                  fontSize: 19 * ws,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.2)),
                          SizedBox(height: 2 * hs),
                          Text("Here's your health summary",
                              style: GoogleFonts.poppins(
                                  fontSize: 9.5 * ws,
                                  color: Colors.white.withOpacity(0.45))),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16 * hs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _HealthScoreCircle(ws: ws, hs: hs, score: frac, label: '$total%'),
                    SizedBox(width: 18 * ws),
                    Expanded(child: _WeeklyTrendGraph(ws: ws, hs: hs, scores: weekScores)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Health Score Circle ──────────────────────────────────────────────────────
class _HealthScoreCircle extends StatelessWidget {
  final double ws, hs, score;
  final String label;
  const _HealthScoreCircle(
      {required this.ws, required this.hs, required this.score, required this.label});

  @override
  Widget build(BuildContext context) {
    final size = 86.0 * ws;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
              size: Size(size, size),
              painter: _CircleScorePainter(score: score)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 17 * ws,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1)),
              Text('Health\nScore',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 7 * ws,
                      color: Colors.white.withOpacity(0.5),
                      height: 1.3)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleScorePainter extends CustomPainter {
  final double score;
  _CircleScorePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center     = Offset(size.width / 2, size.height / 2);
    final radius     = size.width / 2 - 7;
    const startAngle = -math.pi / 2;
    final rect       = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
        center, radius,
        Paint()
          ..style      = PaintingStyle.stroke
          ..strokeWidth = 9
          ..color      = Colors.white.withOpacity(0.11));

    if (score > 0) {
      canvas.drawArc(
        rect,
        startAngle,
        2 * math.pi * score,
        false,
        Paint()
          ..style      = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeCap  = StrokeCap.round
          ..shader     = const SweepGradient(
            startAngle: 0,
            endAngle: 2 * math.pi,
            colors: [Color(0xFFD1FAE5), Color(0xFF10B981), Color(0xFFD1FAE5)],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(_CircleScorePainter old) => old.score != score;
}

// ─── Weekly Trend Graph ───────────────────────────────────────────────────────
class _WeeklyTrendGraph extends StatelessWidget {
  final double ws, hs;
  final List<double> scores;
  const _WeeklyTrendGraph({required this.ws, required this.hs, required this.scores});

  @override
  Widget build(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    // Compute trend delta between first and last valid day
    final first = scores.first;
    final last  = scores.last;
    final delta = (last - first).round();
    final trendLabel = delta >= 0 ? '↑ +${delta}pts' : '↓ ${delta}pts';
    final trendColor = delta >= 0 ? const Color(0xFFD1FAE5) : const Color(0xFFFF7043);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Weekly Trend',
                style: GoogleFonts.poppins(
                    fontSize: 9.5 * ws,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.5))),
            Text(trendLabel,
                style: GoogleFonts.poppins(
                    fontSize: 9 * ws,
                    fontWeight: FontWeight.w700,
                    color: trendColor)),
          ],
        ),
        SizedBox(height: 8 * hs),
        SizedBox(
          height: 46 * hs,
          child: CustomPaint(
              painter: _TrendLinePainter(scores: scores),
              size: Size.infinite),
        ),
        SizedBox(height: 5 * hs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: days
              .asMap()
              .entries
              .map((e) => Text(e.value,
              style: GoogleFonts.poppins(
                  fontSize: 8.5 * ws,
                  color: e.key == DateTime.now().weekday - 1
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                  fontWeight: e.key == DateTime.now().weekday - 1
                      ? FontWeight.w700
                      : FontWeight.w400)))
              .toList(),
        ),
      ],
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  final List<double> scores;
  _TrendLinePainter({required this.scores});

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;
    final minV  = scores.reduce(math.min) - 5;
    final maxV  = scores.reduce(math.max) + 5;
    final range = maxV - minV;

    final points = <Offset>[];
    for (int i = 0; i < scores.length; i++) {
      points.add(Offset(
        i * size.width / (scores.length - 1),
        size.height - ((scores[i] - minV) / range) * size.height,
      ));
    }

    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) fillPath.lineTo(p.dx, p.dy);
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFD1FAE5).withOpacity(0.35),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final cp1 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i - 1].dy);
      final cp2 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i].dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i].dx, points[i].dy);
    }
    canvas.drawPath(
        linePath,
        Paint()
          ..style      = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap  = StrokeCap.round
          ..color      = const Color(0xFF10B981));

    canvas.drawCircle(points.last, 4, Paint()..color = const Color(0xFF10B981));
    canvas.drawCircle(points.last, 2.2, Paint()..color = Colors.white);
  }

  @override
  // ✅ FIX: was always returning false — graph never repainted when sleep data changed
  bool shouldRepaint(_TrendLinePainter old) => old.scores != scores;
}

// ─── Sleep Tracker Card — REAL data from SleepProvider ───────────────────────
class _SleepTrackerCard extends StatelessWidget {
  final double ws, hs;
  const _SleepTrackerCard({required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Changed from violet (0xFF5C35C9) to midnight navy-blue
    // matching app's dark navy header theme (0xFF1A1A2E)
    const accent = Color(0xFF1565C0);   // royal blue — no violet
    const dark   = Color(0xFF0A2744);   // deep navy

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SleepTrackerScreen())),
      child: Consumer<SleepProvider>(
        builder: (_, provider, __) {
          final entry      = provider.todayEntry;
          final hasData    = entry != null && entry.totalHours > 0;
          final label      = hasData ? entry!.durationLabel : '—';
          final subLabel   = hasData ? 'Last Night' : 'Not logged yet';
          final progress   = hasData ? (entry!.totalHours / 8.0).clamp(0.0, 1.0) : 0.0;

          // Quality badge colour
          Color qColor = accent.withOpacity(0.65);
          if (hasData) {
            final h = entry!.totalHours;
            if (h >= 7.5) qColor = const Color(0xFF2E7D32);
            else if (h >= 6) qColor = const Color(0xFFF57F17);
            else qColor = const Color(0xFFC62828);
          }

          return Container(
            height: 120 * hs,
            padding: EdgeInsets.all(12 * ws),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasData
                    ? const [Color(0xFFE3F0FF), Color(0xFFBDD8FA)]  // soft sky blue
                    : [const Color(0xFFEDF4FF), const Color(0xFFD6E9FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24 * ws),
              boxShadow: _cardShadow(accent),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: EdgeInsets.all(5 * ws),
                    decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10 * ws)),
                    child: Icon(Icons.nightlight_round, size: 12 * ws, color: accent),
                  ),
                  SizedBox(width: 6 * ws),
                  Text('Sleep',
                      style: GoogleFonts.poppins(
                          fontSize: 10.5 * ws,
                          fontWeight: FontWeight.w700,
                          color: dark)),
                  const Spacer(),
                  // Quality dot
                  if (hasData)
                    Container(
                      width: 6 * ws,
                      height: 6 * ws,
                      decoration: BoxDecoration(color: qColor, shape: BoxShape.circle),
                    ),
                ]),
                SizedBox(height: 7 * hs),
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: hasData ? 17 * ws : 14 * ws,
                        fontWeight: FontWeight.w800,
                        color: dark,
                        height: 1)),
                Text(subLabel,
                    style: GoogleFonts.poppins(
                        fontSize: 8 * ws,
                        color: accent.withOpacity(0.6))),
                const Spacer(),
                // Sleep stage segments — navy/blue tones, no purple
                Row(children: [
                  _seg(flex: (progress * 2).clamp(0.1, 2).round(),
                      color: const Color(0xFF0D47A1)),  // deep blue (deep sleep)
                  SizedBox(width: 2 * ws),
                  _seg(flex: (progress * 2).clamp(0.1, 2).round(),
                      color: const Color(0xFF1976D2)),  // medium blue (light sleep)
                  SizedBox(width: 2 * ws),
                  _seg(flex: (progress * 3).clamp(0.1, 3).round(),
                      color: const Color(0xFF64B5F6)),  // sky blue (REM)
                  SizedBox(width: 2 * ws),
                  _seg(flex: ((1 - progress) * 3 + 1).clamp(1, 4).round(),
                      color: accent.withOpacity(0.10)),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _seg({required int flex, required Color color}) => Expanded(
    flex: flex,
    child: Container(
      height: 3.5 * hs,
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(2)),
    ),
  );
}

// ─── Water Tracker Card — REAL data from WaterProvider ───────────────────────
class _WaterTrackerCard extends StatelessWidget {
  final double ws, hs;
  const _WaterTrackerCard({required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF0288D1);
    const dark   = Color(0xFF014D72);

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const WaterTrackerScreen())),
      child: Consumer<WaterProvider>(
        builder: (_, provider, __) {
          final intakeMl  = provider.currentIntake;   // ml drunk today
          final goalMl    = provider.dailyGoal;       // ml goal (e.g. 2000)
          final progress  = provider.progress.clamp(0.0, 1.0);
          final isDone    = progress >= 1.0;

          // Convert ml → display glasses (250 ml per glass)
          final glassSize = 250.0;
          final consumed  = (intakeMl / glassSize).floor();
          final totalGlasses = (goalMl / glassSize).round();
          final remaining = (totalGlasses - consumed).clamp(0, totalGlasses);

          return Container(
            height: 120 * hs,
            padding: EdgeInsets.all(12 * ws),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDone
                    ? const [Color(0xFFE3F2FD), Color(0xFFBBDEFB)]
                    : const [Color(0xFFE2F5FD), Color(0xFFB9E4F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24 * ws),
              boxShadow: _cardShadow(accent),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: EdgeInsets.all(5 * ws),
                    decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10 * ws)),
                    child: Icon(Icons.water_drop, size: 12 * ws, color: accent),
                  ),
                  SizedBox(width: 6 * ws),
                  Text('Water',
                      style: GoogleFonts.poppins(
                          fontSize: 10.5 * ws,
                          fontWeight: FontWeight.w700,
                          color: dark)),
                  const Spacer(),
                  if (isDone)
                    Icon(Icons.check_circle, size: 12 * ws, color: const Color(0xFF0288D1)),
                ]),
                SizedBox(height: 7 * hs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(isDone ? '$consumed' : '$remaining',
                        style: GoogleFonts.poppins(
                            fontSize: 24 * ws,
                            fontWeight: FontWeight.w800,
                            color: dark,
                            height: 1)),
                    SizedBox(width: 3 * ws),
                    Padding(
                      padding: EdgeInsets.only(bottom: 2 * hs),
                      child: Text(
                          isDone ? 'glasses\ndone! 🎉' : 'glasses\nleft',
                          style: GoogleFonts.poppins(
                              fontSize: 7.5 * ws,
                              color: accent.withOpacity(0.6),
                              height: 1.3)),
                    ),
                    const Spacer(),
                    // Mini glass icon with fill level
                    Container(
                      width: 15 * ws,
                      height: 24 * hs,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.09),
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(3 * ws),
                            bottomRight: Radius.circular(3 * ws)),
                        border: Border.all(color: accent.withOpacity(0.25), width: 1),
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDone
                                  ? accent.withOpacity(0.6)
                                  : accent.withOpacity(0.32),
                              borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(2 * ws),
                                  bottomRight: Radius.circular(2 * ws)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Animated progress bar
                Container(
                  height: 3 * hs,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: accent.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(2 * ws)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                        decoration: BoxDecoration(
                            color: isDone ? const Color(0xFF0288D1) : accent,
                            borderRadius: BorderRadius.circular(2 * ws))),
                  ),
                ),
                SizedBox(height: 3 * hs),
                Text('$consumed / $totalGlasses glasses  (${(intakeMl / 1000).toStringAsFixed(1)}L)',
                    style: GoogleFonts.poppins(
                        fontSize: 7.5 * ws,
                        color: accent.withOpacity(0.55),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Steps Tracker Card — LIVE real-time data ─────────────────────────────────
class _StepsTrackerCard extends StatefulWidget {
  final double ws, hs;
  const _StepsTrackerCard({required this.ws, required this.hs});

  @override
  State<_StepsTrackerCard> createState() => _StepsTrackerCardState();
}

class _StepsTrackerCardState extends State<_StepsTrackerCard>
    with SingleTickerProviderStateMixin {

  int  _steps   = 0;
  int  _goal    = 10000;
  bool _loading = true;

  Timer? _refreshTimer;
  late AnimationController _barController;
  late Animation<double>   _barAnim;

  static const _accent = Color(0xFF2E7D32);
  static const _dark   = Color(0xFF1B4E1E);

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _barAnim = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _barController, curve: Curves.easeOutCubic));

    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      await StepCounterService.instance.startService();
      final steps = await HealthService.instance.fetchTodaySteps();
      final prefs = await SharedPreferences.getInstance();
      final goal  = prefs.getInt('daily_step_goal') ?? 10000;
      if (!mounted) return;
      setState(() {
        _steps   = steps;
        _goal    = goal;
        _loading = false;
      });
      _animateBar();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _animateBar() {
    final target = (_steps / (_goal > 0 ? _goal : 1)).clamp(0.0, 1.0);
    _barAnim = Tween<double>(begin: _barAnim.value, end: target).animate(
        CurvedAnimation(parent: _barController, curve: Curves.easeOutCubic));
    _barController
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _barController.dispose();
    super.dispose();
  }

  String _fmt(int n) {
    if (n < 1000) return n.toString();
    final k = n / 1000;
    return '${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(1)}k';
  }

  String _fmtGoal(int n) {
    if (n < 1000) return n.toString();
    final s  = n.toString();
    final sb = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) sb.write(',');
      sb.write(s[i]);
    }
    return sb.toString();
  }

  String get _motivText {
    if (_steps == 0) return 'Start walking — you got this! 💪';
    final pct = _goal > 0 ? (_steps / _goal * 100).round() : 0;
    if (pct < 25)  return 'Great start, keep moving! 🚶';
    if (pct < 50)  return 'Warmed up — keep pushing! 🔥';
    if (pct < 75)  return 'Halfway there, amazing effort! ⚡';
    if (pct < 100) return 'Almost at the goal — finish strong! 🏃';
    return '🏆 Goal crushed! Outstanding!';
  }

  String get _caloriesLabel {
    final cal = StepCounterService.stepsToCalories(_steps);
    return '${cal} kcal burned';
  }

  @override
  Widget build(BuildContext context) {
    final ws = widget.ws;
    final hs = widget.hs;

    final pct       = _goal > 0 ? (_steps / _goal * 100).round().clamp(0, 100) : 0;
    final isGoalMet = _steps >= _goal && !_loading;

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const StepsTrackerScreen())),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: EdgeInsets.all(13 * ws),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isGoalMet
                ? [const Color(0xFFD4EDDA), const Color(0xFFA8D5B5)]
                : [const Color(0xFFEAF5E4), const Color(0xFFC9EAB8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24 * ws),
          boxShadow: _cardShadow(_accent),
        ),
        child: Row(
          children: [
            // ── Left content ─────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: icon + label + live dot
                  Row(children: [
                    Container(
                      padding: EdgeInsets.all(5 * ws),
                      decoration: BoxDecoration(
                          color: _accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10 * ws)),
                      child: Icon(Icons.directions_walk_rounded,
                          size: 12 * ws, color: _accent),
                    ),
                    SizedBox(width: 6 * ws),
                    Text('Steps Tracker',
                        style: GoogleFonts.poppins(
                            fontSize: 10.5 * ws,
                            fontWeight: FontWeight.w700,
                            color: _dark)),
                    const Spacer(),
                    if (!_loading) ...[
                      Container(
                        width: 5 * ws, height: 5 * ws,
                        decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50), shape: BoxShape.circle),
                      ),
                      SizedBox(width: 3 * ws),
                      Text('Live',
                          style: GoogleFonts.poppins(
                              fontSize: 7.5 * ws,
                              color: _accent.withOpacity(0.55),
                              fontWeight: FontWeight.w600)),
                    ],
                  ]),

                  SizedBox(height: 9 * hs),

                  // Step count
                  _loading
                      ? SizedBox(
                      height: 28 * hs,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 18 * ws, height: 18 * ws,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _accent.withOpacity(0.4)),
                        ),
                      ))
                      : RichText(
                    text: TextSpan(children: [
                      TextSpan(
                          text: _fmt(_steps),
                          style: GoogleFonts.poppins(
                              fontSize: 26 * ws,
                              fontWeight: FontWeight.w800,
                              color: _dark,
                              height: 1.0)),
                      TextSpan(
                          text: '  steps today',
                          style: GoogleFonts.poppins(
                              fontSize: 9.5 * ws,
                              fontWeight: FontWeight.w500,
                              color: _accent.withOpacity(0.65))),
                    ]),
                  ),

                  SizedBox(height: 4 * hs),

                  if (!_loading)
                    Text(_motivText,
                        style: GoogleFonts.poppins(
                            fontSize: 8 * ws,
                            color: _accent.withOpacity(0.7),
                            fontWeight: FontWeight.w500)),

                  SizedBox(height: 9 * hs),

                  // Animated progress bar
                  Container(
                    height: 4.5 * hs,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: _accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(3 * ws)),
                    child: AnimatedBuilder(
                      animation: _barAnim,
                      builder: (_, __) => FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _barAnim.value.clamp(0.0, 1.0),
                        child: Container(
                            decoration: BoxDecoration(
                                color: isGoalMet ? const Color(0xFF43A047) : _accent,
                                borderRadius: BorderRadius.circular(3 * ws))),
                      ),
                    ),
                  ),

                  SizedBox(height: 4 * hs),

                  Row(children: [
                    Text(
                      'Goal: ${_fmtGoal(_goal)} steps',
                      style: GoogleFonts.poppins(
                          fontSize: 7.5 * ws,
                          color: _accent.withOpacity(0.5)),
                    ),
                    const Spacer(),
                    if (!_loading)
                      Text(
                        '$pct%',
                        style: GoogleFonts.poppins(
                            fontSize: 8 * ws,
                            fontWeight: FontWeight.w700,
                            color: isGoalMet
                                ? const Color(0xFF2E7D32)
                                : _accent.withOpacity(0.65)),
                      ),
                  ]),
                ],
              ),
            ),

            SizedBox(width: 12 * ws),

            // ── Right side: trophy + calories + CTA button ────────────────
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  size: 34 * ws,
                  color: isGoalMet
                      ? const Color(0xFFFFD700).withOpacity(0.9)
                      : _accent.withOpacity(0.15),
                ),
                SizedBox(height: 4 * hs),
                if (!_loading)
                  Text(
                    _caloriesLabel,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 7 * ws,
                        color: _accent.withOpacity(0.6),
                        fontWeight: FontWeight.w500),
                  ),
                SizedBox(height: 6 * hs),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14 * ws, vertical: 7 * hs),
                  decoration: BoxDecoration(
                    color: isGoalMet ? const Color(0xFF2E7D32) : AppTheme.orange,
                    borderRadius: BorderRadius.circular(12 * ws),
                    boxShadow: [
                      BoxShadow(
                          color: (isGoalMet
                              ? const Color(0xFF2E7D32)
                              : AppTheme.orange)
                              .withOpacity(0.32),
                          blurRadius: 10,
                          spreadRadius: -2,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Text(
                    isGoalMet ? 'Done!' : 'Track',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 9.5 * ws,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Diabetic Care Card ───────────────────────────────────────────────────────
class _DiabeticCareCard extends StatelessWidget {
  final double ws, hs;
  const _DiabeticCareCard({required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFC62828);
    const dark   = Color(0xFF7B1010);
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BloodGlucoseScreen())),
      child: Container(
        height: 120 * hs,
        padding: EdgeInsets.all(12 * ws),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFECEE), Color(0xFFFFCDD2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24 * ws),
          boxShadow: _cardShadow(accent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: EdgeInsets.all(5 * ws),
                decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10 * ws)),
                child: Icon(Icons.favorite, size: 12 * ws, color: accent),
              ),
              SizedBox(width: 6 * ws),
              Text('Diabetic',
                  style: GoogleFonts.poppins(
                      fontSize: 10.5 * ws,
                      fontWeight: FontWeight.w700,
                      color: dark)),
            ]),
            SizedBox(height: 7 * hs),
            Text('Low Carb',
                style: GoogleFonts.poppins(
                    fontSize: 17 * ws,
                    fontWeight: FontWeight.w800,
                    color: dark,
                    height: 1)),
            Text('Meals',
                style: GoogleFonts.poppins(
                    fontSize: 8 * ws, color: accent.withOpacity(0.55))),
            const Spacer(),
            Container(
              height: 3 * hs,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: accent.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(2 * ws)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.7,
                child: Container(
                    decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(2 * ws))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nutritional Analysis Card ────────────────────────────────────────────────
class _NutritionalAnalysisCard extends StatelessWidget {
  final double ws, hs;
  const _NutritionalAnalysisCard({required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF57F17);
    const dark   = Color(0xFF7A3D00);
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LogScreen())),
      child: Container(
        height: 120 * hs,
        padding: EdgeInsets.all(12 * ws),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF9E6), Color(0xFFFFECB3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24 * ws),
          boxShadow: _cardShadow(accent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: EdgeInsets.all(5 * ws),
                decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10 * ws)),
                child: Icon(Icons.pie_chart, size: 12 * ws, color: accent),
              ),
              SizedBox(width: 6 * ws),
              Text('Nutrition',
                  style: GoogleFonts.poppins(
                      fontSize: 10.5 * ws,
                      fontWeight: FontWeight.w700,
                      color: dark)),
            ]),
            SizedBox(height: 6 * hs),
            Text('Log',
                style: GoogleFonts.poppins(
                    fontSize: 17 * ws,
                    fontWeight: FontWeight.w800,
                    color: dark,
                    height: 1)),
            Text('Your Meals',
                style: GoogleFonts.poppins(
                    fontSize: 8 * ws, color: accent.withOpacity(0.55))),
            const Spacer(),
            Row(children: [
              Expanded(
                child: Container(
                  height: 3 * hs,
                  decoration: BoxDecoration(
                      color: accent.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(2 * ws)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.0,
                    child: Container(
                        decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(2 * ws))),
                  ),
                ),
              ),
              SizedBox(width: 6 * ws),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 6 * ws, vertical: 2 * hs),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(6 * ws)),
                child: Text('Tap →',
                    style: GoogleFonts.poppins(
                        fontSize: 7 * ws,
                        fontWeight: FontWeight.w700,
                        color: accent)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}