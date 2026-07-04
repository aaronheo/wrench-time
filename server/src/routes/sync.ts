import { Router } from 'express';
import { z } from 'zod';
import { pool, query } from '../db.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import { BIKE_COLS, COMPONENT_COLS, MAINTENANCE_COLS } from '../columns.js';

export const syncRouter = Router();

/**
 * GET /api/sync — the user's full dataset in one round-trip. Used by clients
 * (e.g. iOS) to hydrate their local cache from the source of truth.
 */
syncRouter.get(
  '/',
  asyncHandler(async (req, res) => {
    const [bikes, components, maintenance] = await Promise.all([
      query(`select ${BIKE_COLS} from bikes where user_id = $1 order by date_added asc`, [req.userId]),
      query(`select ${COMPONENT_COLS} from components where user_id = $1`, [req.userId]),
      query(`select ${MAINTENANCE_COLS} from maintenance_records where user_id = $1`, [req.userId]),
    ]);
    res.json({ bikes, components, maintenance });
  }),
);

// A full snapshot of the user's data, pushed by a client to replace server state.
const snapshot = z.object({
  bikes: z.array(
    z.object({
      id: z.string().uuid(),
      name: z.string().min(1),
      brandName: z.string().default(''),
      modelName: z.string().default(''),
      stravaGearId: z.string().nullable().optional(),
      brakeType: z.enum(['disc', 'rim']).default('disc'),
      totalDistanceMeters: z.number().default(0),
      isPrimary: z.boolean().default(false),
      dateAdded: z.string().datetime().optional(),
      lastSyncDate: z.string().datetime().nullable().optional(),
    }),
  ),
  components: z.array(
    z.object({
      id: z.string().uuid(),
      bikeId: z.string().uuid(),
      type: z.string().min(1),
      name: z.string().min(1),
      installedDate: z.string().datetime().optional(),
      distanceAtInstall: z.number().default(0),
      replacementThresholdMiles: z.number().positive(),
      notes: z.string().default(''),
    }),
  ),
  maintenance: z.array(
    z.object({
      id: z.string().uuid(),
      bikeId: z.string().uuid(),
      componentType: z.string().min(1),
      date: z.string().datetime().optional(),
      distanceAtReplacement: z.number().default(0),
      cost: z.number().nullable().optional(),
      notes: z.string().default(''),
      partName: z.string().default(''),
    }),
  ),
});

/**
 * POST /api/sync — replace the user's server data with the provided snapshot,
 * transactionally. Components/maintenance are re-parented to the pushed bikes.
 *
 * Guard: a snapshot with zero bikes is rejected, so a client that hasn't hydrated
 * yet can't accidentally wipe the account.
 */
syncRouter.post(
  '/',
  asyncHandler(async (req, res) => {
    const data = snapshot.parse(req.body);

    if (data.bikes.length === 0) {
      res.status(409).json({ error: 'Refusing to replace account data with an empty snapshot.' });
      return;
    }

    const bikeIds = new Set(data.bikes.map((b) => b.id));
    for (const c of data.components) {
      if (!bikeIds.has(c.bikeId)) {
        res.status(400).json({ error: `Component ${c.id} references unknown bike ${c.bikeId}.` });
        return;
      }
    }
    for (const m of data.maintenance) {
      if (!bikeIds.has(m.bikeId)) {
        res.status(400).json({ error: `Maintenance ${m.id} references unknown bike ${m.bikeId}.` });
        return;
      }
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Deleting bikes cascades to components + maintenance for this user.
      await client.query('delete from bikes where user_id = $1', [req.userId]);

      for (const b of data.bikes) {
        await client.query(
          `insert into bikes
             (id, user_id, name, brand_name, model_name, strava_gear_id, brake_type,
              total_distance_meters, is_primary, date_added, last_sync_date)
           values ($1,$2,$3,$4,$5,$6,$7,$8,$9, coalesce($10, now()), $11)`,
          [
            b.id, req.userId, b.name, b.brandName, b.modelName, b.stravaGearId ?? null,
            b.brakeType, b.totalDistanceMeters, b.isPrimary, b.dateAdded ?? null, b.lastSyncDate ?? null,
          ],
        );
      }

      for (const c of data.components) {
        await client.query(
          `insert into components
             (id, user_id, bike_id, type, name, installed_date, distance_at_install,
              replacement_threshold_miles, notes)
           values ($1,$2,$3,$4,$5, coalesce($6, now()), $7,$8,$9)`,
          [
            c.id, req.userId, c.bikeId, c.type, c.name, c.installedDate ?? null,
            c.distanceAtInstall, c.replacementThresholdMiles, c.notes,
          ],
        );
      }

      for (const m of data.maintenance) {
        await client.query(
          `insert into maintenance_records
             (id, user_id, bike_id, component_type, date, distance_at_replacement, cost, notes, part_name)
           values ($1,$2,$3,$4, coalesce($5, now()), $6,$7,$8,$9)`,
          [
            m.id, req.userId, m.bikeId, m.componentType, m.date ?? null,
            m.distanceAtReplacement, m.cost ?? null, m.notes, m.partName,
          ],
        );
      }

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }

    // Return the freshly-persisted dataset.
    const [bikes, components, maintenance] = await Promise.all([
      query(`select ${BIKE_COLS} from bikes where user_id = $1 order by date_added asc`, [req.userId]),
      query(`select ${COMPONENT_COLS} from components where user_id = $1`, [req.userId]),
      query(`select ${MAINTENANCE_COLS} from maintenance_records where user_id = $1`, [req.userId]),
    ]);
    res.json({ bikes, components, maintenance });
  }),
);
