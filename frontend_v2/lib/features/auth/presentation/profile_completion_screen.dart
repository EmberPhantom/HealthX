import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';
import '../../health/services/ai_health_service.dart';
import '../../health/providers/ai_health_provider.dart';

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends ConsumerState<ProfileCompletionScreen> {
  final PageController _pageController = PageController();
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  int _currentPage = 0;
  String? _selectedGender;
  String _selectedAvatar = 'https://images.unsplash.com/photo-1544816155-12df9643f363?fit=crop&w=150&h=150'; // Panda
  DateTime? _selectedDate;

  // Step 2: Biometrics & Activity
  int _selectedActivity = 2; // Default: Moderately Active
  final List<Map<String, dynamic>> _activityOptions = [
    {
      'title': 'Sedentary',
      'desc': 'Little or no exercise. Desk job, mostly sitting.',
      'icon': PhosphorIconsRegular.coffee,
    },
    {
      'title': 'Lightly Active',
      'desc': 'Light exercise 1-3 days/week. Walks, light chores.',
      'icon': PhosphorIconsRegular.personSimpleWalk,
    },
    {
      'title': 'Moderately Active',
      'desc': 'Brisk exercise 3-5 days/week. Active lifestyle.',
      'icon': PhosphorIconsRegular.personSimpleRun,
    },
    {
      'title': 'Very Active',
      'desc': 'Hard exercise 6-7 days/week. Gym, sports, cycling.',
      'icon': PhosphorIconsRegular.barbell,
    },
    {
      'title': 'Extremely Active',
      'desc': 'Heavy physical work/athlete-level training daily.',
      'icon': PhosphorIconsRegular.lightning,
    },
  ];

  // Step 3: Conditions & Allergies
  bool _isDiabetesPatient = false;
  bool _isBpPatient = false;
  final Set<String> _selectedAllergies = {};
  final List<String> _allergyOptions = [
    'Milk (Dairy)', 'Peanuts', 'Tree Nuts', 'Soy', 'Wheat', 'Eggs', 'Fish', 'Shellfish'
  ];

  // Step 4: Health Goals & Ayurvedic Prakriti
  final Set<String> _selectedGoals = {};
  final List<String> _goalsOptions = [
    'Lose Weight', 'Build Muscle', 'Eat Healthier', 'Improve Sleep', 'Reduce Stress', 'Manage Diabetes', 'Overall Fitness'
  ];

  String? _selectedDosha;
  final List<Map<String, String>> _doshaOptions = [
    {'title': 'Vata', 'desc': 'Light, energetic, creative (Air/Ether)'},
    {'title': 'Pitta', 'desc': 'Fiery, sharp, focused, ambitious (Fire/Water)'},
    {'title': 'Kapha', 'desc': 'Steady, calm, steady, strong (Earth/Water)'},
    {'title': 'Tridoshic', 'desc': 'Perfect balance of Vata, Pitta, and Kapha'},
  ];

  // Step 5: AI-generated health questions
  final Map<String, dynamic> _step5Answers = {}; // questionId → answer
  bool _step5QuestionsLoaded = false;

  final List<String> _avatars = [
    'https://images.unsplash.com/photo-1544816155-12df9643f363?fit=crop&w=150&h=150', // Cute Panda
    'https://images.unsplash.com/photo-1513836279014-a89f7a76ae86?fit=crop&w=150&h=150', // Stylized Fox
    'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?fit=crop&w=150&h=150', // Cute Cat
    'https://images.unsplash.com/photo-1543466835-00a7907e9de1?fit=crop&w=150&h=150', // Cute Dog
    'https://images.unsplash.com/photo-1507666480058-863390B1a881?fit=crop&w=150&h=150', // Cute Squirrel
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null && user.phone.isNotEmpty) {
        _phoneController.text = user.phone;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  int _calculateCompletionPercentage() {
    int percentage = 20; // Signup complete
    if (_currentPage >= 1) percentage += 16; // Slide 1 done
    if (_currentPage >= 2) percentage += 16; // Slide 2 done
    if (_currentPage >= 3) percentage += 16; // Slide 3 done
    if (_currentPage >= 4) percentage += 16; // Slide 4 done
    if (_currentPage == 4 && _step5QuestionsLoaded) percentage += 16; // Final touches
    return percentage.clamp(0, 100);
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            colorScheme: const ColorScheme.light(
              primary: AppColors.textPrimary,
              onPrimary: AppColors.tertiary,
              surface: AppColors.cardBackground,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      HapticFeedback.lightImpact();
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (!_formKey1.currentState!.validate()) return;
      if (_selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your gender'), backgroundColor: AppColors.error),
        );
        return;
      }
    } else if (_currentPage == 1) {
      if (!_formKey2.currentState!.validate()) return;
    } else if (_currentPage == 3) {
      // Moving to Step 5 — trigger AI question load
      if (!_step5QuestionsLoaded) {
        ref.read(aiHealthProvider.notifier).loadStep5Questions();
        setState(() => _step5QuestionsLoaded = true);
      }
    }

    HapticFeedback.lightImpact();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    HapticFeedback.lightImpact();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _submitProfile() async {
    if (_selectedGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one wellness goal'), backgroundColor: AppColors.error),
      );
      return;
    }

    ref.read(authProvider.notifier).clearError();

    int? age;
    if (_selectedDate != null) {
      age = DateTime.now().year - _selectedDate!.year;
    }

    final success = await ref.read(authProvider.notifier).completeOnboarding(
          dateOfBirth: _dobController.text.isNotEmpty ? _dobController.text : null,
          phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
          gender: _selectedGender == 'Other' ? 'Others' : _selectedGender,
          avatarUrl: _selectedAvatar,
          height: double.tryParse(_heightController.text.trim()),
          weight: double.tryParse(_weightController.text.trim()),
          isDiabetesPatient: _isDiabetesPatient,
          isBpPatient: _isBpPatient,
          activityLevel: _selectedActivity,
          wellnessGoals: _selectedGoals.toList(),
          dominantDosha: _selectedDosha,
          allergies: _selectedAllergies.toList(),
          age: age,
        );

    if (!success || !mounted) {
      final errorMsg = ref.read(authProvider).error ?? 'Failed to complete profile';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    // Advance to Step 5 and load AI questions in background
    HapticFeedback.lightImpact();
    if (!_step5QuestionsLoaded) {
      ref.read(aiHealthProvider.notifier).loadStep5Questions();
      setState(() => _step5QuestionsLoaded = true);
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Called when the user taps 'FINISH' on Step 5.
  /// Submits Step 5 answers (non-blocking) and navigates to home.
  void _finishOnboarding() async {
    final aiState = ref.read(aiHealthProvider);
    final questions = aiState.step5Questions;

    final responses = questions.map((q) {
      return AIStep5Response(
        questionId: q.id,
        questionText: q.text,
        answer: _step5Answers[q.id] ?? '',
      );
    }).toList();

    // Submit in background — don't block navigation
    ref.read(aiHealthProvider.notifier).submitStep5(responses);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your personalised health plan is being prepared ✨'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
      context.go('/home');
    }
  }

  void _skipOnboarding() async {
    ref.read(authProvider.notifier).clearError();
    HapticFeedback.lightImpact();
    final success = await ref.read(authProvider.notifier).completeOnboarding(
          avatarUrl: _selectedAvatar,
        );
    if (success && mounted) {
      context.go('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not complete onboarding. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final completion = _calculateCompletionPercentage();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SETUP PROFILE',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '$completion% COMPLETE',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: completion / 100,
                      minHeight: 6,
                      backgroundColor: AppColors.border.withValues(alpha: 0.5),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            // Sliding Wizard Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildStep1BasicDetails(),
                  _buildStep2BiometricsAndActivity(),
                  _buildStep3VitalsAndAllergies(),
                  _buildStep4GoalsAndPrakriti(),
                  _buildStep5AIQuestions(),
                ],
              ),
            ),

            // Sticky Bottom Nav buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  if (_currentPage > 0) ...[
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _prevPage,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('BACK', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: _currentPage < 3
                        ? PrimaryButton(
                            text: 'CONTINUE',
                            onPressed: _nextPage,
                          )
                        : _currentPage == 3
                            ? state.isLoading
                                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                                : PrimaryButton(
                                    text: 'CONTINUE →  FINAL STEP',
                                    onPressed: _submitProfile,
                                  )
                            : ref.watch(aiHealthProvider).isSubmitting
                                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                                : PrimaryButton(
                                    text: 'FINISH  ✨',
                                    onPressed: _finishOnboarding,
                                  ),
                  ),
                ],
              ),
            ),

            // Skip Option
            if (_currentPage == 0 && !state.isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Center(
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    child: const Text(
                      'SKIP FOR NOW',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Step 1: Basic Info, Avatar, Phone, DOB, Gender ---
  Widget _buildStep1BasicDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomCard(
            backgroundColor: AppColors.cardBackground,
            child: Column(
              children: [
                const Text(
                  'Choose Your Avatar',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _avatars.map((url) {
                    final isSelected = _selectedAvatar == url;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _selectedAvatar = url;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.background,
                          backgroundImage: NetworkImage(url),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CustomCard(
            backgroundColor: AppColors.cardBackground,
            child: Form(
              key: _formKey1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Personal Details',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Phone
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: Icon(PhosphorIconsRegular.phone, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Phone number is required';
                      if (value.length < 10) return 'Enter a valid phone number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // DOB
                  TextFormField(
                    controller: _dobController,
                    readOnly: true,
                    onTap: _selectDate,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Date of Birth',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: Icon(PhosphorIconsRegular.calendar, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Date of birth is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Gender
                  const Text(
                    'Gender',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: ['Male', 'Female', 'Other'].map((gender) {
                      final isSelected = _selectedGender == gender;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Text(gender),
                            selected: isSelected,
                            onSelected: (selected) {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _selectedGender = selected ? gender : null;
                              });
                            },
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.secondary : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.background,
                            checkmarkColor: AppColors.secondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : AppColors.border,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 2: Body Metrics & Activity Level Selection ---
  Widget _buildStep2BiometricsAndActivity() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomCard(
            backgroundColor: AppColors.cardBackground,
            child: Form(
              key: _formKey2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Biometric Parameters',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Height (cm)',
                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                            prefixIcon: Icon(PhosphorIconsRegular.ruler, color: AppColors.textSecondary),
                            filled: true,
                            fillColor: AppColors.cardBackground,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            final val = double.tryParse(value);
                            if (val == null || val <= 40 || val > 260) return 'Invalid height';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Weight (kg)',
                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                            prefixIcon: Icon(PhosphorIconsRegular.scales, color: AppColors.textSecondary),
                            filled: true,
                            fillColor: AppColors.cardBackground,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            final val = double.tryParse(value);
                            if (val == null || val <= 10 || val > 250) return 'Invalid weight';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              'Physical Activity Level',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: List.generate(_activityOptions.length, (index) {
              final opt = _activityOptions[index];
              final isSelected = _selectedActivity == index;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedActivity = index;
                    });
                  },
                  child: CustomCard(
                    backgroundColor: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.cardBackground,
                    borderSide: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 1.5 : 0.5,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          opt['icon'] as IconData,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opt['title'] as String,
                                style: TextStyle(
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                opt['desc'] as String,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
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
            }),
          ),
        ],
      ),
    );
  }

  // --- Step 3: Medical Conditions & Allergies ---
  Widget _buildStep3VitalsAndAllergies() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomCard(
            backgroundColor: AppColors.cardBackground,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medical Profile',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Diabetes Patient', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Do you have diabetes or high blood sugar?', style: TextStyle(fontSize: 11)),
                  value: _isDiabetesPatient,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _isDiabetesPatient = val;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Blood Pressure (BP) Patient', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Do you have high or low blood pressure?', style: TextStyle(fontSize: 11)),
                  value: _isBpPatient,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _isBpPatient = val;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              'Food Allergies (Select all that apply)',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allergyOptions.map((allergy) {
              final isSelected = _selectedAllergies.contains(allergy);
              return FilterChip(
                label: Text(allergy),
                selected: isSelected,
                onSelected: (selected) {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (selected) {
                      _selectedAllergies.add(allergy);
                    } else {
                      _selectedAllergies.remove(allergy);
                    }
                  });
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: AppColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- Step 4: Health Goals & Ayurvedic Prakriti ---
  Widget _buildStep4GoalsAndPrakriti() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Wellness Goals (Select up to 3)',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _goalsOptions.map((goal) {
              final isSelected = _selectedGoals.contains(goal);
              return FilterChip(
                label: Text(goal),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected && _selectedGoals.length >= 3) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You can select a maximum of 3 goals')),
                    );
                    return;
                  }
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (selected) {
                      _selectedGoals.add(goal);
                    } else {
                      _selectedGoals.remove(goal);
                    }
                  });
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: AppColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Ayurvedic Prakriti (Dosha Focus)',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select your body constitution type if known',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: _doshaOptions.map((opt) {
              final isSelected = _selectedDosha == opt['title'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedDosha = isSelected ? null : opt['title'];
                    });
                  },
                  child: CustomCard(
                    backgroundColor: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.cardBackground,
                    borderSide: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 1.5 : 0.5,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              width: 2,
                            ),
                            color: isSelected ? AppColors.primary : Colors.transparent,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opt['title']!,
                                style: TextStyle(
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                opt['desc']!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
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
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- Step 5: AI-Generated Condition Questions ---
  Widget _buildStep5AIQuestions() {
    final aiState = ref.watch(aiHealthProvider);
    final questions = aiState.step5Questions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          CustomCard(
            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
            borderSide: const BorderSide(color: AppColors.primary, width: 0.8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(PhosphorIconsRegular.brain, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personalisation Questions',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'AI-tailored to your health profile',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Loading shimmer
          if (aiState.isLoadingQuestions)
            ...List.generate(
              4,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: CustomCard(
                  backgroundColor: AppColors.cardBackground,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.border.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 36,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.border.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (questions.isEmpty)
            CustomCard(
              backgroundColor: AppColors.cardBackground,
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Tap FINISH to complete your setup.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            ...questions.map((q) => _buildQuestionWidget(q)),

          if (aiState.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                aiState.error!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  /// Renders a single AI question based on its type.
  Widget _buildQuestionWidget(AIStep5Question q) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: CustomCard(
        backgroundColor: AppColors.cardBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              q.text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            if (q.type == 'mcq' && q.options != null) _buildMCQ(q)
            else if (q.type == 'boolean') _buildBoolean(q)
            else if (q.type == 'scale') _buildScale(q)
            else _buildTextInput(q),
          ],
        ),
      ),
    );
  }

  Widget _buildMCQ(AIStep5Question q) {
    return Column(
      children: (q.options ?? []).map((option) {
        final isSelected = _step5Answers[q.id] == option;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _step5Answers[q.id] = option);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.5 : 0.8,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.textSecondary, width: 2),
                    color: isSelected ? AppColors.primary : Colors.transparent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBoolean(AIStep5Question q) {
    final selected = _step5Answers[q.id];
    return Row(
      children: ['Yes', 'No'].map((label) {
        final val = label == 'Yes';
        final isSelected = selected == val;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _step5Answers[q.id] = val);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.5 : 0.8,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScale(AIStep5Question q) {
    final min = (q.scaleMin ?? 1).toDouble();
    final max = (q.scaleMax ?? 5).toDouble();
    final current = (_step5Answers[q.id] as double?) ?? min;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Slider(
          value: current,
          min: min,
          max: max,
          divisions: (max - min).round(),
          activeColor: AppColors.primary,
          inactiveColor: AppColors.border,
          label: current.round().toString(),
          onChanged: (val) {
            HapticFeedback.selectionClick();
            setState(() => _step5Answers[q.id] = val);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(min.round().toString(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            if (q.scaleLabel != null)
              Text(q.scaleLabel!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            Text(max.round().toString(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildTextInput(AIStep5Question q) {
    return TextFormField(
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      maxLines: 2,
      decoration: InputDecoration(
        hintText: 'Your answer...',
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.background,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      onChanged: (val) => _step5Answers[q.id] = val,
    );
  }
}
