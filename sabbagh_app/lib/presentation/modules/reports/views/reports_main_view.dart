import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_colors.dart';
import 'package:sabbagh_app/presentation/modules/reports/controller.dart';
import 'package:sabbagh_app/presentation/widgets/app_drawer.dart';
import 'package:sabbagh_app/presentation/widgets/custom_app_bar.dart';

/// Enhanced Reports main view
class ReportsMainView extends GetView<ReportController> {
  /// Creates a new [ReportsMainView]
  const ReportsMainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: 'reports'.tr),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeaderSection(),
            const SizedBox(height: 24),

            // Quick Stats Section
            _buildQuickStatsSection(),
            const SizedBox(height: 24),

            // Reports Grid
            _buildReportsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.secondaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: AppColors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'reports_dashboard'.tr,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'reports_description'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Obx(() {
      // Only show stats if we have report data
      if (controller.reportData.value.isEmpty) {
        return const SizedBox.shrink();
      }

      final data = controller.reportData.value;
      final List<Map<String, dynamic>> summary = <Map<String, dynamic>>[];
      for (Map<String, dynamic> order in data['data']) {
        summary.add(order);
      }
      final totalAmount = summary.fold<double>(
        0.0,
        (sum, order) => sum + (order['totalValue'] ?? 0.0),
      );
      // final summary = Map<String, dynamic>.from(data['data'] ?? {});

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'quick_overview'.tr,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'total_orders'.tr,
                  '${summary.length}',
                  Icons.shopping_cart_outlined,
                  AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'total_amount'.tr,
                  '$totalAmount ${summary.isNotEmpty ? summary[0]['currency'] : 'SAR'}',
                  Icons.attach_money_outlined,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'average_amount'.tr,
                  '${(totalAmount / summary.length).toStringAsFixed(2)} ${summary.isNotEmpty ? summary[0]['currency'] : 'SAR'}',
                  Icons.trending_up_outlined,
                  AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      );
    });
  }

  Widget _buildStatCard(
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
              fontSize: 20,
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

  Widget _buildReportsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'available_reports'.tr,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          children: [
            _buildReportCard(
              'purchase_orders_report'.tr,
              'purchase_orders_report_desc'.tr,
              Icons.shopping_cart_outlined,
              AppColors.primaryGreen,
              controller.navigateToPurchaseOrdersReport,
            ),

            _buildReportCard(
              'expenses_report'.tr,
              'expenses_report_desc'.tr,
              Icons.attach_money_outlined,
              AppColors.success,
              controller.navigateToExpensesReport,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shadowColor: AppColors.shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  description,
                  style: TextStyle(fontSize: 11, color: AppColors.darkGray),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
