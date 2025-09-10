/// Purchase Order DTOs for API communication
class PurchaseOrderDto {
  final String id;
  final String number;
  final String requestDate;
  final String department;
  final String requestType;
  final String requesterName;
  final String status;
  final String? notes;
  final String? supplierId;
  final String? supplierName;
  final String? executionDate;
  final List<String>? attachmentUrls;
  final double? totalAmount;
  final String? currency;
  final String createdBy;
  final String? creatorName;
  final String? creatorEmail;
  final String createdAt;
  final String updatedAt;
  final List<PurchaseOrderItemDto> items;

  const PurchaseOrderDto({
    required this.id,
    required this.number,
    required this.requestDate,
    required this.department,
    required this.requestType,
    required this.requesterName,
    required this.status,
    this.notes,
    this.supplierId,
    this.supplierName,
    this.executionDate,
    this.attachmentUrls,
    this.totalAmount,
    this.currency,
    required this.createdBy,
    this.creatorName,
    this.creatorEmail,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  factory PurchaseOrderDto.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderDto(
      id: json['id'] as String,
      number: json['number'] as String,
      requestDate: json['request_date'] as String,
      department: json['department'] as String,
      requestType: json['request_type'] as String,
      requesterName: json['requester_name'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      supplierId: json['supplier_id'] as String?,
      supplierName: json['supplier_name'] as String?,
      executionDate: json['execution_date'] as String?,
      // Accept array or single string for backward compatibility
      attachmentUrls: (() {
        final v = json['attachment_url'];
        if (v == null) return null;
        if (v is List) return v.whereType<String>().toList();
        if (v is String && v.isNotEmpty) return <String>[v];
        return <String>[];
      })(),
      totalAmount:
          json['total_amount'] != null
              ? (json['total_amount'] as num).toDouble()
              : null,
      currency: json['currency'] as String?,
      createdBy: json['created_by'] as String,
      creatorName: json['creator_name'] as String?,
      creatorEmail: json['creator_email'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      items:
          (json['items'] as List<dynamic>)
              .map(
                (item) =>
                    PurchaseOrderItemDto.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'request_date': requestDate,
      'department': department,
      'request_type': requestType,
      'requester_name': requesterName,
      'status': status,
      'notes': notes,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'execution_date': executionDate,
      'attachment_url': attachmentUrls,
      'total_amount': totalAmount,
      'currency': currency,
      'created_by': createdBy,
      'creator_name': creatorName,
      'creator_email': creatorEmail,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class PurchaseOrderItemDto {
  final String id;
  final String purchaseOrderId;
  final String? itemId;
  final String? itemCode;
  final String? itemName;
  final double quantity;
  final String unit;
  final double? receivedQuantity;
  final double? price;
  final double? lineTotal;
  final String? currency;

  const PurchaseOrderItemDto({
    required this.id,
    required this.purchaseOrderId,
    this.itemId,
    this.itemCode,
    this.itemName,
    required this.quantity,
    required this.unit,
    this.receivedQuantity,
    this.price,
    this.lineTotal,
    this.currency,
  });

  factory PurchaseOrderItemDto.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItemDto(
      id: json['id'] as String,
      purchaseOrderId: json['purchase_order_id'] as String,
      itemId: json['item_id'] as String?,
      itemCode: json['item_code'] as String?,
      itemName: json['item_name'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      receivedQuantity:
          json['received_quantity'] != null
              ? (json['received_quantity'] as num).toDouble()
              : null,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      lineTotal:
          json['line_total'] != null
              ? (json['line_total'] as num).toDouble()
              : null,
      currency: json['currency'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchase_order_id': purchaseOrderId,
      'item_id': itemId,
      'item_code': itemCode,
      'item_name': itemName,
      'quantity': quantity,
      'unit': unit,
      'received_quantity': receivedQuantity,
      'price': price,
      'line_total': lineTotal,
      'currency': currency,
    };
  }
}

/// Request DTOs for creating/updating purchase orders
class CreatePurchaseOrderRequestDto {
  final String requestDate;
  final String department;
  final String requestType;
  final String requesterName;
  final String? notes;
  final String? supplierId;
  final String? executionDate;
  final List<String>? attachmentUrls;
  final double? totalAmount;
  final String? currency;
  final List<CreatePurchaseOrderItemRequestDto> items;

  const CreatePurchaseOrderRequestDto({
    required this.requestDate,
    required this.department,
    required this.requestType,
    required this.requesterName,
    this.notes,
    this.supplierId,
    this.executionDate,
    this.attachmentUrls,
    this.totalAmount,
    this.currency,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'request_date': requestDate,
      'department': department,
      'request_type': requestType,
      'requester_name': requesterName,
      'items': items.map((item) => item.toJson()).toList(),
    };

    // Only add optional fields if they are not null
    if (notes != null) json['notes'] = notes;
    if (supplierId != null) json['supplier_id'] = supplierId;
    if (executionDate != null) json['execution_date'] = executionDate;
    if (attachmentUrls != null) json['attachment_url'] = attachmentUrls;
    if (totalAmount != null) json['total_amount'] = totalAmount;
    if (currency != null) json['currency'] = currency;

    return json;
  }
}

class CreatePurchaseOrderItemRequestDto {
  final String? itemId;
  final String? itemCode;
  final String? itemName;
  final double quantity;
  final String unit;
  final double? receivedQuantity;
  final double? price;
  final double? lineTotal;
  final String? currency;

  const CreatePurchaseOrderItemRequestDto({
    this.itemId,
    this.itemCode,
    this.itemName,
    required this.quantity,
    required this.unit,
    this.receivedQuantity,
    this.price,
    this.lineTotal,
    this.currency,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'quantity': quantity, 'unit': unit};

    // Only add optional fields if they are not null
    if (currency != null) json['currency'] = currency;
    if (itemId != null) json['item_id'] = itemId;
    if (itemCode != null) json['item_code'] = itemCode;
    if (itemName != null) json['item_name'] = itemName;
    if (receivedQuantity != null) json['received_quantity'] = receivedQuantity;
    if (price != null) json['price'] = price;
    if (lineTotal != null) json['line_total'] = lineTotal;

    return json;
  }
}

class UpdatePurchaseOrderRequestDto {
  final String? requestDate;
  final String? department;
  final String? requestType;
  final String? requesterName;
  final String? notes;
  final String? supplierId;
  final String? executionDate;
  final List<String>? attachmentUrls;
  final double? totalAmount;
  final String? currency;
  final List<CreatePurchaseOrderItemRequestDto>? items;

  const UpdatePurchaseOrderRequestDto({
    this.requestDate,
    this.department,
    this.requestType,
    this.requesterName,
    this.notes,
    this.supplierId,
    this.executionDate,
    this.attachmentUrls,
    this.totalAmount,
    this.currency,
    this.items,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (requestDate != null) json['request_date'] = requestDate;
    if (department != null) json['department'] = department;
    if (requestType != null) json['request_type'] = requestType;
    if (requesterName != null) json['requester_name'] = requesterName;
    if (notes != null) json['notes'] = notes;
    if (supplierId != null) json['supplier_id'] = supplierId;
    if (executionDate != null) json['execution_date'] = executionDate;
    if (attachmentUrls != null) json['attachment_url'] = attachmentUrls;
    if (totalAmount != null) json['total_amount'] = totalAmount;
    if (currency != null) json['currency'] = currency;
    if (items != null)
      json['items'] = items!.map((item) => item.toJson()).toList();

    return json;
  }
}

class ApproveRejectRequestDto {
  final String? reason;

  const ApproveRejectRequestDto({this.reason});

  Map<String, dynamic> toJson() {
    return {if (reason != null) 'reason': reason};
  }
}

/// Response wrapper for API responses
class PurchaseOrderApiResponse {
  final bool success;
  final String? message;
  final PurchaseOrderDto? data;
  final int? count;

  const PurchaseOrderApiResponse({
    required this.success,
    this.message,
    this.data,
    this.count,
  });

  factory PurchaseOrderApiResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderApiResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data:
          json['data'] != null
              ? PurchaseOrderDto.fromJson(json['data'] as Map<String, dynamic>)
              : null,
      count: json['count'] as int?,
    );
  }
}

class PurchaseOrderListApiResponse {
  final bool success;
  final String? message;
  final List<PurchaseOrderDto> data;
  final int count;

  const PurchaseOrderListApiResponse({
    required this.success,
    this.message,
    required this.data,
    required this.count,
  });

  factory PurchaseOrderListApiResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderListApiResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data:
          (json['data'] as List<dynamic>)
              .map(
                (item) =>
                    PurchaseOrderDto.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
      count: json['count'] as int,
    );
  }
}
