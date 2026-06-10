// lib/screens/set_reminders_screen.dart
//
// pubspec.yaml dependencies required:
//   permission_handler: ^11.3.0
//   shared_preferences: ^2.2.3
//
// AndroidManifest.xml (inside <manifest>):
//   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
//   <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
//
// iOS Info.plist:
//   <key>NSUserNotificationUsageDescription</key>
//   <string>We need this to send your medicine reminders.</string>

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme.dart';

class SetRemindersScreen extends StatefulWidget {
  const SetRemindersScreen({super.key});
  @override
  State<SetRemindersScreen> createState() => _SetRemindersScreenState();
}

class _SetRemindersScreenState extends State<SetRemindersScreen>
    with WidgetsBindingObserver {
  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const _kNotif  = 'perm_notifications_enabled';
  static const _kAlarm  = 'perm_alarms_enabled';

  // ── State ─────────────────────────────────────────────────────────────────
  bool _notificationsEnabled = false;
  bool _alarmsEnabled        = false;
  bool _notifExpanded        = true;
  bool _alarmExpanded        = false;
  bool _loading              = true;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAndSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// When user returns from system settings, re-verify real OS permission.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAndSync();
    }
  }

  // ── Load from prefs AND verify against real OS status ────────────────────
  Future<void> _loadAndSync() async {
    final prefs = await SharedPreferences.getInstance();

    // Real notification status from OS
    final notifStatus  = await Permission.notification.status;
    final notifGranted = notifStatus.isGranted;

    // Real exact-alarm status (Android 12+ only; graceful fallback for others)
    bool alarmGranted;
    try {
      alarmGranted = (await Permission.scheduleExactAlarm.status).isGranted;
    } catch (_) {
      alarmGranted = true; // platform does not require this permission
    }

    // If OS revoked — clear saved state to match reality
    if (!notifGranted) await prefs.setBool(_kNotif,  false);
    if (!alarmGranted) await prefs.setBool(_kAlarm, false);

    final savedNotif  = (prefs.getBool(_kNotif)  ?? false) && notifGranted;
    final savedAlarm  = (prefs.getBool(_kAlarm) ?? false) && alarmGranted;

    if (!mounted) return;
    setState(() {
      _notificationsEnabled = savedNotif;
      _alarmsEnabled        = savedAlarm;
      // Auto-expand the first pending step
      _notifExpanded  = !savedNotif;
      _alarmExpanded  = savedNotif && !savedAlarm;
      _loading        = false;
    });
  }

  // ── Request notification permission ──────────────────────────────────────
  Future<void> _requestNotification() async {
    final proceed = await _showExplainDialog(
      icon: Icons.notifications_active_rounded,
      iconBg: AppTheme.emerald50,
      iconColor: AppTheme.primaryGreen,
      title: 'Enable Notifications',
      body: 'HealthX needs permission to send you medicine reminders and health alerts.\n\nTap "Continue" then Allow on the system prompt.',
      btnColor: AppTheme.primaryGreen,
    );
    if (!proceed || !mounted) return;

    final status = await Permission.notification.request();

    if (status.isGranted) {
      await _persist(notif: true);
      _toast('Notifications enabled!');
    } else if (status.isPermanentlyDenied) {
      _showSettingsDialog(
        title: 'Notifications Blocked',
        body: 'You permanently denied notifications. Open your device Settings to enable them.',
      );
    } else {
      _toast('Notification permission was not granted.');
    }
  }

  // ── Request alarm permission ──────────────────────────────────────────────
  Future<void> _requestAlarm() async {
    final proceed = await _showExplainDialog(
      icon: Icons.alarm_rounded,
      iconBg: const Color(0xFFFFFBEB),
      iconColor: const Color(0xFFF59E0B),
      title: 'Alarms & Reminders',
      body: 'HealthX needs permission to schedule exact alarms so your reminders fire at the right time.\n\nTap "Continue" then Allow on the system prompt.',
      btnColor: AppTheme.primaryGreen,
    );
    if (!proceed || !mounted) return;

    PermissionStatus status;
    try {
      status = await Permission.scheduleExactAlarm.request();
    } catch (_) {
      status = PermissionStatus.granted;
    }

    if (status.isGranted) {
      await _persist(alarm: true);
      _toast('Alarm permission granted!');
    } else if (status.isPermanentlyDenied) {
      _showSettingsDialog(
        title: 'Alarm Permission Blocked',
        body: 'Please enable "Alarms & reminders" from your device app settings.',
      );
    } else {
      _toast('Alarm permission was not granted.');
    }
  }

  // ── Persist to SharedPreferences ─────────────────────────────────────────
  Future<void> _persist({bool notif = false, bool alarm = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (notif) await prefs.setBool(_kNotif, true);
    if (alarm) await prefs.setBool(_kAlarm, true);
    if (!mounted) return;
    setState(() {
      if (notif) {
        _notificationsEnabled = true;
        _notifExpanded        = false;
        _alarmExpanded        = true;
      }
      if (alarm) {
        _alarmsEnabled  = true;
        _alarmExpanded  = false;
      }
    });
  }

  // ── Explanation dialog ────────────────────────────────────────────────────
  Future<bool> _showExplainDialog({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String body,
    required Color btnColor,
  }) async {
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 36),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
            const SizedBox(height: 8),
            Text(body,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppTheme.textMedium, height: 1.5)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.divider),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Not Now',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMedium)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Continue',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
    return res == true;
  }

  // ── "Open Settings" dialog — for permanently denied permissions ───────────
  void _showSettingsDialog({required String title, required String body}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF3ED), shape: BoxShape.circle),
              child: const Icon(Icons.settings_rounded,
                  color: Color(0xFFEA580C), size: 36),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
            const SizedBox(height: 8),
            Text(body,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppTheme.textMedium, height: 1.5)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.divider),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Cancel',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMedium)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  // ✅ Opens real system App Info / Settings page
                  onPressed: () {
                    Navigator.pop(ctx);
                    openAppSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Open Settings',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor: AppTheme.primaryGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.bgLight,
        appBar: _appBar(),
        body: const Center(
            child:
            CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: _appBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Allow HealthX to set your\nmedicine reminders',
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
                height: 1.4),
          ),
          const SizedBox(height: 16),

          // ── Notifications tile ──────────────────────────────────────
          _PermissionTile(
            icon: Icons.notifications_outlined,
            iconColor: AppTheme.primaryGreen,
            iconBg: AppTheme.emerald50,
            title: 'Enable Notifications',
            subtitle:
            'Enable push notifications to receive medicine reminders.',
            isExpanded: _notifExpanded,
            onHeaderTap: () =>
                setState(() => _notifExpanded = !_notifExpanded),
            badge: _notificationsEnabled
                ? const _StatusBadge(
                label: 'Enabled', color: AppTheme.primaryGreen)
                : null,
            action: _notificationsEnabled
                ? null
                : ElevatedButton(
              onPressed: _requestNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Enable',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ),

          const SizedBox(height: 12),

          // ── Alarms tile ─────────────────────────────────────────────
          _PermissionTile(
            icon: Icons.alarm_rounded,
            iconColor: const Color(0xFFF59E0B),
            iconBg: const Color(0xFFFFFBEB),
            title: 'Alarms & reminders\npermission',
            subtitle:
            'Required to schedule exact alarms for your medicine reminders.',
            isExpanded: _alarmExpanded,
            onHeaderTap: () =>
                setState(() => _alarmExpanded = !_alarmExpanded),
            badge: _alarmsEnabled
                ? const _StatusBadge(
                label: 'Allowed', color: Color(0xFFF59E0B))
                : null,
            action: _alarmsEnabled
                ? null
                : ElevatedButton(
              onPressed: _notificationsEnabled
                  ? _requestAlarm
                  : () => _toast('Please enable notifications first.'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _notificationsEnabled
                    ? AppTheme.primaryGreen
                    : AppTheme.textLight,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Allow',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ),

          // ── All set ─────────────────────────────────────────────────
          if (_notificationsEnabled && _alarmsEnabled) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.emerald50,
                borderRadius: BorderRadius.circular(14),
                border:
                Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('All set!',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark)),
                        Text(
                          'You will now receive medicine reminders from HealthX.',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textMedium,
                              height: 1.4),
                        ),
                      ]),
                ),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  AppBar _appBar() => AppBar(
    title: Text('My Reminders',
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700, fontSize: 17)),
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
      onPressed: () => Navigator.pop(context),
    ),
  );
}

// ─── Permission Tile ──────────────────────────────────────────────────────────
class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle;
  final bool isExpanded;
  final VoidCallback onHeaderTap;
  final Widget? action, badge;

  const _PermissionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.isExpanded,
    required this.onHeaderTap,
    this.action,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onHeaderTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration:
                  BoxDecoration(color: iconBg, shape: BoxShape.circle),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                                height: 1.3)),
                        if (badge != null) ...[
                          const SizedBox(height: 4),
                          badge!,
                        ],
                      ]),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textMedium,
                  size: 22,
                ),
              ]),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppTheme.textMedium,
                          height: 1.5)),
                  if (action != null) ...[
                    const SizedBox(height: 12),
                    action!,
                  ],
                ]),
          ),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ]),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_rounded, color: color, size: 12),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}