# AssetVault

Enterprise IT asset management built on Xano. Backend is XanoScript you push to your own Xano instance; frontend is a single-file HTML app that asks for your instance's base URL the first time it loads.

Assets (laptops, monitors, phones, servers, network gear) are tagged, categorized, located, and optionally assigned to users. Every assignment is logged with `assigned_at` / `returned_at`, so you get a full custody chain per device. Maintenance events (repairs, upgrades, cost) are logged per asset.

## Repo layout

```
backend/            # XanoScript — push to your Xano workspace
  workspace/
  table/            # user, av_asset, av_category, av_location,
                    # av_assignment, av_maintenance_log
  api/
    enterprise_auth/  # signup, login, me, users
    assetvault/       # assets, categories, locations, stats, seed
frontend/
  index.html        # single-file static app
```

## Quick start

### 1. Push the backend to your Xano instance

```bash
npm install -g @xano/cli
xano profile:wizard

cd backend
xano workspace:push
```

This creates 6 tables and two API groups (`EnterpriseAuth` and `AssetVault`) in your workspace.

### 2. Seed demo data

```bash
curl -X POST https://YOUR-INSTANCE.n7d.xano.io/api:assetvault/seed \
  -d '{}' -H 'Content-Type: application/json'
```

Creates 8 users, 7 categories, 5 locations, 20 assets spanning laptops, phones, monitors, servers, network gear — with realistic statuses (available, assigned, in_repair, retired) and active assignments linking assets to users. All seeded users share password `DemoPass1` (emails `alice.johnson@acme.enterprise` through `henry.tanaka@acme.enterprise`). Idempotent.

### 3. Run the frontend

```bash
cd frontend
python3 -m http.server 8000
# open http://localhost:8000
```

On first load the page asks for your **Xano base URL** (e.g. `https://xxsw-1d5c-nopq.n7d.xano.io`). Stored in `localStorage`; reconfigure any time.

## What the frontend can do

- Browse assets with filters for status, category, location, and name search
- Drill into an asset to see current assignee, full assignment history, and maintenance log
- **Assign** an available asset to a user (creates an `av_assignment` row and flips the asset's status to `assigned`)
- **Return** an assigned asset (closes the open assignment row and flips status back to `available`)
- Log a maintenance event with a cost
- Dashboard counts (total / available / assigned / in_repair / retired)

## API surface

All endpoints except `/seed` require `Authorization: Bearer <token>`.

```
POST   /api:enterprise-auth/signup         { name, email, password }
POST   /api:enterprise-auth/login          { email, password }
GET    /api:enterprise-auth/me
GET    /api:enterprise-auth/users

POST   /api:assetvault/seed
GET    /api:assetvault/assets              ?status&category_id&location_id&assigned_to&q&page&per_page
POST   /api:assetvault/assets
GET    /api:assetvault/assets/{id}
PATCH  /api:assetvault/assets/{id}
POST   /api:assetvault/assets/{id}/assign  { user_id, notes? }
POST   /api:assetvault/assets/{id}/return  { notes? }
GET    /api:assetvault/assets/{id}/assignments
GET    /api:assetvault/assets/{id}/maintenance
POST   /api:assetvault/assets/{id}/maintenance  { description, cost? }
GET    /api:assetvault/categories
GET    /api:assetvault/locations
GET    /api:assetvault/stats/dashboard
```

## Schema

- **`user`** — id, name, email (unique), password, created_at — shared auth table with `auth = true`
- **`av_asset`** — id, asset_tag (unique), name, manufacturer, model, serial_number, status, category_id, location_id, assigned_to → user, purchase_date, purchase_cost
- **`av_category`** — id, name (unique), description
- **`av_location`** — id, name (unique), address, city, country
- **`av_assignment`** — id, asset_id, user_id, assigned_at, returned_at, notes
- **`av_maintenance_log`** — id, asset_id, performed_by → user, description, cost, performed_at

## License

MIT.
