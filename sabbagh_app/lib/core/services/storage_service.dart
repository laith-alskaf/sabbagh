import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling local storage
class StorageService {
  late SharedPreferences _prefs;

  /// Keys for storage
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String languageKey = 'language';
  static const String themeKey = 'theme_mode';
  static const String rememberMeKey = 'remember_me';
  static const String firstRunKey = 'first_run';

  /// Initialize the storage service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save auth token
  Future<bool> saveToken(String token) async {
    return await _prefs.setString(tokenKey, token);
  }

  /// Get auth token
  Future<String?> getToken() async {
    return _prefs.getString(tokenKey);
  }

  /// Get auth token synchronously (for middleware)
  String? getTokenSync() {
    return _prefs.getString(tokenKey);
  }

  /// Clear auth token
  Future<bool> clearToken() async {
    return await _prefs.remove(tokenKey);
  }

  /// Save user data
  Future<bool> saveUser(Map<String, dynamic> userData) async {
    return await _prefs.setString(userKey, jsonEncode(userData));
  }

  /// Get user data
  Future<Map<String, dynamic>?> getUser() async {
    final userData = _prefs.getString(userKey);
    if (userData != null) {
      return jsonDecode(userData) as Map<String, dynamic>;
    }
    return null;
  }

  /// Clear user data
  Future<bool> clearUser() async {
    return await _prefs.remove(userKey);
  }

  /// Save language
  Future<bool> saveLanguage(String language) async {
    return await _prefs.setString(languageKey, language);
  }

  /// Get language
  Future<String?> getLanguage() async {
    return _prefs.getString(languageKey);
  }

  /// Save theme mode
  Future<bool> saveThemeMode(String themeMode) async {
    return await _prefs.setString(themeKey, themeMode);
  }

  /// Get theme mode
  Future<String?> getThemeMode() async {
    return _prefs.getString(themeKey);
  }

  /// Save remember me
  Future<bool> saveRememberMe(bool rememberMe) async {
    return await _prefs.setBool(rememberMeKey, rememberMe);
  }

  /// Get remember me
  Future<bool> getRememberMe() async {
    return _prefs.getBool(rememberMeKey) ?? false;
  }

  /// Save first run
  Future<bool> saveFirstRun(bool firstRun) async {
    return await _prefs.setBool(firstRunKey, firstRun);
  }

  /// Get first run
  Future<bool> isFirstRun() async {
    return _prefs.getBool(firstRunKey) ?? true;
  }

  /// Clear all data
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}