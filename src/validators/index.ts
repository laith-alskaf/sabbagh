import { z } from 'zod';
import { Request, Response, NextFunction } from 'express';
import { AppError } from '../middlewares/errorMiddleware';
import { t } from '../utils/i18n';
import { logError } from '../utils/logger';

// Helper to parse JSON safely
function tryParseJson(input: any): any {
  if (typeof input !== 'string') return input;
  const trimmed = input.trim();
  if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) return input;
  try {
    return JSON.parse(trimmed);
  } catch {
    return input;
  }
}

// Normalize multipart "payload" into req.body before validation
function normalizeMultipartBody(req: Request): void {
  const contentType = req.headers['content-type'] || '';
  if (typeof contentType === 'string' && contentType.includes('multipart/form-data')) {
    // If client sends JSON inside `payload`, parse it
    if ((req as any).body && typeof (req as any).body.payload !== 'undefined') {
      const parsed = tryParseJson((req as any).body.payload);
      if (parsed && typeof parsed === 'object') {
        req.body = parsed;
      }
    } else {
      // Attempt to parse each string field if it looks like JSON
      if (req.body && typeof req.body === 'object') {
        const entries = Object.entries(req.body);
        const normalized: Record<string, any> = {};
        for (const [k, v] of entries) {
          normalized[k] = tryParseJson(v as any);
        }
        req.body = normalized;
      }
    }
  }
}

// Helper function to validate request data against a Zod schema
export const validate = (schema: z.ZodType<any, any>) => {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      normalizeMultipartBody(req);
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
export * from './auditValidators';
export * from './userValidators';
