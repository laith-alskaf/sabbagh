import 'package:get/get.dart';
import 'package:sabbagh_app/presentation/controllers/user_controller.dart';
import 'package:sabbagh_app/presentation/modules/auth/controller.dart';
import 'package:sabbagh_app/presentation/modules/profile/controller.dart';

/// Binding for profile
class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // Register user controller if not already registered
    if (!Get.isRegistered<UserController>()) {
      Get.put(UserController(), permanent: true);
    }
    
    // Register auth controller if not already registered
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController(), permanent: true);
    }
    
    // Register profile controller
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}