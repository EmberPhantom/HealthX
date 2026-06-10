import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'food_detail_screen.dart';

class CountingCaloriesScreen extends StatefulWidget {
  final File imageFile;
  final String meal;
  final bool isTextBased;
  final Map<String, dynamic> nutritionData;

  const CountingCaloriesScreen({
    super.key,
    required this.imageFile,
    required this.meal,
    this.isTextBased = false,
    required this.nutritionData,
  });

  @override
  State<CountingCaloriesScreen> createState() =>
      _CountingCaloriesScreenState();
}

class _CountingCaloriesScreenState extends State<CountingCaloriesScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _bounceController;
  late Animation<double> _progressAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..repeat(reverse: true);

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FoodDetailScreen(
              imageFile: widget.imageFile,
              meal: widget.meal,
              isTextBased: widget.isTextBased,
              nutritionData: widget.nutritionData,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  bool get _hasImage =>
      !widget.isTextBased &&
          widget.imageFile.path.isNotEmpty &&
          widget.imageFile.existsSync();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = MediaQuery.of(context).size.height;

        const double refW = 360;
        const double refH = 800;

        final double ws = screenWidth / refW;
        final double hs = screenHeight / refH;

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // Food image or placeholder
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.42,
                child: _hasImage
                    ? Image.file(
                  widget.imageFile,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => _placeholder(ws, hs),
                )
                    : _placeholder(ws, hs),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding:
                  EdgeInsets.symmetric(horizontal: 28 * ws),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.nutritionData['foodName'] ?? widget.nutritionData['name'] ?? 'Identified Food',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 18 * ws,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      SizedBox(height: 28 * hs),

                      // Bouncing emoji
                      AnimatedBuilder(
                        animation: _bounceAnimation,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(0, -_bounceAnimation.value * hs),
                          child: child,
                        ),
                        child: Text(
                          '🥑',
                          style: TextStyle(fontSize: 54 * ws),
                        ),
                      ),
                      SizedBox(height: 22 * hs),

                      Text(
                        'Counting calories...',
                        style: GoogleFonts.poppins(
                          fontSize: 13 * ws,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      SizedBox(height: 16 * hs),

                      // Progress bar
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (_, __) => ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: _progressAnimation.value,
                            minHeight: 4 * hs,
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor:
                            const AlwaysStoppedAnimation<Color>(
                              Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _placeholder(double ws, double hs) {
    return Container(
      color: const Color(0xFFF0F5F0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80 * ws,
              height: 80 * ws,
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(40 * ws),
              ),
              child: Icon(
                Icons.restaurant_menu_rounded,
                size: 40 * ws,
                color: const Color(0xFF10B981),
              ),
            ),
            SizedBox(height: 16 * hs),
            Text(
              'Analysing your meal...',
              style: GoogleFonts.poppins(
                fontSize: 14 * ws,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}