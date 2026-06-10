import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authProvider.notifier).clearError();
    final success = await ref.read(authProvider.notifier).signup(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        );

    if (!success && mounted) {
      final errorMsg = ref.read(authProvider).error ?? 'Registration failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleGoogleSignup() async {
    ref.read(authProvider.notifier).clearError();
    final success = await ref.read(authProvider.notifier).googleLogin(isSignup: true);

    if (!success && mounted) {
      final errorMsg = ref.read(authProvider).error ?? 'Google Sign-in failed';
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

    return Scaffold(
      backgroundColor: AppColors.background, // Uniform off-white premium feel
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Activity Logo
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'GET STARTED',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: 2.0,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Create your unified medical profile.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                  ),
                ),
                const SizedBox(height: 28),

                // Main Form Card
                CustomCard(
                  backgroundColor: AppColors.cardBackground,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Register Account',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                              ),
                        ),
                        const SizedBox(height: 20),

                        // Full Name
                        TextFormField(
                          controller: _nameController,
                          keyboardType: TextInputType.name,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                            prefixIcon: Icon(PhosphorIconsRegular.user, color: AppColors.textSecondary),
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
                            if (value == null || value.trim().isEmpty) {
                              return 'Name is required';
                            }
                            if (value.trim().length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Email Address
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                            prefixIcon: Icon(PhosphorIconsRegular.envelope, color: AppColors.textSecondary),
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
                              return 'Email is required';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Phone Number
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Phone Number (Optional)',
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
                            if (value != null && value.isNotEmpty) {
                              if (value.length < 10) {
                                return 'Enter a valid phone number';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                            prefixIcon: Icon(PhosphorIconsRegular.lock, color: AppColors.textSecondary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? PhosphorIconsRegular.eyeClosed
                                    : PhosphorIconsRegular.eye,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
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
                              return 'Password is required';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Action Button
                        if (state.isLoading)
                          const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          )
                        else
                          PrimaryButton(
                            text: 'CREATE ACCOUNT',
                            onPressed: _handleSignup,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Separator
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'OR SIGN UP WITH',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 20),

                // Google button
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: state.isLoading ? null : _handleGoogleSignup,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      backgroundColor: AppColors.cardBackground,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIconsBold.googleLogo,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'CONTINUE WITH GOOGLE',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Bottom login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.pop();
                      },
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
