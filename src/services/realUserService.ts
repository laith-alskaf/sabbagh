import bcrypt from 'bcrypt';
import { User, UserRole } from '../types/models';
import * as userRepository from '../repositories/userRepository';
import { AppError } from '../middlewares/errorMiddleware';

export interface CreateUserInput {
  name: string;
  email: string;
  password: string;
  role: UserRole;
  department?: string;
  phone?: string;
}

export interface UpdateUserInput {
  name?: string;
  email?: string;
  role?: UserRole;
  department?: string;
  phone?: string;
  is_active?: boolean;
}

export interface UserFilters {
  search?: string;
  role?: UserRole;
  department?: string;
  is_active?: boolean;
}

export interface UserPagination {
  page: number;
  limit: number;
  sort: string;
  order: 'asc' | 'desc';
}

export interface UserListResponse {
  users: Omit<User, 'password_hash'>[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
    hasNext: boolean;
    hasPrev: boolean;
  };
}

/**
 * Get users with filtering and pagination
 */
export async function getUsers(
  filters: UserFilters,
  pagination: UserPagination
): Promise<UserListResponse> {
  const repositoryFilters = {
    search: filters.search,
    role: filters.role,
    department: filters.department,
    is_active: filters.is_active,
  };

  const repositoryPagination = {
    page: pagination.page,
    limit: pagination.limit,
    sort: pagination.sort,
    order: pagination.order,
  };

  const result = await userRepository.findUsers(repositoryFilters, repositoryPagination);

  const totalPages = Math.ceil(result.total / pagination.limit);

  return {
    users: result.users,
    pagination: {
      page: pagination.page,
      limit: pagination.limit,
      total: result.total,
      totalPages,
      hasNext: pagination.page < totalPages,
      hasPrev: pagination.page > 1,
    },
  };
}

/**
 * Get user by ID
 */
export async function getUserById(id: string): Promise<Omit<User, 'password_hash'> | null> {
  const user = await userRepository.findById(id);
  
  if (!user) {
    return null;
  }

  // Remove password_hash from response
  const { password_hash, ...userWithoutPassword } = user;
  return userWithoutPassword;
}

/**
 * Create new user
 */
export async function createUser(userData: CreateUserInput): Promise<Omit<User, 'password_hash'>> {
  // Check if email already exists
  const existingUser = await userRepository.findByEmail(userData.email);
  if (existingUser) {
    throw new AppError('Email already exists', 409);
  }

  // Hash password
  const password_hash = await bcrypt.hash(userData.password, 12);

  // Create user
  const newUser = await userRepository.createUser({
    name: userData.name,
    email: userData.email,
    password_hash,
    role: userData.role,
    department: userData.department,
    phone: userData.phone,
  });

  // Remove password_hash from response
  const { password_hash: _, ...userWithoutPassword } = newUser;
  return userWithoutPassword;
}

/**
 * Update user
 */
export async function updateUser(
  id: string,
  updateData: UpdateUserInput
): Promise<Omit<User, 'password_hash'> | null> {
  // Check if user exists
  const existingUser = await userRepository.findById(id);
  if (!existingUser) {
    return null;
  }

  // Check if email already exists (if email is being updated)
  if (updateData.email && updateData.email !== existingUser.email) {
    const emailInUse = await userRepository.emailExists(updateData.email, id);
    if (emailInUse) {
      throw new AppError('Email already exists', 409);
    }
  }

  // Convert is_active to active for repository
  const repositoryUpdateData = {
    name: updateData.name,
    email: updateData.email,
    role: updateData.role,
    department: updateData.department,
    phone: updateData.phone,
    active: updateData.is_active,
  };

  // Update user
  const updatedUser = await userRepository.updateUser(id, repositoryUpdateData);
  
  if (!updatedUser) {
    return null;
  }

  // Remove password_hash from response
  const { password_hash, ...userWithoutPassword } = updatedUser;
  return userWithoutPassword;
}

/**
 * Delete user (soft delete)
 */
export async function deleteUser(id: string, currentUserId: string): Promise<boolean> {
  // Check if user exists
  const user = await userRepository.findById(id);
  if (!user) {
    return false;
  }

  // Prevent deleting yourself
  if (id === currentUserId) {
    throw new AppError('Cannot delete your own account', 409);
  }

  // Prevent deleting other managers (business rule)
  if (user.role === UserRole.MANAGER) {
    throw new AppError('Cannot delete manager accounts', 409);
  }

  // Soft delete user
  return await userRepository.softDeleteUser(id);
}

/**
 * Change user password (admin only)
 */
export async function changeUserPassword(id: string, newPassword: string): Promise<boolean> {
  // Check if user exists
  const user = await userRepository.findById(id);
  if (!user) {
    return false;
  }

  // Hash new password
  const password_hash = await bcrypt.hash(newPassword, 12);

  // Update password
  await userRepository.updatePassword(id, password_hash);
  return true;
}

/**
 * Get all departments
 */
export async function getDepartments(): Promise<string[]> {
  return await userRepository.getDepartments();
}