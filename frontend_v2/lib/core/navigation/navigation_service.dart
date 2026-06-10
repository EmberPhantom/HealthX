import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/tracker/presentation/tracker_screen.dart';
import '../../features/consults/presentation/consults_screen.dart';
import '../../features/shop/presentation/shop_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/profile_completion_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../shared/widgets/navigation_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isOnboardingComplete = authState.isOnboardingComplete;

      final isLoggingIn = state.matchedLocation == '/login';
      final isSigningUp = state.matchedLocation == '/signup';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!isAuthenticated) {
        if (isLoggingIn || isSigningUp) return null;
        return '/login';
      }

      if (!isOnboardingComplete) {
        if (isOnboarding) return null;
        return '/onboarding';
      }

      if (isLoggingIn || isSigningUp || isOnboarding) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const ProfileCompletionScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return NavigationShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/tracker',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TrackerScreen(),
            ),
          ),
          GoRoute(
            path: '/consults',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ConsultsScreen(),
            ),
          ),
          GoRoute(
            path: '/shop',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ShopScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
