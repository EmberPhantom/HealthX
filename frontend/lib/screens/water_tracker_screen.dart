import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/water_provider.dart';
import '../providers/rewards_provider.dart';
import '../painters/progress_arc_painter.dart';
import '../painters/water_jar_painter.dart';
import '../painters/bubble_background_painter.dart';
import '../widgets/corner_card.dart';
import '../widgets/weekly_chart.dart';
import '../widgets/insights_card.dart';

class WaterTrackerScreen extends StatefulWidget {
  const WaterTrackerScreen({super.key});

  @override
  State<WaterTrackerScreen> createState() => _WaterTrackerScreenState();
}

class _WaterTrackerScreenState extends State<WaterTrackerScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _bubbleController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // ── Cooldown timer state ──────────────────────────────────────
  Timer? _cooldownTicker;
  int _cooldownSecondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    final provider = context.read<WaterProvider>();
    _progressAnimation = Tween<double>(begin: 0.0, end: provider.progress)
        .animate(CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic));
    _progressController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncCooldown(context.read<WaterProvider>());
    });
  }

  // Sync cooldown state from provider on init / after log.
  // Uses waterCooldownSecondsLeft for second-precision accuracy.
  void _syncCooldown(WaterProvider provider) {
    _cooldownTicker?.cancel();
    final rewards = context.read<RewardsProvider>();

    final int secsLeft = rewards.waterCooldownSecondsLeft;

    if (secsLeft <= 0) {
      if (mounted) setState(() => _cooldownSecondsLeft = 0);
      return;
    }

    if (mounted) setState(() => _cooldownSecondsLeft = secsLeft);

    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) { _cooldownTicker?.cancel(); return; }
      setState(() {
        _cooldownSecondsLeft = (_cooldownSecondsLeft - 1).clamp(0, 1800);
        if (_cooldownSecondsLeft == 0) _cooldownTicker?.cancel();
      });
    });
  }

  String _formatCooldown(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
    return '${s}s';
  }

  @override
  void dispose() {
    _cooldownTicker?.cancel();

    _waveController.dispose();
    _bubbleController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _animateProgress(double from, double to) {
    _progressAnimation = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _progressController..reset()..forward();
  }

  Future<void> _logWater(WaterProvider provider, double ml) async {
    HapticFeedback.mediumImpact();
    final old = provider.progress;
    await provider.addWater(ml);
    _animateProgress(old, provider.progress);
    _syncCooldown(provider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Text('💧', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text('+${ml.toInt()}ml added!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
          const Spacer(),
          Text(provider.remainingText,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
        ]),
        backgroundColor: const Color(0xFF3586C4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _undoLog(WaterProvider provider) async {
    if (provider.currentIntake <= 0) return;
    HapticFeedback.lightImpact();
    final old = provider.progress;
    await provider.undoLastLog();
    _animateProgress(old, provider.progress);
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Text('↩️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text('-250ml undone',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
          const Spacer(),
          Text(provider.remainingText,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
        ]),
        backgroundColor: const Color(0xFFE57373),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Goal Picker Sheet ─────────────────────────────────────────────
  void _showGoalPicker(BuildContext context, WaterProvider provider) {
    HapticFeedback.lightImpact();
    double tempGoal = provider.dailyGoal;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                const SizedBox(height: 22),
                _sheetIcon(Icons.local_drink_outlined),
                const SizedBox(height: 14),
                _sheetTitle('Daily Water Goal'),
                const SizedBox(height: 4),
                _sheetSubtitle('How much water do you want to drink?'),
                const SizedBox(height: 22),
                // Big value
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: (tempGoal / 1000).toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontSize: 52, fontWeight: FontWeight.w800,
                        color: const Color(0xFF4A9FD4), height: 1,
                      ),
                    ),
                    TextSpan(
                      text: ' L',
                      style: GoogleFonts.poppins(
                        fontSize: 22, fontWeight: FontWeight.w600,
                        color: const Color(0xFF8AAFC7),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                _styledSlider(context, tempGoal, 500, 5000, 18, (v) => set(() => tempGoal = v)),
                const SizedBox(height: 16),
                // Preset chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [1500, 2000, 2500, 3000].map((ml) {
                    final sel = tempGoal == ml.toDouble();
                    return GestureDetector(
                      onTap: () => set(() => tempGoal = ml.toDouble()),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFF4A9FD4) : const Color(0xFFF0F8FF),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: sel ? const Color(0xFF4A9FD4) : const Color(0xFFD8EDF8),
                            width: 1.5,
                          ),
                          boxShadow: sel ? [BoxShadow(
                            color: const Color(0xFF4A9FD4).withOpacity(0.28),
                            blurRadius: 8, offset: const Offset(0, 3),
                          )] : [],
                        ),
                        child: Text(
                          '${(ml / 1000).toStringAsFixed(1)}L',
                          style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : const Color(0xFF5B8AAE),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 26),
                _sheetButton('Save Goal', () async {
                  await provider.setGoal(tempGoal);
                  if (context.mounted) Navigator.pop(context);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Reminder Sheet ────────────────────────────────────────────────
  void _showReminderSheet(BuildContext context, WaterProvider provider) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                const SizedBox(height: 22),
                _sheetIcon(Icons.alarm_rounded),
                const SizedBox(height: 14),
                _sheetTitle('Drink Water Reminder'),
                const SizedBox(height: 4),
                _sheetSubtitle("We'll remind you to stay hydrated throughout the day"),
                const SizedBox(height: 22),

                // Toggle card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5FAFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD8EDF8)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: Color(0xFF4A9FD4), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Enable Reminders',
                          style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A2E40),
                          ),
                        ),
                        Text(
                          provider.reminderEnabled ? 'Currently active' : 'Tap to enable',
                          style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF8AAFC7)),
                        ),
                      ],
                    )),
                    Switch(
                      value: provider.reminderEnabled,
                      activeColor: const Color(0xFF4A9FD4),
                      onChanged: (v) async {
                        await provider.toggleReminder(v);
                        set(() {});
                      },
                    ),
                  ]),
                ),

                // Interval — only when enabled
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  child: provider.reminderEnabled
                      ? Column(children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Remind me every',
                          style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A2E40),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A9FD4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${provider.reminderHours}h',
                            style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _styledSlider(
                      context,
                      provider.reminderHours.toDouble(),
                      1, 8, 7,
                          (v) async {
                        await provider.setReminderHours(v.toInt());
                        set(() {});
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(8, (i) => i + 1).map((h) => Text(
                          '${h}h',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: provider.reminderHours == h
                                ? const Color(0xFF4A9FD4)
                                : const Color(0xFFB8D4E8),
                            fontWeight: provider.reminderHours == h
                                ? FontWeight.w700 : FontWeight.w400,
                          ),
                        )).toList(),
                      ),
                    ),
                  ])
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 28),
                _sheetButton('Done', () => Navigator.pop(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Sheet helpers ─────────────────────────────────────────────────
  Widget _sheetHandle() => Container(
    width: 40, height: 4,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget _sheetIcon(IconData icon) => Container(
    width: 54, height: 54,
    decoration: BoxDecoration(
      color: const Color(0xFFEBF6FF),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Icon(icon, color: const Color(0xFF4A9FD4), size: 26),
  );

  Widget _sheetTitle(String t) => Text(t,
    style: GoogleFonts.poppins(
      fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1A2E40),
    ),
  );

  Widget _sheetSubtitle(String t) => Text(t,
    textAlign: TextAlign.center,
    style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF8AAFC7)),
  );

  Widget _styledSlider(
      BuildContext context,
      double value,
      double min, double max, int divisions,
      ValueChanged<double> onChanged,
      ) => SliderTheme(
    data: SliderTheme.of(context).copyWith(
      activeTrackColor: const Color(0xFF4A9FD4),
      inactiveTrackColor: const Color(0xFFD8EDF8),
      thumbColor: Colors.white,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
      overlayColor: const Color(0x224A9FD4),
      trackHeight: 6,
    ),
    child: Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
  );

  Widget _sheetButton(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity, height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4A9FD4), Color(0xFF2B6FA8)]),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(
          color: const Color(0xFF4A9FD4).withOpacity(0.35),
          blurRadius: 16, offset: const Offset(0, 6),
        )],
      ),
      alignment: Alignment.center,
      child: Text(label,
        style: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w700,
          color: Colors.white, letterSpacing: 0.3,
        ),
      ),
    ),
  );

  // ─── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WaterProvider>();

    if (!provider.isLoaded) {
      return Scaffold(
        backgroundColor: const Color(0xFFEDF6FC),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF4A9FD4), strokeWidth: 2.5),
        ),
      );
    }

    return Scaffold(
      body: Stack(children: [
        // Background
        Positioned.fill(child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFD6EAF5), Color(0xFFE4F1FA), Color(0xFFEDF6FC), Color(0xFFF2F8FD)],
              stops: [0.0, 0.3, 0.6, 1.0],
            ),
          ),
        )),
        // Bubbles
        Positioned.fill(child: AnimatedBuilder(
          animation: _bubbleController,
          builder: (_, __) => CustomPaint(
            painter: BubbleBackgroundPainter(phase: _bubbleController.value * 2 * math.pi),
          ),
        )),
        // Content
        Positioned.fill(child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 16),
                _buildCenterArea(provider, context),
                const SizedBox(height: 18),
                _buildLogButtons(provider),
                const SizedBox(height: 18),
                const WeeklyChart(),
                const SizedBox(height: 14),
                const InsightsCard(),
                const SizedBox(height: 28),
              ]),
            ),
          ),
        )),
      ]),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────
  Widget _buildHeader() => Row(children: [
    GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFB8D8ED).withOpacity(0.5)),
          boxShadow: [BoxShadow(
            color: const Color(0xFF4A9FD4).withOpacity(0.08),
            blurRadius: 8, offset: const Offset(0, 2),
          )],
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Color(0xFF1A2E40)),
      ),
    ),
    const SizedBox(width: 12),
    Text('Water Tracker',
      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF1A2E40)),
    ),
  ]);

  // ─── Center area ───────────────────────────────────────────────────
  Widget _buildCenterArea(WaterProvider provider, BuildContext context) {
    return SizedBox(
      height: 355,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Arc
          Positioned(top: 0, child: SizedBox(
            width: 230, height: 230,
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (_, __) => CustomPaint(
                painter: ProgressArcPainter(progress: _progressAnimation.value, strokeWidth: 9),
              ),
            ),
          )),

          // Check badge — top-right corner of arc, never overlaps text
          Positioned(
            top: 10, right: 48,
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: const Color(0xFF4A9FD4).withOpacity(0.15),
                  blurRadius: 8, offset: const Offset(0, 2),
                )],
              ),
              child: Icon(
                provider.goalReached ? Icons.check_circle_rounded : Icons.check_rounded,
                size: 17,
                color: provider.goalReached ? const Color(0xFF4CAF50) : const Color(0xFF4A9FD4),
              ),
            ),
          ),

          // ── Center text block ──────────────────────────────
          // FIX: sits at top:28 so all text stays inside the arc circle
          // "remaining" text is BELOW "Today" — no bottle overlap
          Positioned(
            top: 28,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${provider.currentLiters.toStringAsFixed(1)}L',
                  style: GoogleFonts.poppins(
                    fontSize: 46, fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2E40), height: 1.0,
                  ),
                ),
                Text('Today',
                  style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF4A9FD4),
                  ),
                ),
                const SizedBox(height: 3),
                // FIX: remaining text clearly below "Today", above bottle neck region
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A9FD4).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    provider.remainingText,
                    style: GoogleFonts.poppins(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: const Color(0xFF4A9FD4),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Water jar ──────────────────────────────────────
          // FIX: top:120 ensures zero overlap with the text above
          Positioned(
            top: 120,
            child: SizedBox(
              width: 138, height: 218,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (_, __) => CustomPaint(
                  painter: WaterJarPainter(
                    fillPercent: provider.progress,
                    wavePhase: _waveController.value * 2 * math.pi,
                  ),
                ),
              ),
            ),
          ),

          // Left cards
          Positioned(left: 0, top: 170, child: CornerCard(
            icon: Icons.add_circle_outline_rounded,
            iconColor: const Color(0xFF5BA8D6),
            topText: '+250mL', bottomText: 'Quick Log',
            onTap: () {
              if (_cooldownSecondsLeft > 0) {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(children: [
                      const Text('⏳', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cooldown active',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
                          Text('Log again in ${_formatCooldown(_cooldownSecondsLeft)}',
                              style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
                        ],
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_formatCooldown(_cooldownSecondsLeft),
                            style: GoogleFonts.poppins(
                                fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ]),
                    backgroundColor: const Color(0xFF2B6FA8),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    duration: const Duration(seconds: 3),
                  ),
                );
              } else {
                _logWater(provider, 250);
              }
            },
          )),
          Positioned(left: 0, top: 252, child: CornerCard(
            icon: Icons.alarm_rounded,
            iconColor: provider.reminderEnabled ? const Color(0xFF4CAF50) : const Color(0xFF5BA8D6),
            topText: provider.reminderEnabled ? 'Every ${provider.reminderHours}h' : 'Reminder',
            bottomText: provider.reminderEnabled ? 'Active ✓' : 'Set Alarm',
            onTap: () => _showReminderSheet(context, provider),
          )),

          // Right cards
          Positioned(right: 0, top: 170, child: CornerCard(
            icon: Icons.local_drink_outlined,
            iconColor: const Color(0xFF5BA8D6),
            topText: '${(provider.dailyGoal / 1000).toStringAsFixed(1)}L Goal',
            bottomText: 'Tap to Set',
            onTap: () => _showGoalPicker(context, provider),
          )),
          // Undo — minimal ghost button, right side below goal card
          Positioned(right: 0, top: 252,
            child: GestureDetector(
              onTap: provider.currentIntake > 0 ? () => _undoLog(provider) : null,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: provider.currentIntake > 0 ? 1.0 : 0.35,
                child: Container(
                  width: 72, height: 68,
                  decoration: BoxDecoration(
                    color: provider.currentIntake > 0
                        ? const Color(0xFFFFF0F0)
                        : Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: provider.currentIntake > 0
                          ? const Color(0xFFE57373).withOpacity(0.4)
                          : const Color(0xFFB0CCDC).withOpacity(0.3),
                      width: 1.2,
                    ),
                    boxShadow: [BoxShadow(
                      color: const Color(0xFFE57373).withOpacity(
                          provider.currentIntake > 0 ? 0.10 : 0),
                      blurRadius: 8, offset: const Offset(0, 3),
                    )],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.undo_rounded, size: 20,
                        color: provider.currentIntake > 0
                            ? const Color(0xFFE57373)
                            : const Color(0xFFB0CCDC),
                      ),
                      const SizedBox(height: 3),
                      Text('Undo', style: GoogleFonts.poppins(
                        fontSize: 10, fontWeight: FontWeight.w600,
                        color: provider.currentIntake > 0
                            ? const Color(0xFFE57373)
                            : const Color(0xFFB0CCDC),
                      )),
                      Text('-250mL', style: GoogleFonts.poppins(
                        fontSize: 8.5, fontWeight: FontWeight.w400,
                        color: provider.currentIntake > 0
                            ? const Color(0xFFE57373).withOpacity(0.7)
                            : const Color(0xFFB0CCDC).withOpacity(0.7),
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Log buttons ───────────────────────────────────────────────────
  Widget _buildLogButtons(WaterProvider provider) {
    final onCooldown = _cooldownSecondsLeft > 0;
    return Column(children: [
      // ── Main CTA — dark when active, chip-style when cooldown ──
      GestureDetector(
        onTap: () {
          if (onCooldown) {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(children: [
                  const Text('⏳', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cooldown active',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
                      Text('Log again in ${_formatCooldown(_cooldownSecondsLeft)}',
                          style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
                    ],
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_formatCooldown(_cooldownSecondsLeft),
                        style: GoogleFonts.poppins(
                            fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ]),
                backgroundColor: const Color(0xFF2B6FA8),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (!provider.goalReached) {
            _logWater(provider, 250);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 52, width: double.infinity,
          decoration: BoxDecoration(
            gradient: provider.goalReached
                ? const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)])
                : onCooldown
                ? null
                : const LinearGradient(
              colors: [Color(0xFF4A9FD4), Color(0xFF3586C4), Color(0xFF2B6FA8)],
              stops: [0.0, 0.5, 1.0],
            ),
            color: onCooldown && !provider.goalReached ? Colors.white : null,
            borderRadius: BorderRadius.circular(26),
            border: onCooldown && !provider.goalReached
                ? Border.all(color: const Color(0xFF90B8D4).withOpacity(0.5), width: 1.2)
                : null,
            boxShadow: [BoxShadow(
              color: (provider.goalReached
                  ? const Color(0xFF4CAF50)
                  : onCooldown ? const Color(0xFF4A9FD4)
                  : const Color(0xFF3586C4))
                  .withOpacity(onCooldown ? 0.06 : 0.28),
              blurRadius: onCooldown ? 4 : 14,
              offset: Offset(0, onCooldown ? 2 : 6),
            )],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                provider.goalReached
                    ? Icons.check_circle_rounded
                    : onCooldown ? Icons.timer_outlined
                    : Icons.water_drop_rounded,
                size: 18,
                color: provider.goalReached
                    ? Colors.white
                    : onCooldown ? const Color(0xFF90B8D4)
                    : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                provider.goalReached
                    ? 'Goal Reached! 🎉'
                    : onCooldown
                    ? 'Next log in ${_formatCooldown(_cooldownSecondsLeft)}'
                    : '+250ml  Log Water',
                style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: provider.goalReached
                      ? Colors.white
                      : onCooldown ? const Color(0xFF90B8D4)
                      : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),

      const SizedBox(height: 10),

      // ── Small ml chips — one row, equal width ──────────────────
      Row(
        children: [
          _chip(provider, 100, onCooldown),
          const SizedBox(width: 8),
          _chip(provider, 200, onCooldown),
          const SizedBox(width: 8),
          _chip(provider, 350, onCooldown),
        ],
      ),
    ]);
  }

  Widget _chip(WaterProvider provider, int ml, bool blocked) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (blocked) {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Row(children: [
                const Text('⏳', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cooldown active',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
                    Text('Log again in ${_formatCooldown(_cooldownSecondsLeft)}',
                        style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
                  ],
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_formatCooldown(_cooldownSecondsLeft),
                      style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ]),
              backgroundColor: const Color(0xFF2B6FA8),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              duration: const Duration(seconds: 3),
            ));
          } else {
            _logWater(provider, ml.toDouble());
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: blocked ? const Color(0xFFF0F8FF) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: blocked
                  ? const Color(0xFF90B8D4).withOpacity(0.5)
                  : const Color(0xFFBEDDF2),
              width: 1.2,
            ),
            boxShadow: [BoxShadow(
              color: const Color(0xFF4A9FD4).withOpacity(blocked ? 0.03 : 0.07),
              blurRadius: 8, offset: const Offset(0, 3),
            )],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (blocked) ...[
                Icon(Icons.timer_outlined, size: 11, color: const Color(0xFF90B8D4)),
                const SizedBox(width: 4),
              ],
              Text('+${ml}ml',
                style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: blocked ? const Color(0xFF90B8D4) : const Color(0xFF2B6FA8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}