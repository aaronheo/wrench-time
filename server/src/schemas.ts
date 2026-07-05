import { z } from 'zod';

// Request body validation. Field names match the Swift model properties
// (camelCase). Dates arrive as ISO 8601 strings.

export const bikeCreate = z.object({
  id: z.string().uuid().optional(),
  name: z.string().min(1),
  brandName: z.string().default(''),
  modelName: z.string().default(''),
  stravaGearId: z.string().nullable().optional(),
  brakeType: z.enum(['disc', 'rim']).default('disc'),
  totalDistanceMeters: z.number().nonnegative().default(0),
  isPrimary: z.boolean().default(false),
  isWaxedChain: z.boolean().default(false),
  lastWaxedAtMeters: z.number().nonnegative().default(0),
  dateAdded: z.string().datetime().optional(),
  lastSyncDate: z.string().datetime().nullable().optional(),
});

export const bikeUpdate = z
  .object({
    name: z.string().min(1),
    brandName: z.string(),
    modelName: z.string(),
    stravaGearId: z.string().nullable(),
    brakeType: z.enum(['disc', 'rim']),
    totalDistanceMeters: z.number().nonnegative(),
    isPrimary: z.boolean(),
    isWaxedChain: z.boolean(),
    lastWaxedAtMeters: z.number().nonnegative(),
    dateAdded: z.string().datetime(),
    lastSyncDate: z.string().datetime().nullable(),
  })
  .partial()
  .strict();

export const componentCreate = z.object({
  id: z.string().uuid().optional(),
  type: z.string().min(1),
  name: z.string().min(1),
  installedDate: z.string().datetime().optional(),
  distanceAtInstall: z.number().nonnegative().default(0),
  replacementThresholdMiles: z.number().positive(),
  notes: z.string().default(''),
});

export const componentUpdate = z
  .object({
    type: z.string().min(1),
    name: z.string().min(1),
    installedDate: z.string().datetime(),
    distanceAtInstall: z.number().nonnegative(),
    replacementThresholdMiles: z.number().positive(),
    notes: z.string(),
  })
  .partial()
  .strict();

export const maintenanceCreate = z.object({
  id: z.string().uuid().optional(),
  componentType: z.string().min(1),
  date: z.string().datetime().optional(),
  distanceAtReplacement: z.number().nonnegative().default(0),
  cost: z.number().nonnegative().nullable().optional(),
  notes: z.string().default(''),
  partName: z.string().default(''),
});

export const maintenanceUpdate = z
  .object({
    componentType: z.string().min(1),
    date: z.string().datetime(),
    distanceAtReplacement: z.number().nonnegative(),
    cost: z.number().nonnegative().nullable(),
    notes: z.string(),
    partName: z.string(),
  })
  .partial()
  .strict();

export const rideCreate = z.object({
  id: z.string().uuid().optional(),
  syncDate: z.string().datetime().optional(),
  bikeStravaGearId: z.string().min(1),
  previousDistanceMeters: z.number().nonnegative(),
  newDistanceMeters: z.number().nonnegative(),
  deltaMeters: z.number().optional(),
});

export const settingsUpsert = z
  .object({
    isPremium: z.boolean(),
    stravaConnected: z.boolean(),
    stravaAthleteId: z.number().int().nullable(),
    distanceUnit: z.enum(['miles', 'kilometers']),
    notificationsEnabled: z.boolean(),
    lastFullSyncDate: z.string().datetime().nullable(),
    maxFreeBikes: z.number().int().nonnegative(),
  })
  .partial()
  .strict();
