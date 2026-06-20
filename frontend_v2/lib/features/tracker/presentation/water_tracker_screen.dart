import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/tracker_provider.dart';
import '../../../core/models/tracker_models.dart';
import '../../../core/services/water_tracker_service.dart';

class WaterTrackerScreen extends ConsumerStatefulWidget {
  const WaterTrackerScreen({super.key});

  @override
  ConsumerState<WaterTrackerScreen> createState() => _WaterTrackerScreenState();
}

class _WaterTrackerScreenState extends ConsumerState<WaterTrackerScreen> {
  int _waterGoal = 2500;
  bool _isLoadingGoal = true;
  bool _remindersEnabled = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadGoal();
    _loadRemindersState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll * 0.8) {
      ref.read(trackerProvider.notifier).fetchMoreWater();
    }
  }

  Future<void> _loadRemindersState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _remindersEnabled = prefs.getBool('water_reminders_enabled') ?? false;
      });
    } catch (_) {}
  }

  Future<void> _toggleReminders(bool enabled) async {
    try {
      HapticFeedback.mediumImpact();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('water_reminders_enabled', enabled);
      setState(() {
        _remindersEnabled = enabled;
      });
      if (enabled) {
        await WaterTrackerService.instance.startWaterReminders(120); // 2 hours
      } else {
        await WaterTrackerService.instance.stopWaterReminders();
      }
    } catch (_) {}
  }

  Future<void> _loadGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _waterGoal = prefs.getInt('water_goal') ?? 2500;
        _isLoadingGoal = false;
      });
      await WaterTrackerService.instance.setWaterGoal(_waterGoal);
    } catch (_) {
      setState(() => _isLoadingGoal = false);
    }
  }

  Future<void> _saveGoal(int goal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('water_goal', goal);
      setState(() {
        _waterGoal = goal;
      });
      await WaterTrackerService.instance.setWaterGoal(goal);
    } catch (_) {}
  }

  void _showSetGoalDialog() {
    final controller = TextEditingController(text: _waterGoal.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Set Daily Hydration Goal', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Water Goal (mL)',
              border: OutlineInputBorder(),
              hintText: 'e.g. 3000',
            ),
          ),
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
              onPressed: () async {
                HapticFeedback.lightImpact();
                final goal = int.tryParse(controller.text) ?? 0;
                if (goal > 0) {
                  await _saveGoal(goal);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }

  void _showCustomLogDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Log Custom Hydration', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount (mL)',
              border: OutlineInputBorder(),
              hintText: 'e.g. 350',
            ),
          ),
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
              onPressed: () async {
                HapticFeedback.lightImpact();
                final amount = int.tryParse(controller.text) ?? 0;
                if (amount > 0) {
                  final success = await ref.read(trackerProvider.notifier).addWater(amount);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Logged $amount mL of water!' : 'Failed to log water'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('LOG'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logWater(int amount) async {
    HapticFeedback.lightImpact();
    final success = await ref.read(trackerProvider.notifier).addWater(amount);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Logged $amount mL of water!' : 'Failed to log water'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackerState = ref.watch(trackerProvider);
    final todayAmount = trackerState.todayWaterAmount;
    final progress = (todayAmount / _waterGoal).clamp(0.0, 1.0);

    // Group logs by date
    final Map<String, List<WaterLog>> groupedLogs = {};
    for (var log in trackerState.waterLogs) {
      final dateStr = DateFormat('yyyy-MM-dd').format(log.loggedAt.toLocal());
      if (groupedLogs.containsKey(dateStr)) {
        groupedLogs[dateStr]!.add(log);
      } else {
        groupedLogs[dateStr] = [log];
      }
    }
    final sortedKeys = groupedLogs.keys.toList()..sort((a, b) => b.compareTo(a));

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
          'Hydration Tracker',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
        ),
      ),
      body: trackerState.isLoading || _isLoadingGoal
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 1. PROGRESS CARD
                  CustomCard(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 220,
                                height: 220,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 16,
                                  backgroundColor: Colors.grey.shade100,
                                  color: AppColors.waterAccent,
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(PhosphorIconsFill.drop, color: AppColors.waterAccent, size: 36),
                                  const SizedBox(height: 12),
                                  RichText(
                                    text: TextSpan(
                                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                            fontSize: 38,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.textPrimary,
                                            height: 1.1,
                                          ),
                                      children: [
                                        TextSpan(text: '$todayAmount'),
                                        const TextSpan(
                                          text: ' mL',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.neutral),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'Daily Goal: $_waterGoal mL',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildProgressBadge(progress),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. QUICK ADD BUTTONS
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('QUICK LOG WATER', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildQuickAddButton(250, 'Glass'),
                            _buildQuickAddButton(500, 'Small Bottle'),
                            _buildQuickAddButton(750, 'Large Bottle'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                text: 'LOG CUSTOM AMOUNT',
                                height: 42,
                                onPressed: _showCustomLogDialog,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: const Icon(PhosphorIconsRegular.gear, color: AppColors.secondary),
                                onPressed: _showSetGoalDialog,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2.5 SMART REMINDERS
                  CustomCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SMART HYDRATION REMINDERS',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Remind me to drink water every 2 hours',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          activeTrackColor: AppColors.waterAccent,
                          value: _remindersEnabled,
                          onChanged: _toggleReminders,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. HYDRATION HISTORY
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hydration History',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (sortedKeys.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('No water logs found.', style: TextStyle(color: AppColors.neutral))))
                  else ...[
                    Column(
                      children: List.generate(sortedKeys.length, (index) {
                        final dateStr = sortedKeys[index];
                        final logs = groupedLogs[dateStr]!;
                        logs.sort((a, b) => b.loggedAt.compareTo(a.loggedAt)); // newest first

                        String headerTitle = dateStr;
                        try {
                          final parsedDate = DateFormat('yyyy-MM-dd').parse(dateStr);
                          if (dateStr == DateFormat('yyyy-MM-dd').format(DateTime.now())) {
                            headerTitle = 'Today';
                          } else if (dateStr == DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)))) {
                            headerTitle = 'Yesterday';
                          } else {
                            headerTitle = DateFormat('EEEE, MMM d').format(parsedDate);
                          }
                        } catch (_) {}

                        final int totalForDay = logs.fold<int>(0, (sum, log) => sum + log.amount);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    headerTitle,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.neutral),
                                  ),
                                  Text(
                                    '$totalForDay mL',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.waterAccent),
                                  ),
                                ],
                              ),
                            ),
                            ...logs.map((log) {
                              final timeStr = DateFormat('h:mm a').format(log.loggedAt.toLocal());
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: CustomCard(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.waterAccent.withOpacity(0.08),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(PhosphorIconsFill.drop, color: AppColors.waterAccent, size: 18),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '${log.amount} mL',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        timeStr,
                                        style: const TextStyle(color: AppColors.neutral, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 8),
                          ],
                        );
                      }),
                    ),
                    if (trackerState.isLoadingMore) ...[
                      const SizedBox(height: 16),
                      const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildQuickAddButton(int amount, String label) {
    return GestureDetector(
      onTap: () => _logWater(amount),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.27,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            const Icon(PhosphorIconsFill.drop, color: AppColors.waterAccent, size: 24),
            const SizedBox(height: 6),
            Text(
              '+$amount mL',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.secondary),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.neutral),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBadge(double pct) {
    final status = pct >= 1.0 ? 'FULLY HYDRATED' : pct >= 0.5 ? 'HYDRATED' : 'DEHYDRATED';
    final dotColor = pct >= 1.0 ? AppColors.waterAccent : pct >= 0.5 ? AppColors.success : Colors.orange;
    final bgColor = pct >= 1.0 ? const Color(0xFFEFF6FF) : pct >= 0.5 ? const Color(0xFFE6FDF4) : const Color(0xFFFFF7ED);

    return StatusBadge(
      text: status,
      dotColor: dotColor,
      backgroundColor: bgColor,
      textColor: dotColor,
    );
  }
}
