import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_colors.dart';
import 'package:sabbagh_app/presentation/modules/profile/controller.dart';
import 'package:sabbagh_app/presentation/widgets/app_drawer.dart';

/// Profile view
class ProfileView extends GetView<ProfileController> {
  /// Creates a new [ProfileView]
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text('profile'.tr),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildProfileMenu(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfileHeader() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primaryGreen,
              child: Text(
                controller.user?.name.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.user?.name ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.user?.email ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      controller.userRole,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfileMenu() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock),
            title: Text('change_password'.tr),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: controller.navigateToChangePassword,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text('settings'.tr),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: controller.navigateToSettings,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              'logout'.tr,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () {
              showDialog(
                context: Get.context!,
                builder: (context) => AlertDialog(
                  title: Text('logout'.tr),
                  content: Text('logout_confirmation'.tr),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('cancel'.tr),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        controller.logout();
                      },
                      child: Text(
                        'logout'.tr,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Settings view
class SettingsView extends GetView<ProfileController> {
  /// Creates a new [SettingsView]
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'appearance'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Column(
                children: [
                  ListTile(
                    title: Text('language'.tr),
                    trailing: Obx(() => DropdownButton<String>(
                      value: controller.selectedLanguage.value,
                      underline: const SizedBox.shrink(),
                      items: [
                        DropdownMenuItem(
                          value: 'en',
                          child: Text('english'.tr),
                        ),
                        DropdownMenuItem(
                          value: 'ar',
                          child: Text('arabic'.tr),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          controller.changeLanguage(value);
                        }
                      },
                    )),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text('theme'.tr),
                    trailing: Obx(() => DropdownButton<String>(
                      value: controller.selectedTheme.value,
                      underline: const SizedBox.shrink(),
                      items: controller.themes.map((theme) => DropdownMenuItem(
                        value: theme['value'],
                        child: Text(theme['name']!.tr),
                      )).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.changeTheme(value);
                        }
                      },
                    )),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'about'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Column(
                children: [
                  ListTile(
                    title: Text('app_name'.tr),
                    subtitle: const Text('Sabbagh Purchase Management'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text('version'.tr),
                    subtitle: const Text('1.0.0'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text('developer'.tr),
                    subtitle: const Text('Laith Alskaf'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}