import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_routes.dart';
import 'package:sabbagh_app/core/services/excel_export_service.dart';
import 'package:sabbagh_app/presentation/controllers/user_controller.dart';
import 'package:sabbagh_app/presentation/modules/reports/repository.dart';

/// Report type enum
enum ReportType {
  /// Purchase orders report
  purchaseOrders,

  /// Expenses report
  expenses,
}

/// Controller for reports
class ReportController extends GetxController {
  final ReportRepository _repository;
  final UserController _userController;

  /// Creates a new [ReportController]
  ReportController(this._repository, this._userController);

  /// Loading state
  final RxBool isLoading = false.obs;

  /// Error message
  final RxString errorMessage = ''.obs;

  /// Success message
  final RxString successMessage = ''.obs;

  /// Report data
  final Rx<Map<String, dynamic>> reportData = Rx<Map<String, dynamic>>({});

  /// Selected report type
  final Rx<ReportType> selectedReportType = ReportType.purchaseOrders.obs;

  /// Start date controller
  final TextEditingController startDateController = TextEditingController();

  /// End date controller
  final TextEditingController endDateController = TextEditingController();

  /// Vendor ID controller
  final TextEditingController vendorIdController = TextEditingController();

  /// Category controller
  final TextEditingController categoryController = TextEditingController();

  /// Department controller
  final TextEditingController departmentController = TextEditingController();

  /// Status controller
  final TextEditingController statusController = TextEditingController();

  /// Form key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  /// Start date
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);

  /// End date
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);

  /// Selected vendor ID
  final RxString selectedVendorId = ''.obs;

  /// Selected category
  final RxString selectedCategory = ''.obs;

  /// Selected department
  final RxString selectedDepartment = ''.obs;

  /// Selected status
  final RxString selectedStatus = ''.obs;

  /// Vendors list
  final RxList<Map<String, dynamic>> vendors = <Map<String, dynamic>>[].obs;

  /// Categories list
  final RxList<String> categories = <String>[].obs;

  /// Departments list
  final RxList<String> departments = <String>[].obs;

  /// Statuses list
  final RxList<String> statuses = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchVendors();
    fetchCategories();
    fetchDepartments();
    fetchStatuses();

    // Set default date range to current month
    final now = DateTime.now();
    startDate.value = DateTime(now.year, now.month, 1);
    endDate.value = DateTime(now.year, now.month + 1, 0);

    startDateController.text = _formatDate(startDate.value!);
    endDateController.text = _formatDate(endDate.value!);
  }

  @override
  void onClose() {
    startDateController.dispose();
    endDateController.dispose();
    vendorIdController.dispose();
    categoryController.dispose();
    departmentController.dispose();
    statusController.dispose();
    super.onClose();
  }

  /// Format date
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Fetch vendors
  Future<void> fetchVendors() async {
    try {
      final vendorsList = await _repository.getVendors();
      vendors.value = vendorsList;
    } catch (e) {
      // Set fallback vendors for testing
      vendors.value = [
        {'id': 'vendor-1', 'name': 'Test Vendor 1'},
        {'id': 'vendor-2', 'name': 'Test Vendor 2'},
      ];
    }
  }

  /// Fetch categories
  Future<void> fetchCategories() async {
    try {
      final categoriesList = await _repository.getCategories();
      categories.value = categoriesList;
    } catch (e) {
      // Set fallback categories
      categories.value = ['Dairy', 'Meat', 'Vegetables', 'Fruits', 'Other'];
    }
  }

  /// Fetch departments
  Future<void> fetchDepartments() async {
    try {
      final departmentsList = await _repository.getDepartments();
      departments.value = departmentsList;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch statuses
  Future<void> fetchStatuses() async {
    try {
      final statusesList = await _repository.getStatuses();
      statuses.value = statusesList;
    } catch (e) {
      // Set fallback statuses
      statuses.value = [
        'draft'
            'under_assistant_review',

        'under_manager_review',

        'in_progress',

        'completed',
      ];
    }
  }

  /// Generate report
  Future<void> generateReport() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    successMessage.value = '';

    try {
      final params = <String, dynamic>{
        'startDate': startDateController.text,
        'endDate': endDateController.text,
        'page': 1,
        'limit': 100, // Get more records for reports
      };

      if (selectedVendorId.value.isNotEmpty) {
        params['supplierId'] =
            selectedVendorId.value; // Backend expects 'supplierId'
      }

      if (selectedCategory.value.isNotEmpty) {
        params['category'] = selectedCategory.value;
      }

      if (selectedDepartment.value.isNotEmpty &&
          departments.contains(selectedDepartment.value)) {
        params['department'] = selectedDepartment.value;
      }

      if (selectedStatus.value.isNotEmpty &&
          statuses.contains(selectedStatus.value)) {
        params['status'] = selectedStatus.value;
      }

      switch (selectedReportType.value) {
        case ReportType.purchaseOrders:
          final data = await _repository.getPurchaseOrdersReport(params);
          reportData.value = data;
          break;
        case ReportType.expenses:
          final data = await _repository.getExpensesReport(params);
          reportData.value = data;
          break;
      }

      successMessage.value = 'report_generated'.tr;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Export report using local Excel generation
  Future<void> exportReport() async {
    if (reportData.value.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'no_report_data'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    successMessage.value = '';

    try {
      String filePath;

      switch (selectedReportType.value) {
        case ReportType.purchaseOrders:
          filePath = await ExcelExportService.exportPurchaseOrdersReport(
            reportData: reportData.value,
            startDate: startDateController.text,
            endDate: endDateController.text,
          );
          break;
        case ReportType.expenses:
          filePath = await ExcelExportService.exportExpensesReport(
            reportData: reportData.value,
            startDate: startDateController.text,
            endDate: endDateController.text,
          );
          break;
      }

      successMessage.value = 'report_exported'.tr;
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'error'.tr,
        'failed_to_export_report'.tr + ': ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Select start date
  Future<void> selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != startDate.value) {
      startDate.value = picked;
      startDateController.text = _formatDate(picked);
    }
  }

  /// Select end date
  Future<void> selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != endDate.value) {
      endDate.value = picked;
      endDateController.text = _formatDate(picked);
    }
  }

  /// Set report type
  void setReportType(ReportType type) {
    selectedReportType.value = type;
    reportData.value = {};
  }

  /// Navigate to purchase orders report
  void navigateToPurchaseOrdersReport() {
    setReportType(ReportType.purchaseOrders);
    Get.toNamed(AppRoutes.purchaseOrdersReport);
  }

  /// Navigate to expenses report
  void navigateToExpensesReport() {
    setReportType(ReportType.expenses);
    Get.toNamed(AppRoutes.expensesReport);
  }

  /// Check if user can view reports
  bool get canViewReports => _userController.canViewReports;

  /// Check if user can export reports
  bool get canExportReports => _userController.canExportReports;
}
