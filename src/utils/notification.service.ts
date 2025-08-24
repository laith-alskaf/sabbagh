import { PurchaseOrderResponse } from '../types/purchaseOrder';

export interface NotificationPayload {
  type: string; // e.g., 'po_created', 'po_status_changed'
  title: string;
  body?: string;
  data?: Record<string, string>;
}

export interface INotificationService {
  sendToTokens(tokens: string[], payload: NotificationPayload): Promise<void>;
}

export interface PurchaseOrderNotificationData {
  id: string;
  number: string;
  status: string;
  department: string;
  requester_name: string;
  request_type: string;
  total_amount?: string;
  currency?: string;
}

export function buildPONotificationData(po: PurchaseOrderResponse): PurchaseOrderNotificationData {
  return {
    id: po.id,
    number: po.number,
    status: String(po.status),
    department: po.department,
    requester_name: po.requester_name,
    request_type: String(po.request_type),
    total_amount: po.total_amount != null ? String(po.total_amount) : undefined,
    currency: po.currency ? String(po.currency) : undefined,
  };
}