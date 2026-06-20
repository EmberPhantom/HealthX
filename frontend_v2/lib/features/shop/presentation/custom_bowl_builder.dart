import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/shop_provider.dart';

class IngredientItem {
  final String name;
  final double price;
  final int calories;
  final String emoji;

  const IngredientItem({
    required this.name,
    required this.price,
    required this.calories,
    required this.emoji,
  });
}

const List<IngredientItem> _bases = [
  IngredientItem(name: 'Brown Rice', price: 50.0, calories: 120, emoji: '🌾'),
  IngredientItem(name: 'Organic Quinoa', price: 80.0, calories: 150, emoji: '🥗'),
  IngredientItem(name: 'Mixed Salad Greens', price: 40.0, calories: 30, emoji: '🥬'),
  IngredientItem(name: 'Baby Spinach', price: 40.0, calories: 25, emoji: '🍃'),
];

const List<IngredientItem> _proteins = [
  IngredientItem(name: 'Grilled Chicken Breast', price: 120.0, calories: 180, emoji: '🍗'),
  IngredientItem(name: 'Organic Grilled Paneer', price: 100.0, calories: 150, emoji: '🧀'),
  IngredientItem(name: 'Herb Marinated Tofu', price: 90.0, calories: 130, emoji: '🍢'),
  IngredientItem(name: 'Soft Boiled Eggs', price: 60.0, calories: 140, emoji: '🥚'),
  IngredientItem(name: 'No Protein (Veggies Only)', price: 0.0, calories: 0, emoji: '🥗'),
];

const List<IngredientItem> _veggies = [
  IngredientItem(name: 'Steamed Broccoli', price: 30.0, calories: 25, emoji: '🥦'),
  IngredientItem(name: 'Button Mushrooms', price: 30.0, calories: 20, emoji: '🍄'),
  IngredientItem(name: 'Sliced Avocado', price: 60.0, calories: 80, emoji: '🥑'),
  IngredientItem(name: 'Cherry Tomatoes', price: 20.0, calories: 15, emoji: '🍅'),
  IngredientItem(name: 'Crisp Cucumber', price: 20.0, calories: 10, emoji: '🥒'),
  IngredientItem(name: 'Sweet Corn Kernels', price: 25.0, calories: 40, emoji: '🌽'),
];

const List<IngredientItem> _dressings = [
  IngredientItem(name: 'Organic Hummus', price: 30.0, calories: 70, emoji: '🍯'),
  IngredientItem(name: 'Sesame Tahini', price: 30.0, calories: 90, emoji: '🥣'),
  IngredientItem(name: 'Lemon Vinaigrette', price: 20.0, calories: 45, emoji: '🍋'),
  IngredientItem(name: 'Herbed Garlic Yogurt', price: 25.0, calories: 50, emoji: '🥛'),
];

class CustomBowlBuilderScreen extends ConsumerStatefulWidget {
  const CustomBowlBuilderScreen({super.key});

  @override
  ConsumerState<CustomBowlBuilderScreen> createState() => _CustomBowlBuilderScreenState();
}

class _CustomBowlBuilderScreenState extends ConsumerState<CustomBowlBuilderScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Selected choices
  IngredientItem? _selectedBase;
  IngredientItem? _selectedProtein;
  final List<IngredientItem> _selectedVeggies = [];
  final List<IngredientItem> _selectedDressings = [];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  double get _totalPrice {
    double base = 120.0; // Base bowl price
    if (_selectedBase != null) base += _selectedBase!.price;
    if (_selectedProtein != null) base += _selectedProtein!.price;
    for (var v in _selectedVeggies) {
      base += v.price;
    }
    for (var d in _selectedDressings) {
      base += d.price;
    }
    return base;
  }

  int get _totalCalories {
    int cals = 50; // base seasoning cals
    if (_selectedBase != null) cals += _selectedBase!.calories;
    if (_selectedProtein != null) cals += _selectedProtein!.calories;
    for (var v in _selectedVeggies) {
      cals += v.calories;
    }
    for (var d in _selectedDressings) {
      cals += d.calories;
    }
    return cals;
  }

  bool get _isVeg {
    if (_selectedProtein != null &&
        (_selectedProtein!.name.contains('Chicken') || _selectedProtein!.name.contains('Eggs'))) {
      return false;
    }
    return true;
  }

  String get _bowlDescription {
    final List<String> parts = [];
    if (_selectedBase != null) parts.add(_selectedBase!.name);
    if (_selectedProtein != null && _selectedProtein!.price > 0) parts.add(_selectedProtein!.name);
    if (_selectedVeggies.isNotEmpty) {
      parts.add('Veggies: ${_selectedVeggies.map((v) => v.name).join(', ')}');
    }
    if (_selectedDressings.isNotEmpty) {
      parts.add('Dressings: ${_selectedDressings.map((d) => d.name).join(', ')}');
    }
    return parts.join(' • ');
  }

  void _nextStep() {
    if (_currentStep == 0 && _selectedBase == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a base to continue.'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (_currentStep == 1 && _selectedProtein == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a protein option to continue.'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_currentStep < 3) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _addBowlToCart();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _addBowlToCart() {
    HapticFeedback.mediumImpact();
    ref.read(shopProvider.notifier).addCustomBowlToCart(
          name: 'Custom Salad Bowl',
          price: _totalPrice,
          calories: _totalCalories,
          description: _bowlDescription,
        );

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Custom Salad Bowl added to cart!'),
        backgroundColor: AppColors.success,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Build Your Bowl',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.border, width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (_currentStep > 0) ...[
                OutlinedButton(
                  onPressed: _prevStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: const BorderSide(color: AppColors.secondary, width: 1.5),
                  ),
                  child: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.secondary),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: PrimaryButton(
                  text: _currentStep == 3
                      ? 'ADD BOWL (₹${_totalPrice.toInt()})'
                      : 'NEXT: ${_getStepNextName(_currentStep + 1)}',
                  onPressed: _nextStep,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. Dynamic Summary Header Card
          _buildBowlPreviewCard(),

          // 2. Step Indicators
          _buildStepsIndicator(),

          // 3. Selection Content (PageView)
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() => _currentStep = page);
              },
              children: [
                _buildBaseSelection(),
                _buildProteinSelection(),
                _buildVeggiesSelection(),
                _buildDressingsSelection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStepNextName(int step) {
    switch (step) {
      case 1:
        return 'PROTEIN';
      case 2:
        return 'VEGGIES';
      case 3:
        return 'DRESSINGS';
      default:
        return 'DONE';
    }
  }

  Widget _buildBowlPreviewCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: CustomCard(
        backgroundColor: AppColors.secondary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'YOUR CUSTOM SALAD',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _isVeg ? Colors.green.shade900 : Colors.red.shade900,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _isVeg ? Colors.green.shade400 : Colors.red.shade400,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isVeg ? Icons.spa : Icons.restaurant,
                        color: Colors.white,
                        size: 10,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isVeg ? 'PURE VEG' : 'NON-VEG',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _bowlDescription.isEmpty ? 'Start assembling your salad bowl...' : _bowlDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(PhosphorIconsFill.fire, color: AppColors.primary, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$_totalCalories kcal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${_totalPrice.toInt()}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          final isCompleted = _currentStep > index;
          final isCurrent = _currentStep == index;
          final stepTitles = ['Base', 'Protein', 'Veggies', 'Dressing'];

          return Expanded(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.secondary
                        : (isCompleted ? AppColors.primary : Colors.grey.shade200),
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: AppColors.secondary)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isCurrent ? Colors.white : AppColors.neutral,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  stepTitles[index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: (isCurrent || isCompleted) ? FontWeight.bold : FontWeight.normal,
                    color: (isCurrent || isCompleted) ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                if (index < 3) ...[
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Divider(color: AppColors.border, thickness: 1.0),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  // --- Step 1: Base Selection ---
  Widget _buildBaseSelection() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _bases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final base = _bases[index];
        final isSelected = _selectedBase == base;

        return _buildSelectionCard(
          item: base,
          isSelected: isSelected,
          onTap: () {
            setState(() => _selectedBase = base);
          },
        );
      },
    );
  }

  // --- Step 2: Protein Selection ---
  Widget _buildProteinSelection() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _proteins.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final protein = _proteins[index];
        final isSelected = _selectedProtein == protein;

        return _buildSelectionCard(
          item: protein,
          isSelected: isSelected,
          onTap: () {
            setState(() => _selectedProtein = protein);
          },
        );
      },
    );
  }

  // --- Step 3: Veggies Selection ---
  Widget _buildVeggiesSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'SELECT UP TO 3 VEGGIES (${_selectedVeggies.length}/3)',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _veggies.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final veg = _veggies[index];
              final isSelected = _selectedVeggies.contains(veg);

              return _buildSelectionCard(
                item: veg,
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (isSelected) {
                      _selectedVeggies.remove(veg);
                    } else {
                      if (_selectedVeggies.length < 3) {
                        _selectedVeggies.add(veg);
                      } else {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('You can choose a maximum of 3 vegetables.'),
                            backgroundColor: AppColors.error,
                            duration: Duration(seconds: 1500),
                          ),
                        );
                      }
                    }
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Step 4: Dressings Selection ---
  Widget _buildDressingsSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'SELECT UP TO 2 DRESSINGS (${_selectedDressings.length}/2)',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _dressings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final dressing = _dressings[index];
              final isSelected = _selectedDressings.contains(dressing);

              return _buildSelectionCard(
                item: dressing,
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (isSelected) {
                      _selectedDressings.remove(dressing);
                    } else {
                      if (_selectedDressings.length < 2) {
                        _selectedDressings.add(dressing);
                      } else {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('You can choose a maximum of 2 dressing options.'),
                            backgroundColor: AppColors.error,
                            duration: Duration(seconds: 1500),
                          ),
                        );
                      }
                    }
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionCard({
    required IngredientItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.secondary : AppColors.border,
          width: isSelected ? 1.8 : 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Material(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.cardBackground,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Row(
                children: [
                  Text(item.emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.calories} kcal • +₹${item.price.toInt()}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.circle,
                    color: isSelected ? AppColors.secondary : AppColors.neutral,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
