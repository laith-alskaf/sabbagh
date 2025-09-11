import { Router } from 'express';
import * as changeRequestController from '../controllers/changeRequestController';
import { authenticateJWT, authorizeRoles } from '../middlewares/authMiddleware';
import { validate, validateQuery, validateParams } from '../validators';
import { createChangeRequestSchema, approveChangeRequestSchema, rejectChangeRequestSchema, changeRequestIdSchema, changeRequestQuerySchema } from '../validators/changeRequestValidators';
import { UserRole } from '../types/models';

const router = Router();

/**
 * @swagger
 * tags:
 *   name: Change Requests
 *   description: Change request management endpoints
 */

// Apply authentication middleware to all routes
router.use(authenticateJWT);

/**
 * @swagger
 * /change-requests:
 *   get:
 *     summary: Get all change requests
 *     tags: [Change Requests]
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
 *           default: 10
 *         description: Number of items per page
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, approved, rejected]
 *         description: Filter by status
 *       - in: query
 *         name: entity_type
 *         schema:
 *           type: string
 *           enum: [vendor, item, purchase_order]
 *         description: Filter by entity type
 *       - in: query
 *         name: operation
 *         schema:
 *           type: string
 *           enum: [create, update, delete]
 *         description: Filter by operation type
 *       - in: query
 *         name: sort
 *         schema:
 *           type: string
 *           enum: [created_at, updated_at, status]
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
 *         description: List of change requests
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
 *                     $ref: '#/components/schemas/ChangeRequest'
 *                 pagination:
 *                   $ref: '#/components/schemas/Pagination'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/', validateQuery(changeRequestQuerySchema), changeRequestController.getChangeRequests);

/**
 * @swagger
 * /change-requests:
 *   post:
 *     summary: Create a new change request
 *     tags: [Change Requests]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - entity_type
 *               - operation
 *               - payload
 *             properties:
 *               entity_type:
 *                 type: string
 *                 enum: [vendor, item, purchase_order]
 *                 description: Type of entity to change
 *                 example: "vendor"
 *               operation:
 *                 type: string
 *                 enum: [create, update, delete]
 *                 description: Type of operation
 *                 example: "update"
 *               target_id:
 *                 type: string
 *                 format: uuid
 *                 description: ID of the target entity (required for update/delete operations)
 *                 example: "456e7890-e89b-12d3-a456-426614174001"
 *               payload:
 *                 type: object
 *                 description: Data for the change (new data for create/update, empty for delete)
 *                 example:
 *                   name: "Updated Vendor Name"
 *                   rating: 4.8
 *               reason:
 *                 type: string
 *                 minLength: 5
 *                 maxLength: 1000
 *                 description: Reason for the change request
 *                 example: "Vendor has improved service quality and deserves higher rating"
 *     responses:
 *       201:
 *         description: Change request created successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: "Change request created successfully"
 *                 data:
 *                   $ref: '#/components/schemas/ChangeRequest'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         description: Target entity not found (for update/delete operations)
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
 *                   example: "Target entity not found"
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.post('/', validate(createChangeRequestSchema), changeRequestController.createChangeRequest);

/**
 * @swagger
 * /change-requests/{id}:
 *   get:
 *     summary: Get a change request by ID
 *     tags: [Change Requests]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Change request ID
 *     responses:
 *       200:
 *         description: Change request details
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/ChangeRequest'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/:id', validateParams(changeRequestIdSchema), changeRequestController.getChangeRequestById);

/**
 * @swagger
 * /change-requests/{id}/approve:
 *   post:
 *     summary: Approve a change request (Assistant Managers and Managers only)
 *     tags: [Change Requests]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Change request ID
 *     requestBody:
 *       required: false
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               notes:
 *                 type: string
 *                 maxLength: 1000
 *                 description: Approval notes
 *                 example: "Change approved and applied successfully"
 *     responses:
 *       200:
 *         description: Change request approved and applied
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: "Change request approved and applied successfully"
 *                 data:
 *                   $ref: '#/components/schemas/ChangeRequest'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 *       409:
 *         description: Change request already processed
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
 *                   example: "Change request has already been processed"
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.post('/:id/approve', 
  authorizeRoles([UserRole.ASSISTANT_MANAGER, UserRole.MANAGER]),
  validateParams(changeRequestIdSchema), 
  validate(approveChangeRequestSchema), 
  changeRequestController.approveChangeRequest
);

/**
 * @swagger
 * /change-requests/{id}/reject:
 *   post:
 *     summary: Reject a change request (Assistant Managers and Managers only)
 *     tags: [Change Requests]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Change request ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - reason
 *             properties:
 *               reason:
 *                 type: string
 *                 minLength: 5
 *                 maxLength: 1000
 *                 description: Rejection reason
 *                 example: "Change does not align with current business requirements"
 *               notes:
 *                 type: string
 *                 maxLength: 1000
 *                 description: Additional notes
 *                 example: "Please discuss with department head before resubmitting"
 *     responses:
 *       200:
 *         description: Change request rejected
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: "Change request rejected"
 *                 data:
 *                   $ref: '#/components/schemas/ChangeRequest'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 *       409:
 *         description: Change request already processed
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
 *                   example: "Change request has already been processed"
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.post('/:id/reject', 
  authorizeRoles([UserRole.ASSISTANT_MANAGER, UserRole.MANAGER]),
  validateParams(changeRequestIdSchema), 
  validate(rejectChangeRequestSchema), 
  changeRequestController.rejectChangeRequest
);

export default router;