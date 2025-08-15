import { pool } from '../config/database';
import { VendorResponse } from '../types/vendor';

export async function findVendors(params: {
  name?: string;
  status?: string;
  limit?: number;
  offset?: number;
}): Promise<VendorResponse[]> {
  const values: any[] = [];
  const conditions: string[] = [];

  if (params.name) {
    values.push(`%${params.name}%`);
    conditions.push(`name ILIKE $${values.length}`);
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
    SELECT id, name, contact_person, phone, email, address, notes, rating, status, created_at, updated_at
    FROM vendors
    ${whereClause}
    ORDER BY name ASC
    LIMIT $${limitIndex} OFFSET $${offsetIndex}
  `;

  const { rows } = await pool.query(sql, values);
  return rows;
}

export async function findVendorById(id: string): Promise<VendorResponse | null> {
  const { rows } = await pool.query(
    `SELECT id, name, contact_person, phone, email, address, notes, rating, status, created_at, updated_at
     FROM vendors WHERE id = $1`,
    [id]
  );
  return rows[0] ?? null;
}

export async function createVendor(data: Omit<VendorResponse, 'id' | 'created_at' | 'updated_at'>): Promise<VendorResponse> {
  const sql = `
    INSERT INTO vendors (name, contact_person, phone, email, address, notes, rating, status)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    RETURNING id, name, contact_person, phone, email, address, notes, rating, status, created_at, updated_at
  `;
  const values = [
    data.name,
    data.contact_person,
    data.phone,
    data.email ?? null,
    data.address,
    data.notes ?? null,
    data.rating ?? null,
    data.status,
  ];
  const { rows } = await pool.query(sql, values);
  return rows[0];
}

export async function updateVendor(
  id: string,
  data: Partial<Omit<VendorResponse, 'id' | 'created_at' | 'updated_at'>>
): Promise<VendorResponse> {
  const fields: string[] = [];
  const values: any[] = [];
  const push = (val: any) => { values.push(val); return `$${values.length}`; };

  if (data.name !== undefined) fields.push(`name = ${push(data.name)}`);
  if (data.contact_person !== undefined) fields.push(`contact_person = ${push(data.contact_person)}`);
  if (data.phone !== undefined) fields.push(`phone = ${push(data.phone)}`);
  if (data.email !== undefined) fields.push(`email = ${push(data.email)}`);
  if (data.address !== undefined) fields.push(`address = ${push(data.address)}`);
  if (data.notes !== undefined) fields.push(`notes = ${push(data.notes)}`);
  if (data.rating !== undefined) fields.push(`rating = ${push(data.rating)}`);
  if (data.status !== undefined) fields.push(`status = ${push(data.status)}`);

  if (!fields.length) {
    const v = await findVendorById(id);
    if (!v) throw new Error('Vendor not found');
    return v;
  }

  values.push(id);
  const idIndex = values.length;

  const sql = `
    UPDATE vendors
    SET ${fields.join(', ')}, updated_at = now()
    WHERE id = $${idIndex}
    RETURNING id, name, contact_person, phone, email, address, notes, rating, status, created_at, updated_at
  `;
  const { rows } = await pool.query(sql, values);
  if (!rows[0]) throw new Error('Vendor not found');
  return rows[0];
}

export async function deleteVendor(id: string): Promise<VendorResponse> {
  const { rows } = await pool.query(
    `DELETE FROM vendors WHERE id = $1
     RETURNING id, name, contact_person, phone, email, address, notes, rating, status, created_at, updated_at`,
    [id]
  );
  if (!rows[0]) throw new Error('Vendor not found');
  return rows[0];
}