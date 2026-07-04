// Augment Express's Request with the authenticated user set by requireAuth.
// All /api routes run behind that middleware, so these are populated there.
declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      userId: string;
      userEmail?: string;
    }
  }
}

export {};
