import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/tracker_provider.dart';

class TrackerScreen extends ConsumerStatefulWidget {
  const TrackerScreen({super.key});

  @override
  ConsumerState<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends ConsumerState<TrackerScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _calculateScore(int steps, int water, String sleepStr) {
    int score = 60; // baseline score
    score += (steps / 10000 * 15).clamp(0, 15).toInt();
    score += (water / 2500 * 15).clamp(0, 15).toInt();
    if (sleepStr != '0h 0m') {
      score += 10;
    }
    return score.clamp(0, 100);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('h:mm a').format(dt);
  }

  Future<void> _showStepsDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: ref.read(trackerProvider).todaySteps.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Log Today\'s Steps', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Steps',
              border: OutlineInputBorder(),
              hintText: 'e.g. 8000',
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
                final steps = int.tryParse(controller.text) ?? 0;
                if (steps >= 0) {
                  final success = await ref.read(trackerProvider.notifier).updateSteps(steps);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Steps updated successfully!' : 'Failed to update steps'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showHydrationDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Log Hydration (mL)', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [250, 500, 750, 1000].map((amount) {
                  return ChoiceChip(
                    label: Text('${amount}mL'),
                    selected: false,
                    onSelected: (_) async {
                      HapticFeedback.lightImpact();
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
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Custom Amount (mL)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. 350',
                ),
              ),
            ],
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

  Future<void> _showSleepDialog(BuildContext context, WidgetRef ref) async {
    DateTime bedtime = DateTime.now().subtract(const Duration(hours: 8));
    DateTime wakeTime = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Log Sleep Session', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Bedtime', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(DateFormat('yyyy-MM-dd hh:mm a').format(bedtime)),
                    trailing: const Icon(PhosphorIconsRegular.calendar),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: bedtime,
                        firstDate: DateTime.now().subtract(const Duration(days: 7)),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        if (!context.mounted) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(bedtime),
                        );
                        if (time != null) {
                          setState(() {
                            bedtime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                          });
                        }
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('Waketime', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(DateFormat('yyyy-MM-dd hh:mm a').format(wakeTime)),
                    trailing: const Icon(PhosphorIconsRegular.calendar),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: wakeTime,
                        firstDate: DateTime.now().subtract(const Duration(days: 7)),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        if (!context.mounted) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(wakeTime),
                        );
                        if (time != null) {
                          setState(() {
                            wakeTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                          });
                        }
                      }
                    },
                  ),
                ],
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
                    if (wakeTime.isAfter(bedtime)) {
                      final success = await ref.read(trackerProvider.notifier).addSleep(bedtime, wakeTime);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Sleep session logged!' : 'Failed to log sleep'),
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
                  },
                  child: const Text('LOG'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showGlucoseDialog(BuildContext context, WidgetRef ref) async {
    final levelController = TextEditingController();
    final noteController = TextEditingController();
    String readingType = 'random';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Log Blood Glucose', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: levelController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Glucose Level (mg/dL)',
                        border: OutlineInputBorder(),
                        hintText: 'e.g. 95',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: readingType,
                      decoration: const InputDecoration(
                        labelText: 'Reading Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'fasting', child: Text('Fasting')),
                        DropdownMenuItem(value: 'postprandial', child: Text('Postprandial')),
                        DropdownMenuItem(value: 'random', child: Text('Random')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            readingType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(),
                        hintText: 'e.g. felt slightly dizzy',
                      ),
                    ),
                  ],
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
                    final level = int.tryParse(levelController.text) ?? 0;
                    if (level > 0) {
                      final note = noteController.text.trim();
                      final success = await ref.read(trackerProvider.notifier).addGlucose(
                            level,
                            readingType,
                            note.isNotEmpty ? note : null,
                          );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Glucose level logged!' : 'Failed to log glucose'),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final trackerState = ref.watch(trackerProvider);

    final sleepLog = trackerState.lastSleep;
    String sleepDuration = '0h 0m';
    double sleepRatio = 0.0;
    if (sleepLog != null) {
      final diff = sleepLog.wakeTime.difference(sleepLog.bedtime);
      final hours = diff.inHours;
      final mins = diff.inMinutes % 60;
      sleepDuration = '${hours}h ${mins}m';
      sleepRatio = (diff.inMinutes / 480.0).clamp(0.0, 1.0); // 8 hours is target
    }

    final score = _calculateScore(trackerState.todaySteps, trackerState.todayWaterAmount, sleepDuration);
    final formattedDate = DateFormat('EEEE, MMM d').format(DateTime.now());

    // Calculate dynamic height for today's water mini-bar (max 50)
    final todayWaterHeight = (trackerState.todayWaterAmount / 2500.0 * 50.0).clamp(0.0, 50.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: trackerState.isLoading && trackerState.waterLogs.isEmpty && trackerState.sleepLogs.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(trackerProvider.notifier).fetchAllData();
              },
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Page Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Summary",
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$formattedDate • Focus: Recovery',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const StatusBadge(
                          text: 'OPTIMIZED',
                          dotColor: AppColors.primary,
                          backgroundColor: Color(0xFFFCFDF2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Daily Score Chart Card
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'DAILY SCORE',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              Text(
                                '$score%',
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Custom Line Chart
                          SizedBox(
                            height: 150,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: _LineChartPainter(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // X Axis Labels
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('W', style: TextStyle(fontSize: 12, color: AppColors.neutral, fontWeight: FontWeight.bold)),
                              Text('T', style: TextStyle(fontSize: 12, color: AppColors.neutral, fontWeight: FontWeight.bold)),
                              Text('F', style: TextStyle(fontSize: 12, color: AppColors.neutral, fontWeight: FontWeight.bold)),
                              Text('S', style: TextStyle(fontSize: 12, color: AppColors.neutral, fontWeight: FontWeight.bold)),
                              Text('S', style: TextStyle(fontSize: 12, color: AppColors.neutral, fontWeight: FontWeight.bold)),
                              Text('M', style: TextStyle(fontSize: 12, color: AppColors.neutral, fontWeight: FontWeight.bold)),
                              Text('T', style: TextStyle(fontSize: 12, color: AppColors.neutral, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Macros Card
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MACROS',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            textBaseline: TextBaseline.alphabetic,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            children: [
                              Text(
                                '2,140',
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 38,
                                    ),
                              ),
                              Text(
                                ' / 2500 kcal',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontSize: 14,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildMacroRow(
                            context: context,
                            label: 'PROTEIN',
                            current: 140,
                            target: 180,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(height: 16),
                          _buildMacroRow(
                            context: context,
                            label: 'CARBS',
                            current: 210,
                            target: 250,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(height: 16),
                          _buildMacroRow(
                            context: context,
                            label: 'FAT',
                            current: 55,
                            target: 70,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Grid of 4 Items (Steps, Sleep, Hydration, Glucose)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.9,
                      children: [
                        // Steps Card
                        GestureDetector(
                          onTap: () => _showStepsDialog(context, ref),
                          child: CustomCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('STEPS', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10)),
                                Center(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 70,
                                        height: 70,
                                        child: CircularProgressIndicator(
                                          value: (trackerState.todaySteps / 10000.0).clamp(0.0, 1.0),
                                          strokeWidth: 8,
                                          backgroundColor: Colors.grey.shade100,
                                          color: AppColors.primary,
                                          strokeCap: StrokeCap.round,
                                        ),
                                      ),
                                      const Icon(PhosphorIconsFill.footprints, color: AppColors.secondary, size: 20),
                                    ],
                                  ),
                                ),
                                Center(
                                  child: Text(
                                    NumberFormat('#,###').format(trackerState.todaySteps),
                                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Sleep Card
                        GestureDetector(
                          onTap: () => _showSleepDialog(context, ref),
                          child: CustomCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('SLEEP', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10)),
                                Center(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 70,
                                        height: 70,
                                        child: CircularProgressIndicator(
                                          value: sleepRatio,
                                          strokeWidth: 8,
                                          backgroundColor: Colors.grey.shade100,
                                          color: AppColors.secondary,
                                          strokeCap: StrokeCap.round,
                                        ),
                                      ),
                                      const Icon(PhosphorIconsFill.moon, color: AppColors.secondary, size: 20),
                                    ],
                                  ),
                                ),
                                Center(
                                  child: Text(
                                    sleepDuration,
                                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Hydration Card
                        GestureDetector(
                          onTap: () => _showHydrationDialog(context, ref),
                          child: CustomCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('HYDRATION', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _buildMiniBar(height: 50, color: AppColors.secondary),
                                    _buildMiniBar(height: 50, color: AppColors.secondary),
                                    _buildMiniBar(height: 50, color: AppColors.secondary),
                                    _buildMiniBar(height: 50, color: AppColors.secondary),
                                    _buildMiniBar(height: todayWaterHeight > 0 ? todayWaterHeight : 10, color: AppColors.primary),
                                    _buildMiniBar(height: 10, color: Colors.grey.shade200),
                                  ],
                                ),
                                Center(
                                  child: RichText(
                                    text: TextSpan(
                                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 22,
                                          ),
                                      children: [
                                        TextSpan(text: '${(trackerState.todayWaterAmount / 1000.0).toStringAsFixed(1)} '),
                                        TextSpan(
                                          text: 'Liters',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Glucose Card
                        CustomCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('GLUCOSE', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10)),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    textBaseline: TextBaseline.alphabetic,
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    children: [
                                      Text(
                                        '${trackerState.lastGlucose?.level ?? 95}',
                                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 24,
                                            ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'mg/dL',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontSize: 10,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    trackerState.lastGlucose != null
                                        ? 'Last: ${_timeAgo(trackerState.lastGlucose!.loggedAt)} ago'
                                        : 'No reading',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10),
                                  ),
                                ],
                              ),
                              PrimaryButton(
                                text: 'LOG READING',
                                height: 36,
                                onPressed: () => _showGlucoseDialog(context, ref),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMacroRow({
    required BuildContext context,
    required String label,
    required double current,
    required double target,
    required Color color,
  }) {
    final double percent = (current / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 11,
                    color: AppColors.textPrimary,
                  ),
            ),
            Text(
              '${current.toInt()}G / ${target.toInt()}G',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: Colors.grey.shade100,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBar({required double height, required Color color}) {
    return Container(
      width: 10,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill;

    final List<Offset> points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.16, size.height * 0.55),
      Offset(size.width * 0.33, size.height * 0.8),
      Offset(size.width * 0.5, size.height * 0.4),
      Offset(size.width * 0.66, size.height * 0.3),
      Offset(size.width * 0.83, size.height * 0.5),
      Offset(size.width, size.height * 0.2),
    ];

    final Path path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final double xc = (points[i].dx + points[i + 1].dx) / 2;
      final double yc = (points[i].dy + points[i + 1].dy) / 2;
      path.quadraticBezierTo(points[i].dx, points[i].dy, xc, yc);
    }
    path.lineTo(points.last.dx, points.last.dy);

    final Path fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    fillPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.primary.withValues(alpha: 0.3),
        AppColors.primary.withValues(alpha: 0.0),
      ],
    ).createShader(rect);

    final Paint gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const int gridRows = 3;
    for (int i = 1; i <= gridRows; i++) {
      final double y = size.height * (i / (gridRows + 1));
      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(Offset(startX, y), Offset(startX + 5, y), gridPaint);
        startX += 10;
      }
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final Paint dotPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;

    final Paint dotOutlinePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final Offset point in points) {
      canvas.drawCircle(point, 5, dotPaint);
      canvas.drawCircle(point, 5, dotOutlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
