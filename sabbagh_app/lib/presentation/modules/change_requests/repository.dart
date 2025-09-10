import 'package:sabbagh_app/core/services/dio_client.dart';
import 'package:sabbagh_app/data/dto/change_request_dto.dart';
import 'package:sabbagh_app/data/dto/get_change_requests_response_dto.dart';

/// Repository for change requests
class ChangeRequestRepository {
  final DioClient _dioClient;

  /// Creates a new [ChangeRequestRepository]
  ChangeRequestRepository(this._dioClient);

  /// Get change requests
    Future<GetChangeRequestsResponseDto> getChangeRequests({
    ChangeRequestStatus? status,
    EntityType? entityType,
    int? limit,
    int? offset,
  }) async {
    final queryParams = <String, dynamic>{};
    
    if (status != null) {
      queryParams['status'] = status.toApiString();
    }
    if (entityType != null) {
      queryParams['entity_type'] = entityType.toApiString();
    }
    if (limit != null) {
      queryParams['limit'] = limit;
    }
    if (offset != null) {
      queryParams['offset'] = offset;
    }

    final response = await _dioClient.get(
      '/change-requests',
      queryParameters: queryParams,
    );
    
    return GetChangeRequestsResponseDto.fromJson(response as Map<String, dynamic>);
  }


  /// Get change request by ID
  Future<ChangeRequestResponseDto> getChangeRequestById(String id) async {
    final response = await _dioClient.get('/change-requests/$id');
    
    return ChangeRequestResponseDto.fromJson(response as Map<String, dynamic>);
  }

  /// Create change request
  Future<ChangeRequestResponseDto> createChangeRequest(
    CreateChangeRequestDto requestDto,
  ) async {
    final response = await _dioClient.post(
      '/change-requests',
      data: requestDto.toJson(),
    );
    
    return ChangeRequestResponseDto.fromJson(response as Map<String, dynamic>);
  }

  /// Review change request (approve/reject)
  Future<ChangeRequestResponseDto> reviewChangeRequest(
    String id,
    ReviewChangeRequestDto reviewDto,
  ) async {
    final response = await _dioClient.patch(
      '/change-requests/$id/review',
      data: reviewDto.toJson(),
    );
    
    return ChangeRequestResponseDto.fromJson(response as Map<String, dynamic>);
  }

  /// Delete change request
  Future<ChangeRequestResponseDto> deleteChangeRequest(String id) async {
    final response = await _dioClient.delete('/change-requests/$id');
    
    return ChangeRequestResponseDto.fromJson(response as Map<String, dynamic>);
  }
 /// Approve a change request
  Future<SingleChangeRequestResponseDto> approveChangeRequest(
    String id, {
    String? reason,
  }) async {
    final response = await _dioClient.post(
      '/change-requests/$id/approve',
      data: ReviewChangeRequestDto(reason: reason).toJson(),
    );
    
    return SingleChangeRequestResponseDto.fromJson(response as Map<String, dynamic>);
  }

  /// Reject a change request
  Future<SingleChangeRequestResponseDto> rejectChangeRequest(
    String id, {
    required String reason,
  }) async {
    final response = await _dioClient.post(
      '/change-requests/$id/reject',
      data: ReviewChangeRequestDto(reason: reason).toJson(),
    );
    
    return SingleChangeRequestResponseDto.fromJson(response as Map<String, dynamic>);
  }
  
}