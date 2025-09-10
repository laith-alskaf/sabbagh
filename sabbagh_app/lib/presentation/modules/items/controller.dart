import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_routes.dart';
import 'package:sabbagh_app/domain/entities/item.dart';
import 'package:sabbagh_app/presentation/controllers/user_controller.dart';
import 'package:sabbagh_app/presentation/modules/items/repository.dart';

/// Controller for items
class ItemController extends GetxController {
  final ItemRepository _repository;
  final UserController _userController;

  /// Creates a new [ItemController]
  ItemController(this._repository, this._userController);

  /// Loading state
  final RxBool isLoading = false.obs;

  /// Items
  final RxList<Item> items = <Item>[].obs;

  /// Selected item
  final Rx<Item?> selectedItem = Rx<Item?>(null);

  /// Search query
  final RxString searchQuery = ''.obs;

  /// Category filter
  final RxString categoryFilter = ''.obs;

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

  /// Code controller
  final TextEditingController codeController = TextEditingController();

  /// Description controller
  final TextEditingController descriptionController = TextEditingController();

  /// Unit controller
  final RxString unitController = ''.obs;

  /// Active
  final RxBool active = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchItems();
  }

  @override
  void onClose() {
    nameController.dispose();
    codeController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  /// Fetch items
  Future<void> fetchItems() async {
    isLoading.value = true;

    try {
      final itemsList = await _repository.getItems(
        search: searchQuery.value.isEmpty ? '' : searchQuery.value,
        category: categoryFilter.value.isEmpty ? null : categoryFilter.value,
        sortBy: sortBy.value,
        sortOrder: sortOrder.value,
        active:
            activeFilter.value == null
                ? null
                : (activeFilter.value ?? true ? 'active' : 'archived'),
        page: currentPage.value,
      );

      items.value = itemsList;
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_load_items'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Get item by ID
  Future<void> getItemById(String id) async {
    isLoading.value = true;

    try {
      final item = await _repository.getItemById(id);
      selectedItem.value = item;

      // Set form values
      nameController.text = item.name;
      codeController.text = item.code;
      descriptionController.text = item.description ?? '';
      unitController.value = item.unit;
      active.value = item.active == 'active';
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_load_item'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh purchase orders
  Future<void> refreshPurchaseOrders() async {
    await fetchItems();
  }

  /// Create item
  Future<void> createItem() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    try {
      final data = {
        'name': nameController.text,
        'code': codeController.text,
        'description':
            descriptionController.text.isEmpty
                ? null
                : descriptionController.text,
        'unit': unitController.value,
        'active': active.value ? 'active' : 'archived',
      };

      // TODO عند انشاء العنصر لا يتم الرجوع الى الخلف ويظهر رسالة ال catch علما ان الطلب تم انشائه للمساعد

      if (_userController.canCreateItems) {
        final item = await _repository.createItem(data);
        Get.back();
        Get.snackbar(
          'success'.tr,
          'item_created'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );

        // Navigate to item details
        getItemById(item.id);
        Get.toNamed(
          AppRoutes.itemDetails.replaceAll(':id', item.id),
          parameters: {'id': item.id},
        );
        resetForm();
        fetchItems();
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
        'failed_to_create_item'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Update item
  Future<void> updateItem(String id) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    try {
      final data = {
        'name': nameController.text,
        'code': codeController.text,
        'description':
            descriptionController.text.isEmpty
                ? null
                : descriptionController.text,
        'unit': unitController.value,
        'active': active.value ? 'active' : 'archived',
      };

      if (_userController.canEditItems) {
        // Direct update
        final item = await _repository.updateItem(id, data);
        selectedItem.value = item;
        Get.back();
        Get.snackbar(
          'success'.tr,
          'item_updated'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        fetchItems();
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
        'failed_to_update_item'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete item
  Future<void> deleteItem(String id) async {
    if (!_userController.canDeleteItems) {
      Get.snackbar(
        'error'.tr,
        'no_permission'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;

    try {
      final success = await _repository.deleteItem(id);
      if (success) {
        items.removeWhere((item) => item.id == id);
        Get.back();
        Get.snackbar(
          'success'.tr,
          'item_deleted'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );

        // Navigate back to items list
        Get.offNamed(AppRoutes.items);
      } else {
        Get.snackbar(
          'error'.tr,
          'failed_to_delete_item'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_delete_item'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset form
  void resetForm() {
    nameController.clear();
    codeController.clear();
    descriptionController.clear();
    active.value = true;
  }

  /// Search items
  void searchItems(String query) {
    searchQuery.value = query;
    currentPage.value = 1;
    fetchItems();
  }

  /// Filter items by category
  void filterItemsByCategory(String category) {
    categoryFilter.value = category;
    currentPage.value = 1;
    fetchItems();
  }

  /// Filter items by active status
  void filterItemsByActive(bool? active) {
    activeFilter.value = active;
    currentPage.value = 1;
    fetchItems();
  }

  /// Sort items
  void sortItems(String sortByField, String sortOrderValue) {
    sortBy.value = sortByField;
    sortOrder.value = sortOrderValue;
    currentPage.value = 1;
    fetchItems();
  }

  /// Go to page
  void goToPage(int page) {
    if (page < 1 || page > totalPages.value) {
      return;
    }

    currentPage.value = page;
    fetchItems();
  }

  /// Next page
  void nextPage() {
    if (currentPage.value < totalPages.value) {
      currentPage.value++;
      fetchItems();
    }
  }

  /// Previous page
  void previousPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
      fetchItems();
    }
  }

  /// Refresh items
  Future<void> refreshItems() async {
    await fetchItems();
  }

  /// Check if user can create items
  bool get canCreateItems => _userController.canCreateItems;

  /// Check if user can request item creation
  bool get canRequestItemCreation => _userController.canRequestItemCreation;

  /// Check if user can edit items
  bool get canEditItems => _userController.canEditItems;

  /// Check if user can delete items
  bool get canDeleteItems => _userController.canDeleteItems;

  /// Show delete confirmation dialog
  void showDeleteConfirmationDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('delete_item'.tr),
          content: Text('delete_item_confirmation'.tr),
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
                deleteItem(id);
              },
              child: Text('delete'.tr),
            ),
          ],
        );
      },
    );
  }
}
