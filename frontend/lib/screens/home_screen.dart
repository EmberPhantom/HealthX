import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/rewards_provider.dart';
import '../providers/water_provider.dart';
import '../providers/sleep_provider.dart';
import '../models/api/auth_models.dart';
import '../services/health_service.dart';
import '../services/step_counter_service.dart';
import '../widgets/shared_widgets.dart';
import 'meal_plan_screen.dart';
import 'health_rewards_screen.dart';
import 'healthy_bowl_screen.dart';
import 'find_doctor_screen.dart';
import 'zym_bowl_screen.dart';
import 'diabetic_care_screen.dart' hide UserProfile;
import 'corporate_tie_up_bowl_screen.dart';
import 'ready_to_eat_screen.dart';
import 'tracker_screen.dart' show TrackerScreen;
import 'notifications_screen.dart';
// ── Health Manager screen imports ─────────────────────────────────────────────
import 'blood_glucose_screen.dart';
import 'bmi_calculator_screen.dart';
import 'my_vitals_screen.dart';
import 'set_reminders_screen.dart';
import 'insulin_dosage_screen.dart';
import 'fat_calculator_screen.dart';

// Reference design dimensions
const double _refW = 360.0;
const double _refH = 800.0;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Timer to rebuild greeting + date every minute
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    // Fire at the top of every minute so greeting & date stay accurate
    _scheduleNextMinuteTick();
    // NOTE: AppProvider.initializeData() is now triggered by the ProxyProvider
    // in main.dart when AuthProvider becomes authenticated. Do NOT call it here
    // to avoid race conditions where DioClient doesn't have the token yet.
  }

  void _scheduleNextMinuteTick() {
    final now      = DateTime.now();
    final nextMin  = Duration(
      seconds: 60 - now.second,
      milliseconds: -now.millisecond,
    );
    _clockTimer = Timer(nextMin, () {
      if (mounted) setState(() {});     // triggers greeting/date rebuild
      _scheduleNextMinuteTick();        // reschedule for next minute
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  /// Pull-to-refresh: force re-fetch even if already initialized
  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    final appProvider = context.read<AppProvider>();
    // Reset initialized flag so initializeData() runs a fresh fetch
    appProvider.resetForRefresh();
    await appProvider.initializeData();
  }

  Widget _buildCompactChip(String label, Color color, double ws) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * ws, vertical: 3 * ws),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10 * ws),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10 * ws,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildCompactButton(String label, double ws) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MealPlanScreen()),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12 * ws, vertical: 4 * ws),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(10 * ws),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10 * ws,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = context.watch<UserProvider>().user ??
                 context.watch<AuthProvider>().user ??
                 const UserProfile.empty();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = MediaQuery.of(context).size.height;
        final ws = screenWidth / _refW;
        final hs = screenHeight / _refH;

        final hPad = 14.0 * ws;
        final padding = EdgeInsets.symmetric(horizontal: hPad);
        final headerHeight = 54.0 * hs; // absolute minimum usable

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Fixed Header
                Container(
                  height: headerHeight,
                  color: AppTheme.bgLight,
                  alignment: Alignment.centerLeft,
                  padding: padding.copyWith(top: 5 * hs, bottom: 5 * hs),
                  child: _buildStickyHeader(context, user, ws, hs),
                ),
                // Scrollable content with RefreshIndicator
                Expanded(
                  child: RefreshIndicator(
                    displacement: 20,
                    edgeOffset: 0,
                    color: AppTheme.primaryGreen,
                    backgroundColor: Colors.white,
                    onRefresh: _handleRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 1 * hs),
                          Padding(
                            padding: padding,
                            child: _StatsRowResponsive(ws: ws, hs: hs),
                          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.05, end: 0),
                          SizedBox(height: 4 * hs),
                          _BannerCarousel(ws: ws, hs: hs)
                              .animate()
                              .fadeIn(duration: 500.ms, delay: 180.ms)
                              .slideY(begin: 0.06, end: 0),
                          SizedBox(height: 14 * hs),

                          // ── Health Manager Section ────────────────────────
                          Padding(
                            padding: padding,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Health Manager',
                                style: TextStyle(
                                  fontSize: 13 * ws,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textDark,
                                  fontFamily: 'Poppins',
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10 * hs),
                          _HealthManagerStrip(ws: ws, hs: hs)
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 280.ms)
                              .slideY(begin: 0.05, end: 0),
                          SizedBox(height: 16 * hs),

                          // ── Explore Services Section ──────────────────────
                          Padding(
                            padding: padding,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Explore Services',
                                style: TextStyle(
                                  fontSize: 13 * ws,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textDark,
                                  fontFamily: 'Poppins',
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8 * hs),
                          Padding(
                            padding: padding,
                            child: _ExploreServicesGrid(ws: ws, hs: hs),
                          ).animate().fadeIn(duration: 400.ms, delay: 380.ms).slideY(begin: 0.05, end: 0),
                          SizedBox(height: 10 * hs),
                          Padding(
                            padding: padding,
                            child: _ReferEarnBannerResponsive(ws: ws, hs: hs),
                          ),
                          SizedBox(height: 4 * hs),
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

  // --- Real-time greeting helper ---
  static String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  static IconData _getGreetingIcon() {
    final h = DateTime.now().hour;
    if (h < 12) return Icons.wb_sunny_rounded;       // morning → sun
    if (h < 17) return Icons.wb_cloudy_rounded;      // afternoon → cloud-sun
    return Icons.nightlight_round;                   // evening → moon
  }

  static Color _getGreetingIconColor() {
    final h = DateTime.now().hour;
    if (h < 12) return const Color(0xFFFFC107);      // yellow sun
    if (h < 17) return const Color(0xFFFF9800);      // orange afternoon
    return const Color(0xFF9C8FFF);                  // purple moon
  }

  static String _getLiveDate() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[now.month - 1]} ${now.day}';
  }

  // --- Sticky Header ---
  Widget _buildStickyHeader(BuildContext context, user, double ws, double hs) {
    final greeting     = _getGreeting();
    final greetIcon    = _getGreetingIcon();
    final greetColor   = _getGreetingIconColor();
    final provider     = context.read<AppProvider>();
    final unreadCount  = context.watch<AppProvider>().unreadNotificationsCount;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Profile Image - Tappable to switch to Profile Tab (Index 4)
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            provider.setTabIndex(4);
          },
          child: Container(
            width: 44 * ws,
            height: 44 * ws,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryGreen, width: 2 * ws),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                  blurRadius: 8 * ws,
                  offset: Offset(0, 2 * hs),
                ),
              ],
            ),
            child: ClipOval(
              child: HBNetworkImage(
                url: user.avatarUrl,
                width: 44 * ws,
                height: 44 * ws,
              ),
            ),
          ),
        ),
        SizedBox(width: 12 * ws),
        // Greeting + Dropdown
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(
                    greeting,
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 9.5 * ws,
                      letterSpacing: 0.1,
                    ),
                  ),
                  SizedBox(width: 2 * ws),
                  Icon(greetIcon, size: 10 * ws, color: greetColor),
                ],
              ),
              SizedBox(height: 1 * hs),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      user.name.toString().toUpperCase(),
                      style: TextStyle(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 10 * ws,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  SizedBox(width: 4 * ws),
                  Icon(Icons.keyboard_arrow_down, size: 14 * ws, color: AppTheme.textMedium),
                ],
              ),
              if (user.isPremium)
                Padding(
                  padding: EdgeInsets.only(top: 1 * hs),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(1.5 * ws),
                        decoration: const BoxDecoration(
                          color: AppTheme.yellow,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, size: 7 * ws, color: Colors.white),
                      ),
                      SizedBox(width: 3 * ws),
                      Text(
                        'Premium Member',
                        style: TextStyle(
                          color: AppTheme.textMedium,
                          fontSize: 8 * ws,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Reward coin badge — live coins from RewardsProvider
        _LiveCoinsBadge(ws: ws, hs: hs),
        SizedBox(width: 10 * ws),
        // Notification bell — clean icon only, no background box
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_outlined,
                size: 26 * ws,
                color: AppTheme.textDark,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -2 * ws,
                  top: -2 * ws,
                  child: Container(
                    width: 14 * ws,
                    height: 14 * ws,
                    decoration: BoxDecoration(
                      color: AppTheme.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5 * ws),
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 7.5 * ws,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'eco_rounded':
      case 'eco':
        return Icons.eco_rounded;
      case 'fitness_center_rounded':
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'favorite_rounded':
      case 'favorite':
        return Icons.favorite_rounded;
      case 'business_center_rounded':
      case 'business_center':
        return Icons.business_center_rounded;
      default:
        return Icons.eco_rounded;
    }
  }

  Widget _getDestinationScreen(String destination) {
    switch (destination) {
      case 'healthy_bowl':
        return const HealthyBowlScreen();
      case 'zym_bowl':
        return const ZYMBowlScreen();
      case 'diabetic_care':
        return const DiabeticCareScreen();
      case 'corporate_tie_up_bowl':
        return const CorporateTieUpBowlScreen();
      default:
        return const HealthyBowlScreen();
    }
  }

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

  // --- Meal Plan Cards (2x2 grid) ---
  Widget _buildMealPlans(BuildContext context, AppProvider provider, double ws, double hs) {
    final gap = 7.0 * ws;

    final plans = provider.mealPlans.map((p) {
      return _PlanCardData(
        assetImagePath: p.assetImagePath.isNotEmpty ? p.assetImagePath : p.imageUrl,
        price: p.price,
        priceSuffix: p.priceSuffix ?? '',
        planName: p.name,
        subtitle: p.subtitle ?? '',
        badgeLabel: p.badgeLabel != null && p.badgeLabel!.isNotEmpty ? p.badgeLabel : null,
        accentColor: _parseColor(p.accentColor),
        btnColor: _parseColor(p.btnColor),
        isFeatured: p.isFeatured,
        tagIcon: _getIconData(p.tagIcon),
        destinationScreen: _getDestinationScreen(p.destination),
        cardBgColor: _parseColor(p.cardBgColor),
      );
    }).toList();

    if (plans.isEmpty) {
      return const SizedBox.shrink();
    }

    final rows = <Widget>[];
    for (int i = 0; i < plans.length; i += 2) {
      final hasNext = i + 1 < plans.length;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildSinglePlanCard(data: plans[i], ws: ws, hs: hs)),
            SizedBox(width: gap),
            if (hasNext)
              Expanded(child: _buildSinglePlanCard(data: plans[i + 1], ws: ws, hs: hs))
            else
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      );
      if (hasNext && i + 2 < plans.length) {
        rows.add(SizedBox(height: gap));
      }
    }

    return Column(
      children: rows,
    );
  }

  Widget _buildSinglePlanCard({
    required _PlanCardData data,
    required double ws,
    required double hs,
  }) {
    const cardRadius = 14.0;
    const imgRadius  = 10.0;
    final imgHeight = 116.0 * hs;
    final accentColor = data.accentColor;
    final btnHeight   = 33.0 * hs;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => data.destinationScreen));
      },
      child: Container(
        height: imgHeight + btnHeight + 48.0 * hs,
        decoration: BoxDecoration(
          color: data.cardBgColor,
          borderRadius: BorderRadius.circular(cardRadius * ws),
          border: data.isFeatured
              ? Border.all(color: accentColor.withOpacity(0.45), width: 1.8)
              : Border.all(color: Colors.black.withOpacity(0.07), width: 1),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(data.isFeatured ? 0.15 : 0.08),
              blurRadius: 16,
              spreadRadius: 0,
              offset: Offset(0, 5 * hs),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: Offset(0, 1 * hs),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(4 * ws),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Image with overlay badges ──────────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(imgRadius * ws),
                    child: SizedBox(
                      height: imgHeight,
                      width: double.infinity,
                      child: Image.asset(data.assetImagePath, fit: BoxFit.cover),
                    ),
                  ),
                  // Top-left: category icon badge
                  Positioned(
                    top: 6 * ws,
                    left: 6 * ws,
                    child: Container(
                      padding: EdgeInsets.all(4.5 * ws),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(7 * ws),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.13),
                            blurRadius: 5,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(data.tagIcon, size: 11 * ws, color: accentColor),
                    ),
                  ),
                  // Top-right: Popular badge (featured only)
                  if (data.badgeLabel != null)
                    Positioned(
                      top: 6 * ws,
                      right: 6 * ws,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6 * ws,
                          vertical: 3 * hs,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(20 * ws),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          data.badgeLabel!,
                          style: TextStyle(
                            fontSize: 6.5 * ws,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 3 * hs),
              // ── Plan name ─────────────────────────────────────────────
              Text(
                data.planName,
                style: TextStyle(
                  fontSize: 11 * ws,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  fontFamily: 'Poppins',
                  letterSpacing: 0.0,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 1 * hs),
              // ── Subtitle ──────────────────────────────────────────────
              Text(
                data.subtitle,
                style: TextStyle(
                  fontSize: 7.5 * ws,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                  fontFamily: 'Poppins',
                  letterSpacing: 0.05,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // ── Price CTA button ──────────────────────────────────────
              _ShinePriceBadge(
                price: data.price,
                priceSuffix: data.priceSuffix,
                accentColor: data.btnColor,
                ws: ws,
                hs: hs,
                height: btnHeight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}



// ─── Professional Auto-Scrolling Banner Carousel (3 banners) ─────────────────
class _BannerData {
  final String imagePath;
  final String title;
  final String subtitle;
  final String chipLabel;
  const _BannerData({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.chipLabel,
  });
}

class _BannerCarousel extends StatefulWidget {
  final double ws, hs;
  const _BannerCarousel({required this.ws, required this.hs});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel>
    with SingleTickerProviderStateMixin {
  final PageController _pageCtrl = PageController(viewportFraction: 1.0);
  late AnimationController _dotCtrl;
  int _current = 0;

  static const _banners = [
    _BannerData(
      imagePath: 'assets/images/bg_healthy_Bowl_home.png',
      title: 'Healthy Bowl',
      subtitle: 'High Protein Salad',
      chipLabel: '230 Cal',
    ),
    _BannerData(
      imagePath: 'assets/images/banner_2.png',
      title: 'Gym Bowl',
      subtitle: 'Power-Packed Fuel',
      chipLabel: '310 Cal',
    ),
    _BannerData(
      imagePath: 'assets/images/banner_3.png',
      title: 'Diabetic Care',
      subtitle: 'Low Glycemic Meal',
      chipLabel: '180 Cal',
    ),
    _BannerData(
      imagePath: 'assets/images/banner_3.png',
      title: 'Corporate Bowl',
      subtitle: 'Bulk Meal Delivery',
      chipLabel: '200 Cal',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addStatusListener((s) {
      if (s == AnimationStatus.completed) _nextPage();
    });
    _dotCtrl.forward();
  }

  void _nextPage() {
    if (!mounted) return;
    final provider = context.read<AppProvider>();
    final count = provider.banners.isNotEmpty ? provider.banners.length : _banners.length;
    final next = (_current + 1) % count;
    _pageCtrl.animateToPage(
      next,
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _current = next);
    _dotCtrl.reset();
    _dotCtrl.forward();
  }

  void _goTo(int i) {
    _pageCtrl.animateToPage(
      i,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _current = i);
    _dotCtrl.reset();
    _dotCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = widget.ws;
    final hs = widget.hs;
    final provider = context.watch<AppProvider>();
    final banners = provider.banners.isNotEmpty
        ? provider.banners.map((b) => _BannerData(
              imagePath: b.imagePath,
              title: b.title,
              subtitle: b.subtitle,
              chipLabel: b.chipLabel,
            )).toList()
        : _banners;

    return Column(
      children: [
        // ── Banner pager ──────────────────────────────────────────────────
        SizedBox(
          height: 136.0 * hs,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: banners.length,
            onPageChanged: (i) {
              setState(() => _current = i);
              _dotCtrl.reset();
              _dotCtrl.forward();
            },
            itemBuilder: (ctx, i) {
              return AnimatedBuilder(
                animation: _pageCtrl,
                builder: (ctx, child) {
                  double delta = 0;
                  if (_pageCtrl.position.haveDimensions) {
                    delta = (_pageCtrl.page! - i).abs().clamp(0.0, 1.0);
                  }
                  return Transform.scale(
                    scale: 1.0 - delta * 0.035,
                    child: Opacity(opacity: 1.0 - delta * 0.15, child: child),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14 * ws),
                  child: _BannerCard(
                    data: banners[i],
                    ws: ws,
                    hs: hs,
                    onViewPlan: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MealPlanScreen()),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),

        SizedBox(height: 4 * hs),

        // ── Progress dot indicators ────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (i) {
            final isActive = i == _current;
            return GestureDetector(
              onTap: () => _goTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                margin: EdgeInsets.symmetric(horizontal: 3.5 * ws),
                width: isActive ? 22 * ws : 7 * ws,
                height: 7 * ws,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.orange
                      : Colors.grey.withOpacity(0.30),
                  borderRadius: BorderRadius.circular(4 * ws),
                ),
                child: isActive
                    ? AnimatedBuilder(
                  animation: _dotCtrl,
                  builder: (_, __) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _dotCtrl.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.40),
                        borderRadius: BorderRadius.circular(4 * ws),
                      ),
                    ),
                  ),
                )
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─── Individual Banner Card with content overlay + shimmer + press ────────────
class _BannerCard extends StatefulWidget {
  final _BannerData data;
  final double ws, hs;
  final VoidCallback onViewPlan;
  const _BannerCard({
    required this.data,
    required this.ws,
    required this.hs,
    required this.onViewPlan,
  });

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = widget.ws;
    final hs = widget.hs;
    final d  = widget.data;

    return GestureDetector(
      onTapDown:  (_) { setState(() => _pressed = true);  HapticFeedback.lightImpact(); },
      onTapUp:    (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18 * ws),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_pressed ? 0.05 : 0.13),
                blurRadius: _pressed ? 6 : 22,
                spreadRadius: -4,
                offset: Offset(0, _pressed ? 2 : 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18 * ws),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Background image ──────────────────────────────────────
                Image.asset(d.imagePath, fit: BoxFit.cover),

                // ── Left-side gradient so text is always readable ─────────
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withOpacity(0.55),
                          Colors.black.withOpacity(0.10),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),

                // ── Bottom gradient for depth ──────────────────────────────
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.22),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // ── Shimmer sweep ─────────────────────────────────────────
                AnimatedBuilder(
                  animation: _shimmerCtrl,
                  builder: (_, __) {
                    final val = _shimmerCtrl.value;
                    return Positioned.fill(
                      child: Transform.translate(
                        offset: Offset((val * 2.2 - 0.6) * 420 * ws, 0),
                        child: Container(
                          width: 55 * ws,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(0.10),
                                Colors.white.withOpacity(0.0),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // ── Content overlay (title + chip + button) ───────────────
                Positioned(
                  left: 14 * ws,
                  bottom: 14 * hs,
                  right: 80 * ws,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        d.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17 * ws,
                          color: Colors.white,
                          letterSpacing: 0.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 2 * hs),
                      Text(
                        d.subtitle,
                        style: TextStyle(
                          fontSize: 10 * ws,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8 * hs),
                      Row(
                        children: [
                          // Cal chip
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8 * ws, vertical: 3 * ws),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(10 * ws),
                            ),
                            child: Text(
                              d.chipLabel,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5 * ws,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(width: 7 * ws),
                          // View Plan button
                          GestureDetector(
                            onTap: widget.onViewPlan,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12 * ws, vertical: 4 * ws),
                              decoration: BoxDecoration(
                                color: AppTheme.orange,
                                borderRadius: BorderRadius.circular(10 * ws),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.orange.withOpacity(0.40),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                'View Plan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5 * ws,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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


// ─── Stats Row — 100% LIVE data from providers + HealthService ────────────────
class _StatsRowResponsive extends StatefulWidget {
  final double ws;
  final double hs;

  const _StatsRowResponsive({required this.ws, required this.hs});

  @override
  State<_StatsRowResponsive> createState() => _StatsRowResponsiveState();
}

class _StatsRowResponsiveState extends State<_StatsRowResponsive> {
  int   _steps    = 0;
  int   _calories = 0;
  bool  _loading  = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchSteps();
    // Refresh steps every 30s so home screen stays live
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchSteps());
  }

  Future<void> _fetchSteps() async {
    try {
      await StepCounterService.instance.startService();
      final steps = await HealthService.instance.fetchTodaySteps();
      if (!mounted) return;
      setState(() {
        _steps    = steps;
        _calories = StepCounterService.stepsToCalories(steps);
        _loading  = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmtSteps(int n) {
    if (n == 0) return '—';
    if (n >= 1000) {
      final k = n / 1000;
      return '${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(1)}k';
    }
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final ws = widget.ws;
    final hs = widget.hs;

    return Consumer2<SleepProvider, WaterProvider>(
      builder: (context, sleepProv, waterProv, _) {
        // ── Sleep: format as "6h 45m" or "—" ──────────────────────────────
        final sleepEntry  = sleepProv.todayEntry;
        final hasSleep    = sleepEntry != null && sleepEntry.totalHours > 0;
        final sleepLabel  = hasSleep ? sleepEntry!.durationLabel : '—';

        // ── Water: glasses consumed / goal ────────────────────────────────
        final consumed    = (waterProv.currentIntake / 250).floor();
        final totalGlass  = (waterProv.dailyGoal / 250).round();
        final waterLabel  = waterProv.currentIntake > 0
            ? '$consumed/$totalGlass'
            : '—';

        // ── Steps & Calories ──────────────────────────────────────────────
        final stepsLabel  = _loading ? '…' : _fmtSteps(_steps);
        final calLabel    = _loading ? '…' : (_calories > 0 ? '$_calories' : '—');

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 6 * ws, vertical: 6 * hs),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14 * ws),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10 * ws,
                offset: Offset(0, 2 * hs),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItemCompact(
                icon: Icons.directions_walk,
                iconColor: const Color(0xFF4CAF50),
                value: stepsLabel,
                label: 'Steps',
                ws: ws,
                hs: hs,
              ),
              _StatDividerResponsive(ws: ws, hs: hs),
              _StatItemCompact(
                icon: Icons.local_fire_department,
                iconColor: const Color(0xFFFF7043),
                value: calLabel,
                label: 'Cal Burn.',
                ws: ws,
                hs: hs,
              ),
              _StatDividerResponsive(ws: ws, hs: hs),
              _StatItemCompact(
                icon: Icons.nightlight_round,
                iconColor: const Color(0xFF7C4DFF),
                value: sleepLabel,
                label: 'Sleep',
                ws: ws,
                hs: hs,
              ),
              _StatDividerResponsive(ws: ws, hs: hs),
              _StatItemCompact(
                icon: Icons.water_drop,
                iconColor: const Color(0xFF42A5F5),
                value: waterLabel,
                label: 'Glasses',
                ws: ws,
                hs: hs,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Stat item — Icon on top, bold value, grey label (vertical stack, centered)
class _StatItemCompact extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final double ws;
  final double hs;

  const _StatItemCompact({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.ws,
    required this.hs,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16 * ws, color: iconColor),
          SizedBox(height: 3 * hs),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 11 * ws,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D26),
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 1 * hs),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 7.5 * ws,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF9E9E9E),
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatDividerResponsive extends StatelessWidget {
  final double ws;
  final double hs;

  const _StatDividerResponsive({required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28 * hs,
      width: 1,
      margin: EdgeInsets.symmetric(horizontal: 2 * ws),
      color: const Color(0xFFE5E7EB),
    );
  }
}

// --- Refer & Earn Banner (Responsive) ---
class _ReferEarnBannerResponsive extends StatelessWidget {
  final double ws;
  final double hs;

  const _ReferEarnBannerResponsive({required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HealthRewardsScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        height: 210 * hs,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16 * ws),
          image: const DecorationImage(
            image: AssetImage('assets/images/bg_refer_earn.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16 * ws,
              offset: Offset(0, 6 * hs),
            ),
          ],
          border: Border.all(
            color: Colors.black.withOpacity(0.04),
            width: 1,
          ),
        ),
      ),
    );
  }
}

// --- Premium Stat Section ---
class _PremiumStatSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Color valueColor;
  final Color labelColor;
  final double iconSize;
  final double valueFont;
  final double labelFont;
  final FontWeight iconWeight;

  const _PremiumStatSection({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.valueColor,
    required this.labelColor,
    required this.iconSize,
    required this.valueFont,
    required this.labelFont,
    required this.iconWeight,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final ws = screenWidth / _refW;
    final iconSz = iconSize * ws;
    final valueSz = valueFont * ws;
    final labelSz = labelFont * ws;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10 * ws),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: iconSz),
              SizedBox(width: 14 * ws),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: valueSz,
                    color: valueColor,
                    fontFamily: 'Inter',
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 4 * (MediaQuery.of(context).size.height / _refH)),
          Padding(
            padding: EdgeInsets.only(left: iconSz + 14 * ws - 2 * ws),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: labelSz,
                color: labelColor,
                fontFamily: 'Inter',
                letterSpacing: 0.1,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumStatDivider extends StatelessWidget {
  final double height;
  final Color color;

  const _PremiumStatDivider({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    final hs = MediaQuery.of(context).size.height / _refH;
    return Container(
      width: 1,
      height: height * hs,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      color: color,
      alignment: Alignment.center,
    );
  }
}

class _PremiumStatSectionStrict extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Color valueColor;
  final Color labelColor;

  const _PremiumStatSectionStrict({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.valueColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final ws = screenWidth / _refW;
    final iconSz = 25.0 * ws;
    final valueSz = 18.0 * ws;
    final labelSz = 11.0 * ws;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2 * ws),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: iconSz),
          SizedBox(width: 7 * ws),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: valueSz,
                    color: valueColor,
                    fontFamily: 'Inter',
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3 * (MediaQuery.of(context).size.height / _refH)),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: labelSz,
                    color: labelColor,
                    fontFamily: 'Inter',
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumStatDividerStrict extends StatelessWidget {
  final double height;
  final Color color;

  const _PremiumStatDividerStrict({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    final hs = MediaQuery.of(context).size.height / _refH;
    final ws = MediaQuery.of(context).size.width / _refW;
    return Container(
      width: 1,
      height: height * hs,
      margin: EdgeInsets.symmetric(horizontal: 12 * ws),
      color: color,
      alignment: Alignment.center,
    );
  }
}

class _FixedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _FixedHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_FixedHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

// ─── Explore Services 2x2 Grid ───────────────────────────────────────────────

class _ServiceData {
  final String assetImagePath;
  final String title;
  final String subtitle;
  final Color borderColor;
  final Color arrowColor;
  final Widget destinationScreen;

  const _ServiceData({
    required this.assetImagePath,
    required this.title,
    required this.subtitle,
    required this.borderColor,
    required this.arrowColor,
    required this.destinationScreen,
  });
}

class _ExploreServicesGrid extends StatelessWidget {
  final double ws, hs;

  const _ExploreServicesGrid({required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    final gap = 8.0 * ws;

    final services = [
      _ServiceData(
        assetImagePath: 'assets/images/bg_subscriptions.png',
        title: 'Subscriptions',
        subtitle: 'Weekly & Monthly\nNutritional Bowls',
        borderColor: AppTheme.primaryGreen,
        arrowColor: AppTheme.primaryGreen,
        destinationScreen: const MealPlanScreen(),
      ),
      _ServiceData(
        assetImagePath: 'assets/images/bg_ready_to_eat.png',
        title: 'Ready to Eat',
        subtitle: 'Sugar Free &\nPreservative Free',
        borderColor: const Color(0xFFF59E0B),
        arrowColor: const Color(0xFFF59E0B),
        destinationScreen: const ReadyToEatScreen(),
      ),
      _ServiceData(
        assetImagePath: 'assets/images/bg_trackers.png',
        title: 'Health Trackers',
        subtitle: 'Track Steps, Sleep\n& Nutrition',
        borderColor: const Color(0xFF6366F1),
        arrowColor: const Color(0xFF6366F1),
        destinationScreen: const TrackerScreen(),
      ),
      _ServiceData(
        assetImagePath: 'assets/images/bg_consultations.png',
        title: 'Consultations',
        subtitle: 'Certified Experts\n& Specialist Doctors',
        borderColor: const Color(0xFF8B5CF6),
        arrowColor: const Color(0xFF8B5CF6),
        destinationScreen: const DiabeticCareScreen(),
      ),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _ServiceCard(data: services[0], ws: ws, hs: hs)),
            SizedBox(width: gap),
            Expanded(child: _ServiceCard(data: services[1], ws: ws, hs: hs)),
          ],
        ),
        SizedBox(height: gap),
        Row(
          children: [
            Expanded(child: _ServiceCard(data: services[2], ws: ws, hs: hs)),
            SizedBox(width: gap),
            Expanded(child: _ServiceCard(data: services[3], ws: ws, hs: hs)),
          ],
        ),
      ],
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final _ServiceData data;
  final double ws, hs;

  const _ServiceCard({
    required this.data,
    required this.ws,
    required this.hs,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ws = widget.ws;
    final hs = widget.hs;
    final d = widget.data;
    final imgHeight = 108.0 * hs;

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => d.destinationScreen),
        );
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14 * ws),
            border: Border.all(
              color: d.borderColor.withOpacity(0.55),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: d.borderColor.withOpacity(0.1),
                blurRadius: 14,
                spreadRadius: 0,
                offset: Offset(0, 5 * hs),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: Offset(0, 1 * hs),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Image (padded all sides including top, fully rounded) ────────
              Padding(
                padding: EdgeInsets.fromLTRB(7 * ws, 7 * ws, 7 * ws, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10 * ws),
                    topRight: Radius.circular(10 * ws),
                    bottomLeft: Radius.circular(10 * ws),
                    bottomRight: Radius.circular(10 * ws),
                  ),
                  child: Container(
                    height: imgHeight,
                    width: double.infinity,
                    color: Colors.grey.shade50,
                    child: Image.asset(
                      d.assetImagePath,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 2 * hs),
              // ── Text content ─────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(10 * ws, 8 * hs, 10 * ws, 10 * hs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.title,
                            style: TextStyle(
                              fontSize: 11.5 * ws,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              fontFamily: 'Poppins',
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 3 * hs),
                          Text(
                            d.subtitle,
                            style: TextStyle(
                              fontSize: 9 * ws,
                              color: const Color(0xFF64748B),
                              fontFamily: 'Poppins',
                              height: 1.3,
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 4 * ws),
                    // Arrow circle
                    Container(
                      width: 26 * ws,
                      height: 26 * ws,
                      decoration: BoxDecoration(
                        color: d.arrowColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: d.arrowColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 13 * ws,
                        color: d.arrowColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ─── Plan Card Data Model ─────────────────────────────────────────────────────
class _PlanCardData {
  final String assetImagePath;
  final String price;
  final String priceSuffix;
  final String planName;
  final String subtitle;
  final String? badgeLabel;
  final Color accentColor;
  final Color btnColor;
  final bool isFeatured;
  final IconData tagIcon;
  final Widget destinationScreen;
  final Color cardBgColor;

  const _PlanCardData({
    required this.assetImagePath,
    required this.price,
    required this.priceSuffix,
    required this.planName,
    required this.subtitle,
    required this.badgeLabel,
    required this.accentColor,
    required this.btnColor,
    required this.isFeatured,
    required this.tagIcon,
    required this.destinationScreen,
    this.cardBgColor = Colors.white,
  });
}

// --- Price Badge — full-width, accent color, suffix ---
class _ShinePriceBadge extends StatefulWidget {
  final String price;
  final String priceSuffix;
  final Color accentColor;
  final double ws;
  final double hs;
  final double? height;

  const _ShinePriceBadge({
    required this.price,
    required this.priceSuffix,
    required this.accentColor,
    required this.ws,
    required this.hs,
    this.height,
  });

  @override
  State<_ShinePriceBadge> createState() => _ShinePriceBadgeState();
}

class _ShinePriceBadgeState extends State<_ShinePriceBadge>
    with TickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _scaleCtrl;
  late AnimationController _shineCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _shineAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut),
    );
    _shineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: false);
    _shineAnim = Tween<double>(begin: -1.0, end: 2.2).animate(
      CurvedAnimation(parent: _shineCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _shineCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    setState(() => _pressed = true);
    _scaleCtrl.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(_) {
    setState(() => _pressed = false);
    _scaleCtrl.reverse();
  }

  void _onTapCancel() {
    setState(() => _pressed = false);
    _scaleCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final ws = widget.ws;
    final hs = widget.hs;
    final color = widget.accentColor;
    final darkColor = HSLColor.fromColor(color)
        .withLightness((HSLColor.fromColor(color).lightness - 0.08).clamp(0.0, 1.0))
        .toColor();

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: double.infinity,
          height: widget.height ?? 42 * hs,
          decoration: BoxDecoration(
            color: _pressed ? darkColor : color,
            borderRadius: BorderRadius.circular(10 * ws),
            boxShadow: _pressed
                ? []
                : [
              BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 10,
                spreadRadius: -2,
                offset: Offset(0, 4 * hs),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10 * ws),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      widget.price,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13 * ws,
                        letterSpacing: 0.3,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(width: 2 * ws),
                    Text(
                      widget.priceSuffix,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.80),
                        fontWeight: FontWeight.w500,
                        fontSize: 9 * ws,
                        letterSpacing: 0.1,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                // Shine sweep
                AnimatedBuilder(
                  animation: _shineAnim,
                  builder: (_, __) {
                    return Positioned.fill(
                      child: Transform.translate(
                        offset: Offset(_shineAnim.value * 80 * ws, 0),
                        child: Container(
                          width: 28 * ws,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(0.12),
                                Colors.white.withOpacity(0.0),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
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
      ),
    );
  }
}

// ─── Health Manager Horizontal Scroll Strip ───────────────────────────────────

class _HealthItem {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final Widget destination;

  const _HealthItem({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.destination,
  });
}

class _HealthManagerStrip extends StatelessWidget {
  final double ws, hs;
  const _HealthManagerStrip({required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    final items = [
      _HealthItem(
        icon: Icons.water_drop_rounded,
        iconColor: const Color(0xFFEF4444),
        bgColor: const Color(0xFFFFF1F1),
        label: 'Blood\nGlucose',
        destination: const BloodGlucoseScreen(),
      ),
      _HealthItem(
        icon: Icons.monitor_weight_outlined,
        iconColor: const Color(0xFF3B82F6),
        bgColor: const Color(0xFFEFF6FF),
        label: 'BMI\nCalculator',
        destination: const BmiCalculatorScreen(),
      ),
      _HealthItem(
        icon: Icons.calendar_month_rounded,
        iconColor: const Color(0xFF10B981),
        bgColor: const Color(0xFFECFDF5),
        label: 'My\nVitals',
        destination: const MyVitalsScreen(),
      ),
      _HealthItem(
        icon: Icons.notifications_active_rounded,
        iconColor: const Color(0xFFF59E0B),
        bgColor: const Color(0xFFFFFBEB),
        label: 'Set\nReminders',
        destination: const SetRemindersScreen(),
      ),
      _HealthItem(
        icon: Icons.medication_rounded,
        iconColor: const Color(0xFF8B5CF6),
        bgColor: const Color(0xFFF5F3FF),
        label: 'Insulin\nDosage',
        destination: const InsulinDosageScreen(),
      ),
      _HealthItem(
        icon: Icons.monitor_heart_outlined,
        iconColor: const Color(0xFFEC4899),
        bgColor: const Color(0xFFFDF2F8),
        label: 'Fat\nCalculator',
        destination: const FatCalculatorScreen(),
      ),
    ];

    return SizedBox(
      height: 92 * hs,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 14 * ws),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: 12 * ws),
        itemBuilder: (context, i) {
          final item = items[i];
          return _HealthManagerTile(item: item, ws: ws, hs: hs);
        },
      ),
    );
  }
}

class _HealthManagerTile extends StatefulWidget {
  final _HealthItem item;
  final double ws, hs;

  const _HealthManagerTile({
    required this.item,
    required this.ws,
    required this.hs,
  });

  @override
  State<_HealthManagerTile> createState() => _HealthManagerTileState();
}

class _HealthManagerTileState extends State<_HealthManagerTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ws = widget.ws;
    final hs = widget.hs;
    final item = widget.item;

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => item.destination),
        );
      },
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58 * ws,
              height: 58 * ws,
              decoration: BoxDecoration(
                color: item.bgColor,
                borderRadius: BorderRadius.circular(16 * ws),
                border: Border.all(
                  color: item.iconColor.withOpacity(0.18),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: item.iconColor.withOpacity(_pressed ? 0.06 : 0.14),
                    blurRadius: _pressed ? 4 : 12,
                    offset: Offset(0, _pressed ? 2 : 4 * hs),
                  ),
                ],
              ),
              child: Icon(item.icon, size: 27 * ws, color: item.iconColor),
            ),
            SizedBox(height: 6 * hs),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8.5 * ws,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
                fontFamily: 'Poppins',
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveCoinsBadge extends StatelessWidget {
  final double ws, hs;
  const _LiveCoinsBadge({required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HealthRewardsScreen()),
        );
      },
      child: Consumer<RewardsProvider>(
        builder: (_, rewards, __) {
          final coins = rewards.totalPoints;
          final hasUnclaimed = rewards.allTasksDone && !rewards.claimedToday;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(horizontal: 8 * ws, vertical: 4 * hs),
            decoration: BoxDecoration(
              color: hasUnclaimed
                  ? const Color(0xFFFFECB3)   // brighter — unclaimed reward
                  : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(20 * ws),
              border: hasUnclaimed
                  ? Border.all(color: const Color(0xFFD4A017), width: 1.2)
                  : null,
              boxShadow: hasUnclaimed
                  ? [BoxShadow(
                color: const Color(0xFFD4A017).withOpacity(0.25),
                blurRadius: 6, offset: const Offset(0, 2),
              )]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16 * ws,
                  height: 16 * ws,
                  decoration: BoxDecoration(
                    color: hasUnclaimed
                        ? const Color(0xFFD4A017)
                        : const Color(0xFFFF9800),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      hasUnclaimed ? Icons.star_rounded : Icons.bolt_rounded,
                      size: 10 * ws,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 4 * ws),
                Text(
                  '$coins',
                  style: TextStyle(
                    color: hasUnclaimed
                        ? const Color(0xFFD4A017)
                        : const Color(0xFFE65100),
                    fontSize: 11 * ws,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                if (hasUnclaimed) ...[
                  SizedBox(width: 3 * ws),
                  Container(
                    width: 6 * ws,
                    height: 6 * ws,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}