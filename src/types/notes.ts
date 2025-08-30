import { UserRole } from './models';

export interface CreatePurchaseOrderNoteRequest {
  note: string;
}

export interface PurchaseOrderNoteResponse {
  id: number;
  purchase_order_id: string;
  user_id: string;
  user_name?: string;
  note: string;
  created_at: Date;
}