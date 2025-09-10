import 'package:sabbagh_app/core/services/dio_client.dart';
import 'package:sabbagh_app/data/dto/auth_dto.dart';

/// Repository for authentication
class AuthRepository {
  final DioClient _dioClient;

  /// Creates a new [AuthRepository]
  AuthRepository(this._dioClient);

  /// Login user
  Future<LoginResponseDto> login(String email, String password) async {
    final requestDto = LoginRequestDto(email: email, password: password);
    
    final response = await _dioClient.post('/auth/login', data: requestDto.toJson());
    
    return LoginResponseDto.fromJson(response as Map<String, dynamic>);
  }

  /// Get current user
  Future<CurrentUserDto> getCurrentUser() async {
    final response = await _dioClient.get('/auth/me');
    
    return GetCurrentUserResponseDto.fromJson(response as Map<String, dynamic>).user;
  }

  /// Change password
  Future<ChangePasswordResponseDto> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final requestDto = ChangePasswordRequestDto(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    
    final response = await _dioClient.post('/auth/change-password', data: requestDto.toJson());
    
    return ChangePasswordResponseDto.fromJson(response as Map<String, dynamic>);
  }

  /// Forgot password
  Future<ForgotPasswordResponseDto> forgotPassword(String email) async {
    final requestDto = ForgotPasswordRequestDto(email: email);
    
    final response = await _dioClient.post('/auth/forgot-password', data: requestDto.toJson());
    
    return ForgotPasswordResponseDto.fromJson(response as Map<String, dynamic>);
  }

  /// Reset password
  Future<ResetPasswordResponseDto> resetPassword(
    String token,
    String newPassword,
  ) async {
    final requestDto = ResetPasswordRequestDto(
      token: token,
      newPassword: newPassword,
    );
    
    final response = await _dioClient.post('/auth/reset-password', data: requestDto.toJson());
    
    return ResetPasswordResponseDto.fromJson(response as Map<String, dynamic>);
  }
}