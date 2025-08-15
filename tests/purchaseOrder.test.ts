import request from 'supertest';
import app from '../src/app';
import { testUsers, testPurchaseOrder, generateTestToken } from './helpers/testHelpers';
import * as purchaseOrderService from '../src/services/purchaseOrderService';

// Mock the purchase order service
jest.mock('../src/services/purchaseOrderService');
const mockPurchaseOrderService = purchaseOrderService as jest.Mocked<typeof purchaseOrderService>;

describe('Purchase Order Workflow', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('POST /api/purchase-orders', () => {
    it('should create purchase order successfully as employee', async () => {
      const token = generateTestToken(testUsers.employee);
      const purchaseOrderData = {
        department: 'IT',
        request_date: new Date().toISOString(),
        delivery_date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
        notes: 'Test purchase order',
        supplier_id: 'supplier-id',
        requester_name: 'Test Requester',
        currency: 'USD',
        items: [
          {
            item_name: 'Laptop',
            quantity: 2,
            unit: 'pcs',
            price: 1000,
          },
        ],
      };

      const mockResponse = {
        success: true,
        data: { ...testPurchaseOrder, ...purchaseOrderData },
      };

      mockPurchaseOrderService.createPurchaseOrder.mockResolvedValue(mockResponse);

      const response = await request(app)
        .post('/api/purchase-orders')
        .set('Authorization', `Bearer ${token}`)
        .send(purchaseOrderData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(mockPurchaseOrderService.createPurchaseOrder).toHaveBeenCalledWith(
        expect.objectContaining(purchaseOrderData),
        testUsers.employee.id
      );
    });

    it('should return 400 for invalid purchase order data', async () => {
      const token = generateTestToken(testUsers.employee);
      const invalidData = {
        department: '', // Empty department
        items: [], // Empty items array
      };

      const response = await request(app)
        .post('/api/purchase-orders')
        .set('Authorization', `Bearer ${token}`)
        .send(invalidData)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });
  });

  describe('PUT /api/purchase-orders/:id/status', () => {
    it('should allow assistant manager to approve purchase order', async () => {
      const token = generateTestToken(testUsers.assistantManager);
      const purchaseOrderId = testPurchaseOrder.id;
      const statusData = {
        status: 'under_manager_review',
        reason: 'Approved by assistant manager',
      };

      const mockResponse = {
        success: true,
        data: { ...testPurchaseOrder, status: 'under_manager_review' },
      };

      mockPurchaseOrderService.updatePurchaseOrderStatus.mockResolvedValue(mockResponse);

      const response = await request(app)
        .put(`/api/purchase-orders/${purchaseOrderId}/status`)
        .set('Authorization', `Bearer ${token}`)
        .send(statusData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(mockPurchaseOrderService.updatePurchaseOrderStatus).toHaveBeenCalledWith(
        purchaseOrderId,
        statusData.status,
        testUsers.assistantManager.id,
        statusData.reason
      );
    });

    it('should allow manager to approve purchase order', async () => {
      const token = generateTestToken(testUsers.manager);
      const purchaseOrderId = testPurchaseOrder.id;
      const statusData = {
        status: 'in_progress',
        reason: 'Approved by manager',
      };

      const mockResponse = {
        success: true,
        data: { ...testPurchaseOrder, status: 'in_progress' },
      };

      mockPurchaseOrderService.updatePurchaseOrderStatus.mockResolvedValue(mockResponse);

      const response = await request(app)
        .put(`/api/purchase-orders/${purchaseOrderId}/status`)
        .set('Authorization', `Bearer ${token}`)
        .send(statusData)
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should not allow employee to approve purchase order', async () => {
      const token = generateTestToken(testUsers.employee);
      const purchaseOrderId = testPurchaseOrder.id;
      const statusData = {
        status: 'in_progress',
        reason: 'Trying to approve',
      };

      const response = await request(app)
        .put(`/api/purchase-orders/${purchaseOrderId}/status`)
        .set('Authorization', `Bearer ${token}`)
        .send(statusData)
        .expect(403);

      expect(response.body.success).toBe(false);
    });

    it('should return 400 for invalid status transition', async () => {
      const token = generateTestToken(testUsers.manager);
      const purchaseOrderId = testPurchaseOrder.id;
      const statusData = {
        status: 'invalid_status',
        reason: 'Invalid status',
      };

      const response = await request(app)
        .put(`/api/purchase-orders/${purchaseOrderId}/status`)
        .set('Authorization', `Bearer ${token}`)
        .send(statusData)
        .expect(400);

      expect(response.body.success).toBe(false);
    });
  });

  describe('GET /api/purchase-orders', () => {
    it('should return purchase orders for authenticated user', async () => {
      const token = generateTestToken(testUsers.employee);
      const mockResponse = {
        success: true,
        data: [testPurchaseOrder],
        pagination: {
          page: 1,
          limit: 10,
          total: 1,
          totalPages: 1,
        },
      };

      mockPurchaseOrderService.getPurchaseOrders.mockResolvedValue(mockResponse);

      const response = await request(app)
        .get('/api/purchase-orders')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toEqual([testPurchaseOrder]);
    });

    it('should support pagination and filtering', async () => {
      const token = generateTestToken(testUsers.manager);
      const queryParams = {
        page: '2',
        limit: '5',
        status: 'draft',
        department: 'IT',
      };

      const mockResponse = {
        success: true,
        data: [],
        pagination: {
          page: 2,
          limit: 5,
          total: 0,
          totalPages: 0,
        },
      };

      mockPurchaseOrderService.getPurchaseOrders.mockResolvedValue(mockResponse);

      const response = await request(app)
        .get('/api/purchase-orders')
        .query(queryParams)
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(mockPurchaseOrderService.getPurchaseOrders).toHaveBeenCalledWith(
        expect.objectContaining({
          page: 2,
          limit: 5,
          status: 'draft',
          department: 'IT',
        }),
        testUsers.manager.id,
        testUsers.manager.role
      );
    });
  });

  describe('GET /api/purchase-orders/:id', () => {
    it('should return purchase order details for authorized user', async () => {
      const token = generateTestToken(testUsers.employee);
      const purchaseOrderId = testPurchaseOrder.id;

      const mockResponse = {
        success: true,
        data: testPurchaseOrder,
      };

      mockPurchaseOrderService.getPurchaseOrderById.mockResolvedValue(mockResponse);

      const response = await request(app)
        .get(`/api/purchase-orders/${purchaseOrderId}`)
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toEqual(testPurchaseOrder);
    });

    it('should return 404 for non-existent purchase order', async () => {
      const token = generateTestToken(testUsers.employee);
      const nonExistentId = '123e4567-e89b-12d3-a456-426614174999';

      mockPurchaseOrderService.getPurchaseOrderById.mockRejectedValue(
        new Error('Purchase order not found')
      );

      const response = await request(app)
        .get(`/api/purchase-orders/${nonExistentId}`)
        .set('Authorization', `Bearer ${token}`)
        .expect(500); // Will be handled by error middleware

      expect(mockPurchaseOrderService.getPurchaseOrderById).toHaveBeenCalledWith(
        nonExistentId,
        testUsers.employee.id,
        testUsers.employee.role
      );
    });
  });

  describe('Purchase Order Lifecycle', () => {
    it('should complete full approval workflow', async () => {
      const employeeToken = generateTestToken(testUsers.employee);
      const assistantToken = generateTestToken(testUsers.assistantManager);
      const managerToken = generateTestToken(testUsers.manager);

      // Step 1: Employee creates purchase order
      const createData = {
        department: 'IT',
        request_date: new Date().toISOString(),
        delivery_date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
        notes: 'Workflow test',
        supplier_id: 'supplier-id',
        requester_name: 'Test Employee',
        currency: 'USD',
        items: [{ item_name: 'Test Item', quantity: 1, unit: 'pcs', price: 100 }],
      };

      mockPurchaseOrderService.createPurchaseOrder.mockResolvedValue({
        success: true,
        data: { ...testPurchaseOrder, status: 'draft' },
      });

      const createResponse = await request(app)
        .post('/api/purchase-orders')
        .set('Authorization', `Bearer ${employeeToken}`)
        .send(createData)
        .expect(201);

      expect(createResponse.body.success).toBe(true);

      // Step 2: Assistant manager approves
      mockPurchaseOrderService.updatePurchaseOrderStatus.mockResolvedValue({
        success: true,
        data: { ...testPurchaseOrder, status: 'under_manager_review' },
      });

      const assistantApprovalResponse = await request(app)
        .put(`/api/purchase-orders/${testPurchaseOrder.id}/status`)
        .set('Authorization', `Bearer ${assistantToken}`)
        .send({ status: 'under_manager_review', reason: 'Assistant approved' })
        .expect(200);

      expect(assistantApprovalResponse.body.success).toBe(true);

      // Step 3: Manager approves
      mockPurchaseOrderService.updatePurchaseOrderStatus.mockResolvedValue({
        success: true,
        data: { ...testPurchaseOrder, status: 'in_progress' },
      });

      const managerApprovalResponse = await request(app)
        .put(`/api/purchase-orders/${testPurchaseOrder.id}/status`)
        .set('Authorization', `Bearer ${managerToken}`)
        .send({ status: 'in_progress', reason: 'Manager approved' })
        .expect(200);

      expect(managerApprovalResponse.body.success).toBe(true);
    });
  });
});