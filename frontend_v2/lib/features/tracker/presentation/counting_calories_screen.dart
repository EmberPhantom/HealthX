import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';

class CountingCaloriesScreen extends StatefulWidget {
  final String meal;
  final String? imagePath;
  final bool isTextBased;
  final Map<String, dynamic> nutritionData;

  const CountingCaloriesScreen({
    super.key,
    required this.meal,
    this.imagePath,
    this.isTextBased = false,
    required this.nutritionData,
  });

  @override
  State<CountingCaloriesScreen> createState() => _CountingCaloriesScreenState();
}

class _CountingCaloriesScreenState extends State<CountingCaloriesScreen> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _bounceController;
  late Animation<double> _progressAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        context.pushReplacement('/tracker/food-detail', extra: {
          'meal': widget.meal,
          'imagePath': widget.imagePath,
          'isTextBased': widget.isTextBased,
          'nutritionData': widget.nutritionData,
        });
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = !widget.isTextBased && widget.imagePath != null && widget.imagePath!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Meal Image backdrop or placeholder
          Expanded(
            flex: 4,
            child: SizedBox(
              width: double.infinity,
              child: hasImage
                  ? Image.file(
                      File(widget.imagePath!),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      child: const Center(
                        child: Icon(
                          Icons.restaurant_menu_rounded,
                          size: 72,
                          color: AppColors.stepsAccent,
                        ),
                      ),
                    ),
            ),
          ),

          // Analysis content
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.nutritionData['foodName'] ?? 'Analyzing Meal...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bouncing Emoji
                  AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -_bounceAnimation.value),
                        child: child,
                      );
                    },
                    child: const Text(
                      '🥑',
                      style: TextStyle(fontSize: 60),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Counting calorie density & breakdown...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Custom progress bar
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progressAnimation.value,
                          minHeight: 5,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.stepsAccent),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
