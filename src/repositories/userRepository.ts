import { pool } from '../config/database';
import { User } from '../types/models';

export async function findByEmail(email: string): Promise<User | null> {
  const { rows } = await pool.query('SELECT * FROM users WHERE email = $1 LIMIT 1', [email]);
  return rows[0] || null;
}

export async function findById(id: string): Promise<User | null> {
  const { rows } = await pool.query('SELECT * FROM users WHERE id = $1 LIMIT 1', [id]);
  return rows[0] || null;
}

export async function updatePassword(id: string, password_hash: string): Promise<void> {
  await pool.query('UPDATE users SET password_hash = $1, updated_at = now() WHERE id = $2', [password_hash, id]);
}

export async function createManager(user: Pick<User, 'name'|'email'|'password_hash'|'role'|'active'>): Promise<void> {
  await pool.query(
    'INSERT INTO users (name, email, password_hash, role, active) VALUES ($1,$2,$3,$4,$5)',
    [user.name, user.email, user.password_hash, user.role, user.active]
  );
}