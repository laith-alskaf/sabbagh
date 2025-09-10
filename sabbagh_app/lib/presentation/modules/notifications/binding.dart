import 'package:get/get.dart';
import 'package:sabbagh_app/presentation/modules/notifications/controller.dart';

class NotificationsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<NotificationsController>()) {
      Get.put(NotificationsController(), permanent: true);
    }
  }
}