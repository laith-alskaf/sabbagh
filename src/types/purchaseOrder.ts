import { Currency, PurchaseOrderStatus, RequestType } from './models';

export interface CreatePurchaseOrderRequest {
  request_date: Date;
  department: string;
  request_type: RequestType;
  requester_name: string;
  notes?: string;
  supplier_id?: string;
  execution_date?: Date;
  attachment_url?: string;
  total_amount?: number;
  currency?: Currency;
  items: CreatePurchaseOrderItemRequest[];
}

export interface CreatePurchaseOrderItemRequest {
  item_id?: string;
  item_code?: string;
  item_name: string;
  quantity: number;
  unit: string;
  received_quantity?: number;
  price?: number;
  line_total?: number;
  currency?: Currency;
}

export interface UpdatePurchaseOrderRequest {
  request_date?: Date;
  department?: string;
  request_type?: RequestType;
  requester_name?: string;
  notes?: string;
  supplier_id?: string;
  execution_date?: Date;
  attachment_url?: string;
  total_amount?: number;
  currency?: Currency;
  items?: CreatePurchaseOrderItemRequest[];
}

export interface PurchaseOrderResponse {
  id: string;
  number: string;
  request_date: Date;
  department: string;
  request_type: RequestType;
  requester_name: string;
  status: PurchaseOrderStatus;
  notes: string | null;
  supplier_id: string | null;
  supplier_name?: string | null;
  execution_date: Date | null;
  attachment_url: string[] | null;
  total_amount: number | null;
  currency: Currency;
  created_by: string;
  creator_name?: string;
  creator_email?: string;
  created_at: Date;
  updated_at: Date;
  items: PurchaseOrderItemResponse[];
}

export interface PurchaseOrderItemResponse {
  id: string;
  purchase_order_id: string;
  item_id: string | null;
  item_code: string | null;
  item_name: string | null;
  quantity: number;
  unit: string;
  received_quantity: number | null;
  price: number | null;
  line_total: number | null;
  currency: Currency;
}

export interface ApproveRejectRequest {
  reason?: string;
}