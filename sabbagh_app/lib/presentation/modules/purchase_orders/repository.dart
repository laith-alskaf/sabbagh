import 'dart:io';

import 'package:dio/dio.dart' show MultipartFile;
import 'package:path/path.dart' as p;
import 'package:sabbagh_app/core/services/dio_client.dart';
import 'package:sabbagh_app/data/dto/purchase_order_dto.dart';
import 'package:sabbagh_app/domain/entities/purchase_order.dart';
import 'package:sabbagh_app/domain/entities/purchase_order_item.dart';
import 'package:sabbagh_app/domain/entities/purchase_order_note.dart';
import 'package:sabbagh_app/domain/entities/purchase_order_workflow.dart';

/// Repository for purchase orders with proper backend integration
class PurchaseOrderRepository {
  final DioClient _dioClient;

  /// Creates a new [PurchaseOrderRepository]
  PurchaseOrderRepository(this._dioClient);

  /// Get purchase orders (for managers and assistant managers)
  /// This endpoint shows all purchase orders based on user role
  Future<List<PurchaseOrder>> getPurchaseOrders({
    String? status,
    String? supplierId,
    String? department,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };

      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }
      if (supplierId != null && supplierId.isNotEmpty) {
        queryParameters['supplier_id'] = supplierId;
      }
      if (department != null && department.isNotEmpty) {
        queryParameters['department'] = department;
      }
      if (startDate != null) {
        queryParameters['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParameters['end_date'] = endDate.toIso8601String();
      }

      final response = await _dioClient.get(
        '/purchase-orders',
        queryParameters: queryParameters,
      );

      final apiResponse = PurchaseOrderListApiResponse.fromJson(response);

      if (apiResponse.success) {
        return apiResponse.data.map(_mapDtoToEntity).toList();
      } else {
        throw Exception(
          apiResponse.message ?? 'Failed to fetch purchase orders',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get my purchase orders (for employees - only their own orders)
  Future<List<PurchaseOrder>> getMyPurchaseOrders({
    String? status,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };

      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }

      final response = await _dioClient.get(
        '/purchase-orders/my',
        queryParameters: queryParameters,
      );
      if (response['success'] == true) {
        final apiResponse = PurchaseOrderListApiResponse.fromJson(response);
        return apiResponse.data.map(_mapDtoToEntity).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Get purchase orders pending assistant review
  /// Only accessible by assistant managers and managers
  Future<List<PurchaseOrder>> getPurchaseOrdersPendingAssistantReview({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await _dioClient.get(
        '/purchase-orders/pending/assistant',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      final apiResponse = PurchaseOrderListApiResponse.fromJson(response);

      if (apiResponse.success) {
        return apiResponse.data.map(_mapDtoToEntity).toList();
      } else {
        throw Exception(
          apiResponse.message ??
              'Failed to fetch pending assistant review orders',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get purchase orders pending manager review
  /// Only accessible by managers
  Future<List<PurchaseOrder>> getPurchaseOrdersPendingManagerReview({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await _dioClient.get(
        '/purchase-orders/pending/manager',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      final apiResponse = PurchaseOrderListApiResponse.fromJson(response);

      if (apiResponse.success) {
        return apiResponse.data.map(_mapDtoToEntity).toList();
      } else {
        throw Exception(
          apiResponse.message ??
              'Failed to fetch pending manager review orders',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get purchase order by ID
  Future<PurchaseOrder> getPurchaseOrderById(String id) async {
    try {
      final response = await _dioClient.get('/purchase-orders/$id');
      final apiResponse = PurchaseOrderApiResponse.fromJson(response);

      if (apiResponse.success && apiResponse.data != null) {
        return _mapDtoToEntity(apiResponse.data!);
      } else {
        throw Exception(apiResponse.message ?? 'Purchase order not found');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Create purchase order (supports optional images via multipart)
  Future<PurchaseOrder> createPurchaseOrder(
    Map<String, dynamic> data, {
    List<File> images = const [],
  }) async {
    try {
      _validateCreatePurchaseOrderData(data);
      final requestDto = _mapCreateDataToDto(data);

      // Prepare files
      final files = <MultipartFile>[];
      for (final f in images) {
        files.add(
          await MultipartFile.fromFile(f.path, filename: p.basename(f.path)),
        );
      }

      final response = await _dioClient.postMultipart(
        '/purchase-orders',
        payload: requestDto.toJson(),
        files: files,
      );

      final apiResponse = PurchaseOrderApiResponse.fromJson(response);

      if (apiResponse.success && apiResponse.data != null) {
        return _mapDtoToEntity(apiResponse.data!);
      } else {
        throw Exception(
          apiResponse.message ?? 'Failed to create purchase order',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update purchase order (supports optional images via multipart)
  Future<PurchaseOrder> updatePurchaseOrder(
    String id,
    Map<String, dynamic> data, {
    List<File> images = const [],
  }) async {
    try {
      final requestDto = _mapUpdateDataToDto(data);

      final files = <MultipartFile>[];
      for (final f in images) {
        files.add(
          await MultipartFile.fromFile(f.path, filename: p.basename(f.path)),
        );
      }

      final response = await _dioClient.putMultipart(
        '/purchase-orders/$id',
        payload: requestDto.toJson(),
        files: files,
      );

      final apiResponse = PurchaseOrderApiResponse.fromJson(response);

      if (apiResponse.success && apiResponse.data != null) {
        return _mapDtoToEntity(apiResponse.data!);
      } else {
        throw Exception(
          apiResponse.message ?? 'Failed to update purchase order',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete purchase order
  Future<bool> deletePurchaseOrder(String id) async {
    try {
      await _dioClient.delete('/purchase-orders/$id');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetch user name by ID (cached upstream by caller if needed)
  Future<String?> getUserNameById(String id) async {
    try {
      final response = await _dioClient.get('/admin/users/$id');
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        return data['name'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Submit purchase order for review
  Future<PurchaseOrder> submitPurchaseOrder(String id) async {
    try {
      final response = await _dioClient.patch('/purchase-orders/$id/submit');

      final apiResponse = PurchaseOrderApiResponse.fromJson(response);

      if (apiResponse.success && apiResponse.data != null) {
        return _mapDtoToEntity(apiResponse.data!);
      } else {
        throw Exception(
          apiResponse.message ?? 'Failed to submit purchase order',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Assistant approve purchase order
  Future<PurchaseOrder> assistantApprovePurchaseOrder(
    String id, {
    String? notes,
  }) async {
    try {
      final requestDto = ApproveRejectRequestDto(reason: notes);

      final response = await _dioClient.patch(
        '/purchase-orders/$id/assistant-approve',
        data: requestDto.toJson(),
      );

      final apiResponse = PurchaseOrderApiResponse.fromJson(response);

      if (apiResponse.success && apiResponse.data != null) {
        return _mapDtoToEntity(apiResponse.data!);
      } else {
        throw Exception(
          apiResponse.message ?? 'Failed to approve purchase order',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Assistant reject purchase order
  Future<PurchaseOrder> assistantRejectPurchaseOrder(
    String id,
    String reason,
  ) async {
    try {
      final requestDto = ApproveRejectRequestDto(reason: reason);

      final response = await _dioClient.patch(
        '/purchase-orders/$id/assistant-reject',
        data: requestDto.toJson(),
      );

      final apiResponse = PurchaseOrderApiResponse.fromJson(response);

      if (apiResponse.success && apiResponse.data != null) {
        return _mapDtoToEntity(apiResponse.data!);
      } else {
        throw Exception(
          apiResponse.message ?? 'Failed to reject purchase order',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Manager approve purchase order
  Future<PurchaseOrder> managerApprovePurchaseOrder(
    String id, {
    String? notes,
  }) async {
    try {
      final requestDto = ApproveRejectRequestDto(reason: notes);

      final response = await _dioClient.patch(
        '/purchase-orders/$id/manager-approve',
        data: requestDto.toJson(),
      );

      final apiResponse = PurchaseOrderApiResponse.fromJson(response);

      if (apiResponse.success && apiResponse.data != null) {
        return _mapDtoToEntity(apiResponse.data!);
      } else {
        throw Exception(
          apiResponse.message ?? 'Failed to approve purchase order',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Manager reject purchase order
  Future<PurchaseOrder> managerRejectPurchaseOrder(
    String id,
    String reason,
  ) async {
    try {
      final requestDto = ApproveRejectRequestDto(reason: reason);

      final response = await _dioClient.patch(
        '/purchase-orders/$id/manager-reject',
        data: requestDto.toJson(),
      );

      final apiResponse = PurchaseOrderApiResponse.fromJson(response);

      if (apiResponse.success && apiResponse.data != null) {
        return _mapDtoToEntity(apiResponse.data!);
      } else {
        throw Exception(
          apiResponse.message ?? 'Failed to reject purchase order',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Complete purchase order
  Future<PurchaseOrder> completePurchaseOrder(String id) async {
    try {
      final response = await _dioClient.patch('/purchase-orders/$id/complete');

      final apiResponse = PurchaseOrderApiResponse.fromJson(response);
  
    if (apiResponse.success && apiResponse.data != null) {
        return _mapDtoToEntity(apiResponse.data!);
      } else {
        throw Exception(
          apiResponse.message ?? 'Failed to complete purchase order',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get workflow for a completed purchase order
  Future<List<PurchaseOrderWorkflowStep>> getPurchaseOrderWorkflow(String id) async {
    try {
      final response = await _dioClient.get('/purchase-orders/$id/workflow');
      if (response is Map<String, dynamic> && response['success'] == true) {
        final List data = response['data'] as List;
        return data.map((e) => PurchaseOrderWorkflowStep.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

      
  

  // ===== Notes Feature =====

  /// Fetch notes for a purchase order
  Future<List<PurchaseOrderNote>> getPurchaseOrderNotes(String id) async {
    try {
      final response = await _dioClient.get('/purchase-orders/$id/notes');
      if (response is Map<String, dynamic> && response['success'] == true) {
        final List<dynamic> list = response['data'] as List<dynamic>;
        return list
            .map((e) => PurchaseOrderNote.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      // Fallback to direct list
      if (response is List) {
        return response
            .map((e) => PurchaseOrderNote.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Add a note to a purchase order
  Future<PurchaseOrderNote> addPurchaseOrderNote(String id, String note) async {
    try {
      final response = await _dioClient.post(
        '/purchase-orders/$id/notes',
        data: {'note': note},
      );
      if (response is Map<String, dynamic> && response['success'] == true) {
        return PurchaseOrderNote.fromJson(
          response['data'] as Map<String, dynamic>,
        );
      }
      if (response is Map<String, dynamic>) {
        return PurchaseOrderNote.fromJson(response);
      }
      throw Exception('Invalid response');
    } catch (e) {
      rethrow;
    }
  }

  /// Route purchase order (assistant or manager)
  Future<PurchaseOrder> routePurchaseOrder(
    String id, {
    required String next, // 'finance' | 'gm' | 'procurement'
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        'next': next,
        if (notes != null) 'notes': notes,
      };
      final response = await _dioClient.patch(
        '/purchase-orders/$id/route',
        data: body,
      );
      final apiResponse = PurchaseOrderApiResponse.fromJson(response);
      if (apiResponse.success && apiResponse.data != null) {
        return _mapDtoToEntity(apiResponse.data!);
      } else {
        throw Exception(
          apiResponse.message ?? 'Failed to route purchase order',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Finance approve/reject
  Future<PurchaseOrder> financeApprove(String id) async {
    try {
      final response = await _dioClient.patch(
        '/purchase-orders/$id/finance-approve',
      );
      final apiResponse = PurchaseOrderApiResponse.fromJson(response);
      if (apiResponse.success && apiResponse.data != null) {
        return _mapDtoToEntity(apiResponse.data!);
      } else {
        throw Exception(apiResponse.message ?? 'Failed to approve by finance');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<PurchaseOrder> financeReject(String id, String reason) async {
    try {
      final response = await _dioClient.patch(
        '/purchase-orders/$id/finance-reject',
        data: ApproveRejectRequestDto(reason: reason).toJson(),
      );
      final apiResponse = PurchaseOrderApiResponse.fromJson(response);
      if (apiResponse.success && apiResponse.data != null) {
        return _mapDtoToEntity(apiResponse.data!);
      } else {
        throw Exception(apiResponse.message ?? 'Failed to reject by finance');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// General manager approve/reject
  Future<PurchaseOrder> generalManagerApprove(String id) async {
    try {
      final response = await _dioClient.patch(
        '/purchase-orders/$id/gm-approve',
      );
      final apiResponse = PurchaseOrderApiResponse.fromJson(response);
      if (apiResponse.success && apiResponse.data != null) {
        return _mapDtoToEntity(apiResponse.data!);
      } else {
        throw Exception(apiResponse.message ?? 'Failed to approve by GM');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<PurchaseOrder> generalManagerReject(String id, String reason) async {
    try {
      final response = await _dioClient.patch(
        '/purchase-orders/$id/gm-reject',
        data: ApproveRejectRequestDto(reason: reason).toJson(),
      );
      final apiResponse = PurchaseOrderApiResponse.fromJson(response);
      if (apiResponse.success && apiResponse.data != null) {
        return _mapDtoToEntity(apiResponse.data!);
      } else {
        throw Exception(apiResponse.message ?? 'Failed to reject by GM');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Procurement update (supports optional images via multipart)
  Future<PurchaseOrder> procurementUpdate(
    String id, {
    required List<Map<String, dynamic>> items,
    List<File> images = const [],
  }) async {
    try {
      final payload = <String, dynamic>{'items': items};

      final files = <MultipartFile>[];
      for (final f in images) {
        files.add(
          await MultipartFile.fromFile(f.path, filename: p.basename(f.path)),
        );
      }

      final response = await _dioClient.patchMultipart(
        '/purchase-orders/$id/procurement-update',
        payload: payload,
        files: files,
      );
      final apiResponse = PurchaseOrderApiResponse.fromJson(response);
      if (apiResponse.success && apiResponse.data != null) {
        return _mapDtoToEntity(apiResponse.data!);
      } else {
        throw Exception(apiResponse.message ?? 'Failed to update procurement');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Return to manager for final review
  Future<PurchaseOrder> returnToManagerForFinalReview(String id) async {
    try {
      final response = await _dioClient.patch(
        '/purchase-orders/$id/return-to-manager',
      );
      final apiResponse = PurchaseOrderApiResponse.fromJson(response);
      if (apiResponse.success && apiResponse.data != null) {
        return _mapDtoToEntity(apiResponse.data!);
      } else {
        throw Exception(apiResponse.message ?? 'Failed to return to manager');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Manager final approve/reject
  Future<PurchaseOrder> managerFinalApprove(String id) async {
    try {
      final response = await _dioClient.patch(
        '/purchase-orders/$id/manager-final-approve',
      );
      final apiResponse = PurchaseOrderApiResponse.fromJson(response);
      if (apiResponse.success && apiResponse.data != null) {
        return _mapDtoToEntity(apiResponse.data!);
      } else {
        throw Exception(apiResponse.message ?? 'Failed to final approve');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<PurchaseOrder> managerFinalReject(String id, String reason) async {
    try {
      final response = await _dioClient.patch(
        '/purchase-orders/$id/manager-final-reject',
        data: ApproveRejectRequestDto(reason: reason).toJson(),
      );
      final apiResponse = PurchaseOrderApiResponse.fromJson(response);
      if (apiResponse.success && apiResponse.data != null) {
        return _mapDtoToEntity(apiResponse.data!);
      } else {
        throw Exception(apiResponse.message ?? 'Failed to final reject');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get items list for dropdown
  Future<List<Map<String, dynamic>>> getItems({
    String? search,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'status': 'active', // Only active items
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _dioClient.get(
        '/items',
        queryParameters: queryParams,
      );
      if (response['success'] == true) {
        final items = response['data'] as List;

        // Handle case where items might be strings or objects
        return items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          if (item is String) {
            // If item is just a string, use it as name
            return {
              'id': item,
              'name': item,
              'code': null,
              'unit': 'piece',
              'price': 0.0,
              'createdAt': "",
              'updatedAt': "",
            };
          } else if (item is Map) {
            // If item is an object, extract fields
            return {
              'id': item['id']?.toString() ?? '0000',
              'name': item['name']?.toString() ?? item.toString(),
              'code': item['code']?.toString() ?? '0000',
              'unit': item['unit']?.toString() ?? 'piece',
              'status': item['status']?.toString() ?? 'active',
              'description': item['description']?.toString() ?? '',
              'created_at': item['created_at']?.toString() ?? "",
              'updated_at': item['updated_at']?.toString() ?? "",
            };
          } else {
            // Fallback case
            return {
              'id': item['id']?.toString() ?? index.toString(),
              'name': item['name']?.toString() ?? item.toString(),
              'code': item['code']?.toString() ?? '0000',
              'unit': item['unit']?.toString() ?? 'piece',
              'status': item['status']?.toString() ?? 'active',
              'description': item['description']?.toString() ?? '',
              'created_at': item['created_at']?.toString() ?? "",
              'updated_at': item['updated_at']?.toString() ?? "",
            };
          }
        }).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get item by ID
  Future<Map<String, dynamic>?> getItemById(String id) async {
    try {
      final response = await _dioClient.get('/items/$id');

      if (response['success'] == true) {
        final item = response['data'];
        return {
          'id': item['id'],
          'name': item['name'],
          'code': item['code'],
          'unit': item['unit'] ?? 'piece',
          'price': item['price'] ?? 0.0,
        };
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Upload attachment (placeholder - implement when backend provides endpoint)
  Future<String> uploadAttachment(String id, String filePath) async {
    try {
      // TODO: Implement when backend provides file upload endpoint
      // For now, return a placeholder URL
      return 'https://example.com/attachments/purchase-order-$id.pdf';
    } catch (e) {
      rethrow;
    }
  }

  /// Get departments list for dropdown
  Future<List<Map<String, dynamic>>> getDepartments() async {
    try {
      final response = await _dioClient.get('/departments');

      if (response['success'] == true) {
        final departments = response['data'] as List;

        // Handle case where departments are just strings
        return departments.asMap().entries.map((entry) {
          final index = entry.key;
          final dept = entry.value;

          if (dept is String) {
            // If department is just a string, use it as both id and name
            return {'id': dept, 'name': dept};
          } else if (dept is Map) {
            // If department is an object, extract id and name
            return {
              'id': dept['id']?.toString() ?? index.toString(),
              'name': dept['name']?.toString() ?? dept.toString(),
            };
          } else {
            // Fallback case
            return {'id': index.toString(), 'name': dept.toString()};
          }
        }).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get suppliers list for dropdown
  Future<List<Map<String, dynamic>>> getSuppliers() async {
    try {
      final response = await _dioClient.get('/vendors');

      if (response['success'] == true) {
        final suppliers = response['data'] as List;

        // Handle case where suppliers might be strings or objects
        return suppliers.asMap().entries.map((entry) {
          final index = entry.key;
          final supplier = entry.value;

          if (supplier is String) {
            // If supplier is just a string, use it as both id and name
            return {
              'id': supplier,
              'name': supplier,
              'contact_person': null,
              'phone': null,
            };
          } else if (supplier is Map) {
            // If supplier is an object, extract fields
            return {
              'id': supplier['id']?.toString() ?? index.toString(),
              'name': supplier['name']?.toString() ?? supplier.toString(),
              'contact_person': supplier['contact_person']?.toString(),
              'phone': supplier['phone']?.toString(),
            };
          } else {
            // Fallback case
            return {
              'id': index.toString(),
              'name': supplier.toString(),
              'contact_person': null,
              'phone': null,
            };
          }
        }).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // Private helper methods

  /// Map DTO to Entity
  PurchaseOrder _mapDtoToEntity(PurchaseOrderDto dto) {
    return PurchaseOrder(
      id: dto.id,
      number: dto.number,
      requesterId: dto.createdBy,
      requesterName: dto.requesterName,
      department: dto.department,
      type: PurchaseOrderType.fromString(dto.requestType),
      status: PurchaseOrderStatus.fromString(dto.status),
      requestDate: DateTime.parse(dto.requestDate),
      executionDate:
          dto.executionDate != null ? DateTime.parse(dto.executionDate!) : null,
      notes: dto.notes,
      vendorId: dto.supplierId,
      vendorName: dto.supplierName,
      currency: dto.currency,
      attachmentUrls: dto.attachmentUrls ?? [],
      items: dto.items.map(_mapItemDtoToEntity).toList(),
      totalAmount: dto.totalAmount,
      rejectionReason: null, // Backend doesn't provide this field directly
      rejectedBy: null, // Backend doesn't provide this field directly
      approvedByAssistant: null, // Backend doesn't provide this field directly
      approvedByManager: null, // Backend doesn't provide this field directly
      createdAt: DateTime.parse(dto.createdAt),
      updatedAt: DateTime.parse(dto.updatedAt),
    );
  }

  /// Map Item DTO to Entity
  PurchaseOrderItem _mapItemDtoToEntity(PurchaseOrderItemDto dto) {
    return PurchaseOrderItem(
      id: dto.id,
      purchaseOrderId: dto.purchaseOrderId,
      itemId: dto.itemId,
      itemCode: dto.itemCode,
      itemName: dto.itemName ?? '',
      quantity: dto.quantity,
      unit: dto.unit,
      receivedQuantity: dto.receivedQuantity,
      price: dto.price,
      lineTotal: dto.lineTotal,
      currency: dto.currency,
    );
  }

  /// Map create data to DTO
  CreatePurchaseOrderRequestDto _mapCreateDataToDto(Map<String, dynamic> data) {
    return CreatePurchaseOrderRequestDto(
      requestDate: data['request_date'],
      department: data['department'],
      requestType: data['request_type'],
      requesterName: data['requester_name'],
      notes: data['notes'] ?? '',
      items:
          (data['items'] as List<dynamic>)
              .map(
                (item) => _mapCreateItemDataToDto(item as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  /// Map create item data to DTO
  CreatePurchaseOrderItemRequestDto _mapCreateItemDataToDto(
    Map<String, dynamic> data,
  ) {
    return CreatePurchaseOrderItemRequestDto(
      itemName: data['item_name'],
      quantity: (data['quantity'] as num).toDouble(),
      unit: data['unit'],
      price:
          data.containsKey('price') && data['price'] != null
              ? (data['price'] as num).toDouble()
              : null,
      currency:
          data.containsKey('currency') && data['currency'] != null
              ? data['currency'] as String?
              : null,
      itemCode:
          data.containsKey('item_code') && data['item_code'] != null
              ? data['item_code'] as String?
              : null,
    );
  }

  /// Map update data to DTO
  UpdatePurchaseOrderRequestDto _mapUpdateDataToDto(Map<String, dynamic> data) {
    return UpdatePurchaseOrderRequestDto(
      requestDate: data['request_date'],
      department: data['department'],
      requestType: data['request_type'],
      requesterName: data['requester_name'],
      notes: data['notes'],
      supplierId: data['supplier_id'],
      executionDate: data['execution_date'],
      attachmentUrls: data['attachment_url'] ?? [],
      totalAmount: data['total_amount'],
      currency: data['currency'],
      items:
          data['items'] != null
              ? (data['items'] as List<dynamic>)
                  .map(
                    (item) =>
                        _mapCreateItemDataToDto(item as Map<String, dynamic>),
                  )
                  .toList()
              : null,
    );
  }

  /// Validate create purchase order data
  void _validateCreatePurchaseOrderData(Map<String, dynamic> data) {
    if (data['department'] == null || data['department'].toString().isEmpty) {
      throw Exception('Department is required');
    }
    if (data['requester_name'] == null ||
        data['requester_name'].toString().isEmpty) {
      throw Exception('Requester name is required');
    }
    if (data['request_type'] == null ||
        data['request_type'].toString().isEmpty) {
      throw Exception('Request type is required');
    }

    if (data['items'] == null || (data['items'] as List).isEmpty) {
      throw Exception('At least one item is required');
    }
  }
}
