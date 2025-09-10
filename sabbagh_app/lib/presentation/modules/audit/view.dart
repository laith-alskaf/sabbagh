import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_colors.dart';
import 'package:sabbagh_app/core/constants/app_routes.dart';
import 'package:sabbagh_app/presentation/modules/audit/controller.dart';
import 'package:sabbagh_app/presentation/widgets/app_drawer.dart';

class AuditLogsView extends GetView<AuditController> {
  const AuditLogsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('audit_logs'.tr),
        actions: [
          Obx(() {
            final count = _activeFilterCount(controller);
            return Row(
              children: [
                if (count > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Chip(
                      label: Text('$count'),
                      backgroundColor: Colors.orange.shade100,
                    ),
                  ),
                IconButton(
                  tooltip: 'Filter'.tr,
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    Get.bottomSheet(
                      SizedBox(
                        // height:,
                        child: _openFiltersBottomSheet(),
                      ),
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          }),

          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: controller.refreshAuditLogs,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Filters moved to a bottom sheet for cleaner UI
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.errorMessage.value != null) {
                  return Center(child: Text(controller.errorMessage.value!));
                }
                final logs = controller.logs;
                if (logs.isEmpty) {
                  return Center(child: Text('No logs found'.tr));
                }
                return ListView.separated(
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final action = (log['action'] ?? '').toString();
                    final entityType = (log['entity_type'] ?? '').toString();
                    final entityId = (log['entity_id'] ?? '').toString();
                    final actorName =
                        (log['actor_name'] ?? log['actor_id'] ?? '').toString();
                    final createdAt = (log['created_at'] ?? '').toString();
                    final description = (log['description'] ?? '').toString();

                    Color chipColor;
                    switch (action) {
                      case 'create_purchase_order':
                        chipColor = Colors.green.shade100;
                        break;
                      case 'update':
                        chipColor = Colors.blue.shade100;
                        break;
                      case 'delete':
                        chipColor = Colors.red.shade100;
                        break;
                      case 'manager_approve_purchase_order':
                      case 'assistant_approve_purchase_order':
                      case 'finance_approve_purchase_order':
                        chipColor = Colors.teal.shade100;
                        break;
                      case 'reject':
                        chipColor = Colors.orange.shade100;
                        break;
                      case 'submit':
                        chipColor = Colors.purple.shade100;
                        break;
                      default:
                        chipColor = Colors.grey.shade200;
                    }

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.white,
                      child: ListTile(
                        onTap: () {
                          // Navigate to PO details when entity_type is purchase_order
                          final poId =
                              log['details']?['purchase_order']?['id']
                                  ?.toString() ??
                              entityId;
                          if (entityType == 'purchase_order' &&
                              poId.isNotEmpty) {
                            final route = AppRoutes.purchaseOrderDetails
                                .replaceFirst(':id', poId);
                            Get.toNamed(route);
                          }
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: chipColor,
                          child: Text(
                            action.isNotEmpty ? action[0].toUpperCase() : '?',
                          ),
                        ),
                        title: LayoutBuilder(
                          builder: (context, constraints) {
                            return ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: chipColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  action.tr.toUpperCase(),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            if (description.isNotEmpty)
                              Text(
                                description,
                                style: const TextStyle(fontSize: 13),
                              ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _kv('entity_type'.tr, entityType.tr),
                                // _kv('Entity ID'.tr, entityId),
                                _kv('actor'.tr, actorName),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.shade50,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(12),
                                    ),
                                    border: Border.all(
                                      color: Colors.blueGrey.shade100,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.schedule,
                                        size: 14,
                                        color: Colors.black45,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatYMD(createdAt),
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
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
                  },
                );
              }),
            ),
            const SizedBox(height: 8),
            _PaginationBar(controller: controller),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.lightGray,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$k: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(v),
      ],
    ),
  );

  // Format ISO date/time to YYYY-MM-DD; fallback to first 10 chars
  String _formatYMD(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    } catch (_) {
      return iso.length >= 10 ? iso.substring(0, 10) : iso;
    }
  }

  int _activeFilterCount(AuditController c) {
    int count = 0;
    if (c.action.value.isNotEmpty) count++;
    if (c.entityType.value.isNotEmpty) count++;
    if (c.actorId.value.isNotEmpty) count++;
    if (c.startDateIso.value.isNotEmpty) count++;
    if (c.endDateIso.value.isNotEmpty) count++;
    return count;
  }

  Widget _openFiltersBottomSheet() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Filters'.tr,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => _Dropdown(
                    label: 'Action'.tr,
                    value:
                        controller.action.value.isEmpty
                            ? null
                            : controller.action.value,
                    items: const [
                      'manager_approve_purchase_order',
                      'assistant_approve_purchase_order',
                      'finance_approve_purchase_order',
                      'create_purchase_order',
                    ],
                    onChanged: (v) => controller.action.value = v ?? '',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => _Dropdown(
                    label: 'Entity'.tr,
                    value:
                        controller.entityType.value.isEmpty
                            ? null
                            : controller.entityType.value,
                    items: const [
                      'user',
                      'vendor',
                      'item',
                      'purchase_order',
                      'change_request',
                    ],
                    onChanged: (v) => controller.entityType.value = v ?? '',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller:
                controller.entityId.text.isEmpty ? null : controller.entityId,

            decoration: InputDecoration(
              labelText: 'entity_id'.tr,
              border: const OutlineInputBorder(),
            ),

            onChanged: (id) => controller.entityId.text = id,
          ),
          const SizedBox(height: 12),
          Obx(() {
            final userOptions = controller.users;
            final loading = controller.isLoadingUsers.value;
            return _LookupDropdown(
              label: 'Actor'.tr,
              loading: loading,
              valueId:
                  controller.actorId.value.isEmpty
                      ? null
                      : controller.actorId.value,
              items: userOptions,
              onChanged: (id) => controller.actorId.value = id ?? '',
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TextField(
                  label: 'Start Date'.tr,
                  hint: 'YYYY-MM-DD'.tr,
                  onSubmitted: (v) => controller.startDateIso.value = v,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TextField(
                  label: 'End Date'.tr,
                  hint: 'YYYY-MM-DD'.tr,
                  onSubmitted: (v) => controller.endDateIso.value = v,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.clear),
                label: Text('Clear'.tr),
                onPressed: () async {
                  Get.back();
                  controller.action.value = '';
                  controller.entityType.value = '';
                  controller.actorId.value = '';
                  controller.entityId.text = '';
                  controller.startDateIso.value = '';
                  controller.endDateIso.value = '';
                  await controller.fetchLogs(reset: true);
                },
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: Text('Apply'.tr),
                onPressed: () async {
                  Get.back();
                  await controller.fetchLogs(reset: true);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final AuditController controller;
  const _PaginationBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Obx(
          () => TextButton(
            onPressed: controller.offset.value > 0 ? controller.prevPage : null,
            child: Text('Prev'.tr),
          ),
        ),
        const SizedBox(width: 8),
        Obx(
          () => Text(
            '${'page'.tr} ${controller.offset.value == 0 ? 0 : (controller.offset.value / 10).toInt()}',
          ),
        ),
        const SizedBox(width: 8),
        TextButton(onPressed: controller.nextPage, child: Text('next'.tr)),
        const Spacer(),
        DropdownButton<int>(
          value: controller.limit.value,
          items:
              const [10, 20, 50, 100]
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text('$e / ${'page'.tr}'),
                    ),
                  )
                  .toList(),
          onChanged: (v) {
            if (v != null) {
              controller.limit.value = v;
              controller.fetchLogs(reset: true);
            }
          },
        ),
      ],
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            hint: Text('Select'.tr),
            underline: const SizedBox.shrink(),
            items:
                items
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _LookupDropdown extends StatelessWidget {
  // Items format: [{id: string, label: string}]
  final String label;
  final String? valueId;
  final List<Map<String, dynamic>> items;
  final ValueChanged<String?> onChanged;
  final bool loading;
  const _LookupDropdown({
    required this.label,
    required this.valueId,
    required this.items,
    required this.onChanged,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              loading
                  ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                  : DropdownButton<String>(
                    isExpanded: true,
                    value: valueId,
                    hint: Text('Select'.tr),
                    underline: const SizedBox.shrink(),
                    items:
                        items
                            .map(
                              (e) => DropdownMenuItem(
                                value: e['id']?.toString(),
                                child: Text(e['label']?.toString() ?? ''),
                              ),
                            )
                            .toList(),
                    onChanged: onChanged,
                  ),
        ),
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  final String label;
  final String? hint;
  final ValueChanged<String> onSubmitted;
  const _TextField({required this.label, this.hint, required this.onSubmitted});

  Future<void> _pickDate(
    BuildContext context,
    TextEditingController ctl,
  ) async {
    try {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: DateTime(now.year - 5),
        lastDate: DateTime(now.year + 5),
        helpText: 'Select date'.tr,
        cancelText: 'cancel'.tr,
        confirmText: 'ok'.tr,
      );
      if (picked != null) {
        // Format as YYYY-MM-DD
        final v =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        ctl.text = v;
        onSubmitted(v);
      }
    } catch (_) {}
  }

  bool get _isDateField => label.toLowerCase().contains('date');

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: _isDateField, // enable picker for date fields
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
            suffixIcon: _isDateField ? const Icon(Icons.date_range) : null,
          ),
          onTap: _isDateField ? () => _pickDate(context, controller) : null,
          onSubmitted: onSubmitted,
        ),
      ],
    );
  }
}
