import './types.js';
import express from 'express';
import cors from 'cors';
import { env } from './env.js';
import { requireAuth } from './middleware/auth.js';
import { errorHandler } from './middleware/errorHandler.js';
import { bikesRouter } from './routes/bikes.js';
import { componentsRouter } from './routes/components.js';
import { maintenanceRouter } from './routes/maintenance.js';
import { ridesRouter } from './routes/rides.js';
import { settingsRouter } from './routes/settings.js';
import { syncRouter } from './routes/sync.js';

const app = express();

app.use(
  cors({
    origin:
      env.ALLOWED_ORIGINS === '*'
        ? true
        : env.ALLOWED_ORIGINS.split(',').map((o) => o.trim()),
  }),
);
app.use(express.json());

// Public health check for Render.
app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

// Everything under /api requires a valid Supabase JWT.
app.use('/api', requireAuth);
app.use('/api/bikes', bikesRouter);
app.use('/api/components', componentsRouter);
app.use('/api/maintenance', maintenanceRouter);
app.use('/api/rides', ridesRouter);
app.use('/api/settings', settingsRouter);
app.use('/api/sync', syncRouter);

app.use(errorHandler);

app.listen(env.PORT, () => {
  console.log(`[wrench-time-api] listening on port ${env.PORT}`);
});
