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

class BloodGlucoseScreen extends ConsumerStatefulWidget {
  const BloodGlucoseScreen({super.key});

  @override
  ConsumerState<BloodGlucoseScreen> createState() => _BloodGlucoseScreenState();
}

class _BloodGlucoseScreenState extends ConsumerState<BloodGlucoseScreen> {
  final _levelController = TextEditingController();
  final _noteController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _readingType = 'random'; // fasting, postprandial, random

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _levelController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll * 0.8) {
      ref.read(trackerProvider.notifier).fetchMoreGlucose();
    }
  }

  Map<String, dynamic> _assessGlucose(int level, String type) {
    if (level <= 0) return {'status': 'UNKNOWN', 'color': AppColors.neutral, 'bg': Colors.grey.shade100};

    if (type.toLowerCase() == 'fasting') {
      if (level < 70) return {'status': 'LOW', 'color': AppColors.error, 'bg': const Color(0xFFFEF2F2)};
      if (level <= 100) return {'status': 'NORMAL', 'color': AppColors.success, 'bg': const Color(0xFFE6FDF4)};
      if (level <= 125) return {'status': 'PRE-DIABETIC', 'color': AppColors.warning, 'bg': const Color(0xFFFFF7ED)};
      return {'status': 'HIGH (DIABETIC)', 'color': AppColors.error, 'bg': const Color(0xFFFEF2F2)};
    } else {
      // Postprandial / Random
      if (level < 70) return {'status': 'LOW', 'color': AppColors.error, 'bg': const Color(0xFFFEF2F2)};
      if (level <= 140) return {'status': 'NORMAL', 'color': AppColors.success, 'bg': const Color(0xFFE6FDF4)};
      if (level <= 199) return {'status': 'PRE-DIABETIC', 'color': AppColors.warning, 'bg': const Color(0xFFFFF7ED)};
      return {'status': 'HIGH (DIABETIC)', 'color': AppColors.error, 'bg': const Color(0xFFFEF2F2)};
    }
  }

  Future<void> _logGlucose() async {
    final level = int.tryParse(_levelController.text) ?? 0;
    if (level <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid glucose level'), backgroundColor: Colors.orange),
      );
      return;
    }

    HapticFeedback.lightImpact();
    final note = _noteController.text.trim();
    final inlineComment = await ref.read(trackerProvider.notifier).addGlucose(
          level,
          _readingType,
          note.isNotEmpty ? note : null,
        );

    if (mounted) {
      _levelController.clear();
      _noteController.clear();

      if (inlineComment != null && inlineComment.isNotEmpty) {
        // AI inline suggestion — calm contextual chip, distinct from error states
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    inlineComment,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0D9488), // teal-600 — calm, non-alarming
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        final hasError = ref.read(trackerProvider).error != null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasError ? 'Failed to log glucose' : 'Glucose level logged!'),
            backgroundColor: hasError ? Colors.red : Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteLog(String id) async {
    HapticFeedback.heavyImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Log?'),
        content: const Text('Are you sure you want to delete this glucose reading?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.neutral)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await ref.read(trackerProvider.notifier).deleteGlucose(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Log deleted successfully' : 'Failed to delete log'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackerState = ref.watch(trackerProvider);
    final glucoseLogs = trackerState.glucoseLogs;

    // Filter logs for trend (last 7 logs chronologically)
    final List<GlucoseLog> chartLogs = List.from(glucoseLogs);
    chartLogs.sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
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
          'Blood Glucose',
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
      body: trackerState.isLoading && glucoseLogs.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TREND LINE CHART
                  if (chartLogs.isNotEmpty) ...[
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GLUCOSE TRENDS (mg/dL)', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10)),
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
                                        return LineTooltipItem(
                                          '${log.readingType.toUpperCase()}\n${spot.y.toInt()} mg/dL',
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
                                        final dateStr = DateFormat('dd/MM').format(chartLogs[index].loggedAt);
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          space: 8,
                                          child: Text(dateStr, style: const TextStyle(color: AppColors.neutral, fontSize: 10, fontWeight: FontWeight.bold)),
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
                                      return FlSpot(index.toDouble(), chartLogs[index].level.toDouble());
                                    }),
                                    isCurved: true,
                                    color: AppColors.glucoseAccent,
                                    barWidth: 4,
                                    dotData: const FlDotData(show: true),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: AppColors.glucoseAccent.withOpacity(0.08),
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

                  // 2. LOG NEW GLUCOSE
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ADD NEW READING', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _levelController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Glucose level (mg/dL)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(PhosphorIconsRegular.drop, color: AppColors.glucoseAccent),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _readingType,
                          decoration: const InputDecoration(
                            labelText: 'Reading Type',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'fasting', child: Text('Fasting (Empty Stomach)')),
                            DropdownMenuItem(value: 'postprandial', child: Text('Postprandial (After Meal)')),
                            DropdownMenuItem(value: 'random', child: Text('Random (Any Time)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _readingType = val);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _noteController,
                          decoration: const InputDecoration(
                            labelText: 'Notes / Symptoms (Optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(PhosphorIconsRegular.note),
                          ),
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(
                          text: 'SAVE GLUCOSE READING',
                          onPressed: _logGlucose,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. GLUCOSE HISTORY
                  Text(
                    'Glucose History',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  if (glucoseLogs.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('No glucose readings logged yet.', style: TextStyle(color: AppColors.neutral))))
                  else ...[
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: glucoseLogs.length,
                      itemBuilder: (context, index) {
                        final log = glucoseLogs[index];
                        final assessment = _assessGlucose(log.level, log.readingType);
                        final dateStr = DateFormat('EEEE, MMM d — h:mm a').format(log.loggedAt);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: CustomCard(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.glucoseAccent.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(PhosphorIconsFill.drop, color: AppColors.glucoseAccent, size: 22),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          RichText(
                                            text: TextSpan(
                                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                    color: AppColors.textPrimary,
                                                  ),
                                              children: [
                                                TextSpan(text: '${log.level}'),
                                                const TextSpan(
                                                  text: ' mg/dL',
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.neutral),
                                                ),
                                              ],
                                            ),
                                          ),
                                          StatusBadge(
                                            text: assessment['status'],
                                            dotColor: assessment['color'],
                                            backgroundColor: assessment['bg'],
                                            textColor: assessment['color'],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Type: ${log.readingType.toUpperCase()} • $dateStr',
                                        style: const TextStyle(color: AppColors.neutral, fontSize: 11),
                                      ),
                                      if (log.note != null && log.note!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Note: ${log.note}',
                                          style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontStyle: FontStyle.italic),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(PhosphorIconsRegular.trash, color: AppColors.error, size: 18),
                                  onPressed: () => _deleteLog(log.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
}
