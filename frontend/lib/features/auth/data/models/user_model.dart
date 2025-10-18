// ✅ Build runner GEREKTIRMEZ - Manuel serialization kullanıldı

class UserModel {
  final int id;
  final String? email;
  final String? phone;
  final String? name;
  final bool isActive;
  final bool isOnboardingCompleted;
  final bool isInitialSetupCompleted;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.id,
    this.email,
    this.phone,
    this.name,
    required this.isActive,
    required this.isOnboardingCompleted,
    required this.isInitialSetupCompleted,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      name: json['name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isOnboardingCompleted: json['is_onboarding_completed'] as bool? ?? false,
      isInitialSetupCompleted: json['is_initial_setup_completed'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'name': name,
      'is_active': isActive,
      'is_onboarding_completed': isOnboardingCompleted,
      'is_initial_setup_completed': isInitialSetupCompleted,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }
}

class AuthResponse {
  final UserModel user;
  final String token;
  final String message;

  AuthResponse({
    required this.user,
    required this.token,
    required this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
      'message': message,
    };
  }
}

