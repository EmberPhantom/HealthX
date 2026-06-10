import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api/api_service.dart';
import '../theme/theme.dart';

const double _refW = 360.0;
const double _refH = 800.0;

class _C {
  static const Color navy      = Color(0xFF0D2137);
  static const Color navyMid   = Color(0xFF1A3A5C);
  static const Color navyLight = Color(0xFF2563A8);
  static const Color gold      = Color(0xFFD4A017);
  static const Color goldLight = Color(0xFFF5C842);
  static const Color white     = Colors.white;
  static const Color textDark  = Color(0xFF1A1A2E);
  static const Color textMid   = Color(0xFF3D3D5C);
  static const Color textLight = Color(0xFF666680);
}

class CorporateTieUpBowlScreen extends StatefulWidget {
  const CorporateTieUpBowlScreen({super.key});

  @override
  State<CorporateTieUpBowlScreen> createState() =>
      _CorporateTieUpBowlScreenState();
}

class _CorporateTieUpBowlScreenState extends State<CorporateTieUpBowlScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double>  _fadeIn;
  late Animation<Offset>  _slideUp;
  bool _buttonPressed = false;

  Future<void> _handleRefresh() async =>
      Future.delayed(const Duration(milliseconds: 500));

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn  = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final ws = constraints.maxWidth / _refW;
      final hs = MediaQuery.of(context).size.height / _refH;
      return Scaffold(
        body: SafeArea(
          bottom: true,
          child: Column(children: [
            _ScreenHeader(ws: ws, hs: hs),
            Expanded(child: _buildContent(ws, hs, context)),
          ]),
        ),
      );
    });
  }

  // ─── MAIN CONTENT STACK ──────────────────────────────────────────────────
  Widget _buildContent(double ws, double hs, BuildContext context) {
    return Container(
      color: _C.navy,
      child: Stack(children: [
        // 1. Hero background image
        Positioned.fill(
          child: Image.asset(
            'assets/images/bg_corporate_tie_up.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0D2137), Color(0xFF1A3A5C)],
                ),
              ),
            ),
          ),
        ),

        // 2. Fade-to-white gradient
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.18, 0.38, 0.52, 1.0],
                colors: [
                  Colors.black.withOpacity(0.18),
                  Colors.black.withOpacity(0.04),
                  Colors.white.withOpacity(0.55),
                  Colors.white.withOpacity(0.93),
                  Colors.white.withOpacity(0.98),
                ],
              ),
            ),
          ),
        ),

        // 3. Gold accent top-left glow
        Positioned(
          top: 0, left: 0, right: 0,
          height: 260 * hs,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFD4A017).withOpacity(0.13),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // 4. Scrollable foreground
        Column(children: [
          SizedBox(height: 26 * hs),

          // Hero circular avatar image
          Center(
            child: Container(
              width:  158 * ws,
              height: 138 * hs,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(79 * ws),
                border: Border.all(color: _C.gold.withOpacity(0.55), width: 2.5),
                boxShadow: [
                  BoxShadow(color: _C.navyLight.withOpacity(0.22), blurRadius: 22, offset: Offset(0, 10 * hs)),
                  BoxShadow(color: _C.gold.withOpacity(0.14), blurRadius: 14, offset: Offset(0, 4 * hs)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(79 * ws),
                child: Image.asset(
                  'assets/images/bg_corporate_tie_up.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A3A5C), Color(0xFF0D2137)],
                      ),
                    ),
                    child: const Icon(Icons.business_center_rounded, color: Color(0xFFD4A017), size: 48),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 14 * hs),

          Expanded(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: RefreshIndicator(
                  displacement: 20,
                  edgeOffset: 0,
                  color: _C.navyLight,
                  backgroundColor: Colors.white,
                  onRefresh: _handleRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom -
                            189 * hs,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20 * ws),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTitle(ws, hs),
                              SizedBox(height: 10 * hs),
                              _buildPriceBadge(ws, hs),
                              SizedBox(height: 14 * hs),
                              _buildFeatureCards(ws, hs),
                              SizedBox(height: 14 * hs),
                              _buildPartnerSection(ws, hs),
                              SizedBox(height: 14 * hs),
                              _buildWhatsIncluded(ws, hs),
                              SizedBox(height: 12 * hs),
                              _buildNutritionStats(ws, hs),
                              SizedBox(height: 12 * hs),
                              _buildTestimonial(ws, hs),
                              const Spacer(),
                              SizedBox(height: 16 * hs),
                              _buildCTAButton(ws, hs),
                              SizedBox(height: 14 * hs),
                              SizedBox(height: MediaQuery.of(context).padding.bottom),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  // ─── TITLE ───────────────────────────────────────────────────────────────
  // FIX: Flexible on Text prevents overflow. ELITE badge uses shrink-wrap.
  Widget _buildTitle(double ws, double hs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'Corporate Tie-Up Bowl',
                style: GoogleFonts.poppins(
                  fontSize: 20 * ws,
                  fontWeight: FontWeight.w800,
                  color: _C.textDark,
                  letterSpacing: -0.4,
                  height: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            SizedBox(width: 8 * ws),
            // ELITE badge — solid gold, visible, fixed size
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7 * ws, vertical: 3 * hs),
              decoration: BoxDecoration(
                color: _C.gold,
                borderRadius: BorderRadius.circular(6 * ws),
                boxShadow: [
                  BoxShadow(color: _C.gold.withOpacity(0.35), blurRadius: 6, offset: Offset(0, 2 * hs)),
                ],
              ),
              child: Text(
                'ELITE',
                style: GoogleFonts.poppins(
                    fontSize: 7.5 * ws, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.2),
              ),
            ),
          ],
        ),
        SizedBox(height: 3 * hs),
        Text(
          'Monthly Corporate Wellness Plan',
          style: GoogleFonts.poppins(
              fontSize: 12.5 * ws, fontWeight: FontWeight.w500, color: _C.navyLight, height: 1.2),
        ),
      ],
    );
  }

  // ─── PRICE BADGE ─────────────────────────────────────────────────────────
  // FIX: Wrap instead of Row — prevents Team Plans badge from clipping on smaller screens
  Widget _buildPriceBadge(double ws, double hs) {
    return Wrap(
      spacing: 10 * ws,
      runSpacing: 6 * hs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14 * ws, vertical: 7 * hs),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0D2137), Color(0xFF2563A8)]),
            borderRadius: BorderRadius.circular(20 * ws),
            boxShadow: [BoxShadow(color: _C.navy.withOpacity(0.28), blurRadius: 8, offset: Offset(0, 3 * hs))],
          ),
          child: Text(
            '₹999/week',
            style: GoogleFonts.poppins(fontSize: 16 * ws, fontWeight: FontWeight.w700, color: _C.white, letterSpacing: 0.2),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10 * ws, vertical: 6 * hs),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(14 * ws),
            border: Border.all(color: _C.gold.withOpacity(0.45), width: 0.9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.groups_rounded, size: 13 * ws, color: _C.gold),
              SizedBox(width: 5 * ws),
              Text(
                'Team Plans Available',
                style: GoogleFonts.poppins(fontSize: 9.5 * ws, fontWeight: FontWeight.w600, color: _C.gold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── FEATURE CARDS ───────────────────────────────────────────────────────
  Widget _buildFeatureCards(double ws, double hs) {
    return Row(children: [
      Expanded(child: _featureCard(
        icon: Icons.corporate_fare_rounded, iconColor: _C.navyLight, iconBg: const Color(0xFFE8EEF8),
        title: 'Office\nDelivery', subtitle: 'Direct to\nYour Desk', ws: ws, hs: hs,
      )),
      SizedBox(width: 10 * ws),
      Expanded(child: _featureCard(
        icon: Icons.verified_rounded, iconColor: _C.gold, iconBg: const Color(0xFFFFF8E1),
        title: 'Certified\nNutrition', subtitle: 'Expert\nApproved', ws: ws, hs: hs,
      )),
      SizedBox(width: 10 * ws),
      Expanded(child: _featureCard(
        icon: Icons.analytics_rounded, iconColor: _C.navy, iconBg: const Color(0xFFE3E8F0),
        title: 'HR\nReports', subtitle: 'Wellness\nAnalytics', ws: ws, hs: hs,
      )),
    ]);
  }

  Widget _featureCard({
    required IconData icon, required Color iconColor, required Color iconBg,
    required String title, required String subtitle, required double ws, required double hs,
  }) {
    return Container(
      height: 110 * hs,
      padding: EdgeInsets.symmetric(vertical: 8 * hs, horizontal: 5 * ws),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(12 * ws),
        border: Border.all(color: const Color(0xFFE0E4EE), width: 0.8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: Offset(0, 2 * hs))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34 * ws, height: 34 * ws,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10 * ws)),
            child: Icon(icon, color: iconColor, size: 17 * ws),
          ),
          SizedBox(height: 5 * hs),
          Text(title, textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 10 * ws, fontWeight: FontWeight.w700, color: _C.textDark, height: 1.1),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          SizedBox(height: 1 * hs),
          Text(subtitle, textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 8 * ws, fontWeight: FontWeight.w400, color: _C.textLight, height: 1.15),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ─── PARTNER LOGOS ───────────────────────────────────────────────────────
  Widget _buildPartnerSection(double ws, double hs) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14 * ws, vertical: 12 * hs),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF0D2137).withOpacity(0.04), const Color(0xFF2563A8).withOpacity(0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14 * ws),
        border: Border.all(color: const Color(0xFFD0DAF0), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 4 * ws, height: 14 * hs,
              decoration: BoxDecoration(color: _C.gold, borderRadius: BorderRadius.circular(3 * ws)),
            ),
            SizedBox(width: 8 * ws),
            Text('Trusted by 200+ Companies',
                style: GoogleFonts.poppins(fontSize: 12 * ws, fontWeight: FontWeight.w700, color: _C.textDark)),
          ]),
          SizedBox(height: 10 * hs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _partnerBadge(Icons.business_rounded, 'TechCorp', ws, hs),
              _partnerBadge(Icons.account_balance_rounded, 'FinBank', ws, hs),
              _partnerBadge(Icons.local_hospital_rounded, 'MediCare', ws, hs),
              _partnerBadge(Icons.store_rounded, 'RetailX', ws, hs),
            ],
          ),
        ],
      ),
    );
  }

  Widget _partnerBadge(IconData icon, String label, double ws, double hs) {
    return Column(children: [
      Container(
        width: 42 * ws, height: 42 * ws,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11 * ws),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 5, offset: Offset(0, 2 * hs))],
        ),
        child: Icon(icon, color: _C.navyLight, size: 21 * ws),
      ),
      SizedBox(height: 4 * hs),
      Text(label, style: GoogleFonts.poppins(fontSize: 8 * ws, fontWeight: FontWeight.w500, color: _C.textLight)),
    ]);
  }

  // ─── WHAT'S INCLUDED ─────────────────────────────────────────────────────
  Widget _buildWhatsIncluded(double ws, double hs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("What's Included",
            style: GoogleFonts.poppins(fontSize: 13 * ws, fontWeight: FontWeight.w700, color: _C.textDark, letterSpacing: 0.1)),
        SizedBox(height: 8 * hs),
        _includedItem('Bulk meal ordering for your entire team', ws, hs),
        SizedBox(height: 6 * hs),
        _includedItem('Dedicated account manager & support', ws, hs),
        SizedBox(height: 6 * hs),
        _includedItem('Monthly HR wellness reports & analytics', ws, hs),
        SizedBox(height: 6 * hs),
        _includedItem('Custom menus for all dietary preferences', ws, hs),
        SizedBox(height: 6 * hs),
        _includedItem('Priority same-day office delivery', ws, hs),
      ],
    );
  }

  Widget _includedItem(String text, double ws, double hs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18 * ws, height: 18 * ws,
          margin: EdgeInsets.only(top: 1 * hs),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0D2137), Color(0xFF2563A8)]),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, color: Colors.white, size: 11 * ws),
        ),
        SizedBox(width: 8 * ws),
        Expanded(
          child: Text(text,
              style: GoogleFonts.poppins(fontSize: 10.5 * ws, fontWeight: FontWeight.w400, color: _C.textMid, height: 1.3)),
        ),
      ],
    );
  }

  // ─── NUTRITION STATS ─────────────────────────────────────────────────────
  Widget _buildNutritionStats(double ws, double hs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Daily Nutrition Target",
            style: GoogleFonts.poppins(fontSize: 13 * ws, fontWeight: FontWeight.w700, color: _C.textDark, letterSpacing: 0.1)),
        SizedBox(height: 7 * hs),
        Row(children: [
          Expanded(child: _statPill(icon: Icons.local_fire_department_rounded, iconColor: _C.navyLight, label: 'Calories', value: '2,200', ws: ws, hs: hs)),
          SizedBox(width: 8 * ws),
          Expanded(child: _statPill(icon: Icons.egg_rounded, iconColor: _C.navy, label: 'Protein', value: '120g', ws: ws, hs: hs)),
          SizedBox(width: 8 * ws),
          Expanded(child: _statPill(icon: Icons.water_drop_rounded, iconColor: _C.navyLight, label: 'Water', value: '2.5L', ws: ws, hs: hs)),
        ]),
      ],
    );
  }

  Widget _statPill({
    required IconData icon, required Color iconColor,
    required String label, required String value,
    required double ws, required double hs,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 7 * hs, horizontal: 6 * ws),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3FA),
        borderRadius: BorderRadius.circular(10 * ws),
        border: Border.all(color: const Color(0xFFD5DCF0), width: 0.7),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 13 * ws),
          SizedBox(width: 3 * ws),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 7.5 * ws, fontWeight: FontWeight.w500, color: _C.textLight, height: 1.1)),
                Text(value, style: GoogleFonts.poppins(fontSize: 10 * ws, fontWeight: FontWeight.w700, color: _C.textDark, height: 1.2),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TESTIMONIAL CARD (NEW) ───────────────────────────────────────────────
  Widget _buildTestimonial(double ws, double hs) {
    return Container(
      padding: EdgeInsets.all(14 * ws),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0D2137).withOpacity(0.06),
            const Color(0xFFD4A017).withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14 * ws),
        border: Border.all(color: _C.gold.withOpacity(0.22), width: 0.9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34 * ws, height: 34 * ws,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0D2137), Color(0xFF2563A8)]),
              borderRadius: BorderRadius.circular(10 * ws),
            ),
            child: Icon(Icons.format_quote_rounded, color: _C.goldLight, size: 18 * ws),
          ),
          SizedBox(width: 10 * ws),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Our team productivity improved after switching to Corporate Bowl. Delivery is always on time!',
                  style: GoogleFonts.poppins(
                      fontSize: 10 * ws, fontWeight: FontWeight.w400,
                      color: _C.textMid, height: 1.4, fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 6 * hs),
                Row(children: [
                  Container(
                    width: 20 * ws, height: 20 * ws,
                    decoration: BoxDecoration(color: _C.navyLight.withOpacity(0.15), shape: BoxShape.circle),
                    child: Icon(Icons.person_rounded, color: _C.navyLight, size: 12 * ws),
                  ),
                  SizedBox(width: 6 * ws),
                  Flexible(
                    child: Text(
                      'Devikiran Buddica · Lead, TechCorp',
                      style: GoogleFonts.poppins(fontSize: 8.5 * ws, fontWeight: FontWeight.w600, color: _C.navyLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── CTA BUTTON ──────────────────────────────────────────────────────────
  Widget _buildCTAButton(double ws, double hs) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _buttonPressed = true),
      onTapUp:     (_) => setState(() => _buttonPressed = false),
      onTapCancel: ()  => setState(() => _buttonPressed = false),
      onTap: () async {
        HapticFeedback.mediumImpact();
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        final plan = appProvider.mealPlans.firstWhere(
          (p) => p.destination == 'corporate_tie_up_bowl',
          orElse: () => throw Exception('Corporate plan not found'),
        );

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_C.navyLight),
            ),
          ),
        );

        try {
          final response = await ApiService().subscribeToPlan(plan.id);
          Navigator.of(context).pop(); // Dismiss spinner
          
          if (response.isSuccess) {
            _showStartDialog(ws, hs);
          } else {
            _showErrorDialog(ws, hs, response.error ?? 'Subscription failed');
          }
        } catch (e) {
          Navigator.of(context).pop(); // Dismiss spinner
          _showErrorDialog(ws, hs, e.toString());
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 13 * hs),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _buttonPressed
                ? [const Color(0xFF071525), const Color(0xFF0D2137)]
                : [const Color(0xFF0D2137), const Color(0xFF2563A8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(22 * ws),
          boxShadow: [
            BoxShadow(
              color: _C.navy.withOpacity(_buttonPressed ? 0.18 : 0.32),
              blurRadius: _buttonPressed ? 4 : 10,
              offset: Offset(0, _buttonPressed ? 2 : 6),
            ),
          ],
        ),
        transform: _buttonPressed
            ? (Matrix4.identity()..scale(0.97, 0.97))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.business_center_rounded, color: _C.goldLight, size: 16 * ws),
              SizedBox(width: 8 * ws),
              Text('Get Corporate Plan',
                  style: GoogleFonts.poppins(fontSize: 14 * ws, fontWeight: FontWeight.w700, color: _C.white, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── SUCCESS DIALOG ──────────────────────────────────────────────────────
  void _showStartDialog(double ws, double hs) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 34 * ws),
            padding: EdgeInsets.all(22 * ws),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20 * ws),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 18, offset: Offset(0, 8 * hs))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54 * ws, height: 54 * ws,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0D2137), Color(0xFF2563A8)]),
                    borderRadius: BorderRadius.circular(16 * ws),
                  ),
                  child: Icon(Icons.verified_rounded, color: _C.goldLight, size: 30 * ws),
                ),
                SizedBox(height: 14 * hs),
                Text('Welcome to Corporate Bowl!',
                    style: GoogleFonts.poppins(fontSize: 14 * ws, fontWeight: FontWeight.w700, color: _C.textDark),
                    textAlign: TextAlign.center),
                SizedBox(height: 7 * hs),
                Text(
                  'Your corporate wellness journey begins.\nA dedicated manager will reach out shortly!',
                  style: GoogleFonts.poppins(fontSize: 11 * ws, fontWeight: FontWeight.w400, color: _C.textLight, height: 1.5),
                  textAlign: TextAlign.center,
                ),
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
                      gradient: const LinearGradient(colors: [Color(0xFF0D2137), Color(0xFF2563A8)]),
                      borderRadius: BorderRadius.circular(18 * ws),
                    ),
                    child: Center(
                      child: Text("Let's Get Started!",
                          style: GoogleFonts.poppins(fontSize: 13 * ws, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── ERROR DIALOG ────────────────────────────────────────────────────────
  void _showErrorDialog(double ws, double hs, String error) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 34 * ws),
            padding: EdgeInsets.all(22 * ws),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20 * ws),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 18, offset: Offset(0, 8 * hs))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54 * ws, height: 54 * ws,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(16 * ws),
                  ),
                  child: const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 30),
                ),
                SizedBox(height: 14 * hs),
                Text('Subscription Failed',
                    style: GoogleFonts.poppins(fontSize: 14 * ws, fontWeight: FontWeight.w700, color: _C.textDark),
                    textAlign: TextAlign.center),
                SizedBox(height: 7 * hs),
                Text(
                  error,
                  style: GoogleFonts.poppins(fontSize: 11 * ws, fontWeight: FontWeight.w400, color: const Color(0xFFEF4444), height: 1.5),
                  textAlign: TextAlign.center,
                ),
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
                    child: Center(
                      child: Text("Close",
                          style: GoogleFonts.poppins(fontSize: 13 * ws, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
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

// ─── SCREEN HEADER ───────────────────────────────────────────────────────────
class _ScreenHeader extends StatelessWidget {
  final double ws, hs;
  const _ScreenHeader({required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16 * ws, vertical: 8 * hs),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: Offset(0, 2 * hs))],
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            padding: EdgeInsets.all(4 * ws),
            child: Icon(Icons.arrow_back_ios_new, size: 17 * ws, color: const Color(0xFF1A1A1A)),
          ),
        ),
        SizedBox(width: 12 * ws),
        // FIX: Flexible prevents header overflow on any screen width
        Flexible(
          child: Text(
            'Corporate Tie-Up Bowl',
            style: GoogleFonts.poppins(fontSize: 17 * ws, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A), letterSpacing: -0.3),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ]),
    );
  }
}