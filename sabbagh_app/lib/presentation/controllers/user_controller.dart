import 'package:get/get.dart';
import 'package:sabbagh_app/core/services/storage_service.dart';
import 'package:sabbagh_app/domain/entities/user.dart';
import 'package:sabbagh_app/domain/entities/user_role.dart';

/// Controller for managing the current user
class UserController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  
  /// Current user
  final Rx<User?> user = Rx<User?>(null);
  
  @override
  void onInit() {
    super.onInit();
    _loadUser();
  }
  
  /// Load user from storage
  Future<void> _loadUser() async {
    final userData = await _storageService.getUser();
    if (userData != null) {
      user.value = User.fromJson(userData);
    }
  }
  
  /// Set user
  Future<void> setUser(User user) async {
    this.user.value = user;
    await _storageService.saveUser(user.toJson());
  }
  
  /// Clear user
  Future<void> clearUser() async {
    user.value = null;
    await _storageService.clearUser();
  }
  
  /// Check if user is authenticated
  bool get isAuthenticated => user.value != null;
  
  /// Get user role
  UserRole get role {
    try {
      return user.value?.role ?? UserRole.guest;
    } catch (e) {
      return UserRole.guest;
    }
  }
  
  /// Check if user is manager
  bool get isManager => role == UserRole.manager;
  
  /// Check if user is assistant manager
  bool get isAssistantManager => role == UserRole.assistantManager;
  
  /// Check if user is employee
  bool get isEmployee => role == UserRole.employee;
  
  /// Check if user is guest
  bool get isGuest => role == UserRole.guest;
  
  /// Check if user is finance manager
  bool get isFinanceManager => role == UserRole.financeManager;

  /// Check if user is general manager
  bool get isGeneralManager => role == UserRole.generalManager;

  /// Check if user is procurement officer
  bool get isProcurementOfficer => role == UserRole.procurementOfficer;

  /// Check if user is auditor
  bool get isAuditor => role == UserRole.auditor;
  
  /// Check if user can view purchase orders
  bool get canViewPurchaseOrders => role.canViewPurchaseOrders;
  
  /// Check if user can create purchase orders
  bool get canCreatePurchaseOrders => role.canCreatePurchaseOrders;
  
  /// Check if user can approve purchase orders
  bool get canApprovePurchaseOrders => role.canApprovePurchaseOrders;
  
  /// Check if user can reject purchase orders
  bool get canRejectPurchaseOrders => role.canRejectPurchaseOrders;
  
  /// Check if user can create vendors
  bool get canCreateVendors => role.canCreateVendors;
  
  /// Check if user can request vendor creation
  bool get canRequestVendorCreation => role.canRequestVendorCreation;
  
  /// Check if user can edit vendors
  bool get canEditVendors => role.canEditVendors;
  
  /// Check if user can request vendor edit
  bool get canRequestVendorEdit => role.canRequestVendorEdit;
  
  /// Check if user can delete vendors
  bool get canDeleteVendors => role.canDeleteVendors;
  
  /// Check if user can create items
  bool get canCreateItems => role.canCreateItems;
  
  /// Check if user can request item creation
  bool get canRequestItemCreation => role.canRequestItemCreation;
  
  /// Check if user can edit items
  bool get canEditItems => role.canEditItems;
  
  
  /// Check if user can delete items
  bool get canDeleteItems => role.canDeleteItems;
  
  /// Check if user can create users
  bool get canCreateUsers => role.canCreateUsers;
  
  /// Check if user can edit users
  bool get canEditUsers => role.canEditUsers;
  
  /// Check if user can delete users
  bool get canDeleteUsers => role.canDeleteUsers;
  
  /// Check if user can view reports
  bool get canViewReports => role.canViewReports;
  
  /// Check if user can export reports
  bool get canExportReports => role.canExportReports;
  
  /// Check if user needs approval for actions
  bool get needsApproval => role.needsApproval;
  
  /// Check if user can approve change requests
  bool get canApproveChangeRequests => role.canApproveChangeRequests;
  
  /// Check if user can review change requests
  bool get canReviewChangeRequests => role.canReviewChangeRequests;

    /// Check if user can get vendors
  bool get canGetVendors => role.canGetVendors;
}