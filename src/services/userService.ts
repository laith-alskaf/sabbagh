import { env } from '../config/env';
import { UserRole } from '../types/models';

// Import both real and mock services
import * as realUserService from './realUserService';
import * as mockUserService from './mockUserService';

// Export types
export type {
  CreateUserInput,
  UpdateUserInput,
  UserFilters,
  UserPagination,
  UserListResponse,
} from './mockUserService';

// Determine which service to use based on environment
const useRealService = !env.useMockData && !process.env.VERCEL && !process.env.AWS_LAMBDA_FUNCTION_NAME;

console.log(`User service mode: ${useRealService ? 'real database' : 'mock data'}`);

// Export the appropriate service functions
export const getUsers = useRealService ? realUserService.getUsers : mockUserService.getUsers;
export const getUserById = useRealService ? realUserService.getUserById : mockUserService.getUserById;
export const createUser = useRealService ? realUserService.createUser : mockUserService.createUser;
export const updateUser = useRealService ? realUserService.updateUser : mockUserService.updateUser;
export const deleteUser = useRealService ? realUserService.deleteUser : mockUserService.deleteUser;
export const changeUserPassword = useRealService ? realUserService.changeUserPassword : mockUserService.changeUserPassword;
export const getDepartments = useRealService ? realUserService.getDepartments : mockUserService.getDepartments;

// Export utility functions (same for both)
export const canManageUser = mockUserService.canManageUser;
export const canCreateUserWithRole = mockUserService.canCreateUserWithRole;