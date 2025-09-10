import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_routes.dart';
import 'package:sabbagh_app/core/services/dio_client.dart';
import 'package:sabbagh_app/core/services/storage_service.dart';
import 'package:sabbagh_app/core/utils/navigation_helper.dart';
import 'package:sabbagh_app/presentation/modules/notifications/repository.dart';

/// Top-level background handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Keep it minimal: background handler runs in its own isolate without Get context
  if (kDebugMode) {
    debugPrint('🔔 [BG] Message ID: ${message.messageId}');
    debugPrint('🔔 [BG] Title: ${message.notification?.title}');
    debugPrint('🔔 [BG] Body: ${message.notification?.body}');
    debugPrint('🔔 [BG] Data: ${message.data}');
  }
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;
  NotificationRepository? _repo; // lazy init from Get

  String? get fcmToken => _fcmToken;

  NotificationRepository get _repository {
    return _repo ??= NotificationRepository(Get.find<DioClient>());
  }

  StorageService get _storage => Get.find<StorageService>();

  /// Initialize Firebase Messaging, permissions, handlers, and register token
  Future<void> initialize() async {
    try {
      if (kDebugMode) debugPrint('🔥 FCM Debug - Starting FCM initialization');
      
      // Register background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      if (kDebugMode) debugPrint('🔥 FCM Debug - Background handler registered');

      // iOS/macOS: request permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (kDebugMode) debugPrint('🔥 FCM Debug - Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        if (kDebugMode) debugPrint('🔥 FCM Debug - Permission denied');
        return;
      }

      // Token fetch + registration
      await _refreshAndRegisterToken();

      // Listen for token refresh and re-register
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        if (kDebugMode) debugPrint('🔥 FCM Debug - Token refreshed: $newToken');
        await _registerTokenWithServerIfPossible();
      });

      // Foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      if (kDebugMode) debugPrint('🔥 FCM Debug - Foreground message listener registered');

      // Notification tapped from background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      if (kDebugMode) debugPrint('🔥 FCM Debug - Message opened app listener registered');

      // Handle initial notification if app opened via notification
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) debugPrint('🔥 FCM Debug - Initial message found: ${initialMessage.data}');
        _handleMessageOpenedApp(initialMessage);
      } else {
        if (kDebugMode) debugPrint('🔥 FCM Debug - No initial message');
      }
      
      if (kDebugMode) debugPrint('🔥 FCM Debug - FCM initialization completed successfully');
    } catch (e) {
      debugPrint('🔥 FCM Debug - FCM initialization error: $e');
    }
  }

  /// Fetch current token and register with server if authenticated
  Future<void> _refreshAndRegisterToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (kDebugMode) debugPrint('🔥 FCM Debug - Token obtained: $_fcmToken');
      await _registerTokenWithServerIfPossible();
    } catch (e) {
      debugPrint('🔥 FCM Debug - Error getting/registering FCM token: $e');
    }
  }

  /// Register token with backend if we have an auth token
  Future<void> _registerTokenWithServerIfPossible() async {
    final authToken = _storage.getTokenSync();
    if (kDebugMode) debugPrint('🔥 FCM Debug - Auth token available: ${authToken != null && authToken.isNotEmpty}');
    if (authToken == null || authToken.isEmpty) {
      if (kDebugMode) debugPrint('🔥 FCM Debug - No auth token, skipping FCM token registration');
      return;
    }
    if (_fcmToken == null || _fcmToken!.isEmpty) {
      if (kDebugMode) debugPrint('🔥 FCM Debug - No FCM token, skipping registration');
      return;
    }

    final deviceInfo = _buildDeviceInfo();
    if (kDebugMode) debugPrint('🔥 FCM Debug - Attempting to register FCM token with server');
    if (kDebugMode) debugPrint('🔥 FCM Debug - Device info: $deviceInfo');
    try {
      await _repository.saveFcmToken(token: _fcmToken!, deviceInfo: deviceInfo);
      if (kDebugMode) debugPrint('🔥 FCM Debug - FCM token registered with server successfully');
    } catch (e) {
      debugPrint('🔥 FCM Debug - Failed to register FCM token with server: $e');
    }
  }

  /// Unregister token from backend if present
  Future<void> unregisterTokenFromServer() async {
    try {
      final token = _fcmToken ?? await _firebaseMessaging.getToken();
      if (token == null || token.isEmpty) return;
      await _repository.deleteFcmToken(token: token);
      if (kDebugMode) debugPrint('FCM token unregistered from server');
    } catch (e) {
      debugPrint('Failed to unregister FCM token: $e');
    }
  }

  /// Manual refresh of the token + re-register
  Future<String?> refreshToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = await _firebaseMessaging.getToken();
      if (kDebugMode) debugPrint('FCM Token refreshed manually: $_fcmToken');
      await _registerTokenWithServerIfPossible();
      return _fcmToken;
    } catch (e) {
      debugPrint('Error refreshing FCM token: $e');
      return null;
    }
  }

  /// Delete local token (does not affect server unless you call unregisterTokenFromServer)
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      debugPrint('FCM Token deleted locally');
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }

  /// Update token in memory and re-register
  Future<void> updateToken(String token) async {
    try {
      _fcmToken = token;
      await _registerTokenWithServerIfPossible();
      if (kDebugMode) debugPrint('FCM Token updated + registered: $token');
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// Role-aware navigation based on message data
  void _navigateFromMessageData(Map<String, dynamic> data) {
    if (kDebugMode) debugPrint('🔔 FCM Debug - Navigating from message data: $data');
    
    // Expected backend payload: { type, id, number, ... }
    final type = data['type'] as String?;
    final id = data['id']?.toString();

    if (kDebugMode) debugPrint('🔔 FCM Debug - Message type: $type, ID: $id');

    String? targetRoute;
    if (type != null) {
      switch (type) {
        case 'po_created':
        case 'po_status_changed':
        case 'po_updated':
        case 'po_approved':
        case 'po_rejected':
        case 'po_completed':
          if (id != null && id.isNotEmpty) {
            targetRoute = '/purchase-orders/$id'; // matches AppRoutes.purchaseOrderDetails
          } else {
            targetRoute = AppRoutes.purchaseOrders;
          }
          break;
        default:
          targetRoute = AppRoutes.dashboard; // fallback for managers, helper will enforce role
      }
    }

    if (kDebugMode) debugPrint('🔔 FCM Debug - Target route: $targetRoute');

    if (targetRoute == null) {
      if (kDebugMode) debugPrint('🔔 FCM Debug - No target route determined');
      return;
    }

    // Enforce role access and navigate
    try {
      if (kDebugMode) debugPrint('🔔 FCM Debug - Attempting navigation with role check');
      // Use helper that checks role and handles fallback
      NavigationHelper.navigateWithRoleCheck(targetRoute);
    } catch (e) {
      if (kDebugMode) debugPrint('🔔 FCM Debug - Navigation error: $e');
      // Fallback to role-based home or login
      NavigationHelper.navigateToHome();
    }
  }

  /// Foreground message handler
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('🔔 [FG] FCM Debug - Received foreground message');
      debugPrint('🔔 [FG] ID: ${message.messageId}');
      debugPrint('🔔 [FG] Title: ${message.notification?.title}');
      debugPrint('🔔 [FG] Body: ${message.notification?.body}');
      debugPrint('🔔 [FG] Data: ${message.data}');
    }

    // Show lightweight in-app banner without interrupting flow
    final title = message.notification?.title ?? 'notifications'.tr;
    final body = message.notification?.body ?? 'notifications_will_appear_here'.tr;

    if (kDebugMode) debugPrint('🔔 [FG] FCM Debug - Showing snackbar with title: $title, body: $body');

    // Use Get.snackbar to avoid needing BuildContext and keep behavior consistent across app
    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
      isDismissible: true,
      duration: const Duration(seconds: 4),
      mainButton: TextButton(
        onPressed: () {
          if (kDebugMode) debugPrint('🔔 [FG] FCM Debug - Snackbar button pressed');
          try {
            if (message.data.isNotEmpty) {
              if (kDebugMode) debugPrint('🔔 [FG] FCM Debug - Navigating from message data: ${message.data}');
              _navigateFromMessageData(message.data);
            } else {
              if (kDebugMode) debugPrint('🔔 [FG] FCM Debug - No data, navigating to home');
              NavigationHelper.navigateToHome();
            }
          } catch (e) {
            if (kDebugMode) debugPrint('🔔 [FG] FCM Debug - Navigation error: $e');
            NavigationHelper.navigateToHome();
          }
        },
        child: Text('more'.tr),
      ),
    );
  }

  /// Notification click handler
  void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) debugPrint('🔔 [TAP] Data: ${message.data}');
    if (message.data.isNotEmpty) {
      _navigateFromMessageData(message.data);
    }
  }

  String _buildDeviceInfo() {
    final os = kIsWeb ? 'web' : Platform.operatingSystem;
    final osVersion = kIsWeb ? 'n/a' : Platform.operatingSystemVersion;
    return 'os=$os; ver=$osVersion';
  }
}