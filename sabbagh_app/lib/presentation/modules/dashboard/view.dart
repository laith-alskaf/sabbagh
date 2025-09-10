import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sabbagh_app/core/constants/app_colors.dart';
import 'package:sabbagh_app/core/constants/app_routes.dart';
import 'package:sabbagh_app/data/dto/dashboard_dto.dart';
import 'package:sabbagh_app/presentation/controllers/user_controller.dart';
import 'package:sabbagh_app/presentation/modules/dashboard/controller.dart';
import 'package:sabbagh_app/presentation/widgets/app_drawer.dart';
import 'package:sabbagh_app/presentation/widgets/custom_app_bar.dart';

/// Professional Dashboard View
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final userController = Get.find<UserController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: 'dashboard'.tr),
      drawer: const AppDrawer(),
      body: Obx(() {
        if (!controller.canAccessDashboard) {
          return _buildAccessDenied();
        }

        return RefreshIndicator(
          onRefresh: controller.refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(userController),
                const SizedBox(height: 24),
                _buildQuickStats(controller),
                const SizedBox(height: 24),
                _buildChartsSection(controller),
                const SizedBox(height: 24),
                _buildRecentOrdersSection(controller),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Build access denied widget
  Widget _buildAccessDenied() {
    double scale = MediaQuery.of(Get.context!).size.width > 600 ? 1.5 : 1.0;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: scale * 64, color: Colors.grey[400]),
          SizedBox(height: scale * 16),
          Text(
            'access_denied'.tr,
            style: TextStyle(
              fontSize: scale * 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'dashboard_access_required'.tr,
            style: TextStyle(fontSize: scale * 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build header section
  Widget _buildHeader(UserController userController) {
    double scale = MediaQuery.of(Get.context!).size.width > 600 ? 1.5 : 1.0;
    return Container(
      padding: EdgeInsets.all(scale * 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreen, Color(0xFF2E7D32)],
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'welcome_back'.tr}, ${userController.user.value?.name ?? ''}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: scale * 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: scale * 8),
                Text(
                  'dashboard_subtitle'.tr,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: scale * 16,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.dashboard, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  /// Build quick stats section
  Widget _buildQuickStats(DashboardController controller) {
    double scale = MediaQuery.of(Get.context!).size.width > 600 ? 1.5 : 1.0;

    return Obx(() {
      if (controller.isLoadingStats.value) {
        return _buildStatsLoading();
      }

      if (controller.statsError.value.isNotEmpty) {
        return _buildStatsError(controller);
      }

      final stats = controller.quickStats.value;
      if (stats == null) {
        return _buildStatsEmpty();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'quick_overview'.tr,
            style: TextStyle(
              fontSize: scale * 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: scale * 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: scale * 16,
            mainAxisSpacing: scale * 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: scale * 1.8,
            children: [
              _buildStatCard(
                'total_orders'.tr,
                stats.totalOrders.toString(),
                Icons.shopping_cart_outlined,
                AppColors.primaryGreen,
                '${stats.completedOrders} ${'completed'.tr}',
              ),
              _buildStatCard(
                'pending_orders'.tr,
                stats.pendingOrders.toString(),
                Icons.pending_actions_outlined,
                Colors.orange,
                '${stats.inProgressOrders} ${'in_progress'.tr}',
              ),
              _buildStatCard(
                'total_value'.tr,
                controller.formatCurrency(stats.totalValue),
                Icons.attach_money_outlined,
                Colors.blue,
                '',
              ),
              _buildStatCard(
                'suppliers'.tr,
                stats.supplierCount.toString(),
                Icons.business_outlined,
                Colors.purple,
                '${stats.itemCount} ${'items'.tr}',
              ),
            ],
          ),
        ],
      );
    });
  }

  /// Build stat card
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    double scale = MediaQuery.of(Get.context!).size.width > 600 ? 1.5 : 1.0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon and trend
              SizedBox(
                height: constraints.maxHeight * 0.3,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(icon, color: color, size: scale * 16),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.trending_up,
                      color: Colors.green,
                      size: scale * 14,
                    ),
                  ],
                ),
              ),

              // Value
              Expanded(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: scale * 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),

              // Title
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: scale * 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              // Subtitle
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: scale * 9,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build charts section
  Widget _buildChartsSection(DashboardController controller) {
    double scale = MediaQuery.of(Get.context!).size.width > 600 ? 1.5 : 1.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'analytics'.tr,
          style: TextStyle(
            fontSize: scale * 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: scale * 16),
        Row(
          children: [
            Expanded(child: _buildOrdersStatusChart(controller)),
            SizedBox(width: scale * 16),
            Expanded(child: _buildTopSuppliersChart(controller)),
          ],
        ),
        const SizedBox(height: 16),
        _buildMonthlyExpensesChart(controller),
      ],
    );
  }

  /// Build orders status pie chart
  Widget _buildOrdersStatusChart(DashboardController controller) {
    double scale = MediaQuery.of(Get.context!).size.width > 600 ? 1.5 : 1.0;
    return Obx(() {
      if (controller.isLoadingOrders.value) {
        return _buildChartLoading('orders_by_status'.tr);
      }

      final orders = controller.ordersByStatus;
      if (orders.isEmpty) {
        return _buildChartEmpty('orders_by_status'.tr);
      }

      return Container(
        height: scale * 300,
        padding: EdgeInsets.all(scale * 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(scale * 12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'orders_by_status'.tr,
              style: TextStyle(
                fontSize: scale * 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: scale * 16),
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: List.generate(orders.length, (index) {
                    return PieChartSectionData(
                      value: orders[index].count.toDouble(),
                      title: orders[index].status,
                      color: Color(
                        int.parse(
                          '0xFF${controller.getStatusColor(orders[index].status).substring(1)}',
                        ),
                      ),
                      radius: scale * 40,
                      titleStyle: TextStyle(
                        fontSize: scale * 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                  centerSpaceRadius: scale * 2.1 * 40,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Build top suppliers chart
  Widget _buildTopSuppliersChart(DashboardController controller) {
    double scale = MediaQuery.of(Get.context!).size.width > 600 ? 1.5 : 1.0;
    return Obx(() {
      if (controller.isLoadingSuppliers.value) {
        return _buildChartLoading('top_suppliers'.tr);
      }

      final suppliers = controller.topSuppliers;
      if (suppliers.isEmpty) {
        return _buildChartEmpty('top_suppliers'.tr);
      }

      return Container(
        height: scale * 300,
        padding: EdgeInsets.all(scale * 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(scale * 12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              children: [
                Text(
                  'top_suppliers'.tr,
                  style: TextStyle(
                    fontSize: scale * 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: controller.supplierSortBy.value,
                  underline: const SizedBox(),
                  items: [
                    DropdownMenuItem(
                      value: 'count',
                      child: Text('by_orders'.tr),
                    ),
                    DropdownMenuItem(
                      value: 'value',
                      child: Text('by_value'.tr),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.changeSupplierSort(value);
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: scale * 16),
            Expanded(
              child: ListView.builder(
                itemCount: suppliers.length,
                itemBuilder: (context, index) {
                  final supplier = suppliers[index];
                  final maxValue =
                      controller.supplierSortBy.value == 'count'
                          ? suppliers.first.orderCount.toDouble()
                          : suppliers.first.totalValue;
                  final currentValue =
                      controller.supplierSortBy.value == 'count'
                          ? supplier.orderCount.toDouble()
                          : supplier.totalValue;
                  final percentage =
                      maxValue > 0 ? currentValue / maxValue : 0.0;

                  return Padding(
                    padding: EdgeInsets.only(bottom: scale * 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                supplier.name,
                                style: TextStyle(
                                  fontSize: scale * 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              controller.supplierSortBy.value == 'count'
                                  ? '${supplier.orderCount}'
                                  : controller.formatCurrency(
                                    supplier.totalValue,
                                  ),
                              style: TextStyle(
                                fontSize: scale * 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Build monthly expenses chart
  Widget _buildMonthlyExpensesChart(DashboardController controller) {
    return Obx(() {
      if (controller.isLoadingExpenses.value) {
        return _buildChartLoading('monthly_expenses'.tr);
      }

      final expenses = controller.monthlyExpenses;
      if (expenses.isEmpty) {
        return _buildChartEmpty('monthly_expenses'.tr);
      }

      return Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'monthly_expenses'.tr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            controller.formatCurrency(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < expenses.length) {
                            final expense = expenses[index];
                            return Text(
                              expense.monthName.substring(0, 3),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots:
                          expenses.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              entry.value.totalExpense,
                            );
                          }).toList(),
                      isCurved: true,
                      color: AppColors.primaryGreen,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Build recent orders section
  Widget _buildRecentOrdersSection(DashboardController controller) {
    double scale = MediaQuery.of(Get.context!).size.width > 600 ? 1.5 : 1.0;
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'recent_orders'.tr,
                style: TextStyle(
                  fontSize: scale * 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.purchaseOrders),
                child: Text(
                  'view_all'.tr,
                  style: TextStyle(fontSize: scale * 10),
                ),
              ),
            ],
          ),
          SizedBox(height: scale * 16),
          if (controller.isLoadingRecentOrders.value)
            _buildRecentOrdersLoading()
          else if (controller.recentOrdersError.value.isNotEmpty)
            _buildRecentOrdersError(controller)
          else if (controller.recentOrders.isEmpty)
            _buildRecentOrdersEmpty()
          else
            _buildRecentOrdersList(controller),
        ],
      );
    });
  }

  /// Build recent orders list
  Widget _buildRecentOrdersList(DashboardController controller) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount:
          controller.recentOrders.length > 4
              ? 4
              : controller.recentOrders.length,
      itemBuilder: (context, index) {
        final order = controller.recentOrders[index];
        return _buildRecentOrderCard(order, controller);
      },
    );
  }

  /// Build recent order card
  Widget _buildRecentOrderCard(
    RecentOrderDto order,
    DashboardController controller,
  ) {
    double scale = MediaQuery.of(Get.context!).size.width > 600 ? 1.5 : 1.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.items.isNotEmpty
                          ? order.items.first.name ?? ''
                          : '',
                      style: TextStyle(
                        fontSize: scale * 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: scale * 4),
                    Text(
                      order.requesterName,
                      style: TextStyle(
                        fontSize: scale * 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: scale * 12,
                  vertical: scale * 6,
                ),
                decoration: BoxDecoration(
                  color: Color(
                    int.parse(
                      '0xFF${controller.getStatusColor(order.status).substring(1)}',
                    ),
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Color(
                      int.parse(
                        '0xFF${controller.getStatusColor(order.status).substring(1)}',
                      ),
                    ),
                  ),
                ),
                child: Text(
                  controller.getStatusText(order.status),
                  style: TextStyle(
                    fontSize: scale * 12,
                    fontWeight: FontWeight.w500,
                    color: Color(
                      int.parse(
                        '0xFF${controller.getStatusColor(order.status).substring(1)}',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: scale * 12),
          Row(
            children: [
              Icon(
                Icons.business_outlined,
                size: scale * 16,
                color: Colors.grey[600],
              ),
              SizedBox(width: scale * 4),
              Text(
                order.department,
                style: TextStyle(fontSize: scale * 12, color: Colors.grey[600]),
              ),
              SizedBox(width: scale * 16),
              Icon(
                Icons.calendar_today_outlined,
                size: scale * 16,
                color: Colors.grey[600],
              ),
              SizedBox(width: scale * 4),
              Text(
                controller.formatDate(order.createdAt),
                style: TextStyle(fontSize: scale * 12, color: Colors.grey[600]),
              ),
              const Spacer(),
              Text(
                '${controller.formatCurrency(order.totalAmount ?? 0)} ${order.items.first.currency ?? 'Currency'}',
                style: TextStyle(
                  fontSize: scale * 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          if (order.supplierName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.store_outlined,
                  size: scale * 16,
                  color: Colors.grey[600],
                ),
                SizedBox(width: scale * 4),
                Text(
                  order.supplierName!,
                  style: TextStyle(
                    fontSize: scale * 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build loading widgets
  Widget _buildStatsLoading() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: List.generate(4, (index) => _buildLoadingCard()),
    );
  }

  Widget _buildLoadingCard() {
    double scale = MediaQuery.of(Get.context!).size.width > 600 ? 1.5 : 1.0;
    return Container(
      padding: EdgeInsets.all(scale * 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scale * 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildChartLoading(String title) {
    double scale = MediaQuery.of(Get.context!).size.width > 600 ? 1.5 : 1.0;
    return Container(
      height: scale * 300,
      padding: EdgeInsets.all(scale * 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: scale * 16, fontWeight: FontWeight.bold),
          ),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersLoading() {
    return Column(children: List.generate(3, (index) => _buildLoadingCard()));
  }

  /// Build error widgets
  Widget _buildStatsError(DashboardController controller) {
    double scale = MediaQuery.of(Get.context!).size.width > 600 ? 1.5 : 1.0;
    return Container(
      padding: EdgeInsets.all(scale * 20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(scale * 12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: scale * 48),
          SizedBox(height: scale * 12),
          Text(
            controller.statsError.value,
            style: TextStyle(
              color: Colors.red[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: scale * 12),
          ElevatedButton(
            onPressed: controller.loadQuickStats,
            child: Text('retry'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildChartEmpty(String title) {
    double scale = MediaQuery.of(Get.context!).size.width > 600 ? 1.5 : 1.0;
    return Container(
      height: scale * 300,
      padding: EdgeInsets.all(scale * 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scale * 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: scale * 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: scale * 16, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart_outlined,
                    size: scale * 48,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: scale * 12),
                  Text(
                    'no_data_available'.tr,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsEmpty() {
    double scale = MediaQuery.of(Get.context!).size.width > 600 ? 1.5 : 1.0;
    return Container(
      padding: EdgeInsets.all(scale * 20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(scale * 12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: scale * 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: scale * 12),
            Text(
              'no_stats_available'.tr,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersError(DashboardController controller) {
    double scale = MediaQuery.of(Get.context!).size.width > 600 ? 1.5 : 1.0;
    return Container(
      padding: EdgeInsets.all(scale * 20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(scale * 12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: scale * 32),
          SizedBox(height: scale * 8),
          Text(
            controller.recentOrdersError.value,
            style: TextStyle(color: Colors.red[700]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: scale * 8),
          ElevatedButton(
            onPressed: controller.loadRecentOrders,
            child: Text('retry'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersEmpty() {
    double scale = MediaQuery.of(Get.context!).size.width > 600 ? 1.5 : 1.0;
    return Container(
      padding: EdgeInsets.all(scale * 20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: scale * 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: scale * 12),
            Text(
              'no_recent_orders'.tr,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
