import { Router, Request, Response } from 'express';
import { authenticateJWT, authorizeRoles } from '../middlewares/authMiddleware';
import { UserRole } from '../types/models';

const router = Router();

// Protected route that requires manager role
router.get('/ping', 
  authenticateJWT, 
  authorizeRoles([UserRole.MANAGER]), 
  (req: Request, res: Response) => {
    res.status(200).json({ 
      message: 'Admin ping successful',
      user: req.user
    });
  }
);

export default router;