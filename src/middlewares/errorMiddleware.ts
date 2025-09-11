import { Request, Response, NextFunction } from 'express';
import { t } from '../utils/i18n';
import { env } from '../config/env';

// Custom error class with status code
export class AppError extends Error {
  statusCode: number;
  isOperational: boolean;
  errors?: Array<{ field: string; message: string }>;

  constructor(message: string, statusCode: number, errors?: Array<{ field: string; message: string }>) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    this.errors = errors;

    Error.captureStackTrace(this, this.constructor);
  }
}

// Not found error handler
export const notFoundHandler = (req: Request, res: Response, next: NextFunction) => {
  const message = t(req, 'api.notFound', { ns: 'errors' });
  const error = new AppError(message, 404);
  next(error);
};

// Global error handler
export const errorHandler = (
  err: Error | AppError,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  // Default values
  let statusCode = 500;
  let message = t(req, 'general.unexpected', { ns: 'errors' });
  let stack: string | undefined = undefined;

  // If it's our custom error, use its status code and message
  if ('statusCode' in err) {
    statusCode = err.statusCode;
    message = err.message;
  } else {
    // Handle specific error types
    if (err.name === 'ValidationError') {
      statusCode = 400;
      message = t(req, 'validation.failed', { ns: 'errors' });
    } else if (err.name === 'JsonWebTokenError') {
      statusCode = 401;
      message = t(req, 'token.invalid', { ns: 'auth' });
    } else if (err.name === 'TokenExpiredError') {
      statusCode = 401;
      message = t(req, 'token.expired', { ns: 'auth' });
    }
  }

  // Include stack trace in development mode
  if (env.isDevelopment) {
    stack = err.stack;
  }

  // Send response
  const response: any = {
    success: false,
    message,
    ...(stack && { stack }),
  };

  // Add validation errors if they exist
  if ('errors' in err && err.errors) {
    response.errors = err.errors;
  }

  res.status(statusCode).json(response);
};

// Async handler to catch errors in async routes
export const asyncHandler = (fn: Function) => {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};