import { pool } from '../config/database';
import { User, UserRole } from '../types/models';

export interface UserFilters {
  search?: string;
  role?: UserRole;
  department?: string;
  is_active?: boolean;
}

export interface UserPagination {
  page: number;
  limit: number;
  sort: string;
  order: 'asc' | 'desc';
}

export interface CreateUserData {
  name: string;
  email: string;
  password_hash: string;
  role: UserRole;
  department?: string;
  phone?: string;
  active?: boolean;
}

export interface UpdateUserData {
  name?: string;
  email?: string;
  role?: UserRole;
  department?: string;
  phone?: string;
  active?: boolean;
}

export interface UserListResult {
  users: Omit<User, 'password_hash'>[];
  total: number;
}

/**
 * Find user by email
 */
export async function findByEmail(email: string): Promise<User | null> {
  const { rows } = await pool.query('SELECT * FROM users WHERE email = $1 LIMIT 1', [email]);
  return rows[0] || null;
}

/**
 * Find user by ID
 */
export async function findById(id: string): Promise<User | null> {
  const { rows } = await pool.query('SELECT * FROM users WHERE id = $1 LIMIT 1', [id]);
  return rows[0] || null;
}

/**
 * Get users with filtering and pagination
 */
export async function findUsers(filters: UserFilters, pagination: UserPagination): Promise<UserListResult> {
  let query = `
    SELECT id, name, email, role, department, phone, active, created_at, updated_at
    FROM users
    WHERE 1=1
  `;

  const params: any[] = [];
  let paramIndex = 1;

  // Apply filters
  if (filters.search) {
    query += ` AND (name ILIKE $${paramIndex} OR email ILIKE $${paramIndex})`;
    params.push(`%${filters.search}%`);
    paramIndex++;
  }

  if (filters.role) {
    query += ` AND role = $${paramIndex}`;
    params.push(filters.role);
    paramIndex++;
  }

  if (filters.department) {
    query += ` AND department = $${paramIndex}`;
    params.push(filters.department);
    paramIndex++;
  }

  if (filters.is_active !== undefined) {
    query += ` AND active = $${paramIndex}`;
    params.push(filters.is_active);
    paramIndex++;
  }

  // Get total count
  const countQuery = query.replace(
    'SELECT id, name, email, role, department, phone, active, created_at, updated_at',
    'SELECT COUNT(*)'
  );
  const { rows: countRows } = await pool.query(countQuery, params);
  const total = parseInt(countRows[0].count);

  // Apply sorting
  const validSortFields = ['name', 'email', 'role', 'department', 'created_at', 'updated_at'];
  const sortField = validSortFields.includes(pagination.sort) ? pagination.sort : 'created_at';
  const sortOrder = pagination.order === 'asc' ? 'ASC' : 'DESC';

  query += ` ORDER BY ${sortField} ${sortOrder}`;

  // Apply pagination
  const offset = (pagination.page - 1) * pagination.limit;
  query += ` LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
  params.push(pagination.limit, offset);

  const { rows } = await pool.query(query, params);

  return {
    users: rows,
    total,
  };
}

/**
 * Create new user
 */
export async function createUser(userData: CreateUserData): Promise<User> {
  const query = `
    INSERT INTO users (name, email, password_hash, role, department, phone, active)
    VALUES ($1, $2, $3, $4, $5, $6, $7)
    RETURNING *
  `;

  const values = [
    userData.name,
    userData.email,
    userData.password_hash,
    userData.role,
    userData.department || null,
    userData.phone || null,
    userData.active !== undefined ? userData.active : true,
  ];

  const { rows } = await pool.query(query, values);
  return rows[0];
}

/**
 * Update user
 */
export async function updateUser(id: string, updateData: UpdateUserData): Promise<User | null> {
  const fields: string[] = [];
  const values: any[] = [];
  let paramIndex = 1;

  // Build dynamic update query
  if (updateData.name !== undefined) {
    fields.push(`name = $${paramIndex}`);
    values.push(updateData.name);
    paramIndex++;
  }

  if (updateData.email !== undefined) {
    fields.push(`email = $${paramIndex}`);
    values.push(updateData.email);
    paramIndex++;
  }

  if (updateData.role !== undefined) {
    fields.push(`role = $${paramIndex}`);
    values.push(updateData.role);
    paramIndex++;
  }

  if (updateData.department !== undefined) {
    fields.push(`department = $${paramIndex}`);
    values.push(updateData.department);
    paramIndex++;
  }

  if (updateData.phone !== undefined) {
    fields.push(`phone = $${paramIndex}`);
    values.push(updateData.phone);
    paramIndex++;
  }

  if (updateData.active !== undefined) {
    fields.push(`active = $${paramIndex}`);
    values.push(updateData.active);
    paramIndex++;
  }

  if (fields.length === 0) {
    // No fields to update
    return await findById(id);
  }

  // Always update the updated_at field
  fields.push(`updated_at = NOW()`);

  const query = `
    UPDATE users 
    SET ${fields.join(', ')}
    WHERE id = $${paramIndex}
    RETURNING *
  `;

  values.push(id);

  const { rows } = await pool.query(query, values);
  return rows[0] || null;
}

/**
 * Update user password
 */
export async function updatePassword(id: string, password_hash: string): Promise<void> {
  await pool.query(
    'UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2',
    [password_hash, id]
  );
}

/**
 * Soft delete user (set active to false)
 */
export async function softDeleteUser(id: string): Promise<boolean> {
  const { rowCount } = await pool.query(
    'UPDATE users SET active = false, updated_at = NOW() WHERE id = $1',
    [id]
  );
  if (rowCount == null)
    return false
  else
    return rowCount > 0

}

/**
 * Check if email exists (excluding specific user ID)
 */
export async function emailExists(email: string, excludeUserId?: string): Promise<boolean> {
  let query = 'SELECT 1 FROM users WHERE email = $1';
  const params: any[] = [email];

  if (excludeUserId) {
    query += ' AND id != $2';
    params.push(excludeUserId);
  }

  query += ' LIMIT 1';

  const { rows } = await pool.query(query, params);
  return rows.length > 0;
}

/**
 * Get user count by role
 */
export async function getUserCountByRole(role: UserRole): Promise<number> {
  const { rows } = await pool.query(
    'SELECT COUNT(*) as count FROM users WHERE role = $1 AND active = true',
    [role]
  );
  return parseInt(rows[0].count);
}

/**
 * Get all departments
 */
export async function getDepartments(): Promise<string[]> {
  const { rows } = await pool.query(
    'SELECT DISTINCT department FROM users WHERE department IS NOT NULL AND active = true ORDER BY department'
  );
  return rows.map(row  => row.department);
}

/**
 * Create manager (legacy function for compatibility)
 */
export async function createManager(user: Pick<User, 'name' | 'email' | 'password_hash' | 'role' | 'active'>): Promise<void> {
  await createUser({
    name: user.name,
    email: user.email,
    password_hash: user.password_hash,
    role: user.role,
    active: user.active,
  });
}