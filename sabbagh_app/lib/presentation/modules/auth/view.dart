import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_colors.dart';
import 'package:sabbagh_app/core/constants/app_routes.dart';
import 'package:sabbagh_app/localization/localization_service.dart';
import 'package:sabbagh_app/presentation/modules/auth/controller.dart';

/// Login view
class LoginView extends GetView<AuthController> {
  /// Creates a new [LoginView]
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationService = Get.find<LocalizationService>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo placeholder
              const SizedBox(height: 100),
              Image.asset('assets/images/logo.png', width: 140, height: 140),
    
              const SizedBox(height: 50),
              Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Obx(
                          () => Checkbox(
                            value: controller.rememberMe.value,
                            onChanged:
                                (value) =>
                                    controller.rememberMe.value = value!,
                            activeColor: AppColors.primaryGreen,
                          ),
                        ),
                        Text('remember_me'.tr),
                        // const Spacer(),
                        // TextButton(
                        //   onPressed: controller.forgotPassword,
                        //   child: Text('forgot_password'.tr),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () =>
                          controller.errorMessage.value.isNotEmpty
                              ? Container(
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
                              )
                              : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 24),
                    Obx(
                      () => ElevatedButton(
                        onPressed:
                            controller.isLoading.value
                                ? null
                                : controller.login,
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
                                : Text('sign_in'.tr),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('language'.tr),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: localizationService.currentLanguage.value,
                    items:
                        localizationService.availableLanguages
                            .map(
                              (language) => DropdownMenuItem<String>(
                                value: language['code'],
                                child: Text(language['name']!),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        localizationService.changeLanguage(value);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Forgot password view
class ForgotPasswordView extends GetView<AuthController> {
  /// Creates a new [ForgotPasswordView]
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('forgot_password'.tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo placeholder
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      'S',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'forgot_password_description'.tr,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Form(
                  key: controller.forgotPasswordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: controller.forgotPasswordEmailController,
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
                        () =>
                            controller
                                    .forgotPasswordErrorMessage
                                    .value
                                    .isNotEmpty
                                ? Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red),
                                  ),
                                  child: Text(
                                    controller
                                        .forgotPasswordErrorMessage
                                        .value,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                )
                                : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 24),
                      Obx(
                        () => ElevatedButton(
                          onPressed:
                              controller.isForgotPasswordLoading.value
                                  ? null
                                  : controller.resetPassword,
                          child:
                              controller.isForgotPasswordLoading.value
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                            AppColors.white,
                                          ),
                                    ),
                                  )
                                  : Text('reset_password'.tr),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Get.offNamed(AppRoutes.login),
                        child: Text('back_to_login'.tr),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
