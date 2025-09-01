import { z } from 'zod';

// Purchase order item schema
const purchaseOrderItemSchema = z.object({
  id: z.string().optional(),
  item_id: z.string().nullable().optional(),
  item_code: z.string().nullable().optional(),
  item_name: z.string(({ message: 'Item Name is required' })),
  quantity: z.number().positive({ message: 'Quantity must be a positive number' }),
  unit: z.string().min(1, { message: 'Unit is required' }),
  received_quantity: z.number().nullable().optional(),
  price: z.number().nonnegative({ message: 'Price must be a non-negative number' }).nullable().optional(),
  line_total: z.number().nonnegative().nullable().optional(),
  currency: z.enum(['SYP', 'USD'], { message: 'Currency must be SYP or USD' }).optional(),
});

// Create purchase order schema
export const createPurchaseOrderSchema = z.object({
  department: z.string().min(1, { message: 'Department is required' }),
  request_date: z.string().or(z.date()),
  request_type: z.enum(['purchase', 'maintenance'], { message: 'Request type must be purchase or maintenance' }),
  requester_name: z.string().min(1, { message: 'Requester name is required' }),
  execution_date: z.string().or(z.date()).nullable().optional(),
  notes: z.string().nullable().optional(),
  supplier_id: z.string().nullable().optional(),
  total_amount: z.number().nonnegative().nullable().optional(),
  currency: z.enum(['SYP', 'USD'], { message: 'Currency must be SYP or USD' }).optional(),
  items: z.array(purchaseOrderItemSchema).min(1, { message: 'At least one item is required' }),
});

// Update purchase order schema
export const updatePurchaseOrderSchema = z.object({
  department: z.string().min(1, { message: 'Department is required' }).optional(),
  request_date: z.string().or(z.date()).optional(),
  request_type: z.enum(['purchase', 'maintenance'], { message: 'Request type must be purchase or maintenance' }).optional(),
  requester_name: z.string().min(1, { message: 'Requester name is required' }).optional(),
  execution_date: z.string().or(z.date()).nullable().optional(),
  notes: z.string().nullable().optional(),
  supplier_id: z.string().nullable().optional(),
  attachment_url: z.string().nullable().optional(),
  total_amount: z.number().nonnegative().nullable().optional(),
  currency: z.enum(['SYP', 'USD'], { message: 'Currency must be SYP or USD' }).optional(),
  items: z.array(purchaseOrderItemSchema).min(1, { message: 'At least one item is required' }).optional(),
});

// Submit purchase order schema
export const submitPurchaseOrderSchema = z.object({
  notes: z.string().optional(),
});

// Approve purchase order schema
export const approvePurchaseOrderSchema = z.object({
  notes: z.string().optional(),
});

// Reject purchase order schema
export const rejectPurchaseOrderSchema = z.object({
  reason: z.string().min(1, { message: 'Rejection reason is required' }),
});

// Complete purchase order schema
export const completePurchaseOrderSchema = z.object({
  notes: z.string().optional(),
});

// Manager/Assistant routing schema (to finance, gm, or procurement)
export const managerRouteSchema = z.object({
  next: z.enum(['finance', 'gm', 'procurement'], { message: 'Invalid next route' }),
  notes: z.string().optional(),
});

// Procurement update schema: only execution-related fields
const procurementItemUpdateSchema = z.object({
  id: z.string().optional(), // item id in the order items table
  received_quantity: z.number().nullable().optional(),
  price: z.number().nonnegative().nullable().optional(),
  line_total: z.number().nonnegative().nullable().optional(),
});

export const procurementUpdateSchema = z.object({
  attachment_url: z.string().nullable().optional(),
  items: z.array(procurementItemUpdateSchema).min(1, { message: 'At least one item is required' }),
});

// Purchase order ID parameter schema
export const purchaseOrderIdSchema = z.object({
  id: z.string().uuid({ message: 'Invalid purchase order ID format' }),
});

// Purchase order query parameters schema
export const purchaseOrderQuerySchema = z.object({
  status: z.string().optional(),
  department: z.string().optional(),
  startDate: z.string().optional(),
  endDate: z.string().optional(),
  limit: z.string().optional().transform(val => val ? parseInt(val) : 10),
  offset: z.string().optional().transform(val => val ? parseInt(val) : 0),
});

// Types derived from schemas
export type CreatePurchaseOrderInput = z.infer<typeof createPurchaseOrderSchema>;
export type UpdatePurchaseOrderInput = z.infer<typeof updatePurchaseOrderSchema>;
export type SubmitPurchaseOrderInput = z.infer<typeof submitPurchaseOrderSchema>;
export type ApprovePurchaseOrderInput = z.infer<typeof approvePurchaseOrderSchema>;
export type RejectPurchaseOrderInput = z.infer<typeof rejectPurchaseOrderSchema>;
export type CompletePurchaseOrderInput = z.infer<typeof completePurchaseOrderSchema>;
export type PurchaseOrderIdParam = z.infer<typeof purchaseOrderIdSchema>;
export type PurchaseOrderQueryParams = z.infer<typeof purchaseOrderQuerySchema>;