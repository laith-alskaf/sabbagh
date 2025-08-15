import { pool } from '../config/database';
import { ItemResponse } from '../types/item';

export async function findItems(params: {
  name?: string;
  code?: string;
  status?: string;
  limit?: number;
  offset?: number;
}): Promise<ItemResponse[]> {
  const values: any[] = [];
  const conditions: string[] = [];

  if (params.name) {
    values.push(`%${params.name}%`);
    conditions.push(`name ILIKE $${values.length}`);
  }
  if (params.code) {
    values.push(params.code);
    conditions.push(`code = $${values.length}`);
  }
  if (params.status) {
    values.push(params.status);
    conditions.push(`status = $${values.length}`);
  }

  const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  values.push(params.limit ?? 50);
  const limitIndex = values.length;
  values.push(params.offset ?? 0);
  const offsetIndex = values.length;

  const sql = `
    SELECT id, name, description, unit, code, status, created_at, updated_at
    FROM items
    ${whereClause}
    ORDER BY name ASC
    LIMIT $${limitIndex} OFFSET $${offsetIndex}
  `;

  const { rows } = await pool.query(sql, values);
  return rows;
}

export async function findItemById(id: string): Promise<ItemResponse | null> {
  const { rows } = await pool.query(
    `SELECT id, name, description, unit, code, status, created_at, updated_at
     FROM items WHERE id = $1`,
    [id]
  );
  return rows[0] ?? null;
}

export async function findItemByCode(code: string): Promise<ItemResponse | null> {
  const { rows } = await pool.query(
    `SELECT id, name, description, unit, code, status, created_at, updated_at
     FROM items WHERE code = $1`,
    [code]
  );
  return rows[0] ?? null;
}

export async function createItem(data: Omit<ItemResponse, 'id' | 'created_at' | 'updated_at'>): Promise<ItemResponse> {
  const sql = `
    INSERT INTO items (name, description, unit, code, status)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING id, name, description, unit, code, status, created_at, updated_at
  `;
  const values = [
    data.name,
    data.description ?? null,
    data.unit,
    data.code,
    data.status,
  ];
  const { rows } = await pool.query(sql, values);
  return rows[0];
}

export async function updateItem(
  id: string,
  data: Partial<Omit<ItemResponse, 'id' | 'created_at' | 'updated_at'>>
): Promise<ItemResponse> {
  const fields: string[] = [];
  const values: any[] = [];
  const push = (val: any) => { values.push(val); return `$${values.length}`; };

  if (data.name !== undefined) fields.push(`name = ${push(data.name)}`);
  if (data.description !== undefined) fields.push(`description = ${push(data.description)}`);
  if (data.unit !== undefined) fields.push(`unit = ${push(data.unit)}`);
  if (data.code !== undefined) fields.push(`code = ${push(data.code)}`);
  if (data.status !== undefined) fields.push(`status = ${push(data.status)}`);

  if (!fields.length) {
    const v = await findItemById(id);
    if (!v) throw new Error('Item not found');
    return v;
  }

  values.push(id);
  const idIndex = values.length;

  const sql = `
    UPDATE items
    SET ${fields.join(', ')}, updated_at = now()
    WHERE id = $${idIndex}
    RETURNING id, name, description, unit, code, status, created_at, updated_at
  `;
  const { rows } = await pool.query(sql, values);
  if (!rows[0]) throw new Error('Item not found');
  return rows[0];
}

export async function deleteItem(id: string): Promise<ItemResponse> {
  const { rows } = await pool.query(
    `DELETE FROM items WHERE id = $1
     RETURNING id, name, description, unit, code, status, created_at, updated_at`,
    [id]
  );
  if (!rows[0]) throw new Error('Item not found');
  return rows[0];
}