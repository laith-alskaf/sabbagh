import 'package:get/get.dart';
import 'package:sabbagh_app/core/services/dio_client.dart';
import 'package:sabbagh_app/presentation/controllers/user_controller.dart';
import 'package:sabbagh_app/presentation/modules/change_requests/controller.dart';
import 'package:sabbagh_app/presentation/modules/change_requests/repository.dart';

/// Binding for change requests module
class ChangeRequestBinding extends Bindings {
  @override
  void dependencies() {
    // Register repository
    Get.lazyPut<ChangeRequestRepository>(
      () => ChangeRequestRepository(Get.find<DioClient>()),
    );

    // Register controller
    Get.lazyPut<ChangeRequestController>(
      () => ChangeRequestController(
        Get.find<ChangeRequestRepository>(),
        Get.find<UserController>(),
      ),
    );
  }
}