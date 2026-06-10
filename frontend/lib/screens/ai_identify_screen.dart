import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../services/api/api_service.dart';
import 'correct_ingredients_screen.dart';

class AIIdentifyScreen extends StatefulWidget {
  final File imageFile;
  final String meal;

  const AIIdentifyScreen({
    super.key,
    required this.imageFile,
    required this.meal,
  });

  @override
  State<AIIdentifyScreen> createState() => _AIIdentifyScreenState();
}

class _AIIdentifyScreenState extends State<AIIdentifyScreen>
    with TickerProviderStateMixin {
  late AnimationController _scanController;
  late AnimationController _fadeController;
  late Animation<double> _scanAnimation;
  late Animation<double> _fadeAnimation;

  static const double _refW = 360;
  static const double _refH = 800;

  @override
  void initState() {
    super.initState();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _performIdentification();
  }

  Future<void> _performIdentification() async {
    try {
      // Real API call to upload image and identify
      final response = await ApiService().identifyMealFromImage(
        imagePath: widget.imageFile.path,
      );

      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CorrectIngredientsScreen(
              imageFile: widget.imageFile,
              meal: widget.meal,
              nutritionData: response.data!,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.error ?? 'Identification failed')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error identifying meal: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final screenH = mq.size.height;
    final topPad = mq.padding.top;

    final ws = screenW / _refW;
    final hs = screenH / _refH;

    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: topPad + hs * 14),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: ws * 18),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: ws * 20,
                    ),
                  ),
                  SizedBox(width: ws * 12),
                  Text(
                    'AI identify',
                    style: GoogleFonts.poppins(
                      fontSize: ws * 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: hs * 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: ws * 18),
              child: Text(
                'Ensure the lighting is sufficient, and place\nfood within the frame',
                style: GoogleFonts.poppins(
                  fontSize: ws * 12,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: hs * 20),

            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final boxSize = constraints.maxWidth * 0.82;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: boxSize,
                          height: boxSize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(ws * 16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.55),
                              width: ws * 2.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(ws * 13.5),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  widget.imageFile,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFF1A2A1A),
                                    child: Center(
                                      child: Text('🥗',
                                          style: TextStyle(fontSize: ws * 60)),
                                    ),
                                  ),
                                ),
                                Container(color: Colors.black.withOpacity(0.12)),
                                AnimatedBuilder(
                                  animation: _scanAnimation,
                                  builder: (_, __) {
                                    return Positioned(
                                      top: _scanAnimation.value * (boxSize - 4),
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: ws * 2,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              const Color(0xFF4CAF50)
                                                  .withOpacity(0.95),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                ..._buildCorners(ws),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: hs * 32),
                        Column(
                          children: [
                            Text(
                              'Mapping your food in detail...',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: ws * 13,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: hs * 14),
                            SizedBox(
                              width: ws * 36,
                              height: ws * 36,
                              child: CircularProgressIndicator(
                                strokeWidth: ws * 2.5,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4CAF50),
                                ),
                                backgroundColor: Colors.white.withOpacity(0.2),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCorners(double ws) {
    final len = ws * 20;
    final thickness = ws * 2.5;
    const color = Colors.white;
    final paint = BoxDecoration(color: color);

    Widget corner(double top, double left, double right, double bottom) {
      return Positioned(
        top: top < 0 ? null : top,
        left: left < 0 ? null : left,
        right: right < 0 ? null : right,
        bottom: bottom < 0 ? null : bottom,
        child: SizedBox(
          width: len,
          height: len,
          child: Stack(
            children: [
              Positioned(
                top: top >= 0 ? 0 : null,
                bottom: bottom >= 0 ? 0 : null,
                left: left >= 0 ? 0 : null,
                right: right >= 0 ? 0 : null,
                child: Container(width: len, height: thickness, decoration: paint),
              ),
              Positioned(
                top: top >= 0 ? 0 : null,
                bottom: bottom >= 0 ? 0 : null,
                left: left >= 0 ? 0 : null,
                right: right >= 0 ? 0 : null,
                child: Container(width: thickness, height: len, decoration: paint),
              ),
            ],
          ),
        ),
      );
    }

    final off = ws * 8;
    return [
      corner(off, off, -1, -1),
      corner(off, -1, off, -1),
      corner(-1, off, -1, off),
      corner(-1, -1, off, off),
    ];
  }
}