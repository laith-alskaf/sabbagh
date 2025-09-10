import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard functionality
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_colors.dart';
import 'package:sabbagh_app/core/constants/app_routes.dart';
import 'package:sabbagh_app/core/services/storage_service.dart';
import 'package:sabbagh_app/core/utils/navigation_helper.dart';
import 'package:sabbagh_app/presentation/controllers/user_controller.dart';
import 'package:sabbagh_app/presentation/modules/auth/controller.dart';

/// Custom application drawer with role-based navigation
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();
    final authController = Get.find<AuthController>();

    return Drawer(
      backgroundColor: AppColors.white,
      child: Column(
        children: [
          _buildDrawerHeader(userController),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavigationItems(userController),
                const Divider(color: AppColors.mediumGray),
                _buildSettingsItems(),
                const Divider(color: AppColors.mediumGray),
                _buildLogoutItem(authController),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build drawer header with user info
  Widget _buildDrawerHeader(UserController userController) {
    return Obx(() {
      final user = userController.user.value;

      return Container(
        alignment: Alignment.center,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryGreen, AppColors.secondaryGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // User Avatar
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 32,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user?.name ?? 'guest'.tr,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // User Email
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // User Role
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getRoleDisplayName(user?.role.name ?? 'guest'),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                // User Name
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Build navigation items based on user role
  Widget _buildNavigationItems(UserController userController) {
    return Obx(() {
      final user = userController.user.value;
      if (user == null) return const SizedBox.shrink();

      final navigationItems = NavigationHelper.getNavigationItems(user.role);
      final widgets = <Widget>[];

      for (final item in navigationItems) {
        widgets.add(
          _buildDrawerItem(
            icon: _getIconData(item.icon),
            title: item.title.tr,
            route: item.route,
            isActive: Get.currentRoute == item.route,
          ),
        );
      }

      return Column(children: widgets);
    });
  }

  /// Get icon data from string
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'dashboard_outlined':
        return Icons.dashboard_outlined;
      case 'shopping_cart_outlined':
        return Icons.shopping_cart_outlined;
      case 'business_outlined':
        return Icons.business_outlined;
      case 'inventory_2_outlined':
        return Icons.inventory_2_outlined;
      case 'analytics_outlined':
        return Icons.analytics_outlined;
      case 'change_circle_outlined':
        return Icons.change_circle_outlined;
      case 'admin_panel_settings_outlined':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  /// Build settings items
  Widget _buildSettingsItems() {
    return Column(
      children: [
        _buildDrawerItem(
          icon: Icons.person_outline,
          title: 'profile'.tr,
          route: AppRoutes.profile,
          isActive: Get.currentRoute == AppRoutes.profile,
        ),
        _buildDrawerItem(
          icon: Icons.language_outlined,
          title: 'language'.tr,
          onTap: _showLanguageDialog,
        ),
        _buildDrawerItem(
          icon: Icons.workspace_premium_outlined,
          title: 'developer_info'.tr,
          onTap: _showDeveloperDialog,
        ),
      ],
    );
  }

  /// Build logout item
  Widget _buildLogoutItem(AuthController authController) {
    return _buildDrawerItem(
      icon: Icons.logout_outlined,
      title: 'logout'.tr,
      onTap: () => _showLogoutDialog(authController),
      isDestructive: true,
    );
  }

  /// Build individual drawer item
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? route,
    VoidCallback? onTap,
    bool isActive = false,
    bool isDestructive = false,
  }) {
    final color =
        isDestructive
            ? AppColors.error
            : isActive
            ? AppColors.primaryGreen
            : AppColors.darkGray;

    final backgroundColor =
        isActive
            ? AppColors.primaryGreen.withValues(alpha: 0.1)
            : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 24),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap:
            onTap ??
            () {
              if (route != null) {
                Get.back(); // Close drawer
                if (Get.currentRoute != route) {
                  NavigationHelper.offAllNamedWithRoleCheck(route);
                }
              }
            },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  /// Get role display name
  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'manager':
        return 'manager'.tr;
      case 'assistant_manager':
        return 'assistant_manager'.tr;
      case 'employee':
        return 'employee'.tr;
      case 'guest':
        return 'guest'.tr;
      case 'general_manager':
        return 'general_manager'.tr;
      case 'finance_manager':
        return 'finance_manager'.tr;
      case 'procurement_officer':
        return 'procurement_officer'.tr;
      case 'auditor':
        return 'auditor'.tr;
      default:
        return role.tr;
    }
  }

  /// Show language selection dialog
  void _showLanguageDialog() {
    Get.back(); // Close drawer first

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.white,
        title: Text(
          'select_language'.tr,
          style: const TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('arabic'.tr, 'ar'),
            const SizedBox(height: 8),
            _buildLanguageOption('english'.tr, 'en'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'cancel'.tr,
              style: const TextStyle(color: AppColors.darkGray),
            ),
          ),
        ],
      ),
    );
  }

  /// Build language option
  Widget _buildLanguageOption(String title, String languageCode) {
    return InkWell(
      onTap: () {
        Get.back();
        Get.updateLocale(Locale(languageCode));
        Get.find<StorageService>().saveLanguage(languageCode);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.mediumGray),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, color: AppColors.black),
        ),
      ),
    );
  }

  /// Show logout confirmation dialog
  void _showLogoutDialog(AuthController authController) {
    Get.back(); // Close drawer first

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.white,
        title: Text(
          'confirm_logout'.tr,
          style: const TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'logout_confirmation_message'.tr,
          style: const TextStyle(color: AppColors.darkGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'cancel'.tr,
              style: const TextStyle(color: AppColors.darkGray),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              authController.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: Text('logout'.tr),
          ),
        ],
      ),
    );
  }

  /// Show developer information dialog
  void _showDeveloperDialog() {
    Get.back(); // Close drawer first

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name with badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Eng Laith Alskaf',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.verified,
                        color: AppColors.primaryGreen,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    'developer_role'.tr,
                    style: TextStyle(
                      color: AppColors.darkGray.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Email container with copy action
                  InkWell(
                    onTap: () async {
                      await Clipboard.setData(
                        const ClipboardData(text: 'laithalskaf@gmail.com'),
                      );
                      Get.snackbar(
                        'copied'.tr,
                        'email_copied'.tr,
                        backgroundColor: AppColors.primaryGreen,
                        colorText: AppColors.white,
                        snackPosition: SnackPosition.BOTTOM,
                        margin: const EdgeInsets.all(12),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.email_outlined,
                            color: AppColors.primaryGreen,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'laithalskaf@gmail.com',
                            style: TextStyle(
                              color: AppColors.black,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.copy, color: AppColors.darkGray, size: 18),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Subtle separator
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: AppColors.mediumGray.withOpacity(0.3),
                  ),

                  const SizedBox(height: 12),

                  // Thank you note
                  Text(
                    'developer_thanks_message'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.darkGray,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text('ok'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Floating circular developer logo
            Positioned(
              top: -40,
              left: 0,
              right: 0,
              child: CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.white,
                child: CircleAvatar(
                  radius: 38,
                  backgroundImage: const AssetImage(
                    'assets/images/developer.jpg',
                  ),
                  backgroundColor: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
