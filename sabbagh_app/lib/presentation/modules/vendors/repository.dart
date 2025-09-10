import 'package:sabbagh_app/core/services/dio_client.dart';
import 'package:sabbagh_app/domain/entities/vendor.dart';
import 'package:sabbagh_app/data/dto/vendor_dto.dart';

/// Repository for vendors
class VendorRepository {
  final DioClient _dioClient;

  /// Creates a new [VendorRepository]
  VendorRepository(this._dioClient);

  /// Get vendors
  Future<List<Vendor>> getVendors({
    String? search,
    String? sortBy,
    String? sortOrder,
    bool? active,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dioClient.get(
        '/vendors',
        queryParameters: {
          'search': search,
          'sort_by': sortBy,
          'sort_order': sortOrder,
          'active': active,
          'page': page,
          'limit': limit,
        },
      );

      final List<dynamic> data = response['data'] as List<dynamic>;
      return data
          .map(
            (json) =>
                VendorDto.fromJson(json as Map<String, dynamic>).toEntity(),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get vendor by ID
  Future<Vendor> getVendorById(String id) async {
    try {
      final response = await _dioClient.get('/vendors/$id');
      return VendorDto.fromJson(
        response['data'] as Map<String, dynamic>,
      ).toEntity();
    } catch (e) {
      // For development, return mock data
      rethrow;
    }
  }

  /// Create vendor
  Future<Vendor> createVendor(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.post('/vendors', data: data);
      return VendorDto.fromJson(
        response['data'] as Map<String, dynamic>,
      ).toEntity();
    } catch (e) {
      // For development, return mock data
      rethrow;
    }
  }
 Future<Map<String, dynamic>> requestVendorCreation(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dioClient.post('/vendors', data: data);
      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Update vendor
  Future<Vendor> updateVendor(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.put('/vendors/$id', data: data);
      return VendorDto.fromJson(
        response['data'] as Map<String, dynamic>,
      ).toEntity();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete vendor
  Future<bool> deleteVendor(String id) async {
    try {
      await _dioClient.delete('/vendors/$id');
      return true;
    } catch (e) {
      return false;
    }
  }


  /// Request vendor update
  Future<Map<String, dynamic>> requestVendorUpdate(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dioClient.post('/vendors/$id', data: data);
      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
