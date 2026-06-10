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

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends ConsumerState<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String? _selectedGender;
  String _selectedAvatar = 'https://images.unsplash.com/photo-1544816155-12df9643f363?fit=crop&w=150&h=150'; // Cute Panda
  DateTime? _selectedDate;
  bool _isDiabetesPatient = false;
  bool _isBpPatient = false;

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
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  int _calculateCompletionPercentage() {
    int percentage = 20; // 20% for email signup
    if (_phoneController.text.isNotEmpty) percentage += 20;
    if (_selectedDate != null) percentage += 20;
    if (_selectedGender != null) percentage += 20;
    if (_heightController.text.isNotEmpty || _weightController.text.isNotEmpty) percentage += 20;
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

  void _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authProvider.notifier).clearError();
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);

    final success = await ref.read(authProvider.notifier).completeOnboarding(
          dateOfBirth: _dobController.text.isNotEmpty ? _dobController.text : null,
          phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
          gender: _selectedGender == 'Other' ? 'Others' : _selectedGender,
          avatarUrl: _selectedAvatar,
          height: height,
          weight: weight,
          isDiabetesPatient: _isDiabetesPatient,
          isBpPatient: _isBpPatient,
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

  void _skipOnboarding() async {
    ref.read(authProvider.notifier).clearError();
    HapticFeedback.lightImpact();
    final success = await ref.read(authProvider.notifier).completeOnboarding(
          avatarUrl: _selectedAvatar,
        );
    if (success && mounted) {
      context.go('/home');
    } else if (mounted) {
      // Fallback navigation in case of error
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final completion = _calculateCompletionPercentage();

    return Scaffold(
      backgroundColor: AppColors.background,
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
              const SizedBox(height: 32),

              // Avatar Selector Card
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
                              radius: 32,
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

              // Profile Form Details Card
              CustomCard(
                backgroundColor: AppColors.cardBackground,
                child: Form(
                  key: _formKey,
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

                      // Phone Field
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
                      const SizedBox(height: 24),

                      // Height and Weight Row
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
                                if (value == null || value.trim().isEmpty) return null;
                                final val = double.tryParse(value);
                                if (val == null || val <= 0) return 'Invalid height';
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
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
                                if (value == null || value.trim().isEmpty) return null;
                                final val = double.tryParse(value);
                                if (val == null || val <= 0) return 'Invalid weight';
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Health Conditions
                      const Text(
                        'Health Conditions',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Diabetes Patient', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
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
                        title: const Text('BP Patient', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
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
                  onPressed: _skipOnboarding,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
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
