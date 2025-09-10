/// Purchase order item entity
class PurchaseOrderItem {
  /// Item ID
  final String id;
  
  /// Purchase order ID
  final String purchaseOrderId;
  
  /// Item ID (from items table)
  final String? itemId;
  
  /// Item name
  final String itemName;
  
  /// Item code
  final String? itemCode;
  
  /// Quantity
  final double quantity;
  
  /// Received quantity
  final double? receivedQuantity;
  
  /// Unit
  final String unit;
  
  /// Price
  final double? price;
  
  /// Line total
  final double? lineTotal;
  
  /// Currency
  final String? currency;

  /// Get price as a string
  String get priceAsString => (price ?? 0.0).toString();

  /// Creates a new [PurchaseOrderItem]
  const PurchaseOrderItem({
    required this.id,
    required this.purchaseOrderId,
    this.itemId,
    required this.itemName,
    this.itemCode,
    required this.quantity,
    this.receivedQuantity,
    required this.unit,
    this.price,
    this.lineTotal,
     this.currency,
  });

  /// Create a purchase order item from JSON
  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItem(
      id: json['id'] as String,
      purchaseOrderId: json['purchase_order_id'] as String,
      itemId: json['item_id'] as String?,
      // Backend returns item_name and item_code
      itemName: (json['item_name'] ?? json['name'] ?? '') as String,
      itemCode: (json['item_code'] ?? json['code']) as String?,
      quantity: (json['quantity'] as num).toDouble(),
      receivedQuantity: json['received_quantity'] != null
          ? (json['received_quantity'] as num).toDouble()
          : null,
      unit: json['unit'] as String,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      lineTotal: json['line_total'] != null
          ? (json['line_total'] as num).toDouble()
          : null,
      currency: json['currency'] != null
          ? (json['currency'] as String)
          : null,
      
    );
  }

  /// Convert purchase order item to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchase_order_id': purchaseOrderId,
      'item_id': itemId,
      'item_name': itemName,
      'item_code': itemCode,
      'quantity': quantity,
      'received_quantity': receivedQuantity,
      'unit': unit,
      'price': price,
      'line_total': lineTotal,
      'currency': currency,
    };
  }

  /// Create a copy of this purchase order item with the given fields replaced
  PurchaseOrderItem copyWith({
    String? id,
    String? purchaseOrderId,
    String? itemId,
    String? itemName,
    String? itemCode,
    double? quantity,
    double? receivedQuantity,
    String? unit,
    double? price,
    double? lineTotal,
    String? currency,
  }) {
    return PurchaseOrderItem(
      id: id ?? this.id,
      purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      itemCode: itemCode ?? this.itemCode,
      quantity: quantity ?? this.quantity,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      lineTotal: lineTotal ?? this.lineTotal,
      currency: currency ?? this.currency,
    );
  }
}
