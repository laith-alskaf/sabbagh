import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_routes.dart';
import 'package:sabbagh_app/core/services/dio_client.dart';
import 'package:sabbagh_app/core/services/storage_service.dart';
import 'package:sabbagh_app/core/services/fcm_service.dart';
import 'package:sabbagh_app/presentation/modules/notifications/controller.dart';
import 'package:sabbagh_app/domain/entities/user.dart';
import 'package:sabbagh_app/domain/entities/user_role.dart';
import 'package:sabbagh_app/presentation/controllers/user_controller.dart';
import 'package:sabbagh_app/presentation/modules/auth/repository.dart';

/// Controller for authentication
class AuthController extends GetxController {
  final DioClient _dioClient = Get.find<DioClient>();
  final StorageService _storageService = Get.find<StorageService>();
  late final UserController _userController;
  late final AuthRepository _authRepository;

  /// Form key for validation
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  /// Email controller
  final TextEditingController emailController = TextEditingController();

  /// Password controller
  final TextEditingController passwordController = TextEditingController();

  /// Loading state
  final RxBool isLoading = false.obs;

  /// Password visibility state
  final RxBool isPasswordVisible = false.obs;

  /// Remember me state
  final RxBool rememberMe = false.obs;

  /// Error message
  final RxString errorMessage = ''.obs;

  /// Form key for forgot password validation
  final GlobalKey<FormState> forgotPasswordFormKey = GlobalKey<FormState>();

  /// Email controller for forgot password
  final TextEditingController forgotPasswordEmailController =
      TextEditingController();

  /// Loading state for forgot password
  final RxBool isForgotPasswordLoading = false.obs;

  /// Error message for forgot password
  final RxString forgotPasswordErrorMessage = ''.obs;

  /// Success message for forgot password
  final RxString forgotPasswordSuccessMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _userController = Get.find<UserController>();
    _authRepository = AuthRepository(_dioClient);
    _loadRememberMe();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    forgotPasswordEmailController.dispose();
    super.onClose();
  }

  /// Load remember me state
  Future<void> _loadRememberMe() async {
    rememberMe.value = await _storageService.getRememberMe();

    if (rememberMe.value) {
      final userData = await _storageService.getUser();
      if (userData != null && userData.containsKey('email')) {
        emailController.text = userData['email'] as String;
      }
    }
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  /// Login user
  Future<void> login() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    errorMessage.value = '';
    isLoading.value = true;

    try {
      // Use repository with DTO
      final loginResponse = await _authRepository.login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (loginResponse.success) {
        // Save token
        await _storageService.saveToken(loginResponse.token);

        // Convert DTO to domain entity and save user data
        final user = loginResponse.toDomainUser();
        await _userController.setUser(user);

        // Save remember me preference
        await _storageService.saveRememberMe(rememberMe.value);

        // Register FCM token with backend now that we have auth token
        try {
          final fcmService = Get.find<FCMService>();
          final token = fcmService.fcmToken;
          debugPrint('🔐 Auth Debug - FCM token available: ${token != null}');
          if (token != null && token.isNotEmpty) {
            debugPrint('🔐 Auth Debug - Updating existing FCM token');
            await fcmService.updateToken(token);
          } else {
            debugPrint('🔐 Auth Debug - Refreshing FCM token');
            await fcmService.refreshToken();
          }
          debugPrint('🔐 Auth Debug - FCM token registration completed');
        } catch (e) {
          debugPrint('🔐 Auth Debug - FCM token registration error: $e');
        }

        // Show success message
        Get.snackbar(
          'success'.tr,
          loginResponse.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 2),
        );

        // Navigate to dashboard based on user role
        _navigateBasedOnRole(user);
      } else {
        errorMessage.value = loginResponse.message;
      }
    } catch (e) {
      if (e is ApiException) {
        errorMessage.value = e.message;
      } else {
        errorMessage.value = 'server_error'.tr;
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Navigate based on user role
  void _navigateBasedOnRole(User user) {
    // Clear navigation stack and go to dashboard
    Get.offAllNamed(AppRoutes.dashboard);

    // Show role-specific welcome message
    Future.delayed(const Duration(milliseconds: 500), () {
      String welcomeMessage = '';
      switch (user.role) {
        case UserRole.manager:
          welcomeMessage = 'welcome_manager'.tr;
          break;
        case UserRole.financeManager:
          welcomeMessage = 'welcome_finance_manager'.tr;
          break;
        case UserRole.generalManager:
          welcomeMessage = 'welcome_general_manager'.tr;
          break;
        case UserRole.procurementOfficer:
          welcomeMessage = 'welcome_procurement_officer'.tr;
          break;
        case UserRole.assistantManager:
          welcomeMessage = 'welcome_assistant_manager'.tr;
          break;
        case UserRole.employee:
          welcomeMessage = 'welcome_employee'.tr;
          break;
        case UserRole.guest:
          welcomeMessage = 'welcome_guest'.tr;
        case UserRole.auditor:
          welcomeMessage = 'welcome_auditor'.tr;
          break;
      }

      if (welcomeMessage.isNotEmpty) {
        Get.snackbar(
          'welcome'.tr,
          welcomeMessage,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.blue.shade100,
          colorText: Colors.blue.shade800,
          duration: const Duration(seconds: 3),
        );
      }
    });
  }

  /// Logout user
  Future<void> logout() async {
    // Unregister FCM token from backend and delete locally
    try {
      final fcmService = Get.find<FCMService>();
      await fcmService.unregisterTokenFromServer();
      await fcmService.deleteToken();
    } catch (_) {}

    // Clear token and in-memory notifications
    await _storageService.clearToken();
    _storageService.clearAll();
    try {
      Get.find<NotificationsController>().clear();
    } catch (_) {}
    // Clear user data if remember me is not enabled
    if (!rememberMe.value) {
      await _userController.clearUser();
    } else {}

    // Clear form data
    emailController.clear();
    passwordController.clear();
    errorMessage.value = '';

    Get.offAllNamed(AppRoutes.login);

    // Show logout message
    Get.snackbar(
      'logged_out'.tr,
      'logged_out_successfully'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.grey.shade100,
      colorText: Colors.grey.shade800,
      duration: const Duration(seconds: 2),
    );
  }

  /// Navigate to forgot password screen
  void forgotPassword() {
    Get.toNamed(AppRoutes.forgotPassword);
  }

  /// Reset password
  Future<void> resetPassword() async {
    if (!forgotPasswordFormKey.currentState!.validate()) {
      return;
    }

    forgotPasswordErrorMessage.value = '';
    forgotPasswordSuccessMessage.value = '';
    isForgotPasswordLoading.value = true;

    try {
      final response = await _authRepository.forgotPassword(
        forgotPasswordEmailController.text.trim(),
      );

      if (response.success) {
        forgotPasswordSuccessMessage.value = response.message;
        Get.snackbar(
          'success'.tr,
          forgotPasswordSuccessMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 5),
        );

        // Navigate back to login after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          Get.offNamed(AppRoutes.login);
        });
      } else {
        forgotPasswordErrorMessage.value = response.message;
      }
    } catch (e) {
      forgotPasswordErrorMessage.value =
          e is ApiException ? e.message : 'server_error'.tr;
    } finally {
      isForgotPasswordLoading.value = false;
    }
  }
}
