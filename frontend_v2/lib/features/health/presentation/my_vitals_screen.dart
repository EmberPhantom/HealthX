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

class MyVitalsScreen extends ConsumerStatefulWidget {
  const MyVitalsScreen({super.key});

  @override
  ConsumerState<MyVitalsScreen> createState() => _MyVitalsScreenState();
}

class _MyVitalsScreenState extends ConsumerState<MyVitalsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bpController = TextEditingController();
  final _pulseController = TextEditingController();
  final _tempController = TextEditingController();
  final _weightController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _exerciseController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _bpController.dispose();
    _pulseController.dispose();
    _tempController.dispose();
    _weightController.dispose();
    _spo2Controller.dispose();
    _exerciseController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll * 0.8) {
      ref.read(healthProvider.notifier).fetchMoreVitals();
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

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final now = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final timeStr = DateFormat('hh:mm a').format(now);

    final bp = _bpController.text.trim().isNotEmpty ? _bpController.text.trim() : null;
    final pulse = int.tryParse(_pulseController.text.trim());
    final temp = double.tryParse(_tempController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());
    final spo2 = int.tryParse(_spo2Controller.text.trim());
    final exercise = int.tryParse(_exerciseController.text.trim());

    if (bp == null && pulse == null && temp == null && weight == null && spo2 == null && exercise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in at least one vital metric'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ref.read(healthProvider.notifier).addVitals(
          date: dateStr,
          time: timeStr,
          bp: bp,
          pulse: pulse,
          temperature: temp,
          weight: weight,
          spo2: spo2,
          exerciseMins: exercise,
        );

    if (mounted) {
      if (success) {
        _bpController.clear();
        _pulseController.clear();
        _tempController.clear();
        _weightController.clear();
        _spo2Controller.clear();
        _exerciseController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vitals logged successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        final stateError = ref.read(healthProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(stateError ?? 'Failed to log vitals'),
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
        content: const Text('Are you sure you want to delete this vitals entry?'),
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
              final success = await ref.read(healthProvider.notifier).deleteVitals(id);
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
          'My Vitals',
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
      body: healthState.isLoading && healthState.vitalsLogs.isEmpty
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
                    // Log Form Card
                    CustomCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LOG NEW VITALS',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppColors.vitalsAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            // Date & Time pickers
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.border),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: _pickDate,
                                    icon: const Icon(PhosphorIconsRegular.calendar, size: 18, color: AppColors.textPrimary),
                                    label: Text(
                                      DateFormat('MMM d, yyyy').format(_selectedDate),
                                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.border),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: _pickTime,
                                    icon: const Icon(PhosphorIconsRegular.clock, size: 18, color: AppColors.textPrimary),
                                    label: Text(
                                      _selectedTime.format(context),
                                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // BP & Pulse Fields
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _bpController,
                                    decoration: InputDecoration(
                                      labelText: 'Blood Pressure',
                                      hintText: 'e.g. 120/80',
                                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                    validator: (val) {
                                      if (val != null && val.isNotEmpty) {
                                        final parts = val.split('/');
                                        if (parts.length != 2 ||
                                            int.tryParse(parts[0]) == null ||
                                            int.tryParse(parts[1]) == null) {
                                          return 'Use format SYS/DIA';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _pulseController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: InputDecoration(
                                      labelText: 'Pulse (BPM)',
                                      hintText: 'e.g. 72',
                                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Temp & SpO2 Fields
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _tempController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'Temp (°F)',
                                      hintText: 'e.g. 98.6',
                                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _spo2Controller,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: InputDecoration(
                                      labelText: 'Oxygen SpO2 (%)',
                                      hintText: 'e.g. 98',
                                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Weight & Exercise Fields
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
                                    controller: _exerciseController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: InputDecoration(
                                      labelText: 'Exercise (mins)',
                                      hintText: 'e.g. 30',
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
                              text: 'SAVE VITALS LOG',
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
                        if (healthState.vitalsLogs.isNotEmpty)
                          Text(
                            '${healthState.vitalsLogs.length} entries',
                            style: const TextStyle(color: AppColors.neutral, fontSize: 12),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // List Logs
                    if (healthState.vitalsLogs.isEmpty)
                      const CustomCard(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(PhosphorIconsRegular.activity, size: 36, color: AppColors.neutral),
                                SizedBox(height: 8),
                                Text(
                                  'No vitals logs available yet',
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
                        itemCount: healthState.vitalsLogs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final log = healthState.vitalsLogs[index];
                          return _buildVitalLogCard(log);
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

  Widget _buildVitalLogCard(VitalsLog log) {
    // Determine BP status colors if available
    Widget? bpWidget;
    if (log.bp != null) {
      final parts = log.bp!.split('/');
      final sys = int.tryParse(parts[0]) ?? 120;
      final dia = int.tryParse(parts[1]) ?? 80;
      
      String bpStatus = 'Normal';
      Color bpColor = Colors.green;
      if (sys >= 140 || dia >= 90) {
        bpStatus = 'Hypertension';
        bpColor = AppColors.error;
      } else if (sys >= 120 || dia >= 80) {
        bpStatus = 'Pre-High';
        bpColor = AppColors.warning;
      }

      bpWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'BP: ',
                style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 13),
              ),
              Text(
                '${log.bp}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: bpColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  bpStatus,
                  style: TextStyle(color: bpColor, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      );
    }

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
                      '${log.date} at ${log.time}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 16),
                if (bpWidget != null) bpWidget,
                
                // Grid of metrics
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (log.pulse != null)
                      _buildMetricTile(PhosphorIconsRegular.heartbeat, 'Pulse', '${log.pulse} bpm'),
                    if (log.temperature != null)
                      _buildMetricTile(PhosphorIconsRegular.thermometerSimple, 'Temp', '${log.temperature}°F'),
                    if (log.weight != null)
                      _buildMetricTile(PhosphorIconsRegular.scales, 'Weight', '${log.weight} kg'),
                    if (log.spo2 != null)
                      _buildMetricTile(PhosphorIconsRegular.wind, 'SpO2', '${log.spo2}%'),
                    if (log.exerciseMins != null)
                      _buildMetricTile(PhosphorIconsRegular.barbell, 'Exercise', '${log.exerciseMins} min'),
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
