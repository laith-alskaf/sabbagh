import 'package:sabbagh_app/domain/entities/user.dart';
import 'package:sabbagh_app/domain/entities/user_role.dart';

/// Login Request DTO
class LoginRequestDto {
  final String email;
  final String password;

  const LoginRequestDto({
    required this.email,
    required this.password,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

/// Login Response DTO - matches backend exactly
class LoginResponseDto {
  final bool success;
  final String message;
  final String token;
  final UserDto user;

  const LoginResponseDto({
    required this.success,
    required this.message,
    required this.token,
    required this.user,
  });

  /// Create from JSON response
  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
      token: json['token'] as String,
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  /// Convert to domain entity
  User toDomainUser() {
    return user.toDomain();
  }
}

/// User DTO - matches backend user object exactly
class UserDto {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? department;
  final String? phone;

  const UserDto({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.department,
    this.phone,
  });

  /// Create from JSON response
  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      department: json['department'] as String?,
      phone: json['phone'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'phone': phone,
    };
  }

  /// Convert to domain entity
  User toDomain() {
    return User(
      id: id,
      name: name,
      email: email,
      role: _mapRole(role),
      department: department,
      phone: phone,
      active: true, // Backend doesn't send this in login response
      createdAt: DateTime.now(), // Backend doesn't send this in login response
      updatedAt: DateTime.now(), // Backend doesn't send this in login response
    );
  }

  /// Map string role to UserRole enum
  static UserRole _mapRole(String role) {
    switch (role) {
      case 'manager':
        return UserRole.manager;
      case 'assistant_manager':
        return UserRole.assistantManager;
      case 'employee':
        return UserRole.employee;
      case 'guest':
        return UserRole.guest;
      case 'general_manager':
        return UserRole.generalManager;
      case 'finance_manager':
        return UserRole.financeManager;
      case 'procurement_officer':
        return UserRole.procurementOfficer;
      case 'auditor':
        return UserRole.auditor;
      default:
        return UserRole.guest;
    }
  }
}

/// Get Current User Response DTO
class GetCurrentUserResponseDto {
  final bool success;
  final CurrentUserDto user;

  const GetCurrentUserResponseDto({
    required this.success,
    required this.user,
  });

  /// Create from JSON response
  factory GetCurrentUserResponseDto.fromJson(Map<String, dynamic> json) {
    return GetCurrentUserResponseDto(
      success: json['success'] as bool,
      user: CurrentUserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// Current User DTO - matches /auth/me response
class CurrentUserDto {
  final String id;
  final String email;
  final String role;

  const CurrentUserDto({
    required this.id,
    required this.email,
    required this.role,
  });

  /// Create from JSON response
  factory CurrentUserDto.fromJson(Map<String, dynamic> json) {
    return CurrentUserDto(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
    };
  }
}

/// Change Password Request DTO
class ChangePasswordRequestDto {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordRequestDto({
    required this.currentPassword,
    required this.newPassword,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    };
  }
}

/// Change Password Response DTO
class ChangePasswordResponseDto {
  final bool success;
  final String message;

  const ChangePasswordResponseDto({
    required this.success,
    required this.message,
  });

  /// Create from JSON response
  factory ChangePasswordResponseDto.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
    );
  }
}

/// Forgot Password Request DTO
class ForgotPasswordRequestDto {
  final String email;

  const ForgotPasswordRequestDto({
    required this.email,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}

/// Forgot Password Response DTO
class ForgotPasswordResponseDto {
  final bool success;
  final String message;

  const ForgotPasswordResponseDto({
    required this.success,
    required this.message,
  });

  /// Create from JSON response
  factory ForgotPasswordResponseDto.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
    );
  }
}

/// Reset Password Request DTO
class ResetPasswordRequestDto {
  final String token;
  final String newPassword;

  const ResetPasswordRequestDto({
    required this.token,
    required this.newPassword,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'newPassword': newPassword,
    };
  }
}

/// Reset Password Response DTO
class ResetPasswordResponseDto {
  final bool success;
  final String message;

  const ResetPasswordResponseDto({
    required this.success,
    required this.message,
  });

  /// Create from JSON response
  factory ResetPasswordResponseDto.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
    );
  }
}