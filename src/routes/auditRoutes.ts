import { Router } from 'express';
import * as auditController from '../controllers/auditController';
import { authenticateJWT } from '../middlewares/authMiddleware';

const router = Router();

// Apply authentication middleware to all routes
router.use(authenticateJWT);

// Get audit logs
router.get('/', auditController.getAuditLogs);

export default router;