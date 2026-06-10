// lib/screens/health_rewards_screen.dart
// ✅ Live points from RewardsProvider
// ✅ Real task status (steps / sleep / water)
// ✅ Animated claim dialog with confetti effect
// ✅ 100 coins = ₹10
// ✅ Claim expires at 11:59 PM daily

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/rewards_provider.dart';
import '../providers/sleep_provider.dart';
import '../providers/water_provider.dart';
import '../services/health_service.dart';
import '../services/step_counter_service.dart';

const double _refW = 360.0;
const double _refH = 800.0;

class HealthRewardsScreen extends StatefulWidget {
  const HealthRewardsScreen({super.key});

  @override
  State<HealthRewardsScreen> createState() => _HealthRewardsScreenState();
}

class _HealthRewardsScreenState extends State<HealthRewardsScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // ✅ SYNC: Check live Sleep + Water providers and mark goals done
      // if they were completed before this session (fixes first-time launch)
      final rewards = context.read<RewardsProvider>();
      final sleep   = context.read<SleepProvider>();
      final water   = context.read<WaterProvider>();

      // ✅ Sync live steps from HealthService so rewards screen is real-time
      // (same source as home screen _StatsRowResponsive)
      try {
        await StepCounterService.instance.startService();
        final steps = await HealthService.instance.fetchTodaySteps();
        if (mounted) rewards.updateSteps(steps);
      } catch (_) {}

      // Sync sleep — if today's sleep entry is ≥8h, mark it done
      final todaySleep = sleep.todayEntry;
      if (todaySleep != null && todaySleep.totalHours >= 8.0) {
        await rewards.markSleepGoalDone();
      }

      // Sync water — if current intake meets or exceeds goal, mark it done
      if (water.goalReached) {
        await rewards.onWaterLogged(); // update cooldown timestamp if needed
        await rewards.markWaterGoalDone();
      }

      // Auto-show claim dialog if all tasks now done and not yet claimed
      if (rewards.allTasksDone && !rewards.claimedToday && mounted) {
        _showClaimDialog(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth  = constraints.maxWidth;
        final screenHeight = MediaQuery.of(context).size.height;
        final ws = screenWidth / _refW;
        final hs = screenHeight / _refH;

        return Scaffold(
          backgroundColor: const Color(0xFFEEF2F7),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 12 * ws, right: 12 * ws,
                top: 12 * hs,
                bottom: MediaQuery.of(context).padding.bottom + 8 * hs,
              ),
              child: Consumer<RewardsProvider>(
                builder: (_, rewards, __) => Column(
                  children: [
                    _buildHeader(ws, hs)
                        .animate().fadeIn(duration: 300.ms).slideY(begin: -0.15, end: 0),
                    SizedBox(height: 12 * hs),
                    _buildTotalPointsCard(rewards, ws, hs)
                        .animate().fadeIn(delay: 80.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
                    SizedBox(height: 10 * hs),
                    _buildRewardPointsCard(rewards, ws, hs)
                        .animate().fadeIn(delay: 160.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
                    SizedBox(height: 10 * hs),
                    _buildRedeemSection(rewards, ws, hs)
                        .animate().fadeIn(delay: 240.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
                    SizedBox(height: 10 * hs),
                    _buildInviteFriendsCard(ws, hs)
                        .animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
                    SizedBox(height: 8 * hs),
                    _buildSecuredFooter(ws, hs)
                        .animate().fadeIn(delay: 380.ms, duration: 300.ms),
                    SizedBox(height: 4 * hs),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Header ─────────────────────────────────────────────────────
  Widget _buildHeader(double ws, double hs) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildShieldLogo(28 * ws, ws),
            SizedBox(width: 7 * ws),
            Text(
              'HealthX',
              style: GoogleFonts.poppins(
                fontSize: 16 * ws, fontWeight: FontWeight.w700,
                color: const Color(0xFF1B5E4B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Total Points Balance Card ───────────────────────────────────
  Widget _buildTotalPointsCard(RewardsProvider rewards, double ws, double hs) {
    final rupees = (rewards.totalPoints / kCoinsPerRupee).toStringAsFixed(2);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E4B), Color(0xFF2E7D6B), Color(0xFF43A89E)],
        ),
        borderRadius: BorderRadius.circular(16 * ws),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E4B).withOpacity(0.28),
            blurRadius: 18, offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(16 * ws),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 18)),
              SizedBox(width: 6 * ws),
              Text(
                'Total Reward Balance',
                style: GoogleFonts.poppins(
                  fontSize: 12 * ws, fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          SizedBox(height: 10 * hs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${rewards.totalPoints}',
                style: GoogleFonts.poppins(
                  fontSize: 38 * ws, fontWeight: FontWeight.w800,
                  color: Colors.white, height: 1.0,
                ),
              ),
              SizedBox(width: 6 * ws),
              Padding(
                padding: EdgeInsets.only(bottom: 4 * hs),
                child: Text(
                  'coins',
                  style: GoogleFonts.poppins(
                    fontSize: 14 * ws, fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10 * ws, vertical: 5 * hs),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20 * ws),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: Text(
                  '= ₹$rupees',
                  style: GoogleFonts.poppins(
                    fontSize: 13 * ws, fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6 * hs),
          Text(
            '100 coins = ₹10 discount on any order',
            style: GoogleFonts.poppins(
              fontSize: 9.5 * ws, fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Today's Reward Progress Card ───────────────────────────────
  Widget _buildRewardPointsCard(RewardsProvider rewards, double ws, double hs) {
    final allDone = rewards.allTasksDone;
    final claimed = rewards.claimedToday;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14 * ws),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9DB2CE).withOpacity(0.12),
            blurRadius: 16, offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(12 * ws),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Reward Points",
            style: GoogleFonts.poppins(
              fontSize: 12 * ws, fontWeight: FontWeight.w600,
              color: const Color(0xFF1A2E35),
            ),
          ),
          SizedBox(height: 7 * hs),
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 18)),
              SizedBox(width: 5 * ws),
              Text(
                '+100',
                style: GoogleFonts.poppins(
                  fontSize: 24 * ws, fontWeight: FontWeight.w800,
                  color: const Color(0xFFD4A017), height: 0.95,
                ),
              ),
              SizedBox(width: 6 * ws),
              Flexible(
                child: Text(
                  claimed ? 'Points Claimed ✓' : 'Points Available',
                  style: GoogleFonts.poppins(
                    fontSize: 14 * ws, fontWeight: FontWeight.w700,
                    color: claimed
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF1A2E35),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1 * hs),
          Text(
            claimed
                ? 'Claimed today! Come back tomorrow 🎯'
                : allDone
                ? 'Tap below to claim your reward!'
                : 'Complete all 3 tasks to earn 100 points',
            style: GoogleFonts.poppins(
              fontSize: 10 * ws, fontWeight: FontWeight.w400,
              color: const Color(0xFF5C7A82),
            ),
          ),
          SizedBox(height: 10 * hs),

          // Tasks status banner
          if (allDone && !claimed)
            _buildDailyTasksBanner(ws, hs)
          else
            _buildProgressBanner(rewards, ws, hs),

          SizedBox(height: 8 * hs),

          // Task items — read live data from Sleep + Water providers
          Consumer2<SleepProvider, WaterProvider>(
            builder: (_, sleep, water, __) {
              final sleepEntry   = sleep.todayEntry;
              final sleepHours   = sleepEntry?.totalHours ?? 0.0;
              final sleepLabel   = sleepEntry != null
                  ? '${sleepHours.toStringAsFixed(1)}h slept'
                  : 'Not logged yet';
              final bedStr       = sleepEntry != null
                  ? _fmtTime(sleepEntry.bedtime)
                  : '11PM';
              final wakeStr      = sleepEntry != null
                  ? _fmtTime(sleepEntry.wakeTime)
                  : '7AM';

              final waterLiters  = water.currentLiters;
              final waterGoalL   = water.dailyGoal / 1000;
              final waterLabel   = '${waterLiters.toStringAsFixed(1)}L / ${waterGoalL.toStringAsFixed(1)}L';
              final glasses      = (waterLiters / 0.25).floor();

              return Column(
                children: [
                  _buildTaskItem(
                    icon: _buildStepsIcon(ws, hs),
                    title: 'Walk 8,000 Steps',
                    subtitle: rewards.stepsGoalDone
                        ? '${rewards.currentSteps} steps done ✓'
                        : '${rewards.currentSteps} / $kStepsGoal steps',
                    points: kStepsPoints,
                    done: rewards.stepsGoalDone,
                    progressWidget: _buildStepsProgress(rewards, ws, hs),
                    ws: ws, hs: hs,
                  ),
                  SizedBox(height: 8 * hs),
                  _buildTaskItem(
                    icon: _buildWaterIcon(ws, hs),
                    title: 'Drink ${waterGoalL.toStringAsFixed(1)} Litres of Water',
                    subtitle: '$waterLabel · $glasses glasses',
                    points: kWaterPoints,
                    done: rewards.waterGoalDone,
                    progressWidget: _buildWaterProgress(water, ws, hs),
                    ws: ws, hs: hs,
                  ),
                  SizedBox(height: 8 * hs),
                  _buildTaskItem(
                    icon: _buildSleepIcon(ws, hs),
                    title: 'Sleep 8 Hours',
                    subtitle: sleepLabel,
                    points: kSleepPoints,
                    done: rewards.sleepGoalDone,
                    progressWidget: _buildSleepTimeline(bedStr, wakeStr, ws, hs),
                    ws: ws, hs: hs,
                  ),
                ],
              );
            },
          ),

          SizedBox(height: 14 * hs),

          // Claim button
          if (!claimed)
            _buildClaimButton(rewards, ws, hs),

          if (claimed)
            _buildClaimedBadge(ws, hs),
        ],
      ),
    );
  }

  Widget _buildDailyTasksBanner(double ws, double hs) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10 * ws, vertical: 7 * hs),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10 * ws),
      ),
      child: Row(
        children: [
          Container(
            width: 20 * ws, height: 20 * ws,
            decoration: const BoxDecoration(
              color: Color(0xFF43A047), shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: Colors.white, size: 13 * ws),
          ),
          SizedBox(width: 8 * ws),
          Text(
            'All Daily Tasks Completed! 🎉',
            style: GoogleFonts.poppins(
              fontSize: 11 * ws, fontWeight: FontWeight.w600,
              color: const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBanner(RewardsProvider rewards, double ws, double hs) {
    final done = [rewards.stepsGoalDone, rewards.sleepGoalDone, rewards.waterGoalDone]
        .where((b) => b).length;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10 * ws, vertical: 7 * hs),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10 * ws),
      ),
      child: Row(
        children: [
          Text('$done/3', style: GoogleFonts.poppins(
            fontSize: 13 * ws, fontWeight: FontWeight.w800,
            color: const Color(0xFFE65100),
          )),
          SizedBox(width: 8 * ws),
          Text(
            'tasks done · Keep going! 💪',
            style: GoogleFonts.poppins(
              fontSize: 11 * ws, fontWeight: FontWeight.w500,
              color: const Color(0xFFBF6000),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimButton(RewardsProvider rewards, double ws, double hs) {
    final enabled = rewards.allTasksDone && !rewards.claimedToday;
    return GestureDetector(
      onTap: enabled
          ? () {
        HapticFeedback.heavyImpact();
        _showClaimDialog(context);
      }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 48 * hs,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
            colors: [Color(0xFFD4A017), Color(0xFFFFCA28), Color(0xFFD4A017)],
            begin: Alignment.centerLeft, end: Alignment.centerRight,
          )
              : const LinearGradient(
            colors: [Color(0xFFBDBDBD), Color(0xFFE0E0E0)],
          ),
          borderRadius: BorderRadius.circular(24 * ws),
          boxShadow: enabled
              ? [BoxShadow(
            color: const Color(0xFFD4A017).withOpacity(0.4),
            blurRadius: 12, offset: const Offset(0, 4),
          )]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              enabled ? '🎁' : '🔒',
              style: TextStyle(fontSize: 18 * ws),
            ),
            SizedBox(width: 8 * ws),
            Text(
              enabled ? 'Claim 100 Points' : 'Complete All Tasks First',
              style: GoogleFonts.poppins(
                fontSize: 14 * ws, fontWeight: FontWeight.w700,
                color: enabled ? Colors.white : const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimedBadge(double ws, double hs) {
    return Container(
      width: double.infinity,
      height: 48 * hs,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(24 * ws),
        border: Border.all(color: const Color(0xFF43A047), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded,
              color: const Color(0xFF43A047), size: 20 * ws),
          SizedBox(width: 8 * ws),
          Text(
            'Claimed Today · Come back tomorrow!',
            style: GoogleFonts.poppins(
              fontSize: 11 * ws, fontWeight: FontWeight.w600,
              color: const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Claim Dialog ────────────────────────────────────────────────
  void _showClaimDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => const _ClaimRewardDialog(),
    );
  }

  // ─── Task Item ───────────────────────────────────────────────────
  Widget _buildTaskItem({
    required Widget icon,
    required String title,
    String? subtitle,
    required int points,
    required bool done,
    Widget? progressWidget,
    required double ws,
    required double hs,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          children: [
            icon,
            if (done)
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  width: 14 * ws, height: 14 * ws,
                  decoration: const BoxDecoration(
                    color: Color(0xFF43A047), shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: Colors.white, size: 9 * ws),
                ),
              ),
          ],
        ),
        SizedBox(width: 10 * ws),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11 * ws, fontWeight: FontWeight.w600,
                  color: done
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF1A2E35),
                  decoration: done ? TextDecoration.none : null,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: EdgeInsets.only(top: 1 * hs),
                  child: Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 9 * ws, color: const Color(0xFF7A8A8E),
                    ),
                  ),
                ),
              if (progressWidget != null)
                Padding(
                  padding: EdgeInsets.only(top: 3 * hs),
                  child: progressWidget,
                ),
            ],
          ),
        ),
        SizedBox(width: 6 * ws),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 7 * ws, vertical: 3 * hs),
          decoration: BoxDecoration(
            color: done
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(8 * ws),
          ),
          child: Text(
            '+$points pts',
            style: GoogleFonts.poppins(
              fontSize: 10 * ws, fontWeight: FontWeight.w700,
              color: done
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFD4A017),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Icon builders ───────────────────────────────────────────────
  Widget _buildStepsIcon(double ws, double hs) => Container(
    width: 38 * ws, height: 38 * ws,
    decoration: BoxDecoration(
      color: const Color(0xFFE3F2FD),
      borderRadius: BorderRadius.circular(10 * ws),
    ),
    child: Icon(Icons.directions_walk_rounded,
        color: const Color(0xFF1976D2), size: 22 * ws),
  );

  Widget _buildWaterIcon(double ws, double hs) => Container(
    width: 38 * ws, height: 38 * ws,
    decoration: BoxDecoration(
      color: const Color(0xFFE0F7FA),
      borderRadius: BorderRadius.circular(10 * ws),
    ),
    child: Icon(Icons.water_drop_rounded,
        color: const Color(0xFF0097A7), size: 22 * ws),
  );

  Widget _buildSleepIcon(double ws, double hs) => Container(
    width: 38 * ws, height: 38 * ws,
    decoration: BoxDecoration(
      color: const Color(0xFFEDE7F6),
      borderRadius: BorderRadius.circular(10 * ws),
    ),
    child: Icon(Icons.bedtime_rounded,
        color: const Color(0xFF673AB7), size: 22 * ws),
  );

  Widget _buildStepsProgress(RewardsProvider rewards, double ws, double hs) {
    final progress = (rewards.currentSteps / kStepsGoal).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4 * ws),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 5,
        backgroundColor: const Color(0xFFE0E0E0),
        valueColor: AlwaysStoppedAnimation<Color>(
          rewards.stepsGoalDone ? const Color(0xFF43A047) : const Color(0xFF1976D2),
        ),
      ),
    );
  }

  Widget _buildWaterProgress(WaterProvider water, double ws, double hs) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4 * ws),
      child: LinearProgressIndicator(
        value: water.progress.clamp(0.0, 1.0),
        minHeight: 5,
        backgroundColor: const Color(0xFFE0E0E0),
        valueColor: AlwaysStoppedAnimation<Color>(
          water.goalReached ? const Color(0xFF43A047) : const Color(0xFF0097A7),
        ),
      ),
    );
  }

  Widget _buildSleepTimeline(String bedStr, String wakeStr, double ws, double hs) {
    return Row(
      children: [
        Text(bedStr, style: GoogleFonts.poppins(
            fontSize: 8 * ws, color: const Color(0xFF7A8A8E),
            fontWeight: FontWeight.w500)),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4 * ws),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(7, (i) => Padding(
                padding: EdgeInsets.symmetric(horizontal: 1 * ws),
                child: Text('•', style: TextStyle(
                    fontSize: 6 * ws,
                    color: const Color(0xFF7A8A8E).withOpacity(0.5))),
              )),
            ),
          ),
        ),
        Text(wakeStr, style: GoogleFonts.poppins(
            fontSize: 8 * ws, color: const Color(0xFF7A8A8E),
            fontWeight: FontWeight.w500)),
      ],
    );
  }

  /// Format DateTime → "11PM" / "7AM" style
  static String _fmtTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute;
    final suffix = h < 12 ? 'AM' : 'PM';
    final hour12 = h == 0 ? 12 : h > 12 ? h - 12 : h;
    if (m == 0) return '$hour12$suffix';
    return '$hour12:${m.toString().padLeft(2, '0')}$suffix';
  }

  // ─── Redeem Section ──────────────────────────────────────────────
  Widget _buildRedeemSection(RewardsProvider rewards, double ws, double hs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14 * ws),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9DB2CE).withOpacity(0.12),
            blurRadius: 16, offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(12 * ws),
      child: Column(
        children: [
          Text(
            'Redeem Points in Healthy Treats',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12 * ws, fontWeight: FontWeight.w600,
              color: const Color(0xFF1A2E35),
            ),
          ),
          SizedBox(height: 10 * hs),
          Row(
            children: [
              Expanded(child: _buildSubscriptionCard(
                title: 'Weekly\nSubscription',
                buttonColor: const Color(0xFFE8A817),
                ws: ws, hs: hs,
                rewards: rewards,
              )),
              SizedBox(width: 8 * ws),
              Expanded(child: _buildSubscriptionCard(
                title: 'Monthly\nSubscription',
                buttonColor: const Color(0xFF1976D2),
                ws: ws, hs: hs,
                rewards: rewards,
              )),
              SizedBox(width: 8 * ws),
              Expanded(child: _buildSubscriptionCard(
                title: 'Custom\nSubscription',
                buttonColor: const Color(0xFF5B6B7D),
                ws: ws, hs: hs,
                rewards: rewards,
              )),
            ],
          ),
          SizedBox(height: 8 * hs),
          RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 18 * ws, fontWeight: FontWeight.w400,
                color: const Color(0xFFAF961C),
              ),
              children: const [
                TextSpan(text: '100 Points = '),
                TextSpan(
                  text: '₹10',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard({
    required String title,
    required Color buttonColor,
    required double ws,
    required double hs,
    required RewardsProvider rewards,
  }) {
    // Each subscription uses 100 pts = ₹10 off
    final hasPoints = rewards.totalPoints >= 100;
    return Container(
      padding: EdgeInsets.all(9 * ws),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(10 * ws),
        border: Border.all(color: const Color(0xFFE0E8F0), width: 0.8),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 8.5 * ws, fontWeight: FontWeight.w600,
              color: const Color(0xFF1A2E35), height: 1.2,
            ),
          ),
          SizedBox(height: 6 * hs),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: '₹',
                  style: GoogleFonts.poppins(
                    fontSize: 11 * ws, fontWeight: FontWeight.w800,
                    color: buttonColor,
                  ),
                ),
                TextSpan(
                  text: '${(rewards.totalPoints / kCoinsPerRupee).floor()}',
                  style: GoogleFonts.poppins(
                    fontSize: 15 * ws, fontWeight: FontWeight.w800,
                    color: buttonColor,
                  ),
                ),
                TextSpan(
                  text: ' OFF',
                  style: GoogleFonts.poppins(
                    fontSize: 10 * ws, fontWeight: FontWeight.w700,
                    color: buttonColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 6 * hs),
          SizedBox(
            width: double.infinity,
            height: 32 * hs,
            child: ElevatedButton(
              onPressed: hasPoints
                  ? () => _showRedeemSnackbar(context,
                  title.replaceAll('\n', ' '), rewards)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasPoints ? buttonColor : const Color(0xFFBDBDBD),
                foregroundColor: Colors.white,
                elevation: hasPoints ? 1 : 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7 * ws)),
              ),
              child: Text(
                hasPoints ? 'Redeem Now' : 'Not Enough',
                style: GoogleFonts.poppins(
                    fontSize: 9.0 * ws, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRedeemSnackbar(BuildContext context, String plan,
      RewardsProvider rewards) {
    final rupees = (rewards.totalPoints / kCoinsPerRupee).floor();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🎉 ₹$rupees discount applied for $plan!',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500, fontSize: 11),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF2E7D6B),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Footer ──────────────────────────────────────────────────────
  // ─── Invite Friends Card ─────────────────────────────────────────
  Widget _buildInviteFriendsCard(double ws, double hs) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E4B), Color(0xFF2E7D6B), Color(0xFF43A89E)],
        ),
        borderRadius: BorderRadius.circular(16 * ws),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E4B).withOpacity(0.25),
            blurRadius: 18, offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(16 * ws),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 42 * ws, height: 42 * ws,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12 * ws),
                ),
                child: Icon(Icons.people_alt_rounded,
                    color: Colors.white, size: 22 * ws),
              ),
              SizedBox(width: 12 * ws),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'Invite Your Friends',
                            style: GoogleFonts.poppins(
                              fontSize: 14 * ws, fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 6 * ws),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 7 * ws, vertical: 2 * ws),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFCA28),
                            borderRadius: BorderRadius.circular(20 * ws),
                          ),
                          child: Text(
                            'Coming Soon',
                            style: GoogleFonts.poppins(
                              fontSize: 7.5 * ws, fontWeight: FontWeight.w700,
                              color: const Color(0xFF7A5200),
                            ),
                            overflow: TextOverflow.clip,
                            softWrap: false,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2 * ws),
                    Text(
                      'Earn 1,000 coins per friend who joins!',
                      style: GoogleFonts.poppins(
                        fontSize: 10 * ws, fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14 * ws),
          // Reward chips row
          Row(
            children: [
              _buildInviteChip('🎁', '+1,000 coins', 'per friend', ws),
              SizedBox(width: 8 * ws),
              _buildInviteChip('👥', 'Unlimited', 'referrals', ws),
              SizedBox(width: 8 * ws),
              _buildInviteChip('⚡', 'Instant', 'reward', ws),
            ],
          ),
          SizedBox(height: 14 * ws),
          // CTA Button — disabled (coming soon)
          Container(
            width: double.infinity,
            height: 44 * ws,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(22 * ws),
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.share_rounded, color: Colors.white.withOpacity(0.6), size: 16 * ws),
                SizedBox(width: 8 * ws),
                Text(
                  'Share Invite Link  (Coming Soon)',
                  style: GoogleFonts.poppins(
                    fontSize: 12 * ws, fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteChip(String emoji, String value, String label, double ws) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10 * ws),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12 * ws),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 16 * ws)),
            SizedBox(height: 3 * ws),
            Text(value,
              style: GoogleFonts.poppins(
                fontSize: 10 * ws, fontWeight: FontWeight.w700, color: Colors.white,
              ),
            ),
            Text(label,
              style: GoogleFonts.poppins(
                fontSize: 8.5 * ws, color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuredFooter(double ws, double hs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22 * ws, height: 22 * ws,
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2),
            borderRadius: BorderRadius.circular(5 * ws),
          ),
          child: Icon(Icons.verified_user, color: Colors.white, size: 13 * ws),
        ),
        SizedBox(width: 6 * ws),
        Text(
          'Secured & Verified Rewards',
          style: GoogleFonts.poppins(
            fontSize: 10 * ws, fontWeight: FontWeight.w500,
            color: const Color(0xFF7A8A8E),
          ),
        ),
      ],
    );
  }

  Widget _buildShieldLogo(double size, double ws) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF43A89E), Color(0xFF2E7D6B)],
        ),
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D6B).withOpacity(0.25),
            blurRadius: 6, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(Icons.health_and_safety,
          color: Colors.white, size: size * 0.55),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Claim Reward Animated Dialog
// ══════════════════════════════════════════════════════════════════
class _ClaimRewardDialog extends StatefulWidget {
  const _ClaimRewardDialog();

  @override
  State<_ClaimRewardDialog> createState() => _ClaimRewardDialogState();
}

class _ClaimRewardDialogState extends State<_ClaimRewardDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late AnimationController _confettiCtrl;
  late Animation<double>   _scaleAnim;
  late Animation<double>   _fadeAnim;

  bool _claiming  = false;
  bool _claimed   = false;

  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();

    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _confettiCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));

    _scaleAnim = CurvedAnimation(
        parent: _scaleCtrl, curve: Curves.elasticOut);
    _fadeAnim  = CurvedAnimation(
        parent: _scaleCtrl, curve: Curves.easeIn);

    // Generate confetti particles
    final rng = math.Random();
    for (int i = 0; i < 30; i++) {
      _particles.add(_ConfettiParticle(
        x: rng.nextDouble(),
        delay: rng.nextDouble() * 0.6,
        speed: 0.4 + rng.nextDouble() * 0.6,
        size: 6 + rng.nextDouble() * 8,
        color: [
          const Color(0xFFFFCA28),
          const Color(0xFF4CAF50),
          const Color(0xFF2196F3),
          const Color(0xFFE91E63),
          const Color(0xFFFF5722),
        ][rng.nextInt(5)],
        rotation: rng.nextDouble() * math.pi * 2,
      ));
    }

    _scaleCtrl.forward();
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  Future<void> _doClaim() async {
    if (_claiming || _claimed) return;
    setState(() => _claiming = true);

    HapticFeedback.heavyImpact();
    final rewards = context.read<RewardsProvider>();
    final success = await rewards.claimDailyReward();

    if (!mounted) return;
    if (success) {
      setState(() {
        _claiming = false;
        _claimed  = true;
      });
      _confettiCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 2200));
      if (mounted) Navigator.of(context).pop();
    } else {
      setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Main card
              Container(
                margin: const EdgeInsets.only(top: 40),
                padding: const EdgeInsets.fromLTRB(24, 52, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 30, offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_claimed) ...[
                      Text(
                        '🎉 Claim Your Reward!',
                        style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A2E35),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You completed all 3 health goals today!\nYour 100 reward coins expire at 11:59 PM.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12, color: const Color(0xFF5C7A82),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPointsRow(),
                      const SizedBox(height: 20),
                      _buildClaimBtn(),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Remind Me Later',
                            style: GoogleFonts.poppins(
                              fontSize: 11, color: const Color(0xFF9E9E9E),
                            )),
                      ),
                    ] else ...[
                      _buildSuccessContent(),
                    ],
                  ],
                ),
              ),

              // Trophy icon at top
              Positioned(
                top: 0,
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFCA28), Color(0xFFD4A017)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4A017).withOpacity(0.4),
                        blurRadius: 16, offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _claimed ? '🏆' : '🎁',
                      style: const TextStyle(fontSize: 34),
                    ),
                  ),
                ),
              ),

              // Confetti overlay
              if (_claimed)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _confettiCtrl,
                      builder: (_, __) => CustomPaint(
                        painter: _ConfettiPainter(
                          particles: _particles,
                          progress: _confettiCtrl.value,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCA28).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _pointChip('👟 Steps', '+50 pts', const Color(0xFF1976D2)),
          _divider(),
          _pointChip('💧 Water', '+25 pts', const Color(0xFF0097A7)),
          _divider(),
          _pointChip('😴 Sleep', '+25 pts', const Color(0xFF673AB7)),
        ],
      ),
    );
  }

  Widget _pointChip(String label, String pts, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.poppins(
            fontSize: 10, color: const Color(0xFF5C7A82))),
        const SizedBox(height: 2),
        Text(pts, style: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _divider() => Container(
    height: 28, width: 1,
    color: const Color(0xFFE0E0E0),
  );

  Widget _buildClaimBtn() {
    return GestureDetector(
      onTap: _claiming ? null : _doClaim,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD4A017), Color(0xFFFFCA28), Color(0xFFD4A017)],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4A017).withOpacity(0.4),
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: _claiming
              ? const SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5))
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎁', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('Claim 100 Coins Now',
                  style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Consumer<RewardsProvider>(
      builder: (_, rewards, __) => Column(
        children: [
          Text('Points Claimed! 🎉',
              style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.w800,
                color: const Color(0xFF2E7D32),
              )),
          const SizedBox(height: 8),
          Text(
            '+100 coins added to your balance',
            style: GoogleFonts.poppins(
              fontSize: 12, color: const Color(0xFF5C7A82),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Balance',
                        style: GoogleFonts.poppins(
                          fontSize: 11, color: const Color(0xFF5C7A82),
                        )),
                    Text('${rewards.totalPoints} coins',
                        style: GoogleFonts.poppins(
                          fontSize: 22, fontWeight: FontWeight.w800,
                          color: const Color(0xFF2E7D32),
                        )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Confetti Painter ──────────────────────────────────────────────
class _ConfettiParticle {
  final double x, delay, speed, size, rotation;
  final Color color;
  const _ConfettiParticle({
    required this.x, required this.delay,
    required this.speed, required this.size,
    required this.color, required this.rotation,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  const _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = ((progress - p.delay) * p.speed).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final x = p.x * size.width;
      final y = t * size.height * 1.2;
      final opacity = (1.0 - t * 0.8).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + t * math.pi * 3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero,
              width: p.size, height: p.size * 0.5),
          const Radius.circular(2),
        ),
        Paint()..color = p.color.withOpacity(opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}