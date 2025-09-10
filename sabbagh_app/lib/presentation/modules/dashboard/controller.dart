import 'package:get/get.dart';
import 'package:sabbagh_app/core/services/dio_client.dart';
import 'package:sabbagh_app/data/dto/dashboard_dto.dart';
import 'package:sabbagh_app/localization/localization_service.dart';
import 'package:sabbagh_app/presentation/controllers/user_controller.dart';
import 'package:sabbagh_app/presentation/modules/dashboard/repository.dart';

/// Controller for dashboard
class DashboardController extends GetxController {
  final DioClient _dioClient = Get.find<DioClient>();
  final UserController _userController = Get.find<UserController>();
  final LocalizationService _localizationService = Get.find<LocalizationService>();
  late final DashboardRepository _repository;


  /// Loading states
  final RxBool isLoadingStats = false.obs;
  final RxBool isLoadingOrders = false.obs;
  final RxBool isLoadingExpenses = false.obs;
  final RxBool isLoadingSuppliers = false.obs;
  final RxBool isLoadingRecentOrders = false.obs;

  /// Dashboard data
  final Rx<DashboardQuickStatsDto?> quickStats = Rx<DashboardQuickStatsDto?>(null);
  final RxList<OrderStatusDto> ordersByStatus = <OrderStatusDto>[].obs;
  final RxList<MonthlyExpenseDto> monthlyExpenses = <MonthlyExpenseDto>[].obs;
  final RxList<TopSupplierDto> topSuppliers = <TopSupplierDto>[].obs;
  final RxList<RecentOrderDto> recentOrders = <RecentOrderDto>[].obs;

  /// Error messages
  final RxString errorMessage = ''.obs;
  final RxString statsError = ''.obs;
  final RxString ordersError = ''.obs;
  final RxString expensesError = ''.obs;
  final RxString suppliersError = ''.obs;
  final RxString recentOrdersError = ''.obs;

  /// Selected chart period
  final RxString selectedPeriod = '12'.obs; // 6, 12 months

  /// Selected supplier sort type
  final RxString supplierSortBy = 'count'.obs; // count, value

  @override
  void onInit() {
    super.onInit();
    _repository = DashboardRepository(_dioClient);
    loadDashboardData();
  }

  /// Load all dashboard data
  Future<void> loadDashboardData() async {
    await Future.wait([
      loadQuickStats(),
      loadOrdersByStatus(),
      loadMonthlyExpenses(),
      loadTopSuppliers(),
      loadRecentOrders(),
    ]);
  }

  /// Refresh all dashboard data
  Future<void> refreshDashboard() async {
    errorMessage.value = '';
    await loadDashboardData();
  }

  /// Load quick statistics
  Future<void> loadQuickStats() async {
    try {
      isLoadingStats.value = true;
      statsError.value = '';

      final response = await _repository.getQuickStats();
      if (response.success) {
        quickStats.value = response.data;
      } else {
        statsError.value = response.message ?? 'failed_to_load_stats'.tr;
      }
    } catch (e) {
      statsError.value = 'failed_to_load_stats'.tr;
    } finally {
      isLoadingStats.value = false;
    }
  }

  /// Load orders by status
  Future<void> loadOrdersByStatus() async {
    try {
      isLoadingOrders.value = true;
      ordersError.value = '';

      final response = await _repository.getOrdersByStatus();
      if (response.success) {
        ordersByStatus.value = response.data;
        
      } else {
        ordersError.value = response.message ?? 'failed_to_load_orders'.tr;
      }
    } catch (e) {
      ordersError.value = 'failed_to_load_orders'.tr;
    } finally {
      isLoadingOrders.value = false;
    }
  }

  /// Load monthly expenses
  Future<void> loadMonthlyExpenses() async {
    try {
      isLoadingExpenses.value = true;
      expensesError.value = '';

      final locale = _localizationService.currentLanguage.value;
      final response = await _repository.getMonthlyExpenses(locale: locale);
      
      if (response.success) {
        monthlyExpenses.value = response.data;
      } else {
        expensesError.value = response.message ?? 'failed_to_load_expenses'.tr;
      }
    } catch (e) {
      expensesError.value = 'failed_to_load_expenses'.tr;
    } finally {
      isLoadingExpenses.value = false;
    }
  }

  /// Load top suppliers
  Future<void> loadTopSuppliers() async {
    try {
      isLoadingSuppliers.value = true;
      suppliersError.value = '';

      final response = await _repository.getTopSuppliers(
        limit: 5,
        sortBy: supplierSortBy.value,
      );
      
      if (response.success) {
        topSuppliers.value = response.data;
      } else {
        suppliersError.value = response.message ?? 'failed_to_load_suppliers'.tr;
      }
    } catch (e) {
      suppliersError.value = 'failed_to_load_suppliers'.tr;
    } finally {
      isLoadingSuppliers.value = false;
    }
  }

  /// Load recent orders
  Future<void> loadRecentOrders() async {
    try {
      isLoadingRecentOrders.value = true;
      recentOrdersError.value = '';

      final response = await _repository.getRecentOrders(limit: 10);
      
      if (response.success) {
        recentOrders.value = response.data;
      } else {
        recentOrdersError.value = response.message ?? 'failed_to_load_recent_orders'.tr;
      }
    } catch (e) {
      recentOrdersError.value = 'failed_to_load_recent_orders'.tr;
    } finally {
      isLoadingRecentOrders.value = false;
    }
  }

  /// Change supplier sort type and reload
  Future<void> changeSupplierSort(String sortBy) async {
    if (supplierSortBy.value != sortBy) {
      supplierSortBy.value = sortBy;
      await loadTopSuppliers();
    }
  }

  /// Get status color
  String getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return '#9E9E9E'; // Gray
      case 'under_assistant_review':
        return '#FF9800'; // Orange
      case 'under_manager_review':
        return '#2196F3'; // Blue
      case 'in_progress':
        return '#00BCD4'; // Cyan
      case 'completed':
        return '#4CAF50'; // Green
      case 'rejected_by_assistant':
      case 'rejected_by_manager':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Gray
    }
  }

  /// Get status text
  String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'draft'.tr;
      case 'under_assistant_review':
        return 'under_assistant_review'.tr;
      case 'under_manager_review':
        return 'under_manager_review'.tr;
      case 'in_progress':
        return 'in_progress'.tr;
      case 'completed':
        return 'completed'.tr;
      case 'rejected_by_assistant':
        return 'rejected_by_assistant'.tr;
      case 'rejected_by_manager':
        return 'rejected_by_manager'.tr;
      default:
        return status.tr;
    }
  }

  /// Format currency
  String formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  /// Format date
  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Format time
  String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Get overall loading state
  bool get isLoading => isLoadingStats.value || 
                       isLoadingOrders.value || 
                       isLoadingExpenses.value || 
                       isLoadingSuppliers.value || 
                       isLoadingRecentOrders.value;

  /// Check if user can access dashboard
  bool get canAccessDashboard {
    final user = _userController.user.value;
    if (user == null) return false;
    
    // Only managers and assistant managers can access full dashboard
    return _userController.isManager || _userController.isAssistantManager;
  }

  /// Check if user can view analytics
  bool get canViewAnalytics {
    return canAccessDashboard;
  }

  /// Check if user can view financial data
  bool get canViewFinancialData {
    return _userController.isManager || _userController.isAssistantManager;
  }
}