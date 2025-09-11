import { Pool } from 'pg';
import { env } from './env';

// Application should use DATABASE_URL (Supabase Pooler 6543)
// Migrations should use DIRECT_URL (Supabase direct 5432)
const connectionString = env.database.url;

if (!connectionString) {
  // Fail fast to surface env misconfiguration
  throw new Error('DATABASE_URL is not set in the environment');
}

console.log('Connecting to database...');
console.log('Database URL configured:', connectionString ? 'Yes' : 'No');

export const pool = new Pool({
  connectionString,
  ssl: { rejectUnauthorized: false }, // Supabase requires SSL
  max: 20, // Maximum number of clients in the pool
  idleTimeoutMillis: 30000, // Close idle clients after 30 seconds
  connectionTimeoutMillis: 10000, // Return an error after 2 seconds if connection could not be established
});
// Optional: quick connectivity check helper
export async function testDbConnection(): Promise<void> {
  const client = await pool.connect();
  try {
    await client.query('SELECT 1');
  } finally {
    client.release();
  }
}