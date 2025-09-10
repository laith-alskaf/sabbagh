import 'package:sabbagh_app/domain/entities/purchase_order_item.dart';

/// Purchase order status enum
enum PurchaseOrderStatus {
  /// Draft status
  draft,

  /// Under assistant review status
  underAssistantReview,

  /// Rejected by assistant status
  rejectedByAssistant,

  /// Under manager review status
  underManagerReview,

  /// Rejected by manager status
  rejectedByManager,

  /// In progress status
  inProgress,

  /// Completed status
  completed,

  /// Under finance review status
  underFinanceReview,

  /// Rejected by finance status
  rejectedByFinance,

  /// Under general manager review status
  underGeneralManagerReview,

  /// Rejected by general manager status
  rejectedByGeneralManager,

  /// Pending procurement status
  pendingProcurement,

  /// Returned to manager for final review
  returnedToManagerReview;

  /// Get status from string
  static PurchaseOrderStatus fromString(String status) {
    switch (status) {
      case 'draft':
        return PurchaseOrderStatus.draft;
      case 'under_assistant_review':
        return PurchaseOrderStatus.underAssistantReview;
      case 'rejected_by_assistant':
        return PurchaseOrderStatus.rejectedByAssistant;
      case 'under_manager_review':
        return PurchaseOrderStatus.underManagerReview;
      case 'rejected_by_manager':
        return PurchaseOrderStatus.rejectedByManager;
      case 'in_progress':
        return PurchaseOrderStatus.inProgress;
      case 'completed':
        return PurchaseOrderStatus.completed;
      case 'under_finance_review':
        return PurchaseOrderStatus.underFinanceReview;
      case 'rejected_by_finance':
        return PurchaseOrderStatus.rejectedByFinance;
      case 'under_general_manager_review':
        return PurchaseOrderStatus.underGeneralManagerReview;
      case 'rejected_by_general_manager':
        return PurchaseOrderStatus.rejectedByGeneralManager;
      case 'pending_procurement':
        return PurchaseOrderStatus.pendingProcurement;
      case 'returned_to_manager_review':
        return PurchaseOrderStatus.returnedToManagerReview;
      default:
        return PurchaseOrderStatus.draft;
    }
  }

  /// Convert status to string
  String toApiString() {
    switch (this) {
      case PurchaseOrderStatus.draft:
        return 'draft';
      case PurchaseOrderStatus.underAssistantReview:
        return 'under_assistant_review';
      case PurchaseOrderStatus.rejectedByAssistant:
        return 'rejected_by_assistant';
      case PurchaseOrderStatus.underManagerReview:
        return 'under_manager_review';
      case PurchaseOrderStatus.rejectedByManager:
        return 'rejected_by_manager';
      case PurchaseOrderStatus.inProgress:
        return 'in_progress';
      case PurchaseOrderStatus.completed:
        return 'completed';
      case PurchaseOrderStatus.underFinanceReview:
        return 'under_finance_review';
      case PurchaseOrderStatus.rejectedByFinance:
        return 'rejected_by_finance';
      case PurchaseOrderStatus.underGeneralManagerReview:
        return 'under_general_manager_review';
      case PurchaseOrderStatus.rejectedByGeneralManager:
        return 'rejected_by_general_manager';
      case PurchaseOrderStatus.pendingProcurement:
        return 'pending_procurement';
      case PurchaseOrderStatus.returnedToManagerReview:
        return 'returned_to_manager_review';
    }
  }
}

/// Purchase order type enum
enum PurchaseOrderType {
  /// Purchase type
  purchase,

  /// Maintenance type
  maintenance;

  /// Get type from string
  static PurchaseOrderType fromString(String type) {
    switch (type) {
      case 'purchase':
        return PurchaseOrderType.purchase;
      case 'maintenance':
        return PurchaseOrderType.maintenance;
      default:
        return PurchaseOrderType.purchase;
    }
  }

  /// Convert type to string
  String toApiString() {
    switch (this) {
      case PurchaseOrderType.purchase:
        return 'purchase';
      case PurchaseOrderType.maintenance:
        return 'maintenance';
    }
  }
}

/// Purchase order entity
class PurchaseOrder {
  /// Purchase order ID
  final String id;

  /// Purchase order number
  final String number;

  /// Requester ID
  final String requesterId;

  /// Requester name
  final String requesterName;

  /// Department
  final String department;

  /// Purchase order type
  final PurchaseOrderType type;

  /// Purchase order status
  final PurchaseOrderStatus status;

  /// Request date
  final DateTime requestDate;

  /// Execution date
  final DateTime? executionDate;

  /// Notes
  final String? notes;

  /// Vendor ID
  final String? vendorId;

  /// Vendor name
  final String? vendorName;

  /// Currency
  final String? currency;

  /// Attachment URLs
  final List<String> attachmentUrls;

  /// Items
  final List<PurchaseOrderItem> items;

  /// Total amount
  final double? totalAmount;

  /// Rejection reason
  final String? rejectionReason;

  /// Rejected by
  final String? rejectedBy;

  /// Approved by assistant
  final String? approvedByAssistant;

  /// Approved by manager
  final String? approvedByManager;

  /// Created at
  final DateTime createdAt;

  /// Updated at
  final DateTime updatedAt;

  /// Creates a new [PurchaseOrder]
  const PurchaseOrder({
    required this.id,
    required this.number,
    required this.requesterId,
    required this.requesterName,
    required this.department,
    required this.type,
    required this.status,
    required this.requestDate,
    this.executionDate,
    this.notes,
    this.vendorId,
    this.vendorName,
    this.currency,
    this.attachmentUrls = const [],
    required this.items,
    this.totalAmount,
    this.rejectionReason,
    this.rejectedBy,
    this.approvedByAssistant,
    this.approvedByManager,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a purchase order from JSON
  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      id: json['id'] as String,
      number: json['number'] as String,
      // Backend returns created_by; support requester_id for forward-compat
      requesterId: (json['requester_id'] ?? json['created_by']) as String,
      requesterName: (json['requester_name'] ?? json['creator_name']) as String,
      department: json['department'] as String,
      // Backend uses request_type; support type for forward-compat
      type: PurchaseOrderType.fromString(
        (json['request_type'] ?? json['type']) as String,
      ),
      status: PurchaseOrderStatus.fromString(json['status'] as String),
      requestDate: DateTime.parse(json['request_date'] as String),
      executionDate:
          json['execution_date'] != null
              ? DateTime.parse(json['execution_date'] as String)
              : null,
      notes: json['notes'] as String?,
      // Backend uses supplier_id/name; support vendor_* for forward-compat
      vendorId: (json['vendor_id'] ?? json['supplier_id']) as String?,
      vendorName: (json['vendor_name'] ?? json['supplier_name']) as String?,
      currency: json['currency'] != null ? (json['currency'] as String) : null,
      // Accept array or single string for backward compatibility
      attachmentUrls: (() {
        final v = json['attachment_url'];
        if (v == null) return <String>[];
        if (v is List) {
          return v.whereType<String>().toList();
        }
        if (v is String && v.isNotEmpty) return <String>[v];
        return <String>[];
      })(),
      items:
          (json['items'] as List<dynamic>)
              .map(
                (item) =>
                    PurchaseOrderItem.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
      totalAmount:
          json['total_amount'] != null
              ? (json['total_amount'] as num).toDouble()
              : null,
      rejectionReason: json['rejection_reason'] as String?,
      rejectedBy: json['rejected_by'] as String?,
      approvedByAssistant: json['approved_by_assistant'] as String?,
      approvedByManager: json['approved_by_manager'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert purchase order to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'requester_id': requesterId,
      'requester_name': requesterName,
      'department': department,
      'type': type.toApiString(),
      'status': status.toApiString(),
      'request_date': requestDate.toIso8601String(),
      'execution_date': executionDate?.toIso8601String(),
      'notes': notes,
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'currency': currency,
      'attachment_url': attachmentUrls,
      'items': items.map((item) => item.toJson()).toList(),
      'total_amount': totalAmount,
      'rejection_reason': rejectionReason,
      'rejected_by': rejectedBy,
      'approved_by_assistant': approvedByAssistant,
      'approved_by_manager': approvedByManager,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of this purchase order with the given fields replaced
  PurchaseOrder copyWith({
    String? id,
    String? number,
    String? requesterId,
    String? requesterName,
    String? department,
    PurchaseOrderType? type,
    PurchaseOrderStatus? status,
    DateTime? requestDate,
    DateTime? executionDate,
    String? notes,
    String? vendorId,
    String? vendorName,
    String? currency,
    List<String>? attachmentUrls,
    List<PurchaseOrderItem>? items,
    double? totalAmount,
    String? rejectionReason,
    String? rejectedBy,
    String? approvedByAssistant,
    String? approvedByManager,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      number: number ?? this.number,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      department: department ?? this.department,
      type: type ?? this.type,
      status: status ?? this.status,
      requestDate: requestDate ?? this.requestDate,
      executionDate: executionDate ?? this.executionDate,
      notes: notes ?? this.notes,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      currency: currency ?? this.currency,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      approvedByAssistant: approvedByAssistant ?? this.approvedByAssistant,
      approvedByManager: approvedByManager ?? this.approvedByManager,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
