import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/config/app_config.dart';
import 'package:sabbagh_app/core/services/storage_service.dart';
import 'package:sabbagh_app/localization/app_translations.dart';

/// Service for handling localization
class LocalizationService extends GetxService {
  final StorageService _storageService = Get.find<StorageService>();

  /// Current language code
  final RxString currentLanguage = AppConfig.defaultLanguage.obs;

  /// Initialize the localization service
  Future<LocalizationService> init() async {
    // Load translations from assets
    await AppTranslations.loadTranslations();

    // Load saved language
    final savedLanguage = await _storageService.getLanguage();

    if (savedLanguage != null &&
        AppConfig.supportedLanguages.contains(savedLanguage)) {
      currentLanguage.value = savedLanguage;
      await changeLanguage(savedLanguage);
    } else {
      await changeLanguage(AppConfig.defaultLanguage);
    }

    return this;
  }

  /// Change the application language
  Future<void> changeLanguage(String languageCode) async {
    if (!AppConfig.supportedLanguages.contains(languageCode)) {
      return;
    }

    // Update current language
    currentLanguage.value = languageCode;

    // Save language preference
    await _storageService.saveLanguage(languageCode);

    // Update locale
    final locale = Locale(languageCode);
    Get.updateLocale(locale);
  }

  /// Check if language is RTL
  bool _isRtl(String languageCode) {
    return languageCode == 'ar';
  }

  /// Get current text direction
  TextDirection get textDirection {
    return _isRtl(currentLanguage.value)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  /// Get available languages
  List<Map<String, String>> get availableLanguages => [
    {'code': 'ar', 'name': 'العربية'},
    {'code': 'en', 'name': 'English'},
  ];
}
