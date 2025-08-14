import { Router, Request, Response } from 'express';
import { t } from '../utils/i18n';
import { AppError } from '../middlewares/errorMiddleware';

const router = Router();

// Test route to show current language
router.get('/language', (req: Request, res: Response) => {
  res.json({
    language: req.language || 'en',
    direction: req.language === 'ar' ? 'rtl' : 'ltr',
    message: t(req, 'welcome')
  });
});

// Test route to demonstrate validation error
router.post('/validate', (req: Request, res: Response) => {
  const { email, password } = req.body;
  
  if (!email) {
    return res.status(400).json({
      success: false,
      error: {
        message: t(req, 'validation.required', { field: 'Email', ns: 'common' })
      }
    });
  }
  
  if (!password) {
    return res.status(400).json({
      success: false,
      error: {
        message: t(req, 'validation.required', { field: 'Password', ns: 'common' })
      }
    });
  }
  
  if (password.length < 8) {
    return res.status(400).json({
      success: false,
      error: {
        message: t(req, 'validation.minLength', { field: 'Password', min: 8, ns: 'common' })
      }
    });
  }
  
  res.json({
    success: true,
    message: t(req, 'validation.success', { ns: 'common' }) || 'Validation successful'
  });
});

// Test route to demonstrate auth error
router.get('/auth-error', (req: Request, res: Response) => {
  res.status(401).json({
    success: false,
    error: {
      message: t(req, 'token.required', { ns: 'auth' })
    }
  });
});

// Test route to demonstrate not found error
router.get('/not-found', (_req: Request, _res: Response) => {
  throw new AppError('Resource not found', 404);
});

// Test route to demonstrate server error
router.get('/server-error', (_req: Request, _res: Response) => {
  throw new Error('Test server error');
});

export default router;