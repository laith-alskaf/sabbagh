import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_routes.dart';
import 'package:sabbagh_app/core/services/dio_client.dart';
import 'package:sabbagh_app/core/services/storage_service.dart';
import 'package:sabbagh_app/domain/entities/user.dart';
import 'package:sabbagh_app/localization/localization_service.dart';
import 'package:sabbagh_app/presentation/controllers/user_controller.dart';
import 'package:sabbagh_app/presentation/modules/auth/controller.dart';

/// Controller for profile
class ProfileController extends GetxController {
  final DioClient _dioClient = Get.find<DioClient>();
  final StorageService _storageService = Get.find<StorageService>();
  final UserController _userController = Get.find<UserController>();
  final AuthController _authController = Get.find<AuthController>();
  final LocalizationService _localizationService =
      Get.find<LocalizationService>();

  /// Loading state
  final RxBool isLoading = false.obs;

  /// Error message
  final RxString errorMessage = ''.obs;

  /// Success message
  final RxString successMessage = ''.obs;

  /// Form key for change password
  final GlobalKey<FormState> changePasswordFormKey = GlobalKey<FormState>();

  /// Current password controller
  final TextEditingController currentPasswordController =
      TextEditingController();

  /// New password controller
  final TextEditingController newPasswordController = TextEditingController();

  /// Confirm password controller
  final TextEditingController confirmPasswordController =
      TextEditingController();

  /// Current password visibility
  final RxBool isCurrentPasswordObscured = true.obs;

  /// New password visibility
  final RxBool isNewPasswordObscured = true.obs;

  /// Confirm password visibility
  final RxBool isConfirmPasswordObscured = true.obs;

  /// Password strength
  final RxInt passwordStrength = 0.obs;

  /// Selected language
  final RxString selectedLanguage = ''.obs;

  /// Selected theme
  final RxString selectedTheme = 'system'.obs;

  /// Available themes
  final List<Map<String, String>> themes = [
    {'value': 'system', 'name': 'system_theme'},
    {'value': 'light', 'name': 'light_theme'},
    {'value': 'dark', 'name': 'dark_theme'},
  ];

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  /// Load settings
  Future<void> _loadSettings() async {
    selectedLanguage.value = _localizationService.currentLanguage.value;
    selectedTheme.value = await _storageService.getThemeMode() ?? 'system';
  }

  /// Change password
  Future<void> changePassword() async {
    if (!changePasswordFormKey.currentState!.validate()) {
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      errorMessage.value = 'passwords_do_not_match'.tr;
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    successMessage.value = '';

    try {
      final response = await _dioClient.post(
        '/auth/change-password',
        data: {
          'currentPassword': currentPasswordController.text,
          'newPassword': newPasswordController.text,
        },
      );

      if (response['success'] == true) {
        successMessage.value =
            response['message'] as String? ?? 'password_changed'.tr;

        // Clear form
        currentPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
        Get.snackbar(
          'success'.tr,
          response['message'],
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );
      } else {
        errorMessage.value = response['message'] as String? ?? 'error'.tr;
      }
    } catch (e) {
      errorMessage.value = e is ApiException ? e.message : 'server_error'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  /// Change language
  Future<void> changeLanguage(String language) async {
    selectedLanguage.value = language;
    await _localizationService.changeLanguage(language);
  }

  /// Change theme
  Future<void> changeTheme(String theme) async {
    selectedTheme.value = theme;
    await _storageService.saveThemeMode(theme);

    switch (theme) {
      case 'light':
        Get.changeThemeMode(ThemeMode.light);
        break;
      case 'dark':
        Get.changeThemeMode(ThemeMode.dark);
        break;
      case 'system':
      default:
        Get.changeThemeMode(ThemeMode.system);
        break;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authController.logout();
  }

  /// Toggle current password visibility
  void toggleCurrentPasswordVisibility() {
    isCurrentPasswordObscured.value = !isCurrentPasswordObscured.value;
  }

  /// Toggle new password visibility
  void toggleNewPasswordVisibility() {
    isNewPasswordObscured.value = !isNewPasswordObscured.value;
  }

  /// Toggle confirm password visibility
  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordObscured.value = !isConfirmPasswordObscured.value;
  }

  /// Validate password strength
  void validatePasswordStrength(String password) {
    int strength = 0;

    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;

    passwordStrength.value = strength;
  }

  /// Get user
  User? get user => _userController.user.value;

  /// Get user role
  String get userRole => _userController.role.toApiString().tr;

  /// Navigate to change password
  void navigateToChangePassword() {
    Get.toNamed(AppRoutes.changePassword);
  }

  /// Navigate to settings
  void navigateToSettings() {
    Get.toNamed(AppRoutes.settings);
  }
}
