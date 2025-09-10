import 'package:get/get.dart';
import 'package:sabbagh_app/core/services/dio_client.dart';
import 'package:sabbagh_app/presentation/controllers/user_controller.dart';
import 'package:sabbagh_app/presentation/modules/auth/controller.dart';
import 'package:sabbagh_app/presentation/modules/auth/repository.dart';

/// Binding for authentication
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Register user controller if not already registered
    if (!Get.isRegistered<UserController>()) {
      Get.put(UserController(), permanent: true);
    }
    
    // Register auth repository
    Get.lazyPut<AuthRepository>(() => AuthRepository(Get.find<DioClient>()));
    
    // Register auth controller
    Get.lazyPut<AuthController>(() => AuthController());
  }
}