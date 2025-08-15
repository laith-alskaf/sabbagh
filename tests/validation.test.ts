import { validate, validateQuery, validateParams } from '../src/validators';
import { createVendorSchema, vendorQuerySchema, vendorIdSchema } from '../src/validators/vendorValidators';
import { createItemSchema } from '../src/validators/itemValidators';
import { loginSchema } from '../src/validators/authValidators';
import { createMockRequest, createMockResponse, createMockNext } from './helpers/testHelpers';

describe('Validation Middleware', () => {
  describe('Body Validation', () => {
    it('should pass valid vendor data', () => {
      const req = createMockRequest({
        body: {
          name: 'Test Vendor',
          contact_person: 'John Doe',
          phone: '+1234567890',
          email: 'vendor@test.com',
          address: '123 Test Street, Test City',
          status: 'active',
        },
      });
      const res = createMockResponse();
      const next = createMockNext();

      const middleware = validate(createVendorSchema);
      middleware(req, res, next);

      expect(next).toHaveBeenCalledWith();
      expect(next).not.toHaveBeenCalledWith(expect.any(Error));
    });

    it('should reject invalid vendor data', () => {
      const req = createMockRequest({
        body: {
          name: 'A', // Too short
          contact_person: '', // Empty
          phone: '123', // Too short
          email: 'invalid-email', // Invalid format
          address: 'Too short', // Too short
        },
      });
      const res = createMockResponse();
      const next = createMockNext();

      const middleware = validate(createVendorSchema);
      
      expect(() => middleware(req, res, next)).toThrow();
    });

    it('should pass valid item data', () => {
      const req = createMockRequest({
        body: {
          name: 'Test Item',
          code: 'TEST-001',
          description: 'Test item description',
          unit: 'pcs',
          status: 'active',
        },
      });
      const res = createMockResponse();
      const next = createMockNext();

      const middleware = validate(createItemSchema);
      middleware(req, res, next);

      expect(next).toHaveBeenCalledWith();
    });

    it('should reject invalid item code format', () => {
      const req = createMockRequest({
        body: {
          name: 'Test Item',
          code: 'test-001', // Should be uppercase
          unit: 'pcs',
          status: 'active',
        },
      });
      const res = createMockResponse();
      const next = createMockNext();

      const middleware = validate(createItemSchema);
      
      expect(() => middleware(req, res, next)).toThrow();
    });

    it('should pass valid login data', () => {
      const req = createMockRequest({
        body: {
          email: 'user@sabbagh.com',
          password: 'password123',
        },
      });
      const res = createMockResponse();
      const next = createMockNext();

      const middleware = validate(loginSchema);
      middleware(req, res, next);

      expect(next).toHaveBeenCalledWith();
    });

    it('should reject invalid email format in login', () => {
      const req = createMockRequest({
        body: {
          email: 'invalid-email',
          password: 'password123',
        },
      });
      const res = createMockResponse();
      const next = createMockNext();

      const middleware = validate(loginSchema);
      
      expect(() => middleware(req, res, next)).toThrow();
    });
  });

  describe('Query Validation', () => {
    it('should pass valid query parameters', () => {
      const req = createMockRequest({
        query: {
          page: '1',
          limit: '10',
          search: 'test',
          status: 'active',
          sort: 'name',
          order: 'asc',
        },
      });
      const res = createMockResponse();
      const next = createMockNext();

      const middleware = validateQuery(vendorQuerySchema);
      middleware(req, res, next);

      expect(next).toHaveBeenCalledWith();
      expect(req.query.page).toBe(1); // Should be converted to number
      expect(req.query.limit).toBe(10); // Should be converted to number
    });

    it('should reject invalid page number', () => {
      const req = createMockRequest({
        query: {
          page: 'invalid',
          limit: '10',
        },
      });
      const res = createMockResponse();
      const next = createMockNext();

      const middleware = validateQuery(vendorQuerySchema);
      
      expect(() => middleware(req, res, next)).toThrow();
    });

    it('should reject invalid status value', () => {
      const req = createMockRequest({
        query: {
          status: 'invalid_status',
        },
      });
      const res = createMockResponse();
      const next = createMockNext();

      const middleware = validateQuery(vendorQuerySchema);
      
      expect(() => middleware(req, res, next)).toThrow();
    });
  });

  describe('Parameter Validation', () => {
    it('should pass valid UUID parameter', () => {
      const req = createMockRequest({
        params: {
          id: '123e4567-e89b-12d3-a456-426614174000',
        },
      });
      const res = createMockResponse();
      const next = createMockNext();

      const middleware = validateParams(vendorIdSchema);
      middleware(req, res, next);

      expect(next).toHaveBeenCalledWith();
    });

    it('should reject invalid UUID format', () => {
      const req = createMockRequest({
        params: {
          id: 'invalid-uuid',
        },
      });
      const res = createMockResponse();
      const next = createMockNext();

      const middleware = validateParams(vendorIdSchema);
      
      expect(() => middleware(req, res, next)).toThrow();
    });
  });

  describe('Data Transformation', () => {
    it('should transform and sanitize data', () => {
      const req = createMockRequest({
        body: {
          name: '  Test Vendor  ', // Should be trimmed
          contact_person: '  John Doe  ', // Should be trimmed
          phone: '+1234567890',
          email: '  vendor@test.com  ', // Should be trimmed
          address: '  123 Test Street  ', // Should be trimmed
          status: 'active',
        },
      });
      const res = createMockResponse();
      const next = createMockNext();

      const middleware = validate(createVendorSchema);
      middleware(req, res, next);

      expect(req.body.name).toBe('Test Vendor');
      expect(req.body.contact_person).toBe('John Doe');
      expect(req.body.email).toBe('vendor@test.com');
      expect(req.body.address).toBe('123 Test Street');
    });

    it('should set default values', () => {
      const req = createMockRequest({
        body: {
          name: 'Test Vendor',
          contact_person: 'John Doe',
          phone: '+1234567890',
          address: '123 Test Street',
          // status not provided, should default to 'active'
        },
      });
      const res = createMockResponse();
      const next = createMockNext();

      const middleware = validate(createVendorSchema);
      middleware(req, res, next);

      expect(req.body.status).toBe('active');
    });
  });

  describe('Error Messages', () => {
    it('should provide detailed error messages', () => {
      const req = createMockRequest({
        body: {
          name: '', // Empty name
          contact_person: 'A', // Too short
          phone: '123', // Too short
          email: 'invalid', // Invalid format
          address: 'Too', // Too short
        },
      });
      const res = createMockResponse();
      const next = createMockNext();

      const middleware = validate(createVendorSchema);
      
      try {
        middleware(req, res, next);
      } catch (error: any) {
        expect(error.errors).toEqual(
          expect.arrayContaining([
            expect.objectContaining({
              field: 'name',
              message: expect.stringContaining('at least'),
            }),
            expect.objectContaining({
              field: 'contact_person',
              message: expect.stringContaining('at least'),
            }),
            expect.objectContaining({
              field: 'phone',
              message: expect.stringContaining('at least'),
            }),
            expect.objectContaining({
              field: 'email',
              message: expect.stringContaining('Invalid email'),
            }),
            expect.objectContaining({
              field: 'address',
              message: expect.stringContaining('at least'),
            }),
          ])
        );
      }
    });
  });
});