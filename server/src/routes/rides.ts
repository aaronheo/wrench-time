import { Router } from 'express';
import { query } from '../db.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import { RIDE_COLS } from '../columns.js';
import { rideCreate } from '../schemas.js';

export const ridesRouter = Router();

// GET /api/rides — sync history for the user, most recent first.
ridesRouter.get(
  '/',
  asyncHandler(async (req, res) => {
    const rows = await query(
      `select ${RIDE_COLS} from ride_syncs where user_id = $1 order by sync_date desc limit 500`,
      [req.userId],
    );
    res.json(rows);
  }),
);

// POST /api/rides — log a sync event (delta computed if not provided).
ridesRouter.post(
  '/',
  asyncHandler(async (req, res) => {
    const r = rideCreate.parse(req.body);
    const delta = r.deltaMeters ?? r.newDistanceMeters - r.previousDistanceMeters;
    const rows = await query(
      `insert into ride_syncs
         (id, user_id, sync_date, bike_strava_gear_id, previous_distance_meters,
          new_distance_meters, delta_meters)
       values
         (coalesce($1, gen_random_uuid()), $2, coalesce($3, now()), $4, $5, $6, $7)
       returning ${RIDE_COLS}`,
      [
        r.id ?? null,
        req.userId,
        r.syncDate ?? null,
        r.bikeStravaGearId,
        r.previousDistanceMeters,
        r.newDistanceMeters,
        delta,
      ],
    );
    res.status(201).json(rows[0]);
  }),
);
