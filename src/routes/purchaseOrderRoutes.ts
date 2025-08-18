import { Router } from 'express';
import * as purchaseOrderController from '../controllers/purchaseOrderController';
import { authenticateJWT, authorizeRoles } from '../middlewares/authMiddleware';
import { UserRole } from '../types/models';
import { validate, validateParams, validateQuery } from '../validators';
import { 
  createPurchaseOrderSchema, 
  updatePurchaseOrderSchema, 
  submitPurchaseOrderSchema,
  approvePurchaseOrderSchema,
  rejectPurchaseOrderSchema,
  completePurchaseOrderSchema,
  purchaseOrderIdSchema,
  purchaseOrderQuerySchema
} from '../validators/purchaseOrderValidators';

const router = Router();

/**
 * @swagger
 * tags:
 *   name: Purchase Orders
 *   description: Purchase order management endpoints
 */

// Apply authentication middleware to all routes
router.use(authenticateJWT);

/**
 * @swagger
 * /purchase-orders/{id}:
 *   get:
 *     summary: Get a purchase order by ID
 *     tags: [Purchase Orders]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Purchase order ID
 *     responses:
 *       200:
 *         description: Purchase order details
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/PurchaseOrder'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/:id', validateParams(purchaseOrderIdSchema), purchaseOrderController.getPurchaseOrderById);

/**
 * @swagger
 * /purchase-orders/my:
 *   get:
 *     summary: Get current user's purchase orders
 *     tags: [Purchase Orders]
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
 *           enum: [draft, under_assistant_review, rejected_by_assistant, under_manager_review, rejected_by_manager, in_progress, completed]
 *         description: Filter by status
 *     responses:
 *       200:
 *         description: User's purchase orders
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
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/my', purchaseOrderController.getMyPurchaseOrders);

/**
 * @swagger
 * /purchase-orders:
 *   post:
 *     summary: Create a new purchase order
 *     tags: [Purchase Orders]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - department
 *               - request_date
 *               - request_type
 *               - requester_name
 *               - currency
 *               - items
 *             properties:
 *               department:
 *                 type: string
 *                 minLength: 2
 *                 maxLength: 100
 *                 description: Requesting department
 *                 example: "IT Department"
 *               request_date:
 *                 type: string
 *                 format: date-time
 *                 description: Request date
 *                 example: "2024-01-15T10:30:00Z"
 *               request_type:
 *                 type: string
 *                 enum: [purchase, maintenance]
 *                 description: Type of request
 *                 example: "purchase"
 *               requester_name:
 *                 type: string
 *                 minLength: 2
 *                 maxLength: 100
 *                 description: Name of the person making the request
 *                 example: "Ahmad Al-Sabbagh"
 *               execution_date:
 *                 type: string
 *                 format: date-time
 *                 description: Expected execution date (optional)
 *                 example: "2024-01-22T10:30:00Z"
 *               notes:
 *                 type: string
 *                 maxLength: 1000
 *                 description: Additional notes (optional)
 *                 example: "Urgent request for new office equipment"
 *               currency:
 *                 type: string
 *                 enum: [SYP, USD]
 *                 description: Currency for the order
 *                 example: "USD"
 *               items:
 *                 type: array
 *                 minItems: 1
 *                 items:
 *                   type: object
 *                   required:
 *                     - item_name
 *                     - quantity
 *                     - unit
 *                     - price
 *                     - currency
 *                   properties:
 *                     item_id:
 *                       type: string
 *                       format: uuid
 *                       description: Item ID from catalog (optional)
 *                     item_name:
 *                       type: string
 *                       minLength: 2
 *                       maxLength: 100
 *                       description: Item name
 *                       example: "Office Chair Executive"
 *                     quantity:
 *                       type: number
 *                       minimum: 0.01
 *                       description: Quantity requested
 *                       example: 5
 *                     unit:
 *                       type: string
 *                       minLength: 1
 *                       maxLength: 20
 *                       description: Unit of measurement
 *                       example: "piece"
 *                     price:
 *                       type: number
 *                       minimum: 0
 *                       description: Unit price
 *                       example: 300.50
 *                     currency:
 *                       type: string
 *                       enum: [SYP, USD]
 *                       description: Currency for this item
 *                       example: "USD"
 *     responses:
 *       201:
 *         description: Purchase order created successfully
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
 *                   example: "Purchase order created successfully"
 *                 data:
 *                   $ref: '#/components/schemas/PurchaseOrder'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.post('/', validate(createPurchaseOrderSchema), purchaseOrderController.createPurchaseOrder);

/**
 * @swagger
 * /purchase-orders/{id}:
 *   put:
 *     summary: Update a purchase order (only in draft or In Progress status)
 *     tags: [Purchase Orders]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Purchase order ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               department:
 *                 type: string
 *                 minLength: 2
 *                 maxLength: 100
 *                 description: Requesting department
 *               request_date:
 *                 type: string
 *                 format: date-time
 *                 description: Request date
 *               request_type:
 *                 type: string
 *                 enum: [purchase, maintenance]
 *                 description: Type of request
 *               requester_name:
 *                 type: string
 *                 minLength: 2
 *                 maxLength: 100
 *                 description: Name of the person making the request
 *               execution_date:
 *                 type: string
 *                 format: date-time
 *                 description: Expected execution date
 *               notes:
 *                 type: string
 *                 maxLength: 1000
 *                 description: Additional notes
 *               supplier_id:
 *                 type: string
 *                 format: uuid
 *                 description: Supplier ID
 *               currency:
 *                 type: string
 *                 enum: [SYP, USD]
 *                 description: Currency for the order
 *               items:
 *                 type: array
 *                 minItems: 1
 *                 items:
 *                   type: object
 *                   required:
 *                     - item_name
 *                     - quantity
 *                     - unit
 *                     - price
 *                     - currency
 *                   properties:
 *                     item_id:
 *                       type: string
 *                       format: uuid
 *                       description: Item ID from catalog
 *                     item_name:
 *                       type: string
 *                       description: Item name
 *                     quantity:
 *                       type: number
 *                       minimum: 0.01
 *                       description: Quantity requested
 *                     unit:
 *                       type: string
 *                       description: Unit of measurement
 *                     price:
 *                       type: number
 *                       minimum: 0
 *                       description: Unit price
 *                     currency:
 *                       type: string
 *                       enum: [SYP, USD]
 *                       description: Currency for this item
 *     responses:
 *       200:
 *         description: Purchase order updated successfully
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
 *                   example: "Purchase order updated successfully"
 *                 data:
 *                   $ref: '#/components/schemas/PurchaseOrder'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         description: Cannot update purchase order (not in draft or In Progress status or not owner)
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
 *                   example: "Cannot update purchase order that is not in draft or In Progress status"
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.put('/:id', validateParams(purchaseOrderIdSchema), validate(updatePurchaseOrderSchema), purchaseOrderController.updatePurchaseOrder);

/**
 * @swagger
 * /purchase-orders/{id}/submit:
 *   patch:
 *     summary: Submit purchase order for review
 *     tags: [Purchase Orders]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Purchase order ID
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
 *                 description: Additional notes for submission
 *                 example: "Please review urgently"
 *     responses:
 *       200:
 *         description: Purchase order submitted successfully
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
 *                   example: "Purchase order submitted for review"
 *                 data:
 *                   $ref: '#/components/schemas/PurchaseOrder'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         description: Cannot submit purchase order (not in draft status or not owner)
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
 *                   example: "Cannot submit purchase order that is not in draft status"
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.patch('/:id/submit', validateParams(purchaseOrderIdSchema), validate(submitPurchaseOrderSchema), purchaseOrderController.submitPurchaseOrder);

/**
 * @swagger
 * /purchase-orders:
 *   get:
 *     summary: Get all purchase orders (Assistant Managers and Managers only)
 *     tags: [Purchase Orders]
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
 *           enum: [draft, under_assistant_review, rejected_by_assistant, under_manager_review, rejected_by_manager, in_progress, completed]
 *         description: Filter by status
 *       - in: query
 *         name: department
 *         schema:
 *           type: string
 *         description: Filter by department
 *       - in: query
 *         name: requester_name
 *         schema:
 *           type: string
 *         description: Filter by requester name
 *       - in: query
 *         name: start_date
 *         schema:
 *           type: string
 *           format: date
 *         description: Filter by start date (YYYY-MM-DD)
 *       - in: query
 *         name: end_date
 *         schema:
 *           type: string
 *           format: date
 *         description: Filter by end date (YYYY-MM-DD)
 *       - in: query
 *         name: sort
 *         schema:
 *           type: string
 *           enum: [created_at, updated_at, request_date, total_amount]
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
 *         description: List of purchase orders
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
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get(
  '/',
  authorizeRoles([UserRole.ASSISTANT_MANAGER, UserRole.MANAGER]),
  validateQuery(purchaseOrderQuerySchema),
  purchaseOrderController.getPurchaseOrders
);

/**
 * @swagger
 * /purchase-orders/pending/assistant:
 *   get:
 *     summary: Get purchase orders pending assistant review
 *     tags: [Purchase Orders]
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
 *     responses:
 *       200:
 *         description: Purchase orders pending assistant review
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
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get(
  '/pending/assistant',
  authorizeRoles([UserRole.ASSISTANT_MANAGER, UserRole.MANAGER]),
  purchaseOrderController.getPurchaseOrdersPendingAssistantReview
);

/**
 * @swagger
 * /purchase-orders/pending/manager:
 *   get:
 *     summary: Get purchase orders pending manager review
 *     tags: [Purchase Orders]
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
 *     responses:
 *       200:
 *         description: Purchase orders pending manager review
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
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get(
  '/pending/manager',
  authorizeRoles([UserRole.MANAGER]),
  purchaseOrderController.getPurchaseOrdersPendingManagerReview
);

/**
 * @swagger
 * /purchase-orders/{id}/assistant-approve:
 *   patch:
 *     summary: Assistant approve purchase order
 *     tags: [Purchase Orders]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Purchase order ID
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
 *                 example: "Approved for manager review"
 *     responses:
 *       200:
 *         description: Purchase order approved by assistant
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
 *                   example: "Purchase order approved by assistant manager"
 *                 data:
 *                   $ref: '#/components/schemas/PurchaseOrder'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.patch(
  '/:id/assistant-approve',
  authorizeRoles([UserRole.ASSISTANT_MANAGER, UserRole.MANAGER]),
  validateParams(purchaseOrderIdSchema),
  validate(approvePurchaseOrderSchema),
  purchaseOrderController.assistantApprove
);

/**
 * @swagger
 * /purchase-orders/{id}/assistant-reject:
 *   patch:
 *     summary: Assistant reject purchase order
 *     tags: [Purchase Orders]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Purchase order ID
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
 *                 example: "Budget not approved for this department"
 *               notes:
 *                 type: string
 *                 maxLength: 1000
 *                 description: Additional notes
 *                 example: "Please resubmit with proper budget approval"
 *     responses:
 *       200:
 *         description: Purchase order rejected by assistant
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
 *                   example: "Purchase order rejected by assistant manager"
 *                 data:
 *                   $ref: '#/components/schemas/PurchaseOrder'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.patch(
  '/:id/assistant-reject',
  authorizeRoles([UserRole.ASSISTANT_MANAGER, UserRole.MANAGER]),
  validateParams(purchaseOrderIdSchema),
  validate(rejectPurchaseOrderSchema),
  purchaseOrderController.assistantReject
);

/**
 * @swagger
 * /purchase-orders/{id}/manager-approve:
 *   patch:
 *     summary: Manager approve purchase order
 *     tags: [Purchase Orders]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Purchase order ID
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
 *                 example: "Approved for execution"
 *     responses:
 *       200:
 *         description: Purchase order approved by manager
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
 *                   example: "Purchase order approved by manager"
 *                 data:
 *                   $ref: '#/components/schemas/PurchaseOrder'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.patch(
  '/:id/manager-approve',
  authorizeRoles([UserRole.MANAGER]),
  validateParams(purchaseOrderIdSchema),
  validate(approvePurchaseOrderSchema),
  purchaseOrderController.managerApprove
);

/**
 * @swagger
 * /purchase-orders/{id}/manager-reject:
 *   patch:
 *     summary: Manager reject purchase order
 *     tags: [Purchase Orders]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Purchase order ID
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
 *                 example: "Does not align with company strategy"
 *               notes:
 *                 type: string
 *                 maxLength: 1000
 *                 description: Additional notes
 *                 example: "Please discuss with department head before resubmitting"
 *     responses:
 *       200:
 *         description: Purchase order rejected by manager
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
 *                   example: "Purchase order rejected by manager"
 *                 data:
 *                   $ref: '#/components/schemas/PurchaseOrder'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.patch(
  '/:id/manager-reject',
  authorizeRoles([UserRole.MANAGER]),
  validateParams(purchaseOrderIdSchema),
  validate(rejectPurchaseOrderSchema),
  purchaseOrderController.managerReject
);

/**
 * @swagger
 * /purchase-orders/{id}/complete:
 *   patch:
 *     summary: Mark purchase order as completed
 *     tags: [Purchase Orders]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Purchase order ID
 *     requestBody:
 *       required: false
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               completion_notes:
 *                 type: string
 *                 maxLength: 1000
 *                 description: Completion notes
 *                 example: "All items received and verified"
 *               actual_completion_date:
 *                 type: string
 *                 format: date-time
 *                 description: Actual completion date (defaults to current time)
 *                 example: "2024-01-25T14:30:00Z"
 *     responses:
 *       200:
 *         description: Purchase order marked as completed
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
 *                   example: "Purchase order completed successfully"
 *                 data:
 *                   $ref: '#/components/schemas/PurchaseOrder'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.patch(
  '/:id/complete',
  authorizeRoles([UserRole.MANAGER,UserRole.ASSISTANT_MANAGER]),
  validateParams(purchaseOrderIdSchema),
  validate(completePurchaseOrderSchema),
  purchaseOrderController.completePurchaseOrder
);

export default router;