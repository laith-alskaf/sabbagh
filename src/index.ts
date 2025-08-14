import app from './app';
import { env } from './config/env';
import { seedDefaultManager } from './services/authService';

const PORT = env.port;

// Seed default manager account
seedDefaultManager()
  .then(() => {
    // Start the server
    const server = app.listen(PORT, () => {
      console.log(`Server running in ${env.nodeEnv} mode on port ${PORT}`);
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
  })
  .catch((error) => {
    console.error('Failed to seed default manager account:', error);
    process.exit(1);
  });