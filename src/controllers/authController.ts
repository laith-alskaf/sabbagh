import { Request, Response } from 'express';
import * as authService from '../services/authService';
import { LoginRequest, ChangePasswordRequest } from '../types/auth';
import { t } from '../utils/i18n';
import { AppError, asyncHandler } from '../middlewares/errorMiddleware';

/**
 * Login controller
 * POST /auth/login
 */
export const login = asyncHandler(async (req: Request, res: Response) => {
  const loginData: LoginRequest = req.body;
  
  // Validate request
  if (!loginData.email || !loginData.password) {
    throw new AppError(t(req, 'validation.required', { field: 'Email and password', ns: 'common' }), 400);
  }
  
  try {
    // Attempt login
    const result = await authService.login(loginData);
    
    // Return token and user info with success message
    return res.status(200).json({
      success: true,
      message: t(req, 'login.success', { ns: 'auth' }),
      ...result
    });
  } catch (error) {
    if (error instanceof Error) {
      // Handle known errors
      if (error.message === 'Invalid email or password') {
        throw new AppError(t(req, 'login.invalidCredentials', { ns: 'auth' }), 401);
      } else if (error.message === 'User account is inactive') {
        throw new AppError(t(req, 'login.accountInactive', { ns: 'auth' }), 401);
      }
    }
    
    // Re-throw other errors to be caught by the error handler
    throw error;
  }
});

/**
 * Change password controller
 * POST /auth/change-password
 */
export const changePassword = asyncHandler(async (req: Request, res: Response) => {
  // Ensure user is authenticated
  if (!req.user || !req.user.userId) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }
  
  const passwordData: ChangePasswordRequest = req.body;
  
  // Validate request
  if (!passwordData.currentPassword || !passwordData.newPassword) {
    throw new AppError(
      t(req, 'validation.required', { field: 'Current password and new password', ns: 'common' }), 
      400
    );
  }
  
  // Validate password strength
  if (passwordData.newPassword.length < 8) {
    throw new AppError(
      t(req, 'validation.minLength', { field: 'New password', min: 8, ns: 'common' }), 
      400
    );
  }
  
  try {
    // Change password
    await authService.changePassword(req.user.userId, passwordData);
    
    return res.status(200).json({
      success: true,
      message: t(req, 'password.changed', { ns: 'auth' })
    });
  } catch (error) {
    if (error instanceof Error) {
      // Handle known errors
      if (error.message === 'Current password is incorrect') {
        throw new AppError(t(req, 'password.incorrect', { ns: 'auth' }), 400);
      } else if (error.message === 'User not found') {
        throw new AppError(t(req, 'user.notFound', { ns: 'auth' }), 404);
      }
    }
    
    // Re-throw other errors to be caught by the error handler
    throw error;
  }
});

/**
 * Get current user info
 * GET /auth/me
 */
export const getCurrentUser = asyncHandler(async (req: Request, res: Response) => {
  // Ensure user is authenticated
  if (!req.user || !req.user.userId) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }
  
  // Return user info from the token
  return res.status(200).json({
    success: true,
    user: {
      id: req.user.userId,
      email: req.user.email,
      role: req.user.role,
    }
  });
});