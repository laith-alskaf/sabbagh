import 'package:sabbagh_app/core/services/dio_client.dart';

class NotificationRepository {
  final DioClient _dio;
  NotificationRepository(this._dio);

  Future<Map<String, dynamic>> list({int limit = 50, int offset = 0}) async {
    final res = await _dio.get('/notifications', queryParameters: {
      'limit': limit,
      'offset': offset,
    });
    return res as Map<String, dynamic>;
  }

  Future<bool> markRead(String id) async {
    final res = await _dio.patch('/notifications/$id/read');
    if (res is Map<String, dynamic>) {
      return (res['success'] as bool?) ?? false;
    }
    return false;
  }

  Future<int> markAllRead() async {
    final res = await _dio.patch('/notifications/read-all');
    if (res is Map<String, dynamic>) {
      return (res['updated'] as int?) ?? 0;
    }
    return 0;
  }

  Future<bool> deleteById(String id) async {
    final res = await _dio.delete('/notifications/$id');
    if (res is Map<String, dynamic>) {
      return (res['success'] as bool?) ?? false;
    }
    return false;
  }

  Future<int> deleteAll() async {
    final res = await _dio.delete('/notifications');
    if (res is Map<String, dynamic>) {
      return (res['deleted'] as int?) ?? 0;
    }
    return 0;
  }

  Future<void> saveFcmToken({required String token, String? deviceInfo}) async {
    await _dio.post('/notifications/fcm-token', data: {
      'token': token,
      if (deviceInfo != null) 'device_info': deviceInfo,
    });
  }

  Future<void> deleteFcmToken({required String token}) async {
    await _dio.delete('/notifications/fcm-token', data: {
      'token': token,
    });
  }
}