import { z } from 'zod';

// Define user roles enum
const UserRole = z.enum(['manager', 'assistant_manager', 'employee']);

// Login schema
export const loginSchema = z.object({
  email: z.string().email({ message: 'Invalid email format' }).toLowerCase(),
  password: z.string().min(6, { message: 'Password must be at least 6 characters' }),
});

// Register schema
export const registerSchema = z.object({
  name: z.string().min(2, { message: 'Name must be at least 2 characters' }),
  email: z.string().email({ message: 'Invalid email format' }),
  password: z.string().min(6, { message: 'Password must be at least 6 characters' }),
  role: UserRole,
});

// Change password schema
export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1, { message: 'Current password is required' }),
  newPassword: z.string().min(6, { message: 'New password must be at least 6 characters' }),
});

// Types derived from schemas
export type LoginInput = z.infer<typeof loginSchema>;
export type RegisterInput = z.infer<typeof registerSchema>;
export type ChangePasswordInput = z.infer<typeof changePasswordSchema>;