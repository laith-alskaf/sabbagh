import winston from 'winston';
import 'winston-daily-rotate-file';
import path from 'path';
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

// Define the format for logs
const format = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss:ms' }),
  winston.format.errors({ stack: true }),
  winston.format.json(),
  winston.format.printf((info) => {
    const { timestamp, level, message, ...meta } = info;
    let logMessage = `${timestamp} [${level.toUpperCase()}]: ${message}`;
    
    if (Object.keys(meta).length > 0) {
      logMessage += ` | Meta: ${JSON.stringify(meta)}`;
    }
    
    return logMessage;
  })
);

// Define the format for console logs
const consoleFormat = winston.format.combine(
  winston.format.colorize({ all: true }),
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss:ms' }),
  winston.format.printf(
    (info) => `${info.timestamp} ${info.level}: ${info.message}`
  )
);

// Define transports
const transports: winston.transport[] = [
  // Console transport
  new winston.transports.Console({
    format: consoleFormat,
  }),
];

// Add file transports in production
if (!env.isDevelopment) {
  // Create a daily rotate file for all logs
  const allFileTransport = new winston.transports.DailyRotateFile({
    filename: path.join(env.logsDir, 'application-%DATE%.log'),
    datePattern: 'YYYY-MM-DD',
    zippedArchive: true,
    maxSize: '20m',
    maxFiles: '14d',
    level: 'info',
  });

  // Create a daily rotate file for error logs
  const errorFileTransport = new winston.transports.DailyRotateFile({
    filename: path.join(env.logsDir, 'error-%DATE%.log'),
    datePattern: 'YYYY-MM-DD',
    zippedArchive: true,
    maxSize: '20m',
    maxFiles: '14d',
    level: 'error',
  });

  transports.push(allFileTransport, errorFileTransport);
}

// Create the logger
const logger = winston.createLogger({
  level: level(),
  levels,
  format,
  transports,
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