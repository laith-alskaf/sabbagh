import { pool } from '../config/database';
import { PurchaseOrderResponse, PurchaseOrderItemResponse } from '../types/purchaseOrder';
import { PurchaseOrderStatus, UserRole } from '../types/models';

export async function countForMonth(year: number, month: number): Promise<number> {
  const start = new Date(year, month, 1);
  const end = new Date(year, month + 1, 1);
  const { rows } = await pool.query(
    'SELECT COUNT(*)::int AS c FROM purchase_orders WHERE created_at >= $1 AND created_at < $2',
    [start, end]
  );
  return rows[0]?.c ?? 0;
}

export async function list(params: {
  userId?: string;
  employeeOnly?: boolean;
  role?: UserRole | null;
  status?: PurchaseOrderStatus;
  supplier_id?: string;
  department?: string;
  start_date?: Date;
  end_date?: Date;
  limit?: number;
  offset?: number;
}): Promise<PurchaseOrderResponse[]> {
  const conds: string[] = [];
  const vals: any[] = [];
  if (params.employeeOnly && params.userId) { vals.push(params.userId); conds.push(`po.created_by = $${vals.length}`); }
  if (params.role != null) { vals.push(params.role); conds.push(`po.role = $${vals.length}`); }
  if (params.status) { vals.push(params.status); conds.push(`po.status = $${vals.length}`); }
  if (params.supplier_id) { vals.push(params.supplier_id); conds.push(`po.supplier_id = $${vals.length}`); }
  if (params.department) { vals.push(params.department); conds.push(`po.department = $${vals.length}`); }
  if (params.start_date && params.end_date) { vals.push(params.start_date, params.end_date); conds.push(`po.request_date BETWEEN $${vals.length - 1} AND $${vals.length}`); }
  else if (params.start_date) { vals.push(params.start_date); conds.push(`po.request_date >= $${vals.length}`); }
  else if (params.end_date) { vals.push(params.end_date); conds.push(`po.request_date <= $${vals.length}`); }
  const where = conds.length ? `WHERE ${conds.join(' AND ')}` : '';
  vals.push(params.limit ?? 50); const limitIdx = vals.length;
  vals.push(params.offset ?? 0); const offsetIdx = vals.length;

  const sql = `
    SELECT po.*, u.name as creator_name, u.email as creator_email, v.name as supplier_name
    FROM purchase_orders po
    LEFT JOIN users u ON u.id = po.created_by
    LEFT JOIN vendors v ON v.id = po.supplier_id
    ${where}
    ORDER BY po.created_at DESC
    LIMIT $${limitIdx} OFFSET $${offsetIdx}
  `;
  const { rows } = await pool.query(sql, vals);
  const ids = rows.map((r: any) => r.id);
  if (!ids.length) return [];

  const { rows: itemRows } = await pool.query(
    `SELECT * FROM purchase_order_items WHERE purchase_order_id = ANY($1::uuid[])`,
    [ids]
  );
  const itemsByPo = new Map<string, PurchaseOrderItemResponse[]>();
  for (const it of itemRows) {
    const arr = itemsByPo.get(it.purchase_order_id) ?? [];
    arr.push(it);
    itemsByPo.set(it.purchase_order_id, arr);
  }
  return rows.map((po: any) => ({
    id: po.id,
    number: po.number,
    request_date: po.request_date,
    department: po.department,
    request_type: po.request_type,
    requester_name: po.requester_name,
    status: po.status,
    notes: po.notes,
    supplier_id: po.supplier_id,
    supplier_name: po.supplier_name,
    execution_date: po.execution_date,
    attachment_url: po.attachment_url,
    total_amount: po.total_amount,
    currency: po.currency,
    created_by: po.created_by,
    creator_name: po.creator_name,
    creator_email: po.creator_email,
    created_at: po.created_at,
    updated_at: po.updated_at,
    items: itemsByPo.get(po.id) ?? [],
  }));
}

export async function getById(id: string, employeeLock?: { userId: string }, client?: import('pg').PoolClient): Promise<PurchaseOrderResponse | null> {
  const queryClient = client || pool;
  const vals: any[] = [id];
  let where = 'po.id = $1';
  if (employeeLock?.userId) { vals.push(employeeLock.userId); where += ` AND po.created_by = $2`; }
  const sql = `
    SELECT po.*, u.name as creator_name, u.email as creator_email, v.name as supplier_name
    FROM purchase_orders po
    LEFT JOIN users u ON u.id = po.created_by
    LEFT JOIN vendors v ON v.id = po.supplier_id
    WHERE ${where}
  `;
  const { rows } = await queryClient.query(sql, vals);
  const po = rows[0];
  if (!po) return null;
  const { rows: itemRows } = await queryClient.query(
    `SELECT * FROM purchase_order_items WHERE purchase_order_id = $1`,
    [po.id]
  );
  return {
    id: po.id,
    number: po.number,
    request_date: po.request_date,
    department: po.department,
    request_type: po.request_type,
    requester_name: po.requester_name,
    status: po.status,
    notes: po.notes,
    supplier_id: po.supplier_id,
    supplier_name: po.supplier_name,
    execution_date: po.execution_date,
    attachment_url: po.attachment_url,
    total_amount: po.total_amount,
    currency: po.currency,
    created_by: po.created_by,
    creator_name: po.creator_name,
    creator_email: po.creator_email,
    created_at: po.created_at,
    updated_at: po.updated_at,
    items: itemRows,
  };
}

export async function insert(po: Omit<PurchaseOrderResponse, 'id' | 'creator_name' | 'creator_email' | 'created_at' | 'updated_at' | 'items'>, items: Omit<PurchaseOrderItemResponse, 'id' | 'purchase_order_id'>[], client: import('pg').PoolClient): Promise<PurchaseOrderResponse> {
  const sql = `
    INSERT INTO purchase_orders (number, request_date, department, request_type, requester_name, status, notes, supplier_id, execution_date, attachment_url, total_amount, currency, created_by)
    VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
    RETURNING *
  `;
  const { rows: poRows } = await client.query(sql, [
    po.number, po.request_date, po.department, po.request_type, po.requester_name, po.status, po.notes ?? null, po.supplier_id ?? null, po.execution_date ?? null, po.attachment_url ?? null, po.total_amount ?? null, po.currency, po.created_by,
  ]);
  const inserted = poRows[0];

  if (items.length) {
    const values: any[] = [];
    const placeholders: string[] = [];
    items.forEach((it, idx) => {
      values.push(inserted.id, it.item_id ?? null, it.item_code ?? null, it.item_name ?? null, it.quantity, it.unit, it.received_quantity ?? null, it.price ?? null, it.line_total ?? null, it.currency);
      const base = idx * 10;
      placeholders.push(`($${base + 1},$${base + 2},$${base + 3},$${base + 4},$${base + 5},$${base + 6},$${base + 7},$${base + 8},$${base + 9},$${base + 10})`);
    });
    const insertItemsSql = `
      INSERT INTO purchase_order_items (purchase_order_id, item_id, item_code, item_name, quantity, unit, received_quantity, price, line_total, currency)
      VALUES ${placeholders.join(',')}
    `;
    await client.query(insertItemsSql, values);
  }

  const full = await getById(inserted.id, undefined, client);
  if (!full) throw new Error('Failed to fetch inserted purchase order');
  return full;
}