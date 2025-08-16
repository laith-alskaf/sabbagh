import app from './app';
import { env } from './config/env';
import { seedDefaultManager } from './services/authService';

const PORT = env.port;

// Function to start server
const startServer = () => {
  const server = app.listen(PORT, () => {
    console.log(`Server running in ${env.nodeEnv} mode on port ${PORT}`);
    console.log(`Using mock data: ${env.useMockData}`);
  });

  // Handle unhandled promise rejections
  process.on('unhandledRejection', (err: Error) => {
    console.error('UNHANDLED REJECTION! 💥 Shutting down...');
    console.error(err.name, err.message);
    server.close(() => {
      process.exit(1);
    });
  });

  // Handle SIGTERM signal
  process.on('SIGTERM', () => {
    console.log('👋 SIGTERM RECEIVED. Shutting down gracefully');
    server.close(() => {
      console.log('💥 Process terminated!');
    });
  });

  return server;
};

// In serverless environments (like Vercel), we don't need to seed data
// and we should start the server immediately
if (env.useMockData || process.env.VERCEL || process.env.AWS_LAMBDA_FUNCTION_NAME) {
  console.log('Serverless environment detected - starting server without database seeding');
  startServer();
} else {
  // For local development with real database
  console.log('Local environment detected - seeding default manager account');
  seedDefaultManager()
    .then(() => {
      startServer();
    })
    .catch((error) => {
      console.error('Failed to seed default manager account:', error);
      // Still start the server even if seeding fails
      console.log('Starting server anyway...');
      startServer();
    });
}

// Export the app for serverless environments
export default app;