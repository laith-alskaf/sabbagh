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

// Routes accessible to all authenticated users
router.get('/:id', validateParams(purchaseOrderIdSchema), purchaseOrderController.getPurchaseOrderById);

// Routes for employees to view their own purchase orders
router.get('/my', purchaseOrderController.getMyPurchaseOrders);

// Routes for creating and submitting purchase orders (all roles)
router.post('/', validate(createPurchaseOrderSchema), purchaseOrderController.createPurchaseOrder);
router.put('/:id', validateParams(purchaseOrderIdSchema), validate(updatePurchaseOrderSchema), purchaseOrderController.updatePurchaseOrder);
router.patch('/:id/submit', validateParams(purchaseOrderIdSchema), validate(submitPurchaseOrderSchema), purchaseOrderController.submitPurchaseOrder);

// Routes for assistant managers and managers
router.get(
  '/pending/assistant',
  authorizeRoles([UserRole.ASSISTANT_MANAGER, UserRole.MANAGER]),
  purchaseOrderController.getPurchaseOrdersPendingAssistantReview
);
router.patch(
  '/:id/assistant-approve',
  authorizeRoles([UserRole.ASSISTANT_MANAGER, UserRole.MANAGER]),
  validateParams(purchaseOrderIdSchema),
  validate(approvePurchaseOrderSchema),
  purchaseOrderController.assistantApprove
);
router.patch(
  '/:id/assistant-reject',
  authorizeRoles([UserRole.ASSISTANT_MANAGER, UserRole.MANAGER]),
  validateParams(purchaseOrderIdSchema),
  validate(rejectPurchaseOrderSchema),
  purchaseOrderController.assistantReject
);

// Routes for managers only
router.get(
  '/pending/manager',
  authorizeRoles([UserRole.MANAGER]),
  purchaseOrderController.getPurchaseOrdersPendingManagerReview
);
router.patch(
  '/:id/manager-approve',
  authorizeRoles([UserRole.MANAGER]),
  validateParams(purchaseOrderIdSchema),
  validate(approvePurchaseOrderSchema),
  purchaseOrderController.managerApprove
);
router.patch(
  '/:id/manager-reject',
  authorizeRoles([UserRole.MANAGER]),
  validateParams(purchaseOrderIdSchema),
  validate(rejectPurchaseOrderSchema),
  purchaseOrderController.managerReject
);
router.patch(
  '/:id/complete',
  authorizeRoles([UserRole.MANAGER]),
  validateParams(purchaseOrderIdSchema),
  validate(completePurchaseOrderSchema),
  purchaseOrderController.completePurchaseOrder
);

// Route for filtering purchase orders (assistant managers and managers)
router.get(
  '/',
  authorizeRoles([UserRole.ASSISTANT_MANAGER, UserRole.MANAGER]),
  validateQuery(purchaseOrderQuerySchema),
  purchaseOrderController.getPurchaseOrders
);

export default router;