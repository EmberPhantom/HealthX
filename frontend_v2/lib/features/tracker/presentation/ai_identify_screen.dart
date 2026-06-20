import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../services/meal_service.dart';

class AiIdentifyScreen extends StatefulWidget {
  final String imagePath;
  final String meal;

  const AiIdentifyScreen({
    super.key,
    required this.imagePath,
    required this.meal,
  });

  @override
  State<AiIdentifyScreen> createState() => _AiIdentifyScreenState();
}

class _AiIdentifyScreenState extends State<AiIdentifyScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;
  final _mealService = MealService();
  bool _isError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _identifyImage();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _identifyImage() async {
    try {
      final result = await _mealService.identifyMealFromImage(
        imagePath: widget.imagePath,
      );

      if (mounted) {
        // Navigate to CorrectIngredientsScreen with results
        context.pushReplacement('/tracker/correct-ingredients', extra: {
          'meal': widget.meal,
          'imagePath': widget.imagePath,
          'isTextBased': false,
          'nutritionData': result,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final boxSize = screenWidth * 0.8;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI Food Scanner',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Analyzing your ${widget.meal.toLowerCase()} photo...',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Image Container
                      Container(
                        width: boxSize,
                        height: boxSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(widget.imagePath),
                                fit: BoxFit.cover,
                              ),
                              Container(
                                color: Colors.black26,
                              ),
                              // Animated scanning line
                              if (!_isError)
                                AnimatedBuilder(
                                  animation: _scanAnimation,
                                  builder: (context, child) {
                                    return Positioned(
                                      top: _scanAnimation.value * (boxSize - 4),
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 3,
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary.withValues(alpha: 0.8),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              AppColors.primary,
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Outline corners
                      ..._buildCorners(boxSize),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (_isError) ...[
                Text(
                  'Analysis Error',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade400, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isError = false;
                      _errorMessage = '';
                    });
                    _identifyImage();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                const Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Reading calorie and ingredient makeup...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCorners(double boxSize) {
    const double len = 24.0;
    const double thickness = 3.0;
    const double offset = 8.0;

    Widget corner(double? top, double? left, double? right, double? bottom) {
      return Positioned(
        top: top,
        left: left,
        right: right,
        bottom: bottom,
        child: SizedBox(
          width: len,
          height: len,
          child: Stack(
            children: [
              if (top != null)
                Positioned(top: 0, left: 0, right: 0, child: Container(height: thickness, color: Colors.white)),
              if (bottom != null)
                Positioned(bottom: 0, left: 0, right: 0, child: Container(height: thickness, color: Colors.white)),
              if (left != null)
                Positioned(top: 0, bottom: 0, left: 0, child: Container(width: thickness, color: Colors.white)),
              if (right != null)
                Positioned(top: 0, bottom: 0, right: 0, child: Container(width: thickness, color: Colors.white)),
            ],
          ),
        ),
      );
    }

    // Adjusting for box position relative to stack
    return [
      // Top Left
      corner(offset, offset, null, null),
      // Top Right
      corner(offset, null, offset, null),
      // Bottom Left
      corner(null, offset, null, offset),
      // Bottom Right
      corner(null, null, offset, offset),
    ];
  }
}
