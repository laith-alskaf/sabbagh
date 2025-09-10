/// Vendor entity
class Vendor {
  /// Vendor ID
  final String id;
  
  /// Vendor name
  final String name;
  
  /// Contact person
  final String? contactPerson;
  
  /// Phone
  final String? phone;
  
  /// Email
  final String? email;
  
  /// Address
  final String? address;
  
  /// Rating (1-5)
  final int? rating;
  
  /// Active status
  final bool active;
  
  /// Notes
  final String? notes;
  
  /// Created at
  final DateTime createdAt;
  
  /// Updated at
  final DateTime updatedAt;

  /// Creates a new [Vendor]
  const Vendor({
    required this.id,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.rating,
    required this.active,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a vendor from JSON
  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] as String,
      name: json['name'] as String,
      contactPerson: json['contact_person'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      rating: json['rating'] as int?,
      active: json['active'] as bool,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert vendor to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'rating': rating,
      'active': active,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of this vendor with the given fields replaced
  Vendor copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    int? rating,
    bool? active,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vendor(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      active: active ?? this.active,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}