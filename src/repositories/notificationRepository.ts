import { pool } from '../config/database';

export interface NotificationRecord {
  id: string;
  user_id: string;
  type: string;
  title: string;
  body?: string | null;
  data?: any;
  is_read: boolean;
  created_at: Date;
}

export async function insert(user_id: string, type: string, title: string, body: string | null, data: any | null): Promise<NotificationRecord> {
  const { rows } = await pool.query(
    `INSERT INTO notifications (user_id, type, title, body, data)
     VALUES ($1,$2,$3,$4,$5)
     RETURNING *`,
    [user_id, type, title, body, data]
  );
  return rows[0];
}

export async function list(user_id: string, limit = 50, offset = 0): Promise<NotificationRecord[]> {
  const { rows } = await pool.query(
    `SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3`,
    [user_id, limit, offset]
  );
  return rows;
}

export async function markRead(user_id: string, id: string): Promise<boolean> {
  const { rowCount } = await pool.query(
    `UPDATE notifications SET is_read = true WHERE id = $1 AND user_id = $2`,
    [id, user_id]
  );
  return (rowCount ?? 0) > 0;
}

export async function markAllRead(user_id: string): Promise<number> {
  const { rowCount } = await pool.query(
    `UPDATE notifications SET is_read = true WHERE user_id = $1 AND is_read = false`,
    [user_id]
  );
  return rowCount ?? 0;
}

export async function remove(user_id: string, id: string): Promise<boolean> {
  const { rowCount } = await pool.query(
    `DELETE FROM notifications WHERE id = $1 AND user_id = $2`,
    [id, user_id]
  );
  return (rowCount ?? 0) > 0;
}

export async function removeAll(user_id: string): Promise<number> {
  const { rowCount } = await pool.query(
    `DELETE FROM notifications WHERE user_id = $1`,
    [user_id]
  );
  return rowCount ?? 0;
}