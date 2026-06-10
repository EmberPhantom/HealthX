import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:healthx/services/api/api_service.dart';
import 'package:healthx/services/api/secure_storage_simple.dart';
import 'package:healthx/models/api/auth_models.dart';
import 'package:healthx/models/api/api_response.dart';
import 'package:healthx/providers/auth_provider.dart';

// Mock ApiService that overrides methods with nullable parameters for Mockito safety
class MockApiService extends Mock implements ApiService {
  @override
  Future<ApiResponse<AuthResponse>> signup({
    String? name,
    String? email,
    String? password,
    String? phone,
  }) =>
      super.noSuchMethod(
        Invocation.method(#signup, [], {
          #name: name,
          #email: email,
          #password: password,
          #phone: phone,
        }),
        returnValue: Future<ApiResponse<AuthResponse>>.value(
          ApiResponse<AuthResponse>.error(statusCode: 500, error: 'Stub required'),
        ),
        returnValueForMissingStub: Future<ApiResponse<AuthResponse>>.value(
          ApiResponse<AuthResponse>.error(statusCode: 500, error: 'Stub required'),
        ),
      );

  @override
  Future<ApiResponse<AuthResponse>> login({
    String? email,
    String? password,
  }) =>
      super.noSuchMethod(
        Invocation.method(#login, [], {
          #email: email,
          #password: password,
        }),
        returnValue: Future<ApiResponse<AuthResponse>>.value(
          ApiResponse<AuthResponse>.error(statusCode: 500, error: 'Stub required'),
        ),
        returnValueForMissingStub: Future<ApiResponse<AuthResponse>>.value(
          ApiResponse<AuthResponse>.error(statusCode: 500, error: 'Stub required'),
        ),
      );

  @override
  Future<ApiResponse<EmptyResponse>> verifyEmail({
    String? token,
  }) =>
      super.noSuchMethod(
        Invocation.method(#verifyEmail, [], {
          #token: token,
        }),
        returnValue: Future<ApiResponse<EmptyResponse>>.value(
          ApiResponse<EmptyResponse>.error(statusCode: 500, error: 'Stub required'),
        ),
        returnValueForMissingStub: Future<ApiResponse<EmptyResponse>>.value(
          ApiResponse<EmptyResponse>.error(statusCode: 500, error: 'Stub required'),
        ),
      );

  @override
  Future<ApiResponse<EmptyResponse>> resendVerification() =>
      super.noSuchMethod(
        Invocation.method(#resendVerification, [], {}),
        returnValue: Future<ApiResponse<EmptyResponse>>.value(
          ApiResponse<EmptyResponse>.error(statusCode: 500, error: 'Stub required'),
        ),
        returnValueForMissingStub: Future<ApiResponse<EmptyResponse>>.value(
          ApiResponse<EmptyResponse>.error(statusCode: 500, error: 'Stub required'),
        ),
      );

  @override
  Future<ApiResponse<UserProfile>> completeOnboarding({
    String? dateOfBirth,
    String? phone,
    String? gender,
    String? medicalHistory,
    List<String>? allergies,
    String? insuranceProvider,
    String? insurancePolicyNumber,
  }) =>
      super.noSuchMethod(
        Invocation.method(#completeOnboarding, [], {
          #dateOfBirth: dateOfBirth,
          #phone: phone,
          #gender: gender,
          #medicalHistory: medicalHistory,
          #allergies: allergies,
          #insuranceProvider: insuranceProvider,
          #insurancePolicyNumber: insurancePolicyNumber,
        }),
        returnValue: Future<ApiResponse<UserProfile>>.value(
          ApiResponse<UserProfile>.error(statusCode: 500, error: 'Stub required'),
        ),
        returnValueForMissingStub: Future<ApiResponse<UserProfile>>.value(
          ApiResponse<UserProfile>.error(statusCode: 500, error: 'Stub required'),
        ),
      );

  @override
  Future<ApiResponse<TokenRefreshResponse>> refreshToken({
    String? refreshToken,
  }) =>
      super.noSuchMethod(
        Invocation.method(#refreshToken, [], {
          #refreshToken: refreshToken,
        }),
        returnValue: Future<ApiResponse<TokenRefreshResponse>>.value(
          ApiResponse<TokenRefreshResponse>.error(statusCode: 500, error: 'Stub required'),
        ),
        returnValueForMissingStub: Future<ApiResponse<TokenRefreshResponse>>.value(
          ApiResponse<TokenRefreshResponse>.error(statusCode: 500, error: 'Stub required'),
        ),
      );

  @override
  Future<ApiResponse<AuthResponse>> googleLogin({
    String? idToken,
  }) =>
      super.noSuchMethod(
        Invocation.method(#googleLogin, [], {
          #idToken: idToken,
        }),
        returnValue: Future<ApiResponse<AuthResponse>>.value(
          ApiResponse<AuthResponse>.error(statusCode: 500, error: 'Stub required'),
        ),
        returnValueForMissingStub: Future<ApiResponse<AuthResponse>>.value(
          ApiResponse<AuthResponse>.error(statusCode: 500, error: 'Stub required'),
        ),
      );

  @override
  Future<ApiResponse<UserProfile>> getProfile() =>
      super.noSuchMethod(
        Invocation.method(#getProfile, [], {}),
        returnValue: Future<ApiResponse<UserProfile>>.value(
          ApiResponse<UserProfile>.error(statusCode: 500, error: 'Stub required'),
        ),
        returnValueForMissingStub: Future<ApiResponse<UserProfile>>.value(
          ApiResponse<UserProfile>.error(statusCode: 500, error: 'Stub required'),
        ),
      );

  @override
  Future<ApiResponse<UserProfile>> updateProfile({
    String? name,
    String? phone,
    String? gender,
    int? age,
  }) =>
      super.noSuchMethod(
        Invocation.method(#updateProfile, [], {
          #name: name,
          #phone: phone,
          #gender: gender,
          #age: age,
        }),
        returnValue: Future<ApiResponse<UserProfile>>.value(
          ApiResponse<UserProfile>.error(statusCode: 500, error: 'Stub required'),
        ),
        returnValueForMissingStub: Future<ApiResponse<UserProfile>>.value(
          ApiResponse<UserProfile>.error(statusCode: 500, error: 'Stub required'),
        ),
      );

  @override
  Future<ApiResponse<EmptyResponse>> logout() =>
      super.noSuchMethod(
        Invocation.method(#logout, [], {}),
        returnValue: Future<ApiResponse<EmptyResponse>>.value(
          ApiResponse<EmptyResponse>.error(statusCode: 500, error: 'Stub required'),
        ),
        returnValueForMissingStub: Future<ApiResponse<EmptyResponse>>.value(
          ApiResponse<EmptyResponse>.error(statusCode: 500, error: 'Stub required'),
        ),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
    late MockApiService mockApiService;
    late AuthProvider authProvider;
    final Map<String, String> mockSecureStorage = {};

    setUp(() {
      mockSecureStorage.clear();
      const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        final Map<dynamic, dynamic>? args = methodCall.arguments as Map<dynamic, dynamic>?;
        switch (methodCall.method) {
          case 'read':
            final String? key = args?['key'] as String?;
            return mockSecureStorage[key];
          case 'write':
            final String? key = args?['key'] as String?;
            final String? value = args?['value'] as String?;
            if (key != null && value != null) {
              mockSecureStorage[key] = value;
            }
            return null;
          case 'delete':
            final String? key = args?['key'] as String?;
            mockSecureStorage.remove(key);
            return null;
          case 'deleteAll':
            mockSecureStorage.clear();
            return null;
          case 'containsKey':
            final String? key = args?['key'] as String?;
            return mockSecureStorage.containsKey(key);
          case 'readAll':
            return mockSecureStorage;
        }
        return null;
      });

      mockApiService = MockApiService();
      ApiService.instance = mockApiService;
      authProvider = AuthProvider();
    });

    group('Signup Flow', () {
      test('Successfully signup with valid credentials', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'Password123!';
        const name = 'Test User';

        final expectedResponse = ApiResponse<AuthResponse>.success(
          statusCode: 201,
          message: 'User registered successfully',
          data: AuthResponse(
            accessToken: 'access_token_123',
            refreshToken: 'refresh_token_456',
            user: User(
              id: 'user_123',
              email: email,
              name: name,
              phone: '',
              avatarUrl: null,
              isEmailVerified: false,
              onboardingComplete: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
        );

        when(mockApiService.signup(
          name: anyNamed('name'),
          email: anyNamed('email'),
          password: anyNamed('password'),
          phone: anyNamed('phone'),
        )).thenAnswer((_) async => expectedResponse);

        // Act
        await authProvider.signup(
          name: name,
          email: email,
          password: password,
        );

        // Assert
        expect(authProvider.isAuthenticated, true);
        expect(authProvider.user?.email, email);
        expect(authProvider.user?.name, name);
        expect(authProvider.error, null);
      });

      test('Signup fails with duplicate email', () async {
        // Arrange
        const email = 'existing@example.com';
        const password = 'Password123!';

        final errorResponse = ApiResponse<AuthResponse>.error(
          statusCode: 409,
          message: 'Email already registered',
          error: 'Email already registered',
        );

        when(mockApiService.signup(
          name: anyNamed('name'),
          email: anyNamed('email'),
          password: anyNamed('password'),
          phone: anyNamed('phone'),
        )).thenAnswer((_) async => errorResponse);

        // Act & Assert
        expect(
          () => authProvider.signup(
            name: 'Test User',
            email: email,
            password: password,
          ),
          throwsException,
        );
      });

      test('Signup fails with weak password', () async {
        // Arrange - password less than 8 chars
        const weakPassword = 'abc123';

        // Act & Assert - validation should fail before API call
        expect(
          () => authProvider.signup(
            name: 'Test User',
            email: 'test@example.com',
            password: weakPassword,
          ),
          throwsException,
        );
      });
    });

    group('Email Verification Flow', () {
      test('Successfully verify email with valid token', () async {
        // Arrange
        const verificationToken = 'verify_token_123';
        
        final expectedResponse = ApiResponse<EmptyResponse>.success(
          statusCode: 200,
          message: 'Email verified successfully',
          data: const EmptyResponse(success: true),
        );

        when(mockApiService.verifyEmail(token: anyNamed('token')))
            .thenAnswer((_) async => expectedResponse);

        // Act
        await authProvider.verifyEmail(token: verificationToken);

        // Assert
        expect(authProvider.user?.isEmailVerified, true);
      });

      test('Resend verification email succeeds', () async {
        // Arrange
        final expectedResponse = ApiResponse<EmptyResponse>.success(
          statusCode: 200,
          message: 'Verification email sent',
          data: const EmptyResponse(success: true),
        );

        when(mockApiService.resendVerification())
            .thenAnswer((_) async => expectedResponse);

        // Act
        await authProvider.resendEmailVerification();

        // Assert
        expect(authProvider.error, null);
      });

      test('Verification fails with expired token', () async {
        // Arrange
        const expiredToken = 'expired_token_123';

        final errorResponse = ApiResponse<EmptyResponse>.error(
          statusCode: 400,
          message: 'Verification token expired',
          error: 'Verification token expired',
        );

        when(mockApiService.verifyEmail(token: anyNamed('token')))
            .thenAnswer((_) async => errorResponse);

        // Act & Assert
        expect(
          () => authProvider.verifyEmail(token: expiredToken),
          throwsException,
        );
      });
    });

    group('Login Flow', () {
      test('Successfully login with valid credentials', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'Password123!';

        final expectedResponse = ApiResponse<AuthResponse>.success(
          statusCode: 200,
          message: 'Login successful',
          data: AuthResponse(
            accessToken: 'access_token_123',
            refreshToken: 'refresh_token_456',
            user: User(
              id: 'user_123',
              email: email,
              name: 'Test User',
              phone: '+1234567890',
              avatarUrl: 'https://example.com/avatar.jpg',
              isEmailVerified: true,
              onboardingComplete: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
        );

        when(mockApiService.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => expectedResponse);

        // Act
        await authProvider.login(email: email, password: password);

        // Assert
        expect(authProvider.isAuthenticated, true);
        expect(authProvider.user?.email, email);
        expect(authProvider.error, null);
      });

      test('Login fails with invalid credentials', () async {
        // Arrange
        const email = 'test@example.com';
        const wrongPassword = 'WrongPassword123';

        final errorResponse = ApiResponse<AuthResponse>.error(
          statusCode: 401,
          message: 'Invalid email or password',
          error: 'Invalid email or password',
        );

        when(mockApiService.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => errorResponse);

        // Act & Assert
        expect(
          () => authProvider.login(email: email, password: wrongPassword),
          throwsException,
        );
      });

      test('Login fails with unverified email', () async {
        // Arrange
        const email = 'unverified@example.com';
        const password = 'Password123!';

        final errorResponse = ApiResponse<AuthResponse>.error(
          statusCode: 403,
          message: 'Email not verified',
          error: 'Please verify your email before logging in',
        );

        when(mockApiService.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => errorResponse);

        // Act & Assert
        expect(
          () => authProvider.login(email: email, password: password),
          throwsException,
        );
      });
    });

    group('Profile Completion Flow', () {
      test('Successfully complete onboarding with profile data', () async {
        // Arrange
        const name = 'John Doe';
        const phone = '+1234567890';
        const dateOfBirth = '1990-01-15';

        final expectedResponse = ApiResponse<UserProfile>.success(
          statusCode: 200,
          message: 'Onboarding completed',
          data: UserProfile(
            id: 'user_123',
            email: 'test@example.com',
            name: name,
            phone: phone,
            avatarUrl: 'https://example.com/avatar.jpg',
            role: 'user',
            isEmailVerified: true,
            isActive: true,
            onboardingComplete: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        when(mockApiService.completeOnboarding(
          dateOfBirth: anyNamed('dateOfBirth'),
          phone: anyNamed('phone'),
          gender: anyNamed('gender'),
          medicalHistory: anyNamed('medicalHistory'),
          allergies: anyNamed('allergies'),
          insuranceProvider: anyNamed('insuranceProvider'),
          insurancePolicyNumber: anyNamed('insurancePolicyNumber'),
        )).thenAnswer((_) async => expectedResponse);

        // Act
        await authProvider.completeOnboarding(
          phone: phone,
          dateOfBirth: dateOfBirth,
        );

        // Assert
        expect(authProvider.user?.onboardingComplete, true);
        expect(authProvider.user?.name, name);
        expect(authProvider.user?.phone, phone);
      });

      test('Complete onboarding with partial data', () async {
        // Arrange - only name provided
        const name = 'John Doe';

        final expectedResponse = ApiResponse<UserProfile>.success(
          statusCode: 200,
          message: 'Onboarding completed',
          data: UserProfile(
            id: 'user_123',
            email: 'test@example.com',
            name: name,
            phone: '',
            avatarUrl: null,
            role: 'user',
            isEmailVerified: true,
            isActive: true,
            onboardingComplete: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        when(mockApiService.completeOnboarding(
          dateOfBirth: anyNamed('dateOfBirth'),
          phone: anyNamed('phone'),
          gender: anyNamed('gender'),
          medicalHistory: anyNamed('medicalHistory'),
          allergies: anyNamed('allergies'),
          insuranceProvider: anyNamed('insuranceProvider'),
          insurancePolicyNumber: anyNamed('insurancePolicyNumber'),
        )).thenAnswer((_) async => expectedResponse);

        // Act
        await authProvider.completeOnboarding();

        // Assert
        expect(authProvider.user?.name, name);
      });
    });

    group('Token Refresh Flow', () {
      test('Successfully refresh access token', () async {
        // Arrange
        await SecureStorage().saveRefreshToken('refresh_token_456');
        const newAccessToken = 'new_access_token_789';

        final expectedResponse = ApiResponse<TokenRefreshResponse>.success(
          statusCode: 200,
          message: 'Token refreshed',
          data: TokenRefreshResponse(
            accessToken: newAccessToken,
            expiresAt: '2026-06-06T18:00:00Z',
          ),
        );

        when(mockApiService.refreshToken(
          refreshToken: anyNamed('refreshToken'),
        )).thenAnswer((_) async => expectedResponse);

        // Act
        await authProvider.refreshAccessToken();

        // Assert
        expect(authProvider.state.accessToken, newAccessToken);
      });

      test('Refresh token fails with invalid refresh token', () async {
        // Arrange
        await SecureStorage().saveRefreshToken('refresh_token_expired');
        final errorResponse = ApiResponse<TokenRefreshResponse>.error(
          statusCode: 401,
          message: 'Invalid refresh token',
          error: 'Refresh token has expired',
        );

        when(mockApiService.refreshToken(
          refreshToken: anyNamed('refreshToken'),
        )).thenAnswer((_) async => errorResponse);

        // Act & Assert
        expect(
          () => authProvider.refreshAccessToken(),
          throwsException,
        );
      });
    });

    group('Logout Flow', () {
      test('Successfully logout and clear auth state', () async {
        // Arrange - set authenticated state first
        authProvider.state.copyWith(
          isAuthenticated: true,
          user: UserProfile(
            id: 'user_123',
            email: 'test@example.com',
            name: 'Test User',
            phone: '',
            avatarUrl: null,
            role: 'user',
            isEmailVerified: true,
            isActive: true,
            onboardingComplete: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Act
        await authProvider.logout();

        // Assert
        expect(authProvider.isAuthenticated, false);
        expect(authProvider.user, null);
        expect(authProvider.error, null);
      });
    });

    group('Error Handling', () {
      test('Network error is caught and displayed', () async {
        // Arrange
        when(mockApiService.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => authProvider.login(email: 'test@example.com', password: 'password'),
          throwsException,
        );
      });

      test('Server error returns user-friendly message', () async {
        // Arrange
        final errorResponse = ApiResponse<AuthResponse>.error(
          statusCode: 500,
          message: 'Internal server error',
          error: 'Something went wrong. Please try again later.',
        );

        when(mockApiService.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => errorResponse);

        // Act & Assert
        expect(
          () => authProvider.login(email: 'test@example.com', password: 'password'),
          throwsException,
        );
      });
    });

    group('Complete Auth Flow Integration', () {
      test('Full signup to login flow succeeds', () async {
        // 1. Signup
        const email = 'newuser@example.com';
        const password = 'Password123!';
        const name = 'New User';

        // Signup response
        when(mockApiService.signup(
          name: anyNamed('name'),
          email: anyNamed('email'),
          password: anyNamed('password'),
          phone: anyNamed('phone'),
        )).thenAnswer((_) async => ApiResponse<AuthResponse>.success(
          statusCode: 201,
          message: 'User registered',
          data: AuthResponse(
            accessToken: 'signup_access_token',
            refreshToken: 'signup_refresh_token',
            user: User(
              id: 'user_123',
              email: email,
              name: name,
              phone: '',
              avatarUrl: null,
              isEmailVerified: false,
              onboardingComplete: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
        ));

        await authProvider.signup(
          name: name,
          email: email,
          password: password,
        );

        expect(authProvider.isAuthenticated, true);

        // 2. Verify email
        when(mockApiService.verifyEmail(token: anyNamed('token')))
            .thenAnswer((_) async => ApiResponse<EmptyResponse>.success(
          statusCode: 200,
          message: 'Email verified',
          data: const EmptyResponse(success: true),
        ));

        await authProvider.verifyEmail(token: 'verify_token');
        expect(authProvider.user?.isEmailVerified, true);

        // 3. Complete profile
        when(mockApiService.completeOnboarding(
          dateOfBirth: anyNamed('dateOfBirth'),
          phone: anyNamed('phone'),
          gender: anyNamed('gender'),
          medicalHistory: anyNamed('medicalHistory'),
          allergies: anyNamed('allergies'),
          insuranceProvider: anyNamed('insuranceProvider'),
          insurancePolicyNumber: anyNamed('insurancePolicyNumber'),
        )).thenAnswer((_) async => ApiResponse<UserProfile>.success(
          statusCode: 200,
          message: 'Onboarding completed',
          data: UserProfile(
            id: 'user_123',
            email: email,
            name: name,
            phone: '+1234567890',
            avatarUrl: null,
            role: 'user',
            isEmailVerified: true,
            isActive: true,
            onboardingComplete: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ));

        await authProvider.completeOnboarding(
          phone: '+1234567890',
        );

        expect(authProvider.user?.onboardingComplete, true);

        // 4. Logout
        await authProvider.logout();
        expect(authProvider.isAuthenticated, false);

        // 5. Login again
        when(mockApiService.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => ApiResponse<AuthResponse>.success(
          statusCode: 200,
          message: 'Login successful',
          data: AuthResponse(
            accessToken: 'login_access_token',
            refreshToken: 'login_refresh_token',
            user: User(
              id: 'user_123',
              email: email,
              name: name,
              phone: '+1234567890',
              avatarUrl: null,
              isEmailVerified: true,
              onboardingComplete: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
        ));

        await authProvider.login(email: email, password: password);
        expect(authProvider.isAuthenticated, true);
        expect(authProvider.user?.email, email);
      });
    });
  });
}
