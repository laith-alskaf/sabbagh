/// User role enum
enum UserRole {
  /// Manager role
  manager,

  /// Assistant manager role
  assistantManager,

  /// Employee role
  employee,

  /// Guest role
  guest,

  /// General manager role
  generalManager,

  /// Finance manager role
  financeManager,

  /// Procurement officer role
  procurementOfficer,

  /// Auditor role (read-only, can view reports and orders)
  auditor;

  /// Get role from string
  static UserRole fromString(String role) {
    switch (role) {
      case 'manager':
        return UserRole.manager;
      case 'assistant_manager':
        return UserRole.assistantManager;
      case 'employee':
        return UserRole.employee;
      case 'guest':
        return UserRole.guest;
      case 'general_manager':
        return UserRole.generalManager;
      case 'finance_manager':
        return UserRole.financeManager;
      case 'procurement_officer':
        return UserRole.procurementOfficer;
      case 'auditor':
        return UserRole.auditor;
      default:
        return UserRole.guest;
    }
  }

  /// Convert role to string
  String toApiString() {
    switch (this) {
      case UserRole.manager:
        return 'manager';
      case UserRole.assistantManager:
        return 'assistant_manager';
      case UserRole.employee:
        return 'employee';
      case UserRole.guest:
        return 'guest';
      case UserRole.generalManager:
        return 'general_manager';
      case UserRole.financeManager:
        return 'finance_manager';
      case UserRole.procurementOfficer:
        return 'procurement_officer';
      case UserRole.auditor:
        return 'auditor';
    }
  }

  /// Check if role can view purchase orders
  bool get canViewPurchaseOrders => true; // All roles can view purchase orders

  /// Check if role can create purchase orders
  bool get canCreatePurchaseOrders =>
      this == UserRole.manager ||
      this == UserRole.assistantManager ||
      this == UserRole.employee ||
      this == UserRole.financeManager ||
      this == UserRole.generalManager ||
      this == UserRole.procurementOfficer; // auditor cannot create

  /// Check if role can approve purchase orders
  bool get canApprovePurchaseOrders =>
      this == UserRole.manager || this == UserRole.assistantManager;

  /// Check if role can reject purchase orders
  bool get canRejectPurchaseOrders =>
      this == UserRole.manager || this == UserRole.assistantManager;

  /// Finance review capability
  bool get canFinanceReviewPurchaseOrders => this == UserRole.financeManager;

  /// General manager review capability
  bool get canGeneralManagerReviewPurchaseOrders =>
      this == UserRole.generalManager;

  /// Procurement update capability
  bool get canProcurementUpdate => this == UserRole.procurementOfficer;

  /// Check if role can create vendors
  bool get canCreateVendors => this == UserRole.manager;

  /// Check if role can request vendor creation
  bool get canRequestVendorCreation =>
      this == UserRole.assistantManager || this == UserRole.employee;

  /// Check if role can edit vendors
  bool get canEditVendors => this == UserRole.manager;

  /// Check if role can request vendor edit
  bool get canRequestVendorEdit =>
      this == UserRole.assistantManager || this == UserRole.employee;

  /// Check if role can delete vendors
  bool get canDeleteVendors => this == UserRole.manager;

  /// Check if role can create items
  bool get canCreateItems => this == UserRole.manager|| this == UserRole.assistantManager;

  /// Check if role can request item creation
  bool get canRequestItemCreation => this == UserRole.assistantManager;

  /// Check if role can edit items
  bool get canEditItems =>
      this == UserRole.assistantManager || this == UserRole.manager;

  /// Check if role can request item edit
  bool get canRequestItemEdit => this == UserRole.assistantManager;

  /// Check if role can delete items
  bool get canDeleteItems => this == UserRole.manager;

  /// Check if role can create users
  bool get canCreateUsers => this == UserRole.manager;

  /// Check if role can edit users
  bool get canEditUsers => this == UserRole.manager;

  /// Check if role can delete users
  bool get canDeleteUsers => this == UserRole.manager;

  /// Check if role can view reports
  bool get canViewReports =>
      this == UserRole.manager || this == UserRole.assistantManager;

  /// Check if role can export reports
  bool get canExportReports =>
      this == UserRole.manager || this == UserRole.assistantManager;

  /// Check if role needs approval for actions
  bool get needsApproval =>
      this == UserRole.assistantManager || this == UserRole.employee;

  /// Check if role can approve change requests
  bool get canApproveChangeRequests => this == UserRole.manager;

  /// Check if role can review change requests
  bool get canReviewChangeRequests =>
      this == UserRole.manager || this == UserRole.assistantManager;

  /// Check if role can get vendors
  bool get canGetVendors =>
      this == UserRole.manager || this == UserRole.assistantManager;
}
