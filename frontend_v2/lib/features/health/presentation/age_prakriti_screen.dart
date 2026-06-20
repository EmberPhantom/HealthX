import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/prakriti_provider.dart';
import '../../../core/models/prakriti_models.dart';

class AgePrakritiScreen extends ConsumerStatefulWidget {
  const AgePrakritiScreen({super.key});

  @override
  ConsumerState<AgePrakritiScreen> createState() => _AgePrakritiScreenState();
}

class _AgePrakritiScreenState extends ConsumerState<AgePrakritiScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage(int totalSteps) {
    if (_currentStep < totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitQuiz() async {
    HapticFeedback.mediumImpact();
    final success = await ref.read(prakritiProvider.notifier).submitQuiz();
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prakriti assessment submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        final errorMsg = ref.read(prakritiProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg ?? 'Failed to submit assessment'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prakritiState = ref.watch(prakritiProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.secondary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Prakriti Quiz',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
        ),
      ),
      body: prakritiState.isLoading && prakritiState.questions.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _buildBody(prakritiState),
    );
  }

  Widget _buildBody(PrakritiState state) {
    if (state.result != null) {
      return _buildResultsView(state.result!);
    }

    if (state.questions.isNotEmpty) {
      return _buildQuizFlow(state);
    }

    return _buildWelcomeView();
  }

  // Welcome Screen when no result and no quiz in progress
  Widget _buildWelcomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          // Large Ayurvedic illustration style banner
          CustomCard(
            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      PhosphorIconsFill.leaf,
                      color: AppColors.stepsAccent,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Discover Your Prakriti',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Prakriti refers to your unique Ayurvedic mind-body constitution, defined by the balance of three vital energies or Doshas: Vata, Pitta, and Kapha.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'THE THREE DOSHAS',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildDoshaIntroCard(
            'Vata (Air & Ether)',
            'Responsible for movement, creativity, and flow. When balanced, Vatas are energetic and quick. Imbalanced, they experience anxiety, dry skin, and irregular digestion.',
            const Color(0xFF8B5CF6),
            PhosphorIconsRegular.wind,
          ),
          const SizedBox(height: 12),
          _buildDoshaIntroCard(
            'Pitta (Fire & Water)',
            'Responsible for metabolism, digestion, and intellect. Balanced Pittas are focused and passionate. Imbalanced, they become irritable and suffer inflammation or acidity.',
            const Color(0xFFEF4444),
            PhosphorIconsRegular.flame,
          ),
          const SizedBox(height: 12),
          _buildDoshaIntroCard(
            'Kapha (Earth & Water)',
            'Responsible for structure, fluid balance, and immunity. Balanced Kaphas are calm, loving, and strong. Imbalanced, they experience sluggishness, congestion, and weight gain.',
            const Color(0xFF10B981),
            PhosphorIconsRegular.mountains,
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            text: 'START ASSESSMENT',
            onPressed: () async {
              HapticFeedback.lightImpact();
              await ref.read(prakritiProvider.notifier).fetchQuestions();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDoshaIntroCard(String name, String description, Color accentColor, IconData icon) {
    return CustomCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Results Screen when assessment exists
  Widget _buildResultsView(PrakritiAssessmentResult result) {
    // Dominant Dosha profile colors
    Color doshaColor = AppColors.stepsAccent;
    IconData doshaIcon = PhosphorIconsFill.leaf;

    if (result.dominantDosha.startsWith('Vata')) {
      doshaColor = const Color(0xFF8B5CF6);
      doshaIcon = PhosphorIconsFill.wind;
    } else if (result.dominantDosha.startsWith('Pitta')) {
      doshaColor = const Color(0xFFEF4444);
      doshaIcon = PhosphorIconsFill.flame;
    } else if (result.dominantDosha.startsWith('Kapha')) {
      doshaColor = const Color(0xFF10B981);
      doshaIcon = PhosphorIconsFill.mountains;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dominant Profile Title Card
          CustomCard(
            backgroundColor: doshaColor.withValues(alpha: 0.05),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: doshaColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(doshaIcon, color: doshaColor, size: 36),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  result.profile.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  result.profile.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Scores breakdown visual chart
          Text(
            'DOSHA RATIO BREAKDOWN',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          CustomCard(
            child: Column(
              children: [
                _buildDoshaProgressBar('Vata (Air & Ether)', result.scores.vataPct, const Color(0xFF8B5CF6)),
                const SizedBox(height: 16),
                _buildDoshaProgressBar('Pitta (Fire & Water)', result.scores.pittaPct, const Color(0xFFEF4444)),
                const SizedBox(height: 16),
                _buildDoshaProgressBar('Kapha (Earth & Water)', result.scores.kaphaPct, const Color(0xFF10B981)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Recommendations card
          Text(
            'DIET & LIFESTYLE RECOMMENDATIONS',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          CustomCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  PhosphorIconsFill.cookingPot,
                  color: AppColors.stepsAccent,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ayurvedic Guidance',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.profile.advice,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(prakritiProvider.notifier).resetQuiz();
                    ref.read(prakritiProvider.notifier).fetchQuestions();
                    setState(() {
                      _currentStep = 0;
                    });
                  },
                  child: const Text(
                    'RETAKE QUIZ',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDoshaProgressBar(String name, int percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
            ),
            Text(
              '$percentage%',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100.0,
            minHeight: 8,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // Quiz flow Screen
  Widget _buildQuizFlow(PrakritiState state) {
    final totalSteps = state.questions.length;
    final progress = totalSteps > 0 ? (_currentStep + 1) / totalSteps : 0.0;
    final currentQuestion = state.questions[_currentStep];
    final selectedAnswer = state.answers[currentQuestion.id];

    return Column(
      children: [
        // Progress bar at the top
        LinearProgressIndicator(
          value: progress,
          minHeight: 4,
          backgroundColor: Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
        
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalSteps,
            itemBuilder: (context, index) {
              final question = state.questions[index];
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'QUESTION ${index + 1} OF $totalSteps',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.textSecondary,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '${((index) / totalSteps * 100).round()}% Completed',
                          style: const TextStyle(color: AppColors.neutral, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      question.text,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Options List
                    ...question.options.map((opt) {
                      final isSelected = state.answers[question.id] == opt.key;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref.read(prakritiProvider.notifier).selectAnswer(question.id, opt.key);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: CustomCard(
                            backgroundColor: isSelected 
                                ? AppColors.primary.withValues(alpha: 0.06) 
                                : AppColors.cardBackground,
                            borderSide: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    opt.text,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: AppColors.textPrimary,
                                          height: 1.4,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.neutral.withValues(alpha: 0.4),
                                      width: 2,
                                    ),
                                    color: isSelected ? AppColors.primary : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          PhosphorIconsBold.check,
                                          color: AppColors.secondary,
                                          size: 12,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),

        // Navigation Footer
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: const BoxDecoration(
            color: AppColors.tertiary,
            border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                if (_currentStep > 0) ...[
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _prevPage,
                      child: const Icon(
                        PhosphorIconsRegular.arrowLeft,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    text: _currentStep == totalSteps - 1 ? 'SUBMIT ASSESSMENT' : 'CONTINUE',
                    onPressed: selectedAnswer != null
                        ? () {
                            if (_currentStep == totalSteps - 1) {
                              _submitQuiz();
                            } else {
                              _nextPage(totalSteps);
                            }
                          }
                        : null,
                    isLoading: _currentStep == totalSteps - 1 ? state.isLoading : false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
