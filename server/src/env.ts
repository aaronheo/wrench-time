import 'dotenv/config';

function required(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export const env = {
  PORT: process.env.PORT ? Number(process.env.PORT) : 8080,
  DATABASE_URL: required('DATABASE_URL'),
  SUPABASE_URL: required('SUPABASE_URL').replace(/\/+$/, ''),
  SUPABASE_JWT_SECRET: process.env.SUPABASE_JWT_SECRET || null,
  ALLOWED_ORIGINS: process.env.ALLOWED_ORIGINS || '*',
};
