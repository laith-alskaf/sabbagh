import { z } from 'zod';
import { Request, Response, NextFunction } from 'express';
import { AppError } from '../middlewares/errorMiddleware';
import { t } from '../utils/i18n';
import { logError } from '../utils/logger';

// Helper function to validate request data against a Zod schema
export const validate = (schema: z.ZodType<any, any>) => {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = schema.parse(req.body);
      req.body = result; // Replace with validated data
      next();
    } catch (error) {
      if (error instanceof z.ZodError) {
        const errors = error.issues.map((err: any) => ({
          field: err.path.join('.'),
          message: err.message,
        }));
        
        logError(error as Error, {
          requestId: req.requestId,
          validationErrors: errors,
          body: req.body,
        });
        
        throw new AppError(
          t(req, 'validation.error', { ns: 'errors' }),
          400,
          errors
        );
      }
      next(error);
    }
  };
};

// Helper function to validate query parameters against a Zod schema
export const validateQuery = (schema: z.ZodType<any, any>) => {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = schema.parse(req.query);
      // Store validated data in a custom property instead of overwriting req.query
      (req as any).validatedQuery = result;
      next();
    } catch (error) {
      if (error instanceof z.ZodError) {
        const errors = error.issues.map((err: any) => ({
          field: err.path.join('.'),
          message: err.message,
        }));
        
        logError(error as Error, {
          requestId: req.requestId,
          validationErrors: errors,
          query: req.query,
        });
        
        throw new AppError(
          t(req, 'validation.error', { ns: 'errors' }),
          400,
          errors
        );
      }
      next(error);
    }
  };
};

// Helper function to validate URL parameters against a Zod schema
export const validateParams = (schema: z.ZodType<any, any>) => {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = schema.parse(req.params);
      // Store validated data in a custom property instead of overwriting req.params
      (req as any).validatedParams = result;
      next();
    } catch (error) {
      if (error instanceof z.ZodError) {
        const errors = error.issues.map((err: any) => ({
          field: err.path.join('.'),
          message: err.message,
        }));
        
        logError(error as Error, {
          requestId: req.requestId,
          validationErrors: errors,
          params: req.params,
        });
        
        throw new AppError(
          t(req, 'validation.error', { ns: 'errors' }),
          400,
          errors
        );
      }
      next(error);
    }
  };
};

// Re-export all validators
export * from './authValidators';
export * from './purchaseOrderValidators';
export * from './reportValidators';
export * from './vendorValidators';
export * from './itemValidators';
export * from './changeRequestValidators';