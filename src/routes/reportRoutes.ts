import { Router } from 'express';
import * as reportController from '../controllers/reportController';
import { authenticateJWT, authorizeRoles } from '../middlewares/authMiddleware';
import { validateQuery } from '../validators';
import { reportQuerySchema } from '../validators/reportValidators';
import { UserRole } from '../types/models';

const router = Router();

/**
 * @swagger
 * tags:
 *   name: Reports
 *   description: Reporting and analytics endpoints
 */

// Apply authentication middleware to all routes
router.use(authenticateJWT);

// Apply authorization middleware to all routes - only managers and assistant managers can access
router.use(authorizeRoles([UserRole.MANAGER, UserRole.ASSISTANT_MANAGER]));

/**
 * @swagger
 * /reports/purchase-orders:
 *   get:
 *     summary: Get purchase orders report
 *     tags: [Reports]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: format
 *         schema:
 *           type: string
 *           enum: [json, csv, excel]
 *           default: json
 *         description: Report format
 *       - in: query
 *         name: start_date
 *         schema:
 *           type: string
 *           format: date
 *         description: Start date filter (YYYY-MM-DD)
 *         example: "2024-01-01"
 *       - in: query
 *         name: end_date
 *         schema:
 *           type: string
 *           format: date
 *         description: End date filter (YYYY-MM-DD)
 *         example: "2024-12-31"
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [draft, under_assistant_review, rejected_by_assistant, under_manager_review, rejected_by_manager, in_progress, completed]
 *         description: Filter by status
 *       - in: query
 *         name: department
 *         schema:
 *           type: string
 *         description: Filter by department
 *       - in: query
 *         name: supplier_id
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Filter by supplier
 *       - in: query
 *         name: currency
 *         schema:
 *           type: string
 *           enum: [SYP, USD, all]
 *           default: all
 *         description: Filter by currency
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           minimum: 1
 *           default: 1
 *         description: Page number (for JSON format)
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 1000
 *           default: 100
 *         description: Number of items per page (for JSON format)
 *     responses:
 *       200:
 *         description: Purchase orders report
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/PurchaseOrder'
 *                 pagination:
 *                   $ref: '#/components/schemas/Pagination'
 *                 summary:
 *                   type: object
 *                   properties:
 *                     total_orders:
 *                       type: integer
 *                       example: 150
 *                     total_amount_syp:
 *                       type: number
 *                       format: float
 *                       example: 25000000
 *                     total_amount_usd:
 *                       type: number
 *                       format: float
 *                       example: 75000
 *                     by_status:
 *                       type: object
 *                       additionalProperties:
 *                         type: integer
 *                       example:
 *                         completed: 100
 *                         in_progress: 30
 *                         under_manager_review: 20
 *           text/csv:
 *             schema:
 *               type: string
 *               example: "Order Number,Department,Requester,Status,Total Amount,Currency,Created Date\nPO-2024-001,IT Department,Ahmad Al-Sabbagh,completed,1500.00,USD,2024-01-15"
 *           application/vnd.openxmlformats-officedocument.spreadsheetml.sheet:
 *             schema:
 *               type: string
 *               format: binary
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/purchase-orders', validateQuery(reportQuerySchema), reportController.getPurchaseOrderList);

/**
 * @swagger
 * /reports/expenses:
 *   get:
 *     summary: Get expenses report
 *     tags: [Reports]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: format
 *         schema:
 *           type: string
 *           enum: [json, csv, excel]
 *           default: json
 *         description: Report format
 *       - in: query
 *         name: start_date
 *         schema:
 *           type: string
 *           format: date
 *         description: Start date filter (YYYY-MM-DD)
 *         example: "2024-01-01"
 *       - in: query
 *         name: end_date
 *         schema:
 *           type: string
 *           format: date
 *         description: End date filter (YYYY-MM-DD)
 *         example: "2024-12-31"
 *       - in: query
 *         name: department
 *         schema:
 *           type: string
 *         description: Filter by department
 *       - in: query
 *         name: currency
 *         schema:
 *           type: string
 *           enum: [SYP, USD, all]
 *           default: all
 *         description: Filter by currency
 *       - in: query
 *         name: group_by
 *         schema:
 *           type: string
 *           enum: [month, department, supplier, category]
 *           default: month
 *         description: Group expenses by
 *     responses:
 *       200:
 *         description: Expenses report
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       period:
 *                         type: string
 *                         example: "2024-01"
 *                       department:
 *                         type: string
 *                         example: "IT Department"
 *                       supplier_name:
 *                         type: string
 *                         example: "ABC Trading Company"
 *                       total_amount_syp:
 *                         type: number
 *                         format: float
 *                         example: 2500000
 *                       total_amount_usd:
 *                         type: number
 *                         format: float
 *                         example: 7500
 *                       order_count:
 *                         type: integer
 *                         example: 15
 *                 summary:
 *                   type: object
 *                   properties:
 *                     total_amount_syp:
 *                       type: number
 *                       format: float
 *                       example: 50000000
 *                     total_amount_usd:
 *                       type: number
 *                       format: float
 *                       example: 150000
 *                     total_orders:
 *                       type: integer
 *                       example: 300
 *           text/csv:
 *             schema:
 *               type: string
 *           application/vnd.openxmlformats-officedocument.spreadsheetml.sheet:
 *             schema:
 *               type: string
 *               format: binary
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/expenses', validateQuery(reportQuerySchema), reportController.getExpenseReport);

/**
 * @swagger
 * /reports/quantities:
 *   get:
 *     summary: Get quantities report
 *     tags: [Reports]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: format
 *         schema:
 *           type: string
 *           enum: [json, csv, excel]
 *           default: json
 *         description: Report format
 *       - in: query
 *         name: start_date
 *         schema:
 *           type: string
 *           format: date
 *         description: Start date filter (YYYY-MM-DD)
 *         example: "2024-01-01"
 *       - in: query
 *         name: end_date
 *         schema:
 *           type: string
 *           format: date
 *         description: End date filter (YYYY-MM-DD)
 *         example: "2024-12-31"
 *       - in: query
 *         name: item_id
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Filter by specific item
 *       - in: query
 *         name: department
 *         schema:
 *           type: string
 *         description: Filter by department
 *       - in: query
 *         name: group_by
 *         schema:
 *           type: string
 *           enum: [item, department, month, supplier]
 *           default: item
 *         description: Group quantities by
 *     responses:
 *       200:
 *         description: Quantities report
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       item_name:
 *                         type: string
 *                         example: "Office Chair Executive"
 *                       item_code:
 *                         type: string
 *                         example: "CHAIR-EXEC-001"
 *                       unit:
 *                         type: string
 *                         example: "piece"
 *                       total_quantity:
 *                         type: number
 *                         format: float
 *                         example: 150
 *                       total_value_syp:
 *                         type: number
 *                         format: float
 *                         example: 15000000
 *                       total_value_usd:
 *                         type: number
 *                         format: float
 *                         example: 45000
 *                       order_count:
 *                         type: integer
 *                         example: 25
 *                       department:
 *                         type: string
 *                         example: "IT Department"
 *                 summary:
 *                   type: object
 *                   properties:
 *                     total_items:
 *                       type: integer
 *                       example: 50
 *                     total_quantity:
 *                       type: number
 *                       format: float
 *                       example: 5000
 *                     total_value_syp:
 *                       type: number
 *                       format: float
 *                       example: 100000000
 *                     total_value_usd:
 *                       type: number
 *                       format: float
 *                       example: 300000
 *           text/csv:
 *             schema:
 *               type: string
 *           application/vnd.openxmlformats-officedocument.spreadsheetml.sheet:
 *             schema:
 *               type: string
 *               format: binary
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/quantities', validateQuery(reportQuerySchema), reportController.getQuantityReport);

/**
 * @swagger
 * /reports/vendors:
 *   get:
 *     summary: Get vendors report
 *     tags: [Reports]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: format
 *         schema:
 *           type: string
 *           enum: [json, csv, excel]
 *           default: json
 *         description: Report format
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [active, archived, all]
 *           default: all
 *         description: Filter by vendor status
 *       - in: query
 *         name: include_performance
 *         schema:
 *           type: boolean
 *           default: true
 *         description: Include performance metrics
 *     responses:
 *       200:
 *         description: Vendors report
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: string
 *                         format: uuid
 *                       name:
 *                         type: string
 *                         example: "ABC Trading Company"
 *                       contact_person:
 *                         type: string
 *                         example: "Ahmad Al-Sabbagh"
 *                       phone:
 *                         type: string
 *                         example: "+963-11-1234567"
 *                       email:
 *                         type: string
 *                         example: "contact@abctrading.com"
 *                       status:
 *                         type: string
 *                         example: "active"
 *                       total_orders:
 *                         type: integer
 *                         example: 25
 *                       total_value_syp:
 *                         type: number
 *                         format: float
 *                         example: 10000000
 *                       total_value_usd:
 *                         type: number
 *                         format: float
 *                         example: 30000
 *                       average_order_value:
 *                         type: number
 *                         format: float
 *                         example: 1200
 *                       rating:
 *                         type: number
 *                         format: float
 *                         example: 4.5
 *                       created_at:
 *                         type: string
 *                         format: date-time
 *           text/csv:
 *             schema:
 *               type: string
 *           application/vnd.openxmlformats-officedocument.spreadsheetml.sheet:
 *             schema:
 *               type: string
 *               format: binary
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/vendors', validateQuery(reportQuerySchema), reportController.getVendorReport);

/**
 * @swagger
 * /reports/items:
 *   get:
 *     summary: Get items report
 *     tags: [Reports]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: format
 *         schema:
 *           type: string
 *           enum: [json, csv, excel]
 *           default: json
 *         description: Report format
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [active, archived, all]
 *           default: all
 *         description: Filter by item status
 *       - in: query
 *         name: include_usage
 *         schema:
 *           type: boolean
 *           default: true
 *         description: Include usage statistics
 *     responses:
 *       200:
 *         description: Items report
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: string
 *                         format: uuid
 *                       name:
 *                         type: string
 *                         example: "Office Chair Executive"
 *                       code:
 *                         type: string
 *                         example: "CHAIR-EXEC-001"
 *                       description:
 *                         type: string
 *                         example: "High-quality executive office chair"
 *                       unit:
 *                         type: string
 *                         example: "piece"
 *                       status:
 *                         type: string
 *                         example: "active"
 *                       total_ordered:
 *                         type: number
 *                         format: float
 *                         example: 150
 *                       total_value_syp:
 *                         type: number
 *                         format: float
 *                         example: 5000000
 *                       total_value_usd:
 *                         type: number
 *                         format: float
 *                         example: 15000
 *                       order_frequency:
 *                         type: integer
 *                         example: 12
 *                       average_price:
 *                         type: number
 *                         format: float
 *                         example: 300.50
 *                       created_at:
 *                         type: string
 *                         format: date-time
 *           text/csv:
 *             schema:
 *               type: string
 *           application/vnd.openxmlformats-officedocument.spreadsheetml.sheet:
 *             schema:
 *               type: string
 *               format: binary
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/items', validateQuery(reportQuerySchema), reportController.getItemReport);

export default router;