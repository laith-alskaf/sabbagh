import { Request, Response, NextFunction } from 'express';
import { env } from '../config/env';

export class AppError extends Error {
  statusCode: number;
  status: string;
  isOperational: boolean;

  constructor(message: string, statusCode: number) {
    super(message);
    this.statusCode = statusCode;
    this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

export const errorHandler = (
  err: Error | AppError,
  _req: Request,
  res: Response,
  _next: NextFunction,
) => {
  const error = err as AppError;
  error.statusCode = error.statusCode || 500;
  error.status = error.status || 'error';

  if (env.isDevelopment) {
    return res.status(error.statusCode).json({
      status: error.status,
      message: error.message,
      stack: error.stack,
      error: error,
    });
  }

  // For production, send less detailed error
  if (error.isOperational) {
    return res.status(error.statusCode).json({
      status: error.status,
      message: error.message,
    });
  }

  // Programming or unknown errors: don't leak error details
  console.error('ERROR 💥', error);
  return res.status(500).json({
    status: 'error',
    message: 'Something went wrong',
  });
};