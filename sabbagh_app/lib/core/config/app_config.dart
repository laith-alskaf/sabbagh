

/// Application configuration class
class AppConfig {
  /// Base URL for API requests
  static const String baseUrl = 'https://sabbagh.vercel.app/api';
  /// API version
  static const String apiVersion = 'v1';

  /// Timeout duration for API requests in seconds
  static const int timeoutDuration = 1500;

  /// Default language code
  static const String defaultLanguage = 'ar';

  /// Supported languages
  static const List<String> supportedLanguages = ['ar', 'en'];

  /// App name
  static const String appName = 'Sabbagh Purchasing System';
}