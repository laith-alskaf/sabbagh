import 'dart:developer';

import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_routes.dart';
import 'package:sabbagh_app/core/services/dio_client.dart';
import 'package:sabbagh_app/core/services/storage_service.dart';
import 'package:sabbagh_app/domain/entities/user.dart';
import 'package:sabbagh_app/domain/entities/user_role.dart';
import 'package:sabbagh_app/localization/localization_service.dart';
import 'package:sabbagh_app/presentation/controllers/user_controller.dart';
import 'package:sabbagh_app/presentation/modules/auth/repository.dart';

/// Controller for splash screen
class SplashController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final LocalizationService _localizationService =
      Get.find<LocalizationService>();
  final DioClient _dioClient = Get.find<DioClient>();
  late final AuthRepository _authRepository;

  @override
  void onInit() {
    super.onInit();

    try {
      _authRepository = AuthRepository(_dioClient);

      // Start initialization after a small delay to ensure UI is ready
      Future.delayed(const Duration(milliseconds: 100), () {
        _initialize();
      });
    } catch (e) {
      // Fallback to login on initialization error
      Future.delayed(const Duration(seconds: 2), () {
        Get.offAllNamed(AppRoutes.login);
      });
    }
  }

  /// Initialize the application
  Future<void> _initialize() async {
    try {
      await _loadUserPreferences();
      await Future.delayed(const Duration(seconds: 2));
      final token = await _storageService.getToken();

      if (token != null && token.isNotEmpty) {
        log('SplashController: Token found, verifying with server...');
        try {
          // Verify token with server
          final currentUser = await _authRepository.getCurrentUser();

          // Create user from server response
          final user = User(
            id: currentUser.id,
            name: currentUser.email, // Server only returns id, email, role
            email: currentUser.email,
            role: _mapStringToUserRole(currentUser.role),
            department: null,
            phone: null,
            active: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Get UserController and set user
          UserController userController;
          try {
            userController = Get.find<UserController>();
          } catch (e) {
            userController = Get.put(UserController(), permanent: true);
          }
          await userController.setUser(user);

          // Navigate based on user role
          _navigateBasedOnRole(user);
        } catch (e) {
          // Token is invalid, clear it and go to login
          await _storageService.clearToken();
          await _storageService.clearUser();
          Get.offAllNamed(AppRoutes.login);
        }
      } else {
        // Navigate to login
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (e) {
      // On error, clear everything and go to login
      await _storageService.clearAll();
      Get.offAllNamed(AppRoutes.login);
    }
  }

  /// Load user preferences
  Future<void> _loadUserPreferences() async {
    try {
      // Load language preference
      final language = await _storageService.getLanguage();
      if (language != null) {
        await _localizationService.changeLanguage(language);
      }

      // Load theme preference
      final themeMode = await _storageService.getThemeMode();
      if (themeMode != null) {
        // Apply theme mode if needed
        // This can be handled by a theme controller if implemented
      }
    } catch (e) {
      // Continue with default preferences
    }
  }

  /// Map string role to UserRole enum
  UserRole _mapStringToUserRole(String role) {
    switch (role.toLowerCase()) {
      case 'manager':
        return UserRole.manager;
      case 'assistant_manager':
        return UserRole.assistantManager;
      case 'employee':
        return UserRole.employee;
      case 'guest':
        return UserRole.guest;
      case 'general_manager':
        return UserRole.generalManager;
      case 'finance_manager':
        return UserRole.financeManager;
      case 'procurement_officer':
        return UserRole.procurementOfficer;
      case 'auditor':
        return UserRole.auditor;
      default:
        return UserRole.guest;
    }
  }

  /// Navigate based on user role
  void _navigateBasedOnRole(User user) {
    try {
      switch (user.role) {
        case UserRole.manager:
          Get.offAllNamed(AppRoutes.dashboard);
          break;
        case UserRole.assistantManager:
          Get.offAllNamed(AppRoutes.dashboard);
          break;
        case UserRole.employee:
        case UserRole.procurementOfficer:
        case UserRole.financeManager:
        case UserRole.generalManager:
        case UserRole.auditor:
          // These roles can't access dashboard, redirect to purchase orders
          Get.offAllNamed(AppRoutes.purchaseOrders);
          break;
        case UserRole.guest:
          // Guests have very limited access, redirect to purchase orders with view-only access
          Get.offAllNamed(AppRoutes.purchaseOrders);
          break;
      }

      // Log successful navigation
    } catch (e) {
      // Fallback to login on navigation error
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
