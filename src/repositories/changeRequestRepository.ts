import { pool } from '../config/database';
import { ChangeRequestResponse } from '../types/changeRequest';
import { ChangeRequestStatus, EntityType, OperationType } from '../types/models';

export async function findChangeRequests(params: {
  status?: ChangeRequestStatus;
  entityType?: EntityType;
  requestedBy?: string;
  limit?: number;
  offset?: number;
}): Promise<ChangeRequestResponse[]> {
  const conditions: string[] = [];
  const values: any[] = [];

  if (params.status) { values.push(params.status); conditions.push(`cr.status = $${values.length}`); }
  if (params.entityType) { values.push(params.entityType); conditions.push(`cr.entity_type = $${values.length}`); }
  if (params.requestedBy) { values.push(params.requestedBy); conditions.push(`cr.requested_by = $${values.length}`); }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  values.push(params.limit ?? 50); const limitIndex = values.length;
  values.push(params.offset ?? 0); const offsetIndex = values.length;

  const sql = `
    SELECT cr.id, cr.entity_type, cr.operation, cr.payload, cr.target_id, cr.status,
           cr.requested_by, req.name AS requester_name, req.email AS requester_email,
           cr.reviewed_by, rev.name AS reviewer_name, rev.email AS reviewer_email,
           cr.reviewed_at, cr.reason, cr.created_at, cr.updated_at
    FROM change_requests cr
    LEFT JOIN users req ON req.id = cr.requested_by
    LEFT JOIN users rev ON rev.id = cr.reviewed_by
    ${where}
    ORDER BY cr.created_at DESC
    LIMIT $${limitIndex} OFFSET $${offsetIndex}
  `;

  const { rows } = await pool.query(sql, values);
  return rows;
}

export async function findById(id: string): Promise<ChangeRequestResponse | null> {
  const sql = `
    SELECT cr.id, cr.entity_type, cr.operation, cr.payload, cr.target_id, cr.status,
           cr.requested_by, req.name AS requester_name, req.email AS requester_email,
           cr.reviewed_by, rev.name AS reviewer_name, rev.email AS reviewer_email,
           cr.reviewed_at, cr.reason, cr.created_at, cr.updated_at
    FROM change_requests cr
    LEFT JOIN users req ON req.id = cr.requested_by
    LEFT JOIN users rev ON rev.id = cr.reviewed_by
    WHERE cr.id = $1
  `;
  const { rows } = await pool.query(sql, [id]);
  return rows[0] ?? null;
}

export async function create(params: {
  operation: OperationType;
  entity_type: EntityType;
  target_id: string | null;
  payload: any;
  requested_by: string;
}): Promise<ChangeRequestResponse> {
  const sql = `
    WITH inserted AS (
      INSERT INTO change_requests (operation, entity_type, target_id, payload, status, requested_by)
      VALUES ($1, $2, $3, $4, 'pending', $5)
      RETURNING *
    )
    SELECT i.id, i.entity_type, i.operation, i.payload, i.target_id, i.status,
           i.requested_by, req.name AS requester_name, req.email AS requester_email,
           i.reviewed_by, rev.name AS reviewer_name, rev.email AS reviewer_email,
           i.reviewed_at, i.reason, i.created_at, i.updated_at
    FROM inserted i
    LEFT JOIN users req ON req.id = i.requested_by
    LEFT JOIN users rev ON rev.id = i.reviewed_by
  `;
  const { rows } = await pool.query(sql, [
    params.operation,
    params.entity_type,
    params.target_id,
    params.payload, // pg will serialize JSON automatically
    params.requested_by,
  ]);
  return rows[0];
}

export async function approve(id: string, reviewerId: string): Promise<ChangeRequestResponse> {
  const sql = `
    WITH updated AS (
      UPDATE change_requests
      SET status = 'approved', reviewed_by = $2, reviewed_at = now()
      WHERE id = $1
      RETURNING *
    )
    SELECT u.id, u.entity_type, u.operation, u.payload, u.target_id, u.status,
           u.requested_by, req.name AS requester_name, req.email AS requester_email,
           u.reviewed_by, rev.name AS reviewer_name, rev.email AS reviewer_email,
           u.reviewed_at, u.reason, u.created_at, u.updated_at
    FROM updated u
    LEFT JOIN users req ON req.id = u.requested_by
    LEFT JOIN users rev ON rev.id = u.reviewed_by
  `;
  const { rows } = await pool.query(sql, [id, reviewerId]);
  if (!rows[0]) throw new Error('Change request not found');
  return rows[0];
}

export async function reject(id: string, reviewerId: string, reason?: string): Promise<ChangeRequestResponse> {
  const sql = `
    WITH updated AS (
      UPDATE change_requests
      SET status = 'rejected', reviewed_by = $2, reviewed_at = now(), reason = $3
      WHERE id = $1
      RETURNING *
    )
    SELECT u.id, u.entity_type, u.operation, u.payload, u.target_id, u.status,
           u.requested_by, req.name AS requester_name, req.email AS requester_email,
           u.reviewed_by, rev.name AS reviewer_name, rev.email AS reviewer_email,
           u.reviewed_at, u.reason, u.created_at, u.updated_at
    FROM updated u
    LEFT JOIN users req ON req.id = u.requested_by
    LEFT JOIN users rev ON rev.id = u.reviewed_by
  `;
  const { rows } = await pool.query(sql, [id, reviewerId, reason ?? null]);
  if (!rows[0]) throw new Error('Change request not found');
  return rows[0];
}