import { Router } from 'express';
import * as authController from '../controllers/authController';
import { authenticateJWT } from '../middlewares/authMiddleware';

const router = Router();

// Public routes
router.post('/login', authController.login);

// Protected routes
router.post('/change-password', authenticateJWT, authController.changePassword);
router.get('/me', authenticateJWT, authController.getCurrentUser);

export default router;