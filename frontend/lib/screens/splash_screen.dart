import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';

const double _refW = 360.0;
const double _refH = 800.0;

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _taglineController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _taglineOpacity;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF228B22),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutQuint),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _taglineSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _taglineController, curve: Curves.easeOutCubic),
        );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOut),
    );

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    _taglineController.forward();

    // Pre-cache background images during splash animation so they load instantly
    try {
      precacheImage(const AssetImage('assets/images/login.jpg'), context);
      precacheImage(const AssetImage('assets/images/signup.jpg'), context);
    } catch (e) {
      debugPrint('Error pre-caching images: $e');
    }

    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    widget.onComplete();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = MediaQuery.of(context).size.height;
        final ws = screenWidth / _refW;
        final hs = screenHeight / _refH;

        // Logo size scales proportionally with width, capped for large screens
        final logoSize = 120.0 * ws;

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.18),
                radius: 1.1,
                colors: [
                  Color(0xFF43A047),
                  Color(0xFF228B22),
                  Color(0xFF1B5E20),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
            child: FractionallySizedBox(
              alignment: const Alignment(0, -0.12),
              heightFactor: 1,
              widthFactor: 1,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Radial light behind logo
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: logoSize * 1.5,
                          height: logoSize * 1.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withOpacity(0.10),
                                Colors.transparent,
                              ],
                              radius: 0.7,
                            ),
                          ),
                        ),
                        // Logo
                        AnimatedBuilder(
                          animation: _logoController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _logoOpacity.value,
                              child: Transform.scale(
                                scale: _logoScale.value,
                                child: _buildLogo(logoSize, ws),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 36 * hs),
                    // App Name
                    Text(
                      'HealthX',
                      style: GoogleFonts.inter(
                        fontSize: 34 * ws,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.4,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 12 * hs),
                    // Tagline
                    SlideTransition(
                      position: _taglineSlide,
                      child: FadeTransition(
                        opacity: _taglineOpacity,
                        child: _buildTagline(ws),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo(double size, double ws) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 7 * ws,
            spreadRadius: 0,
            offset: Offset(0, 2 * ws),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/icon/Healthy_treats.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildTagline(double ws) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24 * ws),
      child: Text(
        'As Unique As You',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 11 * ws,
          fontWeight: FontWeight.w400,
          color: Colors.white.withOpacity(0.87),
          height: 1.3,
        ),
      ),
    );
  }
}