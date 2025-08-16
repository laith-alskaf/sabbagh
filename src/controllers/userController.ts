import { Request, Response } from 'express';
import { AppError, asyncHandler } from '../middlewares/errorMiddleware';
import { t } from '../utils/i18n';
import { logInfo, logError } from '../utils/logger';
import * as userService from '../services/userService';
import { UserRole } from '../types/models';

/**
 * Get all users with pagination and filtering
 */
export const getUsers = asyncHandler(async (req: Request, res: Response) => {
  const { 
    page = 1, 
    limit = 10, 
    search, 
    role, 
    department, 
    is_active, 
    sort = 'created_at', 
    order = 'desc' 
  } = (req as any).validatedQuery || req.query;

  logInfo('Getting users list', {
    requestId: req.requestId,
    userId: req.user?.userId,
    filters: { search, role, department, is_active, sort, order },
    pagination: { page: Number(page), limit: Number(limit) },
  });

  try {
    const filters = {
      search,
      role: role as UserRole,
      department,
      is_active: is_active !== undefined ? Boolean(is_active) : undefined,
    };

    const pagination = {
      page: Number(page),
      limit: Number(limit),
      sort,
      order: order as 'asc' | 'desc',
    };

    const result = await userService.getUsers(filters, pagination);

    res.json({
      success: true,
      data: result.users,
      pagination: result.pagination,
    });
  } catch (error) {
    logError(error as Error, {
      requestId: req.requestId,
      userId: req.user?.userId,
      action: 'getUsers',
    });
    throw error;
  }
});

/**
 * Get user by ID
 */
export const getUserById = asyncHandler(async (req: Request, res: Response) => {
  const { id } = (req as any).validatedParams || req.params;

  logInfo('Getting user by ID', {
    requestId: req.requestId,
    userId: req.user?.userId,
    targetUserId: id,
  });

  try {
    const user = await userService.getUserById(id);

    if (!user) {
      throw new AppError(t(req, 'user.notFound', { ns: 'errors' }), 404);
    }

    res.json({
      success: true,
      data: user,
    });
  } catch (error) {
    logError(error as Error, {
      requestId: req.requestId,
      userId: req.user?.userId,
      targetUserId: id,
      action: 'getUserById',
    });
    throw error;
  }
});

/**
 * Create new user
 */
export const createUser = asyncHandler(async (req: Request, res: Response) => {
  const userData = req.body;

  logInfo('Creating new user', {
    requestId: req.requestId,
    userId: req.user?.userId,
    newUserEmail: userData.email,
    newUserRole: userData.role,
  });

  try {
    // Check permissions
    const currentUserRole = req.user?.role as UserRole;
    if (!userService.canCreateUserWithRole(currentUserRole, userData.role)) {
      throw new AppError(t(req, 'user.insufficientPermissions', { ns: 'errors' }), 403);
    }

    const newUser = await userService.createUser({
      name: userData.name,
      email: userData.email,
      password: userData.password,
      role: userData.role,
      department: userData.department,
      phone: userData.phone,
    });

    res.status(201).json({
      success: true,
      message: t(req, 'user.created', { ns: 'success' }),
      data: newUser,
    });
  } catch (error) {
    logError(error as Error, {
      requestId: req.requestId,
      userId: req.user?.userId,
      newUserEmail: userData.email,
      action: 'createUser',
    });
    throw error;
  }
});

/**
 * Update user
 */
export const updateUser = asyncHandler(async (req: Request, res: Response) => {
  const { id } = (req as any).validatedParams || req.params;
  const updateData = req.body;

  logInfo('Updating user', {
    requestId: req.requestId,
    userId: req.user?.userId,
    targetUserId: id,
    updateFields: Object.keys(updateData),
  });

  try {
    // Get target user to check permissions
    const targetUser = await userService.getUserById(id);
    if (!targetUser) {
      throw new AppError(t(req, 'user.notFound', { ns: 'errors' }), 404);
    }

    // Check permissions
    const currentUserRole = req.user?.role as UserRole;
    if (!userService.canManageUser(currentUserRole, targetUser.role as UserRole)) {
      throw new AppError(t(req, 'user.insufficientPermissions', { ns: 'errors' }), 403);
    }

    // If role is being changed, check if current user can assign the new role
    if (updateData.role && !userService.canCreateUserWithRole(currentUserRole, updateData.role)) {
      throw new AppError(t(req, 'user.cannotAssignRole', { ns: 'errors' }), 403);
    }

    const updatedUser = await userService.updateUser(id, {
      name: updateData.name,
      email: updateData.email,
      role: updateData.role,
      department: updateData.department,
      phone: updateData.phone,
      is_active: updateData.is_active,
    });

    if (!updatedUser) {
      throw new AppError(t(req, 'user.notFound', { ns: 'errors' }), 404);
    }

    res.json({
      success: true,
      message: t(req, 'user.updated', { ns: 'success' }),
      data: updatedUser,
    });
  } catch (error) {
    logError(error as Error, {
      requestId: req.requestId,
      userId: req.user?.userId,
      targetUserId: id,
      action: 'updateUser',
    });
    throw error;
  }
});

/**
 * Delete user (soft delete)
 */
export const deleteUser = asyncHandler(async (req: Request, res: Response) => {
  const { id } = (req as any).validatedParams || req.params;

  logInfo('Deleting user', {
    requestId: req.requestId,
    userId: req.user?.userId,
    targetUserId: id,
  });

  try {
    // Get target user to check permissions
    const targetUser = await userService.getUserById(id);
    if (!targetUser) {
      throw new AppError(t(req, 'user.notFound', { ns: 'errors' }), 404);
    }

    // Check permissions
    const currentUserRole = req.user?.role as UserRole;
    if (!userService.canManageUser(currentUserRole, targetUser.role as UserRole)) {
      throw new AppError(t(req, 'user.insufficientPermissions', { ns: 'errors' }), 403);
    }

    const deleted = await userService.deleteUser(id, req.user?.userId!);

    if (!deleted) {
      throw new AppError(t(req, 'user.notFound', { ns: 'errors' }), 404);
    }

    res.json({
      success: true,
      message: t(req, 'user.deleted', { ns: 'success' }),
    });
  } catch (error) {
    logError(error as Error, {
      requestId: req.requestId,
      userId: req.user?.userId,
      targetUserId: id,
      action: 'deleteUser',
    });
    throw error;
  }
});

/**
 * Change user password (admin only)
 */
export const adminChangePassword = asyncHandler(async (req: Request, res: Response) => {
  const { id } = (req as any).validatedParams || req.params;
  const { new_password } = req.body;

  logInfo('Admin changing user password', {
    requestId: req.requestId,
    userId: req.user?.userId,
    targetUserId: id,
  });

  try {
    // Get target user to check permissions
    const targetUser = await userService.getUserById(id);
    if (!targetUser) {
      throw new AppError(t(req, 'user.notFound', { ns: 'errors' }), 404);
    }

    // Check permissions
    const currentUserRole = req.user?.role as UserRole;
    if (!userService.canManageUser(currentUserRole, targetUser.role as UserRole)) {
      throw new AppError(t(req, 'user.insufficientPermissions', { ns: 'errors' }), 403);
    }

    const success = await userService.changeUserPassword(id, new_password);

    if (!success) {
      throw new AppError(t(req, 'user.notFound', { ns: 'errors' }), 404);
    }

    res.json({
      success: true,
      message: t(req, 'user.passwordChanged', { ns: 'success' }),
    });
  } catch (error) {
    logError(error as Error, {
      requestId: req.requestId,
      userId: req.user?.userId,
      targetUserId: id,
      action: 'adminChangePassword',
    });
    throw error;
  }
});

/**
 * Get all departments
 */
export const getDepartments = asyncHandler(async (req: Request, res: Response) => {
  logInfo('Getting departments list', {
    requestId: req.requestId,
    userId: req.user?.userId,
  });

  try {
    const departments = await userService.getDepartments();

    res.json({
      success: true,
      data: departments,
    });
  } catch (error) {
    logError(error as Error, {
      requestId: req.requestId,
      userId: req.user?.userId,
      action: 'getDepartments',
    });
    throw error;
  }
});