import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_colors.dart';
import 'package:sabbagh_app/presentation/modules/profile/controller.dart';
import 'package:sabbagh_app/presentation/widgets/custom_app_bar.dart';

/// Change password view
class ChangePasswordView extends GetView<ProfileController> {
  /// Creates a new [ChangePasswordView]
  const ChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'change_password'.tr,
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 32),
            _buildPasswordForm(),
            const SizedBox(height: 32),
            _buildChangePasswordButton(),
          ],
        ),
      ),
    );
  }

  /// Build header section
  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.secondaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 48,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'change_password'.tr,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'change_password_description'.tr,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build password form
  Widget _buildPasswordForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: controller.changePasswordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'password_requirements'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 16),
              _buildPasswordRequirements(),
              const SizedBox(height: 24),
              
              // Current Password
              Obx(() => _buildPasswordField(
                controller: controller.currentPasswordController,
                label: 'current_password'.tr,
                isObscured: controller.isCurrentPasswordObscured.value,
                onToggleVisibility: controller.toggleCurrentPasswordVisibility,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'current_password_required'.tr;
                  }
                  return null;
                },
              )),
              const SizedBox(height: 16),
              
              // New Password
              Obx(() => _buildPasswordField(
                controller: controller.newPasswordController,
                label: 'new_password'.tr,
                isObscured: controller.isNewPasswordObscured.value,
                onToggleVisibility: controller.toggleNewPasswordVisibility,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'new_password_required'.tr;
                  }
                  if (value.length < 8) {
                    return 'password_min_length'.tr;
                  }
                  if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
                    return 'password_complexity_error'.tr;
                  }
                  return null;
                },
                onChanged: (value) => controller.validatePasswordStrength(value),
              )),
              const SizedBox(height: 8),
              
              // Password strength indicator
              Obx(() => _buildPasswordStrengthIndicator()),
              const SizedBox(height: 16),
              
              // Confirm Password
              Obx(() => _buildPasswordField(
                controller: controller.confirmPasswordController,
                label: 'confirm_password'.tr,
                isObscured: controller.isConfirmPasswordObscured.value,
                onToggleVisibility: controller.toggleConfirmPasswordVisibility,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'confirm_password_required'.tr;
                  }
                  if (value != controller.newPasswordController.text) {
                    return 'passwords_do_not_match'.tr;
                  }
                  return null;
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  /// Build password field
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isObscured,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscured,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            isObscured ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppColors.lightGray,
      ),
      validator: validator,
    );
  }

  /// Build password requirements
  Widget _buildPasswordRequirements() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.info,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'password_must_contain'.tr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRequirementItem('password_min_8_chars'.tr),
          _buildRequirementItem('password_uppercase_letter'.tr),
          _buildRequirementItem('password_lowercase_letter'.tr),
          _buildRequirementItem('password_number'.tr),
        ],
      ),
    );
  }

  /// Build requirement item
  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.success,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.darkGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build password strength indicator
  Widget _buildPasswordStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'password_strength'.tr,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: controller.passwordStrength.value / 4,
                backgroundColor: AppColors.lightGray,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getPasswordStrengthColor(controller.passwordStrength.value),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _getPasswordStrengthText(controller.passwordStrength.value),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getPasswordStrengthColor(controller.passwordStrength.value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Get password strength color
  Color _getPasswordStrengthColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.info;
      case 4:
        return AppColors.success;
      default:
        return AppColors.lightGray;
    }
  }

  /// Get password strength text
  String _getPasswordStrengthText(int strength) {
    switch (strength) {
      case 0:
        return 'very_weak'.tr;
      case 1:
        return 'weak'.tr;
      case 2:
        return 'fair'.tr;
      case 3:
        return 'good'.tr;
      case 4:
        return 'strong'.tr;
      default:
        return '';
    }
  }

  /// Build change password button
  Widget _buildChangePasswordButton() {
    return SizedBox(
      width: double.infinity,
      child: Obx(() => ElevatedButton.icon(
        onPressed: controller.isLoading.value 
            ? null 
            : controller.changePassword,
        icon: controller.isLoading.value
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : const Icon(Icons.lock_reset),
        label: Text(
          controller.isLoading.value 
              ? 'changing_password'.tr 
              : 'change_password'.tr,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      )),
    );
  }
}