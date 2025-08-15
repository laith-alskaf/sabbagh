// import express from 'express';
// import cors from 'cors';
// import helmet from 'helmet';
// import morgan from 'morgan';
// import swaggerJsdoc from 'swagger-jsdoc';
// import swaggerUi from 'swagger-ui-express';
// import { validate } from './src/validators';
// import { createVendorSchema, vendorQuerySchema } from './src/validators/vendorValidators';
// import { createItemSchema } from './src/validators/itemValidators';
// import { loginSchema } from './src/validators/authValidators';
// import { errorHandler, notFoundHandler } from './src/middlewares/errorMiddleware';
// import { loggingMiddleware } from './src/middlewares/loggingMiddleware';

// const app = express();
// const PORT = process.env.PORT || 3000;

// // Middleware
// app.use(helmet());
// app.use(cors());
// app.use(morgan('combined'));
// app.use(express.json());
// app.use(express.urlencoded({ extended: true }));
// app.use(loggingMiddleware);

// // Swagger configuration
// const swaggerOptions = {
//   definition: {
//     openapi: '3.0.0',
//     info: {
//       title: 'Sabbagh Backend API - Demo',
//       version: '1.0.0',
//       description: 'Purchase Order Management System API with Validation Demo',
//     },
//     servers: [
//       {
//         url: `http://localhost:${PORT}`,
//         description: 'Development server',
//       },
//     ],
//     components: {
//       securitySchemes: {
//         bearerAuth: {
//           type: 'http',
//           scheme: 'bearer',
//           bearerFormat: 'JWT',
//         },
//       },
//       schemas: {
//         Vendor: {
//           type: 'object',
//           required: ['name', 'contact_person', 'phone', 'address'],
//           properties: {
//             name: {
//               type: 'string',
//               minLength: 2,
//               maxLength: 100,
//               description: 'Vendor name',
//             },
//             contact_person: {
//               type: 'string',
//               minLength: 2,
//               maxLength: 100,
//               description: 'Contact person name',
//             },
//             phone: {
//               type: 'string',
//               minLength: 8,
//               maxLength: 20,
//               pattern: '^[\\d\\s\\-\\+\\(\\)]+$',
//               description: 'Phone number',
//             },
//             email: {
//               type: 'string',
//               format: 'email',
//               maxLength: 100,
//               description: 'Email address (optional)',
//             },
//             address: {
//               type: 'string',
//               minLength: 5,
//               maxLength: 500,
//               description: 'Address',
//             },
//             status: {
//               type: 'string',
//               enum: ['active', 'inactive'],
//               default: 'active',
//               description: 'Vendor status',
//             },
//           },
//         },
//         Item: {
//           type: 'object',
//           required: ['code', 'name', 'unit'],
//           properties: {
//             code: {
//               type: 'string',
//               pattern: '^[A-Z0-9\\-_]+$',
//               description: 'Item code (uppercase letters, numbers, hyphens, underscores)',
//             },
//             name: {
//               type: 'string',
//               minLength: 2,
//               maxLength: 200,
//               description: 'Item name',
//             },
//             description: {
//               type: 'string',
//               maxLength: 1000,
//               description: 'Item description (optional)',
//             },
//             unit: {
//               type: 'string',
//               minLength: 1,
//               maxLength: 20,
//               description: 'Unit of measurement',
//             },
//             status: {
//               type: 'string',
//               enum: ['active', 'inactive'],
//               default: 'active',
//               description: 'Item status',
//             },
//           },
//         },
//         LoginRequest: {
//           type: 'object',
//           required: ['email', 'password'],
//           properties: {
//             email: {
//               type: 'string',
//               format: 'email',
//               description: 'User email',
//             },
//             password: {
//               type: 'string',
//               minLength: 6,
//               description: 'User password',
//             },
//           },
//         },
//         ValidationError: {
//           type: 'object',
//           properties: {
//             success: {
//               type: 'boolean',
//               example: false,
//             },
//             message: {
//               type: 'string',
//               example: 'Validation error',
//             },
//             errors: {
//               type: 'array',
//               items: {
//                 type: 'object',
//                 properties: {
//                   field: {
//                     type: 'string',
//                     example: 'name',
//                   },
//                   message: {
//                     type: 'string',
//                     example: 'Name must be at least 2 characters',
//                   },
//                 },
//               },
//             },
//           },
//         },
//       },
//     },
//   },
//   apis: ['./demo-server.ts'],
// };

// const specs = swaggerJsdoc(swaggerOptions);
// app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));

// /**
//  * @swagger
//  * /api/health:
//  *   get:
//  *     summary: Health check endpoint
//  *     tags: [Health]
//  *     responses:
//  *       200:
//  *         description: Server is healthy
//  *         content:
//  *           application/json:
//  *             schema:
//  *               type: object
//  *               properties:
//  *                 status:
//  *                   type: string
//  *                   example: ok
//  *                 timestamp:
//  *                   type: string
//  *                   format: date-time
//  */
// app.get('/api/health', (req, res) => {
//   res.json({
//     status: 'ok',
//     timestamp: new Date().toISOString(),
//     message: 'Sabbagh Backend API is running with validation and documentation!',
//   });
// });

// /**
//  * @swagger
//  * /api/demo/vendors:
//  *   post:
//  *     summary: Create a new vendor (Demo with validation)
//  *     tags: [Demo - Vendors]
//  *     requestBody:
//  *       required: true
//  *       content:
//  *         application/json:
//  *           schema:
//  *             $ref: '#/components/schemas/Vendor'
//  *           examples:
//  *             valid:
//  *               summary: Valid vendor data
//  *               value:
//  *                 name: "ABC Supplies"
//  *                 contact_person: "John Doe"
//  *                 phone: "+1234567890"
//  *                 email: "john@abcsupplies.com"
//  *                 address: "123 Business Street, City"
//  *                 status: "active"
//  *             invalid:
//  *               summary: Invalid vendor data (for testing validation)
//  *               value:
//  *                 name: "A"
//  *                 contact_person: ""
//  *                 phone: "123"
//  *                 email: "invalid-email"
//  *                 address: "123"
//  *     responses:
//  *       201:
//  *         description: Vendor created successfully (demo response)
//  *         content:
//  *           application/json:
//  *             schema:
//  *               type: object
//  *               properties:
//  *                 success:
//  *                   type: boolean
//  *                   example: true
//  *                 message:
//  *                   type: string
//  *                   example: "Validation passed! Vendor would be created in real implementation."
//  *                 data:
//  *                   $ref: '#/components/schemas/Vendor'
//  *       400:
//  *         description: Validation error
//  *         content:
//  *           application/json:
//  *             schema:
//  *               $ref: '#/components/schemas/ValidationError'
//  */
// app.post('/api/demo/vendors', validate(createVendorSchema), (req, res) => {
//   res.status(201).json({
//     success: true,
//     message: 'Validation passed! Vendor would be created in real implementation.',
//     data: req.body,
//   });
// });

// /**
//  * @swagger
//  * /api/demo/vendors:
//  *   get:
//  *     summary: Get vendors with query validation (Demo)
//  *     tags: [Demo - Vendors]
//  *     parameters:
//  *       - in: query
//  *         name: page
//  *         schema:
//  *           type: string
//  *           pattern: '^\\d+$'
//  *         description: Page number
//  *         example: "1"
//  *       - in: query
//  *         name: limit
//  *         schema:
//  *           type: string
//  *           pattern: '^\\d+$'
//  *         description: Items per page
//  *         example: "10"
//  *       - in: query
//  *         name: search
//  *         schema:
//  *           type: string
//  *           maxLength: 100
//  *         description: Search term
//  *         example: "ABC"
//  *       - in: query
//  *         name: status
//  *         schema:
//  *           type: string
//  *           enum: [active, inactive]
//  *         description: Filter by status
//  *         example: "active"
//  *     responses:
//  *       200:
//  *         description: Vendors retrieved successfully (demo response)
//  *         content:
//  *           application/json:
//  *             schema:
//  *               type: object
//  *               properties:
//  *                 success:
//  *                   type: boolean
//  *                   example: true
//  *                 message:
//  *                   type: string
//  *                   example: "Query validation passed! Vendors would be retrieved in real implementation."
//  *                 query:
//  *                   type: object
//  *       400:
//  *         description: Query validation error
//  *         content:
//  *           application/json:
//  *             schema:
//  *               $ref: '#/components/schemas/ValidationError'
//  */
// app.get('/api/demo/vendors', validate(vendorQuerySchema, 'query'), (req, res) => {
//   res.json({
//     success: true,
//     message: 'Query validation passed! Vendors would be retrieved in real implementation.',
//     query: req.query,
//   });
// });

// /**
//  * @swagger
//  * /api/demo/items:
//  *   post:
//  *     summary: Create a new item (Demo with validation)
//  *     tags: [Demo - Items]
//  *     requestBody:
//  *       required: true
//  *       content:
//  *         application/json:
//  *           schema:
//  *             $ref: '#/components/schemas/Item'
//  *           examples:
//  *             valid:
//  *               summary: Valid item data
//  *               value:
//  *                 code: "ITEM-001"
//  *                 name: "Office Chair"
//  *                 description: "Ergonomic office chair with lumbar support"
//  *                 unit: "piece"
//  *                 status: "active"
//  *             invalid:
//  *               summary: Invalid item data (for testing validation)
//  *               value:
//  *                 code: "invalid-code"
//  *                 name: "A"
//  *                 unit: ""
//  *     responses:
//  *       201:
//  *         description: Item created successfully (demo response)
//  *         content:
//  *           application/json:
//  *             schema:
//  *               type: object
//  *               properties:
//  *                 success:
//  *                   type: boolean
//  *                   example: true
//  *                 message:
//  *                   type: string
//  *                   example: "Validation passed! Item would be created in real implementation."
//  *                 data:
//  *                   $ref: '#/components/schemas/Item'
//  *       400:
//  *         description: Validation error
//  *         content:
//  *           application/json:
//  *             schema:
//  *               $ref: '#/components/schemas/ValidationError'
//  */
// app.post('/api/demo/items', validate(createItemSchema), (req, res) => {
//   res.status(201).json({
//     success: true,
//     message: 'Validation passed! Item would be created in real implementation.',
//     data: req.body,
//   });
// });

// /**
//  * @swagger
//  * /api/demo/auth/login:
//  *   post:
//  *     summary: User login (Demo with validation)
//  *     tags: [Demo - Authentication]
//  *     requestBody:
//  *       required: true
//  *       content:
//  *         application/json:
//  *           schema:
//  *             $ref: '#/components/schemas/LoginRequest'
//  *           examples:
//  *             valid:
//  *               summary: Valid login data
//  *               value:
//  *                 email: "manager@sabbagh.com"
//  *                 password: "Manager@123"
//  *             invalid:
//  *               summary: Invalid login data (for testing validation)
//  *               value:
//  *                 email: "invalid-email"
//  *                 password: "123"
//  *     responses:
//  *       200:
//  *         description: Login validation passed (demo response)
//  *         content:
//  *           application/json:
//  *             schema:
//  *               type: object
//  *               properties:
//  *                 success:
//  *                   type: boolean
//  *                   example: true
//  *                 message:
//  *                   type: string
//  *                   example: "Login validation passed! Authentication would be performed in real implementation."
//  *                 data:
//  *                   type: object
//  *                   properties:
//  *                     email:
//  *                       type: string
//  *                       example: "manager@sabbagh.com"
//  *       400:
//  *         description: Validation error
//  *         content:
//  *           application/json:
//  *             schema:
//  *               $ref: '#/components/schemas/ValidationError'
//  */
// app.post('/api/demo/auth/login', validate(loginSchema), (req, res) => {
//   res.json({
//     success: true,
//     message: 'Login validation passed! Authentication would be performed in real implementation.',
//     data: {
//       email: req.body.email,
//     },
//   });
// });

// // Error handling
// app.use(notFoundHandler);
// app.use(errorHandler);

// // Start server
// app.listen(PORT, () => {
//   console.log(`🚀 Sabbagh Backend Demo Server is running on port ${PORT}`);
//   console.log(`📚 API Documentation: http://localhost:${PORT}/api-docs`);
//   console.log(`❤️  Health Check: http://localhost:${PORT}/api/health`);
//   console.log(`✅ Validation & Logging: Fully functional`);
//   console.log(`🎯 Ready for testing!`);
// });

// export default app;