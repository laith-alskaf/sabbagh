import { Router, Request, Response } from 'express';
import { t } from '../utils/i18n';
import { AppError } from '../middlewares/errorMiddleware';
import fs from 'fs';
import path from 'path';

const router = Router();

/**
 * @swagger
 * tags:
 *   name: Internationalization
 *   description: Language and localization endpoints
 */

/**
 * @swagger
 * /i18n/languages:
 *   get:
 *     summary: Get supported languages
 *     tags: [Internationalization]
 *     responses:
 *       200:
 *         description: List of supported languages
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       code:
 *                         type: string
 *                         example: "en"
 *                       name:
 *                         type: string
 *                         example: "English"
 *                       nativeName:
 *                         type: string
 *                         example: "English"
 *                       direction:
 *                         type: string
 *                         enum: [ltr, rtl]
 *                         example: "ltr"
 *                       flag:
 *                         type: string
 *                         example: "🇺🇸"
 *                   example:
 *                     - code: "en"
 *                       name: "English"
 *                       nativeName: "English"
 *                       direction: "ltr"
 *                       flag: "🇺🇸"
 *                     - code: "ar"
 *                       name: "Arabic"
 *                       nativeName: "العربية"
 *                       direction: "rtl"
 *                       flag: "🇸🇦"
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/languages', (req: Request, res: Response) => {
  const supportedLanguages = [
    {
      code: 'en',
      name: 'English',
      nativeName: 'English',
      direction: 'ltr',
      flag: '🇺🇸'
    },
    {
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      direction: 'rtl',
      flag: '🇸🇦'
    }
  ];

  res.json({
    success: true,
    data: supportedLanguages
  });
});

/**
 * @swagger
 * /i18n/translations/{language}:
 *   get:
 *     summary: Get translations for a specific language
 *     tags: [Internationalization]
 *     parameters:
 *       - in: path
 *         name: language
 *         required: true
 *         schema:
 *           type: string
 *           enum: [en, ar]
 *         description: Language code
 *         example: "en"
 *       - in: query
 *         name: namespace
 *         schema:
 *           type: string
 *           enum: [common, auth, errors, validation]
 *         description: Translation namespace (optional, returns all if not specified)
 *         example: "common"
 *     responses:
 *       200:
 *         description: Translation data for the specified language
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 language:
 *                   type: string
 *                   example: "en"
 *                 direction:
 *                   type: string
 *                   enum: [ltr, rtl]
 *                   example: "ltr"
 *                 data:
 *                   type: object
 *                   additionalProperties: true
 *                   example:
 *                     common:
 *                       welcome: "Welcome to Sabbagh Purchasing System"
 *                       save: "Save"
 *                       cancel: "Cancel"
 *                       delete: "Delete"
 *                     auth:
 *                       login: "Login"
 *                       logout: "Logout"
 *                       email: "Email"
 *                       password: "Password"
 *       400:
 *         description: Invalid language code
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: "Unsupported language code"
 *       404:
 *         description: Translation file not found
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: "Translation file not found"
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/translations/:language', (req: Request, res: Response) => {
  const { language } = req.params;
  const { namespace } = req.query;

  // Validate language code
  const supportedLanguages = ['en', 'ar'];
  if (!supportedLanguages.includes(language)) {
    return res.status(400).json({
      success: false,
      message: 'Unsupported language code'
    });
  }

  try {
    const localesPath = path.join(__dirname, '..', 'locales', language);
    
    if (!fs.existsSync(localesPath)) {
      return res.status(404).json({
        success: false,
        message: 'Translation file not found'
      });
    }

    let translations: any = {};

    if (namespace) {
      // Load specific namespace
      const namespacePath = path.join(localesPath, `${namespace}.json`);
      if (fs.existsSync(namespacePath)) {
        const namespaceData = JSON.parse(fs.readFileSync(namespacePath, 'utf8'));
        translations[namespace as string] = namespaceData;
      }
    } else {
      // Load all namespaces
      const files = fs.readdirSync(localesPath);
      for (const file of files) {
        if (file.endsWith('.json')) {
          const namespaceName = file.replace('.json', '');
          const filePath = path.join(localesPath, file);
          const fileData = JSON.parse(fs.readFileSync(filePath, 'utf8'));
          translations[namespaceName] = fileData;
        }
      }
    }

    res.json({
      success: true,
      language,
      direction: language === 'ar' ? 'rtl' : 'ltr',
      data: translations
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error loading translations'
    });
  }
});

/**
 * @swagger
 * /i18n/current:
 *   get:
 *     summary: Get current language information
 *     tags: [Internationalization]
 *     parameters:
 *       - in: header
 *         name: Accept-Language
 *         schema:
 *           type: string
 *         description: Preferred language (en, ar)
 *         example: "ar"
 *     responses:
 *       200:
 *         description: Current language information
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: object
 *                   properties:
 *                     language:
 *                       type: string
 *                       example: "en"
 *                     direction:
 *                       type: string
 *                       enum: [ltr, rtl]
 *                       example: "ltr"
 *                     message:
 *                       type: string
 *                       example: "Welcome to Sabbagh Purchasing System"
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/current', (req: Request, res: Response) => {
  const currentLanguage = req.language || 'en';
  res.json({
    success: true,
    data: {
      language: currentLanguage,
      direction: currentLanguage === 'ar' ? 'rtl' : 'ltr',
      message: t(req, 'welcome')
    }
  });
});

/**
 * @swagger
 * /i18n/test/validation:
 *   post:
 *     summary: Test localized validation messages
 *     tags: [Internationalization]
 *     parameters:
 *       - in: header
 *         name: Accept-Language
 *         schema:
 *           type: string
 *         description: Preferred language (en, ar)
 *         example: "ar"
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 example: "test@example.com"
 *               password:
 *                 type: string
 *                 minLength: 8
 *                 example: "password123"
 *     responses:
 *       200:
 *         description: Validation successful
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: "Validation successful"
 *       400:
 *         description: Validation failed with localized error messages
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 error:
 *                   type: object
 *                   properties:
 *                     message:
 *                       type: string
 *                       example: "Email is required"
 */
router.post('/test/validation', (req: Request, res: Response) => {
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

// Legacy routes for backward compatibility
router.get('/language', (req: Request, res: Response) => {
  res.redirect('/api/i18n/current');
});

router.post('/validate', (req: Request, res: Response) => {
  res.redirect(307, '/api/i18n/test/validation');
});

router.get('/auth-error', (req: Request, res: Response) => {
  res.status(401).json({
    success: false,
    error: {
      message: t(req, 'token.required', { ns: 'auth' })
    }
  });
});

router.get('/not-found', (_req: Request, _res: Response) => {
  throw new AppError('Resource not found', 404);
});

router.get('/server-error', (_req: Request, _res: Response) => {
  throw new Error('Test server error');
});

export default router;