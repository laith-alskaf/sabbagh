import { z } from 'zod';

// Audit log query parameters validation schema
export const auditQuerySchema = z.object({
  offset: z.string().optional().transform((val) => val ? parseInt(val, 10) : 1),
  limit: z.string().optional().transform((val) => val ? parseInt(val, 10) : 20),
  action: z.string().optional(),
  entity_type: z.enum(['user', 'vendor', 'item', 'purchase_order', 'change_request']).optional(),
  entity_id: z.string().uuid().optional(),
  actor_id: z.string().uuid().optional(),
  start_date: z.string().datetime().optional(),
  end_date: z.string().datetime().optional(),
  sort: z.enum(['created_at', 'action', 'entity_type']).optional().default('created_at'),
  order: z.enum(['asc', 'desc']).optional().default('desc'),
}).refine((data) => {
  if (data.offset && data.offset < 1) return false;
  if (data.limit && (data.limit < 1 || data.limit > 100)) return false;
  if (data.start_date && data.end_date) {
    return new Date(data.start_date) <= new Date(data.end_date);
  }
  return true;
}, {
  message: "Invalid query parameters",
});

export type AuditQueryParams = z.infer<typeof auditQuerySchema>;