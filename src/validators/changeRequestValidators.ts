import { z } from 'zod';

// Change request creation schema
export const createChangeRequestSchema = z.object({
  operation_type: z.enum(['create', 'update', 'delete']),
  entity_type: z.enum(['vendor', 'item']),
  entity_id: z.string()
    .uuid('Invalid entity ID format')
    .optional(),
  data: z.record(z.string(), z.any())
    .refine((data) => Object.keys(data).length > 0, {
      message: 'Data cannot be empty',
    }),
}).refine((data) => {
  // For update and delete operations, entity_id is required
  if ((data.operation_type === 'update' || data.operation_type === 'delete') && !data.entity_id) {
    return false;
  }
  return true;
}, {
  message: 'Entity ID is required for update and delete operations',
  path: ['entity_id'],
});

// Change request approval schema
export const approveChangeRequestSchema = z.object({
  notes: z.string()
    .max(1000, 'Notes must not exceed 1000 characters')
    .trim()
    .optional(),
});

// Change request rejection schema
export const rejectChangeRequestSchema = z.object({
  reason: z.string()
    .min(5, 'Reason must be at least 5 characters')
    .max(1000, 'Reason must not exceed 1000 characters')
    .trim(),
  notes: z.string()
    .max(1000, 'Notes must not exceed 1000 characters')
    .trim()
    .optional(),
});

// Change request approval/rejection schema (legacy)
export const processChangeRequestSchema = z.object({
  action: z.enum(['approve', 'reject']),
  reason: z.string()
    .min(5, 'Reason must be at least 5 characters')
    .max(500, 'Reason must not exceed 500 characters')
    .trim()
    .optional(),
}).refine((data) => {
  // Reason is required for rejection
  if (data.action === 'reject' && !data.reason) {
    return false;
  }
  return true;
}, {
  message: 'Reason is required when rejecting a change request',
  path: ['reason'],
});

// Change request ID parameter schema
export const changeRequestIdSchema = z.object({
  id: z.string().uuid('Invalid change request ID format'),
});

// Change request query parameters schema
export const changeRequestQuerySchema = z.object({
  page: z.string().regex(/^\d+$/, 'Page must be a number').transform(Number).optional(),
  limit: z.string().regex(/^\d+$/, 'Limit must be a number').transform(Number).optional(),
  status: z.enum(['pending', 'approved', 'rejected']).optional(),
  operation_type: z.enum(['create', 'update', 'delete']).optional(),
  entity_type: z.enum(['vendor', 'item']).optional(),
  requested_by: z.string().uuid('Invalid user ID format').optional(),
  sort: z.enum(['created_at', 'updated_at', 'status']).optional(),
  order: z.enum(['asc', 'desc']).optional(),
});

// Export types
export type CreateChangeRequestInput = z.infer<typeof createChangeRequestSchema>;
export type ProcessChangeRequestInput = z.infer<typeof processChangeRequestSchema>;
export type ChangeRequestIdParams = z.infer<typeof changeRequestIdSchema>;
export type ChangeRequestQueryParams = z.infer<typeof changeRequestQuerySchema>;