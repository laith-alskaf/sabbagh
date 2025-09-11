import { Request, Response, NextFunction } from 'express';
import { verifyToken } from '../services/authService';
import { UserRole } from '../types/models';
import { t } from '../utils/i18n';
import { AppError } from './errorMiddleware';

// Extend Express Request type to include user
declare global {
  namespace Express {
    interface Request {
      user?: {
        userId: string;
        email: string;
        role: UserRole;
      };
    }
  }
}

/**
 * Middleware to authenticate JWT token
 */
export const authenticateJWT = (req: Request, res: Response, next: NextFunction) => {
  // Get the token from the Authorization header
  const authHeader = req.headers.authorization;
  
  if (!authHeader) {
    return next(new AppError(t(req, 'token.required', { ns: 'auth' }), 401));
  }

  // Check if the header has the correct format
  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') {
    return next(new AppError(t(req, 'token.invalid', { ns: 'auth' }), 401));
  }

  const token = parts[1];

  try {
    // Verify the token
    const decoded = verifyToken(token);
    
    // Attach user info to the request
    req.user = {
      userId: decoded.userId,
      email: decoded.email,
      role: decoded.role,
    };
    
    next();
  } catch (error) {
    if (error instanceof Error && error.name === 'TokenExpiredError') {
      return next(new AppError(t(req, 'token.expired', { ns: 'auth' }), 401));
    }
    return next(new AppError(t(req, 'token.invalid', { ns: 'auth' }), 401));
  }
};

/**
 * Middleware to authorize user roles
 */
export const authorizeRoles = (roles: UserRole[]) => {
  return (req: Request, res: Response, next: NextFunction) => {
    // Check if user exists (should be set by authenticateJWT)
    if (!req.user) {
      return next(new AppError(t(req, 'token.required', { ns: 'auth' }), 401));
    }

    // Check if user has the required role
    if (!roles.includes(req.user.role)) {
      return next(new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403));
    }

    next();
  };
};