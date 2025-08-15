import { PoolClient } from 'pg';
import { PurchaseOrderResponse } from '../types/purchaseOrder';
import { PurchaseOrderStatus } from '../types/models';
import * as poRepo from './purchaseOrderRepository';

export async function updateStatus(
  id: string,
  status: PurchaseOrderStatus,
  extra: { notesAppend?: string } | undefined,
  client: PoolClient
): Promise<PurchaseOrderResponse> {
  const values: any[] = [status, id];
  let setNotes = '';
  if (extra?.notesAppend) {
    setNotes = ', notes = COALESCE(notes, \'\') || CASE WHEN notes IS NULL OR notes = \'\' THEN $3 ELSE E"\n\n" || $3 END';
    values.push(extra.notesAppend);
  }
  const sql = `
    UPDATE purchase_orders
    SET status = $1${setNotes}, updated_at = now()
    WHERE id = $2
    RETURNING *
  `;
  const { rows } = await client.query(sql, values);
  const po = rows[0];
  if (!po) throw new Error('Purchase order not found');
  const full = await poRepo.getById(po.id);
  if (!full) throw new Error('Failed to fetch updated purchase order');
  return full;
}

export async function updateDraft(
  id: string,
  data: Partial<Omit<PurchaseOrderResponse, 'id' | 'number' | 'created_by' | 'creator_name' | 'creator_email' | 'created_at' | 'updated_at' | 'items'>>,
  items: any[] | undefined,
  client: PoolClient
): Promise<PurchaseOrderResponse> {
  // Update core fields
  const fields: string[] = [];
  const vals: any[] = [];
  const push = (v:any)=>{ vals.push(v); return `$${vals.length}`; };
  if (data.request_date !== undefined) fields.push(`request_date = ${push(data.request_date)}`);
  if (data.department !== undefined) fields.push(`department = ${push(data.department)}`);
  if (data.request_type !== undefined) fields.push(`request_type = ${push(data.request_type)}`);
  if (data.requester_name !== undefined) fields.push(`requester_name = ${push(data.requester_name)}`);
  if (data.notes !== undefined) fields.push(`notes = ${push(data.notes)}`);
  if (data.supplier_id !== undefined) fields.push(`supplier_id = ${push(data.supplier_id)}`);
  if (data.execution_date !== undefined) fields.push(`execution_date = ${push(data.execution_date)}`);
  if (data.attachment_url !== undefined) fields.push(`attachment_url = ${push(data.attachment_url)}`);
  if (data.total_amount !== undefined) fields.push(`total_amount = ${push(data.total_amount)}`);
  if (data.currency !== undefined) fields.push(`currency = ${push(data.currency)}`);

  if (fields.length) {
    const sql = `UPDATE purchase_orders SET ${fields.join(', ')}, updated_at = now() WHERE id = $${vals.length+1} RETURNING id`;
    vals.push(id);
    await client.query(sql, vals);
  }

  if (items && items.length > 0) {
    await client.query('DELETE FROM purchase_order_items WHERE purchase_order_id = $1', [id]);
    const values: any[] = [];
    const placeholders: string[] = [];
    items.forEach((it, idx) => {
      values.push(id, it.item_id ?? null, it.item_code ?? null, it.item_name ?? null, it.quantity, it.unit, it.received_quantity ?? null, it.price ?? null, it.line_total ?? null, it.currency);
      const base = idx * 10;
      placeholders.push(`($${base+1},$${base+2},$${base+3},$${base+4},$${base+5},$${base+6},$${base+7},$${base+8},$${base+9},$${base+10})`);
    });
    const insertItemsSql = `
      INSERT INTO purchase_order_items (purchase_order_id, item_id, item_code, item_name, quantity, unit, received_quantity, price, line_total, currency)
      VALUES ${placeholders.join(',')}
    `;
    await client.query(insertItemsSql, values);
  }

  const full = await poRepo.getById(id);
  if (!full) throw new Error('Failed to fetch updated purchase order');
  return full;
}