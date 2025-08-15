import { Router } from 'express';
import * as reportController from '../controllers/reportController';
import { authenticateJWT, authorizeRoles } from '../middlewares/authMiddleware';
import { UserRole } from '../types/models';

const router = Router();

// Apply authentication middleware to all routes
router.use(authenticateJWT);

// Apply authorization middleware to all routes - only managers and assistant managers can access
router.use(authorizeRoles([UserRole.MANAGER, UserRole.ASSISTANT_MANAGER]));

// Expense report routes
router.get('/expenses', reportController.getExpenseReport);
router.get('/expenses/export', reportController.exportExpenseReport);

// Quantity report routes
router.get('/quantities', reportController.getQuantityReport);
router.get('/quantities/export', reportController.exportQuantityReport);

// Purchase order list routes
router.get('/purchase-orders', reportController.getPurchaseOrderList);
router.get('/purchase-orders/export', reportController.exportPurchaseOrderList);

export default router;