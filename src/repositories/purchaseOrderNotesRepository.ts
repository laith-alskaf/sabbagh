import { pool } from '../config/database';
import { PurchaseOrderNoteResponse } from '../types/notes';

export async function insertNote(purchaseOrderId: string, userId: string, note: string): Promise<PurchaseOrderNoteResponse> {
  const sql = `
    with ins as (
      insert into purchase_order_notes (purchase_order_id, user_id, note)
      values ($1, $2, $3)
      returning id, purchase_order_id, user_id, note, created_at
    )
    select i.id, i.purchase_order_id, i.user_id, i.note, i.created_at, u.name as user_name
    from ins i
    left join users u on u.id = i.user_id
  `;
  const params = [purchaseOrderId, userId, note];
  const { rows } = await pool.query(sql, params);
  const r = rows[0];
  return {
    id: Number(r.id),
    purchase_order_id: r.purchase_order_id,
    user_id: r.user_id,
    user_name: r.user_name ?? undefined,
    note: r.note,
    created_at: r.created_at,
  };
}

export async function listNotes(purchaseOrderId: string): Promise<PurchaseOrderNoteResponse[]> {
  const sql = `
    select n.id, n.purchase_order_id, n.user_id, u.name as user_name, n.note, n.created_at
    from purchase_order_notes n
    left join users u on u.id = n.user_id
    where n.purchase_order_id = $1
    order by n.created_at asc
  `;
  const { rows } = await pool.query(sql, [purchaseOrderId]);
  return rows.map(r => ({
    id: Number(r.id),
    purchase_order_id: r.purchase_order_id,
    user_id: r.user_id,
    user_name: r.user_name ?? undefined,
    note: r.note,
    created_at: r.created_at,
  }));
}