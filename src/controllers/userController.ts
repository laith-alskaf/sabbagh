import { Request, Response } from 'express';
import { AppError, asyncHandler } from '../middlewares/errorMiddleware';
import { t } from '../utils/i18n';
import { logInfo, logError } from '../utils/logger';
import bcrypt from 'bcrypt';

// Mock user data for now - replace with actual database operations
const mockUsers: any[] = [
  {
    id: '123e4567-e89b-12d3-a456-426614174000',
    name: 'Ahmad Al-Sabbagh',
    email: 'ahmad@sabbagh.com',
    password: '$2b$12$hashedpassword1', // Mock hashed password
    role: 'manager',
    department: 'Management',
    phone: '+963-11-1234567',
    is_active: true,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  },
  {
    id: '456e7890-e89b-12d3-a456-426614174001',
    name: 'Sara Al-Ahmad',
    email: 'sara@sabbagh.com',
    password: '$2b$12$hashedpassword2', // Mock hashed password
    role: 'assistant_manager',
    department: 'IT Department',
    phone: '+963-11-1234568',
    is_active: true,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  },
];

/**
 * Get all users with pagination and filtering
 */
export const getUsers = asyncHandler(async (req: Request, res: Response) => {
  const { page = 1, limit = 10, search, role, department, is_active, sort = 'created_at', order = 'desc' } = (req as any).validatedQuery || req.query;

  logInfo('Getting users list', {
    requestId: req.requestId,
    userId: req.user?.userId,
    filters: { search, role, department, is_active, sort, order },
    pagination: { page, limit },
  });

  // Mock filtering logic - replace with actual database query
  let filteredUsers = [...mockUsers];

  if (search) {
    filteredUsers = filteredUsers.filter(user => 
      user.name.toLowerCase().includes(search.toLowerCase()) ||
      user.email.toLowerCase().includes(search.toLowerCase())
    );
  }

  if (role) {
    filteredUsers = filteredUsers.filter(user => user.role === role);
  }

  if (department) {
    filteredUsers = filteredUsers.filter(user => user.department === department);
  }

  if (is_active !== undefined) {
    filteredUsers = filteredUsers.filter(user => user.is_active === is_active);
  }

  // Mock pagination
  const total = filteredUsers.length;
  const totalPages = Math.ceil(total / limit);
  const startIndex = (page - 1) * limit;
  const endIndex = startIndex + limit;
  const paginatedUsers = filteredUsers.slice(startIndex, endIndex);

  // Remove password from response
  const usersWithoutPassword = paginatedUsers.map(({ ...user }) => user);

  res.json({
    success: true,
    data: usersWithoutPassword,
    pagination: {
      page,
      limit,
      total,
      totalPages,
      hasNext: page < totalPages,
      hasPrev: page > 1,
    },
  });
});

/**
 * Get user by ID
 */
export const getUserById = asyncHandler(async (req: Request, res: Response) => {
  const { id } = (req as any).validatedParams || req.params;

  logInfo('Getting user by ID', {
    requestId: req.requestId,
    userId: req.user?.userId,
    targetUserId: id,
  });

  const user = mockUsers.find(u => u.id === id);

  if (!user) {
    throw new AppError(t(req, 'user.notFound', { ns: 'errors' }), 404);
  }

  // Remove password from response
  const { ...userWithoutPassword } = user;

  res.json({
    success: true,
    data: userWithoutPassword,
  });
});

/**
 * Create new user
 */
export const createUser = asyncHandler(async (req: Request, res: Response) => {
  const userData = req.body;

  logInfo('Creating new user', {
    requestId: req.requestId,
    userId: req.user?.userId,
    newUserEmail: userData.email,
    newUserRole: userData.role,
  });

  // Check if email already exists
  const existingUser = mockUsers.find(u => u.email === userData.email);
  if (existingUser) {
    throw new AppError(t(req, 'user.emailExists', { ns: 'errors' }), 409);
  }

  // Hash password
  const hashedPassword = await bcrypt.hash(userData.password, 12);

  // Create new user (mock implementation)
  const newUser = {
    id: `user-${Date.now()}`,
    ...userData,
    password: hashedPassword,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  };

  mockUsers.push(newUser);

  // Remove password from response
  const { password, ...userWithoutPassword } = newUser;

  res.status(201).json({
    success: true,
    message: t(req, 'user.created', { ns: 'success' }),
    data: userWithoutPassword,
  });
});

/**
 * Update user
 */
export const updateUser = asyncHandler(async (req: Request, res: Response) => {
  const { id } = (req as any).validatedParams || req.params;
  const updateData = req.body;

  logInfo('Updating user', {
    requestId: req.requestId,
    userId: req.user?.userId,
    targetUserId: id,
    updateFields: Object.keys(updateData),
  });

  const userIndex = mockUsers.findIndex(u => u.id === id);

  if (userIndex === -1) {
    throw new AppError(t(req, 'user.notFound', { ns: 'errors' }), 404);
  }

  // Check if email already exists (if email is being updated)
  if (updateData.email && updateData.email !== mockUsers[userIndex].email) {
    const existingUser = mockUsers.find(u => u.email === updateData.email && u.id !== id);
    if (existingUser) {
      throw new AppError(t(req, 'user.emailExists', { ns: 'errors' }), 409);
    }
  }

  // Update user (mock implementation)
  mockUsers[userIndex] = {
    ...mockUsers[userIndex],
    ...updateData,
    updated_at: new Date().toISOString(),
  };

  // Remove password from response
  const { password, ...userWithoutPassword } = mockUsers[userIndex];

  res.json({
    success: true,
    message: t(req, 'user.updated', { ns: 'success' }),
    data: userWithoutPassword,
  });
});

/**
 * Delete user (soft delete)
 */
export const deleteUser = asyncHandler(async (req: Request, res: Response) => {
  const { id } = (req as any).validatedParams || req.params;

  logInfo('Deleting user', {
    requestId: req.requestId,
    userId: req.user?.userId,
    targetUserId: id,
  });

  const userIndex = mockUsers.findIndex(u => u.id === id);

  if (userIndex === -1) {
    throw new AppError(t(req, 'user.notFound', { ns: 'errors' }), 404);
  }

  const targetUser = mockUsers[userIndex];

  // Prevent deleting yourself
  if (targetUser.id === req.user?.userId) {
    throw new AppError(t(req, 'user.cannotDeleteSelf', { ns: 'errors' }), 409);
  }

  // Prevent deleting other managers (business rule)
  if (targetUser.role === 'manager') {
    throw new AppError(t(req, 'user.cannotDeleteManager', { ns: 'errors' }), 409);
  }

  // Soft delete (mock implementation)
  mockUsers[userIndex].is_active = false;
  mockUsers[userIndex].updated_at = new Date().toISOString();

  res.json({
    success: true,
    message: t(req, 'user.deleted', { ns: 'success' }),
  });
});

/**
 * Change user password (admin only)
 */
export const adminChangePassword = asyncHandler(async (req: Request, res: Response) => {
  const { id } = (req as any).validatedParams || req.params;
  const { new_password } = req.body;

  logInfo('Admin changing user password', {
    requestId: req.requestId,
    userId: req.user?.userId,
    targetUserId: id,
  });

  const userIndex = mockUsers.findIndex(u => u.id === id);

  if (userIndex === -1) {
    throw new AppError(t(req, 'user.notFound', { ns: 'errors' }), 404);
  }

  // Hash new password
  const hashedPassword = await bcrypt.hash(new_password, 12);

  // Update password (mock implementation)
  mockUsers[userIndex] = {
    ...mockUsers[userIndex],
    password: hashedPassword,
    updated_at: new Date().toISOString(),
  };

  res.json({
    success: true,
    message: t(req, 'user.passwordChanged', { ns: 'success' }),
  });
});