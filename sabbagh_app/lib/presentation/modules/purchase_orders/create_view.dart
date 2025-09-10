import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/presentation/modules/purchase_orders/controller.dart';
import 'package:sabbagh_app/presentation/widgets/custom_app_bar.dart';
import 'package:sabbagh_app/presentation/widgets/drop_menu.dart';

class CreatePurchaseOrderView extends GetView<PurchaseOrderController> {
  const CreatePurchaseOrderView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize form and load data when view is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeCreateForm();
      // Ensure data is loaded
      if (controller.departments.isEmpty) {
        controller.loadDepartments();
      }
    });
    return Scaffold(
      appBar: CustomAppBar(
        title: 'create_purchase_order'.tr,
        showBackButton: true,
      ),
      body: Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'basic_information'.tr,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Department dropdown
                      Obx(() {
                        if (controller.isDepartmentsLoading.value) {
                          return Container(
                            height: 56,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Row(
                                children: [
                                  SizedBox(width: 12),
                                  Icon(Icons.business, color: Colors.grey),
                                  SizedBox(width: 12),
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'loading_departments'.tr,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return DropdownButtonFormField<String>(
                          value:
                              controller.formData['department']?.isEmpty == true
                                  ? null
                                  : controller.formData['department'],
                          decoration: InputDecoration(
                            labelText: 'department'.tr,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.business),
                            suffixIcon:
                                controller.departments.isEmpty &&
                                        !controller.isDepartmentsLoading.value
                                    ? IconButton(
                                      icon: const Icon(Icons.refresh),
                                      onPressed:
                                          () => controller.loadDepartments(),
                                      tooltip: 'reload_departments'.tr,
                                    )
                                    : null,
                            hintText:
                                controller.departments.isEmpty
                                    ? 'no_departments_available'.tr
                                    : 'select_department'.tr,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'department_required'.tr;
                            }
                            return null;
                          },
                          items:
                              controller.departments.isEmpty
                                  ? [
                                    DropdownMenuItem<String>(
                                      value: null,
                                      enabled: false,
                                      child: Text(
                                        'no_departments_available'.tr,
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ]
                                  : controller.departments
                                      .map(
                                        (dept) => DropdownMenuItem<String>(
                                          value: dept.id,
                                          child: Text(dept.name),
                                        ),
                                      )
                                      .toList(),
                          onChanged:
                              controller.departments.isEmpty
                                  ? null
                                  : (value) {
                                    controller.formData['department'] = value;
                                    controller.formData.refresh();
                                  },
                        );
                      }),

                      const SizedBox(height: 16),

                      // Request type dropdown
                      DropdownButtonFormField<String>(
                        value: controller.formData['request_type'],
                        decoration: InputDecoration(
                          labelText: 'request_type'.tr,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.category),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'request_type_required'.tr;
                          }
                          return null;
                        },
                        items: [
                          DropdownMenuItem(
                            value: 'purchase',
                            child: Text('purchase'.tr),
                          ),
                          DropdownMenuItem(
                            value: 'maintenance',
                            child: Text('maintenance'.tr),
                          ),
                        ],
                        onChanged: (value) {
                          controller.formData['request_type'] = value;
                          controller.formData.refresh();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Items Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'items_list'.tr,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton.icon(
                            onPressed: controller.addFormItem,
                            icon: const Icon(Icons.add),
                            label: Text('add_item'.tr),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Items List
                      Obx(() {
                        if (controller.formItems.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'no_items_added'.tr,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'click_add_item_to_start'.tr,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey[500]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children:
                              controller.formItems.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${'item'.tr} ${index + 1}',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (controller.formItems.length > 1)
                                              IconButton(
                                                onPressed:
                                                    () => controller
                                                        .removeFormItem(index),
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                tooltip: 'remove_item'.tr,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        if (controller
                                                .userController
                                                .isManager ||
                                            controller
                                                .userController
                                                .isAssistantManager)
                                          Obx(
                                            () => DropMenuJob(
                                              textEditingController:
                                                  controller.searchItems[index],
                                              suffixIcon:
                                                  controller.items.isEmpty
                                                      ? IconButton(
                                                        icon: const Icon(
                                                          Icons.refresh,
                                                        ),
                                                        onPressed:
                                                            () =>
                                                                controller
                                                                    .loadItems(),
                                                        tooltip: 'reload'.tr,
                                                      )
                                                      : null,
                                              hintText: 'item_name'.tr,
                                              // value: ,
                                              value:
                                                  controller
                                                              .formItems[index]['item_name']
                                                              ?.isEmpty ==
                                                          true
                                                      ? ''
                                                      : controller
                                                          .formItems[index]['item_name'],
                                              items:
                                                  controller.items.isEmpty
                                                      ? ['No Data']
                                                      : controller.items,
                                              messageError: '',
                                              onSaved:
                                                  controller.items.isEmpty
                                                      ? null
                                                      : (value) {
                                                        controller
                                                                .formItems[index]['item_name'] =
                                                            value;
                                                        // controller.formItems
                                                        //     .refresh();
                                                        final matches =
                                                            controller
                                                                .purchaseOrderItems
                                                                .where(
                                                                  (item) =>
                                                                      item.name ==
                                                                      value,
                                                                )
                                                                .toList();

                                                        controller
                                                                .formItems[index]['unit'] =
                                                            matches.first.unit;

                                                        controller.formItems
                                                            .refresh();
                                                      },

                                              validator: (value) {
                                                return;
                                              },
                                            ),
                                          ),
                                        // Item Name
                                        if (!controller
                                                .userController
                                                .isManager &&
                                            !controller
                                                .userController
                                                .isAssistantManager)
                                          TextFormField(
                                            initialValue:
                                                item['item_name']?.toString(),
                                            decoration: InputDecoration(
                                              labelText: 'item_name'.tr,
                                              border:
                                                  const OutlineInputBorder(),
                                              prefixIcon: const Icon(
                                                Icons.inventory,
                                              ),
                                              hintText:
                                                  'enter_item_name_optional'.tr,
                                            ),
                                            onChanged: (value) {
                                              if (value.isNotEmpty) {
                                                controller
                                                        .formItems[index]['item_name'] =
                                                    value;
                                                controller.formItems.refresh();
                                              }
                                            },
                                          ),

                                        const SizedBox(height: 16),

                                        Row(
                                          children: [
                                            // Quantity
                                            Expanded(
                                              flex: 2,
                                              child: TextFormField(
                                                initialValue:
                                                    item['quantity']
                                                        ?.toString() ??
                                                    '1',
                                                decoration: InputDecoration(
                                                  labelText: 'quantity'.tr,
                                                  border:
                                                      const OutlineInputBorder(),
                                                  prefixIcon: const Icon(
                                                    Icons.numbers,
                                                  ),
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'quantity'.tr +
                                                        ' ' +
                                                        'required_field'.tr
                                                            .toLowerCase();
                                                  }
                                                  final quantity =
                                                      double.tryParse(value);
                                                  if (quantity == null ||
                                                      quantity <= 0) {
                                                    return 'invalid_quantity'
                                                        .tr;
                                                  }
                                                  return null;
                                                },
                                                onChanged: (value) {
                                                  final quantity =
                                                      double.tryParse(value);
                                                  controller
                                                          .formItems[index]['quantity'] =
                                                      quantity ?? 1.0;
                                                  controller.formItems
                                                      .refresh();
                                                },
                                              ),
                                            ),

                                            const SizedBox(width: 16),
                                            if (controller
                                                    .userController
                                                    .isManager ||
                                                controller
                                                    .userController
                                                    .isAssistantManager)
                                              // Unit
                                              Obx(() {
                                                return Expanded(
                                                  flex: 2,
                                                  child: DropdownButtonFormField<
                                                    String
                                                  >(
                                                    value:
                                                        controller
                                                            .formItems[index]['unit'] ??
                                                        '',
                                                    decoration: InputDecoration(
                                                      labelText: 'unit'.tr,
                                                      enabled: false,
                                                      border:
                                                          const OutlineInputBorder(),
                                                      prefixIcon: const Icon(
                                                        Icons.straighten,
                                                      ),
                                                    ),

                                                    items: [
                                                      DropdownMenuItem(
                                                        value: 'piece',
                                                        child: Text('piece'.tr),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 'kg',
                                                        child: Text('kg'.tr),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 'liter',
                                                        child: Text('liter'.tr),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 'meter',
                                                        child: Text('meter'.tr),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 'box',
                                                        child: Text('box'.tr),
                                                      ),
                                                    ],
                                                    onChanged: (value) {},
                                                  ),
                                                );
                                              }),

                                            if (!controller
                                                    .userController
                                                    .isManager &&
                                                !controller
                                                    .userController
                                                    .isAssistantManager)
                                              Expanded(
                                                flex: 2,
                                                child: DropdownButtonFormField<
                                                  String
                                                >(
                                                  value:
                                                      item['unit']
                                                          ?.toString() ??
                                                      'piece',
                                                  decoration: InputDecoration(
                                                    labelText: 'unit'.tr,
                                                    border:
                                                        const OutlineInputBorder(),
                                                    prefixIcon: const Icon(
                                                      Icons.straighten,
                                                    ),
                                                  ),
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'unit_required'.tr;
                                                    }
                                                    return null;
                                                  },
                                                  items: [
                                                    DropdownMenuItem(
                                                      value: 'piece',
                                                      child: Text('piece'.tr),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 'kg',
                                                      child: Text('kg'.tr),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 'liter',
                                                      child: Text('liter'.tr),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 'meter',
                                                      child: Text('meter'.tr),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 'box',
                                                      child: Text('box'.tr),
                                                    ),
                                                  ],
                                                  onChanged: (value) {
                                                    controller
                                                            .formItems[index]['unit'] =
                                                        value;
                                                    controller.formItems
                                                        .refresh();
                                                  },
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Attachments (Images)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'attachments'.tr,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          OutlinedButton.icon(
                            onPressed: controller.pickImages,
                            icon: const Icon(Icons.add_a_photo),
                            label: Text('add_images'.tr),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Obx(() {
                        final images = controller.pickedImages;
                        if (images.isEmpty) {
                          return Text(
                            'no_attachments'.tr,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          );
                        }
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            final file = images[index];
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(file, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    radius: 14,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      iconSize: 16,
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                      ),
                                      onPressed:
                                          () => controller.removePickedImage(
                                            index,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Additional Notes (Optional)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'additional_notes'.tr,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        initialValue: controller.formData['notes']?.toString(),
                        decoration: InputDecoration(
                          labelText: 'notes'.tr,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.note_alt),
                          hintText: 'enter_additional_notes'.tr,
                        ),
                        maxLines: 3,
                        onChanged: (value) {
                          controller.formData['notes'] =
                              value.isEmpty ? null : value;
                          controller.formData.refresh();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: Text('cancel'.tr),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(
                      () => ElevatedButton(
                        onPressed:
                            controller.isSubmitting.value
                                ? null
                                : () => controller.createPurchaseOrder(),
                        child:
                            controller.isSubmitting.value
                                ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('submitting'.tr),
                                  ],
                                )
                                : Text('submit_order'.tr),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
