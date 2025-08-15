import { pool } from '../config/database';
import { PurchaseOrderStatus } from '../types/models';

export interface ExpenseReportFilters {
  startDate?: Date;
  endDate?: Date;
  supplierId?: string;
  department?: string;
  status?: string;
}

export interface QuantityReportFilters {
  startDate?: Date;
  endDate?: Date;
  itemId?: string;
  department?: string;
}

export interface PurchaseOrderListFilters {
  startDate?: Date;
  endDate?: Date;
  supplierId?: string;
  department?: string;
  status?: string;
}

export async function expenseOrders(filters: ExpenseReportFilters, offset?: number, limit?: number) {
  const conds: string[] = [];
  const vals: any[] = [];
  if (filters.startDate) { vals.push(filters.startDate); conds.push(`po.created_at >= $${vals.length}`); }
  if (filters.endDate) { vals.push(filters.endDate); conds.push(`po.created_at <= $${vals.length}`); }
  if (filters.supplierId) { vals.push(filters.supplierId); conds.push(`po.supplier_id = $${vals.length}`); }
  if (filters.department) { vals.push(filters.department); conds.push(`po.department = $${vals.length}`); }
  if (filters.status) { vals.push(filters.status); conds.push(`po.status = $${vals.length}`); }
  else { vals.push(PurchaseOrderStatus.COMPLETED); conds.push(`po.status = $${vals.length}`); }
  const where = conds.length ? `WHERE ${conds.join(' AND ')}` : '';

  const countSql = `SELECT COUNT(*)::int AS c FROM purchase_orders po ${where}`;
  const { rows: countRows } = await pool.query(countSql, vals);
  const totalCount = countRows[0].c as number;

  const pag = [] as string[];
  if (offset !== undefined) { vals.push(offset); pag.push(`OFFSET $${vals.length}`); }
  if (limit !== undefined) { vals.push(limit); pag.push(`LIMIT $${vals.length}`); }

  const sql = `
    SELECT po.*, v.name as supplier_name, u.name as creator_name,
           COALESCE(json_agg(poi.*) FILTER (WHERE poi.id IS NOT NULL), '[]') AS items
    FROM purchase_orders po
    LEFT JOIN vendors v ON v.id = po.supplier_id
    LEFT JOIN users u ON u.id = po.created_by
    LEFT JOIN purchase_order_items poi ON poi.purchase_order_id = po.id
    ${where}
    GROUP BY po.id, v.name, u.name
    ORDER BY po.created_at DESC
    ${pag.join(' ')}
  `;
  const { rows } = await pool.query(sql, vals);
  return { totalCount, orders: rows.map((r: any) => ({ ...r, items: r.items as any[] })) };
}

export async function quantityItems(filters: QuantityReportFilters, offset?: number, limit?: number) {
  const conds: string[] = [`po.status = $1`];
  const vals: any[] = [PurchaseOrderStatus.COMPLETED];
  if (filters.startDate) { vals.push(filters.startDate); conds.push(`po.created_at >= $${vals.length}`); }
  if (filters.endDate) { vals.push(filters.endDate); conds.push(`po.created_at <= $${vals.length}`); }
  if (filters.department) { vals.push(filters.department); conds.push(`po.department = $${vals.length}`); }
  if (filters.itemId) { vals.push(filters.itemId); conds.push(`poi.item_id = $${vals.length}`); }
  const where = `WHERE ${conds.join(' AND ')}`;

  const sql = `
    SELECT poi.item_name, poi.quantity, poi.price, po.department, po.request_date, po.updated_at, po.currency
    FROM purchase_order_items poi
    JOIN purchase_orders po ON po.id = poi.purchase_order_id
    ${where}
    ORDER BY po.created_at DESC
  `;
  const { rows } = await pool.query(sql, vals);
  // pagination on reduced array level
  const items = rows.map((r: any) => ({ ...r }));
  return items;
}

export async function purchaseOrderList(filters: PurchaseOrderListFilters, offset?: number, limit?: number) {
  const conds: string[] = [];
  const vals: any[] = [];
  if (filters.startDate) { vals.push(filters.startDate); conds.push(`po.created_at >= $${vals.length}`); }
  if (filters.endDate) { vals.push(filters.endDate); conds.push(`po.created_at <= $${vals.length}`); }
  if (filters.supplierId) { vals.push(filters.supplierId); conds.push(`po.supplier_id = $${vals.length}`); }
  if (filters.department) { vals.push(filters.department); conds.push(`po.department = $${vals.length}`); }
  if (filters.status) { vals.push(filters.status); conds.push(`po.status = $${vals.length}`); }
  const where = conds.length ? `WHERE ${conds.join(' AND ')}` : '';

  const countSql = `SELECT COUNT(*)::int AS c FROM purchase_orders po ${where}`;
  const { rows: countRows } = await pool.query(countSql, vals);
  const totalCount = countRows[0].c as number;

  const pag = [] as string[];
  if (offset !== undefined) { vals.push(offset); pag.push(`OFFSET $${vals.length}`); }
  if (limit !== undefined) { vals.push(limit); pag.push(`LIMIT $${vals.length}`); }

  const sql = `
    SELECT po.*, v.name as supplier_name, u.name as creator_name,
           COALESCE(json_agg(poi.*) FILTER (WHERE poi.id IS NOT NULL), '[]') AS items
    FROM purchase_orders po
    LEFT JOIN vendors v ON v.id = po.supplier_id
    LEFT JOIN users u ON u.id = po.created_by
    LEFT JOIN purchase_order_items poi ON poi.purchase_order_id = po.id
    ${where}
    GROUP BY po.id, v.name, u.name
    ORDER BY po.created_at DESC
    ${pag.join(' ')}
  `;
  const { rows } = await pool.query(sql, vals);
  return { totalCount, orders: rows.map((r: any) => ({ ...r, items: r.items as any[] })) };
}