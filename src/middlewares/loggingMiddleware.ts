import { Request, Response, NextFunction } from 'express';
import { v4 as uuidv4 } from 'uuid';
import logger from '../utils/logger';

// Extend Request interface to include requestId
declare global {
  namespace Express {
    interface Request {
      requestId?: string;
      startTime?: number;
    }
  }
}

// Request ID middleware
export const requestIdMiddleware = (req: Request, res: Response, next: NextFunction) => {
  req.requestId = uuidv4();
  req.startTime = Date.now();
  
  // Add request ID to response headers
  res.setHeader('X-Request-ID', req.requestId);
  
  next();
};

// Request logging middleware
export const requestLoggingMiddleware = (req: Request, res: Response, next: NextFunction) => {
  const { method, url, ip, headers } = req;
  const userAgent = headers['user-agent'] || 'Unknown';
  const userId = (req as any).user?.id || 'Anonymous';
  
  logger.info(`[${req.requestId}] ${method} ${url} - IP: ${ip} - User: ${userId} - UserAgent: ${userAgent}`);
  
  // Log request body for non-GET requests (excluding sensitive data)
  if (method !== 'GET' && req.body) {
    const sanitizedBody = { ...req.body };
    // Remove sensitive fields
    delete sanitizedBody.password;
    delete sanitizedBody.currentPassword;
    delete sanitizedBody.newPassword;
    
    logger.debug(`[${req.requestId}] Request Body:`, JSON.stringify(sanitizedBody));
  }
  
  // Override res.json to log response
  const originalJson = res.json;
  res.json = function(body: any) {
    const duration = Date.now() - (req.startTime || 0);
    const statusCode = res.statusCode;
    
    logger.info(`[${req.requestId}] ${method} ${url} - ${statusCode} - ${duration}ms`);
    
    // Log response body for errors or debug mode
    if (statusCode >= 400 || process.env.NODE_ENV === 'development') {
      logger.debug(`[${req.requestId}] Response Body:`, JSON.stringify(body));
    }
    
    return originalJson.call(this, body);
  };
  
  next();
};

// Error logging middleware
export const errorLoggingMiddleware = (error: any, req: Request, res: Response, next: NextFunction) => {
  const { method, url, ip } = req;
  const userId = (req as any).user?.id || 'Anonymous';
  
  logger.error(`[${req.requestId}] ERROR - ${method} ${url} - IP: ${ip} - User: ${userId}`, {
    error: error.message,
    stack: error.stack,
    statusCode: error.statusCode || 500,
  });
  
  next(error);
};