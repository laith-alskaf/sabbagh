/// Dashboard Quick Statistics DTO
class DashboardQuickStatsDto {
  final int totalOrders;
  final int pendingOrders;
  final int inProgressOrders;
  final int completedOrders;
  final double totalValue;
  final int supplierCount;
  final int itemCount;

  const DashboardQuickStatsDto({
    required this.totalOrders,
    required this.pendingOrders,
    required this.inProgressOrders,
    required this.completedOrders,
    required this.totalValue,
    required this.supplierCount,
    required this.itemCount,
  });

  /// Create from JSON response
  factory DashboardQuickStatsDto.fromJson(Map<String, dynamic> json) {
    return DashboardQuickStatsDto(
      totalOrders: json['totalOrders'] as int? ?? 0,
      pendingOrders: json['pendingOrders'] as int? ?? 0,
      inProgressOrders: json['inProgressOrders'] as int? ?? 0,
      completedOrders: json['completedOrders'] as int? ?? 0,
      totalValue: (json['totalValue'] as num?)?.toDouble() ?? 0.0,
      supplierCount: json['supplierCount'] as int? ?? 0,
      itemCount: json['itemCount'] as int? ?? 0,
    );
  }
}

/// Orders by Status DTO
class OrdersByStatusDto {
  final int draft;
  final int underAssistantReview;
  final int underManagerReview;
  final int inProgress;
  final int completed;
  final int rejectedByAssistant;
  final int rejectedByManager;

  const OrdersByStatusDto({
    required this.draft,
    required this.underAssistantReview,
    required this.underManagerReview,
    required this.inProgress,
    required this.completed,
    required this.rejectedByAssistant,
    required this.rejectedByManager,
  });

  /// Create from JSON response
  factory OrdersByStatusDto.fromJson(Map<String, dynamic> json) {
    return OrdersByStatusDto(
      draft: json['draft'] as int? ?? 0,
      underAssistantReview: json['under_assistant_review'] as int? ?? 0,
      underManagerReview: json['under_manager_review'] as int? ?? 0,
      inProgress: json['in_progress'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      rejectedByAssistant: json['rejected_by_assistant'] as int? ?? 0,
      rejectedByManager: json['rejected_by_manager'] as int? ?? 0,
    );
  }

  /// Get total orders
  int get total =>
      draft +
      underAssistantReview +
      underManagerReview +
      inProgress +
      completed +
      rejectedByAssistant +
      rejectedByManager;

  /// Get pending orders (under review)
  int get pending => underAssistantReview + underManagerReview;

  /// Get rejected orders
  int get rejected => rejectedByAssistant + rejectedByManager;
}

/// Monthly Expense DTO
class MonthlyExpenseDto {
  final String month;
  final String monthName;
  final double totalExpense;

  const MonthlyExpenseDto({
    required this.month,
    required this.monthName,
    required this.totalExpense,
  });

  /// Create from JSON response
  factory MonthlyExpenseDto.fromJson(Map<String, dynamic> json) {
    return MonthlyExpenseDto(
      month: json['month'] as String? ?? '',
      monthName: json['monthName'] as String? ?? '',
      totalExpense: (json['totalExpense'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Top Supplier DTO
class TopSupplierDto {
  final String id;
  final String name;
  final int orderCount;
  final double totalValue;

  const TopSupplierDto({
    required this.id,
    required this.name,
    required this.orderCount,
    required this.totalValue,
  });

  /// Create from JSON response
  factory TopSupplierDto.fromJson(Map<String, dynamic> json) {
    return TopSupplierDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      orderCount: json['orderCount'] as int? ?? 0,
      totalValue: (json['totalValue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Recent Order DTO
class RecentOrderDto {
  final String id;
  final String orderNumber;
  final String requesterName;
  final String department;
  final String requestType;
  final String status;
  final DateTime createdAt;
  final double? totalAmount;
  final DateTime updatedAt;
  final String? supplierName;
  final List<RecentOrderItemDto> items;

  const RecentOrderDto({
    required this.id,
    required this.orderNumber,
    required this.requesterName,
    required this.department,
    required this.requestType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
     this.totalAmount,
    this.supplierName,
    required this.items,
  });

  /// Create from JSON response
  factory RecentOrderDto.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final items =
        itemsJson
            .map(
              (item) =>
                  RecentOrderItemDto.fromJson(item as Map<String, dynamic>),
            )
            .toList();

    return RecentOrderDto(
      id: json['id'] as String? ?? '',
      orderNumber: json['number'] as String? ?? '',
      requesterName: json['requesterName'] as String? ?? '',
      department: json['department'] as String? ?? '',
      requestType: json['request_type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
      supplierName: json['supplier_name'] as String?,
      totalAmount:
          json['total_amount'] != null
              ? (json['total_amount'] as num).toDouble()
              : 0,
      items: items,
    );
  }

  /// Get total value of the order
  double get totalValue {
    return items.fold(
      0.0,
      (sum, item) => sum + ((item.price ?? 0.0) * (item.quantity ?? 1)),
    );
  }
}

/// Recent Order Item DTO
class RecentOrderItemDto {
  final String? id;
  final String? name;
  final int? quantity;
  final double? price;
  final String? unit;
  final String? currency;

  const RecentOrderItemDto({
    this.id,
    this.name,
    this.quantity,
    this.price,
    this.unit,
    this.currency,
  });

  /// Create from JSON response
  factory RecentOrderItemDto.fromJson(Map<String, dynamic> json) {
    return RecentOrderItemDto(
      id: json['id'] as String? ?? '',
      name: json['item_name'] as String? ?? '',
      quantity: (json['quantity'] as int?) ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String?,
      currency: json['currency'] as String?,
    );
  }
}

/// Dashboard Response DTOs
class DashboardQuickStatsResponseDto {
  final bool success;
  final String? message;
  final DashboardQuickStatsDto data;

  const DashboardQuickStatsResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory DashboardQuickStatsResponseDto.fromJson(Map<String, dynamic> json) {
    return DashboardQuickStatsResponseDto(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: DashboardQuickStatsDto.fromJson(
        json['data'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class OrdersByStatusResponseDto {
  final bool success;
  final String? message;
  final List<OrderStatusDto> data;

  const OrdersByStatusResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory OrdersByStatusResponseDto.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'] as List<dynamic>? ?? [];
    return OrdersByStatusResponseDto(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data:
          dataJson
              .map(
                (expense) =>
                    OrderStatusDto.fromJson(expense as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}

class MonthlyExpensesResponseDto {
  final bool success;
  final String? message;
  final List<MonthlyExpenseDto> data;

  const MonthlyExpensesResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory MonthlyExpensesResponseDto.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'] as List<dynamic>? ?? [];
    final data =
        dataJson
            .map(
              (expense) =>
                  MonthlyExpenseDto.fromJson(expense as Map<String, dynamic>),
            )
            .toList();

    return MonthlyExpensesResponseDto(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: data,
    );
  }
}

class TopSuppliersResponseDto {
  final bool success;
  final String? message;
  final List<TopSupplierDto> data;

  const TopSuppliersResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory TopSuppliersResponseDto.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'] as List<dynamic>? ?? [];
    final data =
        dataJson
            .map(
              (supplier) =>
                  TopSupplierDto.fromJson(supplier as Map<String, dynamic>),
            )
            .toList();

    return TopSuppliersResponseDto(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: data,
    );
  }
}

class RecentOrdersResponseDto {
  final bool success;
  final String? message;
  final List<RecentOrderDto> data;

  const RecentOrdersResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory RecentOrdersResponseDto.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'] as List<dynamic>? ?? [];
    final data =
        dataJson
            .map(
              (order) => RecentOrderDto.fromJson(order as Map<String, dynamic>),
            )
            .toList();

    return RecentOrdersResponseDto(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: data,
    );
  }
}

class OrderStatusDto {
  final String status;
  final int count;

  const OrderStatusDto({required this.count, required this.status});

  /// Create from JSON response
  factory OrderStatusDto.fromJson(Map<String, dynamic> json) {
    return OrderStatusDto(
      status: json['status'] as String,
      count: json['count'] as int,
    );
  }
}
