import bcrypt from 'bcrypt';
import jwt, { type Secret, type SignOptions } from 'jsonwebtoken';
import { env } from '../config/env';
import * as users from '../repositories/userRepository';
import { AuthTokenPayload, LoginRequest, ChangePasswordRequest } from '../types/auth';
import { User, UserRole } from '../types/models';

/**
 * Generate a JWT token for a user
 */
export const generateToken = (user: User): string => {
  const payload: AuthTokenPayload = {
    userId: user.id,
    email: user.email,
    role: user.role as UserRole,
  };

  const secret: Secret = env.jwt.secret;
  const options: SignOptions = { expiresIn: env.jwt.expiresIn as SignOptions['expiresIn'] };

  return jwt.sign(payload, secret, options);
};

/**
 * Verify and decode a JWT token
 */
export const verifyToken = (token: string): AuthTokenPayload => {
  return jwt.verify(token, env.jwt.secret) as AuthTokenPayload;
};

/**
 * Hash a password
 */
export const hashPassword = async (password: string): Promise<string> => {
  const saltRounds = 10;
  return bcrypt.hash(password, saltRounds);
};

/**
 * Compare a password with a hash
 */
export const comparePassword = async (
  password: string,
  hashedPassword: string
): Promise<boolean> => {
  return bcrypt.compare(password, hashedPassword);
};

/**
 * Login a user
 */
export const login = async (loginData: LoginRequest) => {
  // Find user by email
  const user = await users.findByEmail(loginData.email);

  if (!user) {
    throw new Error('Invalid email or password');
  }

  // Check if user is active
  if (!user.active) {
    throw new Error('User account is inactive');
  }

  // Verify password
  const isPasswordValid = await comparePassword(loginData.password, user.password_hash);
  if (!isPasswordValid) {
    throw new Error('Invalid email or password');
  }

  // Generate token
  const token = generateToken(user as User);

  return {
    token,
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
    },
  };
};

/**
 * Change user password
 */
export const changePassword = async (userId: string, data: ChangePasswordRequest) => {
  // Find user
  const user = await users.findById(userId);

  if (!user) {
    throw new Error('User not found');
  }

  // Verify current password
  const isPasswordValid = await comparePassword(data.currentPassword, user.password_hash);
  if (!isPasswordValid) {
    throw new Error('Current password is incorrect');
  }

  // Hash new password
  const hashedPassword = await hashPassword(data.newPassword);

  // Update password
  await users.updatePassword(userId, hashedPassword);

  return { success: true, message: 'Password changed successfully' };
};

/**
 * Create or update the default manager account
 */
export const seedDefaultManager = async (): Promise<void> => {
  // Skip seeding if using mock data
  if (env.useMockData) {
    console.log('Using mock data - skipping default manager seeding');
    return;
  }

  const { name, email, password } = env.defaultManager;
  
  try {
    // Check if default manager already exists
    const existingManager = await users.findByEmail(email);

    if (existingManager) {
      console.log('Default manager account already exists');
      return;
    }

    // Hash the password
    const hashedPassword = await hashPassword(password);

    // Create the default manager
    await users.createManager({
      name,
      email,
      password_hash: hashedPassword,
      role: 'manager' as any,
      active: true,
    });

    console.log('Default manager account created successfully');
  } catch (error) {
    console.error('Failed to seed default manager account:', error);
    // Don't throw error in production to prevent app crash
    if (env.isDevelopment) {
      throw error;
    }
  }
};