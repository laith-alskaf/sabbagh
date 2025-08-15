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

// Types derived from schemas
export type ExpenseReportQueryParams = z.infer<typeof expenseReportQuerySchema>;
export type QuantityReportQueryParams = z.infer<typeof quantityReportQuerySchema>;
export type PurchaseOrderListQueryParams = z.infer<typeof purchaseOrderListQuerySchema>;