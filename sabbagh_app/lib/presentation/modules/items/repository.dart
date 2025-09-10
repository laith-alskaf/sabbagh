import 'package:sabbagh_app/core/services/dio_client.dart';
import 'package:sabbagh_app/domain/entities/item.dart';

/// Repository for items
class ItemRepository {
  final DioClient _dioClient;

  /// Creates a new [ItemRepository]
  ItemRepository(this._dioClient);

  /// Get items
  Future<List<Item>> getItems({
    String? search,
    String? category,
    String? sortBy,
    String? sortOrder,
    String? active,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dioClient.get(
        '/items',
        queryParameters: {
          'name': search,
          'category': category,
          'sort_by': sortBy,
          'sort_order': sortOrder,
          if (active != null) 'status': active,
          'page': page,
          'limit': limit,
        },
      );

      final List<dynamic> data = response['data'] as List<dynamic>;
      return data
          .map((json) => Item.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get item by ID
  Future<Item> getItemById(String id) async {
    try {
      final response = await _dioClient.get('/items/$id');
      return Item.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Create item
  Future<Item> createItem(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.post('/items', data: data);
      return Item.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  // / Update item
  Future<Item> updateItem(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.put('/items/$id', data: data);
      return Item.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete item
  Future<bool> deleteItem(String id) async {
    try {
      await _dioClient.delete('/items/$id');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> requestItemCreation(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dioClient.post('/items', data: data);
      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
