# AGENTS.md

## Project Structure

Two independent packages in one repo:
- `mobile/` — Flutter app (offline-first POS, app name "Lumio")
- `backend/` — Go Fiber API server

## Flutter App

**Install & run:**
```bash
cd mobile && flutter pub get && flutter run
```

**Critical: Drift codegen after ANY schema change**
```bashx
flutter pub run build_runner build --delete-conflicting-outputs
```
Then regenerate `database.g.dart`. If you skip this, the app will crash or misbehave.

**Android emulator networking:** Use `10.0.2.2` instead of `localhost` for the backend URL. Real devices use your machine's LAN IP.

**Key dependencies:** Drift (SQLite ORM), Riverpod, Supabase Flutter, flutter_secure_storage, device_info_plus

## Go Backend

**Install & run:**
```bash
cd backend && go mod tidy && go run cmd/api/main.go
```
Server starts on port `8080`.

**Seeding:**
```bash
cd backend && go run seeding.go
```

**Test license for dev:** `POS-L1-A8F9K2-X1Y2Z3`

**Reset a used license:**
```bash
sqlite3 backend/posify-license.db "UPDATE licenses SET device_fingerprint = NULL, activation_date = NULL WHERE license_code = 'POS-L1-A8F9K2-X1Y2Z3';"
```

## Testing

**Flutter:** `cd mobile && flutter test` (unit tests in `mobile/test/unit/`)

**Go:** `cd backend && go test ./...`

No separate lint/typecheck commands are configured — `flutter test` runs analysis as part of the test runner.

## Environment Variables

**NEVER commit `.env` files.** Copy `.env.example` to `.env` for both `mobile/` and `backend/`.

Mobile `.env` required keys: `BASE_URL`, `APP_CLIENT_KEY`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GOOGLE_WEB_CLIENT_ID`

Backend `.env` required keys: `PORT`, `DATABASE_URL` (or individual DB params), `APP_CLIENT_KEY`, `ADMIN_SECRET_KEY`

## Architecture Notes

- License is device-bound via fingerprint. Reinstalling emulator/device invalidates the license — use the SQLite reset command above.
- Backend uses local SQLite (`posify-license.db`) for license management; Supabase PostgreSQL for user data and sync.
- Sync flows: Supabase Realtime → SyncService → Drift SQLite (mobile).
- Drift schema version is tracked in `database.dart`. Migrations handled via `onUpgrade`.

## CI/CD

Backend deploys automatically on push to `main`/`master` (Docker build + Easypanel webhook trigger). See `.github/workflows/deploy-backend.yml`.
