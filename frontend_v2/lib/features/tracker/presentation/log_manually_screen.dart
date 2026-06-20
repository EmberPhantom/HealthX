import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/meal_provider.dart';

class LogManuallyScreen extends ConsumerStatefulWidget {
  final String? initialMeal;
  const LogManuallyScreen({super.key, this.initialMeal});

  @override
  ConsumerState<LogManuallyScreen> createState() => _LogManuallyScreenState();
}

class _LogManuallyScreenState extends ConsumerState<LogManuallyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _proteinController = TextEditingController(text: '0');
  final _carbsController = TextEditingController(text: '0');
  final _fatController = TextEditingController(text: '0');
  
  String _selectedMealType = 'Breakfast';
  File? _pickedImage;
  final List<String> _ingredients = [];
  final _ingredientNameController = TextEditingController();
  final _ingredientQtyController = TextEditingController();

  int _protein = 0;
  int _carbs = 0;
  int _fat = 0;

  int get _calculatedCalories => (_protein * 4) + (_fat * 9) + (_carbs * 4);

  @override
  void initState() {
    super.initState();
    if (widget.initialMeal != null) {
      final canonicalMeal = widget.initialMeal!.toLowerCase();
      if (canonicalMeal == 'breakfast') _selectedMealType = 'Breakfast';
      if (canonicalMeal == 'lunch') _selectedMealType = 'Lunch';
      if (canonicalMeal == 'dinner') _selectedMealType = 'Dinner';
      if (canonicalMeal == 'snack' || canonicalMeal == 'other') _selectedMealType = 'Snack';
    }

    _proteinController.addListener(_updateMacros);
    _carbsController.addListener(_updateMacros);
    _fatController.addListener(_updateMacros);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _ingredientNameController.dispose();
    _ingredientQtyController.dispose();
    super.dispose();
  }

  void _updateMacros() {
    setState(() {
      _protein = int.tryParse(_proteinController.text.trim()) ?? 0;
      _carbs = int.tryParse(_carbsController.text.trim()) ?? 0;
      _fat = int.tryParse(_fatController.text.trim()) ?? 0;
    });
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null && mounted) {
        setState(() {
          _pickedImage = File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _addIngredient() {
    final name = _ingredientNameController.text.trim();
    final qty = _ingredientQtyController.text.trim();

    if (name.isEmpty) return;

    setState(() {
      if (qty.isNotEmpty) {
        _ingredients.add('$name - $qty');
      } else {
        _ingredients.add(name);
      }
      _ingredientNameController.clear();
      _ingredientQtyController.clear();
    });
    Navigator.pop(context);
  }

  void _showAddIngredientDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Add Ingredient', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _ingredientNameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Ingredient Name',
                  hintText: 'e.g. Tomato',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ingredientQtyController,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: 'Quantity / Portion (Optional)',
                  hintText: 'e.g. 1 medium, 50g',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.neutral)),
            ),
            TextButton(
              onPressed: _addIngredient,
              child: const Text('Add', style: TextStyle(color: AppColors.stepsAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _titleController.text.trim();

    HapticFeedback.mediumImpact();
    final warning = await ref.read(mealProvider.notifier).addMealLog(
          name,
          _selectedMealType,
          _calculatedCalories,
          _protein,
          _carbs,
          _fat,
          ingredients: _ingredients,
        );

    if (!mounted) return;

    final hasError = ref.read(mealProvider).error != null;
    if (!hasError) {
      Navigator.pop(context);
      if (warning != null && warning.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_outlined, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(warning, style: const TextStyle(fontSize: 13, color: Colors.white))),
              ],
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to log meal. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mealProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Log Meal Manually',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MEAL DETAILS',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Food Name / Title',
                        prefixIcon: Icon(PhosphorIconsRegular.bowlFood, color: AppColors.textSecondary),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter meal title' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedMealType,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Meal Type',
                        prefixIcon: Icon(PhosphorIconsRegular.clock, color: AppColors.textSecondary),
                        border: OutlineInputBorder(),
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
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Macro and Calorie Section Card
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'NUTRITION & MACROS',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10, letterSpacing: 0.5),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$_calculatedCalories kcal',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.stepsAccent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _proteinController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              labelText: 'Protein (g)',
                              border: OutlineInputBorder(),
                            ),
                            onTap: () {
                              if (_proteinController.text == '0') _proteinController.clear();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _carbsController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              labelText: 'Carbs (g)',
                              border: OutlineInputBorder(),
                            ),
                            onTap: () {
                              if (_carbsController.text == '0') _carbsController.clear();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _fatController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              labelText: 'Fat (g)',
                              border: OutlineInputBorder(),
                            ),
                            onTap: () {
                              if (_fatController.text == '0') _fatController.clear();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Ingredients Card
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'INGREDIENTS (${_ingredients.length})',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10, letterSpacing: 0.5),
                        ),
                        GestureDetector(
                          onTap: _showAddIngredientDialog,
                          child: const Text(
                            '+ ADD',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.stepsAccent, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    if (_ingredients.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No ingredients added. Click add to detail the meal.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _ingredients.length,
                        itemBuilder: (context, idx) {
                          final item = _ingredients[idx];
                          final parts = item.split(' - ');
                          final name = parts[0];
                          final qty = parts.length > 1 ? parts[1] : '';

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: qty.isNotEmpty ? Text(qty, style: const TextStyle(fontSize: 11)) : null,
                            trailing: IconButton(
                              icon: const Icon(PhosphorIconsRegular.trash, color: AppColors.error, size: 16),
                              onPressed: () => setState(() => _ingredients.removeAt(idx)),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Optional Meal Photo Card
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MEAL PHOTO (OPTIONAL)',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: _pickedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_pickedImage!, width: double.infinity, height: 150, fit: BoxFit.cover),
                              )
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(PhosphorIconsRegular.image, size: 32, color: AppColors.neutral),
                                    SizedBox(height: 8),
                                    Text('Upload or Take Photo', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              PrimaryButton(
                text: 'LOG MEAL INTAKE',
                isLoading: state.isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
