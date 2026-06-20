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
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../shared/widgets/navigation_shell.dart';
import '../../features/tracker/presentation/steps_tracker_screen.dart';
import '../../features/tracker/presentation/sleep_tracker_screen.dart';
import '../../features/tracker/presentation/water_tracker_screen.dart';
import '../../features/tracker/presentation/blood_glucose_screen.dart';
import '../../features/tracker/presentation/sleep_insights_screen.dart';
import '../../features/tracker/presentation/set_goal_screen.dart';
import '../../features/tracker/presentation/set_reminders_screen.dart';
import '../../features/tracker/presentation/nutrition_screen.dart';
import '../../features/tracker/presentation/log_manually_screen.dart';
import '../../features/tracker/presentation/log_from_text_screen.dart';
import '../../features/tracker/presentation/ai_identify_screen.dart';
import '../../features/tracker/presentation/correct_ingredients_screen.dart';
import '../../features/tracker/presentation/counting_calories_screen.dart';
import '../../features/tracker/presentation/food_detail_screen.dart';

// Import newly created features
import '../../features/health/presentation/my_vitals_screen.dart';
import '../../features/health/presentation/measurements_screen.dart';
import '../../features/health/presentation/insulin_dosage_screen.dart';
import '../../features/health/presentation/bmi_calculator_screen.dart';
import '../../features/health/presentation/health_records_screen.dart';
import '../../features/health/presentation/age_prakriti_screen.dart';
import '../../features/health/presentation/fat_calculator_screen.dart';
import '../../features/health/presentation/diabetic_care_screen.dart';
import '../../features/rewards/presentation/rewards_screen.dart';
import '../../features/consults/presentation/find_doctor_screen.dart';
import '../../features/consults/presentation/doctor_list_screen.dart';
import '../../features/consults/presentation/doctor_profile_screen.dart';
import '../../features/consults/presentation/book_appointment_screen.dart';
import '../../features/consults/presentation/appointment_detail_screen.dart';
import '../../features/consults/presentation/chat_screen.dart';
import '../../features/consults/presentation/prescription_screen.dart';
import '../../features/shop/presentation/product_detail_screen.dart';
import '../../features/shop/presentation/cart_screen.dart';
import '../../features/shop/presentation/checkout_screen.dart';
import '../../features/shop/presentation/address_management_screen.dart';
import '../../features/shop/presentation/my_orders_screen.dart';
import '../../features/shop/presentation/order_tracking_screen.dart';
import '../../features/shop/presentation/favorites_screen.dart';
import '../../features/shop/presentation/ready_to_eat_screen.dart';
import '../../features/shop/presentation/meal_plan_screen.dart';
import '../../features/shop/presentation/menu_screen.dart';
import '../../features/auth/presentation/settings_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/profile/presentation/help_support_screen.dart';
import '../../features/rewards/presentation/wellness_goals_screen.dart';
import '../../features/shop/presentation/custom_bowl_builder.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final showSplash = ref.watch(showSplashProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      if (showSplash || authState.isLoading) {
        return '/splash';
      }

      final isAuthenticated = authState.isAuthenticated;
      final isOnboardingComplete = authState.isOnboardingComplete;

      final isLoggingIn = state.matchedLocation == '/login';
      final isSigningUp = state.matchedLocation == '/signup';
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isSplash = state.matchedLocation == '/splash';
      final isForgotPassword = state.matchedLocation == '/forgot-password';
      final isResetPassword = state.matchedLocation.startsWith('/reset-password');

      if (isSplash) {
        if (!isAuthenticated) return '/login';
        if (!isOnboardingComplete) return '/onboarding';
        return '/home';
      }

      if (!isAuthenticated) {
        if (isLoggingIn || isSigningUp || isForgotPassword || isResetPassword) return null;
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
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
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
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(
          token: state.uri.queryParameters['token'] ?? '',
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/tracker/steps',
        builder: (context, state) => const StepsTrackerScreen(),
      ),
      GoRoute(
        path: '/tracker/sleep',
        builder: (context, state) => const SleepTrackerScreen(),
      ),
      GoRoute(
        path: '/tracker/water',
        builder: (context, state) => const WaterTrackerScreen(),
      ),
      GoRoute(
        path: '/tracker/glucose',
        builder: (context, state) => const BloodGlucoseScreen(),
      ),
      GoRoute(
        path: '/tracker/sleep-insights',
        builder: (context, state) => const SleepInsightsScreen(),
      ),
      GoRoute(
        path: '/tracker/goals',
        builder: (context, state) => const SetGoalScreen(),
      ),
      GoRoute(
        path: '/tracker/reminders',
        builder: (context, state) => const SetRemindersScreen(),
      ),
      GoRoute(
        path: '/tracker/nutrition',
        builder: (context, state) => const NutritionScreen(),
      ),
      GoRoute(
        path: '/tracker/log-manual',
        builder: (context, state) {
          final meal = state.uri.queryParameters['meal'];
          return LogManuallyScreen(initialMeal: meal);
        },
      ),
      GoRoute(
        path: '/tracker/log-text',
        builder: (context, state) {
          final meal = state.uri.queryParameters['meal'];
          return LogFromTextScreen(initialMeal: meal);
        },
      ),
      GoRoute(
        path: '/tracker/scan',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final imagePath = extra?['imagePath'] as String? ?? '';
          final meal = extra?['meal'] as String? ?? 'Breakfast';
          return AiIdentifyScreen(imagePath: imagePath, meal: meal);
        },
      ),
      GoRoute(
        path: '/tracker/correct-ingredients',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final meal = extra?['meal'] as String? ?? 'Breakfast';
          final imagePath = extra?['imagePath'] as String?;
          final mealDescription = extra?['mealDescription'] as String?;
          final isTextBased = extra?['isTextBased'] as bool? ?? false;
          final nutritionData = extra?['nutritionData'] as Map<String, dynamic>? ?? {};
          return CorrectIngredientsScreen(
            meal: meal,
            imagePath: imagePath,
            mealDescription: mealDescription,
            isTextBased: isTextBased,
            nutritionData: nutritionData,
          );
        },
      ),
      GoRoute(
        path: '/tracker/counting-calories',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final meal = extra?['meal'] as String? ?? 'Breakfast';
          final imagePath = extra?['imagePath'] as String?;
          final isTextBased = extra?['isTextBased'] as bool? ?? false;
          final nutritionData = extra?['nutritionData'] as Map<String, dynamic>? ?? {};
          return CountingCaloriesScreen(
            meal: meal,
            imagePath: imagePath,
            isTextBased: isTextBased,
            nutritionData: nutritionData,
          );
        },
      ),
      GoRoute(
        path: '/tracker/food-detail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final meal = extra?['meal'] as String? ?? 'Breakfast';
          final imagePath = extra?['imagePath'] as String?;
          final isTextBased = extra?['isTextBased'] as bool? ?? false;
          final nutritionData = extra?['nutritionData'] as Map<String, dynamic>? ?? {};
          return FoodDetailScreen(
            meal: meal,
            imagePath: imagePath,
            isTextBased: isTextBased,
            nutritionData: nutritionData,
          );
        },
      ),
      
      // Health Manager routes
      GoRoute(
        path: '/health/vitals',
        builder: (context, state) => const MyVitalsScreen(),
      ),
      GoRoute(
        path: '/health/measurements',
        builder: (context, state) => const MeasurementsScreen(),
      ),
      GoRoute(
        path: '/health/insulin',
        builder: (context, state) => const InsulinDosageScreen(),
      ),
      GoRoute(
        path: '/health/bmi',
        builder: (context, state) => const BmiCalculatorScreen(),
      ),
      GoRoute(
        path: '/health/records',
        builder: (context, state) {
          final specialist = state.uri.queryParameters['specialist'];
          final autoOpenUpload = state.uri.queryParameters['openUpload'] == 'true';
          return HealthRecordsScreen(
            specialist: specialist,
            autoOpenUpload: autoOpenUpload,
          );
        },
      ),
      GoRoute(
        path: '/health/prakriti',
        builder: (context, state) => const AgePrakritiScreen(),
      ),
      GoRoute(
        path: '/health/fat-calculator',
        builder: (context, state) => const FatCalculatorScreen(),
      ),
      GoRoute(
        path: '/health/diabetic-care',
        builder: (context, state) => const DiabeticCareScreen(),
      ),

      // Rewards route
      GoRoute(
        path: '/rewards',
        builder: (context, state) => const RewardsScreen(),
      ),
      GoRoute(
        path: '/rewards/wellness-goals',
        builder: (context, state) => const WellnessGoalsScreen(),
      ),

      // Doctor consultations routes
      GoRoute(
        path: '/consults/find',
        builder: (context, state) => const FindDoctorScreen(),
      ),
      GoRoute(
        path: '/consults/list',
        builder: (context, state) => DoctorListScreen(
          specialty: state.uri.queryParameters['specialty'],
        ),
      ),
      GoRoute(
        path: '/consults/doctor/:id',
        builder: (context, state) => DoctorProfileScreen(
          doctorId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/consults/book/:id',
        builder: (context, state) => BookAppointmentScreen(
          doctorId: state.pathParameters['id']!,
          day: state.uri.queryParameters['day'] ?? 'Monday',
          time: state.uri.queryParameters['time'] ?? '09:00 AM',
        ),
      ),
      GoRoute(
        path: '/consults/appointment/:id',
        builder: (context, state) => AppointmentDetailScreen(
          appointmentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/consults/appointment/:id/chat',
        builder: (context, state) => ChatScreen(
          appointmentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/consults/appointment/:id/prescription',
        builder: (context, state) => PrescriptionScreen(
          appointmentId: state.pathParameters['id']!,
        ),
      ),

      // Shop & Cart routes
      GoRoute(
        path: '/shop/product/:id',
        builder: (context, state) => ProductDetailScreen(
          productId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/shop/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/shop/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/shop/addresses',
        builder: (context, state) => const AddressManagementScreen(),
      ),
      GoRoute(
        path: '/shop/orders',
        builder: (context, state) => const MyOrdersScreen(),
      ),
      GoRoute(
        path: '/shop/orders/:id/track',
        builder: (context, state) => OrderTrackingScreen(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/shop/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/shop/ready-to-eat',
        builder: (context, state) => const ReadyToEatScreen(),
      ),
      GoRoute(
        path: '/shop/meal-plan',
        builder: (context, state) => const MealPlanScreen(),
      ),
      GoRoute(
        path: '/shop/menu',
        builder: (context, state) => const MenuScreen(),
      ),
      GoRoute(
        path: '/shop/custom-bowl',
        builder: (context, state) => const CustomBowlBuilderScreen(),
      ),

      // Profile settings & help routes
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => const HelpSupportScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return NavigationShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tracker',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: TrackerScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/consults',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ConsultsScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shop',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ShopScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
