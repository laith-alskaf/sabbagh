import bcrypt from 'bcrypt';
import { User, UserRole } from '../types/models';
import { AppError } from '../middlewares/errorMiddleware';

// Mock user data
const mockUsers: User[] = [
  {
    id: '123e4567-e89b-12d3-a456-426614174000',
    name: 'Ahmad Al-Sabbagh',
    email: 'ahmad@sabbagh.com',
    password_hash: '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.PZvO.G', // password123
    role: UserRole.MANAGER,
    department: 'Management',
    phone: '+963-11-1234567',
    active: true,
    created_at: new Date('2024-01-01T00:00:00Z'),
    updated_at: new Date('2024-01-01T00:00:00Z'),
  },
  {
    id: '456e7890-e89b-12d3-a456-426614174001',
    name: 'Sara Al-Ahmad',
    email: 'sara@sabbagh.com',
    password_hash: '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.PZvO.G', // password123
    role: UserRole.ASSISTANT_MANAGER,
    department: 'IT Department',
    phone: '+963-11-1234568',
    active: true,
    created_at: new Date('2024-01-02T00:00:00Z'),
    updated_at: new Date('2024-01-02T00:00:00Z'),
  },
  {
    id: '789e1234-e89b-12d3-a456-426614174002',
    name: 'Omar Al-Khouri',
    email: 'omar@sabbagh.com',
    password_hash: '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.PZvO.G', // password123
    role: UserRole.EMPLOYEE,
    department: 'Sales',
    phone: '+963-11-1234569',
    active: true,
    created_at: new Date('2024-01-03T00:00:00Z'),
    updated_at: new Date('2024-01-03T00:00:00Z'),
  },
  {
    id: '012e5678-e89b-12d3-a456-426614174003',
    name: 'Layla Al-Zahra',
    email: 'layla@sabbagh.com',
    password_hash: '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.PZvO.G', // password123
    role: UserRole.EMPLOYEE,
    department: 'HR',
    phone: '+963-11-1234570',
    active: false,
    created_at: new Date('2024-01-04T00:00:00Z'),
    updated_at: new Date('2024-01-04T00:00:00Z'),
  },
];

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
 * Get users with filtering and pagination (Mock implementation)
 */
export async function getUsers(
  filters: UserFilters,
  pagination: UserPagination
): Promise<UserListResponse> {
  let filteredUsers = [...mockUsers];

  // Apply filters
  if (filters.search) {
    const searchLower = filters.search.toLowerCase();
    filteredUsers = filteredUsers.filter(user => 
      user.name.toLowerCase().includes(searchLower) ||
      user.email.toLowerCase().includes(searchLower)
    );
  }

  if (filters.role) {
    filteredUsers = filteredUsers.filter(user => user.role === filters.role);
  }

  if (filters.department) {
    filteredUsers = filteredUsers.filter(user => user.department === filters.department);
  }

  if (filters.is_active !== undefined) {
    filteredUsers = filteredUsers.filter(user => user.active === filters.is_active);
  }

  // Apply sorting
  const validSortFields = ['name', 'email', 'role', 'department', 'created_at', 'updated_at'];
  const sortField = validSortFields.includes(pagination.sort) ? pagination.sort : 'created_at';
  
  filteredUsers.sort((a, b) => {
    let aValue: any = (a as any)[sortField];
    let bValue: any = (b as any)[sortField];
    
    // Handle date sorting
    if (sortField === 'created_at' || sortField === 'updated_at') {
      aValue = new Date(aValue).getTime();
      bValue = new Date(bValue).getTime();
    }
    
    // Handle string sorting
    if (typeof aValue === 'string') {
      aValue = aValue.toLowerCase();
      bValue = bValue.toLowerCase();
    }
    
    if (pagination.order === 'asc') {
      return aValue > bValue ? 1 : -1;
    } else {
      return aValue < bValue ? 1 : -1;
    }
  });

  // Apply pagination
  const total = filteredUsers.length;
  const totalPages = Math.ceil(total / pagination.limit);
  const startIndex = (pagination.page - 1) * pagination.limit;
  const endIndex = startIndex + pagination.limit;
  const paginatedUsers = filteredUsers.slice(startIndex, endIndex);

  // Remove password_hash from response
  const usersWithoutPassword = paginatedUsers.map(({ password_hash, ...user }) => user);

  return {
    users: usersWithoutPassword,
    pagination: {
      page: pagination.page,
      limit: pagination.limit,
      total,
      totalPages,
      hasNext: pagination.page < totalPages,
      hasPrev: pagination.page > 1,
    },
  };
}

/**
 * Get user by ID (Mock implementation)
 */
export async function getUserById(id: string): Promise<Omit<User, 'password_hash'> | null> {
  const user = mockUsers.find(u => u.id === id);
  
  if (!user) {
    return null;
  }

  // Remove password_hash from response
  const { password_hash, ...userWithoutPassword } = user;
  return userWithoutPassword;
}

/**
 * Create new user (Mock implementation)
 */
export async function createUser(userData: CreateUserInput): Promise<Omit<User, 'password_hash'>> {
  // Check if email already exists
  const existingUser = mockUsers.find(u => u.email === userData.email);
  if (existingUser) {
    throw new AppError('Email already exists', 409);
  }

  // Hash password
  const password_hash = await bcrypt.hash(userData.password, 12);

  // Create new user
  const newUser: User = {
    id: `user-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
    name: userData.name,
    email: userData.email,
    password_hash,
    role: userData.role,
    department: userData.department || null,
    phone: userData.phone || null,
    active: true,
    created_at: new Date(),
    updated_at: new Date(),
  };

  mockUsers.push(newUser);

  // Remove password_hash from response
  const { password_hash: _, ...userWithoutPassword } = newUser;
  return userWithoutPassword;
}

/**
 * Update user (Mock implementation)
 */
export async function updateUser(
  id: string,
  updateData: UpdateUserInput
): Promise<Omit<User, 'password_hash'> | null> {
  const userIndex = mockUsers.findIndex(u => u.id === id);
  
  if (userIndex === -1) {
    return null;
  }

  // Check if email already exists (if email is being updated)
  if (updateData.email && updateData.email !== mockUsers[userIndex].email) {
    const emailInUse = mockUsers.some(u => u.email === updateData.email && u.id !== id);
    if (emailInUse) {
      throw new AppError('Email already exists', 409);
    }
  }

  // Update user
  const updatedUser = {
    ...mockUsers[userIndex],
    ...(updateData.name && { name: updateData.name }),
    ...(updateData.email && { email: updateData.email }),
    ...(updateData.role && { role: updateData.role }),
    ...(updateData.department !== undefined && { department: updateData.department }),
    ...(updateData.phone !== undefined && { phone: updateData.phone }),
    ...(updateData.is_active !== undefined && { active: updateData.is_active }),
    updated_at: new Date(),
  };

  mockUsers[userIndex] = updatedUser;

  // Remove password_hash from response
  const { password_hash, ...userWithoutPassword } = updatedUser;
  return userWithoutPassword;
}

/**
 * Delete user (soft delete) (Mock implementation)
 */
export async function deleteUser(id: string, currentUserId: string): Promise<boolean> {
  const userIndex = mockUsers.findIndex(u => u.id === id);
  
  if (userIndex === -1) {
    return false;
  }

  const user = mockUsers[userIndex];

  // Prevent deleting yourself
  if (id === currentUserId) {
    throw new AppError('Cannot delete your own account', 409);
  }

  // Prevent deleting other managers (business rule)
  if (user.role === UserRole.MANAGER) {
    throw new AppError('Cannot delete manager accounts', 409);
  }

  // Soft delete user
  mockUsers[userIndex] = {
    ...user,
    active: false,
    updated_at: new Date(),
  };

  return true;
}

/**
 * Change user password (admin only) (Mock implementation)
 */
export async function changeUserPassword(id: string, newPassword: string): Promise<boolean> {
  const userIndex = mockUsers.findIndex(u => u.id === id);
  
  if (userIndex === -1) {
    return false;
  }

  // Hash new password
  const password_hash = await bcrypt.hash(newPassword, 12);

  // Update password
  mockUsers[userIndex] = {
    ...mockUsers[userIndex],
    password_hash,
    updated_at: new Date(),
  };

  return true;
}

/**
 * Get all departments (Mock implementation)
 */
export async function getDepartments(): Promise<string[]> {
  const departments = mockUsers
    .filter(user => user.department && user.active)
    .map(user => user.department!)
    .filter((dept, index, arr) => arr.indexOf(dept) === index)
    .sort();
  
  return departments;
}

/**
 * Find user by email (Mock implementation)
 */
export async function findUserByEmail(email: string): Promise<User | null> {
  return mockUsers.find(u => u.email === email) || null;
}

/**
 * Find user by ID (Mock implementation)
 */
export async function findUserById(id: string): Promise<User | null> {
  return mockUsers.find(u => u.id === id) || null;
}

/**
 * Validate user permissions for operations
 */
export function canManageUser(currentUserRole: UserRole, targetUserRole: UserRole): boolean {
  // Managers can manage everyone except other managers
  if (currentUserRole === UserRole.MANAGER) {
    return targetUserRole !== UserRole.MANAGER;
  }

  // Assistant managers can manage employees and guests
  if (currentUserRole === UserRole.ASSISTANT_MANAGER) {
    return targetUserRole === UserRole.EMPLOYEE || targetUserRole === UserRole.GUEST;
  }

  // Employees and guests cannot manage anyone
  return false;
}

/**
 * Validate if user can create users with specific role
 */
export function canCreateUserWithRole(currentUserRole: UserRole, targetRole: UserRole): boolean {
  // Managers can create anyone except other managers
  if (currentUserRole === UserRole.MANAGER) {
    return targetRole !== UserRole.MANAGER;
  }

  // Assistant managers can create employees and guests
  if (currentUserRole === UserRole.ASSISTANT_MANAGER) {
    return targetRole === UserRole.EMPLOYEE || targetRole === UserRole.GUEST;
  }

  // Employees and guests cannot create users
  return false;
}