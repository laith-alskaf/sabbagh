// User model types
export enum UserRole {
  MANAGER = 'manager',
  ASSISTANT_MANAGER = 'assistant_manager',
  EMPLOYEE = 'employee',
  GUEST = 'guest',
}

export interface User {
  id: string;
  name: string;
  email: string;
  password_hash: string;
  role: UserRole;
  department?: string | null;
  phone?: string | null;
  active: boolean;
  created_at: Date;
  updated_at: Date;
}

// Vendor model types
export enum VendorStatus {
  ACTIVE = 'active',
  ARCHIVED = 'archived',
}

export interface Vendor {
  id: string;
  name: string;
  contact_person: string;
  phone: string;
  email?: string | null;
  address: string;
  notes?: string | null;
  rating?: number | null;
  status: VendorStatus;
  created_at: Date;
  updated_at: Date;
}

// Item model types
export enum ItemStatus {
  ACTIVE = 'active',
  ARCHIVED = 'archived',
}

export interface Item {
  id: string;
  name: string;
  description?: string | null;
  unit: string;
  code: string;
  status: ItemStatus;
  created_at: Date;
  updated_at: Date;
}

// Purchase Order model types
export enum RequestType {
  PURCHASE = 'purchase',
  MAINTENANCE = 'maintenance',
}

export enum PurchaseOrderStatus {
  DRAFT = 'draft',
  UNDER_ASSISTANT_REVIEW = 'under_assistant_review',
  REJECTED_BY_ASSISTANT = 'rejected_by_assistant',
  UNDER_MANAGER_REVIEW = 'under_manager_review',
  REJECTED_BY_MANAGER = 'rejected_by_manager',
  IN_PROGRESS = 'in_progress',
  COMPLETED = 'completed',
}

export enum Currency {
  SYP = 'SYP',
  USD = 'USD',
}

export interface PurchaseOrder {
  id: string;
  number: string;
  request_date: Date;
  department: string;
  request_type: RequestType;
  requester_name: string;
  status: PurchaseOrderStatus;
  notes?: string | null;
  supplier_id?: string | null;
  execution_date?: Date | null;
  attachment_url?: string | null;
  total_amount?: number | null;
  currency: Currency;
  created_by: string;
  created_at: Date;
  updated_at: Date;
}

// Purchase Order Item model types
export interface PurchaseOrderItem {
  id: string;
  purchase_order_id: string;
  item_id?: string | null;
  item_code?: string | null;
  item_name?: string | null;
  quantity: number;
  unit: string;
  received_quantity?: number | null;
  price?: number | null;
  line_total?: number | null;
  currency: Currency;
}

// Change Request model types
export enum EntityType {
  VENDOR = 'vendor',
  ITEM = 'item',
}

export enum OperationType {
  CREATE = 'create',
  UPDATE = 'update',
  DELETE = 'delete',
}

export enum ChangeRequestStatus {
  PENDING = 'pending',
  APPROVED = 'approved',
  REJECTED = 'rejected',
}

export interface ChangeRequest {
  id: string;
  entity_type: EntityType;
  operation: OperationType;
  payload: Record<string, any>;
  target_id?: string | null;
  status: ChangeRequestStatus;
  requested_by: string;
  reviewed_by?: string | null;
  reviewed_at?: Date | null;
  reason?: string | null;
  created_at: Date;
  updated_at: Date;
}

// Audit Log model types
export interface AuditLog {
  id: string;
  actor_id: string;
  action: string;
  entity_type: string;
  entity_id?: string | null;
  details: Record<string, any>;
  created_at: Date;
}