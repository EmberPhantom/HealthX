import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/meal_provider.dart';

class LogMealSheet extends ConsumerStatefulWidget {
  const LogMealSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LogMealSheet(),
    );
  }

  @override
  ConsumerState<LogMealSheet> createState() => _LogMealSheetState();
}

class _LogMealSheetState extends ConsumerState<LogMealSheet> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  String _selectedMealType = 'Breakfast';

  @override
  void dispose() {
    _foodNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _foodNameController.text.trim();
    final calories = int.parse(_caloriesController.text.trim());
    final protein = int.parse(_proteinController.text.trim());
    final carbs = int.parse(_carbsController.text.trim());
    final fat = int.parse(_fatController.text.trim());

    HapticFeedback.mediumImpact();
    final warning = await ref.read(mealProvider.notifier).addMealLog(
          name,
          _selectedMealType,
          calories,
          protein,
          carbs,
          fat,
        );

    if (!mounted) return;

    final hasError = ref.read(mealProvider).error != null;
    if (hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to log meal. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Close sheet first, then show feedback
    Navigator.pop(context);

    if (warning != null && warning.isNotEmpty) {
      // AI meal warning — amber chip, distinct from success/error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_outlined, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(warning, style: const TextStyle(fontSize: 13))),
            ],
          ),
          backgroundColor: const Color(0xFFB45309), // amber-700 — noticeable but calm
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name logged successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mealProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pull bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LOG NEW MEAL',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.x),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppColors.border),
              const SizedBox(height: 16),

              // Food Name
              TextFormField(
                controller: _foodNameController,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Food Name / Description',
                  prefixIcon: Icon(PhosphorIconsRegular.bowlFood, color: AppColors.textSecondary),
                  border: const OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter food description' : null,
              ),
              const SizedBox(height: 16),

              // Meal Type Selector
              DropdownButtonFormField<String>(
                value: _selectedMealType,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Meal Type',
                  prefixIcon: Icon(PhosphorIconsRegular.clock, color: AppColors.textSecondary),
                  border: const OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Breakfast', child: Text('Breakfast')),
                  DropdownMenuItem(value: 'Lunch', child: Text('Lunch')),
                  DropdownMenuItem(value: 'Dinner', child: Text('Dinner')),
                  DropdownMenuItem(value: 'Snack', child: Text('Snack / Other')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedMealType = val);
                  }
                },
              ),
              const SizedBox(height: 20),

              // Calories Field
              TextFormField(
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Calories (kcal)',
                  prefixIcon: Icon(PhosphorIconsRegular.fire, color: AppColors.textSecondary),
                  border: const OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Macro Splits (Protein, Carbs, Fat)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _proteinController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Protein (g)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _carbsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Carbs (g)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _fatController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Fat (g)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit Button
              state.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : PrimaryButton(
                      text: 'LOG MEAL INTAKE',
                      onPressed: _submit,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
