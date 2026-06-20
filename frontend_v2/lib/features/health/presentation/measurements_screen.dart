import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/health_provider.dart';
import '../../../core/models/tracker_models.dart';

class MeasurementsScreen extends ConsumerStatefulWidget {
  const MeasurementsScreen({super.key});

  @override
  ConsumerState<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends ConsumerState<MeasurementsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipsController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _bodyFatController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipsController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll * 0.8) {
      ref.read(healthProvider.notifier).fetchMoreMeasurements();
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.secondary,
              onSurface: AppColors.secondary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();

    final weight = double.tryParse(_weightController.text.trim());
    final height = double.tryParse(_heightController.text.trim());
    final bodyFat = double.tryParse(_bodyFatController.text.trim());
    final chest = double.tryParse(_chestController.text.trim());
    final waist = double.tryParse(_waistController.text.trim());
    final hips = double.tryParse(_hipsController.text.trim());

    if (weight == null && height == null && bodyFat == null && chest == null && waist == null && hips == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one measurement'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ref.read(healthProvider.notifier).addMeasurement(
          weight: weight,
          height: height,
          bodyFatPercent: bodyFat,
          chest: chest,
          waist: waist,
          hips: hips,
          loggedAt: _selectedDate,
        );

    if (mounted) {
      if (success) {
        _weightController.clear();
        _heightController.clear();
        _bodyFatController.clear();
        _chestController.clear();
        _waistController.clear();
        _hipsController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Measurements logged successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        final stateError = ref.read(healthProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(stateError ?? 'Failed to log measurements'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Log', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this measurements entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.neutral)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              HapticFeedback.lightImpact();
              final success = await ref.read(healthProvider.notifier).deleteMeasurement(id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Log deleted successfully' : 'Failed to delete log'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final healthState = ref.watch(healthProvider);

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
          'Body Measurements',
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
      body: healthState.isLoading && healthState.measurementLogs.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(healthProvider.notifier).fetchAllHealthData();
              },
              color: AppColors.primary,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form Card
                    CustomCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LOG BODY METRICS',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppColors.stepsAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            // Date selector
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                minimumSize: const Size(double.infinity, 44),
                              ),
                              onPressed: _pickDate,
                              icon: const Icon(PhosphorIconsRegular.calendar, size: 18, color: AppColors.textPrimary),
                              label: Text(
                                DateFormat('MMMM d, yyyy').format(_selectedDate),
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Weight & Height fields
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _weightController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'Weight (kg)',
                                      hintText: 'e.g. 70.5',
                                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _heightController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'Height (cm)',
                                      hintText: 'e.g. 175',
                                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Body Fat & Chest fields
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _bodyFatController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'Body Fat (%)',
                                      hintText: 'e.g. 18.5',
                                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _chestController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'Chest (cm)',
                                      hintText: 'e.g. 96',
                                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Waist & Hips fields
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _waistController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'Waist (cm)',
                                      hintText: 'e.g. 84',
                                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _hipsController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'Hips (cm)',
                                      hintText: 'e.g. 98',
                                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            PrimaryButton(
                              text: 'SAVE MEASUREMENTS',
                              onPressed: _submitForm,
                              isLoading: healthState.isLoading,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Log History Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LOG HISTORY',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.textSecondary,
                                letterSpacing: 1.2,
                              ),
                        ),
                        if (healthState.measurementLogs.isNotEmpty)
                          Text(
                            '${healthState.measurementLogs.length} entries',
                            style: const TextStyle(color: AppColors.neutral, fontSize: 12),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // List Logs
                    if (healthState.measurementLogs.isEmpty)
                      const CustomCard(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(PhosphorIconsRegular.ruler, size: 36, color: AppColors.neutral),
                                SizedBox(height: 8),
                                Text(
                                  'No measurements logged yet',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else ...[
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: healthState.measurementLogs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final log = healthState.measurementLogs[index];
                          return _buildMeasurementLogCard(log);
                        },
                      ),
                      if (healthState.isLoadingMore) ...[
                        const SizedBox(height: 16),
                        const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMeasurementLogCard(MeasurementLog log) {
    final dateStr = DateFormat('MMM d, yyyy').format(log.loggedAt.toLocal());

    return CustomCard(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    if (log.bmi != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'BMI: ${log.bmi!.toStringAsFixed(1)}',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 16),
                
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (log.weight != null)
                      _buildMetricTile(PhosphorIconsRegular.scales, 'Weight', '${log.weight} kg'),
                    if (log.height != null)
                      _buildMetricTile(PhosphorIconsRegular.textT, 'Height', '${log.height} cm'),
                    if (log.bodyFatPercent != null)
                      _buildMetricTile(PhosphorIconsRegular.percent, 'Body Fat', '${log.bodyFatPercent}%'),
                    if (log.chest != null)
                      _buildMetricTile(PhosphorIconsRegular.selectionBackground, 'Chest', '${log.chest} cm'),
                    if (log.waist != null)
                      _buildMetricTile(PhosphorIconsRegular.layout, 'Waist', '${log.waist} cm'),
                    if (log.hips != null)
                      _buildMetricTile(PhosphorIconsRegular.circlesThree, 'Hips', '${log.hips} cm'),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: const Icon(PhosphorIconsRegular.trash, color: AppColors.neutral, size: 18),
              onPressed: () => _confirmDelete(log.id),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.neutral),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 10),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
            ),
          ],
        ),
      ],
    );
  }
}
