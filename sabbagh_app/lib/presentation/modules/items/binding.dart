import 'package:get/get.dart';
import 'package:sabbagh_app/core/services/dio_client.dart';
import 'package:sabbagh_app/presentation/controllers/user_controller.dart';
import 'package:sabbagh_app/presentation/modules/items/controller.dart';
import 'package:sabbagh_app/presentation/modules/items/repository.dart';

/// Binding for items
class ItemBinding extends Bindings {
  @override
  void dependencies() {
    // Register user controller if not already registered
    if (!Get.isRegistered<UserController>()) {
      Get.put(UserController(), permanent: true);
    }
    
    // Register item repository
    Get.lazyPut<ItemRepository>(() => ItemRepository(Get.find<DioClient>()));
    
    // Register item controller
    Get.lazyPut<ItemController>(() => ItemController(
      Get.find<ItemRepository>(),
      Get.find<UserController>(),
    ));
  }
}