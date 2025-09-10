// Change Request DTOs for API communication

/// Entity type enum matching backend
enum EntityType {
  vendor,
  item,
  purchaseOrder;

  /// Convert to API string
  String toApiString() {
    switch (this) {
      case EntityType.vendor:
        return 'vendor';
      case EntityType.item:
        return 'item';
      case EntityType.purchaseOrder:
        return 'purchase_order';
    }
  }

  /// Create from string
  static EntityType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'vendor':
        return EntityType.vendor;
      case 'item':
        return EntityType.item;
      case 'purchase_order':
        return EntityType.purchaseOrder;
      default:
        throw ArgumentError('Unknown entity type: $value');
    }
  }

  /// Create from API string
  static EntityType fromApiString(String value) {
    switch (value) {
      case 'vendor':
        return EntityType.vendor;
      case 'item':
        return EntityType.item;
      case 'purchase_order':
        return EntityType.purchaseOrder;
      default:
        return EntityType.vendor;
    }
  }
}

/// Operation type enum matching backend
enum OperationType {
  create,
  update,
  delete;

  /// Convert to API string
  String toApiString() {
    switch (this) {
      case OperationType.create:
        return 'create';
      case OperationType.update:
        return 'update';
      case OperationType.delete:
        return 'delete';
    }
  }

  /// Create from string
  static OperationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'create':
        return OperationType.create;
      case 'update':
        return OperationType.update;
      case 'delete':
        return OperationType.delete;
      default:
        throw ArgumentError('Unknown operation type: $value');
    }
  }

  /// Create from API string
  static OperationType fromApiString(String value) {
    switch (value) {
      case 'create':
        return OperationType.create;
      case 'update':
        return OperationType.update;
      case 'delete':
        return OperationType.delete;
      default:
        return OperationType.create;
    }
  }
}

/// Change request status enum matching backend
enum ChangeRequestStatus {
  pending,
  approved,
  rejected;

  /// Convert to API string
  String toApiString() {
    switch (this) {
      case ChangeRequestStatus.pending:
        return 'pending';
      case ChangeRequestStatus.approved:
        return 'approved';
      case ChangeRequestStatus.rejected:
        return 'rejected';
    }
  }

  /// Create from API string
  static ChangeRequestStatus fromApiString(String value) {
    switch (value) {
      case 'pending':
        return ChangeRequestStatus.pending;
      case 'approved':
        return ChangeRequestStatus.approved;
      case 'rejected':
        return ChangeRequestStatus.rejected;
      default:
        return ChangeRequestStatus.pending;
    }
  }
}

/// Change Request DTO matching backend response
class ChangeRequestDto {
  final String id;
  final EntityType entityType;
  final OperationType operation;
  final Map<String, dynamic> payload;
  final String? targetId;
  final ChangeRequestStatus status;
  final String requestedBy;
  final String? requesterName;
  final String? requesterEmail;
  final String? reviewedBy;
  final String? reviewerName;
  final String? reviewerEmail;
  final DateTime? reviewedAt;
  final String? reason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChangeRequestDto({
    required this.id,
    required this.entityType,
    required this.operation,
    required this.payload,
    this.targetId,
    required this.status,
    required this.requestedBy,
    this.requesterName,
    this.requesterEmail,
    this.reviewedBy,
    this.reviewerName,
    this.reviewerEmail,
    this.reviewedAt,
    this.reason,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from JSON response
  factory ChangeRequestDto.fromJson(Map<String, dynamic> json) {
    return ChangeRequestDto(
      id: json['id'] as String,
      entityType: EntityType.fromApiString(json['entity_type'] as String),
      operation: OperationType.fromApiString(json['operation'] as String),
      payload: json['payload'] as Map<String, dynamic>? ?? {},
      targetId: json['target_id'] as String?,
      status: ChangeRequestStatus.fromApiString(json['status'] as String),
      requestedBy: json['requested_by'] as String,
      requesterName: json['requester_name'] as String?,
      requesterEmail: json['requester_email'] as String?,
      reviewedBy: json['reviewed_by'] as String?,
      reviewerName: json['reviewer_name'] as String?,
      reviewerEmail: json['reviewer_email'] as String?,
      reviewedAt:
          json['reviewed_at'] != null
              ? DateTime.tryParse(json['reviewed_at'] as String)
              : null,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType.toApiString(),
      'operation': operation.toApiString(),
      'payload': payload,
      'target_id': targetId,
      'status': status.toApiString(),
      'requested_by': requestedBy,
      'requester_name': requesterName,
      'requester_email': requesterEmail,
      'reviewed_by': reviewedBy,
      'reviewer_name': reviewerName,
      'reviewer_email': reviewerEmail,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get display title for the change request
  String get displayTitle {
    final entityName = entityType.name;
    final operationName = operation.name;

    switch (operation) {
      case OperationType.create:
        return 'Create $entityName';
      case OperationType.update:
        return 'Update $entityName';
      case OperationType.delete:
        return 'Delete $entityName';
    }
  }

  /// Get status color
  String get statusColor {
    switch (status) {
      case ChangeRequestStatus.pending:
        return '#FF9800'; // Orange
      case ChangeRequestStatus.approved:
        return '#4CAF50'; // Green
      case ChangeRequestStatus.rejected:
        return '#F44336'; // Red
    }
  }

  /// Check if request can be approved/rejected
  bool get canBeReviewed => status == ChangeRequestStatus.pending;
}

/// Create Change Request DTO for API requests
class CreateChangeRequestDto {
  final EntityType entityType;
  final OperationType operation;
  final String? targetId;
  final Map<String, dynamic> payload;
  final String? reason;

  const CreateChangeRequestDto({
    required this.entityType,
    required this.operation,
    this.targetId,
    required this.payload,
    this.reason,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'entity_type': entityType.toApiString(),
      'operation': operation.toApiString(),
      'target_id': targetId,
      'payload': payload,
      'reason': reason,
    };
  }
}

/// Approve/Reject Change Request DTO
class ReviewChangeRequestDto {
  final String? reason;

  const ReviewChangeRequestDto({this.reason});

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {'reason': reason};
  }
}

/// Change Requests Response DTO
class ChangeRequestsResponseDto {
  final bool success;
  final String? message;
  final int count;
  final List<ChangeRequestDto> data;

  const ChangeRequestsResponseDto({
    required this.success,
    this.message,
    required this.count,
    required this.data,
  });

  /// Create from JSON response
  factory ChangeRequestsResponseDto.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    final changeRequests =
        dataList
            .map(
              (item) => ChangeRequestDto.fromJson(item as Map<String, dynamic>),
            )
            .toList();

    return ChangeRequestsResponseDto(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      count: json['count'] as int? ?? 0,
      data: changeRequests,
    );
  }
}

/// Single Change Request Response DTO
class ChangeRequestResponseDto {
  final bool success;
  final String? message;
  final ChangeRequestDto data;

  const ChangeRequestResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  /// Create from JSON response
  factory ChangeRequestResponseDto.fromJson(Map<String, dynamic> json) {
    return ChangeRequestResponseDto(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: ChangeRequestDto.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
