import 'package:get/get.dart';
import 'package:sabbagh_app/core/services/dio_client.dart';
import 'package:sabbagh_app/presentation/modules/audit/controller.dart';
import 'package:sabbagh_app/presentation/modules/audit/repository.dart';

class AuditBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DioClient());
    Get.lazyPut(() => AuditRepository(Get.find<DioClient>()));
    Get.lazyPut(() => AuditController(Get.find<AuditRepository>()));
  }
}