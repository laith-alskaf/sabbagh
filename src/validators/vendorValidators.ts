import { z } from 'zod';

// Vendor creation schema
export const createVendorSchema = z.object({
  name: z.string()
    .min(2, 'Vendor name must be at least 2 characters')
    .max(100, 'Vendor name must not exceed 100 characters')
    .trim(),
  contact_person: z.string()
    .min(2, 'Contact person name must be at least 2 characters')
    .max(100, 'Contact person name must not exceed 100 characters')
    .trim(),
  phone: z.string()
    .min(8, 'Phone number must be at least 8 characters')
    .max(20, 'Phone number must not exceed 20 characters')
    .regex(/^[\d\s\-\+\(\)]+$/, 'Invalid phone number format'),
  email: z.string()
    .trim()
    .email('Invalid email format')
    .max(100, 'Email must not exceed 100 characters')
    .optional()
    .or(z.literal('')),
  address: z.string()
    .min(5, 'Address must be at least 5 characters')
    .max(500, 'Address must not exceed 500 characters')
    .trim(),
  status: z.enum(['active', 'archived']).default('active'),
});

// Vendor update schema (all fields optional except those that shouldn't be empty)
export const updateVendorSchema = z.object({
  name: z.string()
    .min(2, 'Vendor name must be at least 2 characters')
    .max(100, 'Vendor name must not exceed 100 characters')
    .trim()
    .optional(),
  contact_person: z.string()
    .min(2, 'Contact person name must be at least 2 characters')
    .max(100, 'Contact person name must not exceed 100 characters')
    .trim()
    .optional(),
  phone: z.string()
    .min(8, 'Phone number must be at least 8 characters')
    .max(20, 'Phone number must not exceed 20 characters')
    .regex(/^[\d\s\-\+\(\)]+$/, 'Invalid phone number format')
    .optional(),
  email: z.string()
    .email('Invalid email format')
    .max(100, 'Email must not exceed 100 characters')
    .optional()
    .or(z.literal('')),
  address: z.string()
    .min(5, 'Address must be at least 5 characters')
    .max(500, 'Address must not exceed 500 characters')
    .trim()
    .optional(),
  status: z.enum(['active', 'archived']).optional(),
});

// Vendor ID parameter schema
export const vendorIdSchema = z.object({
  id: z.string().uuid('Invalid vendor ID format'),
});

// Vendor query parameters schema
export const vendorQuerySchema = z.object({
  page: z.string().regex(/^\d+$/, 'Page must be a number').transform(Number).optional(),
  limit: z.string().regex(/^\d+$/, 'Limit must be a number').transform(Number).optional(),
  search: z.string().max(100, 'Search term must not exceed 100 characters').optional(),
  status: z.enum(['active', 'archived']).optional(),
  sort: z.enum(['name', 'created_at', 'updated_at']).optional(),
  order: z.enum(['asc', 'desc']).optional(),
});

// Export types
export type CreateVendorInput = z.infer<typeof createVendorSchema>;
export type UpdateVendorInput = z.infer<typeof updateVendorSchema>;
export type VendorIdParams = z.infer<typeof vendorIdSchema>;
export type VendorQueryParams = z.infer<typeof vendorQuerySchema>;