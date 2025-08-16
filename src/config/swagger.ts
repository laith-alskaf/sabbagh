import swaggerJsdoc from 'swagger-jsdoc';
import { version } from '../../package.json';

const options: swaggerJsdoc.Options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Sabbagh Purchasing System API',
      version,
      description: `
# Sabbagh Purchasing System API

A comprehensive purchasing management system with role-based access control, workflow management, and internationalization support.

## Features
- **Authentication & Authorization**: JWT-based authentication with role-based permissions
- **Purchase Order Management**: Complete workflow from draft to completion
- **Vendor & Item Management**: CRUD operations with change request approval system
- **Dashboard & Reports**: Analytics and reporting capabilities
- **Internationalization**: Support for Arabic and English languages
- **Audit Trail**: Complete audit logging for all operations

## User Roles
- **Manager**: Full access to all operations and approvals
- **Assistant Manager**: Can approve/reject purchase orders and change requests
- **Employee**: Can create purchase orders and change requests
- **Guest**: Read-only access to basic information

## Workflow
1. **Purchase Orders**: Draft → Assistant Review → Manager Review → In Progress → Completed
2. **Change Requests**: Pending → Approved/Rejected by Manager

## Authentication
All protected endpoints require a Bearer token in the Authorization header:
\`Authorization: Bearer <your-jwt-token>\`

## Error Handling
All endpoints return consistent error responses with appropriate HTTP status codes and localized messages.
      `,
      license: {
        name: 'Private',
        url: 'https://sabbagh.com',
      },
      contact: {
        name: 'Sabbagh IT Team',
        url: 'https://sabbagh.com',
        email: 'it@sabbagh.com',
      },
    },
    servers: [
      {
        url: 'https://sabbagh.vercel.app/api',
        description: 'Development server',
      },
      {
        url: '/api',
        description: 'Current server',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
      schemas: {
        User: {
          type: 'object',
          required: ['email', 'name', 'role'],
          properties: {
            id: {
              type: 'string',
              format: 'uuid',
              description: 'User unique identifier',
              example: '123e4567-e89b-12d3-a456-426614174000',
            },
            email: {
              type: 'string',
              format: 'email',
              description: 'User email address',
              example: 'manager@sabbagh.com',
            },
            name: {
              type: 'string',
              description: 'User full name',
              example: 'Purchasing Manager',
              minLength: 2,
              maxLength: 100,
            },
            role: {
              type: 'string',
              enum: ['manager', 'assistant_manager', 'employee', 'guest'],
              description: 'User role in the system',
              example: 'manager',
            },
            active: {
              type: 'boolean',
              description: 'Whether the user account is active',
              example: true,
            },
            created_at: {
              type: 'string',
              format: 'date-time',
              description: 'Account creation timestamp',
              example: '2024-01-15T10:30:00Z',
            },
            updated_at: {
              type: 'string',
              format: 'date-time',
              description: 'Last account update timestamp',
              example: '2024-01-15T10:30:00Z',
            },
          },
        },
        LoginRequest: {
          type: 'object',
          required: ['email', 'password'],
          properties: {
            email: {
              type: 'string',
              format: 'email',
              description: 'User email address',
              example: 'manager@sabbagh.com',
            },
            password: {
              type: 'string',
              format: 'password',
              description: 'User password',
              example: 'Manager@123',
              minLength: 8,
            },
          },
        },
        LoginResponse: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: true,
            },
            token: {
              type: 'string',
              description: 'JWT authentication token',
              example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
            },
            user: {
              $ref: '#/components/schemas/User',
            },
          },
        },
        ChangePasswordRequest: {
          type: 'object',
          required: ['currentPassword', 'newPassword'],
          properties: {
            currentPassword: {
              type: 'string',
              format: 'password',
              description: 'Current password',
              example: 'OldPassword@123',
            },
            newPassword: {
              type: 'string',
              format: 'password',
              description: 'New password (min 8 chars, must include uppercase, lowercase, number, and special character)',
              example: 'NewPassword@123',
              minLength: 8,
            },
          },
        },
        Vendor: {
          type: 'object',
          required: ['name', 'contact_person', 'phone', 'address', 'status'],
          properties: {
            id: {
              type: 'string',
              format: 'uuid',
              description: 'Vendor unique identifier',
              example: '456e7890-e89b-12d3-a456-426614174001',
            },
            name: {
              type: 'string',
              description: 'Vendor company name',
              example: 'ABC Trading Company',
              minLength: 2,
              maxLength: 200,
            },
            contact_person: {
              type: 'string',
              description: 'Primary contact person name',
              example: 'Ahmed Al-Sabbagh',
              minLength: 2,
              maxLength: 100,
            },
            phone: {
              type: 'string',
              description: 'Primary phone number',
              example: '+963-11-1234567',
              pattern: '^[+]?[0-9\\s\\-()]+$',
            },
            email: {
              type: 'string',
              format: 'email',
              description: 'Contact email address (optional)',
              example: 'contact@abctrading.com',
            },
            address: {
              type: 'string',
              description: 'Physical business address',
              example: 'Damascus, Syria - Al-Mazzeh District, Building 123',
              minLength: 10,
              maxLength: 500,
            },
            notes: {
              type: 'string',
              description: 'Additional notes about the vendor',
              example: 'Reliable supplier for office supplies',
              maxLength: 1000,
            },
            rating: {
              type: 'number',
              format: 'float',
              description: 'Vendor rating (1-5 scale)',
              example: 4.5,
              minimum: 1,
              maximum: 5,
            },
            status: {
              type: 'string',
              enum: ['active', 'archived'],
              description: 'Vendor status',
              example: 'active',
            },
            created_at: {
              type: 'string',
              format: 'date-time',
              description: 'Vendor creation timestamp',
              example: '2024-01-15T10:30:00Z',
            },
            updated_at: {
              type: 'string',
              format: 'date-time',
              description: 'Last vendor update timestamp',
              example: '2024-01-15T10:30:00Z',
            },
          },
        },
        VendorCreateRequest: {
          type: 'object',
          required: ['name', 'contact_person', 'phone', 'address', 'status'],
          properties: {
            name: {
              type: 'string',
              description: 'Vendor company name',
              example: 'ABC Trading Company',
              minLength: 2,
              maxLength: 200,
            },
            contact_person: {
              type: 'string',
              description: 'Primary contact person name',
              example: 'Ahmed Al-Sabbagh',
              minLength: 2,
              maxLength: 100,
            },
            phone: {
              type: 'string',
              description: 'Primary phone number',
              example: '+963-11-1234567',
            },
            email: {
              type: 'string',
              format: 'email',
              description: 'Contact email address (optional)',
              example: 'contact@abctrading.com',
            },
            address: {
              type: 'string',
              description: 'Physical business address',
              example: 'Damascus, Syria - Al-Mazzeh District, Building 123',
              minLength: 10,
              maxLength: 500,
            },
            notes: {
              type: 'string',
              description: 'Additional notes about the vendor',
              example: 'Reliable supplier for office supplies',
              maxLength: 1000,
            },
            rating: {
              type: 'number',
              format: 'float',
              description: 'Vendor rating (1-5 scale)',
              example: 4.5,
              minimum: 1,
              maximum: 5,
            },
            status: {
              type: 'string',
              enum: ['active', 'archived'],
              description: 'Vendor status',
              example: 'active',
            },
          },
        },
        Item: {
          type: 'object',
          required: ['name', 'code', 'unit', 'status'],
          properties: {
            id: {
              type: 'string',
              format: 'uuid',
              description: 'Item unique identifier',
              example: '789e0123-e89b-12d3-a456-426614174002',
            },
            name: {
              type: 'string',
              description: 'Item name',
              example: 'Office Chair - Executive',
              minLength: 2,
              maxLength: 200,
            },
            code: {
              type: 'string',
              description: 'Unique item code',
              example: 'CHAIR-EXEC-001',
              minLength: 3,
              maxLength: 50,
              pattern: '^[A-Z0-9\\-_]+$',
            },
            description: {
              type: 'string',
              description: 'Detailed item description',
              example: 'High-quality executive office chair with leather upholstery and ergonomic design',
              maxLength: 1000,
            },
            unit: {
              type: 'string',
              description: 'Unit of measurement',
              example: 'piece',
              enum: ['piece', 'kg', 'liter', 'meter', 'box', 'pack', 'set'],
            },
            status: {
              type: 'string',
              enum: ['active', 'archived'],
              description: 'Item status',
              example: 'active',
            },
            created_at: {
              type: 'string',
              format: 'date-time',
              description: 'Item creation timestamp',
              example: '2024-01-15T10:30:00Z',
            },
            updated_at: {
              type: 'string',
              format: 'date-time',
              description: 'Last item update timestamp',
              example: '2024-01-15T10:30:00Z',
            },
          },
        },
        ItemCreateRequest: {
          type: 'object',
          required: ['name', 'code', 'unit', 'status'],
          properties: {
            name: {
              type: 'string',
              description: 'Item name',
              example: 'Office Chair - Executive',
              minLength: 2,
              maxLength: 200,
            },
            code: {
              type: 'string',
              description: 'Unique item code',
              example: 'CHAIR-EXEC-001',
              minLength: 3,
              maxLength: 50,
              pattern: '^[A-Z0-9\\-_]+$',
            },
            description: {
              type: 'string',
              description: 'Detailed item description',
              example: 'High-quality executive office chair with leather upholstery and ergonomic design',
              maxLength: 1000,
            },
            unit: {
              type: 'string',
              description: 'Unit of measurement',
              example: 'piece',
              enum: ['piece', 'kg', 'liter', 'meter', 'box', 'pack', 'set'],
            },
            status: {
              type: 'string',
              enum: ['active', 'archived'],
              description: 'Item status',
              example: 'active',
            },
          },
        },
        ChangeRequest: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              description: 'Change request ID',
            },
            operation_type: {
              type: 'string',
              enum: ['create', 'update', 'delete'],
              description: 'Operation type',
            },
            entity_type: {
              type: 'string',
              enum: ['vendor', 'item'],
              description: 'Entity type',
            },
            entity_id: {
              type: 'string',
              description: 'Entity ID (for update/delete operations)',
            },
            data: {
              type: 'object',
              description: 'Change request data',
            },
            status: {
              type: 'string',
              enum: ['pending', 'approved', 'rejected'],
              description: 'Change request status',
            },
            requested_by: {
              type: 'string',
              description: 'User ID who requested the change',
            },
            approved_by: {
              type: 'string',
              description: 'User ID who approved/rejected the change',
            },
            reason: {
              type: 'string',
              description: 'Reason for approval/rejection',
            },
            created_at: {
              type: 'string',
              format: 'date-time',
              description: 'Creation timestamp',
            },
            updated_at: {
              type: 'string',
              format: 'date-time',
              description: 'Last update timestamp',
            },
          },
        },
        PurchaseOrder: {
          type: 'object',
          required: ['number', 'department', 'request_date', 'request_type', 'requester_name', 'currency'],
          properties: {
            id: {
              type: 'string',
              format: 'uuid',
              description: 'Purchase order unique identifier',
              example: 'abc12345-e89b-12d3-a456-426614174003',
            },
            number: {
              type: 'string',
              description: 'Unique purchase order number',
              example: 'PO-2024-001',
            },
            department: {
              type: 'string',
              description: 'Requesting department name',
              example: 'IT Department',
              minLength: 2,
              maxLength: 100,
            },
            request_date: {
              type: 'string',
              format: 'date-time',
              description: 'Purchase request date',
              example: '2024-01-15T10:30:00Z',
            },
            request_type: {
              type: 'string',
              enum: ['purchase', 'maintenance'],
              description: 'Type of request',
              example: 'purchase',
            },
            requester_name: {
              type: 'string',
              description: 'Name of the person requesting the purchase',
              example: 'Ahmad Al-Sabbagh',
              minLength: 2,
              maxLength: 100,
            },
            execution_date: {
              type: 'string',
              format: 'date-time',
              description: 'Expected execution/delivery date',
              example: '2024-01-20T10:30:00Z',
            },
            status: {
              type: 'string',
              enum: [
                'draft',
                'under_assistant_review',
                'rejected_by_assistant',
                'under_manager_review',
                'rejected_by_manager',
                'in_progress',
                'completed',
              ],
              description: 'Current purchase order status',
              example: 'draft',
            },
            notes: {
              type: 'string',
              description: 'Additional notes or comments',
              example: 'Urgent requirement for new project',
              maxLength: 1000,
            },
            supplier_id: {
              type: 'string',
              format: 'uuid',
              description: 'Selected supplier/vendor ID',
              example: '456e7890-e89b-12d3-a456-426614174001',
            },
            attachment_url: {
              type: 'string',
              format: 'uri',
              description: 'URL to attached documents',
              example: 'https://storage.sabbagh.com/attachments/po-2024-001.pdf',
            },
            total_amount: {
              type: 'number',
              format: 'float',
              description: 'Total purchase order amount',
              example: 1500.50,
              minimum: 0,
            },
            currency: {
              type: 'string',
              enum: ['SYP', 'USD'],
              description: 'Currency code',
              example: 'USD',
            },
            created_by: {
              type: 'string',
              format: 'uuid',
              description: 'User ID who created the purchase order',
              example: '123e4567-e89b-12d3-a456-426614174000',
            },
            items: {
              type: 'array',
              description: 'List of items in the purchase order',
              items: {
                $ref: '#/components/schemas/PurchaseOrderItem',
              },
            },
            created_at: {
              type: 'string',
              format: 'date-time',
              description: 'Purchase order creation timestamp',
              example: '2024-01-15T10:30:00Z',
            },
            updated_at: {
              type: 'string',
              format: 'date-time',
              description: 'Last purchase order update timestamp',
              example: '2024-01-15T10:30:00Z',
            },
          },
        },
        PurchaseOrderItem: {
          type: 'object',
          required: ['quantity', 'unit', 'currency'],
          properties: {
            id: {
              type: 'string',
              format: 'uuid',
              description: 'Purchase order item unique identifier',
              example: 'def45678-e89b-12d3-a456-426614174004',
            },
            purchase_order_id: {
              type: 'string',
              format: 'uuid',
              description: 'Parent purchase order ID',
              example: 'abc12345-e89b-12d3-a456-426614174003',
            },
            item_id: {
              type: 'string',
              format: 'uuid',
              description: 'Reference to existing item (optional)',
              example: '789e0123-e89b-12d3-a456-426614174002',
            },
            item_code: {
              type: 'string',
              description: 'Item code (if not referencing existing item)',
              example: 'CHAIR-EXEC-001',
            },
            item_name: {
              type: 'string',
              description: 'Item name/description',
              example: 'Office Chair - Executive',
              minLength: 2,
              maxLength: 200,
            },
            quantity: {
              type: 'number',
              format: 'float',
              description: 'Requested quantity',
              example: 5,
              minimum: 0.01,
            },
            unit: {
              type: 'string',
              description: 'Unit of measurement',
              example: 'piece',
              enum: ['piece', 'kg', 'liter', 'meter', 'box', 'pack', 'set'],
            },
            received_quantity: {
              type: 'number',
              format: 'float',
              description: 'Actually received quantity',
              example: 5,
              minimum: 0,
            },
            price: {
              type: 'number',
              format: 'float',
              description: 'Unit price',
              example: 300.10,
              minimum: 0,
            },
            line_total: {
              type: 'number',
              format: 'float',
              description: 'Total line amount (quantity × price)',
              example: 1500.50,
              minimum: 0,
            },
            currency: {
              type: 'string',
              enum: ['SYP', 'USD'],
              description: 'Currency code',
              example: 'USD',
            },
          },
        },
        PurchaseOrderCreateRequest: {
          type: 'object',
          required: ['department', 'request_date', 'request_type', 'requester_name', 'currency', 'items'],
          properties: {
            department: {
              type: 'string',
              description: 'Requesting department name',
              example: 'IT Department',
              minLength: 2,
              maxLength: 100,
            },
            request_date: {
              type: 'string',
              format: 'date-time',
              description: 'Purchase request date',
              example: '2024-01-15T10:30:00Z',
            },
            request_type: {
              type: 'string',
              enum: ['purchase', 'maintenance'],
              description: 'Type of request',
              example: 'purchase',
            },
            requester_name: {
              type: 'string',
              description: 'Name of the person requesting the purchase',
              example: 'Ahmad Al-Sabbagh',
              minLength: 2,
              maxLength: 100,
            },
            execution_date: {
              type: 'string',
              format: 'date-time',
              description: 'Expected execution/delivery date',
              example: '2024-01-20T10:30:00Z',
            },
            notes: {
              type: 'string',
              description: 'Additional notes or comments',
              example: 'Urgent requirement for new project',
              maxLength: 1000,
            },
            supplier_id: {
              type: 'string',
              format: 'uuid',
              description: 'Selected supplier/vendor ID',
              example: '456e7890-e89b-12d3-a456-426614174001',
            },
            currency: {
              type: 'string',
              enum: ['SYP', 'USD'],
              description: 'Currency code',
              example: 'USD',
            },
            items: {
              type: 'array',
              description: 'List of items to purchase',
              minItems: 1,
              items: {
                type: 'object',
                required: ['quantity', 'unit', 'currency'],
                properties: {
                  item_id: {
                    type: 'string',
                    format: 'uuid',
                    description: 'Reference to existing item (optional)',
                    example: '789e0123-e89b-12d3-a456-426614174002',
                  },
                  item_code: {
                    type: 'string',
                    description: 'Item code (if not referencing existing item)',
                    example: 'CHAIR-EXEC-001',
                  },
                  item_name: {
                    type: 'string',
                    description: 'Item name/description',
                    example: 'Office Chair - Executive',
                    minLength: 2,
                    maxLength: 200,
                  },
                  quantity: {
                    type: 'number',
                    format: 'float',
                    description: 'Requested quantity',
                    example: 5,
                    minimum: 0.01,
                  },
                  unit: {
                    type: 'string',
                    description: 'Unit of measurement',
                    example: 'piece',
                  },
                  price: {
                    type: 'number',
                    format: 'float',
                    description: 'Unit price',
                    example: 300.10,
                    minimum: 0,
                  },
                  currency: {
                    type: 'string',
                    enum: ['SYP', 'USD'],
                    description: 'Currency code',
                    example: 'USD',
                  },
                },
              },
            },
          },
        },
        DashboardStats: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: true,
            },
            data: {
              type: 'object',
              properties: {
                totalPurchaseOrders: {
                  type: 'integer',
                  description: 'Total number of purchase orders',
                  example: 150,
                },
                pendingPurchaseOrders: {
                  type: 'integer',
                  description: 'Number of pending purchase orders',
                  example: 25,
                },
                completedPurchaseOrders: {
                  type: 'integer',
                  description: 'Number of completed purchase orders',
                  example: 100,
                },
                totalVendors: {
                  type: 'integer',
                  description: 'Total number of active vendors',
                  example: 45,
                },
                totalItems: {
                  type: 'integer',
                  description: 'Total number of active items',
                  example: 200,
                },
                pendingChangeRequests: {
                  type: 'integer',
                  description: 'Number of pending change requests',
                  example: 8,
                },
                monthlySpending: {
                  type: 'object',
                  properties: {
                    SYP: {
                      type: 'number',
                      format: 'float',
                      description: 'Monthly spending in Syrian Pounds',
                      example: 5000000,
                    },
                    USD: {
                      type: 'number',
                      format: 'float',
                      description: 'Monthly spending in US Dollars',
                      example: 15000,
                    },
                  },
                },
                recentActivity: {
                  type: 'array',
                  description: 'Recent system activities',
                  items: {
                    type: 'object',
                    properties: {
                      id: {
                        type: 'string',
                        example: 'activity-001',
                      },
                      type: {
                        type: 'string',
                        example: 'purchase_order_created',
                      },
                      description: {
                        type: 'string',
                        example: 'New purchase order PO-2024-001 created',
                      },
                      timestamp: {
                        type: 'string',
                        format: 'date-time',
                        example: '2024-01-15T10:30:00Z',
                      },
                    },
                  },
                },
              },
            },
          },
        },
        PaginatedResponse: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: true,
            },
            data: {
              type: 'array',
              description: 'Array of items',
            },
            pagination: {
              type: 'object',
              properties: {
                page: {
                  type: 'integer',
                  description: 'Current page number',
                  example: 1,
                },
                limit: {
                  type: 'integer',
                  description: 'Items per page',
                  example: 10,
                },
                total: {
                  type: 'integer',
                  description: 'Total number of items',
                  example: 100,
                },
                totalPages: {
                  type: 'integer',
                  description: 'Total number of pages',
                  example: 10,
                },
                hasNext: {
                  type: 'boolean',
                  description: 'Whether there is a next page',
                  example: true,
                },
                hasPrev: {
                  type: 'boolean',
                  description: 'Whether there is a previous page',
                  example: false,
                },
              },
            },
          },
        },
        SuccessResponse: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: true,
            },
            message: {
              type: 'string',
              example: 'Operation completed successfully',
            },
            data: {
              type: 'object',
              description: 'Response data (optional)',
            },
          },
        },
        Error: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: false,
            },
            message: {
              type: 'string',
              example: 'Error message',
            },
            code: {
              type: 'string',
              description: 'Error code for programmatic handling',
              example: 'VALIDATION_ERROR',
            },
          },
        },
        ValidationError: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: false,
            },
            message: {
              type: 'string',
              example: 'Validation error',
            },
            errors: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  field: {
                    type: 'string',
                    example: 'email',
                  },
                  message: {
                    type: 'string',
                    example: 'Invalid email format',
                  },
                },
              },
            },
          },
        },
        AuditLog: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              format: 'uuid',
              description: 'Audit log unique identifier',
              example: 'log12345-e89b-12d3-a456-426614174005',
            },
            actor_id: {
              type: 'string',
              format: 'uuid',
              description: 'ID of the user who performed the action',
              example: '123e4567-e89b-12d3-a456-426614174000',
            },
            actor_name: {
              type: 'string',
              description: 'Name of the user who performed the action',
              example: 'Ahmad Al-Sabbagh',
            },
            actor_email: {
              type: 'string',
              format: 'email',
              description: 'Email of the user who performed the action',
              example: 'ahmad@sabbagh.com',
            },
            action: {
              type: 'string',
              enum: ['create', 'update', 'delete', 'login', 'logout', 'approve', 'reject', 'submit'],
              description: 'Action performed',
              example: 'create',
            },
            entity_type: {
              type: 'string',
              enum: ['user', 'vendor', 'item', 'purchase_order', 'change_request'],
              description: 'Type of entity affected',
              example: 'vendor',
            },
            entity_id: {
              type: 'string',
              format: 'uuid',
              description: 'ID of the affected entity',
              example: '456e7890-e89b-12d3-a456-426614174001',
            },
            details: {
              type: 'object',
              description: 'Additional details about the action',
              additionalProperties: true,
              example: {
                before: { name: 'Old Name' },
                after: { name: 'New Name' }
              },
            },
            ip_address: {
              type: 'string',
              description: 'IP address of the user',
              example: '192.168.1.100',
            },
            user_agent: {
              type: 'string',
              description: 'User agent string',
              example: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
            created_at: {
              type: 'string',
              format: 'date-time',
              description: 'Audit log creation timestamp',
              example: '2024-01-15T10:30:00Z',
            },
          },
        },
        Pagination: {
          type: 'object',
          properties: {
            page: {
              type: 'integer',
              description: 'Current page number',
              example: 1,
              minimum: 1,
            },
            limit: {
              type: 'integer',
              description: 'Number of items per page',
              example: 10,
              minimum: 1,
            },
            total: {
              type: 'integer',
              description: 'Total number of items',
              example: 150,
              minimum: 0,
            },
            totalPages: {
              type: 'integer',
              description: 'Total number of pages',
              example: 15,
              minimum: 0,
            },
            hasNext: {
              type: 'boolean',
              description: 'Whether there is a next page',
              example: true,
            },
            hasPrev: {
              type: 'boolean',
              description: 'Whether there is a previous page',
              example: false,
            },
          },
        },
      },
      responses: {
        UnauthorizedError: {
          description: 'Access token is missing or invalid',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/Error',
              },
              example: {
                success: false,
                message: 'Unauthorized access',
              },
            },
          },
        },
        ForbiddenError: {
          description: 'User does not have permission to access this resource',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/Error',
              },
              example: {
                success: false,
                message: 'Permission denied',
              },
            },
          },
        },
        ValidationError: {
          description: 'Validation error',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/ValidationError',
              },
              example: {
                success: false,
                message: 'Validation error',
                errors: [
                  {
                    field: 'email',
                    message: 'Invalid email format',
                  },
                ],
              },
            },
          },
        },
        NotFoundError: {
          description: 'Resource not found',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/Error',
              },
              example: {
                success: false,
                message: 'Resource not found',
              },
            },
          },
        },
        ServerError: {
          description: 'Internal server error',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/Error',
              },
              example: {
                success: false,
                message: 'Internal server error',
              },
            },
          },
        },
      },
    },
    security: [
      {
        bearerAuth: [],
      },
    ],
  },
  apis: ['./src/routes/*.ts', './src/controllers/*.ts'],
};

export const specs = swaggerJsdoc(options);