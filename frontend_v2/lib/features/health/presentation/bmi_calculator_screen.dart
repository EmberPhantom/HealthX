import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/health_provider.dart';

class BmiCalculatorScreen extends ConsumerStatefulWidget {
  const BmiCalculatorScreen({super.key});

  @override
  ConsumerState<BmiCalculatorScreen> createState() => _BmiCalculatorScreenState();
}

class _BmiCalculatorScreenState extends ConsumerState<BmiCalculatorScreen> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  double _bmi = 0.0;
  String _category = 'Enter details';
  Color _categoryColor = AppColors.neutral;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _prefillFields());
  }

  void _prefillFields() {
    // 1. Try from user profile onboarding
    final user = ref.read(authProvider).user;
    double? initialHeight = user?.height;
    double? initialWeight = user?.weight;

    // 2. Try from latest measurement logs
    final logs = ref.read(healthProvider).measurementLogs;
    if (logs.isNotEmpty) {
      final latest = logs.first;
      initialHeight ??= latest.height;
      initialWeight ??= latest.weight;
    }

    if (initialHeight != null) {
      _heightController.text = initialHeight.toString();
    }
    if (initialWeight != null) {
      _weightController.text = initialWeight.toString();
    }

    if (initialHeight != null && initialWeight != null) {
      _calculateBmi();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _calculateBmi() {
    final weight = double.tryParse(_weightController.text.trim()) ?? 0.0;
    final height = double.tryParse(_heightController.text.trim()) ?? 0.0;

    if (weight > 0 && height > 0) {
      // height is in cm
      final heightInM = height / 100.0;
      final calculated = weight / (heightInM * heightInM);
      setState(() {
        _bmi = calculated;
        _evaluateCategory();
      });
    } else {
      setState(() {
        _bmi = 0.0;
        _category = 'Enter details';
        _categoryColor = AppColors.neutral;
      });
    }
  }

  void _evaluateCategory() {
    if (_bmi < 18.5) {
      _category = 'Underweight';
      _categoryColor = const Color(0xFF3B82F6); // Blue
    } else if (_bmi >= 18.5 && _bmi < 25.0) {
      _category = 'Normal Weight';
      _categoryColor = const Color(0xFF10B981); // Green
    } else if (_bmi >= 25.0 && _bmi < 30.0) {
      _category = 'Overweight';
      _categoryColor = const Color(0xFFF59E0B); // Amber
    } else {
      _category = 'Obese';
      _categoryColor = const Color(0xFFEF4444); // Red
    }
  }

  Future<void> _logToMetrics() async {
    final weight = double.tryParse(_weightController.text.trim()) ?? 0.0;
    final height = double.tryParse(_heightController.text.trim()) ?? 0.0;

    if (weight <= 0 || height <= 0) return;

    HapticFeedback.mediumImpact();
    final success = await ref.read(healthProvider.notifier).addMeasurement(
          weight: weight,
          height: height,
          loggedAt: DateTime.now(),
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'BMI details saved to body metrics history!' : 'Failed to save to metrics'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
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
        title: Text(
          'BMI Calculator',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Calculator Inputs
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CALCULATE YOUR BMI',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
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
                          onChanged: (_) => _calculateBmi(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Weight (kg)',
                            hintText: 'e.g. 70',
                            labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          onChanged: (_) => _calculateBmi(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // BMI Result Display
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    const Text(
                      'YOUR BMI',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.neutral),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _bmi > 0 ? _bmi.toStringAsFixed(1) : '--',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _categoryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _category.toUpperCase(),
                        style: TextStyle(
                          color: _categoryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Simple progress/gauge representation
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildGaugeSegment('Underweight', const Color(0xFF3B82F6), true),
                              _buildGaugeSegment('Normal', const Color(0xFF10B981), false),
                              _buildGaugeSegment('Overweight', const Color(0xFFF59E0B), false),
                              _buildGaugeSegment('Obese', const Color(0xFFEF4444), false),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Categories legend labels
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('<18.5', style: TextStyle(fontSize: 10, color: AppColors.neutral)),
                              Text('18.5 - 24.9', style: TextStyle(fontSize: 10, color: AppColors.neutral)),
                              Text('25.0 - 29.9', style: TextStyle(fontSize: 10, color: AppColors.neutral)),
                              Text('30.0+', style: TextStyle(fontSize: 10, color: AppColors.neutral)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Health Information and Save Action
            if (_bmi > 0) ...[
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(PhosphorIconsRegular.info, size: 20, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Health Recommendations',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getTipForBmi(),
                      style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      text: 'SAVE TO BODY MEASUREMENTS',
                      onPressed: _logToMetrics,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGaugeSegment(String name, Color color, bool isStart) {
    bool isSelected = false;
    if (_bmi > 0) {
      if (name == 'Underweight' && _bmi < 18.5) isSelected = true;
      if (name == 'Normal' && _bmi >= 18.5 && _bmi < 25.0) isSelected = true;
      if (name == 'Overweight' && _bmi >= 25.0 && _bmi < 30.0) isSelected = true;
      if (name == 'Obese' && _bmi >= 30.0) isSelected = true;
    }

    return Expanded(
      child: Container(
        height: 12,
        margin: const EdgeInsets.symmetric(horizontal: 2.0),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: isSelected ? Border.all(color: AppColors.secondary, width: 1.5) : null,
        ),
      ),
    );
  }

  String _getTipForBmi() {
    if (_bmi < 18.5) {
      return 'You are in the Underweight range. It is recommended to consult with a doctor or nutritionist to discuss healthy ways to gain weight, including balanced meal plans and strength training.';
    } else if (_bmi >= 18.5 && _bmi < 25.0) {
      return 'Great job! You are in the Normal/Healthy weight range. Maintaining a balanced diet and regular physical activity of at least 150 minutes per week will help keep your weight stable.';
    } else if (_bmi >= 25.0 && _bmi < 30.0) {
      return 'You are in the Overweight range. A slight reduction in calorie intake and an increase in daily steps can help shift your weight back to a healthy range. Consult your health provider for guidance.';
    } else {
      return 'You are in the Obese range. Obesity increases the risk of chronic conditions like diabetes and cardiovascular disease. We highly recommend booking an appointment with one of our specialized doctors for an initial assessment.';
    }
  }
}
