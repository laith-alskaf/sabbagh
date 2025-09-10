import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_colors.dart';
import 'package:sabbagh_app/core/constants/app_routes.dart';
import 'package:sabbagh_app/domain/entities/item.dart';
import 'package:sabbagh_app/presentation/modules/items/controller.dart';
import 'package:sabbagh_app/presentation/widgets/app_drawer.dart';
import 'package:sabbagh_app/presentation/widgets/custom_app_bar.dart';
import 'package:sabbagh_app/presentation/widgets/drop_menu.dart';

/// Items view
class ItemsView extends GetView<ItemController> {
  /// Creates a new [ItemsView]
  const ItemsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'items'.tr,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.white),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: controller.refreshPurchaseOrders,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: controller.refreshItems,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.items.isEmpty) {
            return Center(child: Text('no_items_found'.tr));
          }

          return ListView.builder(
            itemCount: controller.items.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final item = controller.items[index];
              return _buildItemCard(context, item);
            },
          );
        }),
      ),
      floatingActionButton: Obx(() {
        if (controller.canCreateItems || controller.canRequestItemCreation) {
          return FloatingActionButton(
            onPressed: () {
              Get.toNamed(AppRoutes.createItem);
            },
            backgroundColor: AppColors.primaryGreen,
            child: const Icon(Icons.add),
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }

  Widget _buildItemCard(BuildContext context, Item item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          controller.getItemById(item.id);
          Get.toNamed(
            '${AppRoutes.itemDetails.replaceAll(':id', '')}${item.id}',
            parameters: {'id': item.id},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          item.active == 'active'
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            item.active == 'active'
                                ? AppColors.success
                                : AppColors.error,
                      ),
                    ),
                    child: Text(
                      item.active.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            item.active == 'active'
                                ? AppColors.success
                                : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${'code'.tr}: ${item.code}',
                style: const TextStyle(fontSize: 14, color: AppColors.darkGray),
              ),

              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${'unit'.tr}: ${item.unit.tr}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('search_items'.tr),
          content: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'search_by_name_or_code'.tr,
              prefixIcon: const Icon(Icons.search),
            ),
            onSubmitted: (value) {
              controller.searchItems(value);
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('cancel'.tr),
            ),
            TextButton(
              onPressed: () {
                controller.searchItems(searchController.text);
                Navigator.pop(context);
              },
              child: Text('search'.tr),
            ),
          ],
        );
      },
    );
  }

  void _showFilterDialog(BuildContext context) {
    final selectedCategory = controller.categoryFilter.value.obs;
    final selectedActive = controller.activeFilter.value.obs;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('filter_items'.tr),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'category'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),
                Text(
                  'status'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => DropdownButtonFormField<bool?>(
                    value: selectedActive.value,
                    decoration: InputDecoration(hintText: 'select_status'.tr),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text('all_statuses'.tr),
                      ),
                      DropdownMenuItem(value: true, child: Text('active'.tr)),
                      DropdownMenuItem(
                        value: false,
                        child: Text('inactive'.tr),
                      ),
                    ],
                    onChanged: (value) {
                      selectedActive.value = value;
                      controller.activeFilter.value = value;
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('cancel'.tr),
            ),
            TextButton(
              onPressed: () {
                controller.filterItemsByCategory(selectedCategory.value);
                controller.filterItemsByActive(selectedActive.value);
                Navigator.pop(context);
              },
              child: Text('apply'.tr),
            ),
          ],
        );
      },
    );
  }
}

/// Item details view
class ItemDetailsView extends GetView<ItemController> {
  /// Creates a new [ItemDetailsView]
  const ItemDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final id = Get.parameters['id'];
    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: Text('item_details'.tr)),
        body: Center(child: Text('item_not_found'.tr)),
      );
    }

    // Fetch item details
    if (controller.selectedItem.value?.id != id) {
      controller.getItemById(id);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('item_details'.tr),
        actions: [
          Obx(() {
            if (controller.isLoading.value) {
              return const SizedBox.shrink();
            }

            if (controller.canEditItems) {
              return IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Get.toNamed(
                    '${AppRoutes.editItem.replaceAll(':id', '')}$id',
                    parameters: {'id': id},
                  );
                },
              );
            }

            return const SizedBox.shrink();
          }),
          Obx(() {
            if (controller.isLoading.value) {
              return const SizedBox.shrink();
            }

            if (controller.canDeleteItems) {
              return IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  controller.showDeleteConfirmationDialog(context, id);
                },
              );
            }

            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final item = controller.selectedItem.value;
        if (item == null) {
          return Center(child: Text('item_not_found'.tr));
        }

        return SingleChildScrollView(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  item.active == 'active'
                                      ? AppColors.success.withOpacity(0.1)
                                      : AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    item.active == 'active'
                                        ? AppColors.success
                                        : AppColors.error,
                              ),
                            ),
                            child: Text(
                              item.active.tr,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    item.active == 'active'
                                        ? AppColors.success
                                        : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow('code'.tr, item.code),
                      if (item.description != null)
                        _buildDetailRow('description'.tr, item.description!),
                      _buildDetailRow('unit'.tr, item.unit),

                      _buildDetailRow(
                        'created_at'.tr,
                        _formatDate(item.createdAt),
                      ),
                      _buildDetailRow(
                        'updated_at'.tr,
                        _formatDate(item.updatedAt),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Create item view
class CreateItemView extends GetView<ItemController> {
  /// Creates a new [CreateItemView]
  const CreateItemView({super.key});

  @override
  Widget build(BuildContext context) {
    // Reset form
    controller.resetForm();

    return Scaffold(
      appBar: AppBar(title: Text('create_item'.tr)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: controller.nameController,
                decoration: InputDecoration(
                  labelText: 'name'.tr,
                  hintText: 'enter_item_name'.tr,
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
                controller: controller.codeController,
                decoration: InputDecoration(
                  labelText: 'code'.tr,
                  hintText: 'enter_item_code'.tr,
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
                controller: controller.descriptionController,
                decoration: InputDecoration(
                  labelText: 'description'.tr,
                  hintText: 'enter_item_description'.tr,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropMenuJob(
                items: ['piece', 'kg', 'liter', 'meter', 'box'],
                messageError: '',
                onSaved: (s) {
                  controller.unitController.value = s ?? '';
                },
                value:
                    controller.unitController.value.isEmpty
                        ? null
                        : controller.unitController.value,
                validator: (value) {
                  return;
                },
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Obx(
                    () => Checkbox(
                      value: controller.active.value,
                      onChanged: (value) {
                        controller.active.value = value ?? true;
                      },
                    ),
                  ),
                  Text('active'.tr),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Obx(
                  () => ElevatedButton(
                    onPressed:
                        controller.isLoading.value
                            ? null
                            : controller.createItem,
                    child:
                        controller.isLoading.value
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Text(
                              controller.canCreateItems
                                  ? 'create_item'.tr
                                  : 'request_item_creation'.tr,
                            ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Edit item view
class EditItemView extends GetView<ItemController> {
  /// Creates a new [EditItemView]
  const EditItemView({super.key});

  @override
  Widget build(BuildContext context) {
    final id = Get.parameters['id'];

    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: Text('edit_item'.tr)),
        body: Center(child: Text('item_not_found'.tr)),
      );
    }

    // Fetch item details if not already loaded
    if (controller.selectedItem.value?.id != id) {
      controller.getItemById(id);
    }

    return Scaffold(
      appBar: AppBar(title: Text('edit_item'.tr)),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final item = controller.selectedItem.value;
        if (item == null) {
          return Center(child: Text('item_not_found'.tr));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: controller.nameController,
                  decoration: InputDecoration(
                    labelText: 'name'.tr,
                    hintText: 'enter_item_name'.tr,
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
                  controller: controller.codeController,
                  decoration: InputDecoration(
                    labelText: 'code'.tr,
                    hintText: 'enter_item_code'.tr,
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
                  controller: controller.descriptionController,
                  decoration: InputDecoration(
                    labelText: 'description'.tr,
                    hintText: 'enter_item_description'.tr,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropMenuJob(
                  items: ['piece', 'kg', 'liter', 'meter', 'box'],
                  messageError: '',
                  onSaved: (s) {
                    controller.unitController.value = s ?? '';
                  },
                  value:
                      controller.unitController.value.isEmpty
                          ? null
                          : controller.unitController.value,
                  validator: (value) {
                    return;
                  },
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Obx(
                      () => Checkbox(
                        value: controller.active.value,
                        onChanged: (value) {
                          controller.active.value = value ?? true;
                        },
                      ),
                    ),
                    Text('active'.tr),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Obx(
                    () => ElevatedButton(
                      onPressed:
                          controller.isLoading.value
                              ? null
                              : () => controller.updateItem(id),
                      child:
                          controller.isLoading.value
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                controller.canEditItems
                                    ? 'update_item'.tr
                                    : 'request_item_update'.tr,
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
