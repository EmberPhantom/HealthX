import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../tracker/providers/tracker_provider.dart';
import '../../health/providers/health_provider.dart';
import '../../consults/providers/consults_provider.dart';
import '../../../core/models/tracker_models.dart';

class DiabeticCareScreen extends ConsumerStatefulWidget {
  const DiabeticCareScreen({super.key});

  @override
  ConsumerState<DiabeticCareScreen> createState() => _DiabeticCareScreenState();
}

class _DiabeticCareScreenState extends ConsumerState<DiabeticCareScreen> {
  static const List<_SpecItem> _specs = [
    _SpecItem('Diabetologist', PhosphorIconsRegular.heartbeat, Color(0xFFFFB3BA), Color(0xFFC62828)),
    _SpecItem('Endocrinologist', PhosphorIconsRegular.testTube, Color(0xFFE8BAFF), Color(0xFF6A1B9A)),
    _SpecItem('Cardiologist', PhosphorIconsRegular.heart, Color(0xFFFFB3D9), Color(0xFFAD1457)),
    _SpecItem('Nephrologist', PhosphorIconsRegular.drop, Color(0xFFBAFFCE), Color(0xFF1B5E20)),
    _SpecItem('General Physician', PhosphorIconsRegular.stethoscope, Color(0xFFBAFFEE), Color(0xFF1B7A5A)),
  ];

  @override
  Widget build(BuildContext context) {
    final trackerState = ref.watch(trackerProvider);
    final healthState = ref.watch(healthProvider);
    final consultsState = ref.watch(consultsProvider);

    final glucoseLogs = trackerState.glucoseLogs;
    final List<GlucoseLog> chartLogs = List.from(glucoseLogs);
    chartLogs.sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    if (chartLogs.length > 7) {
      chartLogs.removeRange(0, chartLogs.length - 7);
    }

    // Calculations
    double avgGlucose = 0.0;
    double estimatedHba1c = 0.0;
    if (glucoseLogs.isNotEmpty) {
      avgGlucose = glucoseLogs.map((l) => l.level).reduce((a, b) => a + b) / glucoseLogs.length;
      // HbA1c formula: (Average Blood Glucose + 46.7) / 28.7
      estimatedHba1c = (avgGlucose + 46.7) / 28.7;
    }

    // Filter upcoming appointments
    final upcomingAppointments = consultsState.appointments.where((a) {
      return a.appointmentDate.isAfter(DateTime.now()) && a.status.toLowerCase() != 'cancelled';
    }).toList();

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
          'Diabetes Care',
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
      body: trackerState.isLoading || healthState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(trackerProvider.notifier).fetchAllData();
                await ref.read(healthProvider.notifier).fetchAllHealthData();
                await ref.read(consultsProvider.notifier).refreshAll();
              },
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Sleek summary cards row
                    Row(
                      children: [
                        Expanded(
                          child: CustomCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(PhosphorIconsFill.drop, color: AppColors.glucoseAccent, size: 16),
                                    SizedBox(width: 6),
                                    Text('AVERAGE GLUCOSE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.neutral)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                RichText(
                                  text: TextSpan(
                                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.textPrimary,
                                        ),
                                    children: [
                                      TextSpan(text: avgGlucose > 0 ? avgGlucose.toStringAsFixed(0) : '--'),
                                      const TextSpan(
                                        text: ' mg/dL',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: AppColors.neutral),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(PhosphorIconsFill.chartLineUp, color: AppColors.sleepAccent, size: 16),
                                    SizedBox(width: 6),
                                    Text('ESTIMATED HBA1C', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.neutral)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                RichText(
                                  text: TextSpan(
                                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.textPrimary,
                                        ),
                                    children: [
                                      TextSpan(text: estimatedHba1c > 0 ? estimatedHba1c.toStringAsFixed(1) : '--'),
                                      const TextSpan(
                                        text: ' %',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: AppColors.neutral),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 2. Glucose Trend Line Chart
                    if (chartLogs.isNotEmpty) ...[
                      CustomCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BLOOD GLUCOSE TRENDS',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 160,
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
                                            child: Text(
                                              dateStr,
                                              style: const TextStyle(color: AppColors.neutral, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
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
                                        color: AppColors.glucoseAccent.withValues(alpha: 0.08),
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

                    // 3. Quick Actions Row
                    Text(
                      'TRACKERS & LOGS',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 1.0,
                            fontSize: 11,
                          ),
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.5,
                      children: [
                        _buildActionCard(
                          context,
                          'Log Glucose',
                          'Record blood sugar',
                          PhosphorIconsFill.drop,
                          AppColors.glucoseAccent,
                          () => context.push('/tracker/glucose'),
                        ),
                        _buildActionCard(
                          context,
                          'Log Insulin',
                          'Record active dose',
                          PhosphorIconsFill.needle,
                          AppColors.sleepAccent,
                          () => context.push('/health/insulin'),
                        ),
                        _buildActionCard(
                          context,
                          'My Vitals',
                          'Track bp, pulse',
                          PhosphorIconsFill.activity,
                          AppColors.vitalsAccent,
                          () => context.push('/health/vitals'),
                        ),
                        _buildActionCard(
                          context,
                          'Health Records',
                          'View medical reports',
                          PhosphorIconsFill.folder,
                          const Color(0xFF8B5CF6),
                          () => context.push('/health/records'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 4. Specialist Records Filters
                    Text(
                      'HEALTH RECORDS BY SPECIALIST',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 1.0,
                            fontSize: 11,
                          ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _specs.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 10),
                        itemBuilder: (ctx, i) {
                          final spec = _specs[i];
                          return _SpecChip(
                            spec: spec,
                            onTap: () => context.push('/health/records?specialist=${spec.name}'),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 5. Upcoming Appointments
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'UPCOMING APPOINTMENTS',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.textSecondary,
                                letterSpacing: 1.0,
                                fontSize: 11,
                              ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/consults/find'),
                          child: const Text(
                            'Book New',
                            style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (upcomingAppointments.isEmpty)
                      CustomCard(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        child: Column(
                          children: [
                            const Icon(PhosphorIconsRegular.calendarBlank, size: 36, color: AppColors.neutral),
                            const SizedBox(height: 12),
                            const Text(
                              'No upcoming appointments scheduled.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            PrimaryButton(
                              text: 'FIND A DIABETOLOGIST',
                              height: 40,
                              onPressed: () => context.push('/consults/list?specialty=Diabetologist'),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: upcomingAppointments.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (ctx, idx) {
                          final appt = upcomingAppointments[idx];
                          final dateStr = DateFormat('EEEE, MMM d').format(appt.appointmentDate);
                          return CustomCard(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(PhosphorIconsFill.stethoscope, color: AppColors.secondary, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appt.doctor?.name ?? 'Specialist',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$dateStr • ${appt.timeSlot}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 4),
                                      StatusBadge(
                                        text: appt.status,
                                        dotColor: appt.status.toLowerCase() == 'confirmed' ? AppColors.success : AppColors.warning,
                                        backgroundColor: appt.status.toLowerCase() == 'confirmed'
                                            ? AppColors.success.withValues(alpha: 0.1)
                                            : AppColors.warning.withValues(alpha: 0.1),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(PhosphorIconsRegular.chatsCircle, color: AppColors.secondary),
                                  onPressed: () => context.push('/consults/appointment/${appt.id}/chat'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String label,
    String subtitle,
    IconData icon,
    Color accentColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 18),
            ),
            const Spacer(),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecItem {
  final String name;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  const _SpecItem(this.name, this.icon, this.bgColor, this.iconColor);
}

class _SpecChip extends StatelessWidget {
  final _SpecItem spec;
  final VoidCallback onTap;

  const _SpecChip({
    required this.spec,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: spec.bgColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: spec.iconColor.withValues(alpha: 0.25), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: spec.bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(spec.icon, color: spec.iconColor, size: 18),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  spec.name.replaceAll(' ', '\n'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
