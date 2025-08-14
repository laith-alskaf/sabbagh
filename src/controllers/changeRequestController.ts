import { Request, Response } from 'express';
import { ChangeRequestStatus, EntityType, UserRole } from '@prisma/client';
import * as changeRequestService from '../services/changeRequestService';
import { ApproveRejectRequest } from '../types/changeRequest';
import { AppError, asyncHandler } from '../middlewares/errorMiddleware';
import { t } from '../utils/i18n';

/**
 * Get all change requests
 * GET /change-requests
 */
export const getChangeRequests = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }
  
  const { status, entity_type, limit, offset } = req.query;
  
  // Employees can only see their own change requests
  const requestedBy = req.user.role === UserRole.employee ? req.user.userId : undefined;
  
  const changeRequests = await changeRequestService.getChangeRequests(
    status as ChangeRequestStatus,
    entity_type as EntityType,
    requestedBy,
    limit ? parseInt(limit as string) : undefined,
    offset ? parseInt(offset as string) : undefined
  );
  
  res.status(200).json({
    success: true,
    count: changeRequests.length,
    data: changeRequests,
  });
});

/**
 * Get a change request by ID
 * GET /change-requests/:id
 */
export const getChangeRequestById = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }
  
  const { id } = req.params;
  
  const changeRequest = await changeRequestService.getChangeRequestById(id);
  
  if (!changeRequest) {
    throw new AppError(t(req, 'changeRequest.notFound', { ns: 'errors' }), 404);
  }
  
  // Employees can only see their own change requests
  if (req.user.role === UserRole.employee && changeRequest.requested_by !== req.user.userId) {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }
  
  res.status(200).json({
    success: true,
    data: changeRequest,
  });
});

/**
 * Approve a change request
 * POST /change-requests/:id/approve
 */
export const approveChangeRequest = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }
  
  // Only managers can approve change requests
  if (req.user.role !== UserRole.manager) {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }
  
  const { id } = req.params;
  
  try {
    const changeRequest = await changeRequestService.approveChangeRequest(id, req.user.userId);
    
    res.status(200).json({
      success: true,
      message: t(req, 'changeRequest.approved', { ns: 'common' }),
      data: changeRequest,
    });
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(
      `${t(req, 'changeRequest.approveFailed', { ns: 'errors' })}: ${error instanceof Error ? error.message : 'Unknown error'}`,
      500
    );
  }
});

/**
 * Reject a change request
 * POST /change-requests/:id/reject
 */
export const rejectChangeRequest = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }
  
  // Only managers can reject change requests
  if (req.user.role !== UserRole.manager) {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }
  
  const { id } = req.params;
  const { reason }: ApproveRejectRequest = req.body;
  
  const changeRequest = await changeRequestService.rejectChangeRequest(id, req.user.userId, reason);
  
  res.status(200).json({
    success: true,
    message: t(req, 'changeRequest.rejected', { ns: 'common' }),
    data: changeRequest,
  });
});