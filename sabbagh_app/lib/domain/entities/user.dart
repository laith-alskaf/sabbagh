import 'package:sabbagh_app/domain/entities/user_role.dart';

/// User entity
class User {
  /// User ID
  final String id;
  
  /// User name
  final String name;
  
  /// User email
  final String email;
  
  /// User role
  final UserRole role;
  
  /// User department
  final String? department;
  
  /// User phone
  final String? phone;
  
  /// User active status
  final bool? active;
  
  /// User created at
  final DateTime createdAt;
  
  /// User updated at
  final DateTime updatedAt;

  /// Creates a new [User]
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.department,
    this.phone,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a user from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.fromString(json['role'] as String),
      department: json['department'] as String?,
      phone: json['phone'] as String?,
      active: json['is_active'] as bool? ?? json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert user to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toApiString(),
      'department': department,
      'phone': phone,
      'active': active,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of this user with the given fields replaced
  User copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? department,
    String? phone,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      phone: phone ?? this.phone,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}