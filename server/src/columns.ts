// SELECT column lists that alias snake_case DB columns to the camelCase field
// names used by the iOS/web clients (matching the Swift model properties).

export const BIKE_COLS = `
  id,
  name,
  brand_name as "brandName",
  model_name as "modelName",
  strava_gear_id as "stravaGearId",
  brake_type as "brakeType",
  total_distance_meters as "totalDistanceMeters",
  is_primary as "isPrimary",
  date_added as "dateAdded",
  last_sync_date as "lastSyncDate",
  created_at as "createdAt",
  updated_at as "updatedAt"
`;

export const COMPONENT_COLS = `
  id,
  bike_id as "bikeId",
  type,
  name,
  installed_date as "installedDate",
  distance_at_install as "distanceAtInstall",
  replacement_threshold_miles as "replacementThresholdMiles",
  notes,
  created_at as "createdAt",
  updated_at as "updatedAt"
`;

export const MAINTENANCE_COLS = `
  id,
  bike_id as "bikeId",
  component_type as "componentType",
  date,
  distance_at_replacement as "distanceAtReplacement",
  cost,
  notes,
  part_name as "partName",
  created_at as "createdAt",
  updated_at as "updatedAt"
`;

export const RIDE_COLS = `
  id,
  sync_date as "syncDate",
  bike_strava_gear_id as "bikeStravaGearId",
  previous_distance_meters as "previousDistanceMeters",
  new_distance_meters as "newDistanceMeters",
  delta_meters as "deltaMeters",
  created_at as "createdAt"
`;

export const SETTINGS_COLS = `
  user_id as "userId",
  is_premium as "isPremium",
  strava_connected as "stravaConnected",
  strava_athlete_id as "stravaAthleteId",
  distance_unit as "distanceUnit",
  notifications_enabled as "notificationsEnabled",
  last_full_sync_date as "lastFullSyncDate",
  max_free_bikes as "maxFreeBikes",
  created_at as "createdAt",
  updated_at as "updatedAt"
`;

// camelCase field -> snake_case column, for building partial UPDATE statements.
export const BIKE_UPDATE_MAP: Record<string, string> = {
  name: 'name',
  brandName: 'brand_name',
  modelName: 'model_name',
  stravaGearId: 'strava_gear_id',
  brakeType: 'brake_type',
  totalDistanceMeters: 'total_distance_meters',
  isPrimary: 'is_primary',
  dateAdded: 'date_added',
  lastSyncDate: 'last_sync_date',
};

export const COMPONENT_UPDATE_MAP: Record<string, string> = {
  type: 'type',
  name: 'name',
  installedDate: 'installed_date',
  distanceAtInstall: 'distance_at_install',
  replacementThresholdMiles: 'replacement_threshold_miles',
  notes: 'notes',
};

export const MAINTENANCE_UPDATE_MAP: Record<string, string> = {
  componentType: 'component_type',
  date: 'date',
  distanceAtReplacement: 'distance_at_replacement',
  cost: 'cost',
  notes: 'notes',
  partName: 'part_name',
};
