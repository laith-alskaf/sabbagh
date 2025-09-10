import 'package:get/get.dart';
import 'package:sabbagh_app/presentation/modules/users/controller.dart';

/// Binding for user management
class UserBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserManagementController>(() => UserManagementController());
  }
}