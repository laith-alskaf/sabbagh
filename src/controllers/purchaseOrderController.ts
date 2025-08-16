import { Request, Response } from 'express';
import { UserRole } from '../types/models';
import * as purchaseOrderService from '../services/purchaseOrderService';
import { ApproveRejectRequest, CreatePurchaseOrderRequest, UpdatePurchaseOrderRequest } from '../types/purchaseOrder';
import { AppError, asyncHandler } from '../middlewares/errorMiddleware';
import { t } from '../utils/i18n';

/**
 * Get all purchase orders with filtering
 * GET /purchase-orders
 */
export const getPurchaseOrders = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  const { status, supplier_id, department, start_date, end_date, limit, offset } = req.query;

  const purchaseOrders = await purchaseOrderService.getPurchaseOrders(
    req.user.userId,
    req.user.role as UserRole,
    status as any,
    supplier_id as string,
    department as string,
    start_date ? new Date(start_date as string) : undefined,
    end_date ? new Date(end_date as string) : undefined,
    limit ? parseInt(limit as string) : undefined,
    offset ? parseInt(offset as string) : undefined
  );

  res.status(200).json({
    success: true,
    count: purchaseOrders.length,
    data: purchaseOrders,
  });
});

/**
 * Get purchase orders created by the current user
 * GET /purchase-orders/my
 */
export const getMyPurchaseOrders = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  const { status, limit, offset } = req.query;

  const purchaseOrders = await purchaseOrderService.getPurchaseOrders(
    req.user.userId,
    UserRole.EMPLOYEE, // Force employee role to only see own purchase orders
    status as any,
    undefined,
    undefined,
    undefined,
    undefined,
    limit ? parseInt(limit as string) : undefined,
    offset ? parseInt(offset as string) : undefined
  );

  res.status(200).json({
    success: true,
    count: purchaseOrders.length,
    data: purchaseOrders,
  });
});

/**
 * Get purchase orders pending assistant manager review
 * GET /purchase-orders/pending/assistant
 */
export const getPurchaseOrdersPendingAssistantReview = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  // Only assistant managers and managers can access this endpoint
  if (req.user.role !== UserRole.ASSISTANT_MANAGER && req.user.role !== UserRole.MANAGER) {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }

  const { limit, offset } = req.query;

  const purchaseOrders = await purchaseOrderService.getPurchaseOrdersPendingAssistantReview(
    limit ? parseInt(limit as string) : undefined,
    offset ? parseInt(offset as string) : undefined
  );

  res.status(200).json({
    success: true,
    count: purchaseOrders.length,
    data: purchaseOrders,
  });
});

/**
 * Get purchase orders pending manager review
 * GET /purchase-orders/pending/manager
 */
export const getPurchaseOrdersPendingManagerReview = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  // Only managers can access this endpoint
  if (req.user.role !== UserRole.MANAGER) {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }

  const { limit, offset } = req.query;

  const purchaseOrders = await purchaseOrderService.getPurchaseOrdersPendingManagerReview(
    limit ? parseInt(limit as string) : undefined,
    offset ? parseInt(offset as string) : undefined
  );

  res.status(200).json({
    success: true,
    count: purchaseOrders.length,
    data: purchaseOrders,
  });
});

/**
 * Get a purchase order by ID
 * GET /purchase-orders/:id
 */
export const getPurchaseOrderById = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  const { id } = req.params;

  const purchaseOrder = await purchaseOrderService.getPurchaseOrderById(
    id,
    req.user.userId,
    req.user.role as UserRole
  );

  if (!purchaseOrder) {
    throw new AppError(t(req, 'purchaseOrder.notFound', { ns: 'errors' }), 404);
  }

  res.status(200).json({
    success: true,
    data: purchaseOrder,
  });
});

/**
 * Create a purchase order
 * POST /purchase-orders
 */
export const createPurchaseOrder = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  const purchaseOrderData: CreatePurchaseOrderRequest = req.body;

  // Validate required fields
  // if (!purchaseOrderData.request_date || !purchaseOrderData.department || 
  //     !purchaseOrderData.request_type || !purchaseOrderData.requester_name || 
  //     !purchaseOrderData.currency || !purchaseOrderData.items || purchaseOrderData.items.length === 0) {
  //   throw new AppError(t(req, 'validation.requiredFields', { ns: 'errors' }), 400);
  // }

  const purchaseOrder = await purchaseOrderService.createPurchaseOrder(
    purchaseOrderData,
    req.user.userId,
    req.user.role as UserRole
  );

  res.status(201).json({
    success: true,
    message: t(req, 'purchaseOrder.created', { ns: 'common' }),
    data: purchaseOrder,
  });
});

/**
 * Update a purchase order
 * PUT /purchase-orders/:id
 */
export const updatePurchaseOrder = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  const { id } = req.params;
  const purchaseOrderData: UpdatePurchaseOrderRequest = req.body;

  try {
    const purchaseOrder = await purchaseOrderService.updatePurchaseOrder(
      id,
      purchaseOrderData,
      req.user.userId,
      req.user.role as UserRole
    );

    res.status(200).json({
      success: true,
      message: t(req, 'purchaseOrder.updated', { ns: 'common' }),
      data: purchaseOrder,
    });
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(
      t(req, 'purchaseOrder.updateFailed', { ns: 'errors' }),
      500
    );
  }
});

/**
 * Submit a draft purchase order for review
 * PATCH /purchase-orders/:id/submit
 */
export const submitPurchaseOrder = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  const { id } = req.params;

  try {
    const purchaseOrder = await purchaseOrderService.submitPurchaseOrder(
      id,
      req.user.userId,
      req.user.role as UserRole
    );

    res.status(200).json({
      success: true,
      message: t(req, 'purchaseOrder.submitted', { ns: 'common' }),
      data: purchaseOrder,
    });
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(
      t(req, 'purchaseOrder.submitFailed', { ns: 'errors' }),
      500
    );
  }
});

/**
 * Assistant manager approves a purchase order
 * PATCH /purchase-orders/:id/assistant-approve
 */
export const assistantApprove = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  // Only assistant managers and managers can approve purchase orders
  if (req.user.role !== UserRole.ASSISTANT_MANAGER && req.user.role !== UserRole.MANAGER) {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }

  const { id } = req.params;

  try {
    const purchaseOrder = await purchaseOrderService.assistantApprove(
      id,
      req.user.userId
    );

    res.status(200).json({
      success: true,
      message: t(req, 'purchaseOrder.assistantApproved', { ns: 'common' }),
      data: purchaseOrder,
    });
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(
      t(req, 'purchaseOrder.approveFailed', { ns: 'errors' }),
      500
    );
  }
});

/**
 * Assistant manager rejects a purchase order
 * PATCH /purchase-orders/:id/assistant-reject
 */
export const assistantReject = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  // Only assistant managers and managers can reject purchase orders
  if (req.user.role !== UserRole.ASSISTANT_MANAGER && req.user.role !== UserRole.MANAGER) {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }

  const { id } = req.params;
  const { reason }: ApproveRejectRequest = req.body;

  try {
    const purchaseOrder = await purchaseOrderService.assistantReject(
      id,
      req.user.userId,
      reason
    );

    res.status(200).json({
      success: true,
      message: t(req, 'purchaseOrder.assistantRejected', { ns: 'common' }),
      data: purchaseOrder,
    });
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(
      t(req, 'purchaseOrder.rejectFailed', { ns: 'errors' }),
      500
    );
  }
});

/**
 * Manager approves a purchase order
 * PATCH /purchase-orders/:id/manager-approve
 */
export const managerApprove = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  // Only managers can approve purchase orders
  if (req.user.role !== UserRole.MANAGER) {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }

  const { id } = req.params;

  try {
    const purchaseOrder = await purchaseOrderService.managerApprove(
      id,
      req.user.userId
    );

    res.status(200).json({
      success: true,
      message: t(req, 'purchaseOrder.managerApproved', { ns: 'common' }),
      data: purchaseOrder,
    });
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(
      t(req, 'purchaseOrder.approveFailed', { ns: 'errors' }),
      500
    );
  }
});

/**
 * Manager rejects a purchase order
 * PATCH /purchase-orders/:id/manager-reject
 */
export const managerReject = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  // Only managers can reject purchase orders
  if (req.user.role !== UserRole.MANAGER) {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }

  const { id } = req.params;
  const { reason }: ApproveRejectRequest = req.body;

  try {
    const purchaseOrder = await purchaseOrderService.managerReject(
      id,
      req.user.userId,
      reason
    );

    res.status(200).json({
      success: true,
      message: t(req, 'purchaseOrder.managerRejected', { ns: 'common' }),
      data: purchaseOrder,
    });
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(
      t(req, 'purchaseOrder.rejectFailed', { ns: 'errors' }),
      500
    );
  }
});

/**
 * Mark a purchase order as completed
 * PATCH /purchase-orders/:id/complete
 */
export const completePurchaseOrder = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  // Only managers can mark purchase orders as completed
  if (req.user.role !== UserRole.MANAGER) {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }

  const { id } = req.params;

  try {
    const purchaseOrder = await purchaseOrderService.completePurchaseOrder(
      id,
      req.user.userId
    );

    res.status(200).json({
      success: true,
      message: t(req, 'purchaseOrder.completed', { ns: 'common' }),
      data: purchaseOrder,
    });
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(
      t(req, 'purchaseOrder.completeFailed', { ns: 'errors' }),
      500
    );
  }
});