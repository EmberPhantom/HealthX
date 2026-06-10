import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api/api_service.dart';
import '../theme/theme.dart';

const double _refW = 360.0;
const double _refH = 800.0;

class DiaCareApp extends StatelessWidget {
  const DiaCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiaCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E7B)),
      ),
      home: const DiaCareScreen(),
    );
  }
}

class DiaCareScreen extends StatefulWidget {
  const DiaCareScreen({super.key});

  @override
  State<DiaCareScreen> createState() => _DiaCareScreenState();
}

class _DiaCareScreenState extends State<DiaCareScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  static const Color _tealBlue = Color(0xFF1B7B8A);
  static const Color _subtitleBlue = Color(0xFF2A8B9A);
  static const Color _bgColor = Color(0xFFF0EDE8);
  static const Color _cardBg = Color(0xFFF6F8FA);
  static const Color _checkGreen = Color(0xFF3A9B8F);

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
                _ScreenHeader(title: 'Diabetic Care', ws: ws, hs: hs),
                Expanded(
                  child: RefreshIndicator(
                    displacement: 20,
                    edgeOffset: 0,
                    color: AppTheme.primaryGreen,
                    backgroundColor: Colors.white,
                    onRefresh: _handleRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                      child: Column(
                        children: [
                          SizedBox(height: 10 * hs),
                          const SizedBox.shrink(),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: MediaQuery.of(context).size.height -
                                      MediaQuery.of(context).padding.top -
                                      MediaQuery.of(context).padding.bottom -
                                      56 * hs,
                                ),
                                child: _buildContent(ws, hs),
                              ),
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).padding.bottom),
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
        Positioned(
          top: -40,
          left: -60,
          child: Container(
            width: 180 * ws,
            height: 180 * ws,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [_tealBlue.withOpacity(0.08), _tealBlue.withOpacity(0.0)]),
            ),
          ),
        ),
        Positioned(
          top: 220 * hs,
          right: -80,
          child: Container(
            width: 140 * ws,
            height: 140 * ws,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [_tealBlue.withOpacity(0.05), _tealBlue.withOpacity(0.0)]),
            ),
          ),
        ),
        Column(
          children: [
            SizedBox(height: 8 * hs),
            FadeTransition(opacity: _fadeAnimation, child: _buildHeroImage(ws, hs)),
            SizedBox(height: 8 * hs),
            FadeTransition(opacity: _fadeAnimation, child: _buildTitleSection(ws, hs)),
            SizedBox(height: 8 * hs),
            FadeTransition(opacity: _fadeAnimation, child: _buildPriceButton(ws, hs)),
            SizedBox(height: 12 * hs),
            FadeTransition(opacity: _fadeAnimation, child: _buildFeatureCards(ws, hs)),
            SizedBox(height: 14 * hs),
            FadeTransition(opacity: _fadeAnimation, child: _buildTodaysTasks(ws, hs)),
            SizedBox(height: 12 * hs),
            FadeTransition(opacity: _fadeAnimation, child: _buildCheckoutButton(ws, hs)),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroImage(double ws, double hs) {
    final size = 170.0 * ws;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(85 * ws),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 14, offset: Offset(0, 6 * hs)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(85 * ws),
        child: CachedNetworkImage(
          imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=600&auto=format&fit=crop',
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: const Color(0xFFE0DCD7),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(_tealBlue))),
          ),
          errorWidget: (_, __, ___) => Container(
            color: const Color(0xFFE0DCD7),
            child: Icon(Icons.restaurant, size: 60 * ws, color: _tealBlue),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection(double ws, double hs) {
    return Column(
      children: [
        Text(
          'Diabetic Care',
          style: GoogleFonts.poppins(
            fontSize: 26 * ws,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A2E3B),
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 4 * hs),
        Text(
          'Monthly Subscription',
          style: GoogleFonts.poppins(
            fontSize: 14 * ws,
            fontWeight: FontWeight.w500,
            color: _subtitleBlue,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceButton(double ws, double hs) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20 * ws, vertical: 8 * hs),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF143D5C), Color(0xFF1A6B7A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20 * ws),
        boxShadow: [
          BoxShadow(color: _tealBlue.withOpacity(0.25), blurRadius: 12, offset: Offset(0, 4 * hs)),
        ],
      ),
      child: Text(
        '₹2,499/month',
        style: GoogleFonts.poppins(fontSize: 15 * ws, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3),
      ),
    );
  }

  Widget _buildFeatureCards(double ws, double hs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * ws),
      child: Row(
        children: [
          Expanded(child: _featureCard(icon: Icons.favorite, iconColor: const Color(0xFFE85050), iconBgColor: const Color(0xFFFDE8E8), title: 'Low Carb\nMeals', subtitle: 'Manage Blood\nSugar', ws: ws, hs: hs)),
          SizedBox(width: 12 * ws),
          Expanded(child: _featureCard(icon: Icons.show_chart_rounded, iconColor: const Color(0xFF1B7B8A), iconBgColor: const Color(0xFFE0F4F4), title: 'Track Your\nProgress', subtitle: 'Daily Analytics\nReports', ws: ws, hs: hs)),
          SizedBox(width: 12 * ws),
          Expanded(child: _featureCard(icon: Icons.shield_outlined, iconColor: const Color(0xFFD4A520), iconBgColor: const Color(0xFFFFF6DD), title: 'Expert\nGuidance', subtitle: 'Control Tips\n& Support', ws: ws, hs: hs)),
        ],
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required double ws,
    required double hs,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12 * hs, horizontal: 4 * ws),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14 * ws),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2 * hs)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36 * ws,
            height: 36 * ws,
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18 * ws),
          ),
          SizedBox(height: 6 * hs),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 10 * ws, fontWeight: FontWeight.w600, color: const Color(0xFF1A2E3B), height: 1.2),
          ),
          SizedBox(height: 2 * hs),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 8.5 * ws, fontWeight: FontWeight.w400, color: const Color(0xFF7A8A96), height: 1.25),
          ),
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
              Text(
                "Today's Tasks",
                style: GoogleFonts.poppins(fontSize: 16 * ws, fontWeight: FontWeight.w700, color: const Color(0xFF1A2E3B)),
              ),
              SizedBox(width: 6 * ws),
              Container(
                width: 6 * ws,
                height: 6 * ws,
                decoration: BoxDecoration(color: _tealBlue, shape: BoxShape.circle),
              ),
            ],
          ),
          SizedBox(height: 12 * hs),
          _taskItem(text: 'Weekly Low Carb Meal Plans tailored for your needs', boldPart: 'Weekly Low Carb Meal Plans', ws: ws, hs: hs),
          SizedBox(height: 10 * hs),
          _taskItem(text: 'Nutritious recipes designed to build muscle', boldPart: 'build muscle', isBoldItalic: true, ws: ws, hs: hs),
          SizedBox(height: 10 * hs),
          _taskItem(text: 'Cancel anytime', boldPart: 'Cancel anytime', ws: ws, hs: hs),
        ],
      ),
    );
  }

  Widget _taskItem({
    required String text,
    required String boldPart,
    bool isBoldItalic = false,
    required double ws,
    required double hs,
  }) {
    final parts = text.split(boldPart);
    final spans = <TextSpan>[];

    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      spans.add(TextSpan(
        text: parts[0],
        style: GoogleFonts.poppins(fontSize: 12.5 * ws, fontWeight: FontWeight.w400, color: const Color(0xFF2D3E4A), height: 1.3),
      ));
    }
    spans.add(TextSpan(
      text: boldPart,
      style: GoogleFonts.poppins(
        fontSize: 12.5 * ws,
        fontWeight: FontWeight.w700,
        fontStyle: isBoldItalic ? FontStyle.italic : FontStyle.normal,
        color: const Color(0xFF1A2E3B),
        height: 1.3,
      ),
    ));
    if (parts.length > 1 && parts[1].isNotEmpty) {
      spans.add(TextSpan(
        text: parts[1],
        style: GoogleFonts.poppins(fontSize: 12.5 * ws, fontWeight: FontWeight.w400, color: const Color(0xFF2D3E4A), height: 1.3),
      ));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 20 * ws,
          height: 20 * ws,
          decoration: BoxDecoration(
            color: _tealBlue,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: _tealBlue.withOpacity(0.25), blurRadius: 4, offset: Offset(0, 1 * hs))],
          ),
          child: Icon(Icons.check_rounded, size: 13 * ws, color: Colors.white),
        ),
        SizedBox(width: 10 * ws),
        Expanded(
          child: Transform.translate(
            offset: const Offset(0, -3),
            child: RichText(text: TextSpan(children: spans)),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutButton(double ws, double hs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * ws),
      child: SizedBox(
        width: double.infinity,
        height: 52 * hs,
        child: ElevatedButton(
          onPressed: () async {
            HapticFeedback.mediumImpact();
            final appProvider = Provider.of<AppProvider>(context, listen: false);
            final plan = appProvider.mealPlans.firstWhere(
              (p) => p.destination == 'diabetic_care',
              orElse: () => throw Exception('Diabetic Care plan not found'),
            );
            
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_tealBlue),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: _tealBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28 * ws)),
            elevation: 2,
            textStyle: GoogleFonts.poppins(fontSize: 17 * ws, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          ),
          child: const Text('Checkout'),
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
              Text("Your subscription to $planName is active. We are here to support your healthy lifestyle!", style: GoogleFonts.poppins(fontSize: 11 * ws, fontWeight: FontWeight.w400, color: const Color(0xFF6B7B6B), height: 1.5), textAlign: TextAlign.center),
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
                    color: _tealBlue,
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

// ─── Shared Header ────────────────────────────────────────────
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
            child: Padding(
              padding: EdgeInsets.all(4 * ws),
              child: Icon(Icons.arrow_back_ios_new, size: 17 * ws, color: const Color(0xFF1A1A1A)),
            ),
          ),
          SizedBox(width: 12 * ws),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 17 * ws, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Chips (kept for completeness) ─────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow();
  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StatChip(label: 'Active', value: '7d'),
        _StatChip(label: 'Meals', value: '21'),
        _StatChip(label: 'Progress', value: 'Good'),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ws = MediaQuery.of(context).size.width / _refW;
        final hs = MediaQuery.of(context).size.height / _refH;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: GoogleFonts.poppins(fontSize: 13 * ws, fontWeight: FontWeight.w700)),
            SizedBox(height: 2 * hs),
            Text(label, style: GoogleFonts.poppins(fontSize: 11 * ws, fontWeight: FontWeight.w400, color: Colors.black54)),
          ],
        );
      },
    );
  }
}