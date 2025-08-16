import app from './app';
import { env } from './config/env';
import { seedDefaultManager } from './services/authService';

const PORT = env.port;

// Function to start server
const startServer = () => {
  const server = app.listen(PORT, () => {
    console.log(`Server running in ${env.nodeEnv} mode on port ${PORT}`);
    console.log(`Database connection: ${env.database.host}:${env.database.port}/${env.database.name}`);
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

// Always try to seed default manager account first
console.log('Seeding default manager account...');
seedDefaultManager()
  .then(() => {
    console.log('Manager seeding completed, starting server...');
    startServer();
  })
  .catch((error) => {
    console.error('Failed to seed default manager account:', error);
    // Still start the server even if seeding fails
    console.log('Starting server anyway...');
    startServer();
  });

// Export the app for serverless environments
export default app;