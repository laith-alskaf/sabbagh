/// Item entity
class Item {
  /// Item ID
  final String id;

  /// Item name
  final String name;

  /// Item code
  final String code;

  /// Description
  final String? description;

  /// Unit
  final String unit;

  /// Active status
  final String active;

  /// Created at
  final DateTime createdAt;

  /// Updated at
  final DateTime updatedAt;

  /// Creates a new [Item]
  const Item({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.unit,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create an item from JSON
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'].toString(),
      name: json['name'].toString(),
      code: json['code'].toString(),
      description: json['description'].toString() as String?,
      unit: json['unit'].toString(),
      active: json['status'].toString(),
      createdAt: DateTime.parse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.parse(json['updated_at']?.toString() ?? ''),
    );
  }

  /// Convert item to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'unit': unit,
      'status': active,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of this item with the given fields replaced
  Item copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    String? unit,
    String? category,
    double? price,
    String? currency,
    double? minimumStock,
    double? currentStock,
    String? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
