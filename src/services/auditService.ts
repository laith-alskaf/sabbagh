import { PrismaClient } from '@prisma/client';
import { AuditLogResponse } from '../types/audit';

const prisma = new PrismaClient();

/**
 * Create an audit log entry
 */
export const createAuditLog = async (
  actorId: string,
  action: string,
  entityType: string,
  entityId: string | null,
  details: any
): Promise<AuditLogResponse> => {
  const auditLog = await prisma.auditLog.create({
    data: {
      actor_id: actorId,
      action,
      entity_type: entityType,
      entity_id: entityId,
      details,
    },
    include: {
      actor: {
        select: {
          name: true,
          email: true,
        },
      },
    },
  });

  return {
    id: auditLog.id,
    actor_id: auditLog.actor_id,
    actor_name: auditLog.actor.name,
    actor_email: auditLog.actor.email,
    action: auditLog.action,
    entity_type: auditLog.entity_type,
    entity_id: auditLog.entity_id,
    details: auditLog.details,
    created_at: auditLog.created_at,
  };
};

/**
 * Get audit logs with optional filters
 */
export const getAuditLogs = async (
  entityType?: string,
  entityId?: string,
  actorId?: string,
  limit = 50,
  offset = 0
): Promise<AuditLogResponse[]> => {
  const where: any = {};

  if (entityType) {
    where.entity_type = entityType;
  }

  if (entityId) {
    where.entity_id = entityId;
  }

  if (actorId) {
    where.actor_id = actorId;
  }

  const auditLogs = await prisma.auditLog.findMany({
    where,
    include: {
      actor: {
        select: {
          name: true,
          email: true,
        },
      },
    },
    orderBy: {
      created_at: 'desc',
    },
    take: limit,
    skip: offset,
  });

  return auditLogs.map((log) => ({
    id: log.id,
    actor_id: log.actor_id,
    actor_name: log.actor.name,
    actor_email: log.actor.email,
    action: log.action,
    entity_type: log.entity_type,
    entity_id: log.entity_id,
    details: log.details,
    created_at: log.created_at,
  }));
};