import { Router } from 'express';
import * as dashboardController from '../controllers/dashboardController';
import { authenticateJWT, authorizeRoles } from '../middlewares/authMiddleware';
import { UserRole } from '../types/models';

const router = Router();

/**
 * @swagger
 * tags:
 *   name: Dashboard
 *   description: Dashboard analytics and statistics endpoints
 */

// Apply authentication middleware to all routes
router.use(authenticateJWT);

// Apply authorization middleware to all routes - only managers and assistant managers can access
router.use(authorizeRoles([UserRole.MANAGER, UserRole.ASSISTANT_MANAGER]));

/**
 * @swagger
 * /dashboard/orders-by-status:
 *   get:
 *     summary: Get purchase orders count by status
 *     tags: [Dashboard]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Purchase orders count by status
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: object
 *                   properties:
 *                     draft:
 *                       type: integer
 *                       example: 15
 *                     under_assistant_review:
 *                       type: integer
 *                       example: 8
 *                     under_manager_review:
 *                       type: integer
 *                       example: 5
 *                     in_progress:
 *                       type: integer
 *                       example: 12
 *                     completed:
 *                       type: integer
 *                       example: 45
 *                     rejected_by_assistant:
 *                       type: integer
 *                       example: 3
 *                     rejected_by_manager:
 *                       type: integer
 *                       example: 2
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/orders-by-status', dashboardController.getPurchaseOrdersByStatus);

/**
 * @swagger
 * /dashboard/monthly-expenses:
 *   get:
 *     summary: Get monthly expenses for the last 12 months
 *     tags: [Dashboard]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: currency
 *         schema:
 *           type: string
 *           enum: [SYP, USD, all]
 *           default: all
 *         description: Filter by currency
 *     responses:
 *       200:
 *         description: Monthly expenses data
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
 *                       month:
 *                         type: string
 *                         example: "2024-01"
 *                       SYP:
 *                         type: number
 *                         format: float
 *                         example: 5000000
 *                       USD:
 *                         type: number
 *                         format: float
 *                         example: 15000
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/monthly-expenses', dashboardController.getMonthlyExpenses);

/**
 * @swagger
 * /dashboard/top-suppliers:
 *   get:
 *     summary: Get top suppliers by order count or total value
 *     tags: [Dashboard]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: metric
 *         schema:
 *           type: string
 *           enum: [orders, value]
 *           default: orders
 *         description: Sort by order count or total value
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 20
 *           default: 10
 *         description: Number of top suppliers to return
 *     responses:
 *       200:
 *         description: Top suppliers data
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
 *                       supplier_id:
 *                         type: string
 *                         format: uuid
 *                         example: "456e7890-e89b-12d3-a456-426614174001"
 *                       supplier_name:
 *                         type: string
 *                         example: "ABC Trading Company"
 *                       order_count:
 *                         type: integer
 *                         example: 25
 *                       total_value_syp:
 *                         type: number
 *                         format: float
 *                         example: 2500000
 *                       total_value_usd:
 *                         type: number
 *                         format: float
 *                         example: 7500
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/top-suppliers', dashboardController.getTopSuppliers);

/**
 * @swagger
 * /dashboard/quick-stats:
 *   get:
 *     summary: Get quick statistics for the dashboard
 *     tags: [Dashboard]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Quick dashboard statistics
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/DashboardStats'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/quick-stats', dashboardController.getQuickStats);

/**
 * @swagger
 * /dashboard/recent-orders:
 *   get:
 *     summary: Get recent purchase orders
 *     tags: [Dashboard]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 50
 *           default: 10
 *         description: Number of recent orders to return
 *     responses:
 *       200:
 *         description: Recent purchase orders
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
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/recent-orders', dashboardController.getRecentOrders);

export default router;