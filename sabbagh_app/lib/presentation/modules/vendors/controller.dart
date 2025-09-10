import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_routes.dart';
import 'package:sabbagh_app/domain/entities/vendor.dart';
import 'package:sabbagh_app/presentation/controllers/user_controller.dart';
import 'package:sabbagh_app/presentation/modules/vendors/repository.dart';

/// Controller for vendors
class VendorController extends GetxController {
  final VendorRepository _repository;
  final UserController _userController;

  /// Creates a new [VendorController]
  VendorController(this._repository, this._userController);

  /// Loading state
  final RxBool isLoading = false.obs;

  /// Vendors
  final RxList<Vendor> vendors = <Vendor>[].obs;

  /// Selected vendor
  final Rx<Vendor?> selectedVendor = Rx<Vendor?>(null);

  /// Search query
  final RxString searchQuery = ''.obs;

  /// Active filter
  final Rx<bool?> activeFilter = Rx<bool?>(null);

  /// Sort by
  final RxString sortBy = 'name'.obs;

  /// Sort order
  final RxString sortOrder = 'asc'.obs;

  /// Current page
  final RxInt currentPage = 1.obs;

  /// Total pages
  final RxInt totalPages = 1.obs;

  /// Form key for create/edit form
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  /// Name controller
  final TextEditingController nameController = TextEditingController();

  /// Contact person controller
  final TextEditingController contactPersonController = TextEditingController();

  /// Phone controller
  final TextEditingController phoneController = TextEditingController();

  /// Email controller
  final TextEditingController emailController = TextEditingController();

  /// Address controller
  final TextEditingController addressController = TextEditingController();

  /// Notes controller
  final TextEditingController notesController = TextEditingController();

  /// Rating
  final RxInt rating = 0.obs;

  /// Active
  final RxBool active = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchVendors();
  }

  @override
  void onClose() {
    nameController.dispose();
    contactPersonController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    notesController.dispose();
    super.onClose();
  }

  /// Fetch vendors
  Future<void> fetchVendors() async {
    isLoading.value = true;

    try {
      final vendorsList = await _repository.getVendors(
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
        sortBy: sortBy.value,
        sortOrder: sortOrder.value,
        active: activeFilter.value,
        page: currentPage.value,
      );

      vendors.value = vendorsList;
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_load_vendors'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh purchase orders
  Future<void> refreshVendors() async {
    await fetchVendors();
  }

  /// Get vendor by ID
  Future<void> getVendorById(String id) async {
    isLoading.value = true;

    try {
      final vendor = await _repository.getVendorById(id);
      selectedVendor.value = vendor;

      // Set form values
      nameController.text = vendor.name;
      contactPersonController.text = vendor.contactPerson ?? '';
      phoneController.text = vendor.phone ?? '';
      emailController.text = vendor.email ?? '';
      addressController.text = vendor.address ?? '';
      notesController.text = vendor.notes ?? '';
      rating.value = vendor.rating ?? 0;
      active.value = vendor.active;
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_load_vendor'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Create vendor
  Future<void> createVendor() async {
    if (formKey.currentState == null || !formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    try {
      final data = {
        'name': nameController.text,
        'contact_person':
            contactPersonController.text.isEmpty
                ? null
                : contactPersonController.text,
        'phone': phoneController.text.isEmpty ? null : phoneController.text,
        'email': emailController.text.isEmpty ? '' : emailController.text,
        'address':
            addressController.text.isEmpty ? null : addressController.text,
        'rating': rating.value == 0 ? null : rating.value,
        'active': active.value,
        'notes': notesController.text.isEmpty ? null : notesController.text,
      };

      if (_userController.canCreateVendors) {
        // Direct creation
        final vendor = await _repository.createVendor(data);
        Get.back();
        Get.snackbar(
          'success'.tr,
          'vendor_created'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );

        // Navigate to vendor details
        Get.toNamed(
          '${AppRoutes.vendorDetails.replaceAll(':id', '')}${vendor.id}',
        );
      } else if (_userController.canRequestVendorCreation) {
        // Request creation
        final response = await _repository.requestVendorCreation(data);
        Get.back();
        Get.snackbar(
          'success'.tr,
          'vendor_creation_requested'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        fetchVendors();
      } else {
        Get.snackbar(
          'error'.tr,
          'no_permission'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_create_vendor'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Update vendor
  Future<void> updateVendor(String id) async {
    if (formKey.currentState == null || !formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    try {
      final data = {
        'name': nameController.text,
        'contact_person':
            contactPersonController.text.isEmpty
                ? null
                : contactPersonController.text,
        'phone': phoneController.text.isEmpty ? null : phoneController.text,
        'email': emailController.text.isEmpty ? null : emailController.text,
        'address':
            addressController.text.isEmpty ? null : addressController.text,
        'rating': rating.value == 0 ? null : rating.value,
        'active': active.value,
        'notes': notesController.text.isEmpty ? null : notesController.text,
      };

      if (_userController.canEditVendors) {
        // Direct update
        final vendor = await _repository.updateVendor(id, data);
        selectedVendor.value = vendor;
        Get.back();
        Get.snackbar(
          'success'.tr,
          'vendor_updated'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else if (_userController.canRequestVendorEdit) {
        // Request update
        final response = await _repository.requestVendorUpdate(id, data);
        Get.back();
        Get.snackbar(
          'success'.tr,
          'vendor_update_requested'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          'no_permission'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_update_vendor'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete vendor
  Future<void> deleteVendor(String id) async {
    if (!_userController.canDeleteVendors) {
      Get.snackbar(
        'error'.tr,
        'no_permission'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;

    try {
      final success = await _repository.deleteVendor(id);
      if (success) {
        vendors.removeWhere((vendor) => vendor.id == id);
        Get.back();
        Get.snackbar(
          'success'.tr,
          'vendor_deleted'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );

        // Navigate back to vendors list
        Get.offNamed(AppRoutes.vendors);
      } else {
        Get.snackbar(
          'error'.tr,
          'failed_to_delete_vendor'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_delete_vendor'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset form
  void resetForm() {
    nameController.clear();
    contactPersonController.clear();
    phoneController.clear();
    emailController.clear();
    addressController.clear();
    notesController.clear();
    rating.value = 0;
    active.value = true;
  }

  /// Search vendors
  void searchVendors(String query) {
    searchQuery.value = query;
    currentPage.value = 1;
    fetchVendors();
  }

  /// Filter vendors by active status
  void filterVendorsByActive(bool? active) {
    activeFilter.value = active;
    currentPage.value = 1;
    fetchVendors();
  }

  /// Sort vendors
  void sortVendors(String sortByField, String sortOrderValue) {
    sortBy.value = sortByField;
    sortOrder.value = sortOrderValue;
    currentPage.value = 1;
    fetchVendors();
  }

  /// Go to page
  void goToPage(int page) {
    if (page < 1 || page > totalPages.value) {
      return;
    }

    currentPage.value = page;
    fetchVendors();
  }

  /// Next page
  void nextPage() {
    if (currentPage.value < totalPages.value) {
      currentPage.value++;
      fetchVendors();
    }
  }

  /// Previous page
  void previousPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
      fetchVendors();
    }
  }

  /// Check if user can create vendors
  bool get canCreateVendors {
    try {
      return _userController.canCreateVendors;
    } catch (e) {
      return false;
    }
  }

  /// Check if user can request vendor creation
  bool get canRequestVendorCreation {
    try {
      return _userController.canRequestVendorCreation;
    } catch (e) {
      return false;
    }
  }

  /// Check if user can edit vendors
  bool get canEditVendors {
    try {
      return _userController.canEditVendors;
    } catch (e) {
      return false;
    }
  }

  /// Check if user can request vendor edit
  bool get canRequestVendorEdit {
    try {
      return _userController.canRequestVendorEdit;
    } catch (e) {
      return false;
    }
  }

  /// Check if user can delete vendors
  bool get canDeleteVendors {
    try {
      return _userController.canDeleteVendors;
    } catch (e) {
      return false;
    }
  }

  /// Show delete confirmation dialog
  void showDeleteConfirmationDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('delete_vendor'.tr),
          content: Text('delete_vendor_confirmation'.tr),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('cancel'.tr),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                deleteVendor(id);
              },
              child: Text('delete'.tr),
            ),
          ],
        );
      },
    );
  }
}
