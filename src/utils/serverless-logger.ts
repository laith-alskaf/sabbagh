import winston from 'winston';
import { env } from '../config/env';

// Define log levels
const levels = {
  error: 0,
  warn: 1,
  info: 2,
  http: 3,
  debug: 4,
};

// Define log level based on environment
const level = () => {
  return env.isDevelopment ? 'debug' : 'info';
};

// Define colors for each level
const colors = {
  error: 'red',
  warn: 'yellow',
  info: 'green',
  http: 'magenta',
  debug: 'blue',
};

// Add colors to winston
winston.addColors(colors);

// Define the format for console logs (optimized for serverless)
const serverlessFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss:ms' }),
  winston.format.errors({ stack: true }),
  winston.format.printf((info) => {
    const { timestamp, level, message, ...meta } = info;
    let logMessage = `${timestamp} [${level.toUpperCase()}]: ${message}`;
    
    if (Object.keys(meta).length > 0) {
      logMessage += ` | ${JSON.stringify(meta)}`;
    }
    
    return logMessage;
  })
);

// Create serverless-optimized logger (console only)
const logger = winston.createLogger({
  level: level(),
  levels,
  format: serverlessFormat,
  transports: [
    new winston.transports.Console({
      format: serverlessFormat,
    }),
  ],
  exitOnError: false,
});

// Add helper methods for structured logging
export const logWithContext = (level: string, message: string, context: any = {}) => {
  logger.log(level, message, context);
};

export const logRequest = (method: string, url: string, statusCode: number, duration: number, requestId?: string) => {
  logger.info('HTTP Request', {
    method,
    url,
    statusCode,
    duration,
    requestId,
  });
};

export const logError = (error: Error, context: any = {}) => {
  logger.error('Application Error', {
    message: error.message,
    stack: error.stack,
    ...context,
  });
};

export const logAuth = (action: string, userId: string, success: boolean, ip?: string) => {
  logger.info('Authentication Event', {
    action,
    userId,
    success,
    ip,
  });
};

export const logBusinessEvent = (event: string, data: any = {}) => {
  logger.info('Business Event', {
    event,
    ...data,
  });
};

export const logInfo = (message: string, context: any = {}) => {
  logger.info(message, context);
};

export default logger;