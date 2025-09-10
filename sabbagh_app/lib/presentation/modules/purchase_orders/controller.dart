import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sabbagh_app/core/constants/app_routes.dart';
import 'package:sabbagh_app/data/dto/purchase_order_dto.dart';
import 'package:sabbagh_app/domain/entities/item.dart';
import 'package:sabbagh_app/domain/entities/purchase_order.dart';
import 'package:sabbagh_app/domain/entities/purchase_order_item.dart';
import 'package:sabbagh_app/domain/entities/user_role.dart';
import 'package:sabbagh_app/presentation/controllers/user_controller.dart';
import 'package:sabbagh_app/presentation/modules/purchase_orders/repository.dart';
import 'package:sabbagh_app/domain/entities/purchase_order_note.dart';
import 'package:sabbagh_app/domain/entities/purchase_order_workflow.dart';

/// Simple dropdown item class
class DropdownItem {
  final String id;
  final String name;

  DropdownItem({required this.id, required this.name});
}

/// Controller for purchase orders with proper role-based access
class PurchaseOrderController extends GetxController {
  final PurchaseOrderRepository _repository;
  final UserController _userController;

  /// Creates a new [PurchaseOrderController]
  PurchaseOrderController(this._repository, this._userController);

  @override
  void onInit() {
    super.onInit();
    _initializeController();
  }

  Rx<TextEditingController> searchVendor = TextEditingController().obs;
  RxList<TextEditingController> searchItems = [TextEditingController()].obs;

  // Observable states
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<PurchaseOrder> purchaseOrders = <PurchaseOrder>[].obs;
  final Rx<PurchaseOrder?> selectedPurchaseOrder = Rx<PurchaseOrder?>(null);

  // Filter and search states
  final RxString searchQuery = ''.obs;
  final RxString statusFilter = ''.obs;
  final RxString departmentFilter = ''.obs;
  final RxString sortBy = 'request_date'.obs;
  final RxString sortOrder = 'desc'.obs;

  // Pagination states
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt itemsPerPage = 10.obs;
  final RxInt totalItems = 0.obs;
  List<Item> purchaseOrderItems = <Item>[];
  // Form states
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final RxMap<String, dynamic> formData = <String, dynamic>{}.obs;
  final TextEditingController rejectionReasonController =
      TextEditingController();
  Rx<TextEditingController> requestDate = TextEditingController().obs;
  Rx<TextEditingController> executionDate = TextEditingController().obs;
  final RxList<Map<String, dynamic>> formItems = <Map<String, dynamic>>[].obs;

  // Images state
  final RxList<File> pickedImages = <File>[].obs;
  final RxList<String> existingImageUrls = <String>[].obs;
  final ImagePicker _picker = ImagePicker();

  /// Pick multiple images (up to 5 total)
  Future<void> pickImages() async {
    try {
      final remaining = 5 - pickedImages.length;
      if (remaining <= 0) {
        _showErrorSnackbar('max_attachments_reached'.trParams({'count': '5'}));
        return;
      }
      final images = await _picker.pickMultiImage();
      if (images.isEmpty) return;
      // Add up to remaining
      final files = images.take(remaining).map((x) => File(x.path)).toList();
      pickedImages.addAll(files);
    } catch (_) {
      _showErrorSnackbar('failed_to_pick_images'.tr);
    }
  }

  /// Remove picked image by index
  void removePickedImage(int index) {
    if (index >= 0 && index < pickedImages.length) {
      pickedImages.removeAt(index);
    }
  }

  // Master data for dropdowns
  final RxList<DropdownItem> departments = <DropdownItem>[].obs;
  final RxList<DropdownItem> suppliers = <DropdownItem>[].obs;
  final RxList<String> items = <String>[].obs;
  final RxBool isDepartmentsLoading = false.obs;
  final RxBool isSuppliersLoading = false.obs;
  final RxBool isItemsLoading = false.obs;

  // View mode for different user roles
  final RxString currentViewMode =
      'all'.obs; // 'all', 'my', 'pending_assistant', 'pending_manager'

  // ===== Notes state =====
  final RxList<PurchaseOrderNote> notes = <PurchaseOrderNote>[].obs;
  final RxBool isNotesLoading = false.obs;
  final RxBool isAddingNote = false.obs;
  final TextEditingController noteController = TextEditingController();

  // ===== Workflow state =====
  final RxList<PurchaseOrderWorkflowStep> workflow = <PurchaseOrderWorkflowStep>[].obs;
  final RxBool isWorkflowLoading = false.obs;

  /// Get user controller
  UserController get userController => _userController;

  /// Initialize form for creating new purchase order
  /// Only essential fields are required at creation time
  void initializeCreateForm() {
    formData.value = {
      // Required fields for creation (request_date will be set automatically when submitting)
      'department': '',
      'request_type': 'purchase',
      // Optional fields
      'notes': null,
    };
    formItems.clear();

    // Reset images state
    pickedImages.clear();

    // Add a default item with minimal required fields
    addFormItem();
  }

  /// Add a new form item with minimal required fields for creation
  void addFormItem() {
    formItems.add({
      // Required fields for items at creation time
      'quantity': 1.0,
      'unit': 'piece',
      // Optional fields (can be filled during creation)
      'item_name': null,
      // Fields that will be added during editing after approval
      'item_id': null,
      'item_code': null,
      'price': null,
      'currency': null,
      'received_quantity': null,
      'line_total': null,
    });
    searchItems.add(TextEditingController());
  }

  /// Remove form item at index
  void removeFormItem(int index) {
    if (formItems.length > 1 && index >= 0 && index < formItems.length) {
      searchItems.removeAt(index);
      formItems.removeAt(index);
    }
  }

  /// Initialize form for editing existing purchase order
  /// All fields are available for editing until order is completed
  void initializeEditForm(PurchaseOrder order) {
    requestDate.value.text = order.requestDate.toString();
    formData.value = {
      // Basic required fields
      'request_date': order.requestDate,
      'department': order.department,
      'request_type': order.type,
      'requester_name': order.requesterName,
      // Additional fields that can be edited
      'notes': order.notes,
      'supplier_id': order.vendorId,
      'execution_date': order.executionDate,
      'currency': order.currency,
      'total_amount': order.totalAmount,
      'attachment_url': order.attachmentUrls,
    };

    // Load existing images
    existingImageUrls.assignAll(order.attachmentUrls);

    // Load items
    formItems.clear();
    searchItems.clear();
    for (var item in order.items) {
      formItems.add({
        'item_id': item.itemId,
        'item_name': item.itemName,
        'item_code': item.itemCode,
        'quantity': item.quantity,
        'unit': item.unit,
        'currency': item.currency,
        'price': item.price,
        'received_quantity': item.receivedQuantity,
        'line_total': item.lineTotal,
      });
      searchItems.add(TextEditingController(text: item.itemName));
    }

    // If no items, add a default one
    if (formItems.isEmpty) {
      addFormItem();
    }
  }

  /// Extract uploader userId from a Cloudinary URL built as folderName/userId/uuid
  String? extractUserIdFromAttachmentUrl(String url) {
    try {
      final parts = url.split('/');
      if (parts.isEmpty) return null;
      final publicIdPart = parts.last.split('.').first; // folder/userId/uuid
      final segments = publicIdPart.split('/');
      if (segments.length < 3) return null;
      // [folderName, userId, uuid]
      return segments[1];
    } catch (_) {
      return null;
    }
  }

  /// Resolve uploader name for given URL (memoized per controller lifetime)
  final Map<String, String> _uploaderNameCache = {};
  Future<String?> resolveUploaderName(String url) async {
    final cached = _uploaderNameCache[url];
    if (cached != null) return cached;
    final userId = extractUserIdFromAttachmentUrl(url);
    if (userId == null) return null;
    try {
      final name = await _repository.getUserNameById(userId);
      if (name != null) {
        _uploaderNameCache[url] = name;
      }
      return name;
    } catch (_) {
      return null;
    }
  }

  @override
  void onClose() {
    rejectionReasonController.dispose();
    noteController.dispose();
    super.onClose();
  }

  /// Initialize controller based on user role
  void _initializeController() {
    _setDefaultViewMode();
    loadDepartments();
    loadSuppliers();
    loadItems();
    fetchPurchaseOrders();
  }

  /// Set default view mode based on user role
  void _setDefaultViewMode() {
    if (_userController.isEmployee ||
        _userController.isFinanceManager ||
        _userController.isGeneralManager ||
        _userController.isProcurementOfficer) {
      currentViewMode.value = 'my';
    } else if (_userController.isManager ||
        _userController.isAssistantManager ||
        _userController.isAuditor) {
      currentViewMode.value = 'all';
    }
  }

  /// Fetch purchase orders based on current view mode
  Future<void> fetchPurchaseOrders() async {
    isLoading.value = true;

    try {
      List<PurchaseOrder> orders;
      final offset = (currentPage.value - 1) * itemsPerPage.value;

      switch (currentViewMode.value) {
        case 'my':
          orders = await _repository.getMyPurchaseOrders(
            status: statusFilter.value.isEmpty ? null : statusFilter.value,
            limit: itemsPerPage.value,
            offset: offset,
          );
          break;

        case 'pending_assistant':
          if (!canAssistantApprovePurchaseOrders) {
            orders = [];
            break;
          }
          orders = await _repository.getPurchaseOrdersPendingAssistantReview(
            limit: itemsPerPage.value,
            offset: offset,
          );
          break;

        case 'pending_manager':
          if (!canManagerApprovePurchaseOrders) {
            orders = [];
            break;
          }
          orders = await _repository.getPurchaseOrdersPendingManagerReview(
            limit: itemsPerPage.value,
            offset: offset,
          );
          break;

        case 'all':
        default:
          if (_userController.isEmployee) {
            // Employees can only see their own orders
            orders = await _repository.getMyPurchaseOrders(
              status: statusFilter.value.isEmpty ? null : statusFilter.value,
              limit: itemsPerPage.value,
              offset: offset,
            );
          } else if (_userController.isAuditor) {
            orders = await _repository.getMyPurchaseOrders(
              status: 'completed',
              limit: itemsPerPage.value,
              offset: offset,
            );
          } else {
            // Managers and assistant managers can see all orders
            orders = await _repository.getPurchaseOrders(
              status: statusFilter.value.isEmpty ? null : statusFilter.value,
              department:
                  departmentFilter.value.isEmpty
                      ? null
                      : departmentFilter.value,
              limit: itemsPerPage.value,
              offset: offset,
            );
          }
          break;
      }

      purchaseOrders.value = orders;
      totalItems.value =
          orders.length; // Note: Backend should provide total count
      _updatePagination();
    } catch (e) {
      _showErrorSnackbar('failed_to_load_purchase_orders'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  /// Change view mode
  void changeViewMode(String mode) {
    if (currentViewMode.value != mode) {
      currentViewMode.value = mode;
      currentPage.value = 1;
      statusFilter.value = '';
      departmentFilter.value = '';
      fetchPurchaseOrders();
    }
  }

  /// Get purchase order by ID
  Future<void> getPurchaseOrderById(String id) async {
    isLoading.value = true;

    try {
      final order = await _repository.getPurchaseOrderById(id);
      selectedPurchaseOrder.value = order;
      // Load notes after loading order
      await fetchNotes(id);
      // Load workflow if auditor and order is completed
      await fetchWorkflowIfAllowed(id);
    } catch (e) {
      _showErrorSnackbar('failed_to_load_purchase_order'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  /// Permission: who can view notes?
  bool canViewNotes(PurchaseOrder order) {
    final role = _userController.role;
    switch (role) {
      case UserRole.manager:
      case UserRole.assistantManager:
      case UserRole.generalManager:
        return true; // can view any time
      case UserRole.financeManager:
        return order.status == PurchaseOrderStatus.underFinanceReview;
      case UserRole.auditor:
        return order.status == PurchaseOrderStatus.completed;
      default:
        return false;
    }
  }

  /// Permission: who can add notes?
  bool canAddNote(PurchaseOrder order) {
    final role = _userController.role;
    switch (role) {
      case UserRole.financeManager:
        return order.status == PurchaseOrderStatus.underFinanceReview;
      case UserRole.generalManager:
        return order.status == PurchaseOrderStatus.underGeneralManagerReview;
      case UserRole.auditor:
        return order.status == PurchaseOrderStatus.completed;
      default:
        return false;
    }
  }

  /// Fetch notes for order
  Future<void> fetchNotes(String orderId) async {
    isNotesLoading.value = true;
    try {
      final order = selectedPurchaseOrder.value;
      if (order == null || !canViewNotes(order)) {
        notes.clear();
        return;
      }
      final list = await _repository.getPurchaseOrderNotes(orderId);
      notes.assignAll(list);
    } catch (e) {
      // Silent fail shows empty list
      notes.clear();
    } finally {
      isNotesLoading.value = false;
    }
  }

  /// Fetch workflow for completed orders if role allows (auditor and managers per backend)
  Future<void> fetchWorkflowIfAllowed(String orderId) async {
    final order = selectedPurchaseOrder.value;
    if (order == null) return;

    // Only show workflow for completed orders
    if (order.status != PurchaseOrderStatus.completed) {
      workflow.clear();
      return;
    }

    // Role check: auditor, general manager, manager, assistant manager
    if (!(_userController.isAuditor ||
        _userController.isGeneralManager ||
        _userController.isManager ||
        _userController.isAssistantManager)) {
      workflow.clear();
      return;
    }

    isWorkflowLoading.value = true;
    try {
      final steps = await _repository.getPurchaseOrderWorkflow(orderId);
      workflow.assignAll(steps);
    } catch (_) {
      workflow.clear();
    } finally {
      isWorkflowLoading.value = false;
    }
  }

  /// Add a note
  Future<void> submitNote(String orderId) async {
    final order = selectedPurchaseOrder.value;
    if (order == null) return;
    if (!canAddNote(order)) {
      _showErrorSnackbar('no_permission_for_this_action'.tr);
      return;
    }
    final text = noteController.text.trim();
    if (text.isEmpty) {
      _showErrorSnackbar('note_required'.tr);
      return;
    }
    isAddingNote.value = true;
    try {
      final note = await _repository.addPurchaseOrderNote(orderId, text);
      noteController.clear();
      notes.add(note);
      _showSuccessSnackbar('note_added_successfully'.tr);
    } catch (e) {
      _showErrorSnackbar('failed_to_add_note'.tr);
    } finally {
      isAddingNote.value = false;
    }
  }

  /// Create purchase order with form data
  Future<void> createPurchaseOrder() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Validate that at least one item exists
    if (formItems.isEmpty) {
      _showErrorSnackbar('at_least_one_item_required'.tr);
      return;
    }

    isSubmitting.value = true;

    try {
      // Prepare data for backend
      final now = DateTime.now();
      final data = {
        // Required fields - set automatically
        'request_date': now.toIso8601String(),
        'requester_name': _userController.user.value?.name ?? '',
        // Required fields from form
        'department': formData['department'],
        'request_type': formData['request_type'],
        // Optional fields
        'notes': formData['notes'],
        // Items
        'items':
            formItems
                .map(
                  (item) => {
                    'quantity': item['quantity'],
                    'unit': item['unit'],
                    'item_name': item['item_name'],
                    if (item['price'] != null) 'price': item['price'],
                    if (item['currency'] != null) 'currency': item['currency'],
                    if (item['item_code'] != null)
                      'item_code': item['item_code'],
                  },
                )
                .toList(),
      };

      final order = await _repository.createPurchaseOrder(
        data,
        images: pickedImages,
      );
      _showSuccessSnackbar('purchase_order_created_and_submitted'.tr);

      // Navigate to purchase order details
      Get.offNamed(AppRoutes.purchaseOrderDetails.replaceAll(':id', order.id));

      // Refresh the list
      fetchPurchaseOrders();
    } catch (e) {
      _showErrorSnackbar('failed_to_create_purchase_order'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===== Phase 2: New workflow controller actions =====

  Future<void> routePurchaseOrder(
    String id, {
    required String next,
    String? notes,
  }) async {
    isSubmitting.value = true;
    try {
      final order = await _repository.routePurchaseOrder(
        id,
        next: next, // 'finance' | 'gm' | 'procurement'
        notes: notes,
      );
      selectedPurchaseOrder.value = order;
      _showSuccessSnackbar('purchase_order_routed_successfully'.tr);
      fetchPurchaseOrders();
    } catch (e) {
      _showErrorSnackbar('failed_to_route_purchase_order'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> financeApprove(String id) async {
    isSubmitting.value = true;
    try {
      final order = await _repository.financeApprove(id);
      selectedPurchaseOrder.value = order;
      _showSuccessSnackbar('finance_approved_successfully'.tr);
      fetchPurchaseOrders();
    } catch (e) {
      _showErrorSnackbar('failed_to_approve_by_finance'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> financeReject(String id, String reason) async {
    isSubmitting.value = true;
    try {
      final order = await _repository.financeReject(id, reason);
      selectedPurchaseOrder.value = order;
      _showSuccessSnackbar('finance_rejected_successfully'.tr);
      fetchPurchaseOrders();
    } catch (e) {
      _showErrorSnackbar('failed_to_reject_by_finance'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> generalManagerApprove(String id) async {
    isSubmitting.value = true;
    try {
      final order = await _repository.generalManagerApprove(id);
      selectedPurchaseOrder.value = order;
      _showSuccessSnackbar('gm_approved_successfully'.tr);
      fetchPurchaseOrders();
    } catch (e) {
      _showErrorSnackbar('failed_to_approve_by_gm'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> generalManagerReject(String id, String reason) async {
    isSubmitting.value = true;
    try {
      final order = await _repository.generalManagerReject(id, reason);
      selectedPurchaseOrder.value = order;
      _showSuccessSnackbar('gm_rejected_successfully'.tr);
      fetchPurchaseOrders();
    } catch (e) {
      _showErrorSnackbar('failed_to_reject_by_gm'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> procurementUpdate(
    String id, {
    required List<Map<String, dynamic>> items,
    List<File> images = const [],
  }) async {
    isSubmitting.value = true;
    try {
      final order = await _repository.procurementUpdate(
        id,
        items: items,
        images: images,
      );
      selectedPurchaseOrder.value = order;
      _showSuccessSnackbar('procurement_updated_successfully'.tr);
      fetchPurchaseOrders();
    } catch (e) {
      _showErrorSnackbar('failed_to_update_procurement'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> returnToManagerForFinalReview(String id) async {
    isSubmitting.value = true;
    try {
      final order = await _repository.returnToManagerForFinalReview(id);
      selectedPurchaseOrder.value = order;
      _showSuccessSnackbar('returned_to_manager_successfully'.tr);
      fetchPurchaseOrders();
    } catch (e) {
      _showErrorSnackbar('failed_to_return_to_manager'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> managerFinalApprove(String id) async {
    isSubmitting.value = true;
    try {
      final order = await _repository.managerFinalApprove(id);
      selectedPurchaseOrder.value = order;
      _showSuccessSnackbar('final_approved_successfully'.tr);
      fetchPurchaseOrders();
    } catch (e) {
      _showErrorSnackbar('failed_to_final_approve'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> managerFinalReject(String id, String reason) async {
    isSubmitting.value = true;
    try {
      final order = await _repository.managerFinalReject(id, reason);
      selectedPurchaseOrder.value = order;
      _showSuccessSnackbar('final_rejected_successfully'.tr);
      fetchPurchaseOrders();
    } catch (e) {
      _showErrorSnackbar('failed_to_final_reject'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Update purchase order
  Future<void> updatePurchaseOrder(String id, Map<String, dynamic> data) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isSubmitting.value = true;

    try {
      final order = await _repository.updatePurchaseOrder(
        id,
        data,
        images: pickedImages,
      );
      selectedPurchaseOrder.value = order;
      Get.back();
      Get.back();
      _showSuccessSnackbar('purchase_order_updated'.tr);

      // Refresh the list
      fetchPurchaseOrders();
    } catch (e) {
      _showErrorSnackbar('failed_to_update_purchase_order'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Delete purchase order
  Future<void> deletePurchaseOrder(String id) async {
    isSubmitting.value = true;

    try {
      final success = await _repository.deletePurchaseOrder(id);
      if (success) {
        purchaseOrders.removeWhere((order) => order.id == id);
        _showSuccessSnackbar('purchase_order_deleted'.tr);
        Get.back(); // Go back from details screen
      } else {
        _showErrorSnackbar('failed_to_delete_purchase_order'.tr);
      }
    } catch (e) {
      _showErrorSnackbar('failed_to_delete_purchase_order'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Submit purchase order for review
  Future<void> submitPurchaseOrder(String id) async {
    isSubmitting.value = true;

    try {
      final order = await _repository.submitPurchaseOrder(id);
      selectedPurchaseOrder.value = order;
      _showSuccessSnackbar('purchase_order_submitted'.tr);
      Get.back();
      // Refresh the list
      fetchPurchaseOrders();
    } catch (e) {
      _showErrorSnackbar('failed_to_submit_purchase_order'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Assistant approve purchase order
  Future<void> assistantApprovePurchaseOrder(String id, {String? notes}) async {
    isSubmitting.value = true;

    try {
      final order = await _repository.assistantApprovePurchaseOrder(
        id,
        notes: notes,
      );
      selectedPurchaseOrder.value = order;
      _showSuccessSnackbar('purchase_order_approved'.tr);
      Get.back();
      // Refresh the list
      fetchPurchaseOrders();
    } catch (e) {
      _showErrorSnackbar('failed_to_approve_purchase_order'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Manager approve purchase order
  Future<void> managerApprovePurchaseOrder(String id, {String? notes}) async {
    isSubmitting.value = true;

    try {
      final order = await _repository.managerApprovePurchaseOrder(
        id,
        notes: notes,
      );
      selectedPurchaseOrder.value = order;
      _showSuccessSnackbar('purchase_order_approved'.tr);
      Get.back();
      // Refresh the list
      fetchPurchaseOrders();
    } catch (e) {
      _showErrorSnackbar('failed_to_approve_purchase_order'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Assistant reject purchase order
  Future<void> assistantRejectPurchaseOrder(String id) async {
    if (rejectionReasonController.text.trim().isEmpty) {
      _showErrorSnackbar('rejection_reason_required'.tr);
      return;
    }

    isSubmitting.value = true;

    try {
      final order = await _repository.assistantRejectPurchaseOrder(
        id,
        rejectionReasonController.text.trim(),
      );
      selectedPurchaseOrder.value = order;
      _showSuccessSnackbar('purchase_order_rejected'.tr);

      // Clear the reason and close dialog
      rejectionReasonController.clear();
      Get.back();

      // Refresh the list
      fetchPurchaseOrders();
    } catch (e) {
      _showErrorSnackbar('failed_to_reject_purchase_order'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Manager reject purchase order
  Future<void> managerRejectPurchaseOrder(String id) async {
    if (rejectionReasonController.text.trim().isEmpty) {
      _showErrorSnackbar('rejection_reason_required'.tr);
      return;
    }

    isSubmitting.value = true;

    try {
      final order = await _repository.managerRejectPurchaseOrder(
        id,
        rejectionReasonController.text.trim(),
      );
      selectedPurchaseOrder.value = order;
      _showSuccessSnackbar('purchase_order_rejected'.tr);

      // Clear the reason and close dialog
      rejectionReasonController.clear();
      Get.back();

      // Refresh the list
      fetchPurchaseOrders();
    } catch (e) {
      _showErrorSnackbar('failed_to_reject_purchase_order'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Complete purchase order
  Future<void> completePurchaseOrder(String id) async {
    isSubmitting.value = true;

    try {
      final order = await _repository.completePurchaseOrder(id);
      selectedPurchaseOrder.value = order;
      _showSuccessSnackbar('purchase_order_completed'.tr);

      // Refresh the list
      fetchPurchaseOrders();
    } catch (e) {
      _showErrorSnackbar('failed_to_complete_purchase_order'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Load departments from backend
  Future<void> loadDepartments() async {
    isDepartmentsLoading.value = true;

    try {
      final departmentsList = await _repository.getDepartments();
      departments.value =
          departmentsList
              .map(
                (dept) => DropdownItem(
                  id: dept['id'].toString(),
                  name: dept['name'].toString(),
                ),
              )
              .toList();
    } catch (e) {
      rethrow;
    } finally {
      isDepartmentsLoading.value = false;
    }
  }

  /// Load suppliers from backend
  Future<void> loadSuppliers() async {
    if (userController.canGetVendors) {
      isSuppliersLoading.value = true;

      try {
        final suppliersList = await _repository.getSuppliers();
        suppliers.value =
            suppliersList
                .map(
                  (supplier) => DropdownItem(
                    id: supplier['id'].toString(),
                    name: supplier['name'].toString(),
                  ),
                )
                .toList();
      } catch (e) {
        rethrow;
      } finally {
        isSuppliersLoading.value = false;
      }
    }
  }

  /// Load items from backend
  Future<void> loadItems({String? search}) async {
    isItemsLoading.value = true;

    try {
      final itemsList = await _repository.getItems(search: search);
      purchaseOrderItems =
          itemsList.map((item) => Item.fromJson(item)).toList();
      items.value = itemsList.map((item) => item['name'].toString()).toList();
    } catch (e) {
      rethrow;
    } finally {
      isItemsLoading.value = false;
    }
  }

  /// Search purchase orders
  void searchPurchaseOrders(String query) {
    searchQuery.value = query;
    currentPage.value = 1;
    // Note: Backend doesn't support text search yet, so we'll filter locally
    // TODO: Implement when backend supports search
    fetchPurchaseOrders();
  }

  /// Filter by status
  void filterByStatus(String status) {
    statusFilter.value = status;
    currentPage.value = 1;
    fetchPurchaseOrders();
  }

  /// Filter by department
  void filterByDepartment(String department) {
    departmentFilter.value = department;
    currentPage.value = 1;
    fetchPurchaseOrders();
  }

  /// Clear all filters
  void clearFilters() {
    statusFilter.value = '';
    departmentFilter.value = '';
    searchQuery.value = '';
    currentPage.value = 1;
    fetchPurchaseOrders();
  }

  /// Pagination methods
  void goToPage(int page) {
    if (page >= 1 && page <= totalPages.value) {
      currentPage.value = page;
      fetchPurchaseOrders();
    }
  }

  void nextPage() {
    if (currentPage.value < totalPages.value) {
      currentPage.value++;
      fetchPurchaseOrders();
    }
  }

  void previousPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
      fetchPurchaseOrders();
    }
  }

  /// Refresh purchase orders
  Future<void> refreshPurchaseOrders() async {
    await fetchPurchaseOrders();
  }

  /// Navigation methods
  void navigateToCreatePurchaseOrder() {
    Get.toNamed(AppRoutes.createPurchaseOrder);
  }

  void navigateToPurchaseOrderDetails(String id) {
    Get.toNamed(AppRoutes.purchaseOrderDetails.replaceAll(':id', id));
  }

  // Permission checks based on user role and purchase order status

  /// Check if user can create purchase orders
  bool get canCreatePurchaseOrders => _userController.canCreatePurchaseOrders;

  /// Check if user can assistant approve purchase orders
  bool get canAssistantApprovePurchaseOrders =>
      _userController.isAssistantManager;

  /// Check if user can manager approve purchase orders
  bool get canManagerApprovePurchaseOrders => _userController.isManager;

  /// Check if user can reject purchase orders
  bool get canRejectPurchaseOrders =>
      _userController.isAssistantManager || _userController.isManager;

  /// Check if user can edit purchase order
  bool canEditPurchaseOrder(PurchaseOrder order) {
    // Only the creator can edit draft orders
    if (order.status == PurchaseOrderStatus.draft) {
      return order.requesterId == _userController.user.value?.id;
    }
    // Managers can edit in-progress orders
    if ((order.status == PurchaseOrderStatus.underAssistantReview ||
            order.status == PurchaseOrderStatus.underManagerReview ||
            order.status == PurchaseOrderStatus.returnedToManagerReview) &&
        (_userController.isManager || _userController.isAssistantManager)) {
      return true;
    }
    return false;
  }

  /// Check if user can delete purchase order
  bool canDeletePurchaseOrder(PurchaseOrder order) {
    // Only the creator can delete draft orders
    return order.status == PurchaseOrderStatus.draft &&
        order.requesterId == _userController.user.value?.id;
  }

  /// Check if user can submit purchase order
  bool canSubmitPurchaseOrder(PurchaseOrder order) {
    // Only the creator can submit draft orders
    return order.status == PurchaseOrderStatus.draft &&
        order.requesterId == _userController.user.value?.id;
  }

  /// Check if user can assistant approve specific purchase order
  bool canAssistantApprovePurchaseOrderStatus(PurchaseOrder order) {
    return order.status == PurchaseOrderStatus.underAssistantReview &&
        canAssistantApprovePurchaseOrders;
  }

  /// Check if user can manager approve specific purchase order
  bool canManagerApprovePurchaseOrderStatus(PurchaseOrder order) {
    return order.status == PurchaseOrderStatus.underManagerReview &&
        canManagerApprovePurchaseOrders;
  }

  /// Check if user can reject specific purchase order
  bool canRejectPurchaseOrderStatus(PurchaseOrder order) {
    // return (order.status == PurchaseOrderStatus.underAssistantReview ||
    //         order.status == PurchaseOrderStatus.underManagerReview) &&
    //     canRejectPurchaseOrders;
    return (order.status == PurchaseOrderStatus.underAssistantReview &&
            _userController.isAssistantManager) ||
        (order.status == PurchaseOrderStatus.underManagerReview &&
            _userController.isManager);
  }

  /// Check if user can complete purchase order
  bool canCompletePurchaseOrder(PurchaseOrder order) {
    return order.status == PurchaseOrderStatus.inProgress &&
        (_userController.isManager || _userController.isAssistantManager);
  }

  /// Check if user can approve purchase order
  bool canApprovePurchaseOrder(PurchaseOrder order) {
    if (_userController.isAssistantManager) {
      return order.status == PurchaseOrderStatus.underAssistantReview;
    }

    if (_userController.isManager) {
      return order.status == PurchaseOrderStatus.underManagerReview;
    }

    return false;
  }

  // Available view modes based on user role
  List<Map<String, String>> get availableViewModes {
    final modes = <Map<String, String>>[];

    if (_userController.isEmployee) {
      modes.add({'key': 'my', 'label': 'my_purchase_orders'.tr});
    } else {
      modes.add({'key': 'all', 'label': 'all_purchase_orders'.tr});

      if (_userController.isAssistantManager || _userController.isManager) {
        modes.add({
          'key': 'pending_assistant',
          'label': 'pending_assistant_review'.tr,
        });
      }

      if (_userController.isManager) {
        modes.add({
          'key': 'pending_manager',
          'label': 'pending_manager_review'.tr,
        });
      }
    }

    return modes;
  }

  // Private helper methods

  void _updatePagination() {
    totalPages.value = (totalItems.value / itemsPerPage.value).ceil();
    if (totalPages.value == 0) totalPages.value = 1;
  }

  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'success'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.primary,
      colorText: Get.theme.colorScheme.onPrimary,
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'error'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
    );
  }
}
