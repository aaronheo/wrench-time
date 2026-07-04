# WrenchTime API

Express + TypeScript backend for the WrenchTime iOS app and (future) web frontend.
Data lives in Supabase Postgres; auth is Supabase Auth (Google sign-in).

## Architecture

```
iOS app ─┐                                   ┌─ Supabase Postgres (data)
         ├─→ this Express API (on Render) ────┤
web app ─┘     verifies Supabase JWT          └─ Supabase Auth (Google login)
```

The clients sign in with Google via Supabase Auth, receive a JWT, and send it as
`Authorization: Bearer <jwt>`. This API verifies the JWT and scopes every query to
that user. The API — not the client — holds the Postgres connection string.

## Endpoints

All `/api/*` routes require a valid bearer token. Fields are camelCase.

| Method | Path | Description |
|--------|------|-------------|
| GET    | `/health` | Public health check |
| GET    | `/api/bikes` | List the user's bikes |
| POST   | `/api/bikes` | Create a bike |
| GET    | `/api/bikes/:id` | Bike + its components + maintenance records |
| PATCH  | `/api/bikes/:id` | Update a bike |
| DELETE | `/api/bikes/:id` | Delete a bike (cascades) |
| GET    | `/api/bikes/:bikeId/components` | List components on a bike |
| POST   | `/api/bikes/:bikeId/components` | Add a component to a bike |
| PATCH  | `/api/components/:id` | Update a component |
| DELETE | `/api/components/:id` | Delete a component |
| GET    | `/api/bikes/:bikeId/maintenance` | List maintenance records |
| POST   | `/api/bikes/:bikeId/maintenance` | Add a maintenance record |
| PATCH  | `/api/maintenance/:id` | Update a maintenance record |
| DELETE | `/api/maintenance/:id` | Delete a maintenance record |
| GET    | `/api/rides` | Sync history |
| POST   | `/api/rides` | Log a ride-sync event |
| GET    | `/api/settings` | Get user settings (defaults if none) |
| PUT    | `/api/settings` | Upsert user settings |

## Local development

```bash
cd server
npm install
cp .env.example .env   # then fill in DATABASE_URL and SUPABASE_URL
npm run dev            # tsx watch on http://localhost:8080
```

Get `DATABASE_URL` from Supabase Dashboard → Project Settings → Database →
Connection string → **Session pooler** (IPv4-compatible; required for Render).

## Deploy (Render)

The repo-root `render.yaml` is a Render Blueprint. Point Render at the GitHub repo;
it builds from `server/` (`npm install && npm run build`) and starts `npm start`.
Set `DATABASE_URL` in the Render dashboard (it is marked `sync: false`, so it is not
stored in the repo).

## Notes

- Computed values (`wearPercentage`, `isDue`, `currentMiles`, …) are derived by the
  clients, not stored.
- Client-supplied `id` is accepted on POST so on-device UUIDs stay stable when syncing.
- Row-Level Security is enabled on all tables as defense-in-depth; this API connects
  with a privileged role and enforces per-user scoping in every query.
