import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/services/storage_service.dart';
import 'package:sabbagh_app/presentation/modules/auth/binding.dart';
import 'package:sabbagh_app/presentation/modules/auth/view.dart';
import 'package:sabbagh_app/presentation/modules/dashboard/binding.dart';
import 'package:sabbagh_app/presentation/modules/dashboard/view.dart';
import 'package:sabbagh_app/presentation/modules/items/binding.dart';
import 'package:sabbagh_app/presentation/modules/items/view.dart';
import 'package:sabbagh_app/presentation/modules/profile/binding.dart';
import 'package:sabbagh_app/presentation/modules/profile/view.dart';
import 'package:sabbagh_app/presentation/modules/purchase_orders/binding.dart';
import 'package:sabbagh_app/presentation/modules/purchase_orders/view.dart';
import 'package:sabbagh_app/presentation/modules/purchase_orders/details_view.dart';
import 'package:sabbagh_app/presentation/modules/purchase_orders/create_view.dart';
import 'package:sabbagh_app/presentation/modules/purchase_orders/edit_view.dart';
import 'package:sabbagh_app/presentation/modules/reports/binding.dart';
import 'package:sabbagh_app/presentation/modules/reports/views/reports_main_view.dart';
import 'package:sabbagh_app/presentation/modules/reports/views/purchase_orders_report_view.dart';
import 'package:sabbagh_app/presentation/modules/reports/views/expenses_report_view.dart';
import 'package:sabbagh_app/presentation/modules/vendors/binding.dart';
import 'package:sabbagh_app/presentation/modules/vendors/view.dart';
import 'package:sabbagh_app/presentation/modules/users/binding.dart';
import 'package:sabbagh_app/presentation/modules/users/view.dart';
import 'package:sabbagh_app/presentation/modules/change_requests/binding.dart';
import 'package:sabbagh_app/presentation/modules/change_requests/view.dart';
import 'package:sabbagh_app/presentation/modules/profile/change_password_view.dart';
import 'package:sabbagh_app/presentation/bindings/splash_binding.dart';
import 'package:sabbagh_app/presentation/screens/splash/splash_screen.dart';
import 'package:sabbagh_app/core/middleware/role_middleware.dart';
import 'package:sabbagh_app/presentation/modules/notifications/binding.dart';
import 'package:sabbagh_app/presentation/modules/notifications/view.dart';
import 'package:sabbagh_app/presentation/modules/audit/binding.dart';
import 'package:sabbagh_app/presentation/modules/audit/view.dart';
import 'package:sabbagh_app/domain/entities/user_role.dart';

/// Application routes
class AppRoutes {
  /// Splash route
  static const String splash = '/';

  /// Auth routes
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';

  /// Dashboard route
  static const String dashboard = '/dashboard';

  /// Purchase orders routes
  static const String purchaseOrders = '/purchase-orders';
  static const String purchaseOrderDetails = '/purchase-orders/:id';
  static const String createPurchaseOrder = '/purchase-orders/create';
  static const String editPurchaseOrder = '/purchase-orders/:id/edit';

  /// Vendors routes
  static const String vendors = '/vendors';
  static const String createVendor = '/vendors/create';
    static const String vendorDetails = '/vendors/:id';
  static const String editVendor = '/vendors/edit/:id';

  /// Items routes
  static const String items = '/items';
  static const String createItem = '/items/create';
    static const String itemDetails = '/items/:id';
  static const String editItem = '/items/edit/:id';


  /// Reports routes
  static const String reports = '/reports';
  static const String purchaseOrdersReport = '/reports/purchase-orders';

  static const String expensesReport = '/reports/expenses';

  /// Audit routes
  static const String auditLogs = '/audit-logs';

  /// Profile routes
  static const String profile = '/profile';
  static const String changePassword = '/profile/change-password';
  static const String settings = '/profile/settings';

  /// Notifications
  static const String notifications = '/notifications';

  /// User management routes (Manager only)
  static const String users = '/users';
  static const String userDetails = '/users/:id';
  static const String createUser = '/users/create';
  static const String editUser = '/users/:id/edit';

  /// Change requests routes
  static const String changeRequests = '/change-requests';
  static const String changeRequestDetails = '/change-requests/:id';
  static const String createChangeRequest = '/change-requests/create';
}

/// Application pages
class AppPages {
  /// Get application pages
  static List<GetPage> pages = [
    // Splash
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),

    // Auth
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),

    // Dashboard
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
      middlewares: [AuthMiddleware(), DashboardAccessMiddleware()],
    ),

    // Purchase Orders
    GetPage(
      name: AppRoutes.purchaseOrders,
      page: () => const PurchaseOrdersView(),
      binding: PurchaseOrderBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.createPurchaseOrder,
      page: () => const CreatePurchaseOrderView(),
      binding: PurchaseOrderBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.purchaseOrderDetails,
      page: () => const PurchaseOrderDetailsView(),
      binding: PurchaseOrderBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.editPurchaseOrder,
      page: () => const EditPurchaseOrderView(),
      binding: PurchaseOrderBinding(),
      middlewares: [AuthMiddleware()],
    ),

    // Vendors
    GetPage(
      name: AppRoutes.vendors,
      page: () => const VendorsView(),
      binding: VendorBinding(),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoutes.createVendor,
      page: () => const CreateVendorView(),
      binding: VendorBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.vendorDetails,
      page: () => const VendorDetailsView(),
      binding: VendorBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.editVendor,
      page: () => const EditVendorView(),
      binding: VendorBinding(),
      middlewares: [AuthMiddleware()],
    ),

    // Items
    GetPage(
      name: AppRoutes.items,
      page: () => const ItemsView(),
      binding: ItemBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.createItem,
      page: () => const CreateItemView(),
      binding: ItemBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.itemDetails,
      page: () => const ItemDetailsView(),
      binding: ItemBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.editItem,
      page: () => const EditItemView(),
      binding: ItemBinding(),
      middlewares: [AuthMiddleware()],
    ),

    // Reports
    GetPage(
      name: AppRoutes.reports,
      page: () => const ReportsMainView(),
      binding: ReportBinding(),
      middlewares: [AuthMiddleware(), ManagerAssistantMiddleware()],
    ),

    // Audit Logs (Manager + General Manager)
    GetPage(
      name: AppRoutes.auditLogs,
      page: () => const AuditLogsView(),
      binding: AuditBinding(),
      middlewares: [
        AuthMiddleware(),
        RoleMiddleware(allowedRoles: [UserRole.manager, UserRole.generalManager]),
      ],
    ),
    GetPage(
      name: AppRoutes.purchaseOrdersReport,
      page: () => const PurchaseOrdersReportView(),
      binding: ReportBinding(),
      middlewares: [AuthMiddleware(), ManagerAssistantMiddleware()],
    ),

    GetPage(
      name: AppRoutes.expensesReport,
      page: () => const ExpensesReportView(),
      binding: ReportBinding(),
      middlewares: [AuthMiddleware(), ManagerAssistantMiddleware()],
    ),

    // Profile
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),

    // Notifications
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsView(),
      binding: NotificationsBinding(),
      middlewares: [AuthMiddleware()],
    ),

    // User Management (Manager only)
    GetPage(
      name: AppRoutes.users,
      page: () => const UsersView(),
      binding: UserBinding(),
      middlewares: [AuthMiddleware(), ManagerOnlyMiddleware()],
    ),
    GetPage(
      name: AppRoutes.createUser,
      page: () => const CreateUserView(),
      binding: UserBinding(),
      middlewares: [AuthMiddleware(), ManagerOnlyMiddleware()],
    ),
    GetPage(
      name: AppRoutes.userDetails,
      page: () => const UserDetailsView(),
      binding: UserBinding(),
      middlewares: [AuthMiddleware(), ManagerOnlyMiddleware()],
    ),
    GetPage(
      name: AppRoutes.editUser,
      page: () => const EditUserView(),
      binding: UserBinding(),
      middlewares: [AuthMiddleware(), ManagerOnlyMiddleware()],
    ),
    // Change Password
    GetPage(
      name: AppRoutes.changePassword,
      page: () => const ChangePasswordView(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    // Change Requests
    GetPage(
      name: AppRoutes.changeRequests,
      page: () => const ChangeRequestsView(),
      binding: ChangeRequestBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.changeRequestDetails,
      page: () => const ChangeRequestDetailsView(),
      binding: ChangeRequestBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}

/// Auth middleware to check if user is authenticated
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Check if user is authenticated
    try {
      final storageService = Get.find<StorageService>();
      final token = storageService.getTokenSync();
      if (token == null || token.isEmpty) {
        return const RouteSettings(name: AppRoutes.login);
      }
    } catch (e) {
      // If there's an error accessing storage, redirect to login
      return const RouteSettings(name: AppRoutes.login);
    }

    return null;
  }
}
