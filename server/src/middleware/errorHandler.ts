import type { NextFunction, Request, RequestHandler, Response } from 'express';
import { ZodError } from 'zod';

/** Error with an explicit HTTP status, thrown from route handlers. */
export class HttpError extends Error {
  constructor(
    public status: number,
    message: string,
  ) {
    super(message);
    this.name = 'HttpError';
  }
}

/** Wrap an async route handler so rejected promises reach the error middleware. */
export function asyncHandler(
  fn: (req: Request, res: Response, next: NextFunction) => Promise<unknown>,
): RequestHandler {
  return (req, res, next) => {
    fn(req, res, next).catch(next);
  };
}

/** Terminal error middleware. Must have 4 args for Express to recognize it. */
export function errorHandler(
  err: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction,
): void {
  if (err instanceof HttpError) {
    res.status(err.status).json({ error: err.message });
    return;
  }
  if (err instanceof ZodError) {
    res.status(400).json({ error: 'Validation failed', details: err.issues });
    return;
  }
  if (err && typeof err === 'object') {
    // Errors that carry an HTTP status (body-parser: malformed JSON -> 400,
    // payload too large -> 413).
    const carried =
      (err as { status?: unknown }).status ?? (err as { statusCode?: unknown }).statusCode;
    if (typeof carried === 'number' && carried >= 400 && carried < 500) {
      res.status(carried).json({ error: (err as { message?: string }).message ?? 'Request error' });
      return;
    }
    // Postgres error codes: invalid UUID in a path param, unique violation.
    const code = (err as { code?: unknown }).code;
    if (code === '22P02') {
      res.status(400).json({ error: 'Invalid identifier.' });
      return;
    }
    if (code === '23505') {
      res.status(409).json({ error: 'Conflict: duplicate id.' });
      return;
    }
  }
  console.error('[wrench-time-api]', err);
  res.status(500).json({ error: 'Internal server error' });
}
