import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling local storage
class StorageService {
  late SharedPreferences _prefs;

  /// Keys for storage
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String languageKey = 'language';
  static const String themeKey = 'theme_mode';

  /// Initialize the storage service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save auth token
  Future<void> saveToken(String token) async {
    await _prefs.setString(tokenKey, token);
  }

  /// Get auth token
  Future<String?> getToken() async {
    return _prefs.getString(tokenKey);
  }

  /// Clear auth token
  Future<void> clearToken() async {
    await _prefs.remove(tokenKey);
  }

  /// Save user data
  Future<void> saveUser(String userData) async {
    await _prefs.setString(userKey, userData);
  }

  /// Get user data
  Future<String?> getUser() async {
    return _prefs.getString(userKey);
  }

  /// Clear user data
  Future<void> clearUser() async {
    await _prefs.remove(userKey);
  }

  /// Save language
  Future<void> saveLanguage(String language) async {
    await _prefs.setString(languageKey, language);
  }

  /// Get language
  Future<String?> getLanguage() async {
    return _prefs.getString(languageKey);
  }

  /// Save theme mode
  Future<void> saveThemeMode(String themeMode) async {
    await _prefs.setString(themeKey, themeMode);
  }

  /// Get theme mode
  Future<String?> getThemeMode() async {
    return _prefs.getString(themeKey);
  }

  /// Clear all data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}