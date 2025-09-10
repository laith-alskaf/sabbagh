import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_colors.dart';
import 'package:sabbagh_app/core/constants/app_routes.dart';
import 'package:sabbagh_app/domain/entities/user_role.dart';
import 'package:sabbagh_app/presentation/modules/users/controller.dart';
import 'package:sabbagh_app/presentation/widgets/app_drawer.dart';

/// Users view
class UsersView extends GetView<UserManagementController> {
  /// Creates a new [UsersView]
  const UsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('users'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.fetchUsers,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.navigateToCreateUser,
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  controller.errorMessage.value,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.fetchUsers,
                  child: Text('retry'.tr),
                ),
              ],
            ),
          );
        }

        if (controller.users.isEmpty) {
          return Center(child: Text('no_users_found'.tr));
        }

        return ListView.builder(
          itemCount: controller.users.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final user = controller.users[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryGreen,
                  child: Text(
                    user.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(user.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.email),
                    Text(
                      _getRoleText(user.role),
                      style: TextStyle(
                        color: _getRoleColor(user.role),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (user.active == false)
                      const Icon(Icons.block, color: Colors.red),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => controller.navigateToEditUser(user.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed:
                          () => _showDeleteConfirmation(
                            context,
                            user.id,
                            user.name,
                          ),
                    ),
                  ],
                ),
                onTap: () => controller.navigateToUserDetails(user.id),
              ),
            );
          },
        );
      }),
    );
  }

  /// Get role text
  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.manager:
        return 'manager'.tr;
      case UserRole.assistantManager:
        return 'assistant_manager'.tr;
      case UserRole.employee:
        return 'employee'.tr;
      case UserRole.guest:
        return 'guest'.tr;
      case UserRole.financeManager:
        return 'finance_manager'.tr;
      case UserRole.generalManager:
        return 'general_manager'.tr;
      case UserRole.procurementOfficer:
        return 'procurement_officer'.tr;
      case UserRole.auditor:
        return 'auditor'.tr;
    }
  }

  /// Get role color
  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.manager:
      case UserRole.generalManager:
      case UserRole.financeManager:
      case UserRole.auditor:
        return Colors.purple;
      case UserRole.assistantManager:
        return Colors.blue;
      case UserRole.employee:
      case UserRole.procurementOfficer:
        return Colors.green;
      case UserRole.guest:
        return Colors.grey;
    }
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, String id, String name) {
    Get.dialog(
      AlertDialog(
        title: Text('confirm_delete'.tr),
        content: Text('confirm_delete_user'.trParams({'name': name})),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteUser(id);
            },
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// User details view
class UserDetailsView extends GetView<UserManagementController> {
  /// Creates a new [UserDetailsView]
  const UserDetailsView({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('user_details'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              if (controller.selectedUser.value != null) {
                controller.navigateToEditUser(
                  controller.selectedUser.value!.id,
                );
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
    
        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Text(
              controller.errorMessage.value,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
    
        if (controller.selectedUser.value == null) {
          return Center(child: Text('user_not_found'.tr));
        }
    
        final user = controller.selectedUser.value!;
    
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primaryGreen,
                  child: Text(
                    user.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 40),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildInfoCard(
                title: 'personal_info'.tr,
                children: [
                  _buildInfoRow('name'.tr, user.name),
                  _buildInfoRow('email'.tr, user.email),
                  _buildInfoRow('phone'.tr, user.phone ?? 'not_provided'.tr),
                  _buildInfoRow(
                    'department'.tr,
                    user.department ?? 'not_provided'.tr,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'account_info'.tr,
                children: [
                  _buildInfoRow(
                    'role'.tr,
                    _getRoleText(user.role),
                    valueColor: _getRoleColor(user.role),
                  ),
                  _buildInfoRow(
                    'status'.tr,
                    (user.active == true) ? 'active'.tr : 'inactive'.tr,
                    valueColor:
                        (user.active == true) ? Colors.green : Colors.red,
                  ),
                  _buildInfoRow('created_at'.tr, _formatDate(user.createdAt)),
                  _buildInfoRow('updated_at'.tr, _formatDate(user.updatedAt)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    controller.navigateToEditUser(user.id);
                  },
                  icon: const Icon(Icons.edit),
                  label: Text('edit_user'.tr),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showDeleteConfirmation(context, user.id, user.name);
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: Text(
                    'delete_user'.tr,
                    style: const TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// Build info card
  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  /// Build info row
  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: valueColor != null ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  /// Get role text
  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.manager:
        return 'manager'.tr;
      case UserRole.assistantManager:
        return 'assistant_manager'.tr;
      case UserRole.employee:
        return 'employee'.tr;
      case UserRole.guest:
        return 'guest'.tr;
      case UserRole.financeManager:
        return 'finance_manager'.tr;
      case UserRole.generalManager:
        return 'general_manager'.tr;
      case UserRole.procurementOfficer:
        return 'procurement_officer'.tr;
      case UserRole.auditor:
        return 'auditor'.tr;
    }
  }

  /// Get role color
  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.manager:
      case UserRole.generalManager:
      case UserRole.financeManager:
      case UserRole.auditor:
        return Colors.purple;
      case UserRole.assistantManager:
        return Colors.blue;
      case UserRole.employee:
      case UserRole.procurementOfficer:
        return Colors.green;
      case UserRole.guest:
        return Colors.grey;
    }
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, String id, String name) {
    Get.dialog(
      AlertDialog(
        title: Text('confirm_delete'.tr),
        content: Text('confirm_delete_user'.trParams({'name': name})),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteUser(id);
              Get.offNamed(AppRoutes.users);
            },
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// Create user view
class CreateUserView extends GetView<UserManagementController> {
  /// Creates a new [CreateUserView]
  const CreateUserView({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text('create_user'.tr)),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
    
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'user_info'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.nameController,
                  decoration: InputDecoration(
                    labelText: 'name'.tr,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'required_field'.tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.emailController,
                  decoration: InputDecoration(
                    labelText: 'email'.tr,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'required_field'.tr;
                    }
                    if (!GetUtils.isEmail(value)) {
                      return 'invalid_email'.tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Obx(
                  () => TextFormField(
                    controller: controller.passwordController,
                    decoration: InputDecoration(
                      labelText: 'password'.tr,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isPasswordVisible.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                    ),
                    obscureText: !controller.isPasswordVisible.value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'required_field'.tr;
                      }
                      if (value.length < 8) {
                        return 'invalid_password'.tr;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.departmentController,
                  decoration: InputDecoration(
                    labelText: 'department'.tr,
                    prefixIcon: const Icon(Icons.business_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.phoneController,
                  decoration: InputDecoration(
                    labelText: 'phone'.tr,
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                Text(
                  'role_and_permissions'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserRole>(
                  value: controller.selectedRole.value,
                  decoration: InputDecoration(
                    labelText: 'role'.tr,
                    prefixIcon: const Icon(
                      Icons.admin_panel_settings_outlined,
                    ),
                  ),
                  items:
                      UserRole.values.map((role) {
                        return DropdownMenuItem<UserRole>(
                          value: role,
                          child: Text(_getRoleText(role)),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedRole.value = value;
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Obx(
                      () => Switch(
                        value: controller.isActive.value,
                        onChanged:
                            (value) => controller.isActive.value = value,
                        activeColor: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('active_account'.tr),
                  ],
                ),
                const SizedBox(height: 16),
                if (controller.errorMessage.value.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Text(
                      controller.errorMessage.value,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        controller.isLoading.value
                            ? null
                            : controller.createUser,
                    child:
                        controller.isLoading.value
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white,
                                ),
                              ),
                            )
                            : Text('create_user'.tr),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: Text('cancel'.tr),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Get role text
  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.manager:
        return 'manager'.tr;
      case UserRole.assistantManager:
        return 'assistant_manager'.tr;
      case UserRole.employee:
        return 'employee'.tr;
      case UserRole.guest:
        return 'guest'.tr;
      case UserRole.financeManager:
        return 'finance_manager'.tr;
      case UserRole.generalManager:
        return 'general_manager'.tr;
      case UserRole.procurementOfficer:
        return 'procurement_officer'.tr;
      case UserRole.auditor:
        return 'auditor'.tr;
    }
  }
}

/// Edit user view
class EditUserView extends GetView<UserManagementController> {
  /// Creates a new [EditUserView]
  const EditUserView({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Get.parameters['id'] ?? '';

    return Scaffold(
      appBar: AppBar(title: Text('edit_user'.tr)),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
    
        if (controller.selectedUser.value == null) {
          return Center(child: Text('user_not_found'.tr));
        }
    
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'user_info'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.nameController,
                  decoration: InputDecoration(
                    labelText: 'name'.tr,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'required_field'.tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.emailController,
                  decoration: InputDecoration(
                    labelText: 'email'.tr,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'required_field'.tr;
                    }
                    if (!GetUtils.isEmail(value)) {
                      return 'invalid_email'.tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Obx(
                  () => TextFormField(
                    controller: controller.passwordController,
                    decoration: InputDecoration(
                      labelText: 'password'.tr,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isPasswordVisible.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                      helperText: 'leave_empty_to_keep_current_password'.tr,
                    ),
                    obscureText: !controller.isPasswordVisible.value,
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          value.length < 8) {
                        return 'invalid_password'.tr;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.departmentController,
                  decoration: InputDecoration(
                    labelText: 'department'.tr,
                    prefixIcon: const Icon(Icons.business_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.phoneController,
                  decoration: InputDecoration(
                    labelText: 'phone'.tr,
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                Text(
                  'role_and_permissions'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserRole>(
                  value: controller.selectedRole.value,
                  decoration: InputDecoration(
                    labelText: 'role'.tr,
                    prefixIcon: const Icon(
                      Icons.admin_panel_settings_outlined,
                    ),
                  ),
                  items:
                      UserRole.values.map((role) {
                        return DropdownMenuItem<UserRole>(
                          value: role,
                          child: Text(_getRoleText(role)),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedRole.value = value;
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Obx(
                      () => Switch(
                        value: controller.isActive.value,
                        onChanged:
                            (value) => controller.isActive.value = value,
                        activeColor: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('active_account'.tr),
                  ],
                ),
                const SizedBox(height: 16),
                if (controller.errorMessage.value.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Text(
                      controller.errorMessage.value,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        controller.isLoading.value
                            ? null
                            : () => controller.updateUser(userId),
                    child:
                        controller.isLoading.value
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white,
                                ),
                              ),
                            )
                            : Text('update_user'.tr),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: Text('cancel'.tr),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Get role text
  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.manager:
        return 'manager'.tr;
      case UserRole.assistantManager:
        return 'assistant_manager'.tr;
      case UserRole.employee:
        return 'employee'.tr;
      case UserRole.guest:
        return 'guest'.tr;
      case UserRole.financeManager:
        return 'finance_manager'.tr;
      case UserRole.generalManager:
        return 'general_manager'.tr;
      case UserRole.procurementOfficer:
        return 'procurement_officer'.tr;
      case UserRole.auditor:
        return 'auditor'.tr;
    }
  }
}
