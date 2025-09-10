/// Base exception class
abstract class AppException implements Exception {
  /// Exception message
  final String message;

  /// Creates a new [AppException]
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Network exception
class NetworkException extends AppException {
  /// Creates a new [NetworkException]
  const NetworkException(super.message);
}

/// Server exception
class ServerException extends AppException {
  /// Creates a new [ServerException]
  const ServerException(super.message);
}

/// Authentication exception
class AuthException extends AppException {
  /// Creates a new [AuthException]
  const AuthException(super.message);
}

/// Not found exception
class NotFoundException extends AppException {
  /// Creates a new [NotFoundException]
  const NotFoundException(super.message);
}

/// Validation exception
class ValidationException extends AppException {
  /// List of validation errors
  final List<dynamic> errors;

  /// Creates a new [ValidationException]
  const ValidationException(super.message, this.errors);
}

/// Conflict exception
class ConflictException extends AppException {
  /// Creates a new [ConflictException]
  const ConflictException(super.message);
}

/// Cache exception
class CacheException extends AppException {
  /// Creates a new [CacheException]
  const CacheException(super.message);
}