import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api/api_service.dart';
import '../theme/theme.dart';

const double _refW = 360.0;
const double _refH = 800.0;

class HealthyBowlApp extends StatelessWidget {
  const HealthyBowlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Healthy Bowl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      ),
      home: const HealthyBowlScreen(),
    );
  }
}

class HealthyBowlScreen extends StatefulWidget {
  const HealthyBowlScreen({super.key});

  @override
  State<HealthyBowlScreen> createState() => _HealthyBowlScreenState();
}

class _HealthyBowlScreenState extends State<HealthyBowlScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _cardsController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _slideController = AnimationController(duration: const Duration(milliseconds: 900), vsync: this);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _scaleController = AnimationController(duration: const Duration(milliseconds: 700), vsync: this);
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack));

    _cardsController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) { _fadeController.forward(); _scaleController.forward(); }
    });
    Future.delayed(const Duration(milliseconds: 400), () { if (mounted) _slideController.forward(); });
    Future.delayed(const Duration(milliseconds: 600), () { if (mounted) _cardsController.forward(); });
  }

  @override
  void dispose() {
    _fadeController.dispose(); _slideController.dispose();
    _scaleController.dispose(); _cardsController.dispose();
    super.dispose();
  }

  static const Color _primaryGreen = Color(0xFF2E7D32);
  static const Color _lightGreen = Color(0xFFE8F5E9);
  static const Color _bgColor = Color(0xFFF5F7F5);
  static const Color _cardBg = Color(0xFFF0F5F0);

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ws = constraints.maxWidth / _refW;
        final hs = MediaQuery.of(context).size.height / _refH;
        return Scaffold(
          backgroundColor: _bgColor,
          body: SafeArea(
            bottom: true,
            child: Column(
              children: [
                _ScreenHeader(title: 'Subscriptions', ws: ws, hs: hs),
                Expanded(
                  child: RefreshIndicator(
                    displacement: 20,
                    edgeOffset: 0,
                    color: AppTheme.primaryGreen,
                    backgroundColor: Colors.white,
                    onRefresh: _handleRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 12 * hs),
                      child: Column(
                        children: [
                          SizedBox(height: 10 * hs),
                          _buildContent(ws, hs),
                          SizedBox(height: MediaQuery.of(context).padding.bottom + 8 * hs),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(double ws, double hs) {
    return Stack(
      children: [
        Positioned(top: -40, left: -60,
          child: Container(width: 220 * ws, height: 220 * ws,
            decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [_primaryGreen.withOpacity(0.08), _primaryGreen.withOpacity(0.0)])),
          ),
        ),
        Positioned(top: 300 * hs, right: -80,
          child: Container(width: 180 * ws, height: 180 * ws,
            decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [_primaryGreen.withOpacity(0.05), _primaryGreen.withOpacity(0.0)])),
          ),
        ),
        Column(
          children: [
            SizedBox(height: 8 * hs),
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(scale: _scaleAnimation, child: _buildBowlImage(ws, hs)),
            ),
            SizedBox(height: 8 * hs),
            SlideTransition(position: _slideAnimation,
                child: FadeTransition(opacity: _fadeAnimation, child: _buildTitleSection(ws, hs))),
            SizedBox(height: 8 * hs),
            SlideTransition(position: _slideAnimation,
                child: FadeTransition(opacity: _fadeAnimation, child: _buildPriceButton(ws, hs))),
            SizedBox(height: 12 * hs),
            FadeTransition(opacity: _fadeAnimation, child: _buildFeatureCards(ws, hs)),
            SizedBox(height: 14 * hs),
            SlideTransition(position: _slideAnimation,
                child: FadeTransition(opacity: _fadeAnimation, child: _buildTodaysTasks(ws, hs))),
            SizedBox(height: 12 * hs),
            FadeTransition(opacity: _fadeAnimation, child: _buildCheckoutButton(ws, hs)),
          ],
        ),
      ],
    );
  }

  Widget _buildBowlImage(double ws, double hs) {
    final size = 170.0 * ws;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 4 * hs,
            child: Container(
              width: 130 * ws,
              height: 18 * hs,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, spreadRadius: 2)],
              ),
            ),
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: Offset(0, 8 * hs)),
                BoxShadow(color: _primaryGreen.withOpacity(0.12), blurRadius: 32, offset: Offset(0, 4 * hs)),
              ],
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500',
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: _lightGreen,
                    child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primaryGreen)))),
                errorWidget: (_, __, ___) => Container(color: _lightGreen,
                    child: Icon(Icons.restaurant_menu_rounded, size: 60 * ws, color: _primaryGreen)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(double ws, double hs) {
    return Column(
      children: [
        Text('Healthy Bowl', style: GoogleFonts.poppins(fontSize: 26 * ws, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A), letterSpacing: -0.5)),
        SizedBox(height: 4 * hs),
        Text('Monthly Subscription', style: GoogleFonts.poppins(fontSize: 14 * ws, fontWeight: FontWeight.w500, color: _primaryGreen, letterSpacing: 0.2)),
      ],
    );
  }

  Widget _buildPriceButton(double ws, double hs) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20 * ws, vertical: 8 * hs),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF388E3C)], begin: Alignment.centerLeft, end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(20 * ws),
        boxShadow: [BoxShadow(color: _primaryGreen.withOpacity(0.25), blurRadius: 12, offset: Offset(0, 4 * hs))],
      ),
      child: Text('₹2,999/month', style: GoogleFonts.poppins(fontSize: 15 * ws, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3)),
    );
  }

  Widget _buildFeatureCards(double ws, double hs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * ws),
      child: Row(
        children: [
          Expanded(child: _buildFeatureCard(icon: Icons.restaurant_menu_rounded, title: 'Personalized\nMeals', subtitle: 'Tailored to\nYour Goals', ws: ws, hs: hs)),
          SizedBox(width: 12 * ws),
          Expanded(child: _buildFeatureCard(icon: Icons.insert_chart_rounded, title: 'Track Your\nProgress', subtitle: 'Daily Analytics\n& Reports', ws: ws, hs: hs)),
          SizedBox(width: 12 * ws),
          Expanded(child: _buildFeatureCard(icon: Icons.lightbulb_outline_rounded, title: 'Expert\nGuidance', subtitle: 'Nutrition Tips\n& Support', ws: ws, hs: hs)),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({required IconData icon, required String title, required String subtitle, required double ws, required double hs}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12 * hs, horizontal: 4 * ws),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14 * ws),
        border: Border.all(color: _primaryGreen.withOpacity(0.08), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2 * hs))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36 * ws, height: 36 * ws,
            decoration: BoxDecoration(color: _lightGreen, shape: BoxShape.circle, border: Border.all(color: _primaryGreen.withOpacity(0.15), width: 1)),
            child: Icon(icon, size: 18 * ws, color: _primaryGreen),
          ),
          SizedBox(height: 6 * hs),
          Text(title, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 10 * ws, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A), height: 1.2)),
          SizedBox(height: 2 * hs),
          Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 8.5 * ws, fontWeight: FontWeight.w400, color: const Color(0xFF6B7B6B), height: 1.25)),
        ],
      ),
    );
  }

  Widget _buildTodaysTasks(double ws, double hs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24 * ws),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Today's Tasks", style: GoogleFonts.poppins(fontSize: 16 * ws, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A))),
              SizedBox(width: 6 * ws),
              Container(width: 6 * ws, height: 6 * ws, decoration: const BoxDecoration(color: _primaryGreen, shape: BoxShape.circle)),
            ],
          ),
          SizedBox(height: 12 * hs),
          _buildTaskItem(text: 'Weekly meal plans customized to your dietary goals', boldPart: 'Weekly meal plans', ws: ws, hs: hs),
          SizedBox(height: 10 * hs),
          _buildTaskItem(text: 'Nutritious recipes crafted to support muscle growth', boldPart: 'support muscle growth', isBoldItalic: true, ws: ws, hs: hs),
          SizedBox(height: 10 * hs),
          _buildTaskItem(text: 'Flexible cancellation at any time', boldPart: 'Flexible cancellation', ws: ws, hs: hs),
        ],
      ),
    );
  }

  Widget _buildTaskItem({required String text, required String boldPart, bool isBoldItalic = false, required double ws, required double hs}) {
    final parts = text.split(boldPart);
    final spans = <TextSpan>[];
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      spans.add(TextSpan(text: parts[0], style: GoogleFonts.poppins(fontSize: 12.5 * ws, fontWeight: FontWeight.w400, color: const Color(0xFF3A3A3A), height: 1.3)));
    }
    spans.add(TextSpan(text: boldPart, style: GoogleFonts.poppins(fontSize: 12.5 * ws, fontWeight: FontWeight.w700, fontStyle: isBoldItalic ? FontStyle.italic : FontStyle.normal, color: const Color(0xFF1A1A1A), height: 1.3)));
    if (parts.length > 1 && parts[1].isNotEmpty) {
      spans.add(TextSpan(text: parts[1], style: GoogleFonts.poppins(fontSize: 12.5 * ws, fontWeight: FontWeight.w400, color: const Color(0xFF3A3A3A), height: 1.3)));
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 20 * ws, height: 20 * ws,
          decoration: BoxDecoration(color: _primaryGreen, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _primaryGreen.withOpacity(0.25), blurRadius: 4, offset: Offset(0, 1 * hs))]),
          child: Icon(Icons.check_rounded, size: 13 * ws, color: Colors.white),
        ),
        SizedBox(width: 10 * ws),
        Expanded(child: Transform.translate(offset: const Offset(0, -3), child: RichText(text: TextSpan(children: spans)))),
      ],
    );
  }

  Widget _buildCheckoutButton(double ws, double hs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * ws),
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.mediumImpact();
          final appProvider = Provider.of<AppProvider>(context, listen: false);
          final plan = appProvider.mealPlans.firstWhere(
            (p) => p.destination == 'healthy_bowl',
            orElse: () => throw Exception('HealthyBowl plan not found'),
          );
          
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
              ),
            ),
          );

          try {
            final response = await ApiService().subscribeToPlan(plan.id);
            Navigator.of(context).pop(); // Dismiss spinner
            
            if (response.isSuccess) {
              _showSuccessDialog(ws, hs, plan.name);
            } else {
              _showErrorDialog(ws, hs, response.error ?? 'Subscription failed');
            }
          } catch (e) {
            Navigator.of(context).pop(); // Dismiss spinner
            _showErrorDialog(ws, hs, e.toString());
          }
        },
        child: Container(
          width: double.infinity,
          height: 52 * hs,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF388E3C)], begin: Alignment.centerLeft, end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(28 * ws),
            boxShadow: [BoxShadow(color: _primaryGreen.withOpacity(0.35), blurRadius: 16, offset: Offset(0, 4 * hs))],
          ),
          child: Center(child: Text('Checkout', style: GoogleFonts.poppins(fontSize: 17 * ws, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5))),
        ),
      ),
    );
  }

  void _showSuccessDialog(double ws, double hs, String planName) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 40 * ws),
          padding: EdgeInsets.all(22 * ws),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20 * ws),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54 * ws, height: 54 * ws,
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(16 * ws)),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF43A047), size: 32),
              ),
              SizedBox(height: 14 * hs),
              Text('Plan Subscribed!', style: GoogleFonts.poppins(fontSize: 15 * ws, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A)), textAlign: TextAlign.center),
              SizedBox(height: 7 * hs),
              Text("Your subscription to $planName is active. Let's build healthy habits!", style: GoogleFonts.poppins(fontSize: 11 * ws, fontWeight: FontWeight.w400, color: const Color(0xFF6B7B6B), height: 1.5), textAlign: TextAlign.center),
              SizedBox(height: 16 * hs),
              GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop(); // Go back to plans list
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 11 * hs),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF388E3C)]),
                    borderRadius: BorderRadius.circular(18 * ws),
                  ),
                  child: Center(child: Text("Awesome!", style: GoogleFonts.poppins(fontSize: 13 * ws, fontWeight: FontWeight.w600, color: Colors.white))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(double ws, double hs, String error) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 40 * ws),
          padding: EdgeInsets.all(22 * ws),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20 * ws),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54 * ws, height: 54 * ws,
                decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(16 * ws)),
                child: const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 32),
              ),
              SizedBox(height: 14 * hs),
              Text('Subscription Failed', style: GoogleFonts.poppins(fontSize: 15 * ws, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A)), textAlign: TextAlign.center),
              SizedBox(height: 7 * hs),
              Text(error, style: GoogleFonts.poppins(fontSize: 11 * ws, fontWeight: FontWeight.w400, color: const Color(0xFFEF4444), height: 1.5), textAlign: TextAlign.center),
              SizedBox(height: 16 * hs),
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 11 * hs),
                  decoration: BoxDecoration(
                    color: const Color(0xFF374151),
                    borderRadius: BorderRadius.circular(18 * ws),
                  ),
                  child: Center(child: Text("Close", style: GoogleFonts.poppins(fontSize: 13 * ws, fontWeight: FontWeight.w600, color: Colors.white))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  final String title;
  final double ws, hs;
  const _ScreenHeader({required this.title, required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16 * ws, vertical: 8 * hs),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: Offset(0, 2 * hs))],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(padding: EdgeInsets.all(4 * ws), child: Icon(Icons.arrow_back_ios_new, size: 17 * ws, color: const Color(0xFF1A1A1A))),
          ),
          SizedBox(width: 12 * ws),
          Text(title, style: GoogleFonts.poppins(fontSize: 17 * ws, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A), letterSpacing: -0.3)),
        ],
      ),
    );
  }
}