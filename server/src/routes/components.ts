import { Router } from 'express';
import { query } from '../db.js';
import { asyncHandler, HttpError } from '../middleware/errorHandler.js';
import { buildUpdateSet } from '../sql.js';
import { COMPONENT_COLS, COMPONENT_UPDATE_MAP } from '../columns.js';
import { componentUpdate } from '../schemas.js';

export const componentsRouter = Router();

// PATCH /api/components/:id — partial update of a component the user owns.
componentsRouter.patch(
  '/:id',
  asyncHandler(async (req, res) => {
    const updates = componentUpdate.parse(req.body);
    const { setClause, values, nextIndex } = buildUpdateSet(COMPONENT_UPDATE_MAP, updates);
    values.push(req.params.id, req.userId);
    const rows = await query(
      `update components set ${setClause}
       where id = $${nextIndex} and user_id = $${nextIndex + 1}
       returning ${COMPONENT_COLS}`,
      values,
    );
    if (rows.length === 0) throw new HttpError(404, 'Component not found');
    res.json(rows[0]);
  }),
);

// DELETE /api/components/:id
componentsRouter.delete(
  '/:id',
  asyncHandler(async (req, res) => {
    const rows = await query(
      'delete from components where id = $1 and user_id = $2 returning id',
      [req.params.id, req.userId],
    );
    if (rows.length === 0) throw new HttpError(404, 'Component not found');
    res.status(204).send();
  }),
);
