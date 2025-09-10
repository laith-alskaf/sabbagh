import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_colors.dart';
import 'package:sabbagh_app/core/services/storage_service.dart';
import 'package:sabbagh_app/presentation/modules/notifications/controller.dart';
import 'package:sabbagh_app/core/constants/app_routes.dart';

/// Custom AppBar with consistent design
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: AppColors.white,
      elevation: 0,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading:
          showBackButton
              ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.white),
                onPressed: onBackPressed ?? () => Get.back(),
              )
              : Builder(
                builder:
                    (context) => IconButton(
                      icon: const Icon(Icons.menu, color: AppColors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
              ),
      actions: [
        ...?actions,
        // Notification icon
        Obx(() {
          // show when user is authenticated
          final hasToken = Get.find<StorageService>().getTokenSync() != null;
          if (!hasToken) return const SizedBox.shrink();

          final notifCtrl =
              Get.isRegistered<NotificationsController>()
                  ? Get.find<NotificationsController>()
                  : null;
          final count = notifCtrl?.unreadCount.value ?? 0;
          return IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.white,
                ),
                if (count > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 16,
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Get.toNamed(AppRoutes.notifications);
            },
            tooltip: 'notifications'.tr,
          );
        }),
        const SizedBox(width: 8),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryGreen, AppColors.secondaryGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
