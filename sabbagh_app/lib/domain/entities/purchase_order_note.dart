/// Purchase order note entity
class PurchaseOrderNote {
  /// Note ID (server bigserial)
  final int id;

  /// Related purchase order ID
  final String purchaseOrderId;

  /// Author user ID
  final String userId;

  /// Author user name (optional if not provided)
  final String? userName;

  /// Note text
  final String note;

  /// Created at timestamp
  final DateTime createdAt;

  const PurchaseOrderNote({
    required this.id,
    required this.purchaseOrderId,
    required this.userId,
    required this.note,
    required this.createdAt,
    this.userName,
  });

  factory PurchaseOrderNote.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderNote(
      id: (json['id'] as num).toInt(),
      purchaseOrderId: json['purchase_order_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String?,
      note: json['note'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchase_order_id': purchaseOrderId,
      'user_id': userId,
      'user_name': userName,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }
}