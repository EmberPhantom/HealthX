import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/theme.dart';
import '../services/api/api_service.dart';
import 'login_screen.dart';

const double _refW = 360.0;
const double _refH = 800.0;

// Dummy StepProgressIndicator for demonstration
class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const StepProgressIndicator({required this.currentStep, required this.totalSteps, super.key});

  @override
  Widget build(BuildContext context) {
    final ws = MediaQuery.of(context).size.width / _refW;
    final hs = MediaQuery.of(context).size.height / _refH;
    return Row(
      children: List.generate(
        totalSteps,
            (i) => Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 2 * ws),
            height: 5 * hs,
            decoration: BoxDecoration(
              color: i <= currentStep ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(3 * ws),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Goal model
// ─────────────────────────────────────────────────────────────────────────────
class Goal {
  final int id;
  final String title;
  final String imageUrl;       // male image path
  final String femaleImageUrl; // female image path
  final bool isSelected;
  final bool isBanner;

  Goal({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.femaleImageUrl,
    required this.isSelected,
    this.isBanner = false,
  });

  Goal copyWith({bool? isSelected}) => Goal(
    id: id,
    title: title,
    imageUrl: imageUrl,
    femaleImageUrl: femaleImageUrl,
    isSelected: isSelected ?? this.isSelected,
    isBanner: isBanner,
  );

  /// Returns the correct asset path based on gender
  String resolvedImage(bool isFemale) =>
      isFemale ? femaleImageUrl : imageUrl;
}

// ─────────────────────────────────────────────────────────────────────────────
//  OnboardingProvider
// ─────────────────────────────────────────────────────────────────────────────
class OnboardingProvider extends ChangeNotifier {
  final List<Goal> goals = [
    Goal(
      id: 1,
      title: 'Lose Weight',
      imageUrl: 'asset:assets/images/lose_weight.png',
      femaleImageUrl: 'asset:assets/images/f_lose_weight.png',
      isSelected: false,
    ),
    Goal(
      id: 2,
      title: 'Build Muscle',
      imageUrl: 'asset:assets/images/build_muscle.png',
      femaleImageUrl: 'asset:assets/images/f_build_muscle.png',
      isSelected: false,
    ),
    Goal(
      id: 3,
      title: 'Eat Healthier',
      imageUrl: 'asset:assets/images/eat_healthier.png',
      femaleImageUrl: 'asset:assets/images/f_eat_healthier.png',
      isSelected: false,
    ),
    Goal(
      id: 4,
      title: 'Improve Sleep',
      imageUrl: 'asset:assets/images/improve_sleep.png',
      femaleImageUrl: 'asset:assets/images/f_improve_sleep.png',
      isSelected: false,
    ),
    Goal(
      id: 5,
      title: 'Reduce Stress',
      imageUrl: 'asset:assets/images/reduce_stress.png',
      femaleImageUrl: 'asset:assets/images/f_reduce_stress.png',
      isSelected: false,
    ),
    Goal(
      id: 6,
      title: 'Increase Fertility',
      imageUrl: 'asset:assets/images/increase_fertility.png',
      femaleImageUrl: 'asset:assets/images/f_increase_fertility.png',
      isSelected: false,
    ),
    Goal(
      id: 7,
      title: 'Strengthen Joints',
      imageUrl: 'asset:assets/images/strengthen_joints_bones.png',
      femaleImageUrl: 'asset:assets/images/f_strengthen_joints_bones.png',
      isSelected: false,
    ),
    Goal(
      id: 8,
      title: 'Manage Fatty Liver',
      imageUrl: 'asset:assets/images/manage_fatty_liver.png',
      femaleImageUrl: 'asset:assets/images/f_manage_fatty_liver.png',
      isSelected: false,
    ),
    Goal(
      id: 9,
      title: 'Ease Constipation',
      imageUrl: 'asset:assets/images/ease_constipation.png',
      femaleImageUrl: 'asset:assets/images/f_ease_constipation.png',
      isSelected: false,
    ),
    Goal(
      id: 10,
      title: 'Yoga & Pranayama',
      imageUrl: 'asset:assets/images/yoga_pranayama.png',
      femaleImageUrl: 'asset:assets/images/f_yoga_pranayama.png',
      isSelected: false,
    ),
    Goal(
      id: 11,
      title: 'Manage Cholesterol',
      imageUrl: 'asset:assets/images/manage_cholesterol.png',
      femaleImageUrl: 'asset:assets/images/f_manage_cholesterol.png',
      isSelected: false,
    ),
    Goal(
      id: 12,
      title: 'Manage Diabetes',
      imageUrl: 'asset:assets/images/manage_diabetes.png',
      femaleImageUrl: 'asset:assets/images/f_manage_diabetes.png',
      isSelected: false,
    ),
    Goal(
      id: 13,
      title: 'Increase Energy',
      imageUrl: 'asset:assets/images/increase_energy.png',
      femaleImageUrl: 'asset:assets/images/f_increase_energy.png',
      isSelected: false,
    ),
    Goal(
      id: 14,
      title: 'Relieve Gastric Discomfort',
      imageUrl: 'asset:assets/images/relieve_gastric_discomfort.png',
      femaleImageUrl: 'asset:assets/images/f_relieve_gastric_discomfort.png',
      isSelected: false,
    ),
    Goal(
      id: 15,
      title: 'Overall Fitness',
      imageUrl: 'asset:assets/images/oveerall_fitness.png',
      femaleImageUrl: 'asset:assets/images/f_oveerall_fitness.png',
      isSelected: false,
      isBanner: true,
    ),
  ];

  int get selectedGoalCount => goals.where((g) => g.isSelected).length;

  void toggleGoal(int id) {
    final idx = goals.indexWhere((g) => g.id == id);
    if (idx == -1) return;
    if (!goals[idx].isSelected && selectedGoalCount >= 3) return;
    goals[idx] = goals[idx].copyWith(isSelected: !goals[idx].isSelected);
    notifyListeners();
  }

  double _weight = 70;
  double _height = 170;
  int _activityLevel = 2;

  double get weight => _weight;
  set weight(double v) { _weight = v; notifyListeners(); }

  double get height => _height;
  set height(double v) { _height = v; notifyListeners(); }

  int get activityLevel => _activityLevel;
  set activityLevel(int v) { _activityLevel = v; notifyListeners(); }

  int? _yearOfBirth;
  int? get yearOfBirth => _yearOfBirth;
  set yearOfBirth(int? val) { _yearOfBirth = val; notifyListeners(); }

  int? get calculatedAge =>
      _yearOfBirth != null ? DateTime.now().year - _yearOfBirth! : null;
}

// ─────────────────────────────────────────────────────────────────────────────
//  WellnessGoalsScreen
// ─────────────────────────────────────────────────────────────────────────────
class WellnessGoalsScreen extends StatefulWidget {
  final VoidCallback onNext;

  /// Pass true when user selected Female on the login screen.
  final bool isFemale;

  const WellnessGoalsScreen({
    super.key,
    required this.onNext,
    this.isFemale = false,
  });

  @override
  State<WellnessGoalsScreen> createState() => _WellnessGoalsScreenState();
}

class _WellnessGoalsScreenState extends State<WellnessGoalsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final ws = screenWidth / _refW;
    final hs = screenHeight / _refH;
    final crossAxisCount = screenWidth > 800 ? 3 : 2;
    final padding = screenWidth < 600 ? 16.0 * ws : 24.0 * ws;

    final gridGoals = provider.goals.where((g) => !g.isBanner).toList();
    final bannerGoals = provider.goals.where((g) => g.isBanner).toList();
    final Goal? bannerGoal = bannerGoals.isNotEmpty ? bannerGoals.first : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFB),
        body: SafeArea(
          child: FadeTransition(
            opacity: _entryController,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(padding, 16 * hs, padding, 8 * hs),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Health Goals',
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth < 600 ? 20 * ws : 24 * ws,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 8 * hs),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12 * ws, vertical: 6 * hs),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20 * ws),
                              ),
                              child: Text(
                                'Select up to 3',
                                style: GoogleFonts.inter(
                                  fontSize: 13 * ws,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Selection count
                      Container(
                        padding: EdgeInsets.all(12 * ws),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2), width: 1.5),
                        ),
                        child: Text(
                          '${provider.selectedGoalCount}/3',
                          style: GoogleFonts.poppins(
                            fontSize: 16 * ws,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Goals Grid
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.all(padding),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              final g = gridGoals[index];
                              return _GoalCard(
                                key: ValueKey(g.id),
                                goal: g,
                                isFemale: widget.isFemale,
                                delay: index * 80,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  provider.toggleGoal(g.id);
                                },
                              );
                            },
                            childCount: gridGoals.length,
                          ),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.35,
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(child: SizedBox(height: 4 * hs)),

                      if (bannerGoal != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: padding),
                            child: _BannerCard(
                              key: ValueKey(bannerGoal.id),
                              goal: bannerGoal,
                              isFemale: widget.isFemale,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                provider.toggleGoal(bannerGoal.id);
                              },
                            ),
                          ),
                        ),

                      SliverToBoxAdapter(child: SizedBox(height: 16 * hs)),
                    ],
                  ),
                ),

                // Footer
                Container(
                  padding: EdgeInsets.fromLTRB(padding * 0.6, 12 * hs, padding * 0.6, 16 * hs),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: const Border(top: BorderSide(color: Color(0xFFEEF1F5), width: 1.0)),
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(0, -2),
                        blurRadius: 12,
                        color: Colors.black.withOpacity(0.04),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const StepProgressIndicator(currentStep: 0, totalSteps: 4),
                      SizedBox(height: 16 * hs),
                      SizedBox(
                        width: double.infinity,
                        height: 52 * hs,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: provider.selectedGoalCount > 0 ? 1.0 : 0.5,
                          child: ElevatedButton(
                            onPressed: provider.selectedGoalCount > 0
                                ? () async {
                              HapticFeedback.lightImpact();
                              
                              // Save goals to backend
                              final selectedGoalTitles = provider.goals
                                  .where((g) => g.isSelected)
                                  .map((g) => g.title)
                                  .toList();
                              
                              try {
                                await ApiService().updateWellnessGoals(selectedGoalTitles);
                              } catch (e) {
                                debugPrint('Error saving wellness goals: $e');
                              }

                              widget.onNext();
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14 * (screenWidth / _refW)),
                              ),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF047857)],
                                ),
                                borderRadius: BorderRadius.circular(14 * (screenWidth / _refW)),
                              ),
                              child: Container(
                                width: double.infinity,
                                height: 52 * hs,
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Continue',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16 * (screenWidth / _refW),
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    SizedBox(width: 10 * (screenWidth / _refW)),
                                    Container(
                                      width: 28 * (screenWidth / _refW),
                                      height: 28 * (screenWidth / _refW),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(8 * (screenWidth / _refW)),
                                      ),
                                      child: Icon(Icons.arrow_forward_rounded,
                                          size: 15 * (screenWidth / _refW), color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
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

// ─────────────────────────────────────────────────────────────────────────────
//  _GoalCard
// ─────────────────────────────────────────────────────────────────────────────
class _GoalCard extends StatefulWidget {
  final Goal goal;
  final bool isFemale;
  final int delay;
  final VoidCallback onTap;

  const _GoalCard({
    Key? key,
    required this.goal,
    required this.isFemale,
    required this.delay,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> with TickerProviderStateMixin {
  late final AnimationController _selectController;
  late final AnimationController _shineController;
  Animation<double>? _selectScale;

  @override
  void initState() {
    super.initState();
    _selectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _selectScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _selectController, curve: Curves.elasticOut),
    );

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.goal.isSelected) {
      _selectController.value = 1.0;
      _shineController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _GoalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.goal.isSelected && !oldWidget.goal.isSelected) {
      _selectController.forward(from: 0);
      _shineController.repeat();
    } else if (!widget.goal.isSelected && oldWidget.goal.isSelected) {
      _selectController.reverse();
      _shineController.stop();
      _shineController.reset();
    }
  }

  @override
  void dispose() {
    _selectController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = MediaQuery.of(context).size.width / _refW;
    final hs = MediaQuery.of(context).size.height / _refH;
    final isSelected = widget.goal.isSelected;
    final Animation<double> selectScale =
        _selectScale ?? AlwaysStoppedAnimation(isSelected ? 1.0 : 0.0);

    // Resolve image based on gender
    final resolvedImage = widget.goal.resolvedImage(widget.isFemale);
    final isAsset = resolvedImage.startsWith('asset:');
    final imagePath = isAsset ? resolvedImage.substring('asset:'.length) : resolvedImage;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16 * ws),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primaryGreen.withOpacity(0.25)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 16 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isSelected ? 13 * ws : 16 * ws),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              if (isAsset)
                Image.asset(imagePath, fit: BoxFit.cover)
              else
                CachedNetworkImage(
                  imageUrl: imagePath,
                  fit: BoxFit.cover,
                  placeholder: (ctx, url) => Container(
                    color: AppTheme.bgLight,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ),
                  errorWidget: (ctx, url, err) => Container(
                    color: AppTheme.bgLight,
                    child: const Icon(Icons.spa, color: Color(0xFF10B981), size: 40),
                  ),
                ),

              // Bottom gradient for checkmark visibility
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(isSelected ? 0.38 : 0.18),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),

              // Shine sweep overlay (only when selected)
              if (isSelected)
                AnimatedBuilder(
                  animation: _shineController,
                  builder: (context, _) {
                    final t = _shineController.value;
                    final double pos = -1.2 + 3.4 * t;
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(pos - 0.6, -1),
                          end: Alignment(pos + 0.6, 1),
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.22),
                            Colors.white.withOpacity(0.0),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    );
                  },
                ),

              // Bottom-left checkmark
              if (isSelected)
                Positioned(
                  bottom: 10 * hs,
                  left: 10 * ws,
                  child: ScaleTransition(
                    scale: selectScale,
                    child: Container(
                      width: 30 * ws,
                      height: 30 * ws,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryGreen,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 17 * ws,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _BannerCard
// ─────────────────────────────────────────────────────────────────────────────
class _BannerCard extends StatefulWidget {
  final Goal goal;
  final bool isFemale;
  final VoidCallback onTap;
  const _BannerCard({Key? key, required this.goal, required this.isFemale, required this.onTap}) : super(key: key);

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard> with TickerProviderStateMixin {
  late final AnimationController _shimmerController;
  AnimationController? _selectController;
  Animation<double>? _selectScale;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _selectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _selectScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _selectController!, curve: Curves.elasticOut),
    );
    if (widget.goal.isSelected) {
      _selectController?.value = 1.0;
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _BannerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectController != null) {
      if (widget.goal.isSelected && !oldWidget.goal.isSelected) {
        _selectController!.forward(from: 0);
        _shimmerController.repeat();
      } else if (!widget.goal.isSelected && oldWidget.goal.isSelected) {
        _selectController!.reverse();
        _shimmerController.stop();
        _shimmerController.reset();
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _selectController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = MediaQuery.of(context).size.width / _refW;
    final hs = MediaQuery.of(context).size.height / _refH;
    final isSelected = widget.goal.isSelected;
    final Animation<double> bannerSelectScale =
        _selectScale ?? AlwaysStoppedAnimation(isSelected ? 1.0 : 0.0);

    // Resolve image based on gender
    final resolvedImage = widget.goal.resolvedImage(widget.isFemale);
    final isAsset = resolvedImage.startsWith('asset:');
    final imagePath = isAsset ? resolvedImage.substring('asset:'.length) : resolvedImage;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6 * hs),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16 * ws),
            border: Border.all(
              color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppTheme.primaryGreen.withOpacity(0.12)
                    : Colors.black.withOpacity(0.04),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AspectRatio(
            aspectRatio: 3 / 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isSelected ? 13 * ws : 16 * ws),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isAsset)
                    Image.asset(imagePath, fit: BoxFit.cover)
                  else
                    CachedNetworkImage(
                      imageUrl: imagePath,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) =>
                          Container(color: AppTheme.bgLight),
                      errorWidget: (ctx, url, err) =>
                          Container(color: AppTheme.bgLight),
                    ),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withOpacity(0.68),
                          Colors.black.withOpacity(0.28),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),

                  if (isSelected)
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, _) {
                        final t = _shimmerController.value;
                        final double pos = -1.2 + 3.4 * t;
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(pos - 0.6, -1),
                              end: Alignment(pos + 0.6, 1),
                              colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(0.20),
                                Colors.white.withOpacity(0.0),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        );
                      },
                    ),

                  Positioned(
                    bottom: 12 * hs,
                    left: 12 * ws,
                    child: ScaleTransition(
                      scale: bannerSelectScale,
                      child: Container(
                        width: 32 * ws,
                        height: 32 * ws,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryGreen,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withOpacity(0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 18 * ws,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}