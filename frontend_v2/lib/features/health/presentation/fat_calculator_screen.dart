import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/health_provider.dart';

class FatCalculatorScreen extends ConsumerStatefulWidget {
  const FatCalculatorScreen({super.key});

  @override
  ConsumerState<FatCalculatorScreen> createState() => _FatCalculatorScreenState();
}

class _FatCalculatorScreenState extends ConsumerState<FatCalculatorScreen> {
  bool _isMale = true;
  double _height = 170.0;
  int _weight = 70;
  int _age = 25;
  int _waist = 80;
  int _neck = 37;
  int _hip = 90;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _prefillFields());
  }

  void _prefillFields() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      if (user.gender != null) {
        _isMale = user.gender!.toLowerCase() == 'male';
      }
      if (user.height != null && user.height! >= 100 && user.height! <= 220) {
        _height = user.height!;
      }
      if (user.weight != null && user.weight! >= 20 && user.weight! <= 200) {
        _weight = user.weight!.round();
      }
      if (user.age != null && user.age! >= 10 && user.age! <= 100) {
        _age = user.age!;
      }
    }

    // Try measurements logs for even better precision
    final logs = ref.read(healthProvider).measurementLogs;
    if (logs.isNotEmpty) {
      final latest = logs.first;
      if (latest.height != null && latest.height! >= 100 && latest.height! <= 220) {
        _height = latest.height!;
      }
      if (latest.weight != null && latest.weight! >= 20 && latest.weight! <= 200) {
        _weight = latest.weight!.round();
      }
      if (latest.waist != null && latest.waist! >= 40 && latest.waist! <= 200) {
        _waist = latest.waist!.round();
      }
      if (latest.hips != null && latest.hips! >= 50 && latest.hips! <= 200) {
        _hip = latest.hips!.round();
      }
    }
    setState(() {});
  }

  void _calculate() {
    if (_isMale && _waist <= _neck) {
      _showError('Waist ($_waist cm) must be greater than Neck ($_neck cm).');
      return;
    }
    if (!_isMale && (_waist + _hip) <= _neck) {
      _showError('Waist + Hip must be greater than Neck measurement.');
      return;
    }

    double bf;
    if (_isMale) {
      final logVal = math.log(_waist - _neck) / math.ln10;
      final logH = math.log(_height) / math.ln10;
      bf = 495 / (1.0324 - 0.19077 * logVal + 0.15456 * logH) - 450;
    } else {
      final logVal = math.log(_waist + _hip - _neck) / math.ln10;
      final logH = math.log(_height) / math.ln10;
      bf = 495 / (1.29579 - 0.35004 * logVal + 0.22100 * logH) - 450;
    }
    bf = bf.clamp(3.0, 50.0);
    HapticFeedback.mediumImpact();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ResultScreen(
          bodyFat: bf,
          isMale: _isMale,
          weight: _weight,
          height: _height,
          waist: _waist,
          hips: _isMale ? null : _hip,
          age: _age,
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _tap(Function() fn) {
    HapticFeedback.selectionClick();
    setState(fn);
  }

  String get _heightFtIn {
    final totalIn = _height / 2.54;
    final feet = (totalIn / 12).floor();
    final inches = (totalIn % 12).round();
    return "$feet'$inches\"";
  }

  Widget _buildGenderToggle() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(children: [
        _GenderPill(
          label: 'Male',
          icon: PhosphorIconsRegular.genderMale,
          color: const Color(0xFF3B82F6),
          isSelected: _isMale,
          onTap: () => _tap(() => _isMale = true),
        ),
        _GenderPill(
          label: 'Female',
          icon: PhosphorIconsRegular.genderFemale,
          color: const Color(0xFFEC4899),
          isSelected: !_isMale,
          onTap: () => _tap(() => _isMale = false),
        ),
      ]),
    );
  }

  Widget _buildHeightCard() {
    return CustomCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'HEIGHT',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _heightFtIn,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${_height.round()}',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
            ),
            const SizedBox(width: 4),
            const Text(
              'cm',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.secondary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.15),
            trackHeight: 5,
          ),
          child: Slider(
            value: _height,
            min: 100,
            max: 220,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _height = v);
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildCounterCard({
    required String label,
    required int value,
    required String unit,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: accentColor, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
          ),
        ]),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$value',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
              ),
              const SizedBox(width: 2),
              Text(
                ' $unit',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          _StepBtn(icon: PhosphorIconsRegular.minus, color: accentColor, onTap: onMinus),
          const Spacer(),
          _StepBtn(icon: PhosphorIconsRegular.plus, color: accentColor, onTap: onPlus),
        ]),
      ]),
    );
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
          'Body Fat Calculator',
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(PhosphorIconsRegular.flask, color: AppColors.secondary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'U.S. Navy Method — Calculates body fat based on height, waist, neck, and hip circumferences.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 11,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'SELECT GENDER',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildGenderToggle(),
                  const SizedBox(height: 16),
                  _buildHeightCard(),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                    children: [
                      _buildCounterCard(
                        label: 'WEIGHT',
                        value: _weight,
                        unit: 'kg',
                        icon: PhosphorIconsRegular.scales,
                        accentColor: const Color(0xFF8B5CF6),
                        onMinus: () => _tap(() => _weight = (_weight - 1).clamp(20, 200)),
                        onPlus: () => _tap(() => _weight = (_weight + 1).clamp(20, 200)),
                      ),
                      _buildCounterCard(
                        label: 'AGE',
                        value: _age,
                        unit: 'yrs',
                        icon: PhosphorIconsRegular.cake,
                        accentColor: const Color(0xFFF59E0B),
                        onMinus: () => _tap(() => _age = (_age - 1).clamp(10, 100)),
                        onPlus: () => _tap(() => _age = (_age + 1).clamp(10, 100)),
                      ),
                      _buildCounterCard(
                        label: 'WAIST',
                        value: _waist,
                        unit: 'cm',
                        icon: PhosphorIconsRegular.ruler,
                        accentColor: const Color(0xFFEF4444),
                        onMinus: () => _tap(() => _waist = (_waist - 1).clamp(40, 200)),
                        onPlus: () => _tap(() => _waist = (_waist + 1).clamp(40, 200)),
                      ),
                      _buildCounterCard(
                        label: 'NECK',
                        value: _neck,
                        unit: 'cm',
                        icon: PhosphorIconsRegular.personSimple,
                        accentColor: const Color(0xFF0EA5E9),
                        onMinus: () => _tap(() => _neck = (_neck - 1).clamp(20, 80)),
                        onPlus: () => _tap(() => _neck = (_neck + 1).clamp(20, 80)),
                      ),
                    ],
                  ),
                  if (!_isMale) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCounterCard(
                            label: 'HIP',
                            value: _hip,
                            unit: 'cm',
                            icon: PhosphorIconsRegular.arrowsHorizontal,
                            accentColor: const Color(0xFF10B981),
                            onMinus: () => _tap(() => _hip = (_hip - 1).clamp(50, 200)),
                            onPlus: () => _tap(() => _hip = (_hip + 1).clamp(50, 200)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 140,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(PhosphorIconsRegular.lightbulb, color: AppColors.secondary, size: 20),
                                const SizedBox(height: 8),
                                Text(
                                  'Measure waist at navel height. For women, measure hip at widest part.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.tertiary,
              border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              top: false,
              child: PrimaryButton(
                text: 'CALCULATE BODY FAT',
                icon: const Icon(PhosphorIconsRegular.calculator, color: AppColors.secondary, size: 20),
                onPressed: _calculate,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderPill({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? color : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StepBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

class _ResultScreen extends ConsumerStatefulWidget {
  final double bodyFat;
  final bool isMale;
  final int weight;
  final double height;
  final int waist;
  final int? hips;
  final int age;

  const _ResultScreen({
    required this.bodyFat,
    required this.isMale,
    required this.weight,
    required this.height,
    required this.waist,
    required this.hips,
    required this.age,
  });

  @override
  ConsumerState<_ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<_ResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  _BfCategory get _category {
    final bf = widget.bodyFat;
    if (widget.isMale) {
      if (bf < 6) return const _BfCategory('Athletic', Color(0xFF3B82F6), 'Extremely lean — athlete level body fat.');
      if (bf < 14) return const _BfCategory('Fitness', Color(0xFF10B981), 'Fit and healthy — great body composition.');
      if (bf < 18) return const _BfCategory('Acceptable', AppColors.primary, 'Normal body fat. You\'re doing well!');
      if (bf < 25) return const _BfCategory('Overweight', Color(0xFFFFAB00), 'Slightly above ideal — small improvements advised.');
      return const _BfCategory('Obese', Color(0xFFD32F2F), 'High body fat — lifestyle changes recommended.');
    } else {
      if (bf < 14) return const _BfCategory('Athletic', Color(0xFF3B82F6), 'Extremely lean — athlete level body fat.');
      if (bf < 21) return const _BfCategory('Fitness', Color(0xFF10B981), 'Fit and healthy — great body composition.');
      if (bf < 25) return const _BfCategory('Acceptable', AppColors.primary, 'Normal body fat. You\'re doing well!');
      if (bf < 32) return const _BfCategory('Overweight', Color(0xFFFFAB00), 'Slightly above ideal — small improvements advised.');
      return const _BfCategory('Obese', Color(0xFFD32F2F), 'High body fat — lifestyle changes recommended.');
    }
  }

  double get _fatMass => widget.weight * widget.bodyFat / 100;

  List<_RangeItem> get _ranges => widget.isMale
      ? [
          const _RangeItem('Athletic', Color(0xFF3B82F6), 0, 6),
          const _RangeItem('Fitness', Color(0xFF10B981), 6, 14),
          const _RangeItem('Acceptable', AppColors.primary, 14, 18),
          const _RangeItem('Overweight', Color(0xFFFFAB00), 18, 25),
          const _RangeItem('Obese', Color(0xFFD32F2F), 25, 50),
        ]
      : [
          const _RangeItem('Athletic', Color(0xFF3B82F6), 0, 14),
          const _RangeItem('Fitness', Color(0xFF10B981), 14, 21),
          const _RangeItem('Acceptable', AppColors.primary, 21, 25),
          const _RangeItem('Overweight', Color(0xFFFFAB00), 25, 32),
          const _RangeItem('Obese', Color(0xFFD32F2F), 32, 50),
        ];

  Future<void> _saveMetrics() async {
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final success = await ref.read(healthProvider.notifier).addMeasurement(
          weight: widget.weight.toDouble(),
          height: widget.height,
          waist: widget.waist.toDouble(),
          hips: widget.hips?.toDouble(),
          bodyFatPercent: widget.bodyFat,
          loggedAt: DateTime.now(),
        );

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Body fat logged successfully!' : 'Failed to save to metrics'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      if (success) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = _category;

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
          'Body Fat Result',
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CustomCard(
                    backgroundColor: cat.color == AppColors.primary ? Colors.white : cat.color.withValues(alpha: 0.03),
                    borderSide: BorderSide(color: cat.color.withValues(alpha: 0.3), width: 1.5),
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _anim,
                          builder: (context, child) => Opacity(
                            opacity: _anim.value.clamp(0.0, 1.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: cat.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: cat.color.withValues(alpha: 0.4), width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: cat.color == AppColors.primary ? AppColors.secondary : cat.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    cat.label.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: cat.color == AppColors.primary ? AppColors.secondary : cat.color,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 150,
                          child: AnimatedBuilder(
                            animation: _anim,
                            builder: (context, child) => CustomPaint(
                              painter: _SemiGaugePainter(
                                value: widget.bodyFat,
                                animValue: _anim.value,
                                ranges: _ranges,
                                activeColor: cat.color,
                              ),
                              size: const Size(double.infinity, 150),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedBuilder(
                          animation: _anim,
                          builder: (context, child) => RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: (widget.bodyFat * _anim.value).toStringAsFixed(_anim.value >= 0.99 ? 1 : 0),
                                style: TextStyle(
                                  fontSize: 54,
                                  fontWeight: FontWeight.w900,
                                  color: cat.color == AppColors.primary ? AppColors.secondary : cat.color,
                                  height: 1,
                                ),
                              ),
                              TextSpan(
                                text: '%',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: (cat.color == AppColors.primary ? AppColors.secondary : cat.color).withValues(alpha: 0.6),
                                ),
                              ),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Body Fat Percentage',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            cat.description,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  height: 1.4,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Body Composition',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _CompositionTile(
                              label: 'Fat Mass',
                              value: '${_fatMass.toStringAsFixed(1)} kg',
                              percent: '${widget.bodyFat.toStringAsFixed(1)}%',
                              color: cat.color == AppColors.primary ? AppColors.secondary : cat.color,
                              icon: PhosphorIconsRegular.drop,
                            ),
                            const SizedBox(width: 12),
                            const _CompositionTile(
                              label: 'Lean Mass',
                              value: '', // dynamic below
                              percent: '',
                              color: Color(0xFF10B981),
                              icon: PhosphorIconsRegular.activity,
                              isLean: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Row(children: [
                            Flexible(
                              flex: widget.bodyFat.round(),
                              child: Container(
                                height: 8,
                                color: (cat.color == AppColors.primary ? AppColors.secondary : cat.color).withValues(alpha: 0.8),
                              ),
                            ),
                            Flexible(
                              flex: (100 - widget.bodyFat).round(),
                              child: Container(
                                height: 8,
                                color: const Color(0xFF10B981).withValues(alpha: 0.8),
                              ),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomCard(
                    backgroundColor: AppColors.success.withValues(alpha: 0.05),
                    borderSide: BorderSide(color: AppColors.success.withValues(alpha: 0.2)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(PhosphorIconsRegular.info, color: AppColors.secondary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'The U.S. Navy circumference method is a reliable estimation tool but does not replace clinical measurement (e.g., DXA scan). Consult a healthcare provider before making major fitness changes.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.tertiary,
              border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              top: false,
              child: PrimaryButton(
                text: 'SAVE TO MEASUREMENTS',
                icon: const Icon(PhosphorIconsRegular.cloudArrowUp, color: AppColors.secondary, size: 20),
                isLoading: _isSaving,
                onPressed: _saveMetrics,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompositionTile extends StatelessWidget {
  final String label, value, percent;
  final Color color;
  final IconData icon;
  final bool isLean;

  const _CompositionTile({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
    required this.icon,
    this.isLean = false,
  });

  @override
  Widget build(BuildContext context) {
    // Access context to read screen's weight or body fat if isLean
    final resultScreen = context.findAncestorWidgetOfExactType<_ResultScreen>();
    final double bf = resultScreen?.bodyFat ?? 0.0;
    final int weight = resultScreen?.weight ?? 0;
    final double fat = weight * bf / 100;
    final double lean = weight - fat;

    final displayVal = isLean ? '${lean.toStringAsFixed(1)} kg' : value;
    final displayPercent = isLean ? '${(100 - bf).toStringAsFixed(1)}%' : percent;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              displayVal,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              displayPercent,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BfCategory {
  final String label;
  final Color color;
  final String description;
  const _BfCategory(this.label, this.color, this.description);
}

class _RangeItem {
  final String label;
  final Color color;
  final double min, max;
  const _RangeItem(this.label, this.color, this.min, this.max);
}

class _SemiGaugePainter extends CustomPainter {
  final double value;
  final double animValue;
  final List<_RangeItem> ranges;
  final Color activeColor;

  const _SemiGaugePainter({
    required this.value,
    required this.animValue,
    required this.ranges,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 10;
    const trackW = 20.0;
    const halfTrack = trackW / 2 + 8;
    final maxR = math.min(cx - halfTrack, cy - halfTrack);
    final radius = maxR.clamp(0.0, size.width * 0.4);
    const startAngle = math.pi;
    const totalSweep = math.pi;
    const gapAngle = 0.025;

    final int segCount = ranges.length;
    final double segSweep = totalSweep / segCount;

    // Draw background track shadow
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      totalSweep,
      false,
      Paint()
        ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = trackW + 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Background track
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      totalSweep,
      false,
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = trackW,
    );

    // Draw segment slices
    double angle = startAngle;
    for (int i = 0; i < segCount; i++) {
      final r = ranges[i];

      if (r.color == activeColor) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius),
          angle + gapAngle / 2,
          segSweep - gapAngle,
          false,
          Paint()
            ..color = r.color.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = trackW + 8
            ..strokeCap = StrokeCap.butt
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        angle + gapAngle / 2,
        segSweep - gapAngle,
        false,
        Paint()
          ..color = r.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = trackW
          ..strokeCap = StrokeCap.butt,
      );
      angle += segSweep;
    }

    // Outer end caps
    final capRadius = trackW / 2;
    canvas.drawCircle(
      Offset(cx + radius * math.cos(startAngle), cy + radius * math.sin(startAngle)),
      capRadius,
      Paint()..color = ranges.first.color,
    );

    final rightEndAngle = startAngle + totalSweep;
    canvas.drawCircle(
      Offset(cx + radius * math.cos(rightEndAngle), cy + radius * math.sin(rightEndAngle)),
      capRadius,
      Paint()..color = ranges.last.color,
    );

    // Needle ratio computation
    double needleRatio = 0.0;
    final double bf = value.clamp(ranges.first.min, ranges.last.max);
    for (int i = 0; i < ranges.length; i++) {
      final r = ranges[i];
      if (bf <= r.max || i == ranges.length - 1) {
        final segMin = r.min.toDouble();
        final segMax = r.max.toDouble();
        final posInSeg = ((bf - segMin) / (segMax - segMin)).clamp(0.0, 1.0);
        needleRatio = (i + posInSeg) / segCount;
        break;
      }
    }

    final needleAngle = startAngle + needleRatio * totalSweep * animValue.clamp(0.0, 1.0);
    final needleTipLen = radius - 4;
    const needleTailLen = 14.0;

    final tipX = cx + needleTipLen * math.cos(needleAngle);
    final tipY = cy + needleTipLen * math.sin(needleAngle);
    final tailX = cx + needleTailLen * math.cos(needleAngle + math.pi);
    final tailY = cy + needleTailLen * math.sin(needleAngle + math.pi);

    // Needle shadow
    canvas.drawLine(
      Offset(tailX, tailY),
      Offset(tipX, tipY),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Needle body
    final perpAngle = needleAngle + math.pi / 2;
    const baseHalfW = 4.0;
    final path = Path()
      ..moveTo(tipX, tipY)
      ..lineTo(cx + baseHalfW * math.cos(perpAngle), cy + baseHalfW * math.sin(perpAngle))
      ..lineTo(tailX, tailY)
      ..lineTo(cx - baseHalfW * math.cos(perpAngle), cy - baseHalfW * math.sin(perpAngle))
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF1E293B)..style = PaintingStyle.fill);

    // Center hub
    canvas.drawCircle(Offset(cx, cy), 18, Paint()..color = activeColor.withValues(alpha: 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(Offset(cx, cy), 12, Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(cx, cy), 12, Paint()..color = activeColor.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 2.0);
    canvas.drawCircle(Offset(cx, cy), 4.5, Paint()..color = const Color(0xFF1E293B));
  }

  @override
  bool shouldRepaint(_SemiGaugePainter old) =>
      old.animValue != animValue || old.value != value || old.activeColor != activeColor;
}
