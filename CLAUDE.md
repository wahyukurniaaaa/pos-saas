# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

POSify is a Point of Sale SaaS platform designed for Indonesian small-medium businesses (UMKM). The system consists of:
- **Flutter mobile client** - Main POS application with offline-first capabilities
- **Go Fiber backend** - License/subscription management and fulfillment
- **Supabase** - Cloud synchronization and PostgreSQL database
- **License tiers**: Lite (1 device, 1 outlet) and Pro (10 devices, 3 outlets)

## Common Development Commands

### Backend Development (Go)
```bash
cd backend
go mod tidy                    # Install dependencies

go run cmd/api/main.go         # Start backend server (default port: 8080)

go run seeding.go             # Seed database with test license

# Test license for development: POS-L1-A8F9K2-X1Y2Z3
```

### Mobile Development (Flutter)
```bash
cd mobile

flutter pub get              # Install dependencies

# Regenerate Drift database code after schema changes
flutter pub run build_runner build --delete-conflicting-outputs

flutter run                  # Run on device/emulator

# Android Emulator URL mapping: Use 10.0.2.2 for localhost
# Real device: Use your computer's local IP (192.168.x.x)
```

### Database & Sync
```bash
# Reset license (if reinstalling on emulator/device)
sqlite3 backend/posify-license.db "UPDATE licenses SET device_fingerprint = NULL, activation_date = NULL WHERE license_code = 'POS-L1-A8F9K2-X1Y2Z3';"

# View backend logs in realtime (when running go backend)
# Logs include activation attempts, API status, and sync operations
```

## Architecture Overview

### Mobile App Architecture

**App Bootstrap Flow** (`mobile/lib/main.dart:AppBootstrap`):
1. Initialize Supabase session
2. Load local license → if none → LicenseActivationScreen
3. Load local owner → if none → OwnerSetupScreen  
4. Employee PIN selection → PinLoginScreen
5. PosDashboardScreen for transactions

**Layer Architecture:**
- `core/` - Foundation classes and services
  - `database/` - Drift/SQLite schema and DAOs (local persistence)
  - `services/` - Sync, realtime, authentication
  - `providers/` - Global state with Riverpod
  
- `features/` - Feature modules with Riverpod providers
  - `auth/` - License activation, owner setup, employee login
  - `pos/` - Point of sale functionality (transactions, cart)
  - `inventory/` - Product management, categories, variants
  - `reports/` - Sales analytics, stock loss tracking
  - `settings/` - Employee, customer, supplier management
  - `dashboard/` - Owner dashboard with analytics

**Database Schema** (Drift, `mobile/lib/core/database/tables/`):
- Entity tables: employees, customers, suppliers, products, variants
- Transaction tables: shifts, transactions, transaction_items, transaction_payments
- Inventory tables: stock_transactions, ingredients, product_recipes, stock_opname
- Lookup tables: categories, discounts, unit_conversions
- Mapping tables: purchase_orders
- License: licenses, store_profiles

### Backend Architecture (Go)

**Main Entry** (`backend/cmd/api/main.go`):
- License verification API (Fiber routes with app/client key & admin middleware)
- Unified auth for Supabase accounts
- Fulfillment webhooks for Supabase

**Package Structure** (`backend/internal/`):
```
auth/         # Unified registration/login (license-based accounts)
license/      # License activation/verification, device limits
domain.go     # Request/response structs
repository.go # Database operations
default_service.go # Business logic, tier limits
handler.go    # HTTP handlers, routes

fulfillment/  # Webhook handlers for Supabase
middleware/   # API key validation, rate limiting
models/       # GORM models (License, User, Employee, Outlet, MappingSKU)
```

**Database**:
- Local SQLite for license management (`posify-license.db`)
- Supabase PostgreSQL for user data, sync tables

### Cloud Sync Architecture

**Sync Flow** (Supabase Realtime → Drift):
1. Supabase changes listened via Realtime
2. SyncService (`mobile/lib/core/services/sync_service.dart`) processes changes
3. Updates Drift SQLite with conflict resolution
4. Uploads local changes to Supabase

**Critical Sync Tables**:
- `employees` → Unified employee management
- `outlets` → Multi-outlet support
- `mapping_sku` → Product SKU mapping for sync
- `stock_opname` → Stock audits synced to cloud

## Important Technical Details

### License & Device Management
- Device fingerprint binds license to single device
- Reinstalling/modifying emulator changes fingerprint → must reset license
- API client key required via X-App-Client-Key header (env: `APP_CLIENT_KEY`)

### Database Versioning
- Drift schema version tracking in database.dart
- Schema migrations via `schemaVersion: X` and `onUpgrade` migration logic
- Always regenerate `.g.dart` files after schema changes

### Testing

**Flutter Tests** (`mobile/test/`):
- Unit tests for cart logic, discount calculations, session management
- Run tests: `flutter test`

**Go Tests** (`backend/internal/*_test.go`):
- Handler and service unit tests
- Run tests: `cd backend && go test ./...`

## Troubleshooting Guide

### Common Issues

1. **License already used (403)**
   - Device fingerprint changed → reset license in backend via SQLite command
   - Command: `sqlite3 backend/posify-license.db "UPDATE licenses SET device_fingerprint = NULL, activation_date = NULL WHERE license_code = 'POS-L1-A8F9K2-X1Y2Z3';"`

2. **Connection Refused during license activation**
   - Verify backend running: `go run cmd/api/main.go`
   - Check `.env` BASE_URL: Android Emulator → `10.0.2.2:3000`, Real device → computer IP

3. **Drift schema mismatches**
   - Delete `database.g.dart`, regenerate: `flutter pub run build_runner build --delete-conflicting-outputs`
   - Verify no conflicting table definitions

4. **Sync issues**
   - Check Supabase credentials in `.env`: `SUPABASE_URL`, `SUPABASE_ANON_KEY`
   - Verify network connectivity (sync requires internet until first sync)
   - Check SyncService log output for sync failures

## Domain Concepts

### Tier Limits
- **Lite**: 1 device, 1 outlet, 3 employees
- **Pro**: 10 devices, 3 outlets, unlimited employees
- Enforced at license activation and device registration

### Multi-Tenancy
- One license → one account → multiple venues/outlets
- Owner account has full privileges
- Employee accounts with domain prefixes (employee@account)

### Product Catalog
- Products have variants (sizes/colors)
- Variant-specific pricing and SKUs
- Ingredients linked to products (recipes) for inventory tracking
- Stock management at ingredient level for F&B use cases

## Security Considerations

- Sensitive data in `.env` (NEVER commit `.env` only `.env.example`)
- API keys: `APP_CLIENT_KEY`, `ADMIN_SECRET_KEY`, `SUPABASE_ANON_KEY`
- Device fingerprinting via `device_info_plus`
- Secure storage via `flutter_secure_storage` for auth tokens
- Transaction receipts use cloud storage only, not on-device

## Development Workflow

1. **New feature development**: Create plan in `/plans` folder (see existing examples)
2. **Schema changes**: Update tables in `mobile/lib/core/database/tables/`, regenerate Drift code
3. **Backend changes**: Update Go models, handlers, services with validation
4. **Testing**: Add unit tests for business logic, integration tests for sync
5. **PR**: Include API changes, schema changes, test results