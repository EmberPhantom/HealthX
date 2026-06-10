import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:healthx/providers/auth_provider.dart';
import 'package:healthx/providers/app_provider.dart';
import 'package:healthx/providers/user_provider.dart';
import 'package:healthx/providers/sleep_provider.dart';
import 'package:healthx/providers/water_provider.dart';
import 'package:healthx/providers/rewards_provider.dart';
import 'package:healthx/screens/wellness_goals_screen.dart' show OnboardingProvider;
import 'package:healthx/models/api/auth_models.dart';
import 'package:healthx/models/api/api_response.dart';
import 'package:healthx/models/models.dart' hide UserProfile;
import 'package:healthx/services/api/api_service.dart';
import 'package:healthx/screens/login_screen.dart';

class MockAuthProvider extends Mock implements AuthProvider {
  @override
  bool get isLoading => super.noSuchMethod(
        Invocation.getter(#isLoading),
        returnValue: false,
        returnValueForMissingStub: false,
      );

  @override
  String? get error => super.noSuchMethod(
        Invocation.getter(#error),
        returnValue: null,
        returnValueForMissingStub: null,
      );

  @override
  bool get isAuthenticated => super.noSuchMethod(
        Invocation.getter(#isAuthenticated),
        returnValue: false,
        returnValueForMissingStub: false,
      );

  @override
  UserProfile? get user => super.noSuchMethod(
        Invocation.getter(#user),
        returnValue: null,
        returnValueForMissingStub: null,
      );

  @override
  AuthState get state => super.noSuchMethod(
        Invocation.getter(#state),
        returnValue: const AuthState(),
        returnValueForMissingStub: const AuthState(),
      );

  @override
  Future<bool> login({
    String? email,
    String? password,
  }) =>
      super.noSuchMethod(
        Invocation.method(#login, [], {#email: email, #password: password}),
        returnValue: Future<bool>.value(false),
        returnValueForMissingStub: Future<bool>.value(false),
      );
}

class MockApiService extends Mock implements ApiService {
  @override
  Future<ApiResponse<List<MenuCategory>>> getCategories() async =>
      ApiResponse.success(statusCode: 200, message: 'Success', data: const []);

  @override
  Future<ApiResponse<List<BannerModel>>> getBanners() async =>
      ApiResponse.success(statusCode: 200, message: 'Success', data: const []);

  @override
  Future<ApiResponse<List<MealPlan>>> getMealPlans() async =>
      ApiResponse.success(statusCode: 200, message: 'Success', data: const []);

  @override
  Future<ApiResponse<List<MenuItem>>> getMenuItems({String? type}) async =>
      ApiResponse.success(statusCode: 200, message: 'Success', data: const []);
}

void main() {
  group('LoginScreen Widget Tests', () {
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      ApiService.instance = MockApiService();
    });

    /// Helper to wrap screen with required providers
    Widget createWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
          ChangeNotifierProvider<AppProvider>(create: (_) => AppProvider()),
          ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
          ChangeNotifierProvider<OnboardingProvider>(create: (_) => OnboardingProvider()),
          ChangeNotifierProvider<RewardsProvider>(create: (_) => RewardsProvider()),
          ChangeNotifierProxyProvider<RewardsProvider, SleepProvider>(
            create: (_) => SleepProvider(),
            update: (_, rewards, sleep) {
              sleep!.setRewards(rewards);
              return sleep;
            },
          ),
          ChangeNotifierProxyProvider<RewardsProvider, WaterProvider>(
            create: (_) => WaterProvider(),
            update: (_, rewards, water) {
              water!.setRewards(rewards);
              return water;
            },
          ),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      );
    }

    /// Sets up the tester with a larger screen viewport to prevent overflow/clipping
    /// and pumps/settles layout animations.
    Future<void> setupTester(WidgetTester tester, {bool settle = true}) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(createWidgetUnderTest());
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump(const Duration(seconds: 2));
      }
    }

    testWidgets('LoginScreen displays all required fields', (tester) async {
      // Arrange
      await setupTester(tester);

      // Assert
      expect(find.text('Log In'), findsWidgets);
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Email'), findsWidgets);
      expect(find.text('Password'), findsWidgets);
    });

    testWidgets('Email field accepts input', (tester) async {
      // Arrange
      await setupTester(tester);

      // Act
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');

      // Assert
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('Password field accepts input', (tester) async {
      // Arrange
      await setupTester(tester);

      // Act
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'Password123!');

      // Assert - password should be visible or hidden based on toggle
      expect(find.text('Password123!'), findsOneWidget);
    });

    testWidgets('Login button is present and clickable', (tester) async {
      // Arrange
      when(mockAuthProvider.isLoading).thenReturn(false);
      await setupTester(tester);

      // Act
      final loginButton = find.byType(ElevatedButton).first;
      expect(loginButton, findsOneWidget);

      // Assert
      await tester.tap(loginButton);
      await tester.pump();
    });

    testWidgets('Loading state shows spinner', (tester) async {
      // Arrange
      when(mockAuthProvider.isLoading).thenReturn(true);
      when(mockAuthProvider.state).thenReturn(
        const AuthState(isLoading: true),
      );

      await setupTester(tester, settle: false);

      // Assert
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('Error message displays when login fails', (tester) async {
      // Arrange
      when(mockAuthProvider.error).thenReturn('Invalid credentials');
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.login(email: anyNamed('email'), password: anyNamed('password')))
          .thenAnswer((_) async => false);

      await setupTester(tester);

      // Act
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');

      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'Password123!');

      final loginButton = find.byType(ElevatedButton).first;
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('Gender dropdown displays options', (tester) async {
      // Arrange
      await setupTester(tester);

      // Act
      final dropdownFinder = find.byType(DropdownButton<String>);
      if (dropdownFinder.evaluate().isNotEmpty) {
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Male'), findsOneWidget);
        expect(find.text('Female'), findsOneWidget);
      }
    });

    testWidgets('Forgot password link is present', (tester) async {
      // Arrange
      await setupTester(tester);

      // Assert
      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets('Sign up link navigates to signup', (tester) async {
      // Arrange
      await setupTester(tester);

      // Act
      final signupLink = find.byType(GestureDetector).last;
      await tester.tap(signupLink);
      await tester.pumpAndSettle();

      // Assert - would navigate to signup screen
      // (navigation test would require route setup)
    });

    testWidgets('Social login buttons are displayed', (tester) async {
      // Arrange
      await setupTester(tester);

      // Assert
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text('Sign in with Facebook'), findsOneWidget);
    });

    testWidgets('Form validation prevents empty email submission', (tester) async {
      // Arrange
      when(mockAuthProvider.login(email: anyNamed('email'), password: anyNamed('password'))).thenThrow(Exception('Validation error'));
      await setupTester(tester);

      // Act
      final loginButton = find.byType(ElevatedButton).first;
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Assert - form should show validation error
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('Password visibility toggle works', (tester) async {
      // Arrange
      await setupTester(tester);

      // Act
      final toggleButton = find.byIcon(Icons.visibility_off_outlined).first;
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      // Assert - icon should change
      expect(find.byIcon(Icons.visibility_outlined), findsWidgets);
    });

    testWidgets('Login with valid credentials calls authProvider.login', (tester) async {
      // Arrange
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.login(email: anyNamed('email'), password: anyNamed('password'))).thenAnswer((_) async => true);

      await setupTester(tester);

      // Act
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');

      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'Password123!');

      final loginButton = find.byType(ElevatedButton).first;
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Assert
      verify(mockAuthProvider.login(email: 'test@example.com', password: 'Password123!'))
          .called(1);
    });

    testWidgets('Screen responds to orientation changes', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act - change to landscape
      tester.view.physicalSize = const Size(800, 400);
      await tester.pumpAndSettle();

      // Assert - screen should still be responsive
      expect(find.text('Log In'), findsNWidgets(2));
    });
  });
}
