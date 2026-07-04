import { Router } from 'express';
import { query } from '../db.js';
import { asyncHandler, HttpError } from '../middleware/errorHandler.js';
import { buildUpdateSet } from '../sql.js';
import { MAINTENANCE_COLS, MAINTENANCE_UPDATE_MAP } from '../columns.js';
import { maintenanceUpdate } from '../schemas.js';

export const maintenanceRouter = Router();

// PATCH /api/maintenance/:id
maintenanceRouter.patch(
  '/:id',
  asyncHandler(async (req, res) => {
    const updates = maintenanceUpdate.parse(req.body);
    const { setClause, values, nextIndex } = buildUpdateSet(MAINTENANCE_UPDATE_MAP, updates);
    values.push(req.params.id, req.userId);
    const rows = await query(
      `update maintenance_records set ${setClause}
       where id = $${nextIndex} and user_id = $${nextIndex + 1}
       returning ${MAINTENANCE_COLS}`,
      values,
    );
    if (rows.length === 0) throw new HttpError(404, 'Maintenance record not found');
    res.json(rows[0]);
  }),
);

// DELETE /api/maintenance/:id
maintenanceRouter.delete(
  '/:id',
  asyncHandler(async (req, res) => {
    const rows = await query(
      'delete from maintenance_records where id = $1 and user_id = $2 returning id',
      [req.params.id, req.userId],
    );
    if (rows.length === 0) throw new HttpError(404, 'Maintenance record not found');
    res.status(204).send();
  }),
);
