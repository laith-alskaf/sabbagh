import 'package:sabbagh_app/domain/entities/user.dart';

/// Change request type enum
enum ChangeRequestType {
  /// Vendor creation request
  vendorCreation,
  
  /// Vendor update request
  vendorUpdate,
  
  /// Item creation request
  itemCreation,
  
  /// Item update request
  itemUpdate;
  
  /// Get type from string
  static ChangeRequestType fromString(String type) {
    switch (type) {
      case 'vendor_creation':
        return ChangeRequestType.vendorCreation;
      case 'vendor_update':
        return ChangeRequestType.vendorUpdate;
      case 'item_creation':
        return ChangeRequestType.itemCreation;
      case 'item_update':
        return ChangeRequestType.itemUpdate;
      default:
        return ChangeRequestType.vendorCreation;
    }
  }
  
  /// Convert type to string
  String toApiString() {
    switch (this) {
      case ChangeRequestType.vendorCreation:
        return 'vendor_creation';
      case ChangeRequestType.vendorUpdate:
        return 'vendor_update';
      case ChangeRequestType.itemCreation:
        return 'item_creation';
      case ChangeRequestType.itemUpdate:
        return 'item_update';
    }
  }
}

/// Change request status enum
enum ChangeRequestStatus {
  /// Pending status
  pending,
  
  /// Approved status
  approved,
  
  /// Rejected status
  rejected;
  
  /// Get status from string
  static ChangeRequestStatus fromString(String status) {
    switch (status) {
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
  
  /// Convert status to string
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
}

/// Change request entity
class ChangeRequest {
  /// Change request ID
  final String id;
  
  /// Change request type
  final ChangeRequestType type;
  
  /// Change request status
  final ChangeRequestStatus status;
  
  /// Change request title
  final String title;
  
  /// Change request description
  final String? description;
  
  /// Change request data (JSON)
  final Map<String, dynamic> requestData;
  
  /// Original data (JSON) - for updates
  final Map<String, dynamic>? originalData;
  
  /// Requested by user
  final User requestedBy;
  
  /// Reviewed by user
  final User? reviewedBy;
  
  /// Review notes
  final String? reviewNotes;
  
  /// Created at
  final DateTime createdAt;
  
  /// Updated at
  final DateTime updatedAt;
  
  /// Reviewed at
  final DateTime? reviewedAt;

  /// Creates a new [ChangeRequest]
  const ChangeRequest({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    this.description,
    required this.requestData,
    this.originalData,
    required this.requestedBy,
    this.reviewedBy,
    this.reviewNotes,
    required this.createdAt,
    required this.updatedAt,
    this.reviewedAt,
  });

  /// Create a change request from JSON
  factory ChangeRequest.fromJson(Map<String, dynamic> json) {
    return ChangeRequest(
      id: json['id'] as String,
      type: ChangeRequestType.fromString(json['type'] as String),
      status: ChangeRequestStatus.fromString(json['status'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      requestData: json['request_data'] as Map<String, dynamic>,
      originalData: json['original_data'] as Map<String, dynamic>?,
      requestedBy: User.fromJson(json['requested_by'] as Map<String, dynamic>),
      reviewedBy: json['reviewed_by'] != null 
          ? User.fromJson(json['reviewed_by'] as Map<String, dynamic>)
          : null,
      reviewNotes: json['review_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      reviewedAt: json['reviewed_at'] != null 
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
    );
  }

  /// Convert change request to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toApiString(),
      'status': status.toApiString(),
      'title': title,
      'description': description,
      'request_data': requestData,
      'original_data': originalData,
      'requested_by': requestedBy.toJson(),
      'reviewed_by': reviewedBy?.toJson(),
      'review_notes': reviewNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
    };
  }

  /// Create a copy of this change request with the given fields replaced
  ChangeRequest copyWith({
    String? id,
    ChangeRequestType? type,
    ChangeRequestStatus? status,
    String? title,
    String? description,
    Map<String, dynamic>? requestData,
    Map<String, dynamic>? originalData,
    User? requestedBy,
    User? reviewedBy,
    String? reviewNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? reviewedAt,
  }) {
    return ChangeRequest(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      requestData: requestData ?? this.requestData,
      originalData: originalData ?? this.originalData,
      requestedBy: requestedBy ?? this.requestedBy,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}