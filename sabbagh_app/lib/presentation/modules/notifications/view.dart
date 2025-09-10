import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_colors.dart';
import 'package:sabbagh_app/presentation/modules/notifications/controller.dart';
import 'package:sabbagh_app/presentation/widgets/custom_app_bar.dart';
import 'package:sabbagh_app/core/utils/navigation_helper.dart';
import 'package:sabbagh_app/core/constants/app_routes.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: 'notifications'.tr, showBackButton: true),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.notifications.isEmpty) {
                return _buildEmptyState(context);
              }
              return RefreshIndicator(
                onRefresh: controller.refreshList,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notif) {
                    if (notif.metrics.pixels >=
                            notif.metrics.maxScrollExtent - 200 &&
                        !controller.isLoadingMore.value) {
                      controller.loadMore();
                    }
                    return false;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.notifications.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == controller.notifications.length) {
                        return Obx(
                          () =>
                              controller.isLoadingMore.value
                                  ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                  : const SizedBox.shrink(),
                        );
                      }
                      final n = controller.notifications[index];
                      return _NotificationTile(
                        notification: n,
                        onTap: () async {
                          await controller.markRead(n.id);
                          // Navigate based on notification data
                          final data = n.data ?? const {};
                          final type = n.type;
                          final id = data['po']['id'].toString();
                          String? target;
                          switch (type) {
                            case 'po_created':
                            case 'po_status_changed':
                            case 'po_approved':
                            case 'po_rejected':
                            case 'po_completed':
                              target =
                                  (id.isNotEmpty)
                                      ? AppRoutes.purchaseOrderDetails
                                          .replaceAll(':id', id)
                                      : AppRoutes.purchaseOrders;
                              break;
                            default:
                              target = AppRoutes.dashboard;
                          }
                          NavigationHelper.navigateWithRoleCheck(target);
                        },
                        onDelete: () => controller.deleteById(n.id),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Obx(
            () => ElevatedButton.icon(
              onPressed:
                  controller.unreadCount.value > 0
                      ? controller.markAllRead
                      : null,
              icon: const Icon(Icons.done_all),
              label: Text('mark_all_read'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primaryGreen.withOpacity(
                  0.3,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: controller.refreshList,
            icon: const Icon(Icons.refresh),
            label: Text('refresh'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 72,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'no_notifications'.tr,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'notifications_will_appear_here'.tr,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab() {
    return PopupMenuButton<String>(
      tooltip: 'more'.tr,
      position: PopupMenuPosition.over,
      icon: const Icon(Icons.tune, color: Colors.white),
      itemBuilder:
          (context) => [
            PopupMenuItem(value: 'read_all', child: Text('mark_all_read'.tr)),
            PopupMenuItem(value: 'delete_all', child: Text('delete_all'.tr)),
          ],
      onSelected: (value) {
        switch (value) {
          case 'read_all':
            controller.markAllRead();
            break;
          case 'delete_all':
            _confirmDeleteAll();
            break;
        }
      },
    )._wrapWithFab();
  }

  Future<void> _confirmDeleteAll() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('delete_all'.tr),
        content: Text('confirm_delete_all_notifications'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteAll();
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final bg =
        isUnread ? AppColors.primaryGreen.withOpacity(0.06) : Colors.white;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        final ok = await Get.dialog<bool>(
          AlertDialog(
            title: Text('delete'.tr),
            content: Text('delete_notification_confirm'.tr),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text('cancel'.tr),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: Text('delete'.tr),
              ),
            ],
          ),
        );
        return ok == true;
      },
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (!isUnread)
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _leadingIcon(notification.type, isUnread),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight:
                            isUnread ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    if (notification.body != null &&
                        notification.body!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        notification.body!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          notification.formattedTime,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isUnread)
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leadingIcon(String type, bool isUnread) {
    IconData icon;
    Color color = AppColors.primaryGreen;
    switch (type) {
      case 'po_created':
        icon = Icons.add_shopping_cart_outlined;
        break;
      case 'po_status_changed':
      case 'po_approved':
      case 'po_rejected':
      case 'po_completed':
        icon = Icons.swap_horiz_outlined;
        break;
      default:
        icon = Icons.notifications_outlined;
        color = Colors.grey;
        break;
    }
    return Container(
      decoration: BoxDecoration(
        color: (isUnread ? color : color.withOpacity(0.12)),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(10),
      child: Icon(icon, size: 20, color: isUnread ? Colors.white : color),
    );
  }
}

extension _PopupAsFab on Widget {
  Widget _wrapWithFab() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.secondaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(child: Material(color: Colors.transparent, child: this)),
    );
  }
}
