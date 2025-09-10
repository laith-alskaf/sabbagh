import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sabbagh_app/core/services/dio_client.dart';

/// Repository for reports data
class ReportRepository {
  final DioClient _dioClient;

  ReportRepository(this._dioClient);

  /// Get purchase orders report
  Future<Map<String, dynamic>> getPurchaseOrdersReport(
    Map<String, dynamic> params,
  ) async {
    try {
      // Convert Flutter parameter names to backend expected names
      final queryParams = <String, dynamic>{};

      if (params['startDate'] != null) {
        queryParams['startDate'] = params['startDate'];
      }
      if (params['endDate'] != null) {
        queryParams['endDate'] = params['endDate'];
      }
      if (params['department'] != null &&
          params['department'].toString().isNotEmpty) {
        queryParams['department'] = params['department'];
      }
      if (params['status'] != null && params['status'].toString().isNotEmpty) {
        queryParams['status'] = params['status'];
      }
      if (params['supplierId'] != null &&
          params['supplierId'].toString().isNotEmpty) {
        queryParams['supplierId'] = params['supplierId'];
      }
      if (params['page'] != null) {
        queryParams['page'] = params['page'];
      }
      if (params['limit'] != null) {
        queryParams['limit'] = params['limit'];
      }

      final response = await _dioClient.get(
        '/reports/purchase-orders',
        queryParameters: queryParams,
      );

      if (response['success'] == true) {
        return {
          'data': response['data'] ?? [],
          'pagination': response['pagination'] ?? {},
          'summary': response['summary'] ?? {},
        };
      } else {
        throw Exception('Failed to fetch purchase orders report');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get expenses report
  Future<Map<String, dynamic>> getExpensesReport(
    Map<String, dynamic> params,
  ) async {
    try {
      final response = await _dioClient.get(
        '/reports/expenses',
        queryParameters: params,
      );

      if (response['success'] == true) {
        return {
          'data': response['data'] ?? [],
          'pagination': response['pagination'] ?? {},
          'summary': response['summary'] ?? {},
        };
      } else {
        throw Exception('Failed to fetch expenses report');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Export purchase orders report
  Future<String> exportPurchaseOrdersReport(Map<String, dynamic> params) async {
    try {
      // Convert parameter names for export API and add format=excel
      final exportParams = <String, dynamic>{
        'format': 'excel', // Backend uses format parameter for export
      };

      if (params['start_date'] != null) {
        exportParams['start_date'] = params['start_date'];
      }
      if (params['end_date'] != null) {
        exportParams['end_date'] = params['end_date'];
      }
      if (params['department'] != null &&
          params['department'].toString().isNotEmpty) {
        exportParams['department'] = params['department'];
      }
      if (params['status'] != null && params['status'].toString().isNotEmpty) {
        exportParams['status'] = params['status'];
      }
      if (params['vendor_id'] != null &&
          params['vendor_id'].toString().isNotEmpty) {
        exportParams['supplier_id'] =
            params['vendor_id']; // Backend uses 'supplier_id'
      }

      // Use downloadFile method for actual file download
      final filePath = await _downloadExcelFile(
        '/reports/purchase-orders',
        exportParams,
        'purchase_orders_report.xlsx',
      );

      return filePath;
    } catch (e) {
      rethrow;
    }
  }

  /// Download Excel file and save to device
  Future<String> _downloadExcelFile(
    String endpoint,
    Map<String, dynamic> params,
    String fileName,
  ) async {
    try {
      // Request storage permission (but don't fail if denied)
      await _requestStoragePermission();

      // Get downloads directory (will choose best available option)
      final directory = await _getDownloadsDirectory();
      final filePath = '${directory.path}/$fileName';

      // Ensure directory exists
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Download file with binary response type
      await _dioClient.downloadFile(
        endpoint,
        filePath,
        queryParameters: params,
      );

      return filePath;
    } catch (e) {
      rethrow;
    }
  }

  /// Request storage permission (simplified approach)
  Future<bool> _requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        // Try different permissions in order of preference

        // First try storage permission (works for most Android versions)
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }

        if (status.isGranted) {
          return true;
        }

        // If storage permission failed, try manage external storage (Android 11+)
        var manageStatus = await Permission.manageExternalStorage.status;
        if (!manageStatus.isGranted) {
          manageStatus = await Permission.manageExternalStorage.request();
        }

        if (manageStatus.isGranted) {
          return true;
        }

        // If both failed, we'll use app-specific directory (no permission needed)
        return true; // We can still save to app directory
      } else {
        // iOS - no permission needed for documents directory
        return true;
      }
    } catch (e) {
      // Even if permission request fails, we can use app directory
      return true;
    }
  }

  /// Get downloads directory (smart selection based on permissions)
  Future<Directory> _getDownloadsDirectory() async {
    try {
      if (Platform.isAndroid) {
        // Check if we have storage permissions
        final hasStoragePermission = await Permission.storage.isGranted;
        final hasManagePermission =
            await Permission.manageExternalStorage.isGranted;

        if (hasStoragePermission || hasManagePermission) {
          // Try to use external storage downloads folder
          final downloadsDir = Directory('/storage/emulated/0/Download');
          try {
            // Test if we can actually write to this directory
            if (await downloadsDir.exists()) {
              return downloadsDir;
            }
          } catch (e) {
            '';
          }
        }

        // Fallback to app documents directory (always accessible)
        final appDir = await getApplicationDocumentsDirectory();
        final downloadsSubDir = Directory('${appDir.path}/Downloads');
        return downloadsSubDir;
      } else {
        // For other platforms, use documents directory
        final directory = await getApplicationDocumentsDirectory();
        return directory;
      }
    } catch (e) {
      // Ultimate fallback - app documents directory
      final directory = await getApplicationDocumentsDirectory();
      return directory;
    }
  }

  /// Export vendors report
  Future<String> exportVendorsReport(Map<String, dynamic> params) async {
    try {
      final exportParams = Map<String, dynamic>.from(params);
      exportParams['format'] = 'excel';

      final filePath = await _downloadExcelFile(
        '/reports/vendors',
        exportParams,
        'vendors_report.xlsx',
      );

      return filePath;
    } catch (e) {
      rethrow;
    }
  }

  /// Export items report
  Future<String> exportItemsReport(Map<String, dynamic> params) async {
    try {
      final exportParams = Map<String, dynamic>.from(params);
      exportParams['format'] = 'excel';

      final filePath = await _downloadExcelFile(
        '/reports/quantities',
        exportParams,
        'items_report.xlsx',
      );

      return filePath;
    } catch (e) {
      rethrow;
    }
  }

  /// Export expenses report
  Future<String> exportExpensesReport(Map<String, dynamic> params) async {
    try {
      final exportParams = Map<String, dynamic>.from(params);
      exportParams['format'] = 'excel';

      final filePath = await _downloadExcelFile(
        '/reports/expenses',
        exportParams,
        'expenses_report.xlsx',
      );

      return filePath;
    } catch (e) {
      rethrow;
    }
  }

  /// Get vendors list for dropdown
  Future<List<Map<String, dynamic>>> getVendors() async {
    try {
      final response = await _dioClient.get('/vendors');
      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['data'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get categories list for dropdown
  Future<List<String>> getCategories() async {
    // Return static categories since there's no backend endpoint for categories
    return [
      'Dairy',
      'Meat',
      'Vegetables',
      'Fruits',
      'Packaging',
      'Equipment',
      'Cleaning Supplies',
      'Office Supplies',
      'Raw Materials',
      'Other',
    ];
  }

  /// Get departments list for dropdown
  Future<List<String>> getDepartments() async {
    try {
      final response = await _dioClient.get('/departments');
      if (response['success'] == true) {
        return List<String>.from(response['data'] ?? []);
      }
      return [
        'Production',
        'Maintenance',
        'Quality Control',
        'Logistics',
        'Administration',
      ];
    } catch (e) {
      return [
        'Production',
        'Maintenance',
        'Quality Control',
        'Logistics',
        'Administration',
      ];
    }
  }

  /// Get statuses list for dropdown
  Future<List<String>> getStatuses() async {
    return [
      'draft',
      'under_assistant_review',
      'under_manager_review',
      'in_progress',
      'completed',
      'rejected_by_assistant',
      'rejected_by_manager',
    ];
  }
}
