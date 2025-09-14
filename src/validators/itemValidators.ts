import { z } from 'zod';

// Item creation schema
export const createItemSchema = z.object({
  name: z.string()
    .min(2, 'Item name must be at least 2 characters')
    .max(100, 'Item name must not exceed 100 characters')
    .trim(),
  code: z.string()
    .min(2, 'Item code must be at least 2 characters')
    .max(50, 'Item code must not exceed 50 characters')
    .regex(/^[A-Z0-9\-_]+$/, 'Item code must contain only uppercase letters, numbers, hyphens, and underscores')
    .trim(),
  description: z.string()
    .max(500, 'Description must not exceed 500 characters')
    .trim().nullable()
    .optional(),
  unit: z.string()
    .min(1, 'Unit is required')
    .max(20, 'Unit must not exceed 20 characters')
    .trim(),
  status: z.enum(['active', 'archived']).default('active'),
});

// Item update schema
export const updateItemSchema = z.object({
  name: z.string()
    .min(2, 'Item name must be at least 2 characters')
    .max(100, 'Item name must not exceed 100 characters')
    .trim()
    .optional(),
  code: z.string()
    .min(2, 'Item code must be at least 2 characters')
    .max(50, 'Item code must not exceed 50 characters')
    .regex(/^[A-Z0-9\-_]+$/, 'Item code must contain only uppercase letters, numbers, hyphens, and underscores')
    .trim()
    .optional(),
  description: z.string()
    .max(500, 'Description must not exceed 500 characters')
    .trim()
    .optional()
    .or(z.literal('')),
  unit: z.string()
    .min(1, 'Unit is required')
    .max(20, 'Unit must not exceed 20 characters')
    .trim()
    .optional(),
  status: z.enum(['active', 'archived']).optional(),
});

// Item ID parameter schema
export const itemIdSchema = z.object({
  id: z.string().uuid('Invalid item ID format'),
});

// Item query parameters schema
export const itemQuerySchema = z.object({
  page: z.string().regex(/^\d+$/, 'Page must be a number').transform(Number).optional(),
  limit: z.string().regex(/^\d+$/, 'Limit must be a number').transform(Number).optional(),
  search: z.string().max(100, 'Search term must not exceed 100 characters').optional(),
  status: z.enum(['active', 'archived']).optional(),
  sort: z.enum(['name', 'code', 'created_at', 'updated_at']).optional(),
  order: z.enum(['asc', 'desc']).optional(),
});

// Export types
export type CreateItemInput = z.infer<typeof createItemSchema>;
export type UpdateItemInput = z.infer<typeof updateItemSchema>;
export type ItemIdParams = z.infer<typeof itemIdSchema>;
export type ItemQueryParams = z.infer<typeof itemQuerySchema>;