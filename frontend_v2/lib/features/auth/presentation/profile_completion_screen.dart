import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends ConsumerState<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  
  String? _selectedGender;
  String _selectedAvatar = 'https://api.dicebear.com/7.x/bottts/png?seed=HealthX1';
  DateTime? _selectedDate;

  final List<String> _avatars = [
    'https://api.dicebear.com/7.x/bottts/png?seed=HealthX1',
    'https://api.dicebear.com/7.x/bottts/png?seed=HealthX2',
    'https://api.dicebear.com/7.x/bottts/png?seed=HealthX3',
    'https://api.dicebear.com/7.x/bottts/png?seed=HealthX4',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-populate phone if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null && user.phone.isNotEmpty) {
        _phoneController.text = user.phone;
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  int _calculateCompletionPercentage() {
    int percentage = 20; // 20% for email signup
    if (_phoneController.text.isNotEmpty) percentage += 25;
    if (_selectedDate != null) percentage += 25;
    if (_selectedGender != null) percentage += 30;
    return percentage;
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.secondary,
              surface: Color(0xFF1E1E1E),
              onSurface: AppColors.tertiary,
            ),
            dialogBackgroundColor: const Color(0xFF121212),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authProvider.notifier).clearError();
    final success = await ref.read(authProvider.notifier).completeOnboarding(
          dateOfBirth: _dobController.text.isNotEmpty ? _dobController.text : null,
          phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
          gender: _selectedGender,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile setup complete! Welcome to HealthX.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/home');
    } else if (mounted) {
      final errorMsg = ref.read(authProvider).error ?? 'Failed to complete profile';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
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
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header progress gauge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SETUP PROFILE',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.tertiary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
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
                  backgroundColor: const Color(0xFF262626),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 32),

              // Avatar Selector Card
              CustomCard(
                backgroundColor: const Color(0xFF1E1E1E),
                child: Column(
                  children: [
                    const Text(
                      'Choose Your Avatar',
                      style: TextStyle(
                        color: AppColors.tertiary,
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
                              radius: 32,
                              backgroundColor: const Color(0xFF262626),
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

              // Profile Form Details Card
              CustomCard(
                backgroundColor: const Color(0xFF1E1E1E),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Personal Details',
                        style: TextStyle(
                          color: AppColors.tertiary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Phone Field
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: AppColors.tertiary),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: const TextStyle(color: AppColors.neutral),
                          prefixIcon: Icon(PhosphorIconsRegular.phone, color: AppColors.neutral),
                          filled: true,
                          fillColor: const Color(0xFF262626),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF333333)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Phone number is required';
                          }
                          if (value.length < 10) {
                            return 'Enter a valid phone number';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      // Date of birth
                      TextFormField(
                        controller: _dobController,
                        readOnly: true,
                        onTap: _selectDate,
                        style: const TextStyle(color: AppColors.tertiary),
                        decoration: InputDecoration(
                          labelText: 'Date of Birth',
                          labelStyle: const TextStyle(color: AppColors.neutral),
                          prefixIcon: Icon(PhosphorIconsRegular.calendar, color: AppColors.neutral),
                          filled: true,
                          fillColor: const Color(0xFF262626),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF333333)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Date of birth is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Gender Chips
                      const Text(
                        'Gender',
                        style: TextStyle(
                          color: AppColors.neutral,
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
                                  setState(() {
                                    _selectedGender = selected ? gender : null;
                                  });
                                },
                                labelStyle: TextStyle(
                                  color: isSelected ? AppColors.secondary : AppColors.tertiary,
                                  fontWeight: FontWeight.bold,
                                ),
                                selectedColor: AppColors.primary,
                                backgroundColor: const Color(0xFF262626),
                                checkmarkColor: AppColors.secondary,
                                border: BorderSide(
                                  color: isSelected ? AppColors.primary : const Color(0xFF333333),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      // Complete button
                      if (state.isLoading)
                        const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      else
                        PrimaryButton(
                          text: 'COMPLETE SETUP',
                          onPressed: _submitProfile,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Skip for now action
              if (!state.isLoading)
                OutlinedButton(
                  onPressed: () {
                    context.go('/home');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.neutral,
                    side: const BorderSide(color: Color(0xFF333333)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'SKIP FOR NOW',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
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
