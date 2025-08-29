import { Request, Response } from 'express';
import { UserRole } from '../types/models';
import * as auditService from '../services/auditService';
import { AppError, asyncHandler } from '../middlewares/errorMiddleware';
import { t } from '../utils/i18n';

/**
 * Get audit logs
 * GET /audit-logs
 */
export const getAuditLogs = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AppError(t(req, 'token.required', { ns: 'auth' }), 401);
  }

  // Only managers can view audit logs
  if (req.user.role !== UserRole.MANAGER && req.user.role !== UserRole.GENERAL_MANAGER) {
    throw new AppError(t(req, 'permission.denied', { ns: 'auth' }), 403);
  }

  const { entity_type, entity_id, actor_id, limit, offset } = req.query;

  const auditLogs = await auditService.getAuditLogs(
    entity_type as string,
    entity_id as string,
    actor_id as string,
    limit ? parseInt(limit as string) : undefined,
    offset ? parseInt(offset as string) : undefined
  );

  res.status(200).json({
    success: true,
    count: auditLogs.length,
    data: auditLogs,
  });
});