// Smart logger that chooses the right implementation based on environment

// Function to detect serverless environment
const isServerlessEnvironment = (): boolean => {
  return !!(
    process.env.VERCEL || 
    process.env.AWS_LAMBDA_FUNCTION_NAME || 
    process.env.LAMBDA_TASK_ROOT ||
    process.env.NETLIFY ||
    process.env.RAILWAY_ENVIRONMENT ||
    process.env.RENDER ||
    process.env.HEROKU_APP_NAME
  );
};

// Import both loggers
import * as serverlessLogger from './serverless-logger';
import * as fullLogger from './full-logger';

// Choose the appropriate logger implementation
const useServerless = isServerlessEnvironment();

if (useServerless) {
  console.log('Using serverless logger (console only)');
} else {
  console.log('Using full logger (with file support)');
}

// Export the appropriate logger
const logger = useServerless ? serverlessLogger.default : fullLogger.default;
export const logWithContext = useServerless ? serverlessLogger.logWithContext : fullLogger.logWithContext;
export const logRequest = useServerless ? serverlessLogger.logRequest : fullLogger.logRequest;
export const logError = useServerless ? serverlessLogger.logError : fullLogger.logError;
export const logAuth = useServerless ? serverlessLogger.logAuth : fullLogger.logAuth;
export const logBusinessEvent = useServerless ? serverlessLogger.logBusinessEvent : fullLogger.logBusinessEvent;
export const logInfo = useServerless ? serverlessLogger.logInfo : fullLogger.logInfo;

export default logger;