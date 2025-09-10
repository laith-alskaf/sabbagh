import 'package:get/get.dart';
import 'package:sabbagh_app/presentation/controllers/splash_controller.dart';

/// Binding for splash screen
class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SplashController());
  }
}