import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';

class ShowSplashNotifier extends Notifier<bool> {
  @override
  bool build() {
    return true;
  }

  void dismiss() {
    state = false;
  }
}

final showSplashProvider = NotifierProvider<ShowSplashNotifier, bool>(ShowSplashNotifier.new);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startSplashTimer();
  }

  void _startSplashTimer() {
    // Keep splash screen visible for 1.0 second for branding animation
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        ref.read(showSplashProvider.notifier).dismiss();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tertiary, // Pure white bg
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.8 + (0.2 * value), // Scale from 0.8 to 1.0
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 48,
                        letterSpacing: -1.5,
                      ),
                  children: const [
                    TextSpan(text: 'HEALTH'),
                    TextSpan(
                      text: 'X',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'YOUR PERSONAL HEALTH INSIGHTS',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.0,
                      color: AppColors.neutral.withValues(alpha: 0.8),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
