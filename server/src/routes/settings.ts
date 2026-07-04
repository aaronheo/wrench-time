import { Router } from 'express';
import { query } from '../db.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import { SETTINGS_COLS } from '../columns.js';
import { settingsUpsert } from '../schemas.js';

export const settingsRouter = Router();

const DEFAULT_SETTINGS = {
  isPremium: false,
  stravaConnected: false,
  stravaAthleteId: null,
  distanceUnit: 'miles',
  notificationsEnabled: true,
  lastFullSyncDate: null,
  maxFreeBikes: 1,
};

// GET /api/settings — the user's settings, or defaults if none saved yet.
settingsRouter.get(
  '/',
  asyncHandler(async (req, res) => {
    const rows = await query(
      `select ${SETTINGS_COLS} from user_settings where user_id = $1`,
      [req.userId],
    );
    if (rows.length === 0) {
      res.json({ userId: req.userId, ...DEFAULT_SETTINGS });
      return;
    }
    res.json(rows[0]);
  }),
);

// PUT /api/settings — upsert. Provided fields overwrite; omitted fields keep
// their current value (or the default on first insert).
settingsRouter.put(
  '/',
  asyncHandler(async (req, res) => {
    const s = settingsUpsert.parse(req.body);
    const rows = await query(
      `insert into user_settings
         (user_id, is_premium, strava_connected, strava_athlete_id, distance_unit,
          notifications_enabled, last_full_sync_date, max_free_bikes)
       values
         ($1,
          coalesce($2, false),
          coalesce($3, false),
          $4,
          coalesce($5, 'miles'),
          coalesce($6, true),
          $7,
          coalesce($8, 1))
       on conflict (user_id) do update set
         is_premium = coalesce($2, user_settings.is_premium),
         strava_connected = coalesce($3, user_settings.strava_connected),
         strava_athlete_id = coalesce($4, user_settings.strava_athlete_id),
         distance_unit = coalesce($5, user_settings.distance_unit),
         notifications_enabled = coalesce($6, user_settings.notifications_enabled),
         last_full_sync_date = coalesce($7, user_settings.last_full_sync_date),
         max_free_bikes = coalesce($8, user_settings.max_free_bikes)
       returning ${SETTINGS_COLS}`,
      [
        req.userId,
        s.isPremium ?? null,
        s.stravaConnected ?? null,
        s.stravaAthleteId ?? null,
        s.distanceUnit ?? null,
        s.notificationsEnabled ?? null,
        s.lastFullSyncDate ?? null,
        s.maxFreeBikes ?? null,
      ],
    );
    res.json(rows[0]);
  }),
);
