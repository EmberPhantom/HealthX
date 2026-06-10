import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/theme.dart';
import 'healthy_bowl_screen.dart';
import 'dia_care_screen.dart';
import 'zym_bowl_screen.dart';
import 'corporate_tie_up_bowl_screen.dart';

const double _refW = 360.0;
const double _refH = 800.0;

class MealPlanScreen extends StatelessWidget {
  const MealPlanScreen({super.key});

  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('0x')) {
        return Color(int.parse(colorStr));
      }
      if (colorStr.startsWith('#')) {
        return Color(int.parse('0xFF${colorStr.substring(1)}'));
      }
      return Color(int.parse('0xFF$colorStr'));
    } catch (_) {
      return AppTheme.primaryGreen;
    }
  }

  Widget _getDestinationScreen(String destination) {
    switch (destination) {
      case 'healthy_bowl':
        return const HealthyBowlScreen();
      case 'zym_bowl':
        return const ZYMBowlScreen();
      case 'diabetic_care':
        return const DiaCareScreen();
      case 'corporate_tie_up_bowl':
        return const CorporateTieUpBowlScreen();
      default:
        return const HealthyBowlScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final mealPlans = provider.mealPlans;

    return LayoutBuilder(
      builder: (context, constraints) {
        final ws = constraints.maxWidth / _refW;
        final hs = MediaQuery.of(context).size.height / _refH;
        return Scaffold(
          backgroundColor: AppTheme.bgLight,
          body: SafeArea(
            bottom: true,
            child: Column(
              children: [
                _Header(ws: ws, hs: hs),
                Expanded(
                  child: RefreshIndicator(
                    displacement: 20,
                    edgeOffset: 0,
                    color: AppTheme.primaryGreen,
                    backgroundColor: Colors.white,
                    onRefresh: () => provider.initializeData(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height -
                              MediaQuery.of(context).padding.top -
                              MediaQuery.of(context).padding.bottom -
                              56 * hs,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: 10 * hs),
                            ...mealPlans.map((p) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: 6 * hs),
                                child: _BannerCard(
                                  assetImage: p.assetImagePath.isNotEmpty ? p.assetImagePath : p.imageUrl,
                                  fallbackColor: _parseColor(p.accentColor).withOpacity(0.25),
                                  overlayColors: [Colors.black.withOpacity(0.40), Colors.black.withOpacity(0.25)],
                                  title: p.name,
                                  subtitle: p.subtitle ?? '',
                                  description: p.subtitle ?? '',
                                  price: '${p.price}${p.priceSuffix}',
                                  priceTextColor: _parseColor(p.accentColor),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => _getDestinationScreen(p.destination)),
                                  ),
                                  ws: ws,
                                  hs: hs,
                                ),
                              );
                            }),
                          ],
                        ),
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
}

// ─── HEADER ───────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final double ws, hs;
  const _Header({required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16 * ws, vertical: 8 * hs),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: Offset(0, 2 * hs)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              padding: EdgeInsets.all(4 * ws),
              child: Icon(Icons.arrow_back_ios_new, size: 17 * ws, color: AppTheme.textDark),
            ),
          ),
          SizedBox(width: 12 * ws),
          Text(
            'Subscriptions',
            style: GoogleFonts.poppins(
              fontSize: 17 * ws,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── BANNER CARD HELPER ───────────────────────────────────────
class _BannerCard extends StatelessWidget {
  final String assetImage;
  final Color fallbackColor;
  final List<Color> overlayColors;
  final String title;
  final String subtitle;
  final String description;
  final String price;
  final Color priceTextColor;
  final VoidCallback onTap;
  final double ws, hs;

  const _BannerCard({
    required this.assetImage,
    required this.fallbackColor,
    required this.overlayColors,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.price,
    required this.priceTextColor,
    required this.onTap,
    required this.ws,
    required this.hs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10 * ws),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 160 * hs,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14 * ws),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 12, offset: Offset(0, 4 * hs)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14 * ws),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    assetImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: fallbackColor),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: overlayColors,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18 * ws, vertical: 16 * hs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: GoogleFonts.poppins(fontSize: 19 * ws, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
                          SizedBox(height: 3 * hs),
                          Text(subtitle, style: GoogleFonts.poppins(fontSize: 11.5 * ws, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.95), letterSpacing: -0.2)),
                          SizedBox(height: 6 * hs),
                          SizedBox(
                            width: 180 * ws,
                            child: Text(description, style: GoogleFonts.poppins(fontSize: 10 * ws, fontWeight: FontWeight.w400, color: Colors.white.withOpacity(0.90), height: 1.3)),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10 * ws, vertical: 5 * hs),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(10 * ws),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: Offset(0, 2 * hs))],
                        ),
                        child: Text(price, style: GoogleFonts.poppins(fontSize: 11 * ws, fontWeight: FontWeight.w700, color: priceTextColor, letterSpacing: -0.2)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── HEALTHY BOWL CARD ────────────────────────────────────────
class _HealthyBowlCard extends StatelessWidget {
  final double ws, hs;
  const _HealthyBowlCard({required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return _BannerCard(
      assetImage: 'assets/images/bg_healthy_bowl.png',
      fallbackColor: const Color(0xFFB8E6C9),
      overlayColors: [Colors.black.withOpacity(0.35), Colors.black.withOpacity(0.20)],
      title: 'Healthy Bowl',
      subtitle: 'Monthly Wellness Plan',
      description: 'Balanced meals for a healthier you',
      price: '₹2,999/month',
      priceTextColor: const Color(0xFF2E7D32),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthyBowlScreen())),
      ws: ws,
      hs: hs,
    );
  }
}

// ─── ZYM BOWL CARD ────────────────────────────────────────────
class _ZymBowlCard extends StatelessWidget {
  final double ws, hs;
  const _ZymBowlCard({required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return _BannerCard(
      assetImage: 'assets/images/bg_zym_bowl.png',
      fallbackColor: const Color(0xFFCCA37B),
      overlayColors: [Colors.black.withOpacity(0.40), Colors.black.withOpacity(0.25)],
      title: 'Gym Bowl',
      subtitle: 'Monthly Fitness Plan',
      description: 'High protein meals for muscle building',
      price: '₹3,699/month',
      priceTextColor: const Color(0xFFCCA37B),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ZYMBowlScreen())),
      ws: ws,
      hs: hs,
    );
  }
}

// ─── DIABETIC CARE CARD ───────────────────────────────────────
class _DiabeticCareCard extends StatelessWidget {
  final double ws, hs;
  const _DiabeticCareCard({required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return _BannerCard(
      assetImage: 'assets/images/bg_diabetic_care.png',
      fallbackColor: const Color(0xFF7B9FCC),
      overlayColors: [Colors.black.withOpacity(0.40), Colors.black.withOpacity(0.25)],
      title: 'Diabetic Care Bowl',
      subtitle: 'Monthly Low-Carb Plan',
      description: 'Low carb diet to manage blood sugar',
      price: '₹2,499/month',
      priceTextColor: const Color(0xFF7B9FCC),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiaCareScreen())),
      ws: ws,
      hs: hs,
    );
  }
}

// ─── CORPORATE TIE-UP CARD ────────────────────────────────────
class _CorporateTieUpCard extends StatelessWidget {
  final double ws, hs;
  const _CorporateTieUpCard({required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10 * ws),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CorporateTieUpBowlScreen())),
        child: Container(
          height: 160 * hs,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14 * ws),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.13), blurRadius: 14, offset: Offset(0, 5 * hs)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14 * ws),
            child: Stack(
              children: [
                // Background image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/bg_corporate_tie_up.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0D2137), Color(0xFF1A3A5C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),
                // Dark overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.52), Colors.black.withOpacity(0.22)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                // Gold shimmer accent top-right
                Positioned(
                  top: 0, right: 0,
                  child: Container(
                    width: 80 * ws,
                    height: 80 * hs,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [const Color(0xFFD4A017).withOpacity(0.28), Colors.transparent],
                        radius: 1.0,
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18 * ws, vertical: 16 * hs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Corporate Tie-Up Bowl',
                                style: GoogleFonts.poppins(
                                  fontSize: 17 * ws,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(width: 6 * ws),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6 * ws, vertical: 2 * hs),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4A017),
                                  borderRadius: BorderRadius.circular(5 * ws),
                                ),
                                child: Text('ELITE', style: GoogleFonts.poppins(fontSize: 7 * ws, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.0)),
                              ),
                            ],
                          ),
                          SizedBox(height: 3 * hs),
                          Text(
                            'Monthly Corporate Wellness Plan',
                            style: GoogleFonts.poppins(fontSize: 11 * ws, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.90), letterSpacing: -0.2),
                          ),
                          SizedBox(height: 6 * hs),
                          SizedBox(
                            width: 190 * ws,
                            child: Text(
                              'Bulk meals for your team with HR wellness reports',
                              style: GoogleFonts.poppins(fontSize: 10 * ws, fontWeight: FontWeight.w400, color: Colors.white.withOpacity(0.85), height: 1.3),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10 * ws, vertical: 5 * hs),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(10 * ws),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: Offset(0, 2 * hs))],
                            ),
                            child: Text(
                              '₹999/week',
                              style: GoogleFonts.poppins(fontSize: 11 * ws, fontWeight: FontWeight.w700, color: const Color(0xFF0D2137), letterSpacing: -0.2),
                            ),
                          ),
                          SizedBox(width: 8 * ws),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8 * ws, vertical: 5 * hs),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4A017).withOpacity(0.90),
                              borderRadius: BorderRadius.circular(10 * ws),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.groups_rounded, size: 11 * ws, color: Colors.white),
                                SizedBox(width: 4 * ws),
                                Text('Team Plans', style: GoogleFonts.poppins(fontSize: 9 * ws, fontWeight: FontWeight.w700, color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
