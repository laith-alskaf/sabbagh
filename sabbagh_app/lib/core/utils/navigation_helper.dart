import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_routes.dart';
import 'package:sabbagh_app/domain/entities/user_role.dart';
import 'package:sabbagh_app/presentation/controllers/user_controller.dart';

/// Helper class for role-based navigation
class NavigationHelper {
  /// Get home route based on user role
  static String getHomeRoute(UserRole role) {
    switch (role) {
      case UserRole.manager:
      case UserRole.assistantManager:
        return AppRoutes.dashboard;
      case UserRole.employee:
      case UserRole.guest:
      case UserRole.financeManager:
      case UserRole.generalManager:
      case UserRole.procurementOfficer:
      case UserRole.auditor:
        return AppRoutes.purchaseOrders;
    }
  }

  /// Navigate to home based on current user role
  static void navigateToHome() {
    try {
      final userController = Get.find<UserController>();
      final user = userController.user.value;

      if (user == null) {
        Get.offAllNamed(AppRoutes.login);
        return;
      }

      final homeRoute = getHomeRoute(user.role);
      Get.offAllNamed(homeRoute);
    } catch (e) {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  /// Check if user can access route
  static bool canAccessRoute(String route, UserRole role) {
    switch (route) {
      case AppRoutes.dashboard:
        return role == UserRole.manager || role == UserRole.assistantManager;

      case AppRoutes.reports:
        return role == UserRole.manager || role == UserRole.assistantManager;

      case AppRoutes.auditLogs:
        return role == UserRole.manager || role == UserRole.generalManager;

      case AppRoutes.users:
      case AppRoutes.createUser:
      case AppRoutes.editUser:
      case AppRoutes.userDetails:
        return role == UserRole.manager;

      case AppRoutes.purchaseOrders:
      case AppRoutes.purchaseOrderDetails:
        return true; // All roles can view purchase orders

      case AppRoutes.createPurchaseOrder:
        return role != UserRole.auditor;

      case AppRoutes.vendors:
      case AppRoutes.vendorDetails:
        return role == UserRole.manager ||
            role == UserRole.assistantManager ||
            role == UserRole.employee;

      case AppRoutes.createVendor:
      case AppRoutes.editVendor:
        return role == UserRole.manager;

      case AppRoutes.items:
      case AppRoutes.itemDetails:
        return role == UserRole.manager ||
            role == UserRole.assistantManager ||
            role == UserRole.employee;

      case AppRoutes.createItem:
      case AppRoutes.editItem:
        return role == UserRole.manager;

      case AppRoutes.changeRequests:
      case AppRoutes.changeRequestDetails:
        return role == UserRole.manager ||
            role == UserRole.assistantManager ||
            role == UserRole.employee;

      case AppRoutes.profile:
      case AppRoutes.settings:
        return true; // All authenticated users can access profile/settings

      default:
        return true;
    }
  }

  /// Get fallback route if user can't access requested route
  static String getFallbackRoute(UserRole role) {
    return getHomeRoute(role);
  }

  /// Navigate with role check
  static void navigateWithRoleCheck(String route) {
    try {
      final userController = Get.find<UserController>();
      final user = userController.user.value;

      if (user == null) {
        Get.offAllNamed(AppRoutes.login);
        return;
      }

      if (canAccessRoute(route, user.role)) {
        Get.toNamed(route);
      } else {
        // Show access denied message
        Get.snackbar(
          'access_denied'.tr,
          'no_permission_for_this_action'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );

        // Navigate to fallback route
        final fallbackRoute = getFallbackRoute(user.role);
        if (Get.currentRoute != fallbackRoute) {
          Get.offAllNamed(fallbackRoute);
        }
      }
    } catch (e) {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  /// Replace current route with role check
  static void offNamedWithRoleCheck(String route) {
    try {
      final userController = Get.find<UserController>();
      final user = userController.user.value;

      if (user == null) {
        Get.offAllNamed(AppRoutes.login);
        return;
      }

      if (canAccessRoute(route, user.role)) {
        Get.offNamed(route);
      } else {
        final fallbackRoute = getFallbackRoute(user.role);
        Get.offAllNamed(fallbackRoute);
      }
    } catch (e) {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  /// Replace all routes with role check
  static void offAllNamedWithRoleCheck(String route) {
    try {
      final userController = Get.find<UserController>();
      final user = userController.user.value;

      if (user == null) {
        Get.offAllNamed(AppRoutes.login);
        return;
      }

      if (canAccessRoute(route, user.role)) {
        Get.offAllNamed(route);
      } else {
        final fallbackRoute = getFallbackRoute(user.role);
        Get.offAllNamed(fallbackRoute);
      }
    } catch (e) {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  /// Get available navigation items for user role
  static List<NavigationItem> getNavigationItems(UserRole role) {
    final items = <NavigationItem>[];

    // Dashboard - Only for managers and assistant managers
    if (role == UserRole.manager || role == UserRole.assistantManager) {
      items.add(
        NavigationItem(
          route: AppRoutes.dashboard,
          title: 'dashboard',
          icon: 'dashboard_outlined',
        ),
      );
    }

    // Purchase Orders - Available for all roles
    items.add(
      NavigationItem(
        route: AppRoutes.purchaseOrders,
        title: 'purchase_orders',
        icon: 'shopping_cart_outlined',
      ),
    );

    // Vendors - Based on permissions
    if (role == UserRole.manager || role == UserRole.assistantManager) {
      items.add(
        NavigationItem(
          route: AppRoutes.vendors,
          title: 'vendors',
          icon: 'business_outlined',
        ),
      );
    }

    // Items - Based on permissions
    if (role == UserRole.manager || role == UserRole.assistantManager) {
      items.add(
        NavigationItem(
          route: AppRoutes.items,
          title: 'items',
          icon: 'inventory_2_outlined',
        ),
      );
    }

    // Reports - Based on permissions
    if (role == UserRole.manager || role == UserRole.assistantManager) {
      items.add(
        NavigationItem(
          route: AppRoutes.reports,
          title: 'reports',
          icon: 'analytics_outlined',
        ),
      );
    }

    // Audit Logs - Manager and General Manager
    if (role == UserRole.manager || role == UserRole.generalManager) {
      items.add(
        NavigationItem(
          route: AppRoutes.auditLogs,
          title: 'audit_logs',
          icon: 'analytics_outlined',
        ),
      );
    }

    // Change Requests - Based on permissions
    if (role == UserRole.manager || role == UserRole.assistantManager) {
      items.add(
        NavigationItem(
          route: AppRoutes.changeRequests,
          title: 'change_requests',
          icon: 'change_circle_outlined',
        ),
      );
    }

    // User Management - Only for managers
    if (role == UserRole.manager) {
      items.add(
        NavigationItem(
          route: AppRoutes.users,
          title: 'users',
          icon: 'admin_panel_settings_outlined',
        ),
      );
    }

    return items;
  }
}

/// Navigation item model
class NavigationItem {
  final String route;
  final String title;
  final String icon;

  NavigationItem({
    required this.route,
    required this.title,
    required this.icon,
  });
}
