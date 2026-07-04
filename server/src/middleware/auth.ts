import type { NextFunction, Request, Response } from 'express';
import { createRemoteJWKSet, jwtVerify, type JWTVerifyGetKey } from 'jose';
import { env } from '../env.js';

const issuer = `${env.SUPABASE_URL}/auth/v1`;

// Two verification paths:
//  - Legacy projects sign JWTs with a shared HS256 secret -> verify with that secret.
//  - Current projects sign with asymmetric keys -> verify against the JWKS endpoint.
const hsKey = env.SUPABASE_JWT_SECRET
  ? new TextEncoder().encode(env.SUPABASE_JWT_SECRET)
  : null;

const jwks: JWTVerifyGetKey | null = hsKey
  ? null
  : createRemoteJWKSet(new URL(`${issuer}/.well-known/jwks.json`));

/**
 * Verify the Supabase-issued JWT (from Google sign-in) on the Authorization
 * header and attach the user id/email to the request. Rejects with 401 otherwise.
 */
export async function requireAuth(req: Request, res: Response, next: NextFunction): Promise<void> {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing or malformed Authorization header' });
    return;
  }

  const token = header.slice('Bearer '.length).trim();
  try {
    const options = { issuer, audience: 'authenticated' };
    const { payload } = hsKey
      ? await jwtVerify(token, hsKey, options)
      : await jwtVerify(token, jwks!, options);

    if (!payload.sub) {
      res.status(401).json({ error: 'Token missing subject claim' });
      return;
    }

    req.userId = payload.sub;
    req.userEmail = typeof payload.email === 'string' ? payload.email : undefined;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}
