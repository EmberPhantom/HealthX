// lib/screens/settings_screen.dart
// ══════════════════════════════════════════════════════════════════
//  HealthX — Settings Screen
//  ✅ All existing app permissions (Notifications, Location, Camera,
//     Activity Recognition, Battery Optimization, Storage)
//  ✅ Live permission status with real-time refresh
//  ✅ Notification sub-settings (water, sleep, health alerts)
//  ✅ App preferences (haptics, etc.)
//  ✅ Professional look matching app theme
// ══════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  // ── Permission states ──────────────────────────────────────────
  bool _notifGranted      = false;
  bool _locationGranted   = false;
  bool _cameraGranted     = false;
  bool _activityGranted   = false;
  bool _batteryGranted    = false;
  bool _storageGranted    = false;
  bool _loading           = true;

  // ── App preferences ────────────────────────────────────────────
  bool _hapticsEnabled         = true;
  bool _waterNotifEnabled      = true;
  bool _sleepNotifEnabled      = true;
  bool _healthAlertEnabled     = true;
  bool _orderUpdateEnabled     = true;
  bool _promoNotifEnabled      = false;

  static const String _kHaptics      = 'pref_haptics';
  static const String _kWaterNotif   = 'pref_water_notif';
  static const String _kSleepNotif   = 'pref_sleep_notif';
  static const String _kHealthAlert  = 'pref_health_alert';
  static const String _kOrderUpdate  = 'pref_order_update';
  static const String _kPromoNotif   = 'pref_promo_notif';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check permissions when user returns from system settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermissions();
  }

  Future<void> _loadAll() async {
    await Future.wait([_checkPermissions(), _loadPrefs()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _checkPermissions() async {
    final results = await Future.wait([
      Permission.notification.status,
      Permission.locationWhenInUse.status,
      Permission.camera.status,
      Permission.activityRecognition.status,
      Permission.ignoreBatteryOptimizations.status,
      Platform.isAndroid
          ? Permission.storage.status
          : Future.value(PermissionStatus.granted),
    ]);

    if (mounted) {
      setState(() {
        _notifGranted    = results[0].isGranted;
        _locationGranted = results[1].isGranted;
        _cameraGranted   = results[2].isGranted;
        _activityGranted = results[3].isGranted;
        _batteryGranted  = results[4].isGranted;
        _storageGranted  = results[5].isGranted;
      });
    }
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _hapticsEnabled      = p.getBool(_kHaptics)      ?? true;
        _waterNotifEnabled   = p.getBool(_kWaterNotif)   ?? true;
        _sleepNotifEnabled   = p.getBool(_kSleepNotif)   ?? true;
        _healthAlertEnabled  = p.getBool(_kHealthAlert)  ?? true;
        _orderUpdateEnabled  = p.getBool(_kOrderUpdate)  ?? true;
        _promoNotifEnabled   = p.getBool(_kPromoNotif)   ?? false;
      });
    }
  }

  Future<void> _savePref(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
  }

  // ── Permission request / open settings ─────────────────────────
  Future<void> _handlePermission({
    required Permission permission,
    required bool currentStatus,
    required String name,
  }) async {
    _haptic();
    if (currentStatus) {
      // Already granted — guide user to revoke in system settings
      _showPermissionDialog(
        title: 'Revoke $name Permission',
        body:
        'To revoke this permission, open System Settings → Apps → HealthX → Permissions and disable $name.',
        onConfirm: () => openAppSettings(),
      );
      return;
    }

    final status = await permission.request();
    if (status.isPermanentlyDenied) {
      _showPermissionDialog(
        title: '$name Permission Blocked',
        body:
        '$name permission was permanently denied. Open System Settings to enable it.',
        onConfirm: () => openAppSettings(),
      );
    }
    await _checkPermissions();
  }

  Future<void> _handleBattery() async {
    _haptic();
    if (_batteryGranted) {
      _showPermissionDialog(
        title: 'Battery Optimization',
        body:
        'To re-enable battery optimization, open System Settings → Battery → Battery Optimization → HealthX.',
        onConfirm: () => openAppSettings(),
      );
      return;
    }
    final status =
    await Permission.ignoreBatteryOptimizations.request();
    setState(() => _batteryGranted = status.isGranted);
  }

  void _showPermissionDialog({
    required String title,
    required String body,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: Text(
          title,
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: Text(
          body,
          style: TextStyle(color: AppTheme.textMedium, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: AppTheme.textMedium)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _haptic() {
    if (_hapticsEnabled) HapticFeedback.lightImpact();
  }

  // ─────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Column(
        children: [
          _buildHeader(context, top),
          Expanded(
            child: _loading
                ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryGreen,
              ),
            )
                : RefreshIndicator(
              color: AppTheme.primaryGreen,
              onRefresh: _checkPermissions,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  // ── Permissions ──────────────────────────
                  _SectionHeader(
                    icon: Icons.security_rounded,
                    title: 'App Permissions',
                    subtitle: 'Manage what HealthX can access',
                  ).animate().fadeIn(duration: 300.ms),

                  const SizedBox(height: 10),

                  _PermissionTile(
                    icon: Icons.notifications_outlined,
                    iconColor: AppTheme.primaryGreen,
                    title: 'Notifications',
                    subtitle: 'Order updates, health reminders & alerts',
                    granted: _notifGranted,
                    onToggle: () => _handlePermission(
                      permission: Permission.notification,
                      currentStatus: _notifGranted,
                      name: 'Notifications',
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: 60.ms),

                  _PermissionTile(
                    icon: Icons.location_on_outlined,
                    iconColor: const Color(0xFF1565C0),
                    title: 'Location',
                    subtitle:
                    'Required for delivery address & nearby stores',
                    granted: _locationGranted,
                    onToggle: () => _handlePermission(
                      permission: Permission.locationWhenInUse,
                      currentStatus: _locationGranted,
                      name: 'Location',
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

                  _PermissionTile(
                    icon: Icons.camera_alt_outlined,
                    iconColor: const Color(0xFF6A1B9A),
                    title: 'Camera',
                    subtitle:
                    'Used for profile photo & document scanning',
                    granted: _cameraGranted,
                    onToggle: () => _handlePermission(
                      permission: Permission.camera,
                      currentStatus: _cameraGranted,
                      name: 'Camera',
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: 140.ms),

                  _PermissionTile(
                    icon: Icons.directions_walk_rounded,
                    iconColor: AppTheme.yellow,
                    title: 'Physical Activity',
                    subtitle:
                    'Counts your daily steps for health rewards',
                    granted: _activityGranted,
                    onToggle: () => _handlePermission(
                      permission: Permission.activityRecognition,
                      currentStatus: _activityGranted,
                      name: 'Physical Activity',
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: 180.ms),

                  _PermissionTile(
                    icon: Icons.battery_charging_full_rounded,
                    iconColor: const Color(0xFF00897B),
                    title: 'Battery Optimization',
                    subtitle:
                    'Keeps step counter & sleep alarms running in background',
                    granted: _batteryGranted,
                    grantedLabel: 'Unrestricted',
                    deniedLabel: 'Restricted',
                    onToggle: _handleBattery,
                  ).animate().fadeIn(duration: 300.ms, delay: 220.ms),

                  if (Platform.isAndroid)
                    _PermissionTile(
                      icon: Icons.folder_outlined,
                      iconColor: AppTheme.red,
                      title: 'Storage',
                      subtitle:
                      'Access photos for profile & document upload',
                      granted: _storageGranted,
                      onToggle: () => _handlePermission(
                        permission: Permission.storage,
                        currentStatus: _storageGranted,
                        name: 'Storage',
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: 260.ms),

                  const SizedBox(height: 20),

                  // ── Notification Preferences ─────────────
                  _SectionHeader(
                    icon: Icons.tune_rounded,
                    title: 'Notification Preferences',
                    subtitle:
                    'Choose which alerts you want to receive',
                  ).animate().fadeIn(duration: 300.ms, delay: 300.ms),

                  const SizedBox(height: 10),

                  _PrefCard(
                    children: [
                      _PrefToggle(
                        icon: Icons.water_drop_outlined,
                        iconColor: const Color(0xFF0288D1),
                        title: 'Water Reminders',
                        subtitle: 'Stay hydrated throughout the day',
                        value: _waterNotifEnabled,
                        onChanged: (v) {
                          _haptic();
                          setState(() => _waterNotifEnabled = v);
                          _savePref(_kWaterNotif, v);
                        },
                      ),
                      _Divider(),
                      _PrefToggle(
                        icon: Icons.bedtime_outlined,
                        iconColor: const Color(0xFF5E35B1),
                        title: 'Sleep Alarms',
                        subtitle:
                        'Bedtime reminders & morning motivation',
                        value: _sleepNotifEnabled,
                        onChanged: (v) {
                          _haptic();
                          setState(() => _sleepNotifEnabled = v);
                          _savePref(_kSleepNotif, v);
                        },
                      ),
                      _Divider(),
                      _PrefToggle(
                        icon: Icons.favorite_outline_rounded,
                        iconColor: AppTheme.red,
                        title: 'Health Alerts',
                        subtitle:
                        'Daily goal completion & reward claims',
                        value: _healthAlertEnabled,
                        onChanged: (v) {
                          _haptic();
                          setState(() => _healthAlertEnabled = v);
                          _savePref(_kHealthAlert, v);
                        },
                      ),
                      _Divider(),
                      _PrefToggle(
                        icon: Icons.receipt_long_outlined,
                        iconColor: AppTheme.primaryGreen,
                        title: 'Order Updates',
                        subtitle:
                        'Delivery status & order confirmations',
                        value: _orderUpdateEnabled,
                        onChanged: (v) {
                          _haptic();
                          setState(() => _orderUpdateEnabled = v);
                          _savePref(_kOrderUpdate, v);
                        },
                      ),
                      _Divider(),
                      _PrefToggle(
                        icon: Icons.local_offer_outlined,
                        iconColor: AppTheme.yellow,
                        title: 'Promotions & Offers',
                        subtitle:
                        'Deals, discounts & seasonal offers',
                        value: _promoNotifEnabled,
                        onChanged: (v) {
                          _haptic();
                          setState(() => _promoNotifEnabled = v);
                          _savePref(_kPromoNotif, v);
                        },
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms, delay: 340.ms),

                  const SizedBox(height: 20),

                  // ── App Preferences ───────────────────────
                  _SectionHeader(
                    icon: Icons.phone_android_rounded,
                    title: 'App Preferences',
                    subtitle: 'Personalize your app experience',
                  ).animate().fadeIn(duration: 300.ms, delay: 440.ms),

                  const SizedBox(height: 10),

                  _PrefCard(
                    children: [
                      _PrefToggle(
                        icon: Icons.vibration_rounded,
                        iconColor: AppTheme.primaryGreen,
                        title: 'Haptic Feedback',
                        subtitle:
                        'Feel subtle vibrations on button taps',
                        value: _hapticsEnabled,
                        onChanged: (v) {
                          // Give one last haptic before disabling
                          HapticFeedback.mediumImpact();
                          setState(() => _hapticsEnabled = v);
                          _savePref(_kHaptics, v);
                        },
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms, delay: 480.ms),

                  const SizedBox(height: 20),

                  // ── Danger Zone ───────────────────────────
                  _SectionHeader(
                    icon: Icons.info_outline_rounded,
                    title: 'About',
                    subtitle: 'App & permission information',
                  ).animate().fadeIn(duration: 300.ms, delay: 520.ms),

                  const SizedBox(height: 10),

                  _PrefCard(
                    children: [
                      _InfoTile(
                        icon: Icons.open_in_new_rounded,
                        iconColor: AppTheme.primaryGreen,
                        title: 'All App Permissions',
                        subtitle:
                        'View & manage all permissions in system settings',
                        onTap: () {
                          _haptic();
                          openAppSettings();
                        },
                      ),
                      _Divider(),
                      _InfoTile(
                        icon: Icons.refresh_rounded,
                        iconColor: const Color(0xFF1565C0),
                        title: 'Refresh Permission Status',
                        subtitle:
                        'Re-check all permissions from system',
                        onTap: () async {
                          _haptic();
                          await _checkPermissions();
                          if (mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.white,
                                        size: 16),
                                    SizedBox(width: 8),
                                    Text('Permissions refreshed'),
                                  ],
                                ),
                                backgroundColor:
                                AppTheme.primaryGreen,
                                behavior:
                                SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(
                                        10)),
                                duration:
                                const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms, delay: 560.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, double top) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
          top: top + 10, bottom: 20, left: 16, right: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius:
        const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Manage permissions & preferences',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          // Permission health indicator
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _allCriticalGranted
                      ? Icons.shield_rounded
                      : Icons.warning_rounded,
                  color: _allCriticalGranted
                      ? const Color(0xFF76FF03)
                      : AppTheme.yellow,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  _allCriticalGranted ? 'All Clear' : 'Action Needed',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  bool get _allCriticalGranted =>
      _notifGranted && _locationGranted && _activityGranted;
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryGreen, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                    color: AppTheme.textMedium, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrefCard extends StatelessWidget {
  final List<Widget> children;
  const _PrefCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 54,
      endIndent: 16,
      color: const Color(0xFFF0F0F0),
    );
  }
}

/// A permission tile with a custom green/red status badge (not a Switch)
/// so it clearly communicates it opens a system dialog
class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool granted;
  final String? grantedLabel;
  final String? deniedLabel;
  final VoidCallback onToggle;

  const _PermissionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onToggle,
    this.grantedLabel,
    this.deniedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final label = granted
        ? (grantedLabel ?? 'Granted')
        : (deniedLabel ?? 'Denied');
    final badgeColor =
    granted ? AppTheme.primaryGreen : AppTheme.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppTheme.textMedium,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: badgeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrefToggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrefToggle({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                      color: AppTheme.textMedium, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryGreen,
            trackOutlineWidth: WidgetStatePropertyAll(0),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                          color: AppTheme.textMedium, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 13, color: AppTheme.textLight),
            ],
          ),
        ),
      ),
    );
  }
}