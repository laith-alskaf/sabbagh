import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_colors.dart';
import 'package:sabbagh_app/presentation/modules/reports/controller.dart';
import 'package:sabbagh_app/presentation/widgets/custom_app_bar.dart';
import 'package:sabbagh_app/presentation/widgets/drop_menu.dart';

/// Enhanced Purchase Orders Report View
class PurchaseOrdersReportView extends GetView<ReportController> {
  /// Creates a new [PurchaseOrdersReportView]
  const PurchaseOrdersReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'purchase_orders_report'.tr,
        actions: [
          if (controller.canExportReports)
            IconButton(
              icon: const Icon(Icons.download, color: AppColors.white),
              onPressed: controller.exportReport,
              tooltip: 'export_report'.tr,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportFilters(context),
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
  }

  Widget _buildReportFilters(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.filter_list,
                      color: AppColors.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'report_filters'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Date Range
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      controller: controller.startDateController,
                      label: 'start_date'.tr,
                      onTap: () => controller.selectStartDate(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateField(
                      controller: controller.endDateController,
                      label: 'end_date'.tr,
                      onTap: () => controller.selectEndDate(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filters Row
              Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      return _buildDropdownField(
                        context: context,
                        value:
                            controller.selectedDepartment.value.isEmpty
                                ? null
                                : controller.selectedDepartment.value,
                        label: 'department'.tr,
                        items: ['all_departments', ...controller.departments],
                        // _buildDropdownItems(
                        //   controller.departments,
                        //   'all_departments'.tr,
                        // ),
                        onChanged: (value) {
                          controller.selectedDepartment.value = value ?? '';
                        },
                      );
                    }),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(() {
                      return _buildDropdownField(
                        context: context,
                        value:
                            controller.selectedStatus.value.isEmpty
                                ? null
                                : controller.selectedStatus.value,
                        label: 'status'.tr,
                        items: ['all_statuses', ...controller.statuses],
                        onChanged: (value) {
                          controller.selectedStatus.value = value ?? '';
                        },
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Generate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.generateReport,
                  icon: const Icon(Icons.analytics),
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
        prefixIcon: const Icon(Icons.calendar_today),
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
    required BuildContext context,
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

  /// Helper  to create dropdown items with proper styling

  Widget _buildLoadingState() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating report...'),
          ],
        ),
      ),
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
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: AppColors.darkGray),
            const SizedBox(height: 16),
            Text(
              'no_data_available'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select filters and generate report',
              style: TextStyle(color: AppColors.darkGray),
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
        // Summary Cards
        _buildSummaryCards(data),
        const SizedBox(height: 24),

        // Charts Section
        _buildChartsSection(data),
        const SizedBox(height: 24),

        // Data Table
        _buildDataTable(data),
      ],
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> data) {
    final List<Map<String, dynamic>> summary = <Map<String, dynamic>>[];
    for (Map<String, dynamic> order in data['data']) {
      summary.add(order);
    }
    final totalOrders = summary.length;
    final currency =
        summary.isNotEmpty ? summary[0]['currency'] ?? 'SYR' : 'SYR';
    final totalAmount = summary.fold<double>(
      0.0,
      (sum, order) => sum + (order['totalValue'] ?? 0.0),
    );
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'total_orders'.tr,
            '$totalOrders',
            Icons.shopping_cart_outlined,
            AppColors.primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'total_amount'.tr,
            '${totalAmount.toStringAsFixed(2)} $currency',
            Icons.attach_money_outlined,
            AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'average_amount'.tr,
            '${totalOrders > 0 ? (totalAmount / totalOrders).toStringAsFixed(2) : '0.00'} $currency',
            Icons.trending_up_outlined,
            AppColors.info,
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.arrow_upward, color: color, size: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: AppColors.darkGray),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'charts_analysis'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Placeholder for charts - you can integrate fl_chart here
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('Charts will be displayed here')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(Map<String, dynamic> data) {
    final orders = List<dynamic>.from(data['data'] ?? []);
    final currency = orders.isNotEmpty ? orders[0]['currency'] ?? 'SYR' : 'SYR';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'purchase_orders_list'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (controller.canExportReports)
                  TextButton.icon(
                    onPressed: controller.exportReport,
                    icon: const Icon(Icons.download),
                    label: Text('export'.tr),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (orders.isEmpty)
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
                    DataColumn(label: Text('number'.tr)),
                    DataColumn(label: Text('requester_name'.tr)),
                    DataColumn(label: Text('department'.tr)),
                    DataColumn(label: Text('status'.tr)),
                    DataColumn(label: Text('request_date'.tr)),
                    DataColumn(label: Text('total_amount'.tr)),
                  ],
                  rows:
                      orders.map<DataRow>((order) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                order['order_number'] ?? order['number'] ?? '',
                              ),
                            ),
                            DataCell(
                              Text(
                                order['requesterName'] ??
                                    order['created_by'] ??
                                    '',
                              ),
                            ),
                            DataCell(Text(order['department'] ?? '')),
                            DataCell(_buildStatusChip(order['status'] ?? '')),
                            DataCell(Text(formatDate(order['requestDate']))),
                            DataCell(
                              Text(
                                '${(order['totalValue'] ?? 0).toStringAsFixed(2)} $currency',
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

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = AppColors.success;
        break;
      case 'in_progress':
        color = AppColors.info;
        break;
      case 'draft':
        color = AppColors.warning;
        break;
      case 'rejected_by_assistant':
      case 'rejected_by_manager':
        color = AppColors.error;
        break;
      default:
        color = AppColors.darkGray;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.tr,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String formatDate(dynamic v) {
    if (v == null) return '';
    DateTime dt;
    try {
      dt = DateTime.parse(v.toString());
    } catch (_) {
      return v.toString();
    }
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
