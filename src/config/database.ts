import prisma from './prisma';

/**
 * Initialize database connection
 */
export const initializeDatabase = async (): Promise<void> => {
  try {
    // Test database connection
    await prisma.$connect();
    console.log('✅ Database connection established successfully');
    
    // Disconnect after testing
    await prisma.$disconnect();
  } catch (error) {
    console.error('❌ Failed to connect to the database:', error);
    process.exit(1);
  }
};

/**
 * Close database connection
 */
export const closeDatabase = async (): Promise<void> => {
  try {
    await prisma.$disconnect();
    console.log('✅ Database connection closed successfully');
  } catch (error) {
    console.error('❌ Failed to close database connection:', error);
    process.exit(1);
  }
};