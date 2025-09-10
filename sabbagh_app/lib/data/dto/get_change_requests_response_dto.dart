import 'package:sabbagh_app/data/dto/change_request_dto.dart';

/// Response DTO for getting change requests
class GetChangeRequestsResponseDto {
  final List<ChangeRequestDto> data;
  final int count;
  final bool success;
  final String? message;

  /// Creates a new [GetChangeRequestsResponseDto]
  const GetChangeRequestsResponseDto({
    required this.data,
    required this.count,
    required this.success,
    this.message,
  });

  /// Creates [GetChangeRequestsResponseDto] from JSON
  factory GetChangeRequestsResponseDto.fromJson(Map<String, dynamic> json) {
    return GetChangeRequestsResponseDto(
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => ChangeRequestDto.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      count: json['count'] as int? ?? 0,
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }

  /// Converts [GetChangeRequestsResponseDto] to JSON
  Map<String, dynamic> toJson() {
    return {
      'data': data.map((item) => item.toJson()).toList(),
      'count': count,
      'success': success,
      if (message != null) 'message': message,
    };
  }
}

/// Response DTO for single change request operations
class SingleChangeRequestResponseDto {
  final ChangeRequestDto data;
  final bool success;
  final String? message;

  /// Creates a new [SingleChangeRequestResponseDto]
  const SingleChangeRequestResponseDto({
    required this.data,
    required this.success,
    this.message,
  });

  /// Creates [SingleChangeRequestResponseDto] from JSON
  factory SingleChangeRequestResponseDto.fromJson(Map<String, dynamic> json) {
    return SingleChangeRequestResponseDto(
      data: ChangeRequestDto.fromJson(json['data'] as Map<String, dynamic>),
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }

  /// Converts [SingleChangeRequestResponseDto] to JSON
  Map<String, dynamic> toJson() {
    return {
      'data': data.toJson(),
      'success': success,
      if (message != null) 'message': message,
    };
  }
}