import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_routes.dart';
import 'package:sabbagh_app/core/services/dio_client.dart';
import 'package:sabbagh_app/domain/entities/user.dart';
import 'package:sabbagh_app/domain/entities/user_role.dart';

/// Controller for user management
class UserManagementController extends GetxController {
  final DioClient _dioClient = Get.find<DioClient>();
  
  /// Users list
  final RxList<User> users = <User>[].obs;
  
  /// Selected user
  final Rx<User?> selectedUser = Rx<User?>(null);
  
  /// Loading state
  final RxBool isLoading = false.obs;
  
  /// Error message
  final RxString errorMessage = ''.obs;
  
  /// Success message
  final RxString successMessage = ''.obs;
  
  /// Form key for user form
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  /// Name controller
  final TextEditingController nameController = TextEditingController();
  
  /// Email controller
  final TextEditingController emailController = TextEditingController();
  
  /// Password controller
  final TextEditingController passwordController = TextEditingController();
  
  /// Department controller
  final TextEditingController departmentController = TextEditingController();
  
  /// Phone controller
  final TextEditingController phoneController = TextEditingController();
  
  /// Selected role
  final Rx<UserRole> selectedRole = UserRole.employee.obs;
  
  /// Active status
  final RxBool isActive = true.obs;
  
  /// Password visibility
  final RxBool isPasswordVisible = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }
  
  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    departmentController.dispose();
    phoneController.dispose();
    super.onClose();
  }
  
  /// Fetch users
  Future<void> fetchUsers() async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      final response = await _dioClient.get('/admin/users');
      
      if (response['success'] == true) {
        final usersList = response['data'] as List<dynamic>;
        users.value = usersList
            .map((user) => User.fromJson(user as Map<String, dynamic>))
            .toList();
      } else {
        errorMessage.value = response['message'] as String? ?? 'error'.tr;
      }
    } catch (e) {
      errorMessage.value = e.toString().contains('Exception') ? e.toString() : 'server_error'.tr;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Get user by ID
  Future<void> getUserById(String id) async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      final response = await _dioClient.get('/admin/users/$id');
      
      if (response['success'] == true) {
        final userData = response['data'] as Map<String, dynamic>;
        selectedUser.value = User.fromJson(userData);
        
        // Set form values
        nameController.text = selectedUser.value!.name;
        emailController.text = selectedUser.value!.email;
        passwordController.text = '';
        departmentController.text = selectedUser.value!.department ?? '';
        phoneController.text = selectedUser.value!.phone ?? '';
        selectedRole.value = selectedUser.value!.role;
        isActive.value = selectedUser.value?.active ?? true;
      } else {
        errorMessage.value = response['message'] as String? ?? 'error'.tr;
      }
    } catch (e) {
      errorMessage.value = e.toString().contains('Exception') ? e.toString() : 'server_error'.tr;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Create user
  Future<void> createUser() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    
    isLoading.value = true;
    errorMessage.value = '';
    successMessage.value = '';
    
    try {
      final response = await _dioClient.post('/admin/users', data: {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text,
        'role': selectedRole.value.toApiString(),
        'department': departmentController.text.trim().isEmpty ? null : departmentController.text.trim(),
        'phone': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
        'is_active': isActive.value,
      });
      
      if (response['success'] == true) {
        successMessage.value = response['message'] as String? ?? 'user_created'.tr;
        Get.snackbar(
          'success'.tr,
          successMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
        
        // Clear form
        _clearForm();
        
        // Navigate back to users list
        Get.offNamed(AppRoutes.users);
      } else {
        errorMessage.value = response['message'] as String? ?? 'error'.tr;
      }
    } catch (e) {
      errorMessage.value = e.toString().contains('Exception') ? e.toString() : 'server_error'.tr;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Update user
  Future<void> updateUser(String id) async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    
    isLoading.value = true;
    errorMessage.value = '';
    successMessage.value = '';
    
    try {
      final data = <String, dynamic>{
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'role': selectedRole.value.toApiString(),
        'department': departmentController.text.trim().isEmpty ? null : departmentController.text.trim(),
        'phone': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
        'is_active': isActive.value,
      };
      
      // Add password only if it's not empty
      if (passwordController.text.isNotEmpty) {
        data['password'] = passwordController.text;
      }
      
      final response = await _dioClient.put('/admin/users/$id', data: data);
      
      if (response['success'] == true) {
        successMessage.value = response['message'] as String? ?? 'user_updated'.tr;
        Get.snackbar(
          'success'.tr,
          successMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
        
        // Clear form
        _clearForm();
        
        // Navigate back to users list
        Get.offNamed(AppRoutes.users);
      } else {
        errorMessage.value = response['message'] as String? ?? 'error'.tr;
      }
    } catch (e) {
      errorMessage.value = e.toString().contains('Exception') ? e.toString() : 'server_error'.tr;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Delete user
  Future<void> deleteUser(String id) async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      final response = await _dioClient.delete('/admin/users/$id');
      
      if (response['success'] == true) {
        successMessage.value = response['message'] as String? ?? 'user_deleted'.tr;
        Get.snackbar(
          'success'.tr,
          successMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
        
        // Refresh users list
        await fetchUsers();
      } else {
        errorMessage.value = response['message'] as String? ?? 'error'.tr;
      }
    } catch (e) {
      errorMessage.value = e.toString().contains('Exception') ? e.toString() : 'server_error'.tr;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
  
  /// Clear form
  void _clearForm() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    departmentController.clear();
    phoneController.clear();
    selectedRole.value = UserRole.employee;
    isActive.value = true;
    selectedUser.value = null;
  }
  
  /// Navigate to create user screen
  void navigateToCreateUser() {
    _clearForm();
    Get.toNamed(AppRoutes.createUser);
  }
  
  /// Navigate to edit user screen
  void navigateToEditUser(String id) {
    _clearForm();
    getUserById(id);
    Get.toNamed(AppRoutes.editUser.replaceAll(':id', id));
  }
  
  /// Navigate to user details screen
  void navigateToUserDetails(String id) {
    getUserById(id);
    Get.toNamed(AppRoutes.userDetails.replaceAll(':id', id));
  }
}