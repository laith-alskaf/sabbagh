import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_colors.dart';
import 'package:sabbagh_app/domain/entities/purchase_order.dart';
import 'package:sabbagh_app/presentation/modules/purchase_orders/controller.dart';
import 'package:sabbagh_app/presentation/widgets/custom_app_bar.dart';
import 'package:sabbagh_app/presentation/widgets/drop_menu.dart';

/// Edit purchase order view
class EditPurchaseOrderView extends GetView<PurchaseOrderController> {
  /// Creates a new [EditPurchaseOrderView]
  const EditPurchaseOrderView({super.key});

  @override
  Widget build(BuildContext context) {
    final orderId = Get.parameters['id'] ?? '';

    // Load purchase order details when view is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (orderId.isNotEmpty) {
        controller.getPurchaseOrderById(orderId);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: 'edit_purchase_order'.tr,showBackButton: true,),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final order = controller.selectedPurchaseOrder.value;
        if (order == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'purchase_order_not_found'.tr,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Check if user can edit this order
        if (!controller.canEditPurchaseOrder(order)) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'cannot_edit_purchase_order'.tr,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'only_draft_orders_can_be_edited'.tr,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        // Initialize form with existing data
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeFormWithOrder(order);
        });
    double scale = MediaQuery.of(Get.context!).size.width > 600 ? 1.5 : 1.0;
        return Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderInfoCard(order),
                const SizedBox(height: 16),
                _buildBasicInfoCard(),
                const SizedBox(height: 16),
                _buildVendorCard(),
                const SizedBox(height: 16),
                _buildItemsCard(),
                const SizedBox(height: 16),
                _buildNotesCard(),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(scale*16),
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
                        const SizedBox(height:scale* 12),
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
                                  crossAxisCount:scale* 3,
                                  crossAxisSpacing:scale* 8,
                                  mainAxisSpacing: scale*8,
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
                                    top:scale* 4,
                                    right:scale* 4,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black54,
                                      radius: 14,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        iconSize:scale* 16,
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
                        const SizedBox(height: scale*8),
                        Text(
                          'attachments_hint_max_count'.trParams({'count': '5'}),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height:scale* 24),
                _buildUpdateButton(order),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildOrderInfoCard(PurchaseOrder order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'order_information'.tr,
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'order_number'.tr,
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      order.number,
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'created_at'.tr,
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _formatDateTime(order.createdAt),
                        style: Get.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'updated_at'.tr,
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _formatDateTime(order.updatedAt),
                        style: Get.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'basic_information'.tr,
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Department dropdown
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.formData['department'],
                decoration: InputDecoration(
                  labelText: 'department'.tr,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'department_required'.tr;
                  }
                  return null;
                },
                items:
                    controller.departments
                        .map(
                          (dept) => DropdownMenuItem<String>(
                            value: dept.id,
                            child: Text(dept.name),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  controller.formData['department'] = value;
                },
              ),
            ),
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
              items:
                  PurchaseOrderType.values
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type.toApiString(),
                          child: Text((type.toApiString()).tr),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                controller.formData['request_type'] = value;
              },
            ),
            const SizedBox(height: 16),

            // Requester name
            TextFormField(
              initialValue: controller.formData['requester_name'],
              decoration: InputDecoration(
                labelText: 'requester_name'.tr,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'requester_name_required'.tr;
                }
                return null;
              },
              onSaved: (value) {
                controller.formData['requester_name'] = value?.trim();
              },
            ),
            const SizedBox(height: 16),

            // Request date
            // Obx(
            //   () => TextFormField(
            //     controller: controller.requestDate.value,
            //     decoration: InputDecoration(
            //       labelText: 'request_date'.tr,
            //       border: const OutlineInputBorder(),
            //       prefixIcon: const Icon(Icons.calendar_today),
            //       suffixIcon: IconButton(
            //         icon: const Icon(Icons.date_range),
            //         onPressed: () => _selectRequestDate(),
            //       ),
            //     ),
            //     readOnly: true,
            //     validator: (value) {
            //       if (value == null || value.isEmpty) {
            //         return 'request_date_required'.tr;
            //       }
            //       return null;
            //     },
            //   ),
            // ),
            // const SizedBox(height: 16),

            // Execution date (optional)
            Obx(
              () => TextFormField(
                controller: controller.executionDate.value,
                decoration: InputDecoration(
                  labelText: 'execution_date_optional'.tr,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.schedule),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: () => _selectExecutionDate(),
                  ),
                ),
                readOnly: true,
              ),
            ),
            const SizedBox(height: 16),

            // Currency dropdown
            DropdownButtonFormField<String>(
              value: controller.formData['currency'] ?? 'USD',
              decoration: InputDecoration(
                labelText: 'currency'.tr,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.attach_money),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'currency_required'.tr;
                }
                return null;
              },
              items: const [
                DropdownMenuItem(value: 'USD', child: Text('USD')),
                DropdownMenuItem(value: 'SYR', child: Text('SYR')),
              ],
              onChanged: (value) {
                controller.formData['currency'] = value;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'vendor_information'.tr,
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (controller.userController.isAssistantManager ||
                controller.userController.isManager)
              Obx(
                () => DropMenuJob(
                  textEditingController: controller.searchVendor.value,
                  hintText: 'vendor_name_optional'.tr,
                  value:
                      controller.formData['supplier_name']?.isEmpty == true
                          ? ''
                          : controller.formData['supplier_name'],
                  items:
                      controller.suppliers.map((sup) {
                        return sup.name;
                      }).toList(),
                  messageError: '',
                  onSaved: (value) {
                    if (value != null) {
                      int index = controller.suppliers.indexWhere((supl) {
                        return value == supl.name;
                      });
                      controller.formData['supplier_name'] = value;
                      controller.formData['supplier_id'] =
                          controller.suppliers[index].id;
                    }
                  },
                  suffixIcon:
                      controller.suppliers.isEmpty
                          ? IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () => controller.loadSuppliers(),
                            tooltip: 'reload'.tr,
                          )
                          : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'items'.tr,
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: Text('add_item'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Obx(() {
              if (controller.formItems.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.inventory, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'no_items_added'.tr,
                        style: Get.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'click_add_item_to_start'.tr,
                        style: Get.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.formItems.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  return _buildItemRow(index);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(int index) {
    final item = controller.formItems[index];
    print(controller.searchItems.length);
    print(controller.formItems.length);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'item'.tr} ${index + 1}',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: () => _removeItem(index),
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TextFormField(
            initialValue: item['item_name'],
            decoration: InputDecoration(
              labelText: 'item_name'.tr,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'item_name_required'.tr;
              }
              return null;
            },
            onChanged: (value) {
              controller.formItems[index]['item_name'] = value.trim();
            },
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // Quantity
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: item['quantity']?.toString(),
                  decoration: InputDecoration(
                    labelText: 'quantity'.tr,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'quantity_required'.tr;
                    }
                    final quantity = double.tryParse(value);
                    if (quantity == null || quantity <= 0) {
                      return 'invalid_quantity'.tr;
                    }
                    return null;
                  },
                  onChanged: (value) {
                    final quantity = double.tryParse(value);
                    controller.formItems[index]['quantity'] = quantity ?? 0.0;
                    _calculateLineTotal(index);
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Unit
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: item['unit'] ?? 'piece',
                  decoration: InputDecoration(
                    labelText: 'unit'.tr,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'unit_required'.tr;
                    }
                    return null;
                  },
                  onChanged: (value) {
                    controller.formItems[index]['unit'] = value.trim();
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Price (optional)
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: item['price']?.toString(),
                  decoration: InputDecoration(
                    labelText: 'price_optional'.tr,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final price = double.tryParse(value);
                    controller.formItems[index]['price'] = price;
                    _calculateLineTotal(index);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: item['currency'],
            decoration: InputDecoration(
              labelText: 'currency'.tr,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.attach_money),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'currency_required'.tr;
              }
              return null;
            },
            items: const [
              DropdownMenuItem(value: 'USD', child: Text('USD')),
              DropdownMenuItem(value: 'SYP', child: Text('SYP')),
            ],
            onChanged: (value) {
              controller.formItems[index]['currency'] = value!.trim();
            },
          ),
          const SizedBox(height: 12),
          // Line total display
          if (item['line_total'] != null && item['line_total'] > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${'line_total'.tr}: ${item['line_total'].toStringAsFixed(2)} ${item['currency'] ?? 'USD'}',
                    style: Get.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'additional_information'.tr,
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              initialValue: controller.formData['notes'],
              decoration: InputDecoration(
                labelText: 'notes_optional'.tr,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.note),
                hintText: 'enter_any_additional_notes'.tr,
              ),
              maxLines: 4,
              onSaved: (value) {
                controller.formData['notes'] = value?.trim();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateButton(PurchaseOrder order) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed:
              controller.isSubmitting.value ? null : () => _updateOrder(order),
          icon:
              controller.isSubmitting.value
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.save),
          label: Text(
            controller.isSubmitting.value
                ? 'updating'.tr
                : 'update_purchase_order'.tr,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(PurchaseOrderStatus status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case PurchaseOrderStatus.draft:
        backgroundColor = Colors.grey[300]!;
        textColor = Colors.grey[800]!;
        break;
      case PurchaseOrderStatus.underAssistantReview:
      case PurchaseOrderStatus.pendingProcurement:
      case PurchaseOrderStatus.underFinanceReview:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case PurchaseOrderStatus.underManagerReview:
      case PurchaseOrderStatus.underGeneralManagerReview:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case PurchaseOrderStatus.rejectedByAssistant:
      case PurchaseOrderStatus.rejectedByManager:
      case PurchaseOrderStatus.rejectedByFinance:
      case PurchaseOrderStatus.rejectedByGeneralManager:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      case PurchaseOrderStatus.inProgress:
      case PurchaseOrderStatus.returnedToManagerReview:
        backgroundColor = Colors.yellow[100]!;
        textColor = Colors.yellow[800]!;
        break;
      case PurchaseOrderStatus.completed:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toApiString().tr,
        style: Get.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _initializeFormWithOrder(PurchaseOrder order) {
    controller.executionDate.value.clear();
    controller.requestDate.value.clear();
    controller.searchVendor.value.clear();
    // Only initialize once
    if (controller.formData.isNotEmpty) return;

    controller.formData.value = {
      'department': order.department,
      'request_type': order.type.toApiString(),
      'requester_name': order.requesterName,
      'request_date': _formatDateForInput(order.requestDate),
      'execution_date':
          order.executionDate != null
              ? _formatDateForInput(order.executionDate!)
              : null,
      'currency': order.currency ?? 'USD',
      'supplier_name': order.vendorName,
      'notes': order.notes,
    };
    controller.executionDate.value.text = controller.formData['execution_date'];
    controller.requestDate.value.text = _formatDateForInput(order.requestDate);
    controller.searchVendor.value.text = order.vendorName ?? '';

    controller.formItems.value =
        order.items
            .map(
              (item) => {
                'item_name': item.itemName,
                'item_code': item.itemCode,
                'quantity': item.quantity,
                'unit': item.unit,
                'price': item.price,
                'line_total': item.lineTotal,
                'currency': item.currency,
              },
            )
            .toList();
  }

  // void _selectRequestDate() async {
  //   final currentDate =
  //       controller.formData['request_date'] != null
  //           ? DateTime.tryParse(controller.formData['request_date'])
  //           : DateTime.now();

  //   final date = await showDatePicker(
  //     context: Get.context!,
  //     initialDate: currentDate ?? DateTime.now(),
  //     firstDate: DateTime.now().subtract(const Duration(days: 30)),
  //     lastDate: DateTime.now().add(const Duration(days: 365)),
  //   );

  //   if (date != null) {
  //     controller.formData['request_date'] = _formatDateForInput(date);
  //     controller.requestDate.value.text = controller.formData['request_date'];
  //   }
  // }

  void _selectExecutionDate() async {
    final currentDate =
        controller.formData['execution_date'] != null
            ? DateTime.tryParse(controller.formData['execution_date'])
            : DateTime.now().add(const Duration(days: 1));

    final date = await showDatePicker(
      context: Get.context!,
      initialDate: currentDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      controller.formData['execution_date'] = _formatDateForInput(date);
      controller.executionDate.value.text =
          controller.formData['execution_date'];
    }
  }

  void _addItem() {
    controller.formItems.add({
      'item_name': '',
      'item_code': '',
      'quantity': 1.0,
      'unit': 'piece',
      'price': null,
      'line_total': null,
      'currency': controller.formData['currency'] ?? 'USD',
    });
  }

  void _removeItem(int index) {
    if (controller.formItems.length > 1) {
      controller.formItems.removeAt(index);
    } else {
      Get.snackbar(
        'error'.tr,
        'at_least_one_item_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  void _calculateLineTotal(int index) {
    final item = controller.formItems[index];
    final quantity = item['quantity'] as double?;
    final price = item['price'] as double?;

    if (quantity != null && price != null && quantity > 0 && price > 0) {
      controller.formItems[index]['line_total'] = quantity * price;
    } else {
      controller.formItems[index]['line_total'] = null;
    }

    // Trigger UI update
    controller.formItems.refresh();
  }

  void _updateOrder(PurchaseOrder order) {
    if (!controller.formKey.currentState!.validate()) {
      return;
    }

    controller.formKey.currentState!.save();

    if (controller.formItems.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'at_least_one_item_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    final data = Map<String, dynamic>.from(controller.formData);
    data['items'] = controller.formItems.toList();

    // Calculate total amount
    double totalAmount = 0.0;
    for (var item in controller.formItems) {
      if (item['line_total'] != null) {
        totalAmount += item['line_total'] as double;
      }
    }
    if (totalAmount > 0) {
      data['total_amount'] = totalAmount;
    }

    controller.updatePurchaseOrder(order.id, data);
  }

  String _formatDateForInput(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
