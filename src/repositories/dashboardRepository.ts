import { pool } from '../config/database';
import { PurchaseOrderStatus } from '../types/models';

export async function countByStatus(): Promise<{ status: PurchaseOrderStatus; count: number }[]> {
  const { rows } = await pool.query(`
    SELECT status, COUNT(*)::int AS count
    FROM purchase_orders
    GROUP BY status
  `);
  const all = Object.values(PurchaseOrderStatus);
  const map = new Map<string, number>();
  rows.forEach((r: any) => map.set(r.status, r.count));
  return all.map((s) => ({ status: s as PurchaseOrderStatus, count: map.get(s) ?? 0 }));
}

export async function completedOrdersSince(since: Date) {
  const { rows } = await pool.query(
    `SELECT po.*, COALESCE(json_agg(poi.*) FILTER (WHERE poi.id IS NOT NULL), '[]') AS items
     FROM purchase_orders po
     LEFT JOIN purchase_order_items poi ON poi.purchase_order_id = po.id
     WHERE po.status = $1 AND po.updated_at >= $2
     GROUP BY po.id
    `,
    [PurchaseOrderStatus.COMPLETED, since]
  );
  return rows.map((r: any) => ({ ...r, items: r.items as any[] }));
}

export async function completedOrdersWithSupplier() {
  const { rows } = await pool.query(
    `SELECT po.*, v.name as supplier_name,
            COALESCE(json_agg(poi.*) FILTER (WHERE poi.id IS NOT NULL), '[]') AS items
     FROM purchase_orders po
     LEFT JOIN vendors v ON v.id = po.supplier_id
     LEFT JOIN purchase_order_items poi ON poi.purchase_order_id = po.id
     WHERE po.status = $1 AND po.supplier_id IS NOT NULL
     GROUP BY po.id, v.name
    `,
    [PurchaseOrderStatus.COMPLETED]
  );
  return rows.map((r: any) => ({ ...r, items: r.items as any[] }));
}

export async function quickCounts() {
  const q = async (status?: PurchaseOrderStatus) => {
    if (!status) {
      const { rows } = await pool.query('SELECT COUNT(*)::int AS c FROM purchase_orders');
      return rows[0].c as number;
    }
    const { rows } = await pool.query('SELECT COUNT(*)::int AS c FROM purchase_orders WHERE status = $1', [status]);
    return rows[0].c as number;
  };
  const [totalOrders, pendingAssistant, pendingManager, inProgress, completed] = await Promise.all([
    q(),
    q(PurchaseOrderStatus.UNDER_ASSISTANT_REVIEW),
    q(PurchaseOrderStatus.UNDER_MANAGER_REVIEW),
    q(PurchaseOrderStatus.IN_PROGRESS),
    q(PurchaseOrderStatus.COMPLETED),
  ]);
  const [{ rows: suppliers }] = await Promise.all([
    pool.query('SELECT COUNT(*)::int AS c FROM vendors'),
  ]);
  const [{ rows: items }] = await Promise.all([
    pool.query('SELECT COUNT(*)::int AS c FROM items'),
  ]);
  return {
    totalOrders,
    pendingOrders: pendingAssistant + pendingManager,
    inProgressOrders: inProgress,
    completedOrders: completed,
    supplierCount: suppliers[0].c as number,
    itemCount: items[0].c as number,
  };
}

export async function recentOrders(limit: number) {
  const { rows } = await pool.query(
    `SELECT po.id, po.request_date, po.department, po.status, v.name as supplier_name, u.name as requester_name
     FROM purchase_orders po
     LEFT JOIN vendors v ON v.id = po.supplier_id
     LEFT JOIN users u ON u.id = po.created_by
     ORDER BY po.created_at DESC
     LIMIT $1`,
    [limit]
  );
  return rows.map((r: any) => ({
    id: r.id,
    requestDate: r.request_date,
    department: r.department,
    status: r.status,
    supplierName: r.supplier_name ?? null,
    requesterName: r.requester_name ?? null,
  }));
}