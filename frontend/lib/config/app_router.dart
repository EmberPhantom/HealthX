/// App Router
/// Navigation configuration using go_router

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/profile_completion_screen.dart';
import '../screens/home_screen.dart';
import '../widgets/app_shell.dart';

/// Authentication routes
class AuthRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String profileCompletion = '/profile-completion';
}

/// App routes
class AppRoutes {
  static const String home = '/home';
  static const String profile = '/profile';
  static const String settings = '/settings';
}

/// Create app router
GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    redirect: _handleRedirect,
    refreshListenable: authProvider,
    routes: [
      // ── Splash Screen ──────────────────────────────────────────────────
      GoRoute(
        path: AuthRoutes.splash,
        builder: (context, state) => SplashScreen(
          onComplete: () {
            // Splash finished, go to login (redirect will handle if already authenticated)
            context.go(AuthRoutes.login);
          },
        ),
      ),

      // ── Auth Routes ────────────────────────────────────────────────────
      GoRoute(
        path: AuthRoutes.login,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ),

      GoRoute(
        path: AuthRoutes.signup,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const SignupScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ),

      GoRoute(
        path: AuthRoutes.profileCompletion,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const ProfileCompletionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ),

      // ── App Routes (Protected) ───────────────────────────────────────
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const AppShell(),
        routes: [
          // Nested routes go here
        ],
      ),

      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const Placeholder(
          child: Center(child: Text('Profile Screen')),
        ),
      ),

      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const Placeholder(
          child: Center(child: Text('Settings Screen')),
        ),
      ),
    ],
    initialLocation: AuthRoutes.splash,
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}

/// Handle navigation redirects based on auth state
Future<String?> _handleRedirect(BuildContext context, GoRouterState state) async {
  // Get auth provider
  final authProvider = context.read<AuthProvider>();

  // Routes that don't require authentication
  final publicRoutes = {
    AuthRoutes.splash,
    AuthRoutes.login,
    AuthRoutes.signup,
    AuthRoutes.profileCompletion,
  };

  final isPublicRoute = publicRoutes.contains(state.matchedLocation);

  // While auth is initializing (restoring session from storage), stay put.
  // Without this guard the user briefly flashes to /login on every app start.
  if (authProvider.isLoading) {
    // Stay on splash while we check — do not redirect yet
    if (state.matchedLocation == AuthRoutes.splash) return null;
    return AuthRoutes.splash;
  }

  // If user is authenticated
  if (authProvider.isAuthenticated) {
    final user = authProvider.user;



    // 2. Mandatory Profile Completion (Onboarding)
    // Redirect if not onboarded and not already on the completion screen
    if (user != null && !user.onboardingComplete) {
      if (state.matchedLocation == AuthRoutes.profileCompletion) return null;
      return AuthRoutes.profileCompletion;
    }

    // 3. Redirect from public routes (login/signup/splash) to home
    if (isPublicRoute && state.matchedLocation != AuthRoutes.splash) {
      return AppRoutes.home;
    }

    return null;
  }

  // If user is not authenticated
  if (!isPublicRoute) {
    // Redirect to login if trying to access protected route
    return AuthRoutes.login;
  }

  return null;
}

/// Router navigation helpers
class RouterHelper {
  /// Navigate to login
  static Future<void> toLogin(BuildContext context) async {
    context.go(AuthRoutes.login);
  }

  /// Navigate to signup
  static Future<void> toSignup(BuildContext context) async {
    context.go(AuthRoutes.signup);
  }



  /// Navigate to profile completion
  static Future<void> toProfileCompletion(BuildContext context) async {
    context.go(AuthRoutes.profileCompletion);
  }

  /// Navigate to home
  static Future<void> toHome(BuildContext context) async {
    context.go(AppRoutes.home);
  }

  /// Navigate to profile
  static Future<void> toProfile(BuildContext context) async {
    context.go(AppRoutes.profile);
  }

  /// Navigate to settings
  static Future<void> toSettings(BuildContext context) async {
    context.go(AppRoutes.settings);
  }

  /// Go back
  static void back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    }
  }

  /// Replace current route
  static Future<void> replace(BuildContext context, String location) async {
    context.replace(location);
  }
}
