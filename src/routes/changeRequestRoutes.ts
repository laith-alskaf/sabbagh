import { Router } from 'express';
import * as changeRequestController from '../controllers/changeRequestController';
import { authenticateJWT } from '../middlewares/authMiddleware';

const router = Router();

// Apply authentication middleware to all routes
router.use(authenticateJWT);

// Get all change requests
router.get('/', changeRequestController.getChangeRequests);

// Get a change request by ID
router.get('/:id', changeRequestController.getChangeRequestById);

// Approve a change request
router.post('/:id/approve', changeRequestController.approveChangeRequest);

// Reject a change request
router.post('/:id/reject', changeRequestController.rejectChangeRequest);

export default router;