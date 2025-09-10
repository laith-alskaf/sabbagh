import 'package:sabbagh_app/core/services/dio_client.dart';
import 'package:sabbagh_app/data/dto/dashboard_dto.dart';

/// Repository for dashboard data
class DashboardRepository {
  final DioClient _dioClient;

  /// Creates a new [DashboardRepository]
  DashboardRepository(this._dioClient);

  /// Get dashboard quick statistics
  Future<DashboardQuickStatsResponseDto> getQuickStats() async {
    final response = await _dioClient.get('/dashboard/quick-stats');
    return DashboardQuickStatsResponseDto.fromJson(response as Map<String, dynamic>);
  }

  /// Get orders count by status
  Future<OrdersByStatusResponseDto> getOrdersByStatus() async {
    final response = await _dioClient.get('/dashboard/orders-by-status');
    return OrdersByStatusResponseDto.fromJson(response as Map<String, dynamic>);
  }

  /// Get monthly expenses for the last 12 months
  Future<MonthlyExpensesResponseDto> getMonthlyExpenses({String? locale}) async {
    final queryParams = <String, dynamic>{};
    if (locale != null) {
      queryParams['locale'] = locale;
    }

    final response = await _dioClient.get(
      '/dashboard/monthly-expenses',
      queryParameters: queryParams,
    );
    return MonthlyExpensesResponseDto.fromJson(response as Map<String, dynamic>);
  }

  /// Get top suppliers
  Future<TopSuppliersResponseDto> getTopSuppliers({
    int limit = 5,
    String sortBy = 'count',
  }) async {
    final response = await _dioClient.get(
      '/dashboard/top-suppliers',
      queryParameters: {
        'limit': limit,
        'sortBy': sortBy,
      },
    );
    return TopSuppliersResponseDto.fromJson(response as Map<String, dynamic>);
  }

  /// Get recent orders
  Future<RecentOrdersResponseDto> getRecentOrders({int limit = 10}) async {
    final response = await _dioClient.get(
      '/dashboard/recent-orders',
      queryParameters: {
        'limit': limit,
      },
    );
    return RecentOrdersResponseDto.fromJson(response as Map<String, dynamic>);
  }
}