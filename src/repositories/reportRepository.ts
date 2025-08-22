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

/**
 * Get vendor report data with performance metrics
 */
export async function getVendorReportData(filters: { status?: string; include_performance?: boolean }, offset?: number, limit?: number) {
  const conds: string[] = [];
  const vals: any[] = [];
  
  if (filters.status) {
    vals.push(filters.status);
    conds.push(`v.status = $${vals.length}`);
  }
  
  const where = conds.length ? `WHERE ${conds.join(' AND ')}` : '';
  
  // Count total vendors
  const countSql = `SELECT COUNT(*)::int AS c FROM vendors v ${where}`;
  const { rows: countRows } = await pool.query(countSql, vals);
  const totalCount = countRows[0].c as number;
  
  // Add pagination
  const pag = [] as string[];
  if (offset !== undefined) { vals.push(offset); pag.push(`OFFSET $${vals.length}`); }
  if (limit !== undefined) { vals.push(limit); pag.push(`LIMIT $${vals.length}`); }
  
  let sql = `
    SELECT 
      v.id,
      v.name,
      v.contact_person,
      v.phone,
      v.email,
      v.status,
      v.created_at,
      COUNT(po.id) as total_orders,
      COALESCE(SUM(CASE WHEN po.currency = 'SYP' THEN po.total_amount ELSE 0 END), 0) as total_value_syp,
      COALESCE(SUM(CASE WHEN po.currency = 'USD' THEN po.total_amount ELSE 0 END), 0) as total_value_usd,
      COALESCE(AVG(po.total_amount), 0) as average_order_value
    FROM vendors v
    LEFT JOIN purchase_orders po ON po.supplier_id = v.id AND po.status = '${PurchaseOrderStatus.COMPLETED}'
    ${where}
    GROUP BY v.id, v.name, v.contact_person, v.phone, v.email, v.status, v.created_at
    ORDER BY total_orders DESC, v.name ASC
    ${pag.join(' ')}
  `;
  
  const { rows } = await pool.query(sql, vals);
  
  // Add rating calculation if performance is included
  const vendors = rows.map((vendor: any) => ({
    ...vendor,
    rating: filters.include_performance ? calculateVendorRating(vendor) : null
  }));
  
  return { totalCount, vendors };
}

/**
 * Get item report data with usage statistics
 */
export async function getItemReportData(filters: { status?: string; include_usage?: boolean }, offset?: number, limit?: number) {
  const conds: string[] = [];
  const vals: any[] = [];
  
  if (filters.status) {
    vals.push(filters.status);
    conds.push(`i.status = $${vals.length}`);
  }
  
  const where = conds.length ? `WHERE ${conds.join(' AND ')}` : '';
  
  // Count total items
  const countSql = `SELECT COUNT(*)::int AS c FROM items i ${where}`;
  const { rows: countRows } = await pool.query(countSql, vals);
  const totalCount = countRows[0].c as number;
  
  // Add pagination
  const pag = [] as string[];
  if (offset !== undefined) { vals.push(offset); pag.push(`OFFSET $${vals.length}`); }
  if (limit !== undefined) { vals.push(limit); pag.push(`LIMIT $${vals.length}`); }
  
  let sql = `
    SELECT 
      i.id,
      i.name,
      i.code,
      i.description,
      i.unit,
      i.status,
      i.created_at,
      COUNT(poi.id) as total_ordered,
      COALESCE(SUM(CASE WHEN po.currency = 'SYP' THEN poi.price * poi.quantity ELSE 0 END), 0) as total_value_syp,
      COALESCE(SUM(CASE WHEN po.currency = 'USD' THEN poi.price * poi.quantity ELSE 0 END), 0) as total_value_usd,
      COUNT(DISTINCT po.id) as order_frequency,
      COALESCE(AVG(poi.price), 0) as average_price
    FROM items i
    LEFT JOIN purchase_order_items poi ON poi.item_id = i.id
    LEFT JOIN purchase_orders po ON po.id = poi.purchase_order_id AND po.status = '${PurchaseOrderStatus.COMPLETED}'
    ${where}
    GROUP BY i.id, i.name, i.code, i.description, i.unit, i.status, i.created_at
    ORDER BY total_ordered DESC, i.name ASC
    ${pag.join(' ')}
  `;
  
  const { rows } = await pool.query(sql, vals);
  
  return { totalCount, items: rows };
}

/**
 * Calculate vendor rating based on performance metrics
 */
function calculateVendorRating(vendor: any): number {
  // Simple rating calculation based on order count and average value
  const orderCount = parseInt(vendor.total_orders) || 0;
  const avgValue = parseFloat(vendor.average_order_value) || 0;
  
  let rating = 3.0; // Base rating
  
  // Bonus for high order count
  if (orderCount > 20) rating += 1.0;
  else if (orderCount > 10) rating += 0.5;
  
  // Bonus for high average order value
  if (avgValue > 1000) rating += 0.5;
  else if (avgValue > 500) rating += 0.3;
  
  // Cap at 5.0
  return Math.min(5.0, rating);
}