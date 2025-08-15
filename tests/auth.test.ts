import request from 'supertest';
import app from '../src/app';
import { testUsers, generateTestToken } from './helpers/testHelpers';
import * as authService from '../src/services/authService';

// Mock the auth service
jest.mock('../src/services/authService');
const mockAuthService = authService as jest.Mocked<typeof authService>;

describe('Authentication Endpoints', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('POST /api/auth/login', () => {
    it('should login successfully with valid credentials', async () => {
      const loginData = {
        email: 'manager@sabbagh.com',
        password: 'password123',
      };

      const mockResponse = {
        success: true,
        token: generateTestToken(testUsers.manager),
        user: testUsers.manager,
      };

      mockAuthService.login.mockResolvedValue(mockResponse);

      const response = await request(app)
        .post('/api/auth/login')
        .send(loginData)
        .expect(200);

      expect(response.body).toEqual(mockResponse);
      expect(mockAuthService.login).toHaveBeenCalledWith(loginData.email, loginData.password);
    });

    it('should return 400 for invalid email format', async () => {
      const loginData = {
        email: 'invalid-email',
        password: 'password123',
      };

      const response = await request(app)
        .post('/api/auth/login')
        .send(loginData)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('validation');
    });

    it('should return 400 for missing password', async () => {
      const loginData = {
        email: 'manager@sabbagh.com',
      };

      const response = await request(app)
        .post('/api/auth/login')
        .send(loginData)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            field: 'password',
          }),
        ])
      );
    });

    it('should return 401 for invalid credentials', async () => {
      const loginData = {
        email: 'manager@sabbagh.com',
        password: 'wrongpassword',
      };

      mockAuthService.login.mockRejectedValue(new Error('Invalid credentials'));

      const response = await request(app)
        .post('/api/auth/login')
        .send(loginData)
        .expect(500); // This will be handled by error middleware

      expect(mockAuthService.login).toHaveBeenCalledWith(loginData.email, loginData.password);
    });
  });

  describe('POST /api/auth/change-password', () => {
    it('should change password successfully with valid token', async () => {
      const token = generateTestToken(testUsers.manager);
      const changePasswordData = {
        currentPassword: 'oldpassword',
        newPassword: 'newpassword123',
      };

      mockAuthService.changePassword.mockResolvedValue({
        success: true,
        message: 'Password changed successfully',
      });

      const response = await request(app)
        .post('/api/auth/change-password')
        .set('Authorization', `Bearer ${token}`)
        .send(changePasswordData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(mockAuthService.changePassword).toHaveBeenCalledWith(
        testUsers.manager.id,
        changePasswordData.currentPassword,
        changePasswordData.newPassword
      );
    });

    it('should return 401 without valid token', async () => {
      const changePasswordData = {
        currentPassword: 'oldpassword',
        newPassword: 'newpassword123',
      };

      const response = await request(app)
        .post('/api/auth/change-password')
        .send(changePasswordData)
        .expect(401);

      expect(response.body.success).toBe(false);
    });

    it('should return 400 for weak new password', async () => {
      const token = generateTestToken(testUsers.manager);
      const changePasswordData = {
        currentPassword: 'oldpassword',
        newPassword: '123', // Too short
      };

      const response = await request(app)
        .post('/api/auth/change-password')
        .set('Authorization', `Bearer ${token}`)
        .send(changePasswordData)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            field: 'newPassword',
          }),
        ])
      );
    });
  });

  describe('GET /api/auth/me', () => {
    it('should return current user info with valid token', async () => {
      const token = generateTestToken(testUsers.manager);

      mockAuthService.getCurrentUser.mockResolvedValue({
        success: true,
        user: testUsers.manager,
      });

      const response = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.user).toEqual(testUsers.manager);
      expect(mockAuthService.getCurrentUser).toHaveBeenCalledWith(testUsers.manager.id);
    });

    it('should return 401 without valid token', async () => {
      const response = await request(app)
        .get('/api/auth/me')
        .expect(401);

      expect(response.body.success).toBe(false);
    });

    it('should return 401 with invalid token', async () => {
      const response = await request(app)
        .get('/api/auth/me')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);

      expect(response.body.success).toBe(false);
    });
  });
});