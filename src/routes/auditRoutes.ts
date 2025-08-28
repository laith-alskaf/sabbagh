import { Router } from 'express';
import * as auditController from '../controllers/auditController';
import { authenticateJWT, authorizeRoles } from '../middlewares/authMiddleware';
import { validateQuery } from '../validators';
import { auditQuerySchema } from '../validators/auditValidators';
import { UserRole } from '../types/models';

const router = Router();

/**
 * @swagger
 * tags:
 *   name: Audit Logs
 *   description: System audit trail and activity logging endpoints
 */

// Apply authentication middleware to all routes
router.use(authenticateJWT);

/**
 * @swagger
 * /audit-logs:
 *   get:
 *     summary: Get system audit logs
 *     tags: [Audit Logs]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           minimum: 1
 *           default: 1
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *           default: 20
 *         description: Number of items per page
 *       - in: query
 *         name: action
 *         schema:
 *           type: string
 *           enum: [create, update, delete, login, logout, approve, reject, submit]
 *         description: Filter by action type
 *       - in: query
 *         name: entity_type
 *         schema:
 *           type: string
 *           enum: [user, vendor, item, purchase_order, change_request]
 *         description: Filter by entity type
 *       - in: query
 *         name: entity_id
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Filter by specific entity ID
 *       - in: query
 *         name: actor_id
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Filter by user who performed the action
 *       - in: query
 *         name: start_date
 *         schema:
 *           type: string
 *           format: date-time
 *         description: Filter by start date (ISO 8601 format)
 *         example: "2024-01-01T00:00:00Z"
 *       - in: query
 *         name: end_date
 *         schema:
 *           type: string
 *           format: date-time
 *         description: Filter by end date (ISO 8601 format)
 *         example: "2024-12-31T23:59:59Z"
 *       - in: query
 *         name: sort
 *         schema:
 *           type: string
 *           enum: [created_at, action, entity_type]
 *           default: created_at
 *         description: Sort field
 *       - in: query
 *         name: order
 *         schema:
 *           type: string
 *           enum: [asc, desc]
 *           default: desc
 *         description: Sort order
 *     responses:
 *       200:
 *         description: List of audit logs
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
 *                     $ref: '#/components/schemas/AuditLog'
 *                 pagination:
 *                   $ref: '#/components/schemas/Pagination'
 *                 summary:
 *                   type: object
 *                   properties:
 *                     total_actions:
 *                       type: integer
 *                       example: 1250
 *                     by_action:
 *                       type: object
 *                       additionalProperties:
 *                         type: integer
 *                       example:
 *                         create: 300
 *                         update: 450
 *                         delete: 50
 *                         login: 400
 *                         approve: 50
 *                     by_entity_type:
 *                       type: object
 *                       additionalProperties:
 *                         type: integer
 *                       example:
 *                         vendor: 200
 *                         item: 150
 *                         purchase_order: 500
 *                         user: 400
 *                     date_range:
 *                       type: object
 *                       properties:
 *                         start:
 *                           type: string
 *                           format: date-time
 *                           example: "2024-01-01T00:00:00Z"
 *                         end:
 *                           type: string
 *                           format: date-time
 *                           example: "2024-12-31T23:59:59Z"
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         description: Insufficient permissions (some audit logs may be restricted)
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: "Access to detailed audit logs requires manager privileges"
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/', authorizeRoles([UserRole.GENERAL_MANAGER, UserRole.MANAGER, UserRole.ASSISTANT_MANAGER]), validateQuery(auditQuerySchema), auditController.getAuditLogs);

export default router;