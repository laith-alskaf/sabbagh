import winston from 'winston';
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

// Function to detect serverless environment
const isServerlessEnvironment = (): boolean => {
  return !!(
    process.env.VERCEL || 
    process.env.AWS_LAMBDA_FUNCTION_NAME || 
    process.env.LAMBDA_TASK_ROOT ||
    process.env.NETLIFY ||
    process.env.RAILWAY_ENVIRONMENT ||
    process.env.RENDER ||
    process.env.HEROKU_APP_NAME ||
    process.env.LAMBDA_RUNTIME_DIR ||
    process.env.AWS_EXECUTION_ENV
  );
};

// Define the format for logs
const logFormat = winston.format.combine(
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

// Define the format for console logs
const consoleFormat = winston.format.combine(
  winston.format.colorize({ all: true }),
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss:ms' }),
  winston.format.printf(
    (info) => `${info.timestamp} ${info.level}: ${info.message}`
  )
);

// Create transports array starting with console
const transports: winston.transport[] = [
  new winston.transports.Console({
    format: consoleFormat,
  }),
];

// Check environment and add file logging only if safe
const serverless = isServerlessEnvironment();
console.log(`Logger initialization: serverless=${serverless}, isDev=${env.isDevelopment}`);

if (!serverless && !env.isDevelopment) {
  console.log('Attempting to enable file logging...');
  
  try {
    // Dynamic import to avoid loading winston-daily-rotate-file in serverless
    const fs = require('fs');
    
    // Check if we can write to the logs directory
    if (!fs.existsSync(env.logsDir)) {
      fs.mkdirSync(env.logsDir, { recursive: true });
    }
    
    // Test write permissions
    const testFile = path.join(env.logsDir, 'test.log');
    fs.writeFileSync(testFile, 'test');
    fs.unlinkSync(testFile);
    
    // Only import DailyRotateFile if we're sure we can use it
    const DailyRotateFile = require('winston-daily-rotate-file');
    
    // Create a daily rotate file for all logs
    const allFileTransport = new DailyRotateFile({
      filename: path.join(env.logsDir, 'application-%DATE%.log'),
      datePattern: 'YYYY-MM-DD',
      zippedArchive: true,
      maxSize: '20m',
      maxFiles: '14d',
      level: 'info',
      format: logFormat,
    });

    // Create a daily rotate file for error logs
    const errorFileTransport = new DailyRotateFile({
      filename: path.join(env.logsDir, 'error-%DATE%.log'),
      datePattern: 'YYYY-MM-DD',
      zippedArchive: true,
      maxSize: '20m',
      maxFiles: '14d',
      level: 'error',
      format: logFormat,
    });

    transports.push(allFileTransport, errorFileTransport);
    console.log('File logging enabled successfully');
  } catch (error) {
    console.warn('File logging disabled due to error:', error instanceof Error ? error.message : 'Unknown error');
  }
} else {
  if (serverless) {
    console.log('File logging disabled - serverless environment detected');
  } else {
    console.log('File logging disabled - development mode');
  }
}

// Create the logger
const logger = winston.createLogger({
  level: level(),
  levels,
  format: logFormat,
  transports,
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