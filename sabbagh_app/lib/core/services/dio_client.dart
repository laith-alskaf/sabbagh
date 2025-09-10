import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide MultipartFile, FormData;
import 'package:sabbagh_app/core/config/app_config.dart';
import 'package:sabbagh_app/core/constants/app_strings.dart';
import 'package:sabbagh_app/core/services/storage_service.dart';

/// Custom exception for API errors
class ApiException implements Exception {
  /// Error message
  final String message;

  /// Error code
  final String? code;

  /// Error details
  final List<dynamic>? errors;

  /// Creates a new [ApiException]
  ApiException(this.message, {this.code, this.errors});

  @override
  String toString() => message;
}

/// API client for making HTTP requests
class DioClient {
  late Dio _dio;
  final StorageService _storageService = Get.find<StorageService>();

  /// Initialize the API client
  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: Duration(seconds: AppConfig.timeoutDuration),
        receiveTimeout: Duration(seconds: AppConfig.timeoutDuration),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if available
          final token = await _storageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Add language header
          final language =
              await _storageService.getLanguage() ?? AppConfig.defaultLanguage;
          options.headers['accept-language'] = language;

          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Check if response is successful
          if (response.data is Map<String, dynamic> &&
              response.data.containsKey('success') &&
              response.data['success'] == false) {
            // Handle API error response
            final message = response.data['message'] ?? "server_error".tr;
            final code = response.data['code'];
            final errors = response.data['errors'];

            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                error: ApiException(message, code: code, errors: errors),
              ),
            );
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          // Handle unauthorized error
          // if (error.response?.statusCode == 401) {
          //   await _storageService.clearToken();
          //   await _storageService.clearUser();

          //   // Navigate to login screen
          //   // Get.offAllNamed(AppRoutes.login);

          //   return handler.next(error);
          // }

          // Handle other errors
          return handler.next(error);
        },
      ),
    );

    // Add logging interceptor in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  /// Make a GET request
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    } on SocketException {
      throw ApiException("network_error".tr);
    } on TimeoutException {
      throw ApiException("network_error".tr);
    }
  }

  /// Make a POST request
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (kDebugMode) {
      print('🚀 POST Request: $path');
      print('📤 Data: $data');
    }

    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      if (kDebugMode) {
        print('📥 Response Status: ${response.statusCode}');
        print('📊 Response Data: ${response.data}');
      }

      return response.data;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ DioException: ${e.message}');
      }
      throw _handleError(e);
    } on SocketException {
      if (kDebugMode) {
        print('❌ SocketException: Network error');
      }
      throw ApiException("network_error".tr);
    } on TimeoutException {
      if (kDebugMode) {
        print('❌ TimeoutException: Request timeout');
      }
      throw ApiException("network_error".tr);
    }
  }

  // Multipart helpers for forms with optional images
  Future<dynamic> postMultipart(
    String path, {
    required Map<String, dynamic> payload,
    List<MultipartFile> files = const [],
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final form = FormData.fromMap({
        'payload': jsonEncode(payload),
        if (files.isNotEmpty) 'images': files,
      });
      final response = await _dio.post(
        path,
        data: form,
        queryParameters: queryParameters,
        options: Options(
          headers: {
            // Let Dio set proper boundary
            'Accept': 'application/json',
          },
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> putMultipart(
    String path, {
    required Map<String, dynamic> payload,
    List<MultipartFile> files = const [],
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final form = FormData.fromMap({
        'payload': jsonEncode(payload),
        if (files.isNotEmpty) 'images': files,
      });
      final response = await _dio.put(
        path,
        data: form,
        queryParameters: queryParameters,
        options: Options(headers: {'Accept': 'application/json'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> patchMultipart(
    String path, {
    required Map<String, dynamic> payload,
    List<MultipartFile> files = const [],
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final form = FormData.fromMap({
        'payload': jsonEncode(payload),
        if (files.isNotEmpty) 'images': files,
      });
      final response = await _dio.patch(
        path,
        data: form,
        queryParameters: queryParameters,
        options: Options(headers: {'Accept': 'application/json'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Make a PUT request
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    } on SocketException {
      throw ApiException("network_error".tr);
    } on TimeoutException {
      throw ApiException("network_error".tr);
    }
  }

  /// Make a PATCH request
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    } on SocketException {
      throw ApiException("network_error".tr);
    } on TimeoutException {
      throw ApiException("network_error".tr);
    }
  }

  /// Make a DELETE request
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    } on SocketException {
      throw ApiException("network_error".tr);
    } on TimeoutException {
      throw ApiException("network_error".tr);
    }
  }

  /// Download file
  Future<void> downloadFile(
    String path,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      if (kDebugMode) {
        print('📥 Downloading file from: $path');
        print('💾 Saving to: $savePath');
        print('🔗 Query params: $queryParameters');
      }

      await _dio.download(
        path,
        savePath,
        queryParameters: queryParameters,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          headers: {
            'Accept':
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          },
        ),
      );

      if (kDebugMode) {
        print('✅ File downloaded successfully: $savePath');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Download error: ${e.message}');
        print('📍 Status Code: ${e.response?.statusCode}');
      }
      throw _handleError(e);
    } on SocketException {
      if (kDebugMode) {
        print('❌ SocketException during download');
      }
      throw ApiException(AppStrings.networkError);
    } on TimeoutException {
      if (kDebugMode) {
        print('❌ TimeoutException during download');
      }
      throw ApiException(AppStrings.networkError);
    }
  }

  /// Handle Dio errors
  Never _handleError(DioException e) {
    if (e.error is ApiException) {
      throw e.error as ApiException;
    }

    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      if (data is Map<String, dynamic> && data.containsKey('message')) {
        final message = data['message'] as String? ?? AppStrings.serverError;
        final code = data['code'] as String?;
        final errors = data['errors'] as List<dynamic>?;

        throw ApiException(message, code: code, errors: errors);
      } else if (statusCode == 400) {
        throw ApiException(e.message ?? "network_error".tr);
      } else if (statusCode == 401 || statusCode == 403) {
        throw ApiException("unauthorized".tr);
      } else if (statusCode == 500) {
        throw ApiException("server_error".tr);
      } else {
        throw ApiException("network_error".tr);
      }
    } else {
      throw ApiException("network_error".tr);
    }
  }
}
