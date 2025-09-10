import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/data/dto/change_request_dto.dart';
import 'package:sabbagh_app/presentation/controllers/user_controller.dart';
import 'package:sabbagh_app/presentation/modules/change_requests/repository.dart';

/// Controller for change requests
class ChangeRequestController extends GetxController {
  final ChangeRequestRepository _repository;
  final UserController _userController;

  /// Creates a new [ChangeRequestController]
  ChangeRequestController(this._repository, this._userController);

  /// Loading states
  final RxBool isLoading = false.obs;
  final RxBool isLoadingDetails = false.obs;
  final RxBool isProcessing = false.obs;

  /// Change requests data
  final RxList<ChangeRequestDto> changeRequests = <ChangeRequestDto>[].obs;
  final Rx<ChangeRequestDto?> selectedChangeRequest = Rx<ChangeRequestDto?>(
    null,
  );

  /// Filters
  final Rx<ChangeRequestStatus?> statusFilter = Rx<ChangeRequestStatus?>(null);
  final Rx<EntityType?> entityTypeFilter = Rx<EntityType?>(null);
  final RxString searchQuery = ''.obs;

  /// Pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalCount = 0.obs;
  final int pageSize = 20;

  /// Form controllers for review
  final TextEditingController reasonController = TextEditingController();
  final GlobalKey<FormState> reviewFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    loadChangeRequests();
  }

  @override
  void onClose() {
    reasonController.dispose();
    super.onClose();
  }

  /// Load change requests with current filters
  Future<void> loadChangeRequests({bool refresh = false}) async {
    try {
      if (refresh) {
        currentPage.value = 1;
        changeRequests.clear();
      }

      isLoading.value = true;

      final offset = (currentPage.value - 1) * pageSize;
      final response = await _repository.getChangeRequests(
        status: statusFilter.value,
        entityType: entityTypeFilter.value,
        limit: pageSize,
        offset: offset,
      );

      if (response.success) {
        if (refresh) {
          changeRequests.value = response.data;
        } else {
          changeRequests.addAll(response.data);
        }
        totalCount.value = response.count;
      } else {
        Get.snackbar(
          'error'.tr,
          response.message ?? 'failed_to_load_change_requests'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_load_change_requests'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more change requests (pagination)
  Future<void> loadMoreChangeRequests() async {
    if (isLoading.value) return;

    final totalPages = (totalCount.value / pageSize).ceil();
    if (currentPage.value >= totalPages) return;

    currentPage.value++;
    await loadChangeRequests();
  }

  /// Refresh change requests
  Future<void> refreshChangeRequests() async {
    await loadChangeRequests(refresh: true);
  }

  /// Get change request by ID
  Future<void> getChangeRequestById(String id) async {
    try {
      isLoadingDetails.value = true;

      final response = await _repository.getChangeRequestById(id);
      if (response.success) {
        selectedChangeRequest.value = response.data;
      } else {
        Get.snackbar(
          'error'.tr,
          response.message ?? 'failed_to_load_change_request'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_load_change_request'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingDetails.value = false;
    }
  }

  /// Approve change request
  Future<void> approveChangeRequest(String id) async {
    try {
      isProcessing.value = true;

      final response = await _repository.approveChangeRequest(
        id,
        reason:
            reasonController.text.trim().isEmpty
                ? null
                : reasonController.text.trim(),
      );

      if (response.success) {
        Get.snackbar(
          'success'.tr,
          'change_request_approved'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Update the change request in the list
        final index = changeRequests.indexWhere((cr) => cr.id == id);
        if (index != -1) {
          changeRequests[index] = response.data;
        }

        // Update selected change request if it's the same
        if (selectedChangeRequest.value?.id == id) {
          selectedChangeRequest.value = response.data;
        }

        reasonController.clear();
        Get.back(); // Close dialog
      } else {
        Get.snackbar(
          'error'.tr,
          response.message ?? 'failed_to_approve_change_request'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_approve_change_request'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  /// Reject change request
  Future<void> rejectChangeRequest(String id) async {
    if (reviewFormKey.currentState == null ||
        !reviewFormKey.currentState!.validate()) {
      return;
    }

    try {
      isProcessing.value = true;

      final response = await _repository.rejectChangeRequest(
        id,
        reason: reasonController.text.trim(),
      );

      if (response.success) {
        Get.snackbar(
          'success'.tr,
          'change_request_rejected'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );

        // Update the change request in the list
        final index = changeRequests.indexWhere((cr) => cr.id == id);
        if (index != -1) {
          changeRequests[index] = response.data;
        }

        // Update selected change request if it's the same
        if (selectedChangeRequest.value?.id == id) {
          selectedChangeRequest.value = response.data;
        }

        reasonController.clear();
        Get.back(); // Close dialog
      } else {
        Get.snackbar(
          'error'.tr,
          response.message ?? 'failed_to_reject_change_request'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_reject_change_request'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  /// Apply status filter
  void applyStatusFilter(ChangeRequestStatus? status) {
    statusFilter.value = status;
    refreshChangeRequests();
  }

  /// Apply entity type filter
  void applyEntityTypeFilter(EntityType? entityType) {
    entityTypeFilter.value = entityType;
    refreshChangeRequests();
  }

  /// Clear all filters
  void clearFilters() {
    statusFilter.value = null;
    entityTypeFilter.value = null;
    searchQuery.value = '';
    refreshChangeRequests();
  }

  /// Get filtered change requests based on search query
  List<ChangeRequestDto> get filteredChangeRequests {
    if (searchQuery.value.isEmpty) {
      return changeRequests;
    }

    final query = searchQuery.value.toLowerCase();
    return changeRequests.where((cr) {
      return cr.displayTitle.toLowerCase().contains(query) ||
          (cr.requesterName?.toLowerCase().contains(query) ?? false) ||
          (cr.reason?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  /// Check if user can approve/reject change requests
  bool get canReviewChangeRequests => _userController.isManager;

  /// Check if user can view change requests
  bool get canViewChangeRequests =>
      _userController.isManager || _userController.isAssistantManager;

  /// Get status display text
  String getStatusDisplayText(ChangeRequestStatus status) {
    switch (status) {
      case ChangeRequestStatus.pending:
        return 'pending'.tr;
      case ChangeRequestStatus.approved:
        return 'approved'.tr;
      case ChangeRequestStatus.rejected:
        return 'rejected'.tr;
    }
  }

  /// Get entity type display text
  String getEntityTypeDisplayText(EntityType entityType) {
    switch (entityType) {
      case EntityType.vendor:
        return 'vendor'.tr;
      case EntityType.item:
        return 'item'.tr;
      case EntityType.purchaseOrder:
        return 'purchase_order'.tr;
    }
  }

  /// Get operation display text
  String getOperationDisplayText(OperationType operation) {
    switch (operation) {
      case OperationType.create:
        return 'create'.tr;
      case OperationType.update:
        return 'update'.tr;
      case OperationType.delete:
        return 'delete'.tr;
    }
  }

  /// Show approve confirmation dialog
  void showApproveDialog(BuildContext context, String id) {
    reasonController.clear();

    Get.dialog(
      AlertDialog(
        title: Text('approve_change_request'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('approve_change_request_confirmation'.tr),
            const SizedBox(height: 16),
            TextFormField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'approval_notes'.tr,
                hintText: 'optional_approval_notes'.tr,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          Obx(
            () => ElevatedButton(
              onPressed:
                  isProcessing.value
                      ? null
                      : () {
                        Get.back();
                        approveChangeRequest(id);
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child:
                  isProcessing.value
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text('approve'.tr),
            ),
          ),
        ],
      ),
    );
  }

  /// Show reject confirmation dialog
  void showRejectDialog(BuildContext context, String id) {
    reasonController.clear();

    Get.dialog(
      AlertDialog(
        title: Text('reject_change_request'.tr),
        content: Form(
          key: reviewFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('reject_change_request_confirmation'.tr),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: '${'rejection_reason'.tr} *',
                  hintText: 'rejection_reason_hint'.tr,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'rejection_reason_required'.tr;
                  }
                  if (value.trim().length < 5) {
                    return 'rejection_reason_min_length'.tr;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          Obx(
            () => ElevatedButton(
              onPressed:
                  isProcessing.value
                      ? null
                      : () {
                        Get.back();
                        rejectChangeRequest(id);
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child:
                  isProcessing.value
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text('reject'.tr),
            ),
          ),
        ],
      ),
    );
  }
}
