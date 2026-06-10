/// API Models and DTOs for authentication and user management
import 'package:equatable/equatable.dart';

// ════════════════════════════════════════════════════════════════════
// Authentication Request Models
// ════════════════════════════════════════════════════════════════════

class SignupRequest extends Equatable {
  final String name;
  final String email;
  final String password;
  final String? phone; // Optional — phone is not required

  const SignupRequest({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
    };
    if (phone != null && phone!.isNotEmpty) {
      map['phone'] = phone;
    }
    return map;
  }

  @override
  List<Object?> get props => [name, email, password, phone];
}

class LoginRequest extends Equatable {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };

  @override
  List<Object?> get props => [email, password];
}

class RefreshTokenRequest extends Equatable {
  final String refreshToken;

  const RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {
    'refreshToken': refreshToken,
  };

  @override
  List<Object?> get props => [refreshToken];
}

/// Google OAuth request — sends idToken from Google Sign-In SDK
class OAuthRequest extends Equatable {
  final String idToken;

  const OAuthRequest({required this.idToken});

  Map<String, dynamic> toJson() => {
    'idToken': idToken, // FIXED: was 'token', backend expects 'idToken'
  };

  @override
  List<Object?> get props => [idToken];
}

// ════════════════════════════════════════════════════════════════════
// User Model
// ════════════════════════════════════════════════════════════════════

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? medicalHistory;
  final String? allergies;
  final String? insuranceProvider;
  final String? insurancePolicyNumber;
  final bool isEmailVerified;
  final bool onboardingComplete;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.dateOfBirth,
    this.medicalHistory,
    this.allergies,
    this.insuranceProvider,
    this.insurancePolicyNumber,
    required this.isEmailVerified,
    required this.onboardingComplete,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatarUrl: json['avatarUrl'],
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth']) : null,
      medicalHistory: json['medicalHistory'],
      allergies: json['allergies'] is String ? json['allergies'] : null,
      insuranceProvider: json['insuranceProvider'],
      insurancePolicyNumber: json['insurancePolicyNumber'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      onboardingComplete: json['onboardingComplete'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'avatarUrl': avatarUrl,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'medicalHistory': medicalHistory,
    'allergies': allergies,
    'insuranceProvider': insuranceProvider,
    'insurancePolicyNumber': insurancePolicyNumber,
    'isEmailVerified': isEmailVerified,
    'onboardingComplete': onboardingComplete,
  };

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? medicalHistory,
    String? allergies,
    String? insuranceProvider,
    String? insurancePolicyNumber,
    bool? isEmailVerified,
    bool? onboardingComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      allergies: allergies ?? this.allergies,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      insurancePolicyNumber: insurancePolicyNumber ?? this.insurancePolicyNumber,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  UserProfile toUserProfile() {
    return UserProfile(
      id: id,
      name: name,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
      role: 'user', // Default role
      isEmailVerified: isEmailVerified,
      isActive: true,
      onboardingComplete: onboardingComplete,
      createdAt: createdAt,
      updatedAt: updatedAt,
      rawJson: toJson(),
    );
  }

  @override
  List<Object?> get props => [
    id, name, email, phone, avatarUrl, dateOfBirth,
    medicalHistory, allergies, insuranceProvider, insurancePolicyNumber,
    isEmailVerified, onboardingComplete, createdAt, updatedAt,
  ];
}

// ════════════════════════════════════════════════════════════════════
// UserProfile — returned by /users/me and profile update endpoints
// ════════════════════════════════════════════════════════════════════

class UserProfile extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String? gender;
  final int? age;
  final String role;
  final bool isEmailVerified;
  final bool isActive;
  final bool onboardingComplete;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? rawJson;

  bool get isPremium => false;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.gender,
    this.age,
    required this.role,
    required this.isEmailVerified,
    required this.isActive,
    required this.onboardingComplete,
    this.createdAt,
    this.updatedAt,
    this.rawJson,
  });

  factory UserProfile.fromJson(dynamic json) {
    if (json == null) return const UserProfile.empty();
    final map = json as Map<String, dynamic>;
    return UserProfile(
      id: map['_id'] ?? map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      avatarUrl: map['avatarUrl'],
      gender: map['gender'],
      age: map['age'] is int ? map['age'] : null,
      role: map['role'] ?? 'user',
      isEmailVerified: map['isEmailVerified'] ?? false,
      isActive: map['isActive'] ?? true,
      onboardingComplete: map['onboardingComplete'] ?? false,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
      rawJson: map,
    );
  }

  const UserProfile.empty()
      : id = '',
        name = '',
        email = '',
        phone = '',
        avatarUrl = null,
        gender = null,
        age = null,
        role = 'user',
        isEmailVerified = false,
        isActive = true,
        onboardingComplete = false,
        createdAt = null,
        updatedAt = null,
        rawJson = null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'avatarUrl': avatarUrl,
    'gender': gender,
    'age': age,
    'role': role,
    'isEmailVerified': isEmailVerified,
    'isActive': isActive,
    'onboardingComplete': onboardingComplete,
  };

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? gender,
    int? age,
    String? role,
    bool? isEmailVerified,
    bool? isActive,
    bool? onboardingComplete,
    Map<String, dynamic>? rawJson,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isActive: isActive ?? this.isActive,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      createdAt: createdAt,
      updatedAt: updatedAt,
      rawJson: rawJson ?? this.rawJson,
    );
  }

  @override
  List<Object?> get props => [id, name, email, phone, avatarUrl, gender, age, role, isEmailVerified, isActive, onboardingComplete];
}

// ════════════════════════════════════════════════════════════════════
// Authentication Response
// ════════════════════════════════════════════════════════════════════

class AuthResponse extends Equatable {
  final String accessToken;
  final String refreshToken;
  final User user;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(dynamic json) {
    if (json == null) throw FormatException('AuthResponse: received null json');

    final map = json as Map<String, dynamic>;
    return AuthResponse(
      accessToken: map['accessToken'] ?? map['access_token'] ?? '',
      refreshToken: map['refreshToken'] ?? map['refresh_token'] ?? '',
      user: User.fromJson(map['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'user': user.toJson(),
  };

  @override
  List<Object?> get props => [accessToken, refreshToken, user];
}

// ════════════════════════════════════════════════════════════════════
// Token Refresh Response
// ════════════════════════════════════════════════════════════════════

class TokenRefreshResponse extends Equatable {
  final String accessToken;
  final String? refreshToken; // Backend may rotate refresh token
  final String? expiresAt;

  const TokenRefreshResponse({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  factory TokenRefreshResponse.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return TokenRefreshResponse(
      accessToken: map['accessToken'] ?? '',
      refreshToken: map['refreshToken'],
      expiresAt: map['expiresAt'],
    );
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresAt];
}

// ════════════════════════════════════════════════════════════════════
// Onboarding Status
// ════════════════════════════════════════════════════════════════════

class OnboardingStatus extends Equatable {
  final int completionPercentage;
  final List<OnboardingSection> sections;
  final bool isComplete;
  final bool emailVerified;
  final bool profileCompleted;

  const OnboardingStatus({
    required this.completionPercentage,
    required this.sections,
    required this.isComplete,
    required this.emailVerified,
    required this.profileCompleted,
  });

  factory OnboardingStatus.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    final percentage = map['completionPercentage'] ?? 0;
    final sectionsJson = map['sections'] as List? ?? [];
    
    return OnboardingStatus(
      completionPercentage: (percentage is double) ? percentage.toInt() : (percentage as int),
      sections: sectionsJson
          .map((s) => OnboardingSection.fromJson(s as Map<String, dynamic>))
          .toList(),
      isComplete: map['isComplete'] ?? map['profileCompleted'] ?? false,
      emailVerified: map['emailVerified'] ?? false,
      profileCompleted: map['profileCompleted'] ?? false,
    );
  }

  @override
  List<Object?> get props => [completionPercentage, sections, isComplete, emailVerified, profileCompleted];
}

class OnboardingSection extends Equatable {
  final String name;
  final bool completed;
  final List<String> incompleteFields;

  const OnboardingSection({
    required this.name,
    required this.completed,
    required this.incompleteFields,
  });

  factory OnboardingSection.fromJson(Map<String, dynamic> json) {
    return OnboardingSection(
      name: json['name'] ?? '',
      completed: json['completed'] ?? false,
      incompleteFields: List<String>.from(json['incompleteFields'] ?? []),
    );
  }

  @override
  List<Object?> get props => [name, completed, incompleteFields];
}

class UpdateProfileRequest extends Equatable {
  final String? name;
  final String? phone;
  final String? avatar;

  const UpdateProfileRequest({this.name, this.phone, this.avatar});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (phone != null) map['phone'] = phone;
    if (avatar != null) map['avatar'] = avatar;
    return map;
  }

  @override
  List<Object?> get props => [name, phone, avatar];
}

class CompleteProfileRequest extends Equatable {
  final String? profilePicture;
  final String? name;
  final String? phone;
  final String? dateOfBirth;
  final String? gender;
  final bool? hasInsurance;
  final String? insuranceProvider;

  const CompleteProfileRequest({
    this.profilePicture,
    this.name,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.hasInsurance,
    this.insuranceProvider,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (profilePicture != null) map['profilePicture'] = profilePicture;
    if (name != null) map['name'] = name;
    if (phone != null) map['phone'] = phone;
    if (dateOfBirth != null) map['dateOfBirth'] = dateOfBirth;
    if (gender != null) map['gender'] = gender;
    if (hasInsurance != null) map['hasInsurance'] = hasInsurance;
    if (insuranceProvider != null) map['insuranceProvider'] = insuranceProvider;
    return map;
  }

  @override
  List<Object?> get props => [profilePicture, name, phone, dateOfBirth, gender, hasInsurance, insuranceProvider];
}

// ════════════════════════════════════════════════════════════════════
// Profile Update Request (Legacy/Alternative)
// ════════════════════════════════════════════════════════════════════

class ProfileUpdateRequest extends Equatable {
  final String? name;
  final String? phone;
  final String? gender;
  final int? age;
  final String? dateOfBirth;
  final String? medicalHistory;
  final String? allergies;
  final String? insuranceProvider;
  final String? insurancePolicyNumber;

  const ProfileUpdateRequest({
    this.name,
    this.phone,
    this.gender,
    this.age,
    this.dateOfBirth,
    this.medicalHistory,
    this.allergies,
    this.insuranceProvider,
    this.insurancePolicyNumber,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (phone != null) map['phone'] = phone;
    if (gender != null) map['gender'] = gender;
    if (age != null) map['age'] = age;
    if (dateOfBirth != null) map['dateOfBirth'] = dateOfBirth;
    if (medicalHistory != null) map['medicalHistory'] = medicalHistory;
    if (allergies != null) map['allergies'] = allergies;
    if (insuranceProvider != null) map['insuranceProvider'] = insuranceProvider;
    if (insurancePolicyNumber != null) map['insurancePolicyNumber'] = insurancePolicyNumber;
    return map;
  }

  @override
  List<Object?> get props => [name, phone, gender, age, dateOfBirth, medicalHistory, allergies, insuranceProvider, insurancePolicyNumber];
}
