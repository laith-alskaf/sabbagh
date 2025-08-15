import request from 'supertest';
import app from '../src/app';
import { testUsers, testChangeRequest, generateTestToken } from './helpers/testHelpers';
import * as changeRequestService from '../src/services/changeRequestService';

// Mock the change request service
jest.mock('../src/services/changeRequestService');
const mockChangeRequestService = changeRequestService as jest.Mocked<typeof changeRequestService>;

describe('Change Request Approval Workflow', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('POST /api/change-requests', () => {
    it('should create vendor change request successfully', async () => {
      const token = generateTestToken(testUsers.employee);
      const changeRequestData = {
        operation_type: 'create',
        entity_type: 'vendor',
        data: {
          name: 'New Vendor',
          contact_person: 'John Smith',
          phone: '+1234567890',
          email: 'newvendor@test.com',
          address: '123 New Street',
          status: 'active',
        },
      };

      const mockResponse = {
        success: true,
        data: { ...testChangeRequest, ...changeRequestData },
      };

      mockChangeRequestService.createChangeRequest.mockResolvedValue(mockResponse);

      const response = await request(app)
        .post('/api/change-requests')
        .set('Authorization', `Bearer ${token}`)
        .send(changeRequestData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(mockChangeRequestService.createChangeRequest).toHaveBeenCalledWith(
        expect.objectContaining(changeRequestData),
        testUsers.employee.id
      );
    });

    it('should create item change request successfully', async () => {
      const token = generateTestToken(testUsers.employee);
      const changeRequestData = {
        operation_type: 'create',
        entity_type: 'item',
        data: {
          name: 'New Item',
          code: 'NEW-001',
          description: 'New item description',
          unit: 'pcs',
          status: 'active',
        },
      };

      const mockResponse = {
        success: true,
        data: { ...testChangeRequest, ...changeRequestData },
      };

      mockChangeRequestService.createChangeRequest.mockResolvedValue(mockResponse);

      const response = await request(app)
        .post('/api/change-requests')
        .set('Authorization', `Bearer ${token}`)
        .send(changeRequestData)
        .expect(201);

      expect(response.body.success).toBe(true);
    });

    it('should require entity_id for update operations', async () => {
      const token = generateTestToken(testUsers.employee);
      const changeRequestData = {
        operation_type: 'update',
        entity_type: 'vendor',
        // Missing entity_id
        data: {
          name: 'Updated Vendor Name',
        },
      };

      const response = await request(app)
        .post('/api/change-requests')
        .set('Authorization', `Bearer ${token}`)
        .send(changeRequestData)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            field: 'entity_id',
          }),
        ])
      );
    });

    it('should validate data is not empty', async () => {
      const token = generateTestToken(testUsers.employee);
      const changeRequestData = {
        operation_type: 'create',
        entity_type: 'vendor',
        data: {}, // Empty data
      };

      const response = await request(app)
        .post('/api/change-requests')
        .set('Authorization', `Bearer ${token}`)
        .send(changeRequestData)
        .expect(400);

      expect(response.body.success).toBe(false);
    });
  });

  describe('PUT /api/change-requests/:id/process', () => {
    it('should allow manager to approve change request', async () => {
      const token = generateTestToken(testUsers.manager);
      const changeRequestId = testChangeRequest.id;
      const processData = {
        action: 'approve',
        reason: 'Approved by manager',
      };

      const mockResponse = {
        success: true,
        data: { ...testChangeRequest, status: 'approved' },
      };

      mockChangeRequestService.processChangeRequest.mockResolvedValue(mockResponse);

      const response = await request(app)
        .put(`/api/change-requests/${changeRequestId}/process`)
        .set('Authorization', `Bearer ${token}`)
        .send(processData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(mockChangeRequestService.processChangeRequest).toHaveBeenCalledWith(
        changeRequestId,
        processData.action,
        testUsers.manager.id,
        processData.reason
      );
    });

    it('should allow assistant manager to approve change request', async () => {
      const token = generateTestToken(testUsers.assistantManager);
      const changeRequestId = testChangeRequest.id;
      const processData = {
        action: 'approve',
        reason: 'Approved by assistant manager',
      };

      const mockResponse = {
        success: true,
        data: { ...testChangeRequest, status: 'approved' },
      };

      mockChangeRequestService.processChangeRequest.mockResolvedValue(mockResponse);

      const response = await request(app)
        .put(`/api/change-requests/${changeRequestId}/process`)
        .set('Authorization', `Bearer ${token}`)
        .send(processData)
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should not allow employee to approve change request', async () => {
      const token = generateTestToken(testUsers.employee);
      const changeRequestId = testChangeRequest.id;
      const processData = {
        action: 'approve',
        reason: 'Trying to approve',
      };

      const response = await request(app)
        .put(`/api/change-requests/${changeRequestId}/process`)
        .set('Authorization', `Bearer ${token}`)
        .send(processData)
        .expect(403);

      expect(response.body.success).toBe(false);
    });

    it('should require reason when rejecting', async () => {
      const token = generateTestToken(testUsers.manager);
      const changeRequestId = testChangeRequest.id;
      const processData = {
        action: 'reject',
        // Missing reason
      };

      const response = await request(app)
        .put(`/api/change-requests/${changeRequestId}/process`)
        .set('Authorization', `Bearer ${token}`)
        .send(processData)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            field: 'reason',
          }),
        ])
      );
    });

    it('should allow rejection with reason', async () => {
      const token = generateTestToken(testUsers.manager);
      const changeRequestId = testChangeRequest.id;
      const processData = {
        action: 'reject',
        reason: 'Insufficient information provided',
      };

      const mockResponse = {
        success: true,
        data: { ...testChangeRequest, status: 'rejected' },
      };

      mockChangeRequestService.processChangeRequest.mockResolvedValue(mockResponse);

      const response = await request(app)
        .put(`/api/change-requests/${changeRequestId}/process`)
        .set('Authorization', `Bearer ${token}`)
        .send(processData)
        .expect(200);

      expect(response.body.success).toBe(true);
    });
  });

  describe('GET /api/change-requests', () => {
    it('should return change requests for authenticated user', async () => {
      const token = generateTestToken(testUsers.employee);
      const mockResponse = {
        success: true,
        data: [testChangeRequest],
        pagination: {
          page: 1,
          limit: 10,
          total: 1,
          totalPages: 1,
        },
      };

      mockChangeRequestService.getChangeRequests.mockResolvedValue(mockResponse);

      const response = await request(app)
        .get('/api/change-requests')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toEqual([testChangeRequest]);
    });

    it('should support filtering by status and entity type', async () => {
      const token = generateTestToken(testUsers.manager);
      const queryParams = {
        status: 'pending',
        entity_type: 'vendor',
        operation_type: 'create',
      };

      const mockResponse = {
        success: true,
        data: [],
        pagination: {
          page: 1,
          limit: 10,
          total: 0,
          totalPages: 0,
        },
      };

      mockChangeRequestService.getChangeRequests.mockResolvedValue(mockResponse);

      const response = await request(app)
        .get('/api/change-requests')
        .query(queryParams)
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(mockChangeRequestService.getChangeRequests).toHaveBeenCalledWith(
        expect.objectContaining(queryParams),
        testUsers.manager.id,
        testUsers.manager.role
      );
    });
  });

  describe('Change Request Lifecycle', () => {
    it('should complete full approval workflow for vendor creation', async () => {
      const employeeToken = generateTestToken(testUsers.employee);
      const managerToken = generateTestToken(testUsers.manager);

      // Step 1: Employee creates change request
      const createData = {
        operation_type: 'create',
        entity_type: 'vendor',
        data: {
          name: 'Workflow Test Vendor',
          contact_person: 'Test Contact',
          phone: '+1234567890',
          email: 'workflow@test.com',
          address: '123 Workflow Street',
          status: 'active',
        },
      };

      mockChangeRequestService.createChangeRequest.mockResolvedValue({
        success: true,
        data: { ...testChangeRequest, ...createData, status: 'pending' },
      });

      const createResponse = await request(app)
        .post('/api/change-requests')
        .set('Authorization', `Bearer ${employeeToken}`)
        .send(createData)
        .expect(201);

      expect(createResponse.body.success).toBe(true);

      // Step 2: Manager approves
      mockChangeRequestService.processChangeRequest.mockResolvedValue({
        success: true,
        data: { ...testChangeRequest, status: 'approved' },
      });

      const approvalResponse = await request(app)
        .put(`/api/change-requests/${testChangeRequest.id}/process`)
        .set('Authorization', `Bearer ${managerToken}`)
        .send({ action: 'approve', reason: 'Vendor information is complete' })
        .expect(200);

      expect(approvalResponse.body.success).toBe(true);
    });

    it('should handle rejection workflow', async () => {
      const employeeToken = generateTestToken(testUsers.employee);
      const managerToken = generateTestToken(testUsers.manager);

      // Step 1: Employee creates change request
      const createData = {
        operation_type: 'create',
        entity_type: 'item',
        data: {
          name: 'Test Item',
          code: 'TEST-001',
          unit: 'pcs',
          status: 'active',
        },
      };

      mockChangeRequestService.createChangeRequest.mockResolvedValue({
        success: true,
        data: { ...testChangeRequest, ...createData, status: 'pending' },
      });

      const createResponse = await request(app)
        .post('/api/change-requests')
        .set('Authorization', `Bearer ${employeeToken}`)
        .send(createData)
        .expect(201);

      expect(createResponse.body.success).toBe(true);

      // Step 2: Manager rejects
      mockChangeRequestService.processChangeRequest.mockResolvedValue({
        success: true,
        data: { ...testChangeRequest, status: 'rejected' },
      });

      const rejectionResponse = await request(app)
        .put(`/api/change-requests/${testChangeRequest.id}/process`)
        .set('Authorization', `Bearer ${managerToken}`)
        .send({ 
          action: 'reject', 
          reason: 'Item description is insufficient. Please provide more details.' 
        })
        .expect(200);

      expect(rejectionResponse.body.success).toBe(true);
    });
  });
});