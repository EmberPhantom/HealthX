import 'package:equatable/equatable.dart';

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
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.tryParse(json['dateOfBirth']) : null,
      medicalHistory: json['medicalHistory'],
      allergies: json['allergies'] is String ? json['allergies'] : null,
      insuranceProvider: json['insuranceProvider'],
      insurancePolicyNumber: json['insurancePolicyNumber'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      onboardingComplete: json['onboardingComplete'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now() : DateTime.now(),
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
      role: 'user',
      isEmailVerified: isEmailVerified,
      isActive: true,
      onboardingComplete: onboardingComplete,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id, name, email, phone, avatarUrl, dateOfBirth,
    medicalHistory, allergies, insuranceProvider, insurancePolicyNumber,
    isEmailVerified, onboardingComplete, createdAt, updatedAt,
  ];
}

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
  final double? height;
  final double? weight;
  final bool? isDiabetesPatient;
  final bool? isBpPatient;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.height,
    this.weight,
    this.isDiabetesPatient,
    this.isBpPatient,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(dynamic json) {
    if (json == null) return const UserProfile.empty();
    final map = json as Map<String, dynamic>;

    final userMap = map.containsKey('user') ? map['user'] as Map<String, dynamic> : map;
    final patientMap = map.containsKey('patient') ? map['patient'] as Map<String, dynamic> : null;

    return UserProfile(
      id: userMap['_id'] ?? userMap['id'] ?? '',
      name: userMap['name'] ?? '',
      email: userMap['email'] ?? '',
      phone: userMap['phone'] ?? '',
      avatarUrl: userMap['avatarUrl'],
      gender: userMap['gender'],
      age: userMap['age'] is int ? userMap['age'] : null,
      role: userMap['role'] ?? 'user',
      isEmailVerified: userMap['isEmailVerified'] ?? false,
      isActive: userMap['isActive'] ?? true,
      onboardingComplete: userMap['onboardingComplete'] ?? false,
      createdAt: userMap['createdAt'] != null ? DateTime.tryParse(userMap['createdAt']) : null,
      updatedAt: userMap['updatedAt'] != null ? DateTime.tryParse(userMap['updatedAt']) : null,
      height: patientMap != null ? (patientMap['height'] as num?)?.toDouble() : (map['height'] as num?)?.toDouble(),
      weight: patientMap != null ? (patientMap['weight'] as num?)?.toDouble() : (map['weight'] as num?)?.toDouble(),
      isDiabetesPatient: patientMap != null ? patientMap['isDiabetesPatient'] as bool? : map['isDiabetesPatient'] as bool?,
      isBpPatient: patientMap != null ? patientMap['isBpPatient'] as bool? : map['isBpPatient'] as bool?,
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
        height = null,
        weight = null,
        isDiabetesPatient = null,
        isBpPatient = null,
        createdAt = null,
        updatedAt = null;

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
    'height': height,
    'weight': weight,
    'isDiabetesPatient': isDiabetesPatient,
    'isBpPatient': isBpPatient,
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
    double? height,
    double? weight,
    bool? isDiabetesPatient,
    bool? isBpPatient,
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
      height: height ?? this.height,
      weight: weight ?? this.weight,
      isDiabetesPatient: isDiabetesPatient ?? this.isDiabetesPatient,
      isBpPatient: isBpPatient ?? this.isBpPatient,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id, name, email, phone, avatarUrl, gender, age, role,
    isEmailVerified, isActive, onboardingComplete, height, weight,
    isDiabetesPatient, isBpPatient
  ];
}

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
    if (json == null) throw const FormatException('AuthResponse: received null json');
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

class TokenRefreshResponse extends Equatable {
  final String accessToken;
  final String? refreshToken;
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
