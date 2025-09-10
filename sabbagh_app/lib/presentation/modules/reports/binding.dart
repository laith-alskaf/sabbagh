import 'package:get/get.dart';
import 'package:sabbagh_app/core/services/dio_client.dart';
import 'package:sabbagh_app/presentation/controllers/user_controller.dart';
import 'package:sabbagh_app/presentation/modules/reports/controller.dart';
import 'package:sabbagh_app/presentation/modules/reports/repository.dart';

/// Binding for reports
class ReportBinding extends Bindings {
  @override
  void dependencies() {
    // Register user controller if not already registered
    if (!Get.isRegistered<UserController>()) {
      Get.put(UserController(), permanent: true);
    }
    
    // Register report repository
    Get.lazyPut<ReportRepository>(() => ReportRepository(Get.find<DioClient>()));
    
    // Register report controller
    Get.lazyPut<ReportController>(() => ReportController(
      Get.find<ReportRepository>(),
      Get.find<UserController>(),
    ));
  }
}