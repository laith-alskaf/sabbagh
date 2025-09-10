import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_colors.dart';
import 'package:sabbagh_app/domain/entities/purchase_order.dart';
import 'package:sabbagh_app/domain/entities/user_role.dart';
import 'package:sabbagh_app/presentation/modules/purchase_orders/controller.dart';
import 'package:sabbagh_app/presentation/widgets/app_drawer.dart';
import 'package:sabbagh_app/presentation/widgets/custom_app_bar.dart';

/// Purchase orders view with role-based functionality
class PurchaseOrdersView extends GetView<PurchaseOrderController> {
  /// Creates a new [PurchaseOrdersView]
  const PurchaseOrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'purchase_orders'.tr,
        actions: [
          // View mode selector for managers and assistant managers
          Obx(() {
            if (controller.availableViewModes.length > 1) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.view_list, color: AppColors.white),
                onSelected: controller.changeViewMode,
                itemBuilder:
                    (context) =>
                        controller.availableViewModes
                            .map(
                              (mode) => PopupMenuItem<String>(
                                value: mode['key'],
                                child: Row(
                                  children: [
                                    Icon(
                                      controller.currentViewMode.value ==
                                              mode['key']
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(mode['label']!),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
              );
            }
            return const SizedBox.shrink();
          }),
          if (controller.userController.isAssistantManager ||
              controller.userController.isManager)
            IconButton(
              icon: const Icon(Icons.filter_list, color: AppColors.white),
              onPressed: () => _showFilterDialog(context),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: controller.refreshPurchaseOrders,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Active filters display
          Obx(() {
            final hasFilters =
                controller.statusFilter.value.isNotEmpty ||
                controller.departmentFilter.value.isNotEmpty;

            if (!hasFilters) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  if (controller.statusFilter.value.isNotEmpty)
                    Chip(
                      label: Text(controller.statusFilter.value.tr),
                      onDeleted: () => controller.filterByStatus(''),
                      deleteIcon: const Icon(Icons.close, size: 18),
                    ),
                  if (controller.departmentFilter.value.isNotEmpty)
                    Chip(
                      label: Text(controller.departmentFilter.value),
                      onDeleted: () => controller.filterByDepartment(''),
                      deleteIcon: const Icon(Icons.close, size: 18),
                    ),
                  if (hasFilters)
                    TextButton(
                      onPressed: controller.clearFilters,
                      child: Text('clear_all'.tr),
                    ),
                ],
              ),
            );
          }),

          // Purchase orders list
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshPurchaseOrders,
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.purchaseOrders.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.purchaseOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'no_purchase_orders_found'.tr,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'try_adjusting_filters'.tr,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: controller.purchaseOrders.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final order = controller.purchaseOrders[index];
                    return _buildPurchaseOrderCard(order);
                  },
                );
              }),
            ),
          ),

          // Pagination
          Obx(() {
            if (controller.totalPages.value <= 1) {
              return const SizedBox.shrink();
            }

            return Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed:
                        controller.currentPage.value > 1
                            ? controller.previousPage
                            : null,
                    icon: const Icon(Icons.chevron_left),
                    label: Text('previous'.tr),
                  ),
                  Text(
                    '${'page'.tr} ${controller.currentPage.value} ${'of'.tr} ${controller.totalPages.value}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton.icon(
                    onPressed:
                        controller.currentPage.value <
                                controller.totalPages.value
                            ? controller.nextPage
                            : null,
                    icon: const Icon(Icons.chevron_right),
                    label: Text('next'.tr),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      floatingActionButton:
          controller.canCreatePurchaseOrders
              ? FloatingActionButton(
                onPressed: controller.navigateToCreatePurchaseOrder,
                backgroundColor: AppColors.primaryGreen,
                child: const Icon(Icons.add, color: AppColors.white),
              )
              : null,
    );
  }

  Widget _buildPurchaseOrderCard(PurchaseOrder order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => controller.navigateToPurchaseOrderDetails(order.id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with number and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SelectableText(
                      order.number,
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const SizedBox(height: 8),

              // Department and requester
              Row(
                children: [
                  Icon(Icons.business, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.department.tr,
                      style: Get.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.requesterName,
                      style: Get.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Request date and total amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(order.requestDate),
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (order.totalAmount != null &&
                      controller.userController.role != UserRole.employee)
                    Text(
                      '${order.totalAmount!.toStringAsFixed(2)} ${order.currency}',
                      style: Get.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                ],
              ),

              // Items count
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.inventory, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${'items_count'.tr}: ${order.items.length}',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              // Action buttons for managers/assistant managers
              if (_shouldShowActionButtons(order))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _buildActionButtons(order),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(PurchaseOrderStatus status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case PurchaseOrderStatus.draft:
        backgroundColor = Colors.grey[300]!;
        textColor = Colors.grey[800]!;
        break;
      case PurchaseOrderStatus.underAssistantReview:
      case PurchaseOrderStatus.pendingProcurement:
      case PurchaseOrderStatus.underFinanceReview:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case PurchaseOrderStatus.underManagerReview:
      case PurchaseOrderStatus.underGeneralManagerReview:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case PurchaseOrderStatus.rejectedByAssistant:
      case PurchaseOrderStatus.rejectedByManager:
      case PurchaseOrderStatus.rejectedByFinance:
      case PurchaseOrderStatus.rejectedByGeneralManager:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      case PurchaseOrderStatus.inProgress:
      case PurchaseOrderStatus.returnedToManagerReview:
        backgroundColor = Colors.yellow[100]!;
        textColor = Colors.yellow[800]!;
        break;
      case PurchaseOrderStatus.completed:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toApiString().tr,
        style: Get.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  bool _shouldShowActionButtons(PurchaseOrder order) {
    return controller.canAssistantApprovePurchaseOrderStatus(order) ||
        controller.canManagerApprovePurchaseOrderStatus(order) ||
        controller.canRejectPurchaseOrderStatus(order);
  }

  Widget _buildActionButtons(PurchaseOrder order) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (controller.canAssistantApprovePurchaseOrderStatus(order) ||
            controller.canManagerApprovePurchaseOrderStatus(order))
          TextButton.icon(
            onPressed: () => _showApproveDialog(order),
            icon: const Icon(Icons.check, color: AppColors.primaryGreen),
            label: Text(
              'approve'.tr,
              style: const TextStyle(color: AppColors.primaryGreen),
            ),
          ),

        if (controller.canRejectPurchaseOrderStatus(order))
          TextButton.icon(
            onPressed: () => _showRejectDialog(order),
            icon: const Icon(Icons.close, color: Colors.red),
            label: Text('reject'.tr, style: const TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('filter_purchase_orders'.tr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status filter
                Obx(
                  () => DropdownButtonFormField<String>(
                    value:
                        controller.statusFilter.value.isEmpty
                            ? null
                            : controller.statusFilter.value,
                    decoration: InputDecoration(
                      labelText: 'status'.tr,
                      border: const OutlineInputBorder(),
                      contentPadding: EdgeInsetsDirectional.only(start: 10),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('all_statuses'.tr),
                      ),
                      ...PurchaseOrderStatus.values.map(
                        (status) => DropdownMenuItem<String>(
                          value: status.toApiString(),
                          child: Text(status.toApiString().tr),
                        ),
                      ),
                    ],
                    onChanged:
                        (value) => controller.filterByStatus(value ?? ''),
                  ),
                ),

                const SizedBox(height: 16),

                // Department filter (only for managers/assistant managers)
                if (!controller.userController.isEmployee)
                  Obx(
                    () => DropdownButtonFormField<String>(
                      value:
                          controller.departmentFilter.value.isEmpty
                              ? null
                              : controller.departmentFilter.value,
                      decoration: InputDecoration(
                        labelText: 'department'.tr,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text('all_departments'.tr),
                        ),
                        ...controller.departments.map(
                          (dept) => DropdownMenuItem<String>(
                            value: dept.id,
                            child: Text(dept.name),
                          ),
                        ),
                      ],
                      onChanged:
                          (value) => controller.filterByDepartment(value ?? ''),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  controller.clearFilters();
                  Get.back();
                },
                child: Text('clear_all'.tr),
              ),
              TextButton(onPressed: () => Get.back(), child: Text('close'.tr)),
            ],
          ),
    );
  }

  void _showApproveDialog(PurchaseOrder order) {
    final notesController = TextEditingController();

    showDialog(
      context: Get.context!,
      builder:
          (context) => AlertDialog(
            title: Text('approve_purchase_order'.tr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'confirm_approve_purchase_order'.tr.replaceAll(
                    '{number}',
                    order.number,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'notes_optional'.tr,
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
                      controller.isSubmitting.value
                          ? null
                          : () {
                            Get.back();
                            if (controller
                                .canAssistantApprovePurchaseOrderStatus(
                                  order,
                                )) {
                              controller.assistantApprovePurchaseOrder(
                                order.id,
                                notes:
                                    notesController.text.trim().isEmpty
                                        ? null
                                        : notesController.text.trim(),
                              );
                              Get.back();
                              Get.back();
                            } else if (controller
                                .canManagerApprovePurchaseOrderStatus(order)) {
                              controller.managerApprovePurchaseOrder(
                                order.id,
                                notes:
                                    notesController.text.trim().isEmpty
                                        ? null
                                        : notesController.text.trim(),
                              );
                              Get.back();
                              Get.back();
                            }
                          },
                  child:
                      controller.isSubmitting.value
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

  void _showRejectDialog(PurchaseOrder order) {
    showDialog(
      context: Get.context!,
      builder:
          (context) => AlertDialog(
            title: Text('reject_purchase_order'.tr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'confirm_reject_purchase_order'.tr.replaceAll(
                    '{number}',
                    order.number,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller.rejectionReasonController,
                  decoration: InputDecoration(
                    labelText: 'rejection_reason'.tr,
                    border: const OutlineInputBorder(),
                    errorText:
                        controller.rejectionReasonController.text.isEmpty
                            ? 'rejection_reason_required'.tr
                            : null,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  controller.rejectionReasonController.clear();
                  Get.back();
                },
                child: Text('cancel'.tr),
              ),
              Obx(
                () => ElevatedButton(
                  onPressed:
                      controller.isSubmitting.value
                          ? null
                          : () {
                            if (controller
                                .canAssistantApprovePurchaseOrderStatus(
                                  order,
                                )) {
                              controller.assistantRejectPurchaseOrder(order.id);
                              Get.back();
                              Get.back();
                            } else if (controller
                                .canManagerApprovePurchaseOrderStatus(order)) {
                              controller.managerRejectPurchaseOrder(order.id);
                              Get.back();
                              Get.back();
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child:
                      controller.isSubmitting.value
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text('reject'.tr),
                ),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
