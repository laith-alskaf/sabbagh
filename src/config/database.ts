import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

// Application should use DATABASE_URL (Supabase Pooler 6543)
// Migrations should use DIRECT_URL (Supabase direct 5432)
const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  // Fail fast to surface env misconfiguration
  throw new Error('DATABASE_URL is not set in the environment');
}

export const pool = new Pool({
  connectionString,
  ssl: { rejectUnauthorized: false }, // Supabase requires SSL
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