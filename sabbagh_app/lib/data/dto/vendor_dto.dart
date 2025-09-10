import 'package:sabbagh_app/domain/entities/vendor.dart';

/// Vendor status enum
enum VendorStatus {
  active,
  archived;

  /// Convert to API string
  String toApiString() {
    switch (this) {
      case VendorStatus.active:
        return 'active';
      case VendorStatus.archived:
        return 'archived';
    }
  }

  /// Create from API string
  static VendorStatus fromApiString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return VendorStatus.active;
      case 'archived':
        return VendorStatus.archived;
      default:
        return VendorStatus.active;
    }
  }
}

/// Vendor DTO for API communication
class VendorDto {
  /// Vendor ID
  final String id;
  
  /// Vendor name
  final String name;
  
  /// Contact person
  final String contactPerson;
  
  /// Phone
  final String phone;
  
  /// Email
  final String? email;
  
  /// Address
  final String address;
  
  /// Rating (1-5)
  final int? rating;
  
  /// Status
  final VendorStatus status;
  
  /// Notes
  final String? notes;
  
  /// Created at
  final DateTime createdAt;
  
  /// Updated at
  final DateTime updatedAt;

  /// Creates a new [VendorDto]
  const VendorDto({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
    this.email,
    required this.address,
    this.rating,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a vendor DTO from JSON
  factory VendorDto.fromJson(Map<String, dynamic> json) {
    return VendorDto(
      id: json['id'] as String,
      name: json['name'] as String,
      contactPerson: json['contact_person'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      address: json['address'] as String,
      rating: json['rating'] as int?,
      status: VendorStatus.fromApiString(json['status'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert vendor DTO to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'rating': rating,
      'status': status.toApiString(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to domain entity
  Vendor toEntity() {
    return Vendor(
      id: id,
      name: name,
      contactPerson: contactPerson,
      phone: phone,
      email: email,
      address: address,
      rating: rating,
      active: status == VendorStatus.active,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create DTO from domain entity
  factory VendorDto.fromEntity(Vendor vendor) {
    return VendorDto(
      id: vendor.id,
      name: vendor.name,
      contactPerson: vendor.contactPerson ?? '',
      phone: vendor.phone ?? '',
      email: vendor.email,
      address: vendor.address ?? '',
      rating: vendor.rating,
      status: vendor.active ? VendorStatus.active : VendorStatus.archived,
      notes: vendor.notes,
      createdAt: vendor.createdAt,
      updatedAt: vendor.updatedAt,
    );
  }

  /// Create a copy of this vendor DTO with the given fields replaced
  VendorDto copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    int? rating,
    VendorStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VendorDto(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Create vendor request DTO
class CreateVendorDto {
  /// Vendor name
  final String name;
  
  /// Contact person
  final String contactPerson;
  
  /// Phone
  final String phone;
  
  /// Email
  final String? email;
  
  /// Address
  final String address;
  
  /// Rating (1-5)
  final int? rating;
  
  /// Status
  final VendorStatus status;
  
  /// Notes
  final String? notes;

  /// Creates a new [CreateVendorDto]
  const CreateVendorDto({
    required this.name,
    required this.contactPerson,
    required this.phone,
    this.email,
    required this.address,
    this.rating,
    this.status = VendorStatus.active,
    this.notes,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'rating': rating,
      'status': status.toApiString(),
      'notes': notes,
    };
  }
}

/// Update vendor request DTO
class UpdateVendorDto {
  /// Vendor name
  final String? name;
  
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
  
  /// Status
  final VendorStatus? status;
  
  /// Notes
  final String? notes;

  /// Creates a new [UpdateVendorDto]
  const UpdateVendorDto({
    this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.rating,
    this.status,
    this.notes,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    
    if (name != null) json['name'] = name;
    if (contactPerson != null) json['contact_person'] = contactPerson;
    if (phone != null) json['phone'] = phone;
    if (email != null) json['email'] = email;
    if (address != null) json['address'] = address;
    if (rating != null) json['rating'] = rating;
    if (status != null) json['status'] = status!.toApiString();
    if (notes != null) json['notes'] = notes;
    
    return json;
  }
}