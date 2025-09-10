import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_colors.dart';
import 'package:sabbagh_app/domain/entities/purchase_order.dart';
import 'package:sabbagh_app/domain/entities/purchase_order_item.dart';
import 'package:sabbagh_app/domain/entities/user_role.dart';
import 'package:sabbagh_app/presentation/modules/purchase_orders/controller.dart';
import 'package:sabbagh_app/presentation/widgets/custom_app_bar.dart';
import 'package:sabbagh_app/domain/entities/purchase_order_note.dart';
import 'package:sabbagh_app/presentation/widgets/custom_grid_cached_images.dart';
import 'package:sabbagh_app/domain/entities/purchase_order_workflow.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Purchase order details view
class PurchaseOrderDetailsView extends GetView<PurchaseOrderController> {
  /// Creates a new [PurchaseOrderDetailsView]
  const PurchaseOrderDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final orderId = Get.parameters['id'] ?? '';

    // Load purchase order details when view is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (orderId.isNotEmpty) {
        controller.getPurchaseOrderById(orderId);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        showBackButton: true,
        title: 'purchase_order_details'.tr,
        actions: [
          Obx(() {
            final order = controller.selectedPurchaseOrder.value;
            if (order == null) return const SizedBox.shrink();

            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.white),
              onSelected: (value) => _handleMenuAction(value, order),
              itemBuilder: (context) => _buildMenuItems(order),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final order = controller.selectedPurchaseOrder.value;
        if (order == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'purchase_order_not_found'.tr,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(order),
              const SizedBox(height: 16),
              _buildDetailsCard(order),
              const SizedBox(height: 16),
              _buildItemsCard(order),
              const SizedBox(height: 16),
              _buildImagesCard(order),
              const SizedBox(height: 16),
              // Workflow card (auditor/managers) only when completed
              _buildWorkflowCard(order),
              const SizedBox(height: 16),
              _buildNotesCard(order),
              const SizedBox(height: 16),
              _buildActionButtons(order),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeaderCard(PurchaseOrder order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SelectableText(
                    order.number,
                    style: Get.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Icon(Icons.business, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.department,
                    style: Get.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.person, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.requesterName,
                    style: Get.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.category, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.type.toApiString().tr,
                    style: Get.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Workflow Card for completed orders
  Widget _buildWorkflowCard(PurchaseOrder order) {
    // Only visible when order completed and role is allowed
    final controller = this.controller;
    final show = order.status == PurchaseOrderStatus.completed &&
        (controller.userController.isAuditor ||
            controller.userController.isGeneralManager ||
            controller.userController.isManager ||
            controller.userController.isAssistantManager);
    if (!show) return const SizedBox.shrink();

    return Obx(() {
      if (controller.isWorkflowLoading.value) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }
      final steps = controller.workflow;
      if (steps.isEmpty) return const SizedBox.shrink();

      Icon _iconForStatus(String status) {
        switch (status) {
          case 'approved':
          case 'completed':
            return const Icon(Icons.check_circle, color: Colors.green);
          case 'rejected':
            return const Icon(Icons.cancel, color: Colors.red);
          case 'pending':
            return const Icon(Icons.hourglass_bottom, color: Colors.orange);
          case 'routed':
            return const Icon(Icons.alt_route, color: Colors.indigo);
          default:
            return const Icon(Icons.info, color: Colors.grey);
        }
      }

      String _titleForStep(PurchaseOrderWorkflowStep s) {
        // Keys should exist in i18n files
        return 'workflow.${s.step}'.tr;
      }

      String _subtitleForStep(PurchaseOrderWorkflowStep s) {
        final actor = s.actorName ?? s.actorEmail ?? s.actorId ?? '';
        final time = _formatDateTime(s.timestamp);
        return [actor, time].where((e) => e.isNotEmpty).join(' • ');
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'workflow.title'.tr,
                style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: steps.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (_, i) {
                  final s = steps[i];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _iconForStatus(s.status),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_titleForStep(s), style: Get.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(_subtitleForStep(s), style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                            if (s.details != null) ...[
                              const SizedBox(height: 4),
                              Text(s.details.toString(), style: Get.textTheme.bodySmall),
                            ]
                          ],
                        ),
                      )
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDetailsCard(PurchaseOrder order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'details'.tr,
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildDetailRow(
              'request_date'.tr,
              _formatDate(order.requestDate),
              Icons.calendar_today,
            ),

            if (order.executionDate != null)
              _buildDetailRow(
                'execution_date'.tr,
                _formatDate(order.executionDate!),
                Icons.schedule,
              ),

            if (order.vendorName != null)
              _buildDetailRow('vendor_name'.tr, order.vendorName!, Icons.store),

            if (order.totalAmount != null)
              _buildDetailRow(
                'total_amount'.tr,
                '${order.totalAmount!.toStringAsFixed(2)} ${order.currency}',
                Icons.attach_money,
              ),

            if (order.notes != null && order.notes!.isNotEmpty)
              _buildDetailRow('notes'.tr, order.notes!, Icons.note),

            _buildDetailRow(
              'created_at'.tr,
              _formatDateTime(order.createdAt),
              Icons.access_time,
            ),

            _buildDetailRow(
              'updated_at'.tr,
              _formatDateTime(order.updatedAt),
              Icons.update,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(PurchaseOrder order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'items'.tr,
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text('${order.items.length}'),
                  backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (order.items.isEmpty)
              Center(
                child: Text(
                  'no_items'.tr,
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.items.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return _buildItemRow(item);
                },
              ),
          ],
        ),
      ),
    );
  }

  // Displays order attachments (images grid and non-image files)
  Widget _buildImagesCard(PurchaseOrder order) {
    final urls = order.attachmentUrls;
    if (urls.isEmpty) return const SizedBox.shrink();

    bool _isImage(String u) {
      final lu = u.toLowerCase();
      return lu.endsWith('.png') ||
          lu.endsWith('.jpg') ||
          lu.endsWith('.jpeg') ||
          lu.endsWith('.gif') ||
          lu.endsWith('.webp');
    }

    Future<void> _openUrl(String u) async {
      if (await canLaunchUrlString(u)) {
        await launchUrlString(u, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('error'.tr, 'cannot_open_link'.tr);
      }
    }

    final imageUrls = urls.where(_isImage).toList();
    final otherUrls = urls.where((u) => !_isImage(u)).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'attachments'.tr,
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Images grid with uploader name
            // if (imageUrls.isNotEmpty)
            SizedBox(
              height: 130,
              child: CachedImagesGrid(imageUrls: urls, crossAxisCount: 3),
            ),
            if (imageUrls.isNotEmpty && otherUrls.isNotEmpty)
              const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(PurchaseOrder order) {
    final canView = controller.canViewNotes(order);
    if (!canView) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'po_notes'.tr,
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Obx(
                  () => Chip(
                    label: Text('${controller.notes.length}'),
                    backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() {
              if (controller.isNotesLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.notes.isEmpty) {
                return Text(
                  'no_notes'.tr,
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.notes.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final note = controller.notes[index];
                  return _buildNoteTile(note);
                },
              );
            }),
            const SizedBox(height: 12),
            if (controller.canAddNote(order)) _buildAddNoteRow(order),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteTile(PurchaseOrderNote note) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.sticky_note_2_outlined, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    note.userName ?? 'user'.tr,
                    style: Get.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateTime(note.createdAt),
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(note.note, style: Get.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddNoteRow(PurchaseOrder order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Text('add_note'.tr, style: Get.textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: controller.noteController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'enter_note'.tr,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Obx(
            () => ElevatedButton.icon(
              onPressed:
                  controller.isAddingNote.value
                      ? null
                      : () => controller.submitNote(order.id),
              icon: const Icon(Icons.add_comment_outlined),
              label:
                  controller.isAddingNote.value
                      ? Text('submitting'.tr)
                      : Text('add'.tr),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(PurchaseOrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: Get.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.itemCode != null)
                      Text(
                        'code_label'.tr + ': ${item.itemCode}',
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.quantity} ${item.unit.tr}',
                      style: Get.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item.price != null &&
                        controller.userController.role != UserRole.employee)
                      Text(
                        '${item.price!.toStringAsFixed(2)} ${item.currency ?? 'SYR'}',
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          if (item.lineTotal != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'line_total'.tr,
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${item.lineTotal!.toStringAsFixed(2)} ${item.currency}',
                    style: Get.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),

          if (item.receivedQuantity != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'received_quantity'.tr,
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${item.receivedQuantity!} ${item.unit.tr}',
                    style: Get.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(PurchaseOrder order) {
    final actions = <Widget>[];

    // Submit button for draft orders
    if (controller.canSubmitPurchaseOrder(order)) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showSubmitDialog(order),
            icon: const Icon(Icons.send),
            label: Text('submit_for_review'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.white,
            ),
          ),
        ),
      );
    }

    // Approve/Reject buttons for reviewers
    if (controller.canAssistantApprovePurchaseOrderStatus(order) ||
        controller.canManagerApprovePurchaseOrderStatus(order)) {
      actions.addAll([
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showApproveDialog(order),
                icon: const Icon(Icons.check),
                label: Text('approve'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showRejectDialog(order),
                icon: const Icon(Icons.close),
                label: Text('reject'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ]);
    }

    // Complete button for managers
    if (controller.canCompletePurchaseOrder(order)) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showCompleteDialog(order),
            icon: const Icon(Icons.done_all),
            label: Text('mark_as_completed'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
    }

    // New workflow actions
    // 1) Route by Assistant/Manager
    if (controller.userController.isManager &&
        order.status == PurchaseOrderStatus.underManagerReview) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showRouteBottomSheet(order),
            icon: const Icon(Icons.alt_route),
            label: Text('route'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
    }

    // 2) Finance approve/reject
    if (controller.userController.isFinanceManager &&
        order.status == PurchaseOrderStatus.underFinanceReview) {
      actions.add(
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => controller.financeApprove(order.id),
                icon: const Icon(Icons.check_circle_outline),
                label: Text('approve'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showFinanceRejectDialog(order),
                icon: const Icon(Icons.cancel_outlined),
                label: Text('reject'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 3) General manager approve/reject
    if (controller.userController.isGeneralManager &&
        order.status == PurchaseOrderStatus.underGeneralManagerReview) {
      actions.add(
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => controller.generalManagerApprove(order.id),
                icon: const Icon(Icons.check_circle_outline),
                label: Text('approve'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showGMRejectDialog(order),
                icon: const Icon(Icons.cancel_outlined),
                label: Text('reject'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 4) Procurement update / Return to manager
    if (controller.userController.isProcurementOfficer &&
        (order.status == PurchaseOrderStatus.pendingProcurement ||
            order.status == PurchaseOrderStatus.inProgress)) {
      actions.add(
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showProcurementUpdateBottomSheet(order),
                icon: const Icon(Icons.edit_note),
                label: Text('procurement_update'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    () => controller.returnToManagerForFinalReview(order.id),
                icon: const Icon(Icons.reply),
                label: Text('return_to_manager'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 5) Manager final approve/reject
    if (controller.userController.isManager &&
        order.status == PurchaseOrderStatus.returnedToManagerReview) {
      actions.add(
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => controller.managerFinalApprove(order.id),
                icon: const Icon(Icons.verified),
                label: Text('final_approve'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showFinalRejectDialog(order),
                icon: const Icon(Icons.highlight_off),
                label: Text('final_reject'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'actions'.tr,
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...actions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: action,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: Get.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
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
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case PurchaseOrderStatus.underManagerReview:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case PurchaseOrderStatus.underFinanceReview:
        backgroundColor = Colors.indigo[100]!;
        textColor = Colors.indigo[800]!;
        break;
      case PurchaseOrderStatus.underGeneralManagerReview:
        backgroundColor = Colors.deepPurple[100]!;
        textColor = Colors.deepPurple[800]!;
        break;
      case PurchaseOrderStatus.pendingProcurement:
        backgroundColor = Colors.teal[100]!;
        textColor = Colors.teal[800]!;
        break;
      case PurchaseOrderStatus.returnedToManagerReview:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[900]!;
        break;
      case PurchaseOrderStatus.rejectedByAssistant:
      case PurchaseOrderStatus.rejectedByManager:
      case PurchaseOrderStatus.rejectedByFinance:
      case PurchaseOrderStatus.rejectedByGeneralManager:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      case PurchaseOrderStatus.inProgress:
        backgroundColor = Colors.yellow[100]!;
        textColor = Colors.yellow[800]!;
        break;
      case PurchaseOrderStatus.completed:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toApiString().tr,
        style: Get.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // =========== New Workflow UI Helpers ===========

  void _showRouteBottomSheet(PurchaseOrder order) {
    final notesCtrl = TextEditingController();
    String selected = 'finance';

    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('choose_next_step'.tr, style: Get.textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'finance',
                      groupValue: selected,
                      title: Text('route_finance'.tr),
                      onChanged: (v) {
                        selected = v!;
                        (context as Element).markNeedsBuild();
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'gm',
                      groupValue: selected,
                      title: Text('route_gm'.tr),
                      onChanged: (v) {
                        selected = v!;
                        (context as Element).markNeedsBuild();
                      },
                    ),
                  ),
                ],
              ),
              RadioListTile<String>(
                value: 'procurement',
                groupValue: selected,
                title: Text('route_procurement'.tr),
                onChanged: (v) {
                  selected = v!;
                  (context as Element).markNeedsBuild();
                },
              ),
              const SizedBox(height: 8),
              Text('add_notes_optional'.tr, style: Get.textTheme.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  hintText: 'notes_optional'.tr,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('cancel'.tr),
                  ),
                  const Spacer(),
                  Obx(
                    () => ElevatedButton.icon(
                      onPressed:
                          controller.isSubmitting.value
                              ? null
                              : () async {
                                await controller.routePurchaseOrder(
                                  order.id,
                                  next: selected,
                                  notes:
                                      notesCtrl.text.trim().isEmpty
                                          ? null
                                          : notesCtrl.text.trim(),
                                );
                                controller.getPurchaseOrderById(order.id);
                                Get.back();
                              },
                      icon: const Icon(Icons.send),
                      label: Text('route'.tr),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showFinanceRejectDialog(PurchaseOrder order) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: Get.context!,
      builder:
          (context) => AlertDialog(
            title: Text('reject_purchase_order'.tr),
            content: TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(
                labelText: 'rejection_reason'.tr,
                hintText: 'rejection_reason_hint'.tr,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
              Obx(
                () => ElevatedButton(
                  onPressed:
                      controller.isSubmitting.value
                          ? null
                          : () async {
                            if (reasonCtrl.text.trim().isEmpty) {
                              Get.snackbar(
                                'error'.tr,
                                'rejection_reason_required'.tr,
                              );
                              return;
                            }
                            await controller.financeReject(
                              order.id,
                              reasonCtrl.text.trim(),
                            );
                            controller.getPurchaseOrderById(order.id);
                            Get.back();
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('reject'.tr),
                ),
              ),
            ],
          ),
    );
  }

  void _showGMRejectDialog(PurchaseOrder order) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: Get.context!,
      builder:
          (context) => AlertDialog(
            title: Text('reject_purchase_order'.tr),
            content: TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(
                labelText: 'rejection_reason'.tr,
                hintText: 'rejection_reason_hint'.tr,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
              Obx(
                () => ElevatedButton(
                  onPressed:
                      controller.isSubmitting.value
                          ? null
                          : () async {
                            if (reasonCtrl.text.trim().isEmpty) {
                              Get.snackbar(
                                'error'.tr,
                                'rejection_reason_required'.tr,
                              );
                              return;
                            }
                            await controller.generalManagerReject(
                              order.id,
                              reasonCtrl.text.trim(),
                            );
                            controller.getPurchaseOrderById(order.id);
                            Get.back();
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('reject'.tr),
                ),
              ),
            ],
          ),
    );
  }

  void _showFinalRejectDialog(PurchaseOrder order) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: Get.context!,
      builder:
          (context) => AlertDialog(
            title: Text('reject_purchase_order'.tr),
            content: TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(
                labelText: 'rejection_reason'.tr,
                hintText: 'rejection_reason_hint'.tr,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
              Obx(
                () => ElevatedButton(
                  onPressed:
                      controller.isSubmitting.value
                          ? null
                          : () async {
                            if (reasonCtrl.text.trim().isEmpty) {
                              Get.snackbar(
                                'error'.tr,
                                'rejection_reason_required'.tr,
                              );
                              return;
                            }
                            await controller.managerFinalReject(
                              order.id,
                              reasonCtrl.text.trim(),
                            );
                            controller.getPurchaseOrderById(order.id);
                            Get.back();
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('reject'.tr),
                ),
              ),
            ],
          ),
    );
  }

  void _showProcurementUpdateBottomSheet(PurchaseOrder order) {
    // final attachmentCtrl = TextEditingController(
    //   text: order.attachmentUrls ?? '',
    // );
    final itemControllers =
        order.items
            .map(
              (it) => {
                'id': it.id,
                'received': TextEditingController(
                  text: it.receivedQuantity?.toString() ?? '',
                ),
                'price': TextEditingController(
                  text: it.price?.toString() ?? '',
                ),
                'line': TextEditingController(
                  text: it.lineTotal?.toString() ?? '',
                ),
              },
            )
            .toList();

    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  Text(
                    'procurement_update_sheet_title'.tr,
                    style: Get.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  // TextField(
                  //   controller: attachmentCtrl,
                  //   decoration: InputDecoration(
                  //     labelText: 'attachment_url'.tr,
                  //     border: const OutlineInputBorder(),
                  //   ),
                  // ),
                  // const SizedBox(height: 16),
                  ...itemControllers.map((c) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${'item'.tr} #${order.items.indexWhere((it) => it.id == c['id']) + 1}',
                                style: Get.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller:
                                          c['received']
                                              as TextEditingController,
                                      decoration: InputDecoration(
                                        labelText: 'received_quantity'.tr,
                                        border: const OutlineInputBorder(),
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller:
                                          c['price'] as TextEditingController,
                                      decoration: InputDecoration(
                                        labelText: 'price'.tr,
                                        border: const OutlineInputBorder(),
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller:
                                          c['line'] as TextEditingController,
                                      decoration: InputDecoration(
                                        labelText: 'line_total'.tr,
                                        border: const OutlineInputBorder(),
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text('cancel'.tr),
                      ),
                      const Spacer(),
                      Obx(
                        () => ElevatedButton.icon(
                          onPressed:
                              controller.isSubmitting.value
                                  ? null
                                  : () async {
                                    final items =
                                        itemControllers.map((c) {
                                          final received =
                                              (c['received']
                                                      as TextEditingController)
                                                  .text
                                                  .trim();
                                          final price =
                                              (c['price']
                                                      as TextEditingController)
                                                  .text
                                                  .trim();
                                          final line =
                                              (c['line']
                                                      as TextEditingController)
                                                  .text
                                                  .trim();
                                          return {
                                            'id': c['id'],
                                            if (received.isNotEmpty)
                                              'received_quantity':
                                                  double.tryParse(received),
                                            if (price.isNotEmpty)
                                              'price': double.tryParse(price),
                                            if (line.isNotEmpty)
                                              'line_total': double.tryParse(
                                                line,
                                              ),
                                          };
                                        }).toList();
                                    await controller.procurementUpdate(
                                      order.id,
                                      items: items,
                                    );
                                    controller.getPurchaseOrderById(order.id);
                                    Get.back();
                                  },
                          icon: const Icon(Icons.save),
                          label: Text('save'.tr),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(PurchaseOrder order) {
    final items = <PopupMenuEntry<String>>[];

    if (controller.canEditPurchaseOrder(order)) {
      items.add(
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit, size: 20),
              const SizedBox(width: 8),
              Text('edit'.tr),
            ],
          ),
        ),
      );
    }

    if (controller.canDeletePurchaseOrder(order)) {
      items.add(
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, size: 20, color: Colors.red),
              const SizedBox(width: 8),
              Text('delete'.tr, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }

    return items;
  }

  void _handleMenuAction(String action, PurchaseOrder order) {
    switch (action) {
      case 'edit':
        // Navigate to edit page
        Get.toNamed('/purchase-orders/${order.id}/edit');
        break;
      case 'delete':
        _showDeleteDialog(order);
        break;
    }
  }

  void _showSubmitDialog(PurchaseOrder order) {
    showDialog(
      context: Get.context!,
      builder:
          (context) => AlertDialog(
            title: Text('submit_purchase_order'.tr),
            content: Text(
              'confirm_submit_purchase_order'.tr.replaceAll(
                '{number}',
                order.number,
              ),
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
                            controller.submitPurchaseOrder(order.id);
                          },
                  child:
                      controller.isSubmitting.value
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text('submit'.tr),
                ),
              ),
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
                // Always show notes field as per requirement
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
                            } else if (controller
                                .canManagerApprovePurchaseOrderStatus(order)) {
                              controller.managerApprovePurchaseOrder(
                                order.id,
                                notes:
                                    notesController.text.trim().isEmpty
                                        ? null
                                        : notesController.text.trim(),
                              );
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
                            Get.back();
                            if (controller
                                .canAssistantApprovePurchaseOrderStatus(
                                  order,
                                )) {
                              controller.assistantRejectPurchaseOrder(order.id);
                            } else if (controller
                                .canManagerApprovePurchaseOrderStatus(order)) {
                              controller.managerRejectPurchaseOrder(order.id);
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

  void _showCompleteDialog(PurchaseOrder order) {
    showDialog(
      context: Get.context!,
      builder:
          (context) => AlertDialog(
            title: Text('complete_purchase_order'.tr),
            content: Text(
              'confirm_complete_purchase_order'.tr.replaceAll(
                '{number}',
                order.number,
              ),
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
                            controller.completePurchaseOrder(order.id);
                            Get.back();
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
                          : Text('complete'.tr),
                ),
              ),
            ],
          ),
    );
  }

  void _showDeleteDialog(PurchaseOrder order) {
    showDialog(
      context: Get.context!,
      builder:
          (context) => AlertDialog(
            title: Text('delete_purchase_order'.tr),
            content: Text(
              'confirm_delete_purchase_order'.tr.replaceAll(
                '{number}',
                order.number,
              ),
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
                            controller.deletePurchaseOrder(order.id);
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
                          : Text('delete'.tr),
                ),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
