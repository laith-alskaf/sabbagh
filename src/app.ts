import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import swaggerUi from 'swagger-ui-express';
import { env } from './config/env';
import routes from './routes';
import { i18nextMiddleware } from './config/i18n';
import { errorHandler, notFoundHandler } from './middlewares/errorMiddleware';
import { requestIdMiddleware, requestLoggingMiddleware, errorLoggingMiddleware } from './middlewares/loggingMiddleware';
import { t } from './utils/i18n';
import { specs } from './config/swagger';

// Create Express app
const app = express();

// Apply middlewares
app.use(helmet()); // Security headers
// Enable CORS with proper configuration
app.use(cors({
  origin: true, // Allow all origins in development
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept-Language'],
}));
app.use(express.json()); // Parse JSON bodies
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded bodies

// Request tracking middleware
app.use(requestIdMiddleware);

// i18n middleware
app.use(i18nextMiddleware);

// Request logging middleware
app.use(requestLoggingMiddleware);

// Logging
if (env.isDevelopment) {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// Welcome route
app.get('/', (req: Request, res: Response) => {
  res.json({ 
    message: t(req, 'welcome'),
    language: req.language || 'en'
  });
});

// Swagger documentation
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs, {
  explorer: true,
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'Sabbagh API Documentation',
  swaggerOptions: {
    persistAuthorization: true,
    displayRequestDuration: true,
    filter: true,
    showExtensions: true,
    showCommonExtensions: true,
    requestInterceptor: (req: any) => {
      // Ensure proper headers
      req.headers['Content-Type'] = 'application/json';
      return req;
    }
  }
}));

// API routes
app.use('/api', routes);

// Handle 404 errors
// app.all('*', notFoundHandler);

// Error logging middleware
app.use(errorLoggingMiddleware);

// Global error handler
app.use(errorHandler);

export default app;