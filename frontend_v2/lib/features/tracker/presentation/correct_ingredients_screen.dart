import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';

class CorrectIngredientsScreen extends StatefulWidget {
  final String meal;
  final String? imagePath;
  final String? mealDescription;
  final bool isTextBased;
  final Map<String, dynamic> nutritionData;

  const CorrectIngredientsScreen({
    super.key,
    required this.meal,
    this.imagePath,
    this.mealDescription,
    this.isTextBased = false,
    required this.nutritionData,
  });

  @override
  State<CorrectIngredientsScreen> createState() => _CorrectIngredientsScreenState();
}

class _CorrectIngredientsScreenState extends State<CorrectIngredientsScreen> {
  late String _foodName;
  final List<String> _ingredients = [];
  final _addNameController = TextEditingController();
  final _addQtyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _foodName = widget.nutritionData['foodName'] ?? widget.nutritionData['name'] ?? 'Identified Meal';
    
    final rawList = widget.nutritionData['ingredients'] as List?;
    if (rawList != null) {
      for (final item in rawList) {
        _ingredients.add(item.toString());
      }
    }
  }

  @override
  void dispose() {
    _addNameController.dispose();
    _addQtyController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final name = _addNameController.text.trim();
    final qty = _addQtyController.text.trim();

    if (name.isEmpty) return;

    setState(() {
      if (qty.isNotEmpty) {
        _ingredients.add('$name - $qty');
      } else {
        _ingredients.add(name);
      }
      _addNameController.clear();
      _addQtyController.clear();
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
                controller: _addNameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Ingredient Name',
                  hintText: 'e.g. Scrambled Eggs',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addQtyController,
                decoration: const InputDecoration(
                  labelText: 'Quantity / Portion (Optional)',
                  hintText: 'e.g. 2 large',
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

  void _onNext() {
    // Navigate to CountingCaloriesScreen
    final updatedData = Map<String, dynamic>.from(widget.nutritionData);
    updatedData['foodName'] = _foodName;
    updatedData['ingredients'] = _ingredients;

    context.pushReplacement('/tracker/counting-calories', extra: {
      'meal': widget.meal,
      'imagePath': widget.imagePath,
      'isTextBased': widget.isTextBased,
      'nutritionData': updatedData,
    });
  }

  @override
  Widget build(BuildContext context) {
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
          'Confirm Ingredients',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Original Prompt Card if text-based
            if (widget.isTextBased && widget.mealDescription != null) ...[
              CustomCard(
                backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR TEXT DESCRIPTION',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.neutral),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.mealDescription!,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Identified Food Title Card
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IDENTIFIED MEAL NAME',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _foodName,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (val) {
                      _foodName = val.trim();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ingredients List Card
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'INGREDIENTS LIST',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10, letterSpacing: 0.5),
                      ),
                      GestureDetector(
                        onTap: _showAddIngredientDialog,
                        child: const Text(
                          '+ ADD ITEM',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.stepsAccent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  if (_ingredients.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No ingredients list. Click add to add items.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _ingredients.length,
                      itemBuilder: (context, index) {
                        final item = _ingredients[index];
                        final parts = item.split(' - ');
                        final name = parts[0];
                        final qty = parts.length > 1 ? parts[1] : '';

                        return Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              subtitle: qty.isNotEmpty ? Text(qty, style: const TextStyle(fontSize: 11)) : null,
                              trailing: IconButton(
                                icon: const Icon(PhosphorIconsRegular.trash, color: AppColors.error, size: 16),
                                onPressed: () {
                                  setState(() {
                                    _ingredients.removeAt(index);
                                  });
                                },
                              ),
                            ),
                            if (index < _ingredients.length - 1)
                              const Divider(height: 1),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            PrimaryButton(
              text: 'CONFIRM & ANALYZE MACROS',
              onPressed: _onNext,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
