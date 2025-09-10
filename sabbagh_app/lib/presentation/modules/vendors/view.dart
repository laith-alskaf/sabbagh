import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_colors.dart';
import 'package:sabbagh_app/core/constants/app_routes.dart';
import 'package:sabbagh_app/domain/entities/vendor.dart';
import 'package:sabbagh_app/presentation/modules/vendors/controller.dart';
import 'package:sabbagh_app/presentation/widgets/app_drawer.dart';
import 'package:sabbagh_app/presentation/widgets/custom_app_bar.dart';

/// Vendors view
class VendorsView extends GetView<VendorController> {
  /// Creates a new [VendorsView]
  const VendorsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'vendors'.tr,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.white),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort, color: AppColors.white),
            onPressed: () {
              _showSortDialog(context);
            },
          ),
           IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: controller.refreshVendors,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'search'.tr,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: controller.searchVendors,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshVendors,
              child: Obx(() {
                if (controller.isLoading.value && controller.vendors.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.vendors.isEmpty) {
                  return Center(child: Text('no_data'.tr));
                }

                return ListView.builder(
                  itemCount: controller.vendors.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final vendor = controller.vendors[index];
                    return _buildVendorCard(vendor);
                  },
                );
              }),
            ),
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        if (controller.canCreateVendors ||
            controller.canRequestVendorCreation) {
          return FloatingActionButton(
            onPressed: () {
              Get.toNamed(AppRoutes.createVendor);
            },
            backgroundColor: AppColors.primaryGreen,
            child: const Icon(Icons.add),
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }

  Widget _buildVendorCard(Vendor vendor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Get.toNamed(
            '${AppRoutes.vendorDetails.replaceAll(':id', '')}${vendor.id}',
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    vendor.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(vendor.active),
                ],
              ),
              const SizedBox(height: 8),
              if (vendor.contactPerson != null)
                Text('${'contact_person'.tr}: ${vendor.contactPerson}'),
              if (vendor.phone != null) Text('${'phone'.tr}: ${vendor.phone}'),
              if (vendor.email != null) Text('${'email'.tr}: ${vendor.email}'),
              if (vendor.address != null)
                Text('${'address'.tr}: ${vendor.address}'),
              const SizedBox(height: 8),
              if (vendor.rating != null)
                Row(
                  children: [
                    Text('${'rating'.tr}: '),
                    _buildRatingStars(vendor.rating!),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            active
                ? Colors.green.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? Colors.green : Colors.grey),
      ),
      child: Text(
        active ? 'active'.tr : 'archived'.tr,
        style: TextStyle(
          color: active ? Colors.green : Colors.grey,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: index < rating ? Colors.amber : Colors.grey,
          size: 16,
        );
      }),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('filter'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('all'.tr),
                onTap: () {
                  Navigator.pop(context);
                  controller.filterVendorsByActive(null);
                },
                trailing: Obx(
                  () =>
                      controller.activeFilter.value == null
                          ? const Icon(
                            Icons.check,
                            color: AppColors.primaryGreen,
                          )
                          : const SizedBox.shrink(),
                ),
              ),
              ListTile(
                title: Text('active'.tr),
                onTap: () {
                  Navigator.pop(context);
                  controller.filterVendorsByActive(true);
                },
                trailing: Obx(
                  () =>
                      controller.activeFilter.value == true
                          ? const Icon(
                            Icons.check,
                            color: AppColors.primaryGreen,
                          )
                          : const SizedBox.shrink(),
                ),
              ),
              ListTile(
                title: Text('archived'.tr),
                onTap: () {
                  Navigator.pop(context);
                  controller.filterVendorsByActive(false);
                },
                trailing: Obx(
                  () =>
                      controller.activeFilter.value == false
                          ? const Icon(
                            Icons.check,
                            color: AppColors.primaryGreen,
                          )
                          : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('cancel'.tr),
            ),
          ],
        );
      },
    );
  }

  void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('sort'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('name'.tr),
                onTap: () {
                  Navigator.pop(context);
                  controller.sortVendors('name', 'asc');
                },
                trailing: Obx(
                  () =>
                      controller.sortBy.value == 'name'
                          ? const Icon(
                            Icons.check,
                            color: AppColors.primaryGreen,
                          )
                          : const SizedBox.shrink(),
                ),
              ),
              ListTile(
                title: Text('rating'.tr),
                onTap: () {
                  Navigator.pop(context);
                  controller.sortVendors('rating', 'desc');
                },
                trailing: Obx(
                  () =>
                      controller.sortBy.value == 'rating'
                          ? const Icon(
                            Icons.check,
                            color: AppColors.primaryGreen,
                          )
                          : const SizedBox.shrink(),
                ),
              ),
              ListTile(
                title: Text('created_at'.tr),
                onTap: () {
                  Navigator.pop(context);
                  controller.sortVendors('created_at', 'desc');
                },
                trailing: Obx(
                  () =>
                      controller.sortBy.value == 'created_at'
                          ? const Icon(
                            Icons.check,
                            color: AppColors.primaryGreen,
                          )
                          : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('cancel'.tr),
            ),
          ],
        );
      },
    );
  }
}

/// Vendor details view
class VendorDetailsView extends GetView<VendorController> {
  /// Creates a new [VendorDetailsView]
  const VendorDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final id = Get.parameters['id'];

    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: Text('vendor_details'.tr)),
        body: Center(child: Text('invalid_vendor_id'.tr)),
      );
    }

    // Ensure controller is initialized
    if (!Get.isRegistered<VendorController>()) {
      return Scaffold(
        appBar: AppBar(title: Text('vendor_details'.tr)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Load vendor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.selectedVendor.value?.id != id) {
        controller.getVendorById(id);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('vendor_details'.tr),
        actions: [
          Obx(() {
            try {
              if (controller.canEditVendors ||
                  controller.canRequestVendorEdit) {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    try {
                      final editRoute = AppRoutes.editVendor.replaceAll(
                        ':id',
                        id,
                      );
                      Get.toNamed(editRoute);
                    } catch (e) {
                      Get.snackbar(
                        'error'.tr,
                        'navigation_error'.tr,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
                );
              }
            } catch (e) {
              rethrow;
            }
            return const SizedBox.shrink();
          }),
          Obx(() {
            if (controller.canDeleteVendors) {
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
    
        if (controller.selectedVendor.value == null) {
          return Center(child: Text('vendor_not_found'.tr));
        }
    
        final vendor = controller.selectedVendor.value!;
    
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
                          Text(
                            vendor.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _buildStatusChip(vendor.active),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (vendor.contactPerson != null)
                        _buildInfoRow(
                          'contact_person'.tr,
                          vendor.contactPerson!,
                        ),
                      if (vendor.phone != null)
                        _buildInfoRow('phone'.tr, vendor.phone!),
                      if (vendor.email != null)
                        _buildInfoRow('email'.tr, vendor.email!),
                      if (vendor.address != null)
                        _buildInfoRow('address'.tr, vendor.address!),
                      if (vendor.rating != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '${'rating'.tr}:',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildRatingStars(vendor.rating!),
                          ],
                        ),
                      ],
                      if (vendor.notes != null &&
                          vendor.notes!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'notes'.tr,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(vendor.notes!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'purchase_orders'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // TODO: Implement purchase orders list
                      Text('purchase_orders_placeholder'.tr),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            active
                ? Colors.green.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? Colors.green : Colors.grey),
      ),
      child: Text(
        active ? 'active'.tr : 'archived'.tr,
        style: TextStyle(
          color: active ? Colors.green : Colors.grey,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: index < rating ? Colors.amber : Colors.grey,
          size: 16,
        );
      }),
    );
  }
}

/// Create vendor view
class CreateVendorView extends GetView<VendorController> {
  /// Creates a new [CreateVendorView]
  const CreateVendorView({super.key});

  @override
  Widget build(BuildContext context) {

    // Reset form
    controller.resetForm();

    return Scaffold(
      appBar: AppBar(title: Text('create_vendor'.tr)),
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
                  labelText: '${'name'.tr} *',
                  border: const OutlineInputBorder(),
                  helperText: 'vendor_name_help'.tr,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'vendor_name_required'.tr;
                  }
                  if (value.trim().length < 2) {
                    return 'vendor_name_min_length'.tr;
                  }
                  if (value.trim().length > 100) {
                    return 'vendor_name_max_length'.tr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.contactPersonController,
                decoration: InputDecoration(
                  labelText: '${'contact_person'.tr} *',
                  border: const OutlineInputBorder(),
                  helperText: 'contact_person_help'.tr,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'contact_person_required'.tr;
                  }
                  if (value.trim().length < 2) {
                    return 'contact_person_min_length'.tr;
                  }
                  if (value.trim().length > 100) {
                    return 'contact_person_max_length'.tr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.phoneController,
                decoration: InputDecoration(
                  labelText: '${'phone'.tr} *',
                  border: const OutlineInputBorder(),
                  helperText: 'phone_help'.tr,
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'phone_required'.tr;
                  }
                  if (value.trim().length < 8) {
                    return 'phone_min_length'.tr;
                  }
                  if (value.trim().length > 20) {
                    return 'phone_max_length'.tr;
                  }
                  if (!RegExp(r'^[\d\s\-\+\(\)]+$').hasMatch(value.trim())) {
                    return 'phone_invalid_format'.tr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.emailController,
                decoration: InputDecoration(
                  labelText: 'email'.tr,
                  border: const OutlineInputBorder(),
                  helperText: 'email_optional'.tr,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!GetUtils.isEmail(value.trim())) {
                      return 'invalid_email'.tr;
                    }
                    if (value.trim().length > 100) {
                      return 'email_max_length'.tr;
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.addressController,
                decoration: InputDecoration(
                  labelText: '${'address'.tr} *',
                  border: const OutlineInputBorder(),
                  helperText: 'address_help'.tr,
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'address_required'.tr;
                  }
                  if (value.trim().length < 5) {
                    return 'address_min_length'.tr;
                  }
                  if (value.trim().length > 500) {
                    return 'address_max_length'.tr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'rating'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Row(
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < controller.rating.value
                            ? Icons.star
                            : Icons.star_border,
                        color:
                            index < controller.rating.value
                                ? Colors.amber
                                : Colors.grey,
                      ),
                      onPressed: () {
                        controller.rating.value = index + 1;
                      },
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Obx(
                    () => Checkbox(
                      value: controller.active.value,
                      onChanged: (value) => controller.active.value = value!,
                      activeColor: AppColors.primaryGreen,
                    ),
                  ),
                  Text('active'.tr),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.notesController,
                decoration: InputDecoration(
                  labelText: 'notes'.tr,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('cancel'.tr),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(
                      () => ElevatedButton(
                        onPressed:
                            controller.isLoading.value
                                ? null
                                : controller.createVendor,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
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
                                : Text(
                                  controller.canCreateVendors
                                      ? 'create'.tr
                                      : 'request_creation'.tr,
                                ),
                      ),
                    ),
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

/// Edit vendor view
class EditVendorView extends GetView<VendorController> {
  /// Creates a new [EditVendorView]
  const EditVendorView({super.key});

  @override
  Widget build(BuildContext context) {
    final id = Get.parameters['id'];

    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: Text('edit_vendor'.tr)),
        body: Center(child: Text('invalid_vendor_id'.tr)),
      );
    }

    // Ensure controller is initialized
    if (!Get.isRegistered<VendorController>()) {
      return Scaffold(
        appBar: AppBar(title: Text('edit_vendor'.tr)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Load vendor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.selectedVendor.value?.id != id) {
        controller.getVendorById(id);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text('edit_vendor'.tr)),
      
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.selectedVendor.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
    
        if (controller.selectedVendor.value == null) {
          return Center(child: Text('vendor_not_found'.tr));
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
                    labelText: '${'name'.tr} *',
                    border: const OutlineInputBorder(),
                    helperText: 'vendor_name_help'.tr,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'vendor_name_required'.tr;
                    }
                    if (value.trim().length < 2) {
                      return 'vendor_name_min_length'.tr;
                    }
                    if (value.trim().length > 100) {
                      return 'vendor_name_max_length'.tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.contactPersonController,
                  decoration: InputDecoration(
                    labelText: '${'contact_person'.tr} *',
                    border: const OutlineInputBorder(),
                    helperText: 'contact_person_help'.tr,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'contact_person_required'.tr;
                    }
                    if (value.trim().length < 2) {
                      return 'contact_person_min_length'.tr;
                    }
                    if (value.trim().length > 100) {
                      return 'contact_person_max_length'.tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.phoneController,
                  decoration: InputDecoration(
                    labelText: '${'phone'.tr} *',
                    border: const OutlineInputBorder(),
                    helperText: 'phone_help'.tr,
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'phone_required'.tr;
                    }
                    if (value.trim().length < 8) {
                      return 'phone_min_length'.tr;
                    }
                    if (value.trim().length > 20) {
                      return 'phone_max_length'.tr;
                    }
                    if (!RegExp(
                      r'^[\d\s\-\+\(\)]+$',
                    ).hasMatch(value.trim())) {
                      return 'phone_invalid_format'.tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.emailController,
                  decoration: InputDecoration(
                    labelText: 'email'.tr,
                    border: const OutlineInputBorder(),
                    helperText: 'email_optional'.tr,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (!GetUtils.isEmail(value.trim())) {
                        return 'invalid_email'.tr;
                      }
                      if (value.trim().length > 100) {
                        return 'email_max_length'.tr;
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.addressController,
                  decoration: InputDecoration(
                    labelText: '${'address'.tr} *',
                    border: const OutlineInputBorder(),
                    helperText: 'address_help'.tr,
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'address_required'.tr;
                    }
                    if (value.trim().length < 5) {
                      return 'address_min_length'.tr;
                    }
                    if (value.trim().length > 500) {
                      return 'address_max_length'.tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'rating'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => Row(
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < controller.rating.value
                              ? Icons.star
                              : Icons.star_border,
                          color:
                              index < controller.rating.value
                                  ? Colors.amber
                                  : Colors.grey,
                        ),
                        onPressed: () {
                          controller.rating.value = index + 1;
                        },
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Obx(
                      () => Checkbox(
                        value: controller.active.value,
                        onChanged:
                            (value) => controller.active.value = value!,
                        activeColor: AppColors.primaryGreen,
                      ),
                    ),
                    Text('active'.tr),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.notesController,
                  decoration: InputDecoration(
                    labelText: 'notes'.tr,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('cancel'.tr),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Obx(
                        () => ElevatedButton(
                          onPressed:
                              controller.isLoading.value
                                  ? null
                                  : () => controller.updateVendor(id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child:
                              controller.isLoading.value
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
                                  : Text(
                                    controller.canEditVendors
                                        ? 'save'.tr
                                        : 'request_update'.tr,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
