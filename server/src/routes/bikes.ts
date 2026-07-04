import { Router } from 'express';
import { query } from '../db.js';
import { asyncHandler, HttpError } from '../middleware/errorHandler.js';
import { buildUpdateSet } from '../sql.js';
import { BIKE_COLS, BIKE_UPDATE_MAP, COMPONENT_COLS, MAINTENANCE_COLS } from '../columns.js';
import { bikeCreate, bikeUpdate, componentCreate, maintenanceCreate } from '../schemas.js';

export const bikesRouter = Router();

// GET /api/bikes — all bikes for the user, primary first.
bikesRouter.get(
  '/',
  asyncHandler(async (req, res) => {
    const bikes = await query(
      `select ${BIKE_COLS} from bikes where user_id = $1 order by is_primary desc, date_added asc`,
      [req.userId],
    );
    res.json(bikes);
  }),
);

// GET /api/bikes/:id — one bike with its components and maintenance records.
bikesRouter.get(
  '/:id',
  asyncHandler(async (req, res) => {
    const bikes = await query(
      `select ${BIKE_COLS} from bikes where id = $1 and user_id = $2`,
      [req.params.id, req.userId],
    );
    if (bikes.length === 0) throw new HttpError(404, 'Bike not found');

    const [components, maintenanceRecords] = await Promise.all([
      query(
        `select ${COMPONENT_COLS} from components where bike_id = $1 and user_id = $2 order by installed_date asc`,
        [req.params.id, req.userId],
      ),
      query(
        `select ${MAINTENANCE_COLS} from maintenance_records where bike_id = $1 and user_id = $2 order by date desc`,
        [req.params.id, req.userId],
      ),
    ]);

    res.json({ ...bikes[0], components, maintenanceRecords });
  }),
);

// POST /api/bikes — create a bike (client may supply id for idempotent sync).
bikesRouter.post(
  '/',
  asyncHandler(async (req, res) => {
    const b = bikeCreate.parse(req.body);
    const rows = await query(
      `insert into bikes
         (id, user_id, name, brand_name, model_name, strava_gear_id, brake_type,
          total_distance_meters, is_primary, date_added, last_sync_date)
       values
         (coalesce($1, gen_random_uuid()), $2, $3, $4, $5, $6, $7, $8, $9, coalesce($10, now()), $11)
       returning ${BIKE_COLS}`,
      [
        b.id ?? null,
        req.userId,
        b.name,
        b.brandName,
        b.modelName,
        b.stravaGearId ?? null,
        b.brakeType,
        b.totalDistanceMeters,
        b.isPrimary,
        b.dateAdded ?? null,
        b.lastSyncDate ?? null,
      ],
    );
    res.status(201).json(rows[0]);
  }),
);

// PATCH /api/bikes/:id — partial update.
bikesRouter.patch(
  '/:id',
  asyncHandler(async (req, res) => {
    const updates = bikeUpdate.parse(req.body);
    const { setClause, values, nextIndex } = buildUpdateSet(BIKE_UPDATE_MAP, updates);
    values.push(req.params.id, req.userId);
    const rows = await query(
      `update bikes set ${setClause}
       where id = $${nextIndex} and user_id = $${nextIndex + 1}
       returning ${BIKE_COLS}`,
      values,
    );
    if (rows.length === 0) throw new HttpError(404, 'Bike not found');
    res.json(rows[0]);
  }),
);

// DELETE /api/bikes/:id — cascades to components and maintenance records.
bikesRouter.delete(
  '/:id',
  asyncHandler(async (req, res) => {
    const rows = await query(
      'delete from bikes where id = $1 and user_id = $2 returning id',
      [req.params.id, req.userId],
    );
    if (rows.length === 0) throw new HttpError(404, 'Bike not found');
    res.status(204).send();
  }),
);

// --- Nested: components under a bike ---

async function assertBikeOwned(bikeId: string, userId: string): Promise<void> {
  const rows = await query('select id from bikes where id = $1 and user_id = $2', [bikeId, userId]);
  if (rows.length === 0) throw new HttpError(404, 'Bike not found');
}

bikesRouter.get(
  '/:bikeId/components',
  asyncHandler(async (req, res) => {
    await assertBikeOwned(req.params.bikeId, req.userId);
    const rows = await query(
      `select ${COMPONENT_COLS} from components where bike_id = $1 and user_id = $2 order by installed_date asc`,
      [req.params.bikeId, req.userId],
    );
    res.json(rows);
  }),
);

bikesRouter.post(
  '/:bikeId/components',
  asyncHandler(async (req, res) => {
    await assertBikeOwned(req.params.bikeId, req.userId);
    const c = componentCreate.parse(req.body);
    const rows = await query(
      `insert into components
         (id, user_id, bike_id, type, name, installed_date, distance_at_install,
          replacement_threshold_miles, notes)
       values
         (coalesce($1, gen_random_uuid()), $2, $3, $4, $5, coalesce($6, now()), $7, $8, $9)
       returning ${COMPONENT_COLS}`,
      [
        c.id ?? null,
        req.userId,
        req.params.bikeId,
        c.type,
        c.name,
        c.installedDate ?? null,
        c.distanceAtInstall,
        c.replacementThresholdMiles,
        c.notes,
      ],
    );
    res.status(201).json(rows[0]);
  }),
);

// --- Nested: maintenance records under a bike ---

bikesRouter.get(
  '/:bikeId/maintenance',
  asyncHandler(async (req, res) => {
    await assertBikeOwned(req.params.bikeId, req.userId);
    const rows = await query(
      `select ${MAINTENANCE_COLS} from maintenance_records where bike_id = $1 and user_id = $2 order by date desc`,
      [req.params.bikeId, req.userId],
    );
    res.json(rows);
  }),
);

bikesRouter.post(
  '/:bikeId/maintenance',
  asyncHandler(async (req, res) => {
    await assertBikeOwned(req.params.bikeId, req.userId);
    const m = maintenanceCreate.parse(req.body);
    const rows = await query(
      `insert into maintenance_records
         (id, user_id, bike_id, component_type, date, distance_at_replacement, cost, notes, part_name)
       values
         (coalesce($1, gen_random_uuid()), $2, $3, $4, coalesce($5, now()), $6, $7, $8, $9)
       returning ${MAINTENANCE_COLS}`,
      [
        m.id ?? null,
        req.userId,
        req.params.bikeId,
        m.componentType,
        m.date ?? null,
        m.distanceAtReplacement,
        m.cost ?? null,
        m.notes,
        m.partName,
      ],
    );
    res.status(201).json(rows[0]);
  }),
);
