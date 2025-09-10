import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_colors.dart';
import 'package:sabbagh_app/localization/localization_service.dart';
import 'package:sabbagh_app/presentation/controllers/user_controller.dart';
import 'package:sabbagh_app/presentation/modules/auth/controller.dart';
import 'package:sabbagh_app/presentation/widgets/app_drawer.dart';

/// Simple test dashboard for testing navigation
class TestDashboard extends StatelessWidget {
  const TestDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationService = Get.find<LocalizationService>();
    final userController = Get.find<UserController>();
    final authController = Get.find<AuthController>();
    
    return Directionality(
      textDirection: localizationService.textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text('dashboard'.tr),
          actions: [
            IconButton(
              icon: const Icon(Icons.language),
              onPressed: () {
                _showLanguageDialog(context, localizationService);
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => authController.logout(),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'welcome'.tr,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 8),
                      Obx(() => Text(
                        userController.user.value?.name ?? 'Unknown User',
                        style: Theme.of(context).textTheme.titleLarge,
                      )),
                      const SizedBox(height: 4),
                      Obx(() => Text(
                        userController.role.toApiString().tr,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'permissions'.tr,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() => ListView(
                  children: [
                    _buildPermissionTile(
                      'create_purchase_orders'.tr,
                      userController.canCreatePurchaseOrders,
                    ),
                    _buildPermissionTile(
                      'approve_purchase_orders'.tr,
                      userController.canApprovePurchaseOrders,
                    ),
                    _buildPermissionTile(
                      'create_vendors'.tr,
                      userController.canCreateVendors,
                    ),
                    _buildPermissionTile(
                      'create_items'.tr,
                      userController.canCreateItems,
                    ),
                    _buildPermissionTile(
                      'view_reports'.tr,
                      userController.canViewReports,
                    ),
                    _buildPermissionTile(
                      'create_users'.tr,
                      userController.canCreateUsers,
                    ),
                  ],
                )),
              ),
            ],
          ),
        ),
        drawer: const AppDrawer(),
      ),
    );
  }

  Widget _buildPermissionTile(String title, bool hasPermission) {
    return ListTile(
      leading: Icon(
        hasPermission ? Icons.check_circle : Icons.cancel,
        color: hasPermission ? AppColors.success : AppColors.error,
      ),
      title: Text(title),
      trailing: Text(
        hasPermission ? 'allowed'.tr : 'denied'.tr,
        style: TextStyle(
          color: hasPermission ? AppColors.success : AppColors.error,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LocalizationService localizationService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('language'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: localizationService.availableLanguages.map((language) {
              return ListTile(
                title: Text(language['name']!),
                onTap: () {
                  localizationService.changeLanguage(language['code']!);
                  Navigator.pop(context);
                },
                trailing: Obx(() => localizationService.currentLanguage.value == language['code']
                    ? const Icon(Icons.check, color: AppColors.primaryGreen)
                    : const SizedBox.shrink()),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('cancel'.tr),
            ),
          ],
        );
      },
    );
  }
}