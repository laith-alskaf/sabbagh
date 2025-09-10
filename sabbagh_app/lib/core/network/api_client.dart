// import 'dart:async';
// import 'dart:io';
//
// import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart';
// import 'package:sabbagh_app/core/config/app_config.dart';
// import 'package:sabbagh_app/core/errors/exceptions.dart';
// import 'package:sabbagh_app/core/utils/storage_service.dart';
//
// /// API Client for making HTTP requests
// class ApiClient {
//   late Dio _dio;
//   final StorageService _storageService = Get.find<StorageService>();
//
//   /// Initialize the API client
//   ApiClient() {
//     _dio = Dio(
//       BaseOptions(
//         baseUrl: AppConfig.baseUrl,
//         connectTimeout: Duration(seconds: AppConfig.timeoutDuration),
//         receiveTimeout: Duration(seconds: AppConfig.timeoutDuration),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//       ),
//     );
//
//     // Add interceptors
//     _dio.interceptors.add(
//       InterceptorsWrapper(
//         onRequest: (options, handler) async {
//           // Add auth token if available
//           final token = await _storageService.getToken();
//           if (token != null && token.isNotEmpty) {
//             options.headers['Authorization'] = 'Bearer $token';
//           }
//
//           // Add language header
//           final language = await _storageService.getLanguage() ?? AppConfig.defaultLanguage;
//           options.headers['Accept-Language'] = language;
//
//           return handler.next(options);
//         },
//         onError: (DioException error, handler) {
//           // Handle errors
//           if (error.response?.statusCode == 401) {
//             // Handle unauthorized error
//             _storageService.clearToken();
//             // TODO: Navigate to login screen
//           }
//           return handler.next(error);
//         },
//       ),
//     );
//
//     // Add logging interceptor in debug mode
//     if (kDebugMode) {
//       _dio.interceptors.add(LogInterceptor(
//         requestBody: true,
//         responseBody: true,
//       ));
//     }
//   }
//
//   /// Make a GET request
//   Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
//     try {
//       final response = await _dio.get(path, queryParameters: queryParameters);
//       return response.data;
//     } on DioException catch (e) {
//       _handleError(e);
//     } on SocketException {
//       throw const NetworkException('No internet connection');
//     } on TimeoutException {
//       throw const NetworkException('Connection timeout');
//     }
//   }
//
//   /// Make a POST request
//   Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
//     try {
//       final response = await _dio.post(path, data: data, queryParameters: queryParameters);
//       return response.data;
//     } on DioException catch (e) {
//       _handleError(e);
//     } on SocketException {
//       throw const NetworkException('No internet connection');
//     } on TimeoutException {
//       throw const NetworkException('Connection timeout');
//     }
//   }
//
//   /// Make a PUT request
//   Future<dynamic> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
//     try {
//       final response = await _dio.put(path, data: data, queryParameters: queryParameters);
//       return response.data;
//     } on DioException catch (e) {
//       _handleError(e);
//     } on SocketException {
//       throw const NetworkException('No internet connection');
//     } on TimeoutException {
//       throw const NetworkException('Connection timeout');
//     }
//   }
//
//   /// Make a DELETE request
//   Future<dynamic> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
//     try {
//       final response = await _dio.delete(path, data: data, queryParameters: queryParameters);
//       return response.data;
//     } on DioException catch (e) {
//       _handleError(e);
//     } on SocketException {
//       throw const NetworkException('No internet connection');
//     } on TimeoutException {
//       throw const NetworkException('Connection timeout');
//     }
//   }
//
//   /// Handle Dio errors
//   void _handleError(DioException e) {
//     if (e.response != null) {
//       final statusCode = e.response!.statusCode;
//       final data = e.response!.data;
//
//       if (statusCode == 400) {
//         // Validation error
//         final message = data['message'] ?? 'Validation error';
//         final errors = data['errors'] ?? [];
//         throw ValidationException(message, errors);
//       } else if (statusCode == 401) {
//         // Unauthorized
//         throw const AuthException('Unauthorized');
//       } else if (statusCode == 403) {
//         // Forbidden
//         throw const AuthException('Forbidden');
//       } else if (statusCode == 404) {
//         // Not found
//         throw const NotFoundException('Resource not found');
//       } else if (statusCode == 409) {
//         // Conflict
//         throw const ConflictException('Conflict error');
//       } else {
//         // Server error
//         throw ServerException(data['message'] ?? 'Server error');
//       }
//     } else {
//       // Network error
//       throw const NetworkException('Network error');
//     }
//   }
// }