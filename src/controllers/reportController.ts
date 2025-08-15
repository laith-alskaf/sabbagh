import { Request, Response } from 'express';
import { UserRole } from '../types/models';
import * as reportService from '../services/reportService';
import { AppError, asyncHandler } from '../middlewares/errorMiddleware';
import { t } from '../utils/i18n';

/**
 * Get expense report data
 * GET /reports/expenses
 */
export const getExpenseReport = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  // Only managers and assistant managers can access reports
  if (req.user.role !== UserRole.MANAGER && req.user.role !== UserRole.ASSISTANT_MANAGER) {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }

  // Parse filters from query parameters
  const filters = {
    startDate: req.query.startDate ? new Date(req.query.startDate as string) : undefined,
    endDate: req.query.endDate ? new Date(req.query.endDate as string) : undefined,
    supplierId: req.query.supplierId as string,
    department: req.query.department as string,
    status: req.query.status as string
  };

  // Parse pagination parameters
  const page = req.query.page ? parseInt(req.query.page as string) : 1;
  const limit = req.query.limit ? parseInt(req.query.limit as string) : 10;

  const reportData = await reportService.getExpenseReport(filters, { page, limit });

  res.status(200).json({
    success: true,
    data: reportData.data,
    pagination: reportData.pagination,
    summary: reportData.summary
  });
});

/**
 * Export expense report to Excel
 * GET /reports/expenses/export
 */
export const exportExpenseReport = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  // Only managers and assistant managers can access reports
  if (req.user.role !== UserRole.MANAGER && req.user.role !== UserRole.ASSISTANT_MANAGER) {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }

  // Parse filters from query parameters
  const filters = {
    startDate: req.query.startDate ? new Date(req.query.startDate as string) : undefined,
    endDate: req.query.endDate ? new Date(req.query.endDate as string) : undefined,
    supplierId: req.query.supplierId as string,
    department: req.query.department as string,
    status: req.query.status as string
  };

  // Get locale from query parameter or use default
  const locale = req.query.locale as string || req.acceptsLanguages()[0] || 'en';

  // Generate Excel file
  const workbook = await reportService.generateExpenseReportExcel(filters, locale);

  // Set response headers
  res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  res.setHeader('Content-Disposition', 'attachment; filename=expense-report.xlsx');

  // Write to response
  await workbook.xlsx.write(res);
  res.end();
});

/**
 * Get purchase quantity report data
 * GET /reports/quantities
 */
export const getQuantityReport = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  // Only managers and assistant managers can access reports
  if (req.user.role !== UserRole.MANAGER && req.user.role !== UserRole.ASSISTANT_MANAGER) {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }

  // Parse filters from query parameters
  const filters = {
    startDate: req.query.startDate ? new Date(req.query.startDate as string) : undefined,
    endDate: req.query.endDate ? new Date(req.query.endDate as string) : undefined,
    itemId: req.query.itemId as string,
    department: req.query.department as string
  };

  // Parse pagination parameters
  const page = req.query.page ? parseInt(req.query.page as string) : 1;
  const limit = req.query.limit ? parseInt(req.query.limit as string) : 10;

  const reportData = await reportService.getQuantityReport(filters, { page, limit });

  res.status(200).json({
    success: true,
    data: reportData.data,
    pagination: reportData.pagination,
    summary: reportData.summary
  });
});

/**
 * Export purchase quantity report to Excel
 * GET /reports/quantities/export
 */
export const exportQuantityReport = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  // Only managers and assistant managers can access reports
  if (req.user.role !== UserRole.MANAGER && req.user.role !== UserRole.ASSISTANT_MANAGER) {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }

  // Parse filters from query parameters
  const filters = {
    startDate: req.query.startDate ? new Date(req.query.startDate as string) : undefined,
    endDate: req.query.endDate ? new Date(req.query.endDate as string) : undefined,
    itemId: req.query.itemId as string,
    department: req.query.department as string
  };

  // Get locale from query parameter or use default
  const locale = req.query.locale as string || req.acceptsLanguages()[0] || 'en';

  // Generate Excel file
  const workbook = await reportService.generateQuantityReportExcel(filters, locale);

  // Set response headers
  res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  res.setHeader('Content-Disposition', 'attachment; filename=quantity-report.xlsx');

  // Write to response
  await workbook.xlsx.write(res);
  res.end();
});

/**
 * Get purchase order list data
 * GET /reports/purchase-orders
 */
export const getPurchaseOrderList = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  // Only managers and assistant managers can access reports
  if (req.user.role !== UserRole.MANAGER && req.user.role !== UserRole.ASSISTANT_MANAGER) {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }

  // Parse filters from query parameters
  const filters = {
    startDate: req.query.startDate ? new Date(req.query.startDate as string) : undefined,
    endDate: req.query.endDate ? new Date(req.query.endDate as string) : undefined,
    supplierId: req.query.supplierId as string,
    department: req.query.department as string,
    status: req.query.status as string
  };

  // Parse pagination parameters
  const page = req.query.page ? parseInt(req.query.page as string) : 1;
  const limit = req.query.limit ? parseInt(req.query.limit as string) : 10;

  const listData = await reportService.getPurchaseOrderList(filters, { page, limit });

  res.status(200).json({
    success: true,
    data: listData.data,
    pagination: listData.pagination
  });
});

/**
 * Export purchase order list to Excel
 * GET /reports/purchase-orders/export
 */
export const exportPurchaseOrderList = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  // Only managers and assistant managers can access reports
  if (req.user.role !== UserRole.MANAGER && req.user.role !== UserRole.ASSISTANT_MANAGER) {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }

  // Parse filters from query parameters
  const filters = {
    startDate: req.query.startDate ? new Date(req.query.startDate as string) : undefined,
    endDate: req.query.endDate ? new Date(req.query.endDate as string) : undefined,
    supplierId: req.query.supplierId as string,
    department: req.query.department as string,
    status: req.query.status as string
  };

  // Get locale from query parameter or use default
  const locale = req.query.locale as string || req.acceptsLanguages()[0] || 'en';

  // Generate Excel file
  const workbook = await reportService.generatePurchaseOrderListExcel(filters, locale);

  // Set response headers
  res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  res.setHeader('Content-Disposition', 'attachment; filename=purchase-order-list.xlsx');

  // Write to response
  await workbook.xlsx.write(res);
  res.end();
});