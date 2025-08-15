import { z } from 'zod';

// Base report query schema
const baseReportQuerySchema = z.object({
  startDate: z.string()
    .optional()
    .refine(val => !val || /^\d{4}-\d{2}-\d{2}$/.test(val), {
      message: 'Start date must be in YYYY-MM-DD format'
    }),
  endDate: z.string()
    .optional()
    .refine(val => !val || /^\d{4}-\d{2}-\d{2}$/.test(val), {
      message: 'End date must be in YYYY-MM-DD format'
    }),
  page: z.string()
    .optional()
    .transform(val => val ? parseInt(val) : 1)
    .refine(val => val > 0, {
      message: 'Page must be a positive number'
    }),
  limit: z.string()
    .optional()
    .transform(val => val ? parseInt(val) : 10)
    .refine(val => val > 0 && val <= 100, {
      message: 'Limit must be between 1 and 100'
    }),
  locale: z.string()
    .optional()
    .refine(val => !val || ['en', 'ar'].includes(val), {
      message: 'Locale must be either "en" or "ar"'
    }),
});

// Expense report query schema
export const expenseReportQuerySchema = baseReportQuerySchema.extend({
  supplierId: z.string().optional(),
  department: z.string().optional(),
  status: z.string().optional(),
});

// Quantity report query schema
export const quantityReportQuerySchema = baseReportQuerySchema.extend({
  itemId: z.string().optional(),
  department: z.string().optional(),
});

// Purchase order list query schema
export const purchaseOrderListQuerySchema = baseReportQuerySchema.extend({
  supplierId: z.string().optional(),
  department: z.string().optional(),
  status: z.string().optional(),
});

// General report query schema (for all report types)
export const reportQuerySchema = baseReportQuerySchema.extend({
  format: z.enum(['json', 'csv', 'excel']).optional().default('json'),
  start_date: z.string().optional(),
  end_date: z.string().optional(),
  status: z.string().optional(),
  entity_type: z.string().optional(),
  department: z.string().optional(),
  supplier_id: z.string().uuid().optional(),
  item_id: z.string().uuid().optional(),
  currency: z.enum(['SYP', 'USD', 'all']).optional().default('all'),
  group_by: z.enum(['month', 'department', 'supplier', 'category', 'item']).optional(),
  include_performance: z.string().optional().transform(val => val === 'true'),
  include_usage: z.string().optional().transform(val => val === 'true'),
  sort: z.string().optional(),
  order: z.enum(['asc', 'desc']).optional().default('desc'),
});

// Types derived from schemas
export type ExpenseReportQueryParams = z.infer<typeof expenseReportQuerySchema>;
export type QuantityReportQueryParams = z.infer<typeof quantityReportQuerySchema>;
export type PurchaseOrderListQueryParams = z.infer<typeof purchaseOrderListQuerySchema>;
export type ReportQueryParams = z.infer<typeof reportQuerySchema>;