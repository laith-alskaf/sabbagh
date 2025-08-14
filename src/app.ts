import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { env } from './config/env';
import routes from './routes';
import { i18nextMiddleware } from './config/i18n';
import { AppError, errorHandler, notFoundHandler } from './middlewares/errorMiddleware';
import { t } from './utils/i18n';

// Create Express app
const app = express();

// Apply middlewares
app.use(helmet()); // Security headers
app.use(cors()); // Enable CORS
app.use(express.json()); // Parse JSON bodies
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded bodies

// i18n middleware
app.use(i18nextMiddleware);

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

// API routes
app.use('/api', routes);

// Handle 404 errors
app.all('*', notFoundHandler);

// Global error handler
app.use(errorHandler);

export default app;