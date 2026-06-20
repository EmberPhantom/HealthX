import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authProvider.notifier).clearError();
    final error = await ref.read(authProvider.notifier).forgotPassword(
          email: _emailController.text.trim(),
        );

    if (error == null) {
      setState(() => _emailSent = true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  PhosphorIconsRegular.lockKey,
                  size: 56,
                  color: AppColors.primary.withOpacity(0.8),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Reset Password',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: 1.0,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _emailSent
                        ? 'Check your inbox for the reset link.'
                        : 'Enter your email and we\'ll send you a reset link.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                  ),
                ),
                const SizedBox(height: 32),

                if (!_emailSent)
                  CustomCard(
                    backgroundColor: AppColors.cardBackground,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                              if (value == null || value.isEmpty) return 'Email is required';
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            text: 'SEND RESET LINK',
                            isLoading: state.isLoading,
                            onPressed: _handleSubmit,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      Icon(
                        PhosphorIconsRegular.checkCircle,
                        size: 64,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        text: 'BACK TO LOGIN',
                        onPressed: () => context.go('/login'),
                      ),
                    ],
                  ),

                if (!_emailSent) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: const Text(
                        'Back to Login',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
