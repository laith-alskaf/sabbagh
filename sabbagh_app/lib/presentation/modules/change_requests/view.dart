import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_colors.dart';
import 'package:sabbagh_app/core/constants/app_routes.dart';
import 'package:sabbagh_app/data/dto/change_request_dto.dart';
import 'package:sabbagh_app/presentation/modules/change_requests/controller.dart';
import 'package:sabbagh_app/presentation/widgets/app_drawer.dart';
import 'package:sabbagh_app/presentation/widgets/custom_app_bar.dart';

/// Change Requests List View
class ChangeRequestsView extends GetView<ChangeRequestController> {
  /// Creates a new [ChangeRequestsView]
  const ChangeRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'change_requests'.tr,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: controller.refreshChangeRequests,
          ),
        ],
      ),

      drawer: const AppDrawer(),
      body: Obx(() {
        if (!controller.canViewChangeRequests) {
          return _buildAccessDenied();
        }

        return Column(
          children: [
            _buildFilters(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refreshChangeRequests,
                child: _buildChangeRequestsList(),
              ),
            ),
          ],
        );
      }),
    );
  }

  /// Build access denied widget
  Widget _buildAccessDenied() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'access_denied'.tr,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'change_requests_access_required'.tr,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build filters section
  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'search_change_requests'.tr,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) => controller.searchQuery.value = value,
          ),
          const SizedBox(height: 12),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Status filter
                Obx(
                  () => _buildFilterChip(
                    label: 'status'.tr,
                    value: controller.statusFilter.value?.name,
                    onTap: () => _showStatusFilterDialog(),
                  ),
                ),
                const SizedBox(width: 8),

                // Entity type filter
                Obx(
                  () => _buildFilterChip(
                    label: 'entity_type'.tr,
                    value: controller.entityTypeFilter.value?.name,
                    onTap: () => _showEntityTypeFilterDialog(),
                  ),
                ),
                const SizedBox(width: 8),

                // Clear filters
                Obx(() {
                  final hasFilters =
                      controller.statusFilter.value != null ||
                      controller.entityTypeFilter.value != null ||
                      controller.searchQuery.value.isNotEmpty;

                  if (!hasFilters) return const SizedBox.shrink();

                  return ActionChip(
                    label: Text('clear_filters'.tr),
                    onPressed: controller.clearFilters,
                    backgroundColor: Colors.red[50],
                    labelStyle: const TextStyle(color: Colors.red),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build filter chip
  Widget _buildFilterChip({
    required String label,
    String? value,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(value != null ? '$label: $value' : label),
      selected: value != null,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey[100],
      selectedColor: AppColors.primaryGreen.withValues(alpha: 0.2),
    );
  }

  /// Build change requests list
  Widget _buildChangeRequestsList() {
    return Obx(() {
      if (controller.isLoading.value && controller.changeRequests.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final filteredRequests = controller.filteredChangeRequests;

      if (filteredRequests.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'no_change_requests_found'.tr,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount:
            filteredRequests.length + (controller.isLoading.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filteredRequests.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final changeRequest = filteredRequests[index];
          return _buildChangeRequestCard(changeRequest);
        },
      );
    });
  }

  /// Build change request card
  Widget _buildChangeRequestCard(ChangeRequestDto changeRequest) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            () => Get.toNamed(
              AppRoutes.changeRequestDetails.replaceAll(
                ':id',
                changeRequest.id,
              ),
            ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      changeRequest.displayTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(changeRequest.status),
                ],
              ),
              const SizedBox(height: 8),

              // Details
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      changeRequest.requesterName ?? changeRequest.requestedBy,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(changeRequest.createdAt),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),

              // Reason (if available)
              if (changeRequest.reason != null) ...[
                const SizedBox(height: 8),
                Text(
                  changeRequest.reason!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Action buttons for managers
              if (controller.canReviewChangeRequests &&
                  changeRequest.canBeReviewed) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed:
                          () => controller.showRejectDialog(
                            Get.context!,
                            changeRequest.id,
                          ),
                      icon: const Icon(Icons.close, size: 16),
                      label: Text('reject'.tr),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed:
                          () => controller.showApproveDialog(
                            Get.context!,
                            changeRequest.id,
                          ),
                      icon: const Icon(Icons.check, size: 16),
                      label: Text('approve'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build status chip
  Widget _buildStatusChip(ChangeRequestStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case ChangeRequestStatus.pending:
        color = Colors.orange;
        icon = Icons.pending;
        break;
      case ChangeRequestStatus.approved:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case ChangeRequestStatus.rejected:
        color = Colors.red;
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            controller.getStatusDisplayText(status),
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Show status filter dialog
  void _showStatusFilterDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('filter_by_status'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('all'.tr),
              leading: Radio<ChangeRequestStatus?>(
                value: null,
                groupValue: controller.statusFilter.value,
                onChanged: (value) {
                  controller.applyStatusFilter(value);
                  Get.back();
                },
              ),
            ),
            ...ChangeRequestStatus.values.map(
              (status) => ListTile(
                title: Text(controller.getStatusDisplayText(status)),
                leading: Radio<ChangeRequestStatus?>(
                  value: status,
                  groupValue: controller.statusFilter.value,
                  onChanged: (value) {
                    controller.applyStatusFilter(value);
                    Get.back();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show entity type filter dialog
  void _showEntityTypeFilterDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('filter_by_entity_type'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('all'.tr),
              leading: Radio<EntityType?>(
                value: null,
                groupValue: controller.entityTypeFilter.value,
                onChanged: (value) {
                  controller.applyEntityTypeFilter(value);
                  Get.back();
                },
              ),
            ),
            ...EntityType.values.map(
              (entityType) => ListTile(
                title: Text(controller.getEntityTypeDisplayText(entityType)),
                leading: Radio<EntityType?>(
                  value: entityType,
                  groupValue: controller.entityTypeFilter.value,
                  onChanged: (value) {
                    controller.applyEntityTypeFilter(value);
                    Get.back();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today'.tr;
    } else if (difference.inDays == 1) {
      return 'yesterday'.tr;
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${'days_ago'.tr}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Change Request Details View
class ChangeRequestDetailsView extends GetView<ChangeRequestController> {
  /// Creates a new [ChangeRequestDetailsView]
  const ChangeRequestDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final id = Get.parameters['id'];

    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: Text('change_request_details'.tr)),
        body: Center(child: Text('invalid_change_request_id'.tr)),
      );
    }

    // Load change request details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.selectedChangeRequest.value?.id != id) {
        controller.getChangeRequestById(id);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('change_request_details'.tr),
        actions: [
          Obx(() {
            final changeRequest = controller.selectedChangeRequest.value;
            if (changeRequest == null ||
                !controller.canReviewChangeRequests ||
                !changeRequest.canBeReviewed) {
              return const SizedBox.shrink();
            }

            return PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'approve':
                    controller.showApproveDialog(context, changeRequest.id);
                    break;
                  case 'reject':
                    controller.showRejectDialog(context, changeRequest.id);
                    break;
                }
              },
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'approve',
                      child: Row(
                        children: [
                          const Icon(Icons.check, color: Colors.green),
                          const SizedBox(width: 8),
                          Text('approve'.tr),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'reject',
                      child: Row(
                        children: [
                          const Icon(Icons.close, color: Colors.red),
                          const SizedBox(width: 8),
                          Text('reject'.tr),
                        ],
                      ),
                    ),
                  ],
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingDetails.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final changeRequest = controller.selectedChangeRequest.value;
        if (changeRequest == null) {
          return Center(child: Text('change_request_not_found'.tr));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailsCard(changeRequest),
              const SizedBox(height: 16),
              _buildPayloadCard(changeRequest),
              if (changeRequest.status != ChangeRequestStatus.pending) ...[
                const SizedBox(height: 16),
                _buildReviewCard(changeRequest),
              ],
            ],
          ),
        );
      }),
    );
  }

  /// Build details card
  Widget _buildDetailsCard(ChangeRequestDto changeRequest) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'request_details'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildDetailRow('title'.tr, changeRequest.displayTitle),
            _buildDetailRow(
              'entity_type'.tr,
              controller.getEntityTypeDisplayText(changeRequest.entityType),
            ),
            _buildDetailRow(
              'operation'.tr,
              controller.getOperationDisplayText(changeRequest.operation),
            ),
            _buildDetailRow(
              'status'.tr,
              controller.getStatusDisplayText(changeRequest.status),
            ),
            _buildDetailRow(
              'requested_by'.tr,
              changeRequest.requesterName ?? changeRequest.requestedBy,
            ),
            _buildDetailRow(
              'created_at'.tr,
              _formatDateTime(changeRequest.createdAt),
            ),

            if (changeRequest.reason != null)
              _buildDetailRow('reason'.tr, changeRequest.reason!),
          ],
        ),
      ),
    );
  }

  /// Build payload card
  Widget _buildPayloadCard(ChangeRequestDto changeRequest) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'request_data'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _formatJson(changeRequest.payload),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build review card
  Widget _buildReviewCard(ChangeRequestDto changeRequest) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'review_details'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildDetailRow(
              'reviewed_by'.tr,
              changeRequest.reviewerName ??
                  changeRequest.reviewedBy ??
                  'unknown'.tr,
            ),
            if (changeRequest.reviewedAt != null)
              _buildDetailRow(
                'reviewed_at'.tr,
                _formatDateTime(changeRequest.reviewedAt!),
              ),
            if (changeRequest.reason != null)
              _buildDetailRow('review_notes'.tr, changeRequest.reason!),
          ],
        ),
      ),
    );
  }

  /// Build detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  /// Format JSON for display
  String _formatJson(Map<String, dynamic> json) {
    final buffer = StringBuffer();
    json.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    return buffer.toString();
  }

  /// Format date time for display
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
