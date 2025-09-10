import 'package:get/get.dart';
import 'package:sabbagh_app/core/services/dio_client.dart';
import 'package:sabbagh_app/presentation/controllers/user_controller.dart';
import 'package:sabbagh_app/presentation/modules/purchase_orders/controller.dart';
import 'package:sabbagh_app/presentation/modules/purchase_orders/repository.dart';

/// Binding for purchase orders
class PurchaseOrderBinding extends Bindings {
  @override
  void dependencies() {
    // Register user controller if not already registered
    if (!Get.isRegistered<UserController>()) {
      Get.put(UserController(), permanent: true);
    }
    
    // Register purchase order repository
    Get.lazyPut<PurchaseOrderRepository>(() => PurchaseOrderRepository(Get.find<DioClient>()));
    
    // Register purchase order controller
    Get.lazyPut<PurchaseOrderController>(() => PurchaseOrderController(
      Get.find<PurchaseOrderRepository>(),
      Get.find<UserController>(),
    ));
  }
}