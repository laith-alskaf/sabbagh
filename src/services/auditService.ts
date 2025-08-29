import { pool } from '../config/database';
import { AuditLogResponse } from '../types/audit';

/**
 * Create an audit log entry (pg implementation)
 */
export const createAuditLog = async (
  actorId: string,
  action: string,
  entityType: string,
  entityId: string | null,
  details: any
): Promise<AuditLogResponse> => {
  // Use CTE to insert then return with joined actor info
  const sql = `
    with inserted as (
      insert into audit_logs (actor_id, action, entity_type, entity_id, details)
      values ($1, $2, $3, $4, $5)
      returning id, actor_id, action, entity_type, entity_id, details, created_at
    )
    select i.id,
           i.actor_id,
           u.name  as actor_name,
           u.email as actor_email,
           i.action,
           i.entity_type,
           i.entity_id,
           i.details,
           i.created_at
    from inserted i
    left join users u on u.id = i.actor_id
  `;

  const params = [actorId, action, entityType, entityId, details];
  const { rows } = await pool.query(sql, params);
  const row = rows[0];

  return {
    id: row.id,
    actor_id: row.actor_id,
    actor_name: row.actor_name ?? undefined,
    actor_email: row.actor_email ?? undefined,
    action: row.action,
    entity_type: row.entity_type,
    entity_id: row.entity_id,
    details: row.details,
    created_at: row.created_at,
  };
};

/**
 * Get audit logs with optional filters (pg implementation)
 */
export const getAuditLogs = async (
  entityType?: string,
  entityId?: string,
  actorId?: string,
  limit = 50,
  offset = 0
): Promise<AuditLogResponse[]> => {
  const conditions: string[] = [];
  const params: any[] = [];

  if (entityType) {
    params.push(entityType);
    conditions.push(`al.entity_type = $${params.length}`);
  }

  if (entityId) {
    params.push(entityId);
    conditions.push(`al.entity_id = $${params.length}`);
  }

  if (actorId) {
    params.push(actorId);
    conditions.push(`al.actor_id = $${params.length}`);
  }

  // Pagination params
  params.push(limit);
  const limitIndex = params.length;
  params.push(offset);
  const offsetIndex = params.length;

  const whereClause = conditions.length ? `where ${conditions.join(' and ')}` : '';

  const sql = `
    select al.id,
           al.actor_id,
           u.name  as actor_name,
           u.email as actor_email,
           al.action,
           al.entity_type,
           al.entity_id,
           al.details,
           al.created_at
    from audit_logs al
    left join users u on u.id = al.actor_id
    ${whereClause}
    order by al.created_at desc
    limit $${limitIndex} offset $${offsetIndex}
  `;

  const { rows } = await pool.query(sql, params);
  return rows.map((row) => ({
    id: row.id,
    actor_id: row.actor_id,
    actor_name: row.actor_name ?? undefined,
    actor_email: row.actor_email ?? undefined,
    action: row.action,
    entity_type: row.entity_type,
    entity_id: row.entity_id,
    details: row.details,
    created_at: row.created_at,
  }));
};

/**
 * Delete single audit log by id
 */
export const deleteAuditLogById = async (id: string): Promise<number> => {
  const sql = `delete from audit_logs where id = $1`;
  const { rowCount } = await pool.query(sql, [id]);
  return rowCount ?? 0;
};

/**
 * Delete ALL audit logs (careful). Wrapped in transaction for safety.
 */
export const clearAllAuditLogs = async (): Promise<number> => {
  const client = await pool.connect();
  try {
    await client.query('begin');
    const res = await client.query('delete from audit_logs');
    await client.query('commit');
    return res.rowCount ?? 0;
  } catch (e) {
    await client.query('rollback');
    throw e;
  } finally {
    client.release();
  }
};