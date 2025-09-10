import 'package:get/get.dart';
import 'package:sabbagh_app/core/services/dio_client.dart';
import 'package:sabbagh_app/presentation/controllers/user_controller.dart';
import 'package:sabbagh_app/presentation/modules/vendors/controller.dart';
import 'package:sabbagh_app/presentation/modules/vendors/repository.dart';

/// Binding for vendors
class VendorBinding extends Bindings {
  @override
  void dependencies() {
    // Register user controller if not already registered
    if (!Get.isRegistered<UserController>()) {
      Get.put(UserController(), permanent: true);
    }
    
    // Register vendor repository
    Get.lazyPut<VendorRepository>(() => VendorRepository(Get.find<DioClient>()));
    
    // Register vendor controller
    Get.lazyPut<VendorController>(() {
      final userController = Get.find<UserController>();
      return VendorController(
        Get.find<VendorRepository>(),
        userController,
      );
    });
  }
}