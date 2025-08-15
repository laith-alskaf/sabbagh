import jwt from 'jsonwebtoken';
import { env } from '../../src/config/env';

// Test user data
export const testUsers = {
  manager: {
    id: '123e4567-e89b-12d3-a456-426614174000',
    email: 'manager@sabbagh.com',
    name: 'Test Manager',
    role: 'manager' as const,
    password: 'hashedpassword123',
  },
  assistantManager: {
    id: '123e4567-e89b-12d3-a456-426614174001',
    email: 'assistant@sabbagh.com',
    name: 'Test Assistant Manager',
    role: 'assistant_manager' as const,
    password: 'hashedpassword123',
  },
  employee: {
    id: '123e4567-e89b-12d3-a456-426614174002',
    email: 'employee@sabbagh.com',
    name: 'Test Employee',
    role: 'employee' as const,
    password: 'hashedpassword123',
  },
};

// Generate JWT token for testing
export const generateTestToken = (user: typeof testUsers.manager) => {
  return jwt.sign(
    { 
      id: user.id, 
      email: user.email, 
      role: user.role 
    },
    env.jwt.secret,
    { expiresIn: '1h' }
  );
};

// Test vendor data
export const testVendor = {
  id: '123e4567-e89b-12d3-a456-426614174100',
  name: 'Test Vendor',
  contact_person: 'John Doe',
  phone: '+1234567890',
  email: 'vendor@test.com',
  address: '123 Test Street, Test City',
  status: 'active' as const,
  created_at: new Date(),
  updated_at: new Date(),
};

// Test item data
export const testItem = {
  id: '123e4567-e89b-12d3-a456-426614174200',
  name: 'Test Item',
  code: 'TEST-001',
  description: 'Test item description',
  unit: 'pcs',
  status: 'active' as const,
  created_at: new Date(),
  updated_at: new Date(),
};

// Test purchase order data
export const testPurchaseOrder = {
  id: '123e4567-e89b-12d3-a456-426614174300',
  department: 'IT',
  request_date: new Date(),
  delivery_date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days from now
  status: 'draft' as const,
  notes: 'Test purchase order',
  supplier_id: testVendor.id,
  user_id: testUsers.employee.id,
  requester_name: 'Test Requester',
  currency: 'USD',
  created_at: new Date(),
  updated_at: new Date(),
};

// Test change request data
export const testChangeRequest = {
  id: '123e4567-e89b-12d3-a456-426614174400',
  operation_type: 'create' as const,
  entity_type: 'vendor' as const,
  entity_id: null,
  data: {
    name: 'New Vendor',
    contact_person: 'Jane Doe',
    phone: '+9876543210',
    email: 'newvendor@test.com',
    address: '456 New Street, New City',
    status: 'active',
  },
  status: 'pending' as const,
  requested_by: testUsers.employee.id,
  approved_by: null,
  reason: null,
  created_at: new Date(),
  updated_at: new Date(),
};

// Mock request object
export const createMockRequest = (overrides: any = {}) => ({
  body: {},
  params: {},
  query: {},
  headers: {},
  user: null,
  requestId: 'test-request-id',
  language: 'en',
  ...overrides,
});

// Mock response object
export const createMockResponse = () => {
  const res: any = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  res.send = jest.fn().mockReturnValue(res);
  res.setHeader = jest.fn().mockReturnValue(res);
  return res;
};

// Mock next function
export const createMockNext = () => jest.fn();