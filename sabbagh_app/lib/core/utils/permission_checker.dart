import 'package:get/get.dart';
import 'package:sabbagh_app/domain/entities/user_role.dart';
import 'package:sabbagh_app/presentation/controllers/user_controller.dart';

/// Utility class for checking user permissions before API calls
class PermissionChecker {
  static final UserController _userController = Get.find<UserController>();

  /// Check if user can access dashboard data
  static bool canAccessDashboard() {
    final role = _userController.role;
    return role == UserRole.manager || role == UserRole.assistantManager;
  }

  /// Check if user can create purchase orders
  static bool canCreatePurchaseOrders() {
    return _userController.canCreatePurchaseOrders;
  }

  /// Check if user can approve purchase orders
  static bool canApprovePurchaseOrders() {
    return _userController.canApprovePurchaseOrders;
  }

  /// Check if user can create vendors
  static bool canCreateVendors() {
    return _userController.canCreateVendors;
  }

  /// Check if user can create items
  static bool canCreateItems() {
    return _userController.canCreateItems;
  }

  /// Check if user can view reports
  static bool canViewReports() {
    return _userController.canViewReports;
  }

  /// Check if user can create users (Manager only)
  static bool canCreateUsers() {
    return _userController.canCreateUsers;
  }

  /// Check if user is manager
  static bool isManager() {
    return _userController.role == UserRole.manager;
  }

  /// Check if user is assistant manager
  static bool isAssistantManager() {
    return _userController.role == UserRole.assistantManager;
  }

  /// Check if user is employee
  static bool isEmployee() {
    return _userController.role == UserRole.employee;
  }

  /// Check if user is guest
  static bool isGuest() {
    return _userController.role == UserRole.guest;
  }

  /// Get user role as string
  static String getUserRoleString() {
    return _userController.role.toApiString();
  }

  /// Throw permission error if user doesn't have required permission
  static void requirePermission(bool hasPermission, String action) {
    if (!hasPermission) {
      throw PermissionException('Access denied: You do not have permission to $action');
    }
  }

  /// Throw permission error if user can't access dashboard
  static void requireDashboardAccess() {
    requirePermission(
      canAccessDashboard(),
      'access dashboard data'
    );
  }

  /// Throw permission error if user can't create purchase orders
  static void requireCreatePurchaseOrderPermission() {
    requirePermission(
      canCreatePurchaseOrders(),
      'create purchase orders'
    );
  }

  /// Throw permission error if user can't approve purchase orders
  static void requireApprovePurchaseOrderPermission() {
    requirePermission(
      canApprovePurchaseOrders(),
      'approve purchase orders'
    );
  }

  /// Throw permission error if user can't create vendors
  static void requireCreateVendorPermission() {
    requirePermission(
      canCreateVendors(),
      'create vendors'
    );
  }

  /// Throw permission error if user can't create items
  static void requireCreateItemPermission() {
    requirePermission(
      canCreateItems(),
      'create items'
    );
  }

  /// Throw permission error if user can't view reports
  static void requireViewReportsPermission() {
    requirePermission(
      canViewReports(),
      'view reports'
    );
  }

  /// Throw permission error if user is not manager
  static void requireManagerRole() {
    requirePermission(
      isManager(),
      'perform manager-only actions'
    );
  }
}

/// Exception thrown when user doesn't have required permissions
class PermissionException implements Exception {
  final String message;
  
  const PermissionException(this.message);
  
  @override
  String toString() => 'PermissionException: $message';
}