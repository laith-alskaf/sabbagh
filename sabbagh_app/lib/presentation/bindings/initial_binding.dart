import 'package:get/get.dart';
import 'package:sabbagh_app/core/services/dio_client.dart';
import 'package:sabbagh_app/core/services/fcm_service.dart';
import 'package:sabbagh_app/core/services/storage_service.dart';
import 'package:sabbagh_app/localization/localization_service.dart';
import 'package:sabbagh_app/presentation/controllers/user_controller.dart';
import 'package:sabbagh_app/presentation/modules/auth/controller.dart';
import 'package:sabbagh_app/presentation/modules/notifications/controller.dart';

/// Initial binding for the application
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Register core services only if not already registered
    if (!Get.isRegistered<StorageService>()) {
      Get.put(StorageService(), permanent: true);
    }
    
    if (!Get.isRegistered<DioClient>()) {
      Get.put(DioClient(), permanent: true);
    }
    
    if (!Get.isRegistered<LocalizationService>()) {
      Get.put(LocalizationService(), permanent: true);
    }
    
    // Register controllers in correct order
    // UserController first since AuthController depends on it
    if (!Get.isRegistered<UserController>()) {
      Get.put(UserController(), permanent: true);
    }
    
    // Register AuthController as permanent to be available everywhere
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController(), permanent: true);
    }

    // Register FCMService (singleton) and initialize later in main
    if (!Get.isRegistered<FCMService>()) {
      Get.put(FCMService(), permanent: true);
    }

    // Preload NotificationsController globally for badge updates
    if (!Get.isRegistered<NotificationsController>()) {
      Get.put(NotificationsController(), permanent: true);
    }
  }
}