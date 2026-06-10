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

class ZYMBowlApp extends StatelessWidget {
  const ZYMBowlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GYMBowl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      ),
      home: const ZYMBowlScreen(),
    );
  }
}

class _C {
  static const Color greenDark = Color(0xFF1B5E20);
  static const Color white = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textMid = Color(0xFF444444);
  static const Color textLight = Color(0xFF666666);
}

class ZYMBowlScreen extends StatefulWidget {
  const ZYMBowlScreen({super.key});

  @override
  State<ZYMBowlScreen> createState() => _ZYMBowlScreenState();
}

class _ZYMBowlScreenState extends State<ZYMBowlScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  bool _buttonPressed = false;

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ws = constraints.maxWidth / _refW;
        final hs = MediaQuery.of(context).size.height / _refH;
        return Scaffold(
          body: SafeArea(
            bottom: true,
            child: Column(
              children: [
                _ScreenHeader(title: 'GYMBowl', ws: ws, hs: hs),
                Expanded(child: _buildContent(ws, hs)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(double ws, double hs) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1A1A1A),
      child: Stack(
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?q=80&w=1000&auto=format&fit=crop',
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2E3A2E), Color(0xFF1A2A1A)]))),
              errorWidget: (_, __, ___) => Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2E3A2E), Color(0xFF1A2A1A)]))),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  stops: const [0.0, 0.25, 0.42, 0.55, 1.0],
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.05),
                    Colors.white.withOpacity(0.55),
                    Colors.white.withOpacity(0.92),
                    Colors.white.withOpacity(0.97),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            height: 300 * hs,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [const Color(0xFF3E6B48).withOpacity(0.18), Colors.transparent],
                ),
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(height: 30 * hs),
              Center(
                child: Container(
                  width: 170 * ws,
                  height: 145 * hs,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(85 * ws),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 18, offset: Offset(0, 8 * hs))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(85 * ws),
                    child: CachedNetworkImage(
                      imageUrl: 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?q=80&w=1000&auto=format&fit=crop',
                      fit: BoxFit.cover,
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
                      color: AppTheme.primaryGreen,
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
                                  _buildWhatsIncluded(ws, hs),
                                  SizedBox(height: 12 * hs),
                                  _buildTodaysFocus(ws, hs),
                                  const Spacer(),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(double ws, double hs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('GYMBowl', style: GoogleFonts.poppins(fontSize: 24 * ws, fontWeight: FontWeight.w800, color: _C.textDark, letterSpacing: -0.5, height: 1.2)),
        SizedBox(height: 2 * hs),
        Text('Monthly Fitness Plan', style: GoogleFonts.poppins(fontSize: 13 * ws, fontWeight: FontWeight.w500, color: _C.greenDark, height: 1.2)),
      ],
    );
  }

  Widget _buildPriceBadge(double ws, double hs) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14 * ws, vertical: 7 * hs),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_C.greenDark, Color(0xFF388E3C)]),
        borderRadius: BorderRadius.circular(20 * ws),
        boxShadow: [BoxShadow(color: _C.greenDark.withOpacity(0.25), blurRadius: 8, offset: Offset(0, 3 * hs))],
      ),
      child: Text('₹3,699/month', style: GoogleFonts.poppins(fontSize: 16 * ws, fontWeight: FontWeight.w700, color: _C.white, letterSpacing: 0.2)),
    );
  }

  Widget _buildFeatureCards(double ws, double hs) {
    return Row(
      children: [
        Expanded(child: _featureCard(icon: Icons.restaurant, iconColor: const Color(0xFF2E7D32), iconBg: const Color(0xFFE8F5E9), title: 'Muscle\nMeals', subtitle: 'High Protein\nRecipes', ws: ws, hs: hs)),
        SizedBox(width: 10 * ws),
        Expanded(child: _featureCard(icon: Icons.fitness_center, iconColor: const Color(0xFF388E3C), iconBg: const Color(0xFFDCEDC8), title: 'Workout\nPlans', subtitle: 'Gym Routines\nIncluded', ws: ws, hs: hs)),
        SizedBox(width: 10 * ws),
        Expanded(child: _featureCard(icon: Icons.trending_up, iconColor: const Color(0xFF1B5E20), iconBg: const Color(0xFFC8E6C9), title: 'Progress\nTracker', subtitle: 'Track Your\nGains', ws: ws, hs: hs)),
      ],
    );
  }

  Widget _featureCard({required IconData icon, required Color iconColor, required Color iconBg, required String title, required String subtitle, required double ws, required double hs}) {
    return Container(
      height: 110 * hs,
      padding: EdgeInsets.symmetric(vertical: 8 * hs, horizontal: 5 * ws),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12 * ws),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.8),
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
          Text(title, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 10 * ws, fontWeight: FontWeight.w700, color: _C.textDark, height: 1.1), maxLines: 2, overflow: TextOverflow.ellipsis),
          SizedBox(height: 1 * hs),
          Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 8 * ws, fontWeight: FontWeight.w400, color: _C.textLight, height: 1.15), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildWhatsIncluded(double ws, double hs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("What's Included", style: GoogleFonts.poppins(fontSize: 13 * ws, fontWeight: FontWeight.w700, color: _C.textDark, letterSpacing: 0.1)),
        SizedBox(height: 8 * hs),
        _includedItem('Weekly Meal Plans tailored to your needs', ws, hs),
        SizedBox(height: 6 * hs),
        _includedItem('Custom workout routines from experts', ws, hs),
        SizedBox(height: 6 * hs),
        _includedItem('Personalized nutrition guidance', ws, hs),
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
          decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle),
          child: Icon(Icons.check, color: Colors.white, size: 12 * ws),
        ),
        SizedBox(width: 8 * ws),
        Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 10.5 * ws, fontWeight: FontWeight.w400, color: _C.textMid, height: 1.25))),
      ],
    );
  }

  Widget _buildTodaysFocus(double ws, double hs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's Focus", style: GoogleFonts.poppins(fontSize: 13 * ws, fontWeight: FontWeight.w700, color: _C.textDark, letterSpacing: 0.1)),
        SizedBox(height: 7 * hs),
        Row(
          children: [
            Expanded(child: _focusPill(icon: Icons.local_fire_department_rounded, iconColor: const Color(0xFF43A047), label: 'Calories', value: '2,500', ws: ws, hs: hs)),
            SizedBox(width: 8 * ws),
            Expanded(child: _focusPill(icon: Icons.set_meal_rounded, iconColor: const Color(0xFF2E7D32), label: 'Protein', value: '180g', ws: ws, hs: hs)),
            SizedBox(width: 8 * ws),
            Expanded(child: _focusPill(icon: Icons.water_drop_rounded, iconColor: const Color(0xFF43A047), label: 'Water', value: '2L', ws: ws, hs: hs)),
          ],
        ),
      ],
    );
  }

  Widget _focusPill({required IconData icon, required Color iconColor, required String label, required String value, required double ws, required double hs}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 7 * hs, horizontal: 6 * ws),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6F0),
        borderRadius: BorderRadius.circular(10 * ws),
        border: Border.all(color: const Color(0xFFD5E8D5), width: 0.7),
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
                Text(value, style: GoogleFonts.poppins(fontSize: 10 * ws, fontWeight: FontWeight.w700, color: _C.textDark, height: 1.2), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTAButton(double ws, double hs) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _buttonPressed = true),
      onTapUp: (_) => setState(() => _buttonPressed = false),
      onTapCancel: () => setState(() => _buttonPressed = false),
      onTap: () async {
        HapticFeedback.mediumImpact();
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        final plan = appProvider.mealPlans.firstWhere(
          (p) => p.destination == 'zym_bowl',
          orElse: () => throw Exception('GYMBowl plan not found'),
        );
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B5E20)),
            ),
          ),
        );

        try {
          final response = await ApiService().subscribeToPlan(plan.id);
          Navigator.of(context).pop(); // Dismiss spinner
          
          if (response.isSuccess) {
            _showStartDialog(ws, hs, plan.name);
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
        padding: EdgeInsets.symmetric(vertical: 12 * hs),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _buttonPressed ? [const Color(0xFF145218), const Color(0xFF2E7D32)] : [const Color(0xFF1B5E20), const Color(0xFF388E3C)],
            begin: Alignment.centerLeft, end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(22 * ws),
          boxShadow: [BoxShadow(color: _C.greenDark.withOpacity(_buttonPressed ? 0.2 : 0.35), blurRadius: _buttonPressed ? 4 : 10, offset: Offset(0, _buttonPressed ? 2 : 6))],
        ),
        transform: _buttonPressed ? (Matrix4.identity()..scale(0.97, 0.97)) : Matrix4.identity(),
        transformAlignment: Alignment.center,
        child: Center(child: Text('Start GYMBowl Plan', style: GoogleFonts.poppins(fontSize: 14 * ws, fontWeight: FontWeight.w700, color: _C.white, letterSpacing: 0.5))),
      ),
    );
  }

  void _showStartDialog(double ws, double hs, String planName) {
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 18, offset: Offset(0, 8 * hs))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54 * ws, height: 54 * ws,
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(16 * ws)),
                child: Icon(Icons.check_circle_rounded, color: const Color(0xFF43A047), size: 32 * ws),
              ),
              SizedBox(height: 14 * hs),
              Text('Welcome to GYMBowl!', style: GoogleFonts.poppins(fontSize: 15 * ws, fontWeight: FontWeight.w700, color: _C.textDark), textAlign: TextAlign.center),
              SizedBox(height: 7 * hs),
              Text("Your subscription to $planName is active.\nLet's crush your fitness goals!", style: GoogleFonts.poppins(fontSize: 11 * ws, fontWeight: FontWeight.w400, color: _C.textLight, height: 1.5), textAlign: TextAlign.center),
              SizedBox(height: 16 * hs),
              GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop(); // Go back to subscriptions list
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 11 * hs),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF388E3C)]),
                    borderRadius: BorderRadius.circular(18 * ws),
                  ),
                  child: Center(child: Text("Let's Go!", style: GoogleFonts.poppins(fontSize: 13 * ws, fontWeight: FontWeight.w600, color: Colors.white))),
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
                child: Icon(Icons.error_outline_rounded, color: const Color(0xFFEF4444), size: 32 * ws),
              ),
              SizedBox(height: 14 * hs),
              Text('Subscription Failed', style: GoogleFonts.poppins(fontSize: 15 * ws, fontWeight: FontWeight.w700, color: _C.textDark), textAlign: TextAlign.center),
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