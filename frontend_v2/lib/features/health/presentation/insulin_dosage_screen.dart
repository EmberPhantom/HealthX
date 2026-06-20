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

class InsulinDosageScreen extends ConsumerStatefulWidget {
  const InsulinDosageScreen({super.key});

  @override
  ConsumerState<InsulinDosageScreen> createState() => _InsulinDosageScreenState();
}

class _InsulinDosageScreenState extends ConsumerState<InsulinDosageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _doseController = TextEditingController();
  final _noteController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _selectedInsulinType = 'Rapid-acting';
  String _selectedInjectionSite = 'Abdomen';
  String _selectedMealContext = 'Fasting';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final List<String> _insulinTypes = [
    'Rapid-acting',
    'Short-acting',
    'Intermediate-acting',
    'Long-acting',
    'Premixed'
  ];

  final List<String> _injectionSites = [
    'Abdomen',
    'Thigh',
    'Upper Arm',
    'Buttocks'
  ];

  final List<String> _mealContexts = [
    'Fasting',
    'Before Breakfast',
    'After Breakfast',
    'Before Lunch',
    'After Lunch',
    'Before Dinner',
    'After Dinner',
    'Bedtime',
    'Random'
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _doseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll * 0.8) {
      ref.read(healthProvider.notifier).fetchMoreInsulin();
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

    final dose = int.tryParse(_doseController.text.trim()) ?? 0;
    if (dose <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid dose greater than 0'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final loggedAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final note = _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null;

    final success = await ref.read(healthProvider.notifier).addInsulin(
          dose: dose,
          insulinType: _selectedInsulinType,
          injectionSite: _selectedInjectionSite,
          mealContext: _selectedMealContext,
          note: note,
          loggedAt: loggedAt,
        );

    if (mounted) {
      if (success) {
        _doseController.clear();
        _noteController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insulin dosage logged successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        final stateError = ref.read(healthProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(stateError ?? 'Failed to log insulin dosage'),
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
        content: const Text('Are you sure you want to delete this insulin dosage entry?'),
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
              final success = await ref.read(healthProvider.notifier).deleteInsulin(id);
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
          'Insulin Dosage',
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
      body: healthState.isLoading && healthState.insulinLogs.isEmpty
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
                              'LOG INSULIN DOSE',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppColors.sleepAccent,
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

                            // Dosage textfield
                            TextFormField(
                              controller: _doseController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                labelText: 'Dose Amount (Units)',
                                hintText: 'e.g. 10',
                                labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Please enter dose units';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Insulin Type Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedInsulinType,
                              decoration: InputDecoration(
                                labelText: 'Insulin Type',
                                labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              items: _insulinTypes.map((type) {
                                return DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontSize: 14)));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedInsulinType = val);
                              },
                            ),
                            const SizedBox(height: 12),

                            // Injection Site Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedInjectionSite,
                              decoration: InputDecoration(
                                labelText: 'Injection Site',
                                labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              items: _injectionSites.map((site) {
                                return DropdownMenuItem(value: site, child: Text(site, style: const TextStyle(fontSize: 14)));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedInjectionSite = val);
                              },
                            ),
                            const SizedBox(height: 12),

                            // Meal Context Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedMealContext,
                              decoration: InputDecoration(
                                labelText: 'Meal Context',
                                labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              items: _mealContexts.map((contextVal) {
                                return DropdownMenuItem(value: contextVal, child: Text(contextVal, style: const TextStyle(fontSize: 14)));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedMealContext = val);
                              },
                            ),
                            const SizedBox(height: 12),

                            // Note Field
                            TextFormField(
                              controller: _noteController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: 'Note (Optional)',
                                hintText: 'e.g. Abdomen - left quadrant',
                                labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                            const SizedBox(height: 16),

                            PrimaryButton(
                              text: 'SAVE INSULIN LOG',
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
                        if (healthState.insulinLogs.isNotEmpty)
                          Text(
                            '${healthState.insulinLogs.length} entries',
                            style: const TextStyle(color: AppColors.neutral, fontSize: 12),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // List Logs
                    if (healthState.insulinLogs.isEmpty)
                      const CustomCard(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(PhosphorIconsRegular.needle, size: 36, color: AppColors.neutral),
                                SizedBox(height: 8),
                                Text(
                                  'No insulin doses logged yet',
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
                        itemCount: healthState.insulinLogs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final log = healthState.insulinLogs[index];
                          return _buildInsulinLogCard(log);
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

  Widget _buildInsulinLogCard(InsulinLog log) {
    final dateTimeStr = DateFormat('MMM d, yyyy h:mm a').format(log.loggedAt.toLocal());

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
                      dateTimeStr,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.sleepAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${log.dose} Units',
                        style: const TextStyle(color: AppColors.sleepAccent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildMetricTile(PhosphorIconsRegular.activity, 'Type', log.insulinType),
                    _buildMetricTile(PhosphorIconsRegular.needle, 'Site', log.injectionSite),
                    _buildMetricTile(PhosphorIconsRegular.cookie, 'Context', log.mealContext),
                  ],
                ),
                if (log.note != null && log.note!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.note!,
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textPrimary),
                    ),
                  ),
                ],
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
