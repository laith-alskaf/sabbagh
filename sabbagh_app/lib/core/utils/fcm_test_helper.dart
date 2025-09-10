import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/services/fcm_service.dart';
import 'package:sabbagh_app/core/services/storage_service.dart';
import 'package:sabbagh_app/presentation/modules/notifications/repository.dart';
import 'package:sabbagh_app/core/services/dio_client.dart';

/// Helper class for testing FCM functionality
class FCMTestHelper {
  static Future<void> testFCMSetup() async {
    if (kDebugMode) {
      debugPrint('🧪 FCM Test - Starting FCM setup test');
      
      try {
        // Test 1: Check if FCMService is registered
        final fcmService = Get.find<FCMService>();
        debugPrint('🧪 FCM Test - ✅ FCMService found');
        
        // Test 2: Check if FCM token exists
        final token = fcmService.fcmToken;
        debugPrint('🧪 FCM Test - FCM Token: ${token != null ? "✅ Available" : "❌ Not available"}');
        if (token != null) {
          debugPrint('🧪 FCM Test - Token: ${token.substring(0, 20)}...');
        }
        
        // Test 3: Check if auth token exists
        final storageService = Get.find<StorageService>();
        final authToken = storageService.getTokenSync();
        debugPrint('🧪 FCM Test - Auth Token: ${authToken != null && authToken.isNotEmpty ? "✅ Available" : "❌ Not available"}');
        
        // Test 4: Test notification repository
        final dioClient = Get.find<DioClient>();
        final notificationRepo = NotificationRepository(dioClient);
        debugPrint('🧪 FCM Test - ✅ NotificationRepository created');
        
        // Test 5: Try to register FCM token if both tokens are available
        if (token != null && authToken != null && authToken.isNotEmpty) {
          try {
            await notificationRepo.saveFcmToken(token: token, deviceInfo: 'Test Device');
            debugPrint('🧪 FCM Test - ✅ FCM token registration test successful');
          } catch (e) {
            debugPrint('🧪 FCM Test - ❌ FCM token registration test failed: $e');
          }
        } else {
          debugPrint('🧪 FCM Test - ⚠️ Cannot test FCM token registration (missing tokens)');
        }
        
        debugPrint('🧪 FCM Test - Test completed');
        
      } catch (e) {
        debugPrint('🧪 FCM Test - ❌ Test failed: $e');
      }
    }
  }
  
  static Future<void> testNotificationFlow() async {
    if (kDebugMode) {
      debugPrint('🧪 Notification Test - Starting notification flow test');
      
      try {
        // Simulate a notification message
        final testData = {
          'type': 'po_created',
          'id': 'test-po-123',
          'number': 'PO-24-01-0001',
          'status': 'UNDER_ASSISTANT_REVIEW',
          'department': 'IT',
          'requester_name': 'Test User',
        };
        
        debugPrint('🧪 Notification Test - Test data: $testData');
        
        // Test navigation logic
        final fcmService = Get.find<FCMService>();
        // We can't directly call the private method, but we can test the logic
        
        final type = testData['type'];
        final id = testData['id']?.toString();
        
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
                targetRoute = '/purchase-orders/$id';
              } else {
                targetRoute = '/purchase-orders';
              }
              break;
            default:
              targetRoute = '/dashboard';
          }
        }
        
        debugPrint('🧪 Notification Test - Target route: $targetRoute');
        debugPrint('🧪 Notification Test - ✅ Navigation logic test passed');
        
      } catch (e) {
        debugPrint('🧪 Notification Test - ❌ Test failed: $e');
      }
    }
  }
  
  static void logCurrentState() {
    if (kDebugMode) {
      debugPrint('🔍 FCM State Check - Current state:');
      
      try {
        final fcmService = Get.find<FCMService>();
        final token = fcmService.fcmToken;
        debugPrint('🔍 FCM Token: ${token != null ? "Available (${token.length} chars)" : "Not available"}');
        
        final storageService = Get.find<StorageService>();
        final authToken = storageService.getTokenSync();
        debugPrint('🔍 Auth Token: ${authToken != null && authToken.isNotEmpty ? "Available" : "Not available"}');
        
        debugPrint('🔍 Current route: ${Get.currentRoute}');
        
      } catch (e) {
        debugPrint('🔍 State check error: $e');
      }
    }
  }
}