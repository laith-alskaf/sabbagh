import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Application translations
class AppTranslations extends Translations {
  static final Map<String, Map<String, String>> _translations = {};

  /// Load translations from assets
  static Future<void> loadTranslations() async {
    try {
      // Load English translations
      final enString = await rootBundle.loadString('assets/l10n/en.json');
      final enMap = json.decode(enString) as Map<String, dynamic>;
      _translations['en'] = enMap.map(
        (key, value) => MapEntry(key, value.toString()),
      );

      // Load Arabic translations
      final arString = await rootBundle.loadString('assets/l10n/ar.json');
      final arMap = json.decode(arString) as Map<String, dynamic>;
      _translations['ar'] = arMap.map(
        (key, value) => MapEntry(key, value.toString()),
      );
    } catch (e) {
      '';
    }
  }

  @override
  Map<String, Map<String, String>> get keys => _translations;
}
