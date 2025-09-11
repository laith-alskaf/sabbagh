import { z } from 'zod';
import { UserRole } from '../types/models';

// User creation validation schema
export const createUserSchema = z.object({
  name: z.string()
    .min(2, 'Name must be at least 2 characters long')
    .max(100, 'Name must not exceed 100 characters'),
  email: z.string()
    .email('Invalid email format')
    .max(255, 'Email must not exceed 255 characters'),
  password: z.string()
    .min(8, 'Password must be at least 8 characters long')
    .max(128, 'Password must not exceed 128 characters')
    .regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, 'Password must contain at least one lowercase letter, one uppercase letter, and one number'),
  role: z.nativeEnum(UserRole),
  department: z.string()
    .min(2, 'Department must be at least 2 characters long')
    .max(100, 'Department must not exceed 100 characters')
    .optional(),
  phone: z.string()
    .regex(/^[+]?[0-9\s\-()]+$/, 'Invalid phone number format')
    .optional(),
  is_active: z.boolean().optional().default(true),
});

// User update validation schema
export const updateUserSchema = z.object({
  name: z.string()
    .min(2, 'Name must be at least 2 characters long')
    .max(100, 'Name must not exceed 100 characters')
    .optional(),
  email: z.string()
    .email('Invalid email format')
    .max(255, 'Email must not exceed 255 characters')
    .optional(),
  role: z.nativeEnum(UserRole).optional(),
  department: z.string()
    .min(2, 'Department must be at least 2 characters long')
    .max(100, 'Department must not exceed 100 characters')
    .optional(),
  phone: z.string()
    .regex(/^[+]?[0-9\s\-()]+$/, 'Invalid phone number format')
    .optional(),
  is_active: z.boolean().optional(),
});

// Change password validation schema (for users)
export const userChangePasswordSchema = z.object({
  current_password: z.string()
    .min(1, 'Current password is required'),
  new_password: z.string()
    .min(8, 'New password must be at least 8 characters long')
    .max(128, 'New password must not exceed 128 characters')
    .regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, 'New password must contain at least one lowercase letter, one uppercase letter, and one number'),
  confirm_password: z.string()
    .min(1, 'Password confirmation is required'),
}).refine((data) => data.new_password === data.confirm_password, {
  message: "Passwords don't match",
  path: ["confirm_password"],
});

// User query parameters validation schema
export const userQuerySchema = z.object({
  page: z.string().optional().transform((val) => val ? parseInt(val, 10) : 1),
  limit: z.string().optional().transform((val) => val ? parseInt(val, 10) : 10),
  search: z.string().optional(),
  role: z.nativeEnum(UserRole).optional(),
  department: z.string().optional(),
  is_active: z.string().optional().transform((val) => val === 'true' ? true : val === 'false' ? false : undefined),
  sort: z.enum(['name', 'email', 'role', 'department', 'created_at']).optional().default('created_at'),
  order: z.enum(['asc', 'desc']).optional().default('desc'),
}).refine((data) => {
  if (data.page && data.page < 1) return false;
  if (data.limit && (data.limit < 1 || data.limit > 100)) return false;
  return true;
}, {
  message: "Invalid query parameters",
});

// User ID parameter validation schema
export const userIdSchema = z.object({
  id: z.string().uuid('Invalid user ID format'),
});

export type CreateUserRequest = z.infer<typeof createUserSchema>;
export type UpdateUserRequest = z.infer<typeof updateUserSchema>;
export type ChangePasswordRequest = z.infer<typeof userChangePasswordSchema>;
export type UserQueryParams = z.infer<typeof userQuerySchema>;
export type UserIdParams = z.infer<typeof userIdSchema>;