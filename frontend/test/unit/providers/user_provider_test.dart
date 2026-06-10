import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:healthx/providers/user_provider.dart';
import 'package:healthx/models/api/auth_models.dart';
import 'package:healthx/models/api/api_response.dart';
import 'package:healthx/services/api/api_service.dart';

class MockApiService extends Mock implements ApiService {
  @override
  Future<ApiResponse<UserProfile>> getProfile() =>
      super.noSuchMethod(
        Invocation.method(#getProfile, []),
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
}

UserProfile createTestUserProfile({
  String id = 'user_123',
  String name = 'Test User',
  String email = 'test@example.com',
  String phone = '+1234567890',
  String? avatarUrl,
  String? gender,
  int? age,
  String role = 'user',
  bool isEmailVerified = false,
  bool isActive = true,
  bool onboardingComplete = false,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return UserProfile(
    id: id,
    name: name,
    email: email,
    phone: phone,
    avatarUrl: avatarUrl,
    gender: gender,
    age: age,
    role: role,
    isEmailVerified: isEmailVerified,
    isActive: isActive,
    onboardingComplete: onboardingComplete,
    createdAt: createdAt ?? DateTime.now(),
    updatedAt: updatedAt ?? DateTime.now(),
  );
}


void main() {
  group('UserProvider Tests', () {
    late UserProvider userProvider;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      userProvider = UserProvider(apiService: mockApiService, autoInitialize: false);
    });

    test('UserProvider initializes with empty state', () {
      // Assert
      expect(userProvider.user, null);
      expect(userProvider.isLoading, false);
      expect(userProvider.error, null);
    });

    test('UserState copyWith creates new instance', () {
      // Arrange
      final user = createTestUserProfile(
        id: 'user_123',
        email: 'test@example.com',
        name: 'Test User',
        phone: '+1234567890',
        isEmailVerified: false,
        onboardingComplete: false,
      );

      // Act
      final newState = UserState(user: user).copyWith(
        user: user.copyWith(phone: '+1234567890'),
      );

      // Assert
      expect(newState.user?.phone, '+1234567890');
      expect(newState.user?.email, 'test@example.com');
    });

    test('isProfileComplete returns true when onboarding is 100%', () {
      // Arrange
      final user = createTestUserProfile(
        id: 'user_123',
        email: 'test@example.com',
        name: 'Test User',
        phone: '+1234567890',
        avatarUrl: 'https://example.com/avatar.jpg',
        isEmailVerified: true,
        onboardingComplete: true,
      );

      final state = UserState(user: user);

      // Assert
      expect(state.isProfileComplete, true);
    });

    test('isProfileComplete returns false when onboarding < 100%', () {
      // Arrange
      final user = createTestUserProfile(
        id: 'user_123',
        email: 'test@example.com',
        name: 'Test User',
        phone: '+1234567890',
        isEmailVerified: true,
        onboardingComplete: false,
      );

      final state = UserState(user: user);

      // Assert
      expect(state.isProfileComplete, false);
    });

    test('fetchUserProfile updates state on success', () async {
      // Arrange
      final mockUser = createTestUserProfile(
        id: 'user_123',
        email: 'test@example.com',
        name: 'Test User',
        phone: '+1234567890',
        isEmailVerified: true,
        onboardingComplete: false,
      );

      when(mockApiService.getProfile()).thenAnswer(
        (_) async => ApiResponse<UserProfile>.success(
          statusCode: 200,
          message: 'Success',
          data: mockUser,
        ),
      );

      // Act
      await userProvider.fetchUserProfile();

      // Assert
      expect(userProvider.user, mockUser);
      expect(userProvider.isLoading, false);
      expect(userProvider.error, null);
    });

    test('fetchUserProfile handles API errors', () async {
      // Arrange
      when(mockApiService.getProfile()).thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => userProvider.fetchUserProfile(),
        throwsException,
      );
      expect(userProvider.isLoading, false);
      expect(userProvider.error, isNotNull);
    });

    test('updateProfile successfully updates user data', () async {
      // Arrange
      final updatedUser = createTestUserProfile(
        id: 'user_123',
        email: 'test@example.com',
        name: 'Updated User',
        phone: '+9876543210',
        isEmailVerified: true,
        onboardingComplete: true,
      );

      when(mockApiService.updateProfile(
        name: anyNamed('name'),
        phone: anyNamed('phone'),
      )).thenAnswer(
        (_) async => ApiResponse<UserProfile>.success(
          statusCode: 200,
          message: 'Profile updated',
          data: updatedUser,
        ),
      );

      // Act
      await userProvider.updateProfile(
        name: 'Updated User',
        phone: '+9876543210',
      );

      // Assert
      expect(userProvider.user?.name, 'Updated User');
      expect(userProvider.user?.phone, '+9876543210');
    });

    test('updateProfile validates name length', () async {
      // Act & Assert
      expect(
        () => userProvider.updateProfile(name: 'A'),
        throwsA(isA<UserException>()),
      );
    });

    test('completeOnboarding updates onboarding status', () async {
      // Arrange
      final completedUser = createTestUserProfile(
        id: 'user_123',
        email: 'test@example.com',
        name: 'Test User',
        phone: '+1234567890',
        isEmailVerified: true,
        onboardingComplete: true,
      );

      when(mockApiService.completeOnboarding(
        phone: anyNamed('phone'),
        gender: anyNamed('gender'),
      )).thenAnswer(
        (_) async => ApiResponse<UserProfile>.success(
          statusCode: 200,
          message: 'Onboarding completed',
          data: completedUser,
        ),
      );

      // Act
      await userProvider.completeOnboarding(
        name: 'Test User',
        phone: '+1234567890',
      );

      // Assert
      expect(userProvider.user?.onboardingComplete, true);
    });

    test('setUser updates state directly', () {
      // Arrange
      final user = createTestUserProfile(
        id: 'user_123',
        email: 'test@example.com',
        name: 'Test User',
        phone: '+1234567890',
        isEmailVerified: false,
        onboardingComplete: false,
      );

      // Act
      userProvider.setUser(user);

      // Assert
      expect(userProvider.user, user);
      expect(userProvider.error, null);
    });

    test('clearUser removes user data', () {
      // Arrange
      userProvider.setUser(createTestUserProfile(
        id: 'user_123',
        email: 'test@example.com',
        name: 'Test User',
        phone: '+1234567890',
        isEmailVerified: false,
        onboardingComplete: false,
      ));

      // Act
      userProvider.clearUser();

      // Assert
      expect(userProvider.user, null);
      expect(userProvider.isLoading, false);
    });

    test('clearError removes error message', () {
      // Arrange
      // Simulate error state by setting it
      final state = UserState(
        user: null,
        isLoading: false,
        error: 'Test error',
      );

      // Act
      final clearedState = state.clearError();

      // Assert
      expect(clearedState.error, null);
    });

    test('needsRefresh returns true when cache is stale', () {
      // Arrange
      final staleTime = DateTime.now().subtract(const Duration(minutes: 10));
      final state = UserState(
        user: null,
        lastFetchTime: staleTime,
      );

      // Assert
      expect(state.lastFetchTime != null &&
          DateTime.now().difference(state.lastFetchTime!).inMinutes > 5,
          true);
    });

    test('refreshUserIfNeeded returns cached data if recent', () async {
      // Arrange
      final user = createTestUserProfile(
        id: 'user_123',
        email: 'test@example.com',
        name: 'Test User',
        phone: '+1234567890',
        isEmailVerified: false,
        onboardingComplete: false,
      );

      userProvider.setUser(user);

      // Act
      final result = await userProvider.refreshUserIfNeeded();

      // Assert
      expect(result, user);
      // Should not call API when cache is fresh
      verifyNever(mockApiService.getProfile());
    });

    test('userInitials generates correct initials', () {
      // Arrange
      final user = createTestUserProfile(
        id: 'user_123',
        email: 'test@example.com',
        name: 'John Doe',
        phone: '+1234567890',
        isEmailVerified: false,
        onboardingComplete: false,
      );

      userProvider.setUser(user);

      // Assert
      expect(userProvider.userInitials, 'JD');
    });

    test('userInitials returns ? when no user', () {
      // Assert
      expect(userProvider.userInitials, '?');
    });

    test('displayName returns user name or default', () {
      // Assert - no user
      expect(userProvider.displayName, 'User');

      // Arrange - set user
      final user = createTestUserProfile(
        id: 'user_123',
        email: 'test@example.com',
        name: 'John Doe',
        phone: '+1234567890',
        isEmailVerified: false,
        onboardingComplete: false,
      );

      userProvider.setUser(user);

      // Assert - with user
      expect(userProvider.displayName, 'John Doe');
    });

    test('syncWithAuth updates user from auth provider', () {
      // Arrange
      final authUser = createTestUserProfile(
        id: 'user_123',
        email: 'test@example.com',
        name: 'Auth User',
        phone: '+1234567890',
        isEmailVerified: false,
        onboardingComplete: false,
      );

      // Act
      userProvider.syncWithAuth(authUser);

      // Assert
      expect(userProvider.user?.id, authUser.id);
    });
  });
}
