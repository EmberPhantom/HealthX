// lib/screens/sleep_tracker_screen.dart
// ✅ Snooze button & bottom sheet removed from UI (works only via notification)
// ✅ "View Sleep Insights" → navigates to SleepInsightsScreen
// ✅ All original UI preserved

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sleep_entry.dart';
import '../providers/sleep_provider.dart';
import '../theme/theme.dart';
import 'sleep_insights_screen.dart';

class SleepTrackerScreen extends StatefulWidget {
  const SleepTrackerScreen({super.key});
  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringController;
  late Animation<double>   _ringAnimation;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _ringAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
        CurvedAnimation(parent: _ringController, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SleepProvider>().loadFromStorage().then((_) => _animateRing());
    });
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  void _animateRing() {
    if (!mounted) return;
    final target = context.read<SleepProvider>().todayEntry?.ringProgress ?? 0.0;
    _ringAnimation = Tween<double>(begin: 0.0, end: target).animate(
        CurvedAnimation(parent: _ringController, curve: Curves.easeOutCubic));
    _ringController.forward(from: 0.0);
  }

  Future<void> _handleRefresh() async {
    await context.read<SleepProvider>().loadFromStorage();
    _animateRing();
  }

  Future<void> _showLogSleepDialog() async {
    final now = DateTime.now();
    final bedtimePicked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 22, minute: 0),
      helpText: 'SELECT BEDTIME',
      builder: (ctx, child) => _timePickerTheme(child!),
    );
    if (bedtimePicked == null || !mounted) return;

    final wakeTimePicked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 6, minute: 0),
      helpText: 'SELECT WAKE-UP TIME',
      builder: (ctx, child) => _timePickerTheme(child!),
    );
    if (wakeTimePicked == null || !mounted) return;

    DateTime bedtime  = DateTime(now.year, now.month, now.day,
        bedtimePicked.hour, bedtimePicked.minute);
    DateTime wakeTime = DateTime(now.year, now.month, now.day,
        wakeTimePicked.hour, wakeTimePicked.minute);

    if (bedtimePicked.hour >= 18 && wakeTimePicked.hour < 18) {
      bedtime = bedtime.subtract(const Duration(days: 1));
    }

    if (!wakeTime.isAfter(bedtime)) {
      if (mounted) _showSnackBar('⚠️ Wake-up time must be after bedtime.', isError: true);
      return;
    }

    final success = await context.read<SleepProvider>()
        .logSleep(bedtime: bedtime, wakeTime: wakeTime);
    if (!mounted) return;
    if (success) {
      _animateRing();
      final entry = context.read<SleepProvider>().todayEntry;
      _showSnackBar('🌙 Sleep logged! ${entry?.durationLabel ?? ''} recorded ✅');
    }
  }

  Widget _timePickerTheme(Widget child) => Theme(
    data: ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: AppTheme.primaryGreen,
        onPrimary: Colors.white,
        surface: const Color(0xFF071628),
        onSurface: Colors.white,
      ),
      dialogBackgroundColor: const Color(0xFF071628),
    ),
    child: child,
  );

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: isError ? const Color(0xFF7F1D1D) : AppTheme.darkGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final ws = constraints.maxWidth / 360.0;
      final hs = MediaQuery.of(context).size.height / 800.0;

      return Scaffold(
        body: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: StarryNightPainter())),
          SafeArea(
            child: Column(children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20*ws, vertical: 8*hs),
                child: _buildHeader(context, ws, hs),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.primaryGreen,
                  backgroundColor: Colors.white,
                  onRefresh: _handleRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics()),
                    padding: EdgeInsets.symmetric(horizontal: 20*ws),
                    child: Consumer<SleepProvider>(
                      builder: (_, provider, __) {
                        final entry = provider.todayEntry;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 12*hs),
                            _buildSleepRing(ws, hs, entry),
                            SizedBox(height: 10*hs),
                            _buildLogSleepButton(ws, hs, entry, provider),
                            SizedBox(height: 14*hs),
                            _buildQualityBedtimeRow(ws, hs, entry),
                            SizedBox(height: 10*hs),
                            _buildWakeUpCard(ws, hs, entry),
                            SizedBox(height: 10*hs),
                            _buildDeepSleepChart(ws, hs),
                            SizedBox(height: 10*hs),
                            _buildSleepPhaseStats(ws, hs, entry),
                            SizedBox(height: 10*hs),
                            _buildInsightsCard(ws, hs, entry),
                            SizedBox(height: 10*hs),
                            _buildSleepHistory(ws, hs, provider.last7Days),
                            SizedBox(height: 14*hs),
                            _buildViewInsightsButton(ws, hs, entry),
                            SizedBox(height: 16*hs),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      );
    });
  }

  // ─── Header — Snooze button removed ──────────────────────────────────────
  Widget _buildHeader(BuildContext context, double ws, double hs) {
    return Row(children: [
      GestureDetector(
        onTap: () => Navigator.maybePop(context),
        child: Icon(Icons.arrow_back, color: Colors.white, size: 22*ws),
      ),
      SizedBox(width: 10*ws),
      Text('Sleep Tracker', style: TextStyle(
          color: Colors.white, fontSize: 20*ws,
          fontWeight: FontWeight.w600, letterSpacing: 0.3)),
    ]);
  }

  // ─── Sleep Ring ───────────────────────────────────────────────────────────
  Widget _buildSleepRing(double ws, double hs, SleepEntry? entry) {
    final hasData = entry != null && entry.totalHours > 0;
    return Center(
      child: SizedBox(
        width: 180*ws, height: 180*ws,
        child: AnimatedBuilder(
          animation: _ringAnimation,
          builder: (_, __) => CustomPaint(
            painter: SleepRingPainter(progress: _ringAnimation.value),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.nightlight_round,
                    color: const Color(0xFFE8D98E), size: 22*ws),
                SizedBox(height: 2*hs),
                if (hasData)
                  RichText(text: TextSpan(children: [
                    TextSpan(text: '${entry!.hours}',
                        style: TextStyle(color: Colors.white, fontSize: 40*ws,
                            fontWeight: FontWeight.w700, height: 1.0)),
                    TextSpan(text: 'h',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 20*ws, height: 1.0)),
                    if (entry.minutes > 0) ...[
                      TextSpan(text: '${entry.minutes}',
                          style: TextStyle(color: Colors.white, fontSize: 40*ws,
                              fontWeight: FontWeight.w700, height: 1.0)),
                      TextSpan(text: 'm',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 20*ws, height: 1.0)),
                    ],
                  ]))
                else
                  Text('--', style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 36*ws, fontWeight: FontWeight.w700)),
                SizedBox(height: 2*hs),
                Text(hasData ? 'Last Night' : 'No data yet',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13*ws)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Log Sleep Button ─────────────────────────────────────────────────────
  Widget _buildLogSleepButton(double ws, double hs,
      SleepEntry? entry, SleepProvider provider) {
    final hasData = entry != null && entry.totalHours > 0;
    return Center(
      child: GestureDetector(
        onTap: provider.isSaving ? null : _showLogSleepDialog,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 18*ws, vertical: 10*hs),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1F3C).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24*ws),
            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(color: AppTheme.primaryGreen.withValues(alpha: 0.15), blurRadius: 14, offset: const Offset(0, 4)),
            ],
          ),
          child: provider.isSaving
              ? SizedBox(width: 18*ws, height: 18*ws,
              child: const CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
              : Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.nightlight_round,
                color: const Color(0xFFE8D98E), size: 18*ws),
            SizedBox(width: 8*ws),
            Text(hasData ? entry!.durationLabel : '+ Log',
                style: TextStyle(color: Colors.white,
                    fontSize: 14*ws, fontWeight: FontWeight.w600)),
            SizedBox(width: 4*ws),
            Text(hasData ? 'Edit Sleep' : 'Log Sleep',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12*ws)),
          ]),
        ),
      ),
    );
  }

  // ─── Glass card ───────────────────────────────────────────────────────────
  Widget _buildGlassCard({required double ws, required double hs,
    required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 14*ws, vertical: 12*hs),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D1F3C).withValues(alpha: 0.65),
            const Color(0xFF071628).withValues(alpha: 0.55),
          ],
        ),
        borderRadius: BorderRadius.circular(16*ws),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.28)),
      ),
      child: child,
    );
  }

  // ─── Quality + Bedtime row ────────────────────────────────────────────────
  Widget _buildQualityBedtimeRow(double ws, double hs, SleepEntry? entry) {
    return _buildGlassCard(
      ws: ws, hs: hs,
      padding: EdgeInsets.symmetric(horizontal: 14*ws, vertical: 14*hs),
      child: IntrinsicHeight(
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('Sleep Quality ',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12*ws)),
                Text(entry != null ? '${entry.qualityScore}%' : '—',
                    style: TextStyle(color: Colors.white,
                        fontSize: 14*ws, fontWeight: FontWeight.w700)),
              ]),
              SizedBox(height: 4*hs),
              Row(children: [
                Text(entry?.qualityEmoji ?? '😴',
                    style: TextStyle(fontSize: 16*ws)),
                SizedBox(width: 4*ws),
                Text(entry?.qualityLabel ?? '—',
                    style: TextStyle(
                        color: entry != null
                            ? const Color(0xFF7DD3A8)
                            : Colors.white.withValues(alpha: 0.4),
                        fontSize: 14*ws, fontWeight: FontWeight.w600)),
              ]),
            ],
          )),
          Container(width: 1,
              color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
          SizedBox(width: 14*ws),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.dark_mode_outlined,
                    color: AppTheme.lightGreen, size: 14*ws),
                SizedBox(width: 4*ws),
                Text('Bedtime',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12*ws)),
              ]),
              SizedBox(height: 4*hs),
              Row(children: [
                Icon(Icons.nightlight_round,
                    color: AppTheme.lightGreen, size: 16*ws),
                SizedBox(width: 4*ws),
                Text(entry?.bedtimeLabel ?? '—',
                    style: TextStyle(color: Colors.white,
                        fontSize: 16*ws, fontWeight: FontWeight.w700)),
              ]),
            ],
          )),
        ]),
      ),
    );
  }

  // ─── Wake Up card ─────────────────────────────────────────────────────────
  Widget _buildWakeUpCard(double ws, double hs, SleepEntry? entry) {
    return _buildGlassCard(ws: ws, hs: hs,
      child: Row(children: [
        Icon(Icons.cloud, color: AppTheme.lightGreen, size: 20*ws),
        SizedBox(width: 8*ws),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Wake Up', style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7), fontSize: 12*ws)),
          Text(entry?.wakeTimeLabel ?? '—',
              style: TextStyle(color: Colors.white,
                  fontSize: 18*ws, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }

  // ─── Deep Sleep Chart ─────────────────────────────────────────────────────
  Widget _buildDeepSleepChart(double ws, double hs) {
    return _buildGlassCard(ws: ws, hs: hs,
      padding: EdgeInsets.symmetric(horizontal: 14*ws, vertical: 12*hs),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Deep Sleep', style: TextStyle(color: Colors.white,
            fontSize: 14*ws, fontWeight: FontWeight.w600)),
        SizedBox(height: 10*hs),
        SizedBox(height: 70*hs, child: CustomPaint(
            size: Size(double.infinity, 70*hs),
            painter: DeepSleepChartPainter(scale: ws))),
        SizedBox(height: 6*hs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['10pm','11pm','12am','2am','4am','5am','7am']
              .map((t) => Text(t, style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5), fontSize: 9*ws)))
              .toList(),
        ),
      ]),
    );
  }

  // ─── Phase Stats ──────────────────────────────────────────────────────────
  Widget _buildSleepPhaseStats(double ws, double hs, SleepEntry? entry) {
    return Row(children: [
      _phaseChip(Icons.nightlight_round, AppTheme.darkGreen,
          entry?.deepSleepLabel ?? '--', ws, hs),
      SizedBox(width: 8*ws),
      _phaseChip(Icons.nightlight_round, AppTheme.primaryGreen,
          entry?.lightSleepLabel ?? '--', ws, hs),
      SizedBox(width: 8*ws),
      _phaseChip(Icons.remove_red_eye_outlined, AppTheme.lightGreen,
          entry?.remSleepLabel ?? '--', ws, hs),
    ]);
  }

  Widget _phaseChip(IconData icon, Color color, String label,
      double ws, double hs) {
    return Expanded(child: Container(
      padding: EdgeInsets.symmetric(horizontal: 10*ws, vertical: 10*hs),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D1F3C).withValues(alpha: 0.65),
            const Color(0xFF071628).withValues(alpha: 0.55),
          ],
        ),
        borderRadius: BorderRadius.circular(14*ws),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.28)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 16*ws),
        SizedBox(width: 4*ws),
        Flexible(child: Text(label,
            style: TextStyle(color: Colors.white,
                fontSize: 13*ws, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis)),
      ]),
    ));
  }

  // ─── Insights Card ────────────────────────────────────────────────────────
  Widget _buildInsightsCard(double ws, double hs, SleepEntry? entry) {
    final hasData = entry != null && entry.totalHours > 0;
    final isGood  = (entry?.qualityScore ?? 0) >= 80;
    return _buildGlassCard(ws: ws, hs: hs,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Insights', style: TextStyle(color: Colors.white,
                  fontSize: 14*ws, fontWeight: FontWeight.w700)),
              SizedBox(height: 4*hs),
              Text(
                  hasData ? entry!.insightText
                      : 'Log your sleep to see personalized insights.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11.5*ws, height: 1.4)),
            ])),
        Container(
          width: 30*ws, height: 30*ws,
          decoration: BoxDecoration(
            color: hasData
                ? (isGood ? AppTheme.primaryGreen : const Color(0xFFFF9800))
                : AppTheme.darkGreen,
            shape: BoxShape.circle,
          ),
          child: Icon(
              hasData ? (isGood ? Icons.check : Icons.info_outline) : Icons.add,
              color: Colors.white, size: 18*ws),
        ),
      ]),
    );
  }

  // ─── Sleep History ────────────────────────────────────────────────────────
  Widget _buildSleepHistory(double ws, double hs, List<SleepEntry> last7) {
    final values = last7.map((e) => e.totalHours).toList();
    final now    = DateTime.now();
    final labels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d.weekday - 1];
    });
    return _buildGlassCard(ws: ws, hs: hs,
      padding: EdgeInsets.symmetric(horizontal: 14*ws, vertical: 12*hs),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Sleep History', style: TextStyle(color: Colors.white,
              fontSize: 14*ws, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('⭐', style: TextStyle(fontSize: 14*ws)),
        ]),
        SizedBox(height: 10*hs),
        SizedBox(height: 55*hs, child: CustomPaint(
            size: Size(double.infinity, 55*hs),
            painter: SleepHistoryChartPainter(scale: ws, hoursData: values))),
        SizedBox(height: 6*hs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: labels.map((d) => Text(d, style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10*ws))).toList(),
        ),
      ]),
    );
  }

  // ─── View Sleep Insights button → navigates to SleepInsightsScreen ───────
  Widget _buildViewInsightsButton(double ws, double hs, SleepEntry? entry) {
    return Container(
      width: double.infinity,
      height: 48*hs,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft, end: Alignment.centerRight,
          colors: [AppTheme.darkGreen, AppTheme.primaryGreen, AppTheme.darkGreen],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24*ws),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryGreen.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24*ws),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => SleepInsightsScreen(
                todayEntry: entry,
                last7Days:  context.read<SleepProvider>().last7Days,
              ),
            ));
          },
          child: Center(child: Text('View Sleep Insights',
              style: TextStyle(color: Colors.white,
                  fontSize: 15*ws, fontWeight: FontWeight.w600,
                  letterSpacing: 0.3))),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CustomPainters
// ══════════════════════════════════════════════════════════════════════════════

class StarryNightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0,0,size.width,size.height),
        Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0,size.height),
            [const Color(0xFF040D1C),const Color(0xFF071628),
              const Color(0xFF071A2E),const Color(0xFF071425),const Color(0xFF040F1E)],
            [0.0,0.25,0.5,0.75,1.0]));
    canvas.drawRect(Rect.fromLTWH(0,0,size.width,size.height),
        Paint()..shader = ui.Gradient.radial(
            Offset(size.width*0.5,size.height*0.15), size.width*0.7,
            [const Color(0xFF0A2040).withValues(alpha:0.4),
              const Color(0xFF071628).withValues(alpha:0.0)],[0.0,1.0]));
    final rng = math.Random(42);
    final p   = Paint();
    for (int i = 0; i < 120; i++) {
      p.color = Colors.white.withValues(alpha: rng.nextDouble()*0.6+0.2);
      canvas.drawCircle(Offset(rng.nextDouble()*size.width,
          rng.nextDouble()*size.height), rng.nextDouble()*1.2+0.3, p);
    }
    for (int i = 0; i < 15; i++) {
      final x = rng.nextDouble()*size.width;
      final y = rng.nextDouble()*size.height;
      p.color = Colors.white.withValues(alpha:0.7);
      canvas.drawCircle(Offset(x,y), rng.nextDouble()*1.5+1.0, p);
      canvas.drawCircle(Offset(x,y), (rng.nextDouble()*1.5+1.0)*3,
          Paint()..color=const Color(0xFF82D4E8).withValues(alpha:0.15)
            ..maskFilter=const MaskFilter.blur(BlurStyle.normal,3));
    }
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}

class SleepRingPainter extends CustomPainter {
  final double progress;
  SleepRingPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);
    final radius = size.width/2 - 12;
    canvas.drawCircle(center, radius,
        Paint()..color=const Color(0xFF0A2040).withValues(alpha:0.5)
          ..style=PaintingStyle.stroke..strokeWidth=10..strokeCap=StrokeCap.round);
    if (progress <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const sa = -math.pi/2;
    final sw = 2*math.pi*progress;
    canvas.drawArc(rect, sa, sw, false,
        Paint()..style=PaintingStyle.stroke..strokeWidth=10..strokeCap=StrokeCap.round
          ..shader=SweepGradient(startAngle:sa,endAngle:sa+sw,
              colors:const[Color(0xFF059669),Color(0xFF059669),Color(0xFF10B981),Color(0xFF34D399)],
              stops:const[0.0,0.35,0.7,1.0],
              transform:const GradientRotation(-math.pi/2)).createShader(rect));
    canvas.drawArc(rect,sa,sw,false,
        Paint()..style=PaintingStyle.stroke..strokeWidth=16..strokeCap=StrokeCap.round
          ..maskFilter=const MaskFilter.blur(BlurStyle.normal,8)
          ..color=const Color(0xFF10B981).withValues(alpha:0.3));
    final ea = sa+sw;
    final dc = Offset(center.dx+radius*math.cos(ea), center.dy+radius*math.sin(ea));
    canvas.drawCircle(dc, 5, Paint()..color=const Color(0xFF34D399));
    canvas.drawCircle(dc, 8,
        Paint()..color=const Color(0xFF10B981).withValues(alpha:0.3)
          ..maskFilter=const MaskFilter.blur(BlurStyle.normal,6));
  }
  @override bool shouldRepaint(covariant SleepRingPainter o) => o.progress!=progress;
}

class DeepSleepChartPainter extends CustomPainter {
  final double scale;
  DeepSleepChartPainter({required this.scale});
  @override
  void paint(Canvas canvas, Size size) {
    const h = [0.55,0.45,0.72,0.80,0.65,0.90,0.75,0.50,0.85,0.70,0.60,
      0.92,0.55,0.40,0.78,0.68,0.85,0.73,0.50,0.45,0.35];
    final bw = (size.width/h.length)-2;
    for (int i=0; i<h.length; i++) {
      final x = i*(bw+2); final barH = h[i]*size.height; final y = size.height-barH;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,bw,barH),
          Radius.circular(2*scale)),
          Paint()..shader=ui.Gradient.linear(Offset(x,y),Offset(x,size.height),[
            Color.lerp(const Color(0xFF10B981),const Color(0xFF059669),i/h.length)!,
            Color.lerp(const Color(0xFF064E3B),const Color(0xFF065F46),i/h.length)!,
          ],[0.0,1.0]));
    }
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}

class SleepHistoryChartPainter extends CustomPainter {
  final double scale;
  final List<double> hoursData;
  SleepHistoryChartPainter({required this.scale, required this.hoursData});
  @override
  void paint(Canvas canvas, Size size) {
    final gw = size.width/7;
    final bw = gw*0.5;
    for (int i=0; i<7; i++) {
      final h     = hoursData[i];
      final normH = (h/7.166).clamp(0.0,1.0);
      final barH  = normH*size.height;
      if (barH < 1) continue;
      final topC = h>=7.166 ? const Color(0xFF059669)
          : h>=5.0 ? const Color(0xFF10B981) : const Color(0xFF34D399);
      final botC = h>=7.166 ? const Color(0xFF064E3B)
          : h>=5.0 ? const Color(0xFF059669) : const Color(0xFF065F46);
      final cx = (i+0.5)*gw;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(cx-bw/2, size.height-barH, bw, barH),
              Radius.circular(2*scale)),
          Paint()..shader=ui.Gradient.linear(
              Offset(0,size.height-barH),Offset(0,size.height),
              [topC,botC],[0.0,1.0]));
    }
  }
  @override bool shouldRepaint(covariant SleepHistoryChartPainter o) =>
      o.hoursData != hoursData;
}