import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_routes.dart';
import 'package:sabbagh_app/domain/entities/user_role.dart';
import 'package:sabbagh_app/presentation/controllers/user_controller.dart';

/// Middleware to check user roles for specific routes
class RoleMiddleware extends GetMiddleware {
  final List<UserRole> allowedRoles;
  final String? redirectRoute;

  /// Creates a new [RoleMiddleware]
  RoleMiddleware({
    required this.allowedRoles,
    this.redirectRoute,
  });

  @override
  RouteSettings? redirect(String? route) {
    try {
      final userController = Get.find<UserController>();
      final user = userController.user.value;
      
      if (user == null) {
        return const RouteSettings(name: AppRoutes.login);
      }
      
      if (!allowedRoles.contains(user.role)) {
        // Redirect based on user role
        final fallbackRoute = redirectRoute ?? _getFallbackRoute(user.role);
        return RouteSettings(name: fallbackRoute);
      }
      
      return null;
    } catch (e) {
      return const RouteSettings(name: AppRoutes.login);
    }
  }

  /// Get fallback route based on user role
  String _getFallbackRoute(UserRole role) {
    switch (role) {
      case UserRole.manager:
      case UserRole.assistantManager:
        return AppRoutes.dashboard;
      case UserRole.employee:
      case UserRole.guest:
      case UserRole.procurementOfficer:
      case UserRole.generalManager:
      case UserRole.financeManager:
      case UserRole.auditor:
        return AppRoutes.purchaseOrders;
    }
  }
}

/// Manager-only middleware
class ManagerOnlyMiddleware extends RoleMiddleware {
  ManagerOnlyMiddleware() : super(allowedRoles: [UserRole.manager]);
}

/// Manager and Assistant Manager middleware
class ManagerAssistantMiddleware extends RoleMiddleware {
  ManagerAssistantMiddleware() : super(
    allowedRoles: [UserRole.manager, UserRole.assistantManager],
  );
}

/// Dashboard access middleware
class DashboardAccessMiddleware extends RoleMiddleware {
  DashboardAccessMiddleware() : super(
    allowedRoles: [UserRole.manager, UserRole.assistantManager],
    redirectRoute: AppRoutes.purchaseOrders,
  );
}