import dotenv from 'dotenv';
import path from 'path';

// Load environment variables from .env file
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

export const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000', 10),
  isProduction: process.env.NODE_ENV === 'production',
  isDevelopment: process.env.NODE_ENV === 'development',
  isTest: process.env.NODE_ENV === 'test',
  
  database: {
    url: process.env.DATABASE_URL,
  },
  
  jwt: {
    secret: process.env.JWT_SECRET || 'fallback-secret-key-change-in-production',
    expiresIn: process.env.JWT_EXPIRES_IN || '1d',
  },
  
  defaultManager: {
    name: process.env.DEFAULT_MANAGER_NAME || 'Purchasing Manager',
    email: process.env.DEFAULT_MANAGER_EMAIL || 'manager@sabbagh.com',
    password: process.env.DEFAULT_MANAGER_PASSWORD || 'Manager@123',
  },
  
  logsDir: process.env.LOGS_DIR || path.resolve(__dirname, '../../logs'),
};