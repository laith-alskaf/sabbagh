import { env } from '../config/env';

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
    process.env.AWS_EXECUTION_ENV ||
    process.env.VERCEL_ENV ||
    process.env.NOW_REGION
  );
};

// Simple logger interface
interface Logger {
  info: (message: string, meta?: any) => void;
  error: (message: string, meta?: any) => void;
  warn: (message: string, meta?: any) => void;
  debug: (message: string, meta?: any) => void;
  http: (message: string, meta?: any) => void;
}

// Check if we're in serverless environment
const serverless = isServerlessEnvironment();
console.log(`Logger mode: ${serverless ? 'serverless (console only)' : 'full winston'}`);

let logger: Logger;

if (serverless) {
  // Simple console-based logger for serverless
  const timestamp = () => new Date().toISOString();
  
  logger = {
    info: (message: string, meta?: any) => {
      const metaStr = meta ? ` | ${JSON.stringify(meta)}` : '';
      console.log(`${timestamp()} [INFO]: ${message}${metaStr}`);
    },
    error: (message: string, meta?: any) => {
      const metaStr = meta ? ` | ${JSON.stringify(meta)}` : '';
      console.error(`${timestamp()} [ERROR]: ${message}${metaStr}`);
    },
    warn: (message: string, meta?: any) => {
      const metaStr = meta ? ` | ${JSON.stringify(meta)}` : '';
      console.warn(`${timestamp()} [WARN]: ${message}${metaStr}`);
    },
    debug: (message: string, meta?: any) => {
      if (env.isDevelopment) {
        const metaStr = meta ? ` | ${JSON.stringify(meta)}` : '';
        console.log(`${timestamp()} [DEBUG]: ${message}${metaStr}`);
      }
    },
    http: (message: string, meta?: any) => {
      const metaStr = meta ? ` | ${JSON.stringify(meta)}` : '';
      console.log(`${timestamp()} [HTTP]: ${message}${metaStr}`);
    },
  };
} else {
  // Full winston logger for local/production servers
  try {
    const winston = require('winston');
    const path = require('path');
    
    // Define log levels
    const levels = {
      error: 0,
      warn: 1,
      info: 2,
      http: 3,
      debug: 4,
    };

    // Define colors for each level
    const colors = {
      error: 'red',
      warn: 'yellow',
      info: 'green',
      http: 'magenta',
      debug: 'blue',
    };

    winston.addColors(colors);

    // Define the format for logs
    const logFormat = winston.format.combine(
      winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss:ms' }),
      winston.format.errors({ stack: true }),
      winston.format.printf((info: any) => {
        const { timestamp, level, message, ...meta } = info;
        let logMessage = `${timestamp} [${level.toUpperCase()}]: ${message}`;
        
        if (Object.keys(meta).length > 0) {
          logMessage += ` | ${JSON.stringify(meta)}`;
        }
        
        return logMessage;
      })
    );

    // Console format
    const consoleFormat = winston.format.combine(
      winston.format.colorize({ all: true }),
      winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss:ms' }),
      winston.format.printf(
        (info: any) => `${info.timestamp} ${info.level}: ${info.message}`
      )
    );

    // Create transports
    const transports: any[] = [
      new winston.transports.Console({
        format: consoleFormat,
      }),
    ];

    // Add file logging only in production
    if (env.nodeEnv === 'production') {
      try {
        const fs = require('fs');
        const DailyRotateFile = require('winston-daily-rotate-file');
        
        // Ensure logs directory exists
        if (!fs.existsSync(env.logsDir)) {
          fs.mkdirSync(env.logsDir, { recursive: true });
        }

        transports.push(
          new DailyRotateFile({
            filename: path.join(env.logsDir, 'application-%DATE%.log'),
            datePattern: 'YYYY-MM-DD',
            zippedArchive: true,
            maxSize: '20m',
            maxFiles: '14d',
            level: 'info',
            format: logFormat,
          }),
          new DailyRotateFile({
            filename: path.join(env.logsDir, 'error-%DATE%.log'),
            datePattern: 'YYYY-MM-DD',
            zippedArchive: true,
            maxSize: '20m',
            maxFiles: '14d',
            level: 'error',
            format: logFormat,
          })
        );
      } catch (error) {
        console.warn('File logging disabled:', error);
      }
    }

    const winstonLogger = winston.createLogger({
      level: env.isDevelopment ? 'debug' : 'info',
      levels,
      format: logFormat,
      transports,
      exitOnError: false,
    });

    logger = {
      info: (message: string, meta?: any) => winstonLogger.info(message, meta),
      error: (message: string, meta?: any) => winstonLogger.error(message, meta),
      warn: (message: string, meta?: any) => winstonLogger.warn(message, meta),
      debug: (message: string, meta?: any) => winstonLogger.debug(message, meta),
      http: (message: string, meta?: any) => winstonLogger.http(message, meta),
    };
  } catch (error) {
    console.error('Failed to initialize winston, falling back to console logging:', error);
    // Fallback to console logging
    const timestamp = () => new Date().toISOString();
    
    logger = {
      info: (message: string, meta?: any) => {
        const metaStr = meta ? ` | ${JSON.stringify(meta)}` : '';
        console.log(`${timestamp()} [INFO]: ${message}${metaStr}`);
      },
      error: (message: string, meta?: any) => {
        const metaStr = meta ? ` | ${JSON.stringify(meta)}` : '';
        console.error(`${timestamp()} [ERROR]: ${message}${metaStr}`);
      },
      warn: (message: string, meta?: any) => {
        const metaStr = meta ? ` | ${JSON.stringify(meta)}` : '';
        console.warn(`${timestamp()} [WARN]: ${message}${metaStr}`);
      },
      debug: (message: string, meta?: any) => {
        if (env.isDevelopment) {
          const metaStr = meta ? ` | ${JSON.stringify(meta)}` : '';
          console.log(`${timestamp()} [DEBUG]: ${message}${metaStr}`);
        }
      },
      http: (message: string, meta?: any) => {
        const metaStr = meta ? ` | ${JSON.stringify(meta)}` : '';
        console.log(`${timestamp()} [HTTP]: ${message}${metaStr}`);
      },
    };
  }
}

// Helper functions
export const logWithContext = (level: string, message: string, context: any = {}) => {
  (logger as any)[level](message, context);
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