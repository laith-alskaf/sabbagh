import { Request, Response } from 'express';
import { UserRole } from '../types/models';
import * as dashboardService from '../services/dashboardService';
import { AppError, asyncHandler } from '../middlewares/errorMiddleware';
import { t } from '../utils/i18n';

/**
 * Get purchase orders count by status
 * GET /dashboard/orders-by-status
 */
export const getPurchaseOrdersByStatus = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  // Only managers and assistant managers can access dashboard data
  if (req.user.role !== UserRole.MANAGER && req.user.role !== UserRole.ASSISTANT_MANAGER) {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }

  const ordersByStatus = await dashboardService.getPurchaseOrdersByStatus();

  res.status(200).json({
    success: true,
    data: ordersByStatus,
  });
});

/**
 * Get monthly expenses for the last 12 months
 * GET /dashboard/monthly-expenses
 */
export const getMonthlyExpenses = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  // Only managers and assistant managers can access dashboard data
  if (req.user.role !== UserRole.MANAGER && req.user.role !== UserRole.ASSISTANT_MANAGER) {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }

  // Get locale from query parameter or use default
  const locale = req.query.locale as string || req.acceptsLanguages()[0] || 'en';

  const monthlyExpenses = await dashboardService.getMonthlyExpenses(locale);

  res.status(200).json({
    success: true,
    data: monthlyExpenses,
  });
});

/**
 * Get top suppliers by order count or total value
 * GET /dashboard/top-suppliers
 */
export const getTopSuppliers = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  // Only managers and assistant managers can access dashboard data
  if (req.user.role !== UserRole.MANAGER && req.user.role !== UserRole.ASSISTANT_MANAGER) {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }

  // Get parameters from query
  const limit = req.query.limit ? parseInt(req.query.limit as string) : 5;
  const sortBy = (req.query.sortBy as 'count' | 'value') || 'count';

  const topSuppliers = await dashboardService.getTopSuppliers(limit, sortBy);

  res.status(200).json({
    success: true,
    data: topSuppliers,
  });
});

/**
 * Get quick statistics for the dashboard
 * GET /dashboard/quick-stats
 */
export const getQuickStats = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  // Only managers and assistant managers can access dashboard data
  if (req.user.role !== UserRole.MANAGER && req.user.role !== UserRole.ASSISTANT_MANAGER) {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }

  const quickStats = await dashboardService.getQuickStats();

  res.status(200).json({
    success: true,
    data: quickStats,
  });
});

/**
 * Get recent purchase orders
 * GET /dashboard/recent-orders
 */
export const getRecentOrders = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  // Only managers and assistant managers can access dashboard data
  if (req.user.role !== UserRole.MANAGER && req.user.role !== UserRole.ASSISTANT_MANAGER) {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }

  // Get limit from query parameter or use default
  const limit = req.query.limit ? parseInt(req.query.limit as string) : 5;

  const recentOrders = await dashboardService.getRecentOrders(limit);

  res.status(200).json({
    success: true,
    data: recentOrders,
  });
});