import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/tracker_provider.dart';
import '../../../core/models/tracker_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/sleep_tracker_service.dart';

class SleepTrackerScreen extends ConsumerStatefulWidget {
  const SleepTrackerScreen({super.key});

  @override
  ConsumerState<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends ConsumerState<SleepTrackerScreen> {
  DateTime _bedtime = DateTime.now().subtract(const Duration(hours: 8));
  DateTime _wakeTime = DateTime.now();

  bool _sleepAlarmsEnabled = false;
  int _scheduledBedtimeHour = 23;
  int _scheduledBedtimeMinute = 0;
  int _scheduledWakeHour = 6;
  int _scheduledWakeMinute = 0;

  @override
  void initState() {
    super.initState();
    _loadAlarmSchedule();
  }

  Future<void> _loadAlarmSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _sleepAlarmsEnabled = prefs.getBool('sleep_alarms_enabled') ?? false;
        _scheduledBedtimeHour = prefs.getInt('scheduled_bedtime_hour') ?? 23;
        _scheduledBedtimeMinute = prefs.getInt('scheduled_bedtime_minute') ?? 0;
        _scheduledWakeHour = prefs.getInt('scheduled_wake_hour') ?? 6;
        _scheduledWakeMinute = prefs.getInt('scheduled_wake_minute') ?? 0;
      });
    } catch (_) {}
  }

  Future<void> _toggleSleepAlarms(bool enabled) async {
    try {
      HapticFeedback.mediumImpact();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sleep_alarms_enabled', enabled);
      setState(() {
        _sleepAlarmsEnabled = enabled;
      });
      if (enabled) {
        await SleepTrackerService.instance.scheduleSleepNotifications(
          bedtimeHour: _scheduledBedtimeHour,
          bedtimeMinute: _scheduledBedtimeMinute,
          wakeHour: _scheduledWakeHour,
          wakeMinute: _scheduledWakeMinute,
        );
      } else {
        await SleepTrackerService.instance.cancelAllSleepNotifications();
      }
    } catch (_) {}
  }

  Future<void> _pickScheduleTime(bool isBedtime) async {
    final initialHour = isBedtime ? _scheduledBedtimeHour : _scheduledWakeHour;
    final initialMinute = isBedtime ? _scheduledBedtimeMinute : _scheduledWakeMinute;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );

    if (time != null) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        if (isBedtime) {
          _scheduledBedtimeHour = time.hour;
          _scheduledBedtimeMinute = time.minute;
        } else {
          _scheduledWakeHour = time.hour;
          _scheduledWakeMinute = time.minute;
        }
      });

      if (isBedtime) {
        await prefs.setInt('scheduled_bedtime_hour', time.hour);
        await prefs.setInt('scheduled_bedtime_minute', time.minute);
      } else {
        await prefs.setInt('scheduled_wake_hour', time.hour);
        await prefs.setInt('scheduled_wake_minute', time.minute);
      }

      // Reschedule native alarms if enabled
      if (_sleepAlarmsEnabled) {
        await SleepTrackerService.instance.scheduleSleepNotifications(
          bedtimeHour: _scheduledBedtimeHour,
          bedtimeMinute: _scheduledBedtimeMinute,
          wakeHour: _scheduledWakeHour,
          wakeMinute: _scheduledWakeMinute,
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  Future<void> _pickDateTime(bool isBedtime) async {
    final initialDate = isBedtime ? _bedtime : _wakeTime;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 14)),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (time != null) {
        setState(() {
          final newDt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          if (isBedtime) {
            _bedtime = newDt;
          } else {
            _wakeTime = newDt;
          }
        });
      }
    }
  }

  Future<void> _logSleep() async {
    HapticFeedback.lightImpact();
    if (_wakeTime.isAfter(_bedtime)) {
      final success = await ref.read(trackerProvider.notifier).addSleep(_bedtime, _wakeTime);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Sleep session logged successfully!' : 'Failed to log sleep'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waketime must be after Bedtime'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackerState = ref.watch(trackerProvider);
    final sleepLogs = trackerState.sleepLogs;

    // Calculate statistics
    double avgSleepMins = 0;
    if (sleepLogs.isNotEmpty) {
      final totalMins = sleepLogs.fold(0, (sum, log) => sum + log.wakeTime.difference(log.bedtime).inMinutes);
      avgSleepMins = totalMins / sleepLogs.length;
    }
    final avgSleepStr = _formatDuration(Duration(minutes: avgSleepMins.round()));

    // Chart Spots (past 7 logs)
    final List<SleepLog> chartLogs = List.from(sleepLogs);
    chartLogs.sort((a, b) => a.dateKey.compareTo(b.dateKey));
    if (chartLogs.length > 7) {
      chartLogs.removeRange(0, chartLogs.length - 7);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.secondary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sleep Tracker',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.chartBar, color: AppColors.secondary, size: 22),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/tracker/sleep-insights');
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
        ),
      ),
      body: trackerState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. SLEEP TREND CHART
                  if (chartLogs.isNotEmpty) ...[
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('SLEEP DURATION (PAST 7 SESSIONS)', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10)),
                              Text('Avg: $avgSleepStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.sleepAccent)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 180,
                            child: LineChart(
                              LineChartData(
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    getTooltipColor: (_) => AppColors.secondary,
                                    getTooltipItems: (touchedSpots) {
                                      return touchedSpots.map((spot) {
                                        final log = chartLogs[spot.x.toInt()];
                                        final diff = log.wakeTime.difference(log.bedtime);
                                        return LineTooltipItem(
                                          '${log.dateKey}\n${_formatDuration(diff)}',
                                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                                gridData: const FlGridData(show: false),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final int index = value.toInt();
                                        if (index < 0 || index >= chartLogs.length) return const SizedBox();
                                        final dateKey = chartLogs[index].dateKey;
                                        String formatted = '';
                                        try {
                                          formatted = DateFormat('dd/MM').format(DateFormat('yyyy-MM-dd').parse(dateKey));
                                        } catch (_) {
                                          formatted = dateKey;
                                        }
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          space: 8,
                                          child: Text(formatted, style: const TextStyle(color: AppColors.neutral, fontSize: 10, fontWeight: FontWeight.bold)),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: List.generate(chartLogs.length, (index) {
                                      final durationHours = chartLogs[index].wakeTime.difference(chartLogs[index].bedtime).inMinutes / 60.0;
                                      return FlSpot(index.toDouble(), durationHours);
                                    }),
                                    isCurved: true,
                                    color: AppColors.sleepAccent,
                                    barWidth: 4,
                                    dotData: const FlDotData(show: true),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: AppColors.sleepAccent.withOpacity(0.08),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 1.5 SLEEP SCHEDULE & REMINDERS
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'BEDTIME ALARMS & REMINDERS',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10),
                            ),
                            Switch.adaptive(
                              activeTrackColor: AppColors.sleepAccent,
                              value: _sleepAlarmsEnabled,
                              onChanged: _toggleSleepAlarms,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Scheduled Bedtime', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(
                            '${_scheduledBedtimeHour.toString().padLeft(2, '0')}:${_scheduledBedtimeMinute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: AppColors.neutral, fontSize: 13),
                          ),
                          trailing: const Icon(PhosphorIconsRegular.pencilSimple, size: 18, color: AppColors.neutral),
                          onTap: () => _pickScheduleTime(true),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Scheduled Wake Up', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(
                            '${_scheduledWakeHour.toString().padLeft(2, '0')}:${_scheduledWakeMinute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: AppColors.neutral, fontSize: 13),
                          ),
                          trailing: const Icon(PhosphorIconsRegular.pencilSimple, size: 18, color: AppColors.neutral),
                          onTap: () => _pickScheduleTime(false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. LOG NEW SLEEP SESSION
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LOG SLEEP SESSION', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10)),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Bedtime (Sleep)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(DateFormat('EEEE, MMM d — h:mm a').format(_bedtime)),
                          trailing: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                            child: const Icon(PhosphorIconsRegular.moon, color: AppColors.sleepAccent, size: 20),
                          ),
                          onTap: () => _pickDateTime(true),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Wake time (Wake Up)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(DateFormat('EEEE, MMM d — h:mm a').format(_wakeTime)),
                          trailing: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                            child: const Icon(PhosphorIconsRegular.sun, color: Colors.orange, size: 20),
                          ),
                          onTap: () => _pickDateTime(false),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          text: 'LOG SLEEP SESSION',
                          onPressed: _logSleep,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. SLEEP HISTORY
                  Text(
                    'Sleep History',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  if (sleepLogs.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('No sleep logs found.', style: TextStyle(color: AppColors.neutral))))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sleepLogs.length,
                      itemBuilder: (context, index) {
                        final log = sleepLogs[index];
                        final diff = log.wakeTime.difference(log.bedtime);
                        final durationStr = _formatDuration(diff);
                        final dateStr = DateFormat('EEEE, MMM d').format(log.bedtime);
                        final bedtimeStr = DateFormat('h:mm a').format(log.bedtime);
                        final wakeStr = DateFormat('h:mm a').format(log.wakeTime);

                        // Quality assessment
                        final hours = diff.inHours;
                        final statusText = hours >= 7 ? 'OPTIMAL' : hours >= 6 ? 'FAIR' : 'INSUFFICIENT';
                        final statusColor = hours >= 7 ? AppColors.success : hours >= 6 ? AppColors.warning : AppColors.error;
                        final statusBg = hours >= 7 ? const Color(0xFFE6FDF4) : hours >= 6 ? const Color(0xFFFFF7ED) : const Color(0xFFFEF2F2);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: CustomCard(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.sleepAccent.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(PhosphorIconsFill.moon, color: AppColors.sleepAccent, size: 22),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          StatusBadge(
                                            text: statusText,
                                            dotColor: statusColor,
                                            backgroundColor: statusBg,
                                            textColor: statusColor,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Duration: $durationStr ($bedtimeStr - $wakeStr)',
                                        style: const TextStyle(color: AppColors.neutral, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
