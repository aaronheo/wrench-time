import pg from 'pg';
import { env } from './env.js';

// Supabase requires TLS. rejectUnauthorized:false avoids bundling their CA cert;
// the connection is still encrypted.
export const pool = new pg.Pool({
  connectionString: env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
  max: 10,
  idleTimeoutMillis: 30_000,
  // Fail fast instead of queueing forever when the pool is saturated, and cap
  // any single query so a hung statement can't hold a connection indefinitely.
  connectionTimeoutMillis: 10_000,
  statement_timeout: 15_000,
});

/** Run a parameterized query and return typed rows. */
export async function query<T = Record<string, unknown>>(
  text: string,
  params: unknown[] = [],
): Promise<T[]> {
  const result = await pool.query(text, params);
  return result.rows as T[];
}
