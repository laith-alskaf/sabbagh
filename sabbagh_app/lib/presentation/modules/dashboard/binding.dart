import 'package:get/get.dart';
import 'package:sabbagh_app/presentation/modules/auth/controller.dart';
import 'package:sabbagh_app/presentation/modules/dashboard/controller.dart';

/// Binding for dashboard module
class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // Register dashboard controller
    Get.lazyPut<DashboardController>(() => DashboardController());
    
    // Register auth controller if not already registered
    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut<AuthController>(() => AuthController());
    }
    
    // UserController should already be registered in InitialBinding
    // No need to register it again
  }
}