import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/presentation/modules/audit/repository.dart';

class AuditController extends GetxController {
  final AuditRepository repository;
  AuditController(this.repository);

  // State
  final logs = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  // Filters
  final offset = 0.obs;
  final limit = 10.obs;
  final action =
      ''.obs; // create, update, delete, login, logout, approve, reject, submit
  final entityType =
      ''.obs; // user, vendor, item, purchase_order, change_request
  TextEditingController entityId = TextEditingController();
  final actorId = ''.obs;
  final startDateIso = ''.obs; // ISO 8601
  final endDateIso = ''.obs; // ISO 8601
  final sort = 'created_at'.obs;
  final order = 'desc'.obs; // asc | desc

  RxBool isExictMore = true.obs;

  // Lookups
  final users = <Map<String, dynamic>>[].obs; // [{id, label}]
  final entities = <Map<String, dynamic>>[].obs; // depends on entityType
  final isLoadingUsers = false.obs;
  final isLoadingEntities = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Preload users for actor selector
    fetchUsers();
    fetchLogs();
  }

  Future<void> fetchUsers() async {
    try {
      isLoadingUsers.value = true;
      final list = await repository.listUsers(limit: 10);
      users.assignAll(list);
    } catch (e) {
      // keep silent, UI shows fallback
    } finally {
      isLoadingUsers.value = false;
    }
  }

  Future<void> fetchLogs({bool reset = false}) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      if (reset) {
        isExictMore.value = true;
        offset.value = 0;
      }

      final res = await repository.getAuditLogs(
        offset: offset.value,
        limit: limit.value,
        action: action.value.isEmpty ? null : action.value,
        entityType: entityType.value.isEmpty ? null : entityType.value,
        entityId: entityId.text.isEmpty ? null : entityId.text,
        actorId: actorId.value.isEmpty ? null : actorId.value,
        startDateIso: startDateIso.value.isEmpty ? null : startDateIso.value,
        endDateIso: endDateIso.value.isEmpty ? null : endDateIso.value,
        sort: sort.value,
        order: order.value,
      );
      logs.assignAll(List<Map<String, dynamic>>.from(res['data'] ?? []));
      if (logs.isEmpty) {
        isExictMore.value = false;
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh purchase orders
  Future<void> refreshAuditLogs() async {
    onInit();
  }

  Future<void> nextPage() async {
    final currentOffset = offset.value;

    if (isExictMore.value) {
      offset.value = currentOffset + limit.value;
      await fetchLogs();
    }
  }

  Future<void> prevPage() async {
    if (offset.value > 0) {
      isExictMore.value = true;
      offset.value = offset.value - limit.value;
      await fetchLogs();
    }
  }

  Future<void> fetchEntities() async {
    final type = entityType.value;
    if (type.isEmpty) {
      entities.clear();
      return;
    }
    try {
      isLoadingEntities.value = true;
      final list = await repository.listEntitiesByType(type, limit: 50);
      entities.assignAll(list);
    } catch (e) {
      entities.clear();
    } finally {
      isLoadingEntities.value = false;
    }
  }
}
