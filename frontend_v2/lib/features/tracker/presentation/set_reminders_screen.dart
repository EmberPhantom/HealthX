import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../notifications/providers/notification_preferences_provider.dart';

class SetRemindersScreen extends ConsumerStatefulWidget {
  const SetRemindersScreen({super.key});

  @override
  ConsumerState<SetRemindersScreen> createState() => _SetRemindersScreenState();
}

class _SetRemindersScreenState extends ConsumerState<SetRemindersScreen> with WidgetsBindingObserver {
  static const _kNotif = 'perm_notifications_enabled';
  static const _kAlarm = 'perm_alarms_enabled';

  bool _notificationsPermissionGranted = false;
  bool _exactAlarmsPermissionGranted = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final prefs = await SharedPreferences.getInstance();

    // Verify notification permission
    final notifStatus = await Permission.notification.status;
    final notifGranted = notifStatus.isGranted;

    // Verify exact alarms permission (primarily Android 12+)
    bool alarmGranted;
    try {
      alarmGranted = (await Permission.scheduleExactAlarm.status).isGranted;
    } catch (_) {
      alarmGranted = true; // Not required on this platform
    }

    // Update prefs to match OS reality
    await prefs.setBool(_kNotif, notifGranted);
    await prefs.setBool(_kAlarm, alarmGranted);

    if (mounted) {
      setState(() {
        _notificationsPermissionGranted = notifGranted;
        _exactAlarmsPermissionGranted = alarmGranted;
        _loading = false;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    HapticFeedback.mediumImpact();
    
    // Check current status
    final status = await Permission.notification.status;
    if (status.isPermanentlyDenied) {
      _showSettingsDialog(
        title: 'Notifications Permanently Blocked',
        body: 'Please open settings and enable notifications for HealthX to receive real-time alerts and reminders.',
      );
      return;
    }

    final requestedStatus = await Permission.notification.request();
    if (requestedStatus.isGranted) {
      await _persistPermission(_kNotif, true);
      _showToast('Notifications permission granted!');
    } else {
      _showToast('Notifications permission denied.');
    }
    await _checkPermissions();
  }

  Future<void> _requestExactAlarmsPermission() async {
    HapticFeedback.mediumImpact();
    
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isPermanentlyDenied) {
      _showSettingsDialog(
        title: 'Alarms & Reminders Blocked',
        body: 'Please enable "Alarms & reminders" permission in system settings to support exact notification scheduling.',
      );
      return;
    }

    final requestedStatus = await Permission.scheduleExactAlarm.request();
    if (requestedStatus.isGranted) {
      await _persistPermission(_kAlarm, true);
      _showToast('Alarms & reminders permission granted!');
    } else {
      _showToast('Alarms permission was not granted.');
    }
    await _checkPermissions();
  }

  Future<void> _persistPermission(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _showSettingsDialog({required String title, required String body}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: AppColors.neutral)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.secondary,
              ),
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('OPEN SETTINGS'),
            ),
          ],
        );
      },
    );
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifState = ref.watch(notificationPreferencesProvider);
    final notifNotifier = ref.read(notificationPreferencesProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.secondary, size: 22),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Reminders & Alerts',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
        ),
      ),
      body: _loading || notifState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SYSTEM PERMISSIONS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 12),

                  // 1. Notifications OS permission
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _notificationsPermissionGranted
                                    ? AppColors.success.withValues(alpha: 0.1)
                                    : AppColors.error.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                PhosphorIconsRegular.bellSimple,
                                color: _notificationsPermissionGranted ? AppColors.success : AppColors.error,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('System Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _notificationsPermissionGranted
                                        ? 'Allowed on this device'
                                        : 'Required to deliver alarms and alerts',
                                    style: const TextStyle(color: AppColors.neutral, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (_notificationsPermissionGranted)
                              const StatusBadge(
                                text: 'ACTIVE',
                                dotColor: AppColors.success,
                                backgroundColor: Color(0xFFE6FDF4),
                                textColor: AppColors.success,
                              )
                            else
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.secondary,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: _requestNotificationPermission,
                                child: const Text('Enable', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Exact Alarms OS permission
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _exactAlarmsPermissionGranted
                                    ? AppColors.success.withValues(alpha: 0.1)
                                    : AppColors.warning.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                PhosphorIconsRegular.alarm,
                                color: _exactAlarmsPermissionGranted ? AppColors.success : AppColors.warning,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Exact Alarms & Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _exactAlarmsPermissionGranted
                                        ? 'Allowed on this device'
                                        : 'Required for precisely timed schedule alerts',
                                    style: const TextStyle(color: AppColors.neutral, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (_exactAlarmsPermissionGranted)
                              const StatusBadge(
                                text: 'ALLOWED',
                                dotColor: AppColors.success,
                                backgroundColor: Color(0xFFE6FDF4),
                                textColor: AppColors.success,
                              )
                            else
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.secondary,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: _requestExactAlarmsPermission,
                                child: const Text('Allow', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'REMINIDER PREFERENCES',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 12),

                  // 3. Toggles card
                  CustomCard(
                    child: Opacity(
                      opacity: _notificationsPermissionGranted ? 1.0 : 0.5,
                      child: AbsorbPointer(
                        absorbing: !_notificationsPermissionGranted,
                        child: Column(
                          children: [
                            _buildPreferenceToggle(
                              icon: PhosphorIconsRegular.drop,
                              label: 'Hydration Reminders',
                              subtitle: 'Remind to drink water regularly',
                              value: notifState.waterReminders,
                              onChanged: (val) => notifNotifier.toggle('water_reminders', val),
                              accentColor: AppColors.waterAccent,
                            ),
                            const Divider(height: 24),
                            _buildPreferenceToggle(
                              icon: PhosphorIconsRegular.moon,
                              label: 'Sleep & Bedtime Alarms',
                              subtitle: 'Alert to sleep and wake up on schedule',
                              value: notifState.sleepAlarms,
                              onChanged: (val) => notifNotifier.toggle('sleep_alarms', val),
                              accentColor: AppColors.sleepAccent,
                            ),
                            const Divider(height: 24),
                            _buildPreferenceToggle(
                              icon: PhosphorIconsRegular.heartbeat,
                              label: 'Health & Vital Alerts',
                              subtitle: 'Notification on abnormal readings',
                              value: notifState.healthAlerts,
                              onChanged: (val) => notifNotifier.toggle('health_alerts', val),
                              accentColor: AppColors.vitalsAccent,
                            ),
                            const Divider(height: 24),
                            _buildPreferenceToggle(
                              icon: PhosphorIconsRegular.shoppingBag,
                              label: 'Shop & Order Updates',
                              subtitle: 'Purchase confirmations and dispatch notifications',
                              value: notifState.orderUpdates,
                              onChanged: (val) => notifNotifier.toggle('order_updates', val),
                              accentColor: AppColors.glucoseAccent,
                            ),
                            const Divider(height: 24),
                            _buildPreferenceToggle(
                              icon: PhosphorIconsRegular.tag,
                              label: 'Promotional Offers',
                              subtitle: 'Exclusive discounts and wellness campaigns',
                              value: notifState.promotionsOffers,
                              onChanged: (val) => notifNotifier.toggle('promotions_offers', val),
                              accentColor: AppColors.rewardsAccent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!_notificationsPermissionGranted) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Row(
                        children: [
                          const Icon(PhosphorIconsRegular.info, size: 14, color: AppColors.error),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Please enable push notifications permission above to configure reminders.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.error,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPreferenceToggle({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color accentColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: accentColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(subtitle, style: const TextStyle(color: AppColors.neutral, fontSize: 11)),
            ],
          ),
        ),
        Switch.adaptive(
          activeTrackColor: AppColors.primary,
          value: value,
          onChanged: (val) {
            HapticFeedback.lightImpact();
            onChanged(val);
          },
        ),
      ],
    );
  }
}
