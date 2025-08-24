import { pool } from '../config/database';

export interface UpsertTokenInput {
  userId: string;
  token: string;
  deviceInfo?: string | null;
}

export async function upsertToken({ userId, token, deviceInfo }: UpsertTokenInput): Promise<void> {
  await pool.query(
    `INSERT INTO user_fcm_tokens (user_id, token, device_info, last_used_at)
     VALUES ($1, $2, $3, NOW())
     ON CONFLICT (user_id, token)
     DO UPDATE SET device_info = EXCLUDED.device_info, last_used_at = NOW(), updated_at = NOW()`,
    [userId, token, deviceInfo ?? null]
  );
}

export async function removeToken(userId: string, token: string): Promise<void> {
  await pool.query('DELETE FROM user_fcm_tokens WHERE user_id = $1 AND token = $2', [userId, token]);
}

// Remove token globally (no user context) - useful when FCM reports invalid token
export async function removeTokenByValue(token: string): Promise<void> {
  await pool.query('DELETE FROM user_fcm_tokens WHERE token = $1', [token]);
}

export async function removeTokensByValues(tokens: string[]): Promise<number> {
  if (!tokens.length) return 0;
  const { rowCount } = await pool.query('DELETE FROM user_fcm_tokens WHERE token = ANY($1::text[])', [tokens]);
  return rowCount ?? 0;
}

export async function getTokensByUserIds(userIds: string[]): Promise<string[]> {
  if (!userIds.length) return [];
  const { rows } = await pool.query(
    `SELECT DISTINCT token FROM user_fcm_tokens WHERE user_id = ANY($1::uuid[])`,
    [userIds]
  );
  return rows.map((r) => r.token as string);
}

export async function getTokensByRoles(roles: string[]): Promise<string[]> {
  if (!roles.length) return [];
  const { rows } = await pool.query(
    `SELECT DISTINCT t.token
       FROM user_fcm_tokens t
       JOIN users u ON u.id = t.user_id
      WHERE u.role = ANY($1::text[]) AND u.active = true`,
    [roles]
  );
  return rows.map((r) => r.token as string);
}