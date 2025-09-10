import 'package:sabbagh_app/core/services/dio_client.dart';

/// Repository for Audit Logs and lookups
class AuditRepository {
  final DioClient _dio;
  AuditRepository(this._dio);

  /// Fetch audit logs with filters and pagination
  Future<Map<String, dynamic>> getAuditLogs({
    int offset = 0,
    int limit = 20,
    String? action,
    String? entityType,
    String? entityId,
    String? actorId,
    String? startDateIso,
    String? endDateIso,
    String sort = 'created_at',
    String order = 'desc',
  }) async {
    final query = <String, dynamic>{
      'offset': offset.toString(),
      'limit': limit.toString(),
      'sort': sort,
      'order': order,
    };

    if (action != null && action.isNotEmpty) {
      query['action'] = action;
    }
    if (entityType != null && entityType.isNotEmpty) {
      query['entity_type'] = entityType;
    }
    if (entityId != null && entityId.isNotEmpty) {
      query['entity_id'] = entityId;
    }
    if (actorId != null && actorId.isNotEmpty) query['actor_id'] = actorId;
    if (startDateIso != null && startDateIso.isNotEmpty) {
      query['start_date'] = startDateIso;
    }
    if (endDateIso != null && endDateIso.isNotEmpty) {
      query['end_date'] = endDateIso;
    }

    final res = await _dio.get('/audit-logs', queryParameters: query);
    if (res is Map && res['success'] == true) {
      return {
        'data': res['data'] ?? [],
        'count': res['count'] ?? 1,
      };
    }
    return {'data': [], 'pagination': {}, 'summary': {}};
  }

  /// Fetch list of users (for actor picker)
  Future<List<Map<String, dynamic>>> listUsers({
    int limit = 10,
    int page = 1,
  }) async {
    final res = await _dio.get(
      '/admin/users',
      queryParameters: {
        'page': page,
        'limit': limit,
        'sort': 'name',
        'order': 'asc',
        'is_active': 'true',
      },
    );
    if (res is Map && res['success'] == true) {
      final List data = res['data'] ?? [];
      return data
          .map<Map<String, dynamic>>(
            (u) => {
              'id': u['id']?.toString() ?? '',
              'label': (u['name'] ?? u['email'] ?? u['id']).toString(),
            },
          )
          .toList();
    }
    return [];
  }

  /// Fetch list of entities by type for entity picker
  Future<List<Map<String, dynamic>>> listEntitiesByType(
    String entityType, {
    int limit = 20,
    int page = 1,
  }) async {
    String path;
    String labelField = 'name';
    switch (entityType) {
      case 'vendor':
        path = '/vendors';
        labelField = 'name';
        break;
      case 'item':
        path = '/items';
        labelField = 'name';
        break;
      case 'purchase_order':
        path = '/purchase-orders';
        labelField = 'code';
        break;
      case 'change_request':
        path = '/change-requests';
        labelField = 'title';
        break;
      case 'user':
        return listUsers(limit: limit, page: page);
      default:
        return [];
    }

    final res = await _dio.get(
      path,
      queryParameters: {'page': page, 'limit': limit, 'order': 'asc'},
    );
    if (res is Map && res['success'] == true) {
      final List data = res['data'] ?? [];
      return data
          .map<Map<String, dynamic>>(
            (e) => {
              'id': e['id']?.toString() ?? '',
              'label':
                  (e[labelField] ??
                          e['name'] ??
                          e['code'] ??
                          e['title'] ??
                          e['id'])
                      .toString(),
            },
          )
          .toList();
    }
    return [];
  }
}
