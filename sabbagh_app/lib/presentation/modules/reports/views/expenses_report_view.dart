import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_colors.dart';
import 'package:sabbagh_app/presentation/modules/reports/controller.dart';
import 'package:sabbagh_app/presentation/widgets/custom_app_bar.dart';
import 'package:sabbagh_app/presentation/widgets/drop_menu.dart';

/// Expenses report view
class ExpensesReportView extends GetView<ReportController> {
  /// Creates a new [ExpensesReportView]
  const ExpensesReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        showBackButton: true,
        title: 'expenses_report'.tr,
        actions: [
          Obx(() {
            if (controller.canExportReports &&
                controller.reportData.value.isNotEmpty) {
              return IconButton(
                icon: const Icon(Icons.download, color: AppColors.white),
                onPressed: controller.exportReport,
                tooltip: 'export_report'.tr,
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFiltersSection(),
                  const SizedBox(height: 24),
                  Obx(() {
                    if (controller.isLoading.value) {
                      return _buildLoadingState();
                    }

                    if (controller.reportData.value.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildReportContent();
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'filters'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Form(
              key: controller.formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          controller: controller.startDateController,
                          label: 'start_date'.tr,
                          onTap: () => controller.selectStartDate(Get.context!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateField(
                          controller: controller.endDateController,
                          label: 'end_date'.tr,
                          onTap: () => controller.selectEndDate(Get.context!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Obx(
                    () => _buildDropdownField(
                      value:
                          controller.selectedDepartment.value.isEmpty
                              ? null
                              : controller.selectedDepartment.value,
                      label: 'department'.tr,
                      items: ['all_departments', ...controller.departments],
                      onChanged: (value) {
                        controller.selectedDepartment.value = value ?? '';
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Obx(
                    () => _buildDropdownField(
                      value:
                          controller.selectedVendorId.value.isEmpty
                              ? null
                              : controller.selectedVendorId.value,
                      label: 'vendor'.tr,
                      items: [
                        'all_vendors',
                        ...controller.vendors.map(
                          (vendor) => vendor['name'] as String,
                        ),
                      ],
                      onChanged: (value) {
                        controller.selectedVendorId.value = value ?? '';
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: controller.generateReport,
                          icon: const Icon(Icons.search),
                          label: Text('generate_report'.tr),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.lightGray,
      ),
      readOnly: true,
      onTap: onTap,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'required_field'.tr;
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropMenuJob(
      hintText: label,
      items: items,
      messageError: '',
      onSaved: onChanged,
      value: value,
      validator: (value) {
        return;
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.attach_money_outlined,
              size: 64,
              color: AppColors.darkGray,
            ),
            const SizedBox(height: 16),
            Text(
              'no_data_available'.tr,
              style: TextStyle(fontSize: 18, color: AppColors.darkGray),
            ),
            const SizedBox(height: 8),
            Text(
              'use_filters_to_generate_report'.tr,
              style: TextStyle(color: AppColors.darkGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    final data = controller.reportData.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryCards(data),
        const SizedBox(height: 24),
        _buildDataTable(data),
      ],
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> data) {
    final summary = Map<String, dynamic>.from(data['summary'] ?? {});
    final totalExpenses = _toNum(summary['total_expenses']).toDouble();
    final currency = (summary['currency'] ?? 'SAR').toString();
    final expenses = List<dynamic>.from(data['data'] ?? []);
    final totalTransactions = expenses.length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'total_expenses'.tr,
            '${totalExpenses.toStringAsFixed(2)} $currency',
            Icons.attach_money_outlined,
            AppColors.primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'total_transactions'.tr,
            '$totalTransactions',
            Icons.receipt_outlined,
            AppColors.info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'average_expense'.tr,
            '${totalTransactions > 0 ? (totalExpenses / totalTransactions).toStringAsFixed(2) : '0.00'} $currency',
            Icons.trending_up_outlined,
            AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: AppColors.darkGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(Map<String, dynamic> data) {
    final expenses = List<dynamic>.from(data['data'] ?? []);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'expenses_list'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (expenses.isEmpty)
              SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: AppColors.darkGray,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'no_data_available'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.darkGray,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('purchase_order'.tr)),
                    DataColumn(label: Text('department'.tr)),
                    DataColumn(label: Text('vendor'.tr)),
                    DataColumn(label: Text('date'.tr)),
                    DataColumn(label: Text('amount'.tr)),
                  ],
                  rows:
                      expenses.map<DataRow>((expense) {
                        final String id = (expense['id'] ?? '').toString();
                        final String department =
                            (expense['department'] ?? '').toString();
                        final String supplierName =
                            (expense['supplierName'] ?? '').toString();
                        final String requestDate =
                            (expense['requestDate'] ?? '').toString();
                        final num totalExpense = _toNum(
                          expense['totalExpense'],
                        );
                        final String currency =
                            (expense['currency'] ?? 'SAR').toString();
                        return DataRow(
                          cells: [
                            DataCell(Text(id)),
                            DataCell(Text(department)),
                            DataCell(Text(supplierName)),
                            DataCell(Text(requestDate)),
                            DataCell(
                              Text(
                                '${totalExpense.toStringAsFixed(2)} $currency',
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Convert dynamic value to num safely
  num _toNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value) ?? 0;
    }
    return 0;
  }
}
