# 🏢 Sabbagh Purchasing System API Documentation

## 📋 Table of Contents
- [Overview](#overview)
- [Getting Started](#getting-started)
- [Authentication](#authentication)
- [API Endpoints](#api-endpoints)
- [Data Models](#data-models)
- [Error Handling](#error-handling)
- [Testing](#testing)
- [Internationalization](#internationalization)

## 🎯 Overview

The Sabbagh Purchasing System API is a comprehensive RESTful API for managing purchasing operations, vendor relationships, and procurement workflows. Built with Node.js, TypeScript, and PostgreSQL, it provides a robust foundation for enterprise purchasing management.

### Key Features
- 🔐 **JWT Authentication** with role-based access control
- 🏢 **Vendor Management** with comprehensive CRUD operations
- 📦 **Item Catalog** management with unique codes and descriptions
- 🛒 **Purchase Order Workflow** with multi-level approval process
- 📊 **Dashboard Analytics** with real-time statistics
- 📈 **Reporting System** with export capabilities
- 🔄 **Change Request System** for controlled modifications
- 🌍 **Internationalization** support (Arabic/English)
- 📝 **Audit Trail** for all operations
- ⚡ **Real-time Notifications** and activity tracking

## 🚀 Getting Started

### Prerequisites
- Node.js 18+ 
- PostgreSQL 12+
- npm or yarn

### Installation
```bash
# Clone the repository
git clone <repository-url>
cd sabbagh

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env
# Edit .env with your database credentials

# Run database migrations
node run-migration.js

# Start the development server
npm run dev
```

### Base URL
```
Development: http://localhost:3000/api
Production: https://your-domain.com/api
```

### Interactive Documentation
Visit `http://localhost:3000/api-docs` for interactive Swagger documentation.

## 🔐 Authentication

The API uses JWT (JSON Web Tokens) for authentication. Most endpoints require authentication.

### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "manager@sabbagh.com",
  "password": "Manager@123"
}
```

**Response:**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid",
    "name": "Purchasing Manager",
    "email": "manager@sabbagh.com",
    "role": "manager"
  }
}
```

### Using the Token
Include the token in the Authorization header for all protected endpoints:
```http
Authorization: Bearer <your-jwt-token>
```

### User Roles
- **Manager**: Full access to all operations and approvals
- **Assistant Manager**: Can approve/reject purchase orders and change requests
- **Employee**: Can create purchase orders and change requests
- **Guest**: Read-only access to basic information

## 📚 API Endpoints

### 🏥 Health Check
```http
GET /api/health
```
Check if the API is running.

### 🔐 Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/login` | User login |
| GET | `/auth/me` | Get current user info |
| POST | `/auth/change-password` | Change password |

### 📊 Dashboard
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/dashboard/quick-stats` | Get dashboard statistics |
| GET | `/dashboard/orders-by-status` | Get orders count by status |
| GET | `/dashboard/monthly-expenses` | Get monthly expenses |
| GET | `/dashboard/top-suppliers` | Get top suppliers |
| GET | `/dashboard/recent-orders` | Get recent orders |

### 🏢 Vendors
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/vendors` | List all vendors |
| GET | `/vendors/{id}` | Get vendor by ID |
| POST | `/vendors` | Create new vendor |
| PUT | `/vendors/{id}` | Update vendor |
| DELETE | `/vendors/{id}` | Delete vendor |

### 📦 Items
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/items` | List all items |
| GET | `/items/{id}` | Get item by ID |
| POST | `/items` | Create new item |
| PUT | `/items/{id}` | Update item |
| DELETE | `/items/{id}` | Delete item |

### 🛒 Purchase Orders
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/purchase-orders` | List all purchase orders |
| GET | `/purchase-orders/{id}` | Get purchase order by ID |
| POST | `/purchase-orders` | Create new purchase order |
| PUT | `/purchase-orders/{id}` | Update purchase order |
| POST | `/purchase-orders/{id}/submit` | Submit for review |
| POST | `/purchase-orders/{id}/approve` | Approve purchase order |
| POST | `/purchase-orders/{id}/reject` | Reject purchase order |
| POST | `/purchase-orders/{id}/complete` | Mark as completed |

### 🔄 Change Requests
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/change-requests` | List all change requests |
| GET | `/change-requests/{id}` | Get change request by ID |
| POST | `/change-requests` | Create new change request |
| POST | `/change-requests/{id}/approve` | Approve change request |
| POST | `/change-requests/{id}/reject` | Reject change request |

### 📈 Reports
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/reports/purchase-orders` | Purchase orders report |
| GET | `/reports/vendors` | Vendors report |
| GET | `/reports/items` | Items report |
| GET | `/reports/expenses` | Expenses report |

### 📝 Audit Logs
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/audit-logs` | List audit logs |

### 🌍 Internationalization
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/i18n/languages` | Get supported languages |
| GET | `/i18n/translations/{lang}` | Get translations for language |

## 📊 Data Models

### User
```json
{
  "id": "uuid",
  "name": "string",
  "email": "string",
  "role": "manager|assistant_manager|employee|guest",
  "active": "boolean",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### Vendor
```json
{
  "id": "uuid",
  "name": "string",
  "contact_person": "string",
  "phone": "string",
  "email": "string",
  "address": "string",
  "notes": "string",
  "rating": "number",
  "status": "active|archived",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### Item
```json
{
  "id": "uuid",
  "name": "string",
  "code": "string",
  "description": "string",
  "unit": "string",
  "status": "active|archived",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### Purchase Order
```json
{
  "id": "uuid",
  "number": "string",
  "department": "string",
  "request_date": "datetime",
  "request_type": "purchase|maintenance",
  "requester_name": "string",
  "status": "draft|under_assistant_review|rejected_by_assistant|under_manager_review|rejected_by_manager|in_progress|completed",
  "notes": "string",
  "supplier_id": "uuid",
  "execution_date": "datetime",
  "attachment_url": "string",
  "total_amount": "number",
  "currency": "SYP|USD",
  "created_by": "uuid",
  "items": [
    {
      "id": "uuid",
      "item_id": "uuid",
      "item_name": "string",
      "quantity": "number",
      "unit": "string",
      "price": "number",
      "line_total": "number",
      "currency": "SYP|USD"
    }
  ],
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

## ⚠️ Error Handling

The API uses consistent error response format:

```json
{
  "success": false,
  "message": "Error description",
  "code": "ERROR_CODE",
  "errors": [
    {
      "field": "field_name",
      "message": "Field-specific error message"
    }
  ]
}
```

### HTTP Status Codes
- `200` - Success
- `201` - Created
- `400` - Bad Request (validation errors)
- `401` - Unauthorized (authentication required)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `409` - Conflict (duplicate data)
- `500` - Internal Server Error

## 🧪 Testing

### Automated Testing
```bash
# Run comprehensive API tests
node test-api-comprehensive.js

# Run unit tests
npm test

# Run tests with coverage
npm run test:coverage
```

### Manual Testing Examples

#### 1. Login and Get Token
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "manager@sabbagh.com",
    "password": "Manager@123"
  }'
```

#### 2. Create a Vendor
```bash
curl -X POST http://localhost:3000/api/vendors \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "name": "ABC Trading Company",
    "contact_person": "Ahmad Al-Sabbagh",
    "phone": "+963-11-1234567",
    "email": "contact@abctrading.com",
    "address": "Damascus, Syria",
    "status": "active"
  }'
```

#### 3. Create a Purchase Order
```bash
curl -X POST http://localhost:3000/api/purchase-orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "department": "IT Department",
    "request_date": "2024-01-15T10:30:00Z",
    "request_type": "purchase",
    "requester_name": "Ahmad Al-Sabbagh",
    "currency": "USD",
    "items": [
      {
        "item_name": "Office Chair",
        "quantity": 5,
        "unit": "piece",
        "price": 300.50,
        "currency": "USD"
      }
    ]
  }'
```

## 🌍 Internationalization

The API supports Arabic and English languages.

### Setting Language
Include the `Accept-Language` header in your requests:
```http
Accept-Language: ar
Accept-Language: en
```

### Supported Languages
- `en` - English (default)
- `ar` - Arabic

### Response Messages
All error messages and success messages are localized based on the requested language.

## 📝 Best Practices

### 1. Authentication
- Always include the Authorization header for protected endpoints
- Handle token expiration gracefully
- Store tokens securely (not in localStorage for web apps)

### 2. Error Handling
- Check the `success` field in responses
- Handle different HTTP status codes appropriately
- Display user-friendly error messages

### 3. Pagination
- Use `page` and `limit` parameters for list endpoints
- Check `pagination` object in responses for navigation info

### 4. Data Validation
- Validate data on the client side before sending requests
- Handle validation errors from the API gracefully

### 5. Performance
- Use appropriate page sizes for list endpoints
- Cache static data like vendor and item lists when appropriate
- Use query parameters to filter large datasets

## 🔧 Development

### Environment Variables
```env
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://user:password@localhost:5432/sabbagh_db
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRES_IN=1d
DEFAULT_MANAGER_NAME=Purchasing Manager
DEFAULT_MANAGER_EMAIL=manager@sabbagh.com
DEFAULT_MANAGER_PASSWORD=Manager@123
```

### Database Schema
The database schema is managed through SQL migrations in the `db/migrations/` directory.

### Logging
All API operations are logged with structured logging. Logs are stored in the `logs/` directory.

## 📞 Support

For technical support or questions about the API:
- Email: it@sabbagh.com
- Documentation: http://localhost:3000/api-docs
- Repository: [GitHub Repository URL]

## 📄 License

This API is proprietary software owned by Sabbagh Company. All rights reserved.

---

**Last Updated:** August 2024  
**API Version:** 1.0.0