# POSify — Project Context & Business Rules

Dokumen ini wajib dibaca sebelum menulis kode apapun di proyek ini. Tujuannya agar AI tidak mengarang field, relasi, atau logika bisnis yang tidak sesuai dengan sistem yang sudah ada.

---

## 1. Gambaran Produk

**POSify** adalah aplikasi Point of Sale (POS) SaaS *offline-first* untuk UMKM Indonesia.

- **Mobile App**: Flutter + Riverpod + Drift ORM (SQLite) → target Android APK
- **Backend API**: Go (Fiber) + GORM + PostgreSQL → license server
- **Cloud Sync (Tier 2/Pro)**: Supabase (Direct Sync + Realtime)
- **Web Dashboard**: Next.js di repo `lumiopos-web` (terpisah)

Model bisnis: **Lifetime License (Tier 1 Lite)** dan **Subscription (Tier 2 Pro)**.

---

## 2. Tier & Batasan

| Fitur | Lite (Lifetime) | Pro (Subscription) |
|---|---|---|
| Outlet | 1 | Hingga 3 |
| Perangkat | 1 (device fingerprint) | Multi-device |
| Sync | Tidak ada | Supabase cloud sync |
| Backup | Manual/Auto lokal (AES-256) | Otomatis cloud |
| Offline limit | 7 hari tanpa heartbeat → hard block | N/A |

---

## 3. Arsitektur Database

### 3.1 SQLite (Drift ORM) — Mobile, Offline-First

Semua tabel di SQLite menggunakan:
- `id`: `TEXT` (UUID v7)
- Tanggal: `TEXT` format ISO 8601
- `is_dirty`: `BOOLEAN` — flag untuk cloud sync (Tier 2)
- `deleted_at`: `TEXT` nullable — soft delete

### 3.2 PostgreSQL (GORM) — Backend Go

Hanya untuk: `users`, `licenses`, `devices`.

### 3.3 Supabase (PostgreSQL) — Cloud Sync Tier 2

Simetris dengan schema SQLite. Lihat `supabase_schema.sql`.

---

## 4. Tabel & Field Lengkap (SQLite)

### `outlets`
```
id, name, address?, phone?, created_at, updated_at, is_dirty, deleted_at?
```

### `users` (Backend PostgreSQL only)
```
id, email, password_hash (bcrypt), created_at, deleted_at?
```

### `licenses`
```
id, user_id (FK→users), license_code (unik, 10-digit alfanumerik),
device_fingerprint (unik), activation_date, last_verified?,
status (active/suspended), updated_at, is_dirty, deleted_at?,
tier_level (lite/pro), max_devices, max_outlets
```

### `employees`
```
id, outlet_id? (FK→outlets), name, pin (6 digit, UNIQUE),
role (owner/supervisor/cashier), failed_login_attempts (default 0),
locked_until?, status (active/inactive), photo_uri?,
created_at, updated_at, is_dirty, deleted_at?
```
- PIN dikunci sementara setelah 5x gagal login
- Role hierarki: owner (L1) > supervisor (L2) > cashier (L3)

### `store_profile`
```
id, name, address?, phone?, logo_uri?,
tax_percentage (0-100), tax_type (inclusive/exclusive),
service_charge_percentage (0-100),
loyalty_point_conversion (Rp per 1 poin),
loyalty_point_value (Rp per 1 poin redeem),
deduct_stock_on_hold (boolean), updated_at, is_dirty, deleted_at?
```
- Hanya 1 baris di tabel ini

### `categories`
```
id, outlet_id?, name (UNIQUE), created_at, updated_at, is_dirty, deleted_at?
```

### `products`
```
id, outlet_id?, category_id (FK→categories), name, sku (UNIQUE, barcode),
price (harga jual, INTEGER Rp), purchase_price (HPP retail, INTEGER Rp),
has_variants (boolean, default false), stock (INTEGER),
low_stock_threshold (default 0), image_uri?,
created_at, updated_at, is_dirty, deleted_at?
```
- Jika `has_variants = true`, stok & harga diambil dari `product_variants`
- SKU: alphanumeric 3-30 karakter, wajib unik

### `product_variants`
```
id, product_id (FK→products), name (contoh: "Ukuran"),
option_value (contoh: "L", "XL"), sku?, price?, stock,
created_at, updated_at, is_dirty, deleted_at?
```

### `customers`
```
id, name, phone? (unik jika ada), email?, address?,
is_member (default true), points (INTEGER, default 0),
created_at, updated_at, is_dirty, deleted_at?
```

### `suppliers`
```
id, outlet_id?, name, phone?, address?,
created_at, updated_at, is_dirty, deleted_at?
```

### `shifts`
```
id, outlet_id?, employee_id (FK→employees),
start_time, end_time?, starting_cash (modal laci),
expected_ending_cash (estimasi sistem), actual_ending_cash (fisik),
status (open/closed), created_at, updated_at, is_dirty, deleted_at?
```
- Transaksi hanya bisa dibuat saat shift `open`

### `transactions`
```
id, outlet_id?, receipt_number (UNIQUE, format: POS-YYYYMMDD-HHMMSS, nullable saat draft),
shift_id (FK→shifts), customer_id? (FK→customers),
subtotal, tax_amount, service_charge_amount, total_amount,
payment_method (cash/qris/debit/credit/bon/mixed),
payment_status (paid/void/pending),
void_by? (FK→employees, wajib diisi jika void, harus L1/L2),
discount_id? (FK→discounts), discount_amount,
points_earned, points_redeemed,
notes?, customer_name (snapshot), customer_phone (snapshot),
created_at, updated_at, is_dirty, deleted_at?
```

### `transaction_payments` (Split Payment)
```
id, outlet_id?, transaction_id (FK→transactions),
method (tunai/qris/debit/kredit), amount, change_given (kembalian),
created_at, updated_at, is_dirty, deleted_at?
```
- Maksimal 4 metode per transaksi
- Kasbon/bon TIDAK boleh dalam split payment
- Kembalian hanya untuk metode tunai

### `transaction_items`
```
id, outlet_id?, transaction_id (FK→transactions),
product_id (FK→products), variant_id? (FK→product_variants),
variant_name (snapshot), quantity, price_at_transaction (snapshot harga),
subtotal (qty × price), discount_id?, discount_amount,
created_at, updated_at, is_dirty, deleted_at?
```

### `discounts`
```
id, outlet_id?, name, scope (transaction/item), type (fixed/percentage),
value (REAL), min_spend (INTEGER Rp), min_qty (INTEGER),
is_automatic (boolean), is_stackable (boolean), is_active (boolean),
start_date, end_date?, created_at, updated_at, is_dirty, deleted_at?
```

### `expenses`
```
id, outlet_id?, category_id (FK→expense_categories), shift_id?,
recorded_by (FK→employees), amount (INTEGER Rp), note?, photo_uri?,
created_at, updated_at, is_dirty, deleted_at?
```

### `expense_categories`
```
id, name (UNIQUE), icon, color (hex), is_default (boolean),
created_at, updated_at, is_dirty, deleted_at?
```

### `ingredients`
```
id, outlet_id?, name, unit (gr/ml/pcs), stock_quantity (REAL),
min_stock_threshold (REAL), average_cost (REAL, weighted average HPP),
last_supplier_id? (FK→suppliers),
created_at, updated_at, is_dirty, deleted_at?
```

### `product_recipes`
```
id, outlet_id?, product_id (FK→products), ingredient_id (FK→ingredients),
quantity_needed (REAL, jumlah per 1 porsi),
created_at, updated_at, is_dirty, deleted_at?
```

### `ingredient_stock_history`
```
id, ingredient_id (FK→ingredients), supplier_id?,
type (SALE/PURCHASE/ADJUST/WASTE), quantity_change (REAL, +/-),
previous_balance (REAL), new_balance (REAL),
reference_id (no nota/batch), reason,
created_at, updated_at, is_dirty, deleted_at?
```

### `stock_transactions`
```
id, outlet_id?, product_id (FK→products), variant_id?,
supplier_id?, type (IN/OUT/ADJUST/SALE),
quantity, previous_stock, new_stock, reason, reference (no invoice),
created_at, updated_at, is_dirty, deleted_at?
```

### `stock_opname`
```
id, outlet_id?, opname_number, type (PRODUCT/INGREDIENT),
status (DRAFT/COMPLETED), created_by (employee_id),
notes, variance_reason, created_at, updated_at, is_dirty, deleted_at?
```

### `stock_opname_items`
```
id, outlet_id?, stock_opname_id (FK→stock_opname),
product_id?, variant_id?, ingredient_id?,
system_stock (REAL), physical_stock (REAL), variance (REAL),
variance_reason, created_at, updated_at, is_dirty, deleted_at?
```

### `purchase_orders`
```
id, supplier_id (FK→suppliers), status (draft/sent/received/cancelled),
total_estimate (INTEGER Rp), notes, ordered_at,
created_at, updated_at, is_dirty, deleted_at?
```

### `purchase_order_items`
```
id, purchase_order_id (FK→purchase_orders),
product_id?, ingredient_id?, item_name (snapshot), unit (snapshot),
quantity (REAL), purchase_price (INTEGER), received_quantity (REAL),
created_at, updated_at, is_dirty, deleted_at?
```

### `unit_conversions`
```
id, outlet_id?, from_unit, to_unit, multiplier (REAL),
notes, created_at, updated_at, is_dirty, deleted_at?
```

### `printer_settings`
```
id, device_name, mac_address, status (paired/last_connected),
auto_print (boolean, default false), updated_at, is_dirty, deleted_at?
```

---

## 5. Logika Bisnis Kritis

### Perhitungan Total Transaksi
```
subtotal = sum(transaction_items.subtotal)
tax_amount = subtotal × (tax_percentage / 100)  [jika exclusive]
           = total × tax_percentage / (100 + tax_percentage)  [jika inclusive]
service_charge_amount = subtotal × (service_charge_percentage / 100)
total_amount = subtotal + tax_amount + service_charge_amount - discount_amount
```

### Gross Profit (Laba Kotor)
- **Produk dengan resep**: `Laba = harga_jual - (qty_bahan × average_cost)`
- **Produk retail**: `Laba = harga_jual - purchase_price`

### Loyalty Points
- Earn: `points = floor(total_amount / loyalty_point_conversion)`
- Redeem: `diskon_rp = points_redeemed × loyalty_point_value`

### Auto-Stock Deduction (saat checkout)
Saat transaksi `paid`:
1. Cek apakah produk punya resep di `product_recipes`
2. Jika ya → kurangi `ingredients.stock_quantity` sesuai `quantity_needed × qty_item`
3. Jika tidak → kurangi `products.stock` atau `product_variants.stock`
4. Catat ke `stock_transactions` (type: SALE) dan `ingredient_stock_history` (type: SALE)

### Weighted Average Cost (HPP Bahan Baku)
Saat stock in bahan baku:
```
new_avg_cost = (current_stock × current_avg_cost + qty_in × purchase_price) / (current_stock + qty_in)
```

### Void Transaksi
- Hanya bisa dilakukan oleh role `owner` (L1) atau `supervisor` (L2)
- Field `void_by` wajib diisi dengan `employee_id` yang melakukan void
- Status berubah ke `void`, stok dikembalikan

---

## 6. Aturan Validasi

| Field | Aturan |
|---|---|
| `products.name` | String, 3-100 karakter, wajib |
| `products.sku` | Alphanumeric, 3-30 karakter, UNIQUE |
| `employees.pin` | Tepat 6 digit numerik, UNIQUE, tidak boleh pola umum (123456, 000000) |
| `employees.role` | Enum: owner / supervisor / cashier |
| `categories.name` | Max 50 karakter, UNIQUE |
| `store_profile.name` | Max 50 karakter, wajib |
| `transactions.receipt_number` | Format: `POS-YYYYMMDD-HHMMSS` |
| `licenses.license_code` | 10 karakter alfanumerik |
| `ingredients.unit` | Enum: gr / ml / pcs |
| `discounts.scope` | Enum: transaction / item |
| `discounts.type` | Enum: fixed / percentage |
| `shifts.status` | Enum: open / closed |
| `transactions.payment_status` | Enum: paid / void / pending |
| `purchase_orders.status` | Enum: draft / sent / received / cancelled |

---

## 7. Tech Stack

### Mobile (Flutter)
- State management: **Riverpod ^3.2.1**
- Database: **Drift ORM ^2.32.0** (SQLite)
- HTTP: **Dio**
- Target: Android APK (Android 10+, RAM min 3GB)

### Backend (Go)
- Framework: **Go Fiber**
- ORM: **GORM**
- Database: **PostgreSQL** (licenses & users)
- Rate limiting: 5 req/menit per IP pada `/activate`

### Cloud (Supabase)
- Auth: Supabase Auth
- Database: PostgreSQL (simetris dengan SQLite schema)
- Realtime: Supabase Realtime Channel
- Tabel realtime-enabled: `products`, `categories`, `transactions`, `product_variants`, `shifts`, `customers`

---

## 8. API Backend (Go Fiber)

Base URL: `https://api.posify.example.com/v1`

| Method | Endpoint | Deskripsi |
|---|---|---|
| POST | `/api/v1/license/activate` | Aktivasi lisensi + bind device fingerprint |
| POST | `/api/v1/license/verify` | Heartbeat cek status lisensi |
| POST | `/api/v1/license/reset` | Lepas device dari lisensi |
| POST | `/api/v1/license/devices` | List perangkat aktif |
| POST | `/api/v1/admin/license/generate` | Generate kode lisensi baru (admin only) |
| POST | `/api/v1/auth/register-with-license` | Registrasi akun + aktivasi lisensi |
| POST | `/api/v1/webhooks/tiktok` | Webhook marketplace |
| POST | `/api/v1/webhooks/shopee` | Webhook marketplace |
| POST | `/api/v1/webhooks/tokopedia` | Webhook marketplace |

Header wajib: `X-App-Client-Key` (semua endpoint) atau `X-Admin-Secret-Key` (admin endpoint).

---

## 9. Struktur Direktori

```
pos-umkm-saas/
├── backend/          # Go Fiber API
│   └── cmd/api/main.go
├── mobile/           # Flutter App
│   └── lib/
│       ├── core/database/tables/   # Drift table definitions
│       └── ...
├── supabase/         # Supabase migrations
├── supabase_schema.sql
├── erd_posify.md     # ERD lengkap
├── prd_umkm.md       # PRD lengkap
└── api_spec.md       # API spec lengkap
```

---

## 10. Hal yang TIDAK Boleh Dilakukan

- Jangan buat field baru tanpa menambahkan `is_dirty` (untuk tabel yang sync ke cloud)
- Jangan gunakan `DateTime` langsung di Drift — gunakan `TEXT` ISO 8601 dengan converter
- Jangan izinkan kasbon/bon dalam split payment
- Jangan void transaksi tanpa `void_by` terisi
- Jangan buat transaksi di luar shift yang `open`
- Jangan hardcode format mata uang — selalu gunakan locale `id_ID`
- Jangan integrasikan payment gateway API (hanya pencatatan manual)


---

## 11. Struktur Flutter App (Mobile)

### Layer Architecture
```
mobile/lib/
├── main.dart                    # AppBootstrap entry point
├── core/
│   ├── constants/               # App-wide constants
│   ├── database/
│   │   ├── database.dart        # PosifyDatabase class (Drift)
│   │   ├── database.g.dart      # Generated — JANGAN edit manual
│   │   └── tables/              # Satu file per tabel Drift
│   ├── providers/               # Global Riverpod providers
│   ├── services/
│   │   ├── sync_service.dart    # Cloud sync logic (Supabase ↔ Drift)
│   │   └── realtime_service.dart
│   ├── theme/                   # App theme & colors
│   ├── utils/                   # Helper functions
│   └── widgets/                 # Shared widgets
└── features/
    ├── auth/                    # License activation, owner setup, PIN login
    ├── pos/                     # Kasir, cart, payment modal
    ├── inventory/               # Products, ingredients, recipes, stock
    ├── reports/                 # Sales analytics, shift reports
    ├── settings/                # Employees, customers, suppliers, categories
    └── dashboard/               # Owner analytics dashboard
```

### App Bootstrap Flow
```
main.dart → AppBootstrap:
1. Initialize Supabase session
2. Load local license (SQLite) → kosong? → LicenseActivationScreen
3. Load local owner → kosong? → OwnerSetupScreen
4. Employee PIN selection → PinLoginScreen
5. PosDashboardScreen
```

### Tabel Drift yang Sudah Ada
Semua file ada di `mobile/lib/core/database/tables/`:
- `categories_table.dart`, `customers_table.dart`, `discounts_table.dart`
- `employees_table.dart`, `expenses_table.dart`
- `ingredient_stock_history_table.dart`, `ingredients_table.dart`
- `licenses_table.dart`, `outlets_table.dart`, `printer_settings_table.dart`
- `product_recipes_table.dart`, `product_variants_table.dart`, `products_table.dart`
- `purchase_orders_table.dart`, `shifts_table.dart`
- `stock_opname_items_table.dart`, `stock_opname_table.dart`, `stock_transactions_table.dart`
- `store_profile_table.dart`, `suppliers_table.dart`
- `transaction_items_table.dart`, `transaction_payments_table.dart`, `transactions_table.dart`
- `unit_conversions_table.dart`

### Flutter Dependencies (pubspec.yaml)
```yaml
drift: ^2.32.0                  # ORM SQLite
sqlcipher_flutter_libs: ^0.6.0  # Enkripsi SQLite
flutter_riverpod: ^3.2.1        # State management
riverpod_annotation: ^4.0.2     # Code gen Riverpod
dio: ^5.9.2                     # HTTP client
supabase_flutter: ^2.8.4        # Supabase SDK
intl: ^0.20.2                   # Locale id_ID
fl_chart: ^0.68.0               # Charts
blue_thermal_printer: ^1.2.3    # ESC/POS printing
mobile_scanner: ^6.0.0          # Barcode scanner
file_picker: ^10.3.10           # CSV import
csv: ^7.2.0                     # CSV parser
image_picker: ^1.2.1            # Foto produk
flutter_secure_storage: ^9.2.2  # Token storage
device_info_plus: ^11.2.2       # Device fingerprint
share_plus: ^10.1.4             # WhatsApp sharing
screenshot: ^3.0.0              # Struk digital
app_links: ^7.0.0               # Deep link
uuid: ^4.5.3                    # UUID generation
google_fonts: ^8.0.2            # Typography
```

### Konvensi Kode Flutter
- State management: **Riverpod** dengan `@riverpod` annotation
- Setiap fitur punya folder sendiri di `features/` dengan struktur: `screens/`, `widgets/`, `providers/`
- Tabel Drift baru: buat file di `tables/`, daftarkan di `database.dart`, jalankan `build_runner`
- Tanggal di Drift: gunakan `TextColumn` dengan format ISO 8601, bukan `DateTimeColumn`
- UUID: gunakan package `uuid` dengan `Uuid().v7()`
- Format Rupiah: gunakan `intl` dengan `NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ')`

---

## 12. Backend Go — Struktur Internal

```
backend/
├── cmd/api/main.go              # Entry point (port 8080)
├── internal/
│   ├── auth/                    # Unified registration/login
│   │   ├── domain.go            # Request/response structs
│   │   ├── repository.go        # DB operations
│   │   ├── default_service.go   # Business logic
│   │   └── handler.go           # HTTP handlers & routes
│   ├── license/                 # License activation/verification
│   │   ├── domain.go
│   │   ├── repository.go
│   │   ├── default_service.go
│   │   └── handler.go
│   ├── fulfillment/             # Marketplace webhooks
│   ├── middleware/              # API key validation, rate limiting
│   └── models/                  # GORM models
│       # License, User, Employee, Outlet, MappingSKU
└── seeding.go                   # Seed test license
```

### GORM Models (Backend PostgreSQL)
- `License`: id, user_id, license_code, device_fingerprint, tier_level, max_devices, max_outlets, status
- `User`: id, email, password_hash
- `MappingSKU`: mapping produk marketplace ke lisensi POSify

### Tier Limits (Enforced di Backend)
| Tier | Max Devices | Max Outlets | Max Employees |
|---|---|---|---|
| Lite | 1 | 1 | 3 |
| Pro | 10 | 3 | Unlimited |

### Development Commands
```bash
# Backend
cd backend
go mod tidy
go run seeding.go          # Buat test license: POS-L1-A8F9K2-X1Y2Z3
go run cmd/api/main.go     # Start server port 8080
go test ./...              # Run tests

# Mobile
cd mobile
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs  # Setelah ubah schema
flutter run
flutter test

# Reset license (dev)
sqlite3 backend/posify-license.db "UPDATE licenses SET device_fingerprint = NULL, activation_date = NULL WHERE license_code = 'POS-L1-A8F9K2-X1Y2Z3';"
```

---

## 13. Status Fitur (Roadmap)

### Sudah Selesai ✅
- License activation & device fingerprinting
- Unified registration (email + license dalam 1 langkah)
- Marketplace webhooks (TikTok, Shopee, Tokopedia)
- Auto email lisensi via Resend
- UUID migration (semua PK pakai UUID v7)
- Outlet mapping & soft-delete
- Cloud sync (Supabase Realtime ↔ Drift)
- Split payment (maks 4 metode)
- Save Bill / Hold transaction
- Transaction notes
- Recipe & ingredient management + auto-stock deduction
- COGS/HPP tracking (weighted moving average)
- Stock opname
- Unit of measure conversion
- Loyalty & membership (poin)
- Discount & voucher engine
- Purchase Order (PO) flow
- Expense management
- Sales analytics dashboard
- CSV import produk
- Bluetooth thermal printing (ESC/POS)
- WhatsApp receipt sharing

### Sedang / Belum Dikerjakan 🔜
- Split Bill (pecah tagihan per item — beda dari split payment)
- In-app Pro subscription upgrade (Midtrans/Xendit)
- Device Management UI (lepas perangkat dari lisensi)
- Stock transfer antar outlet
- F&B Table Management (denah meja)
- Kitchen Display System (KDS)
- Debt/Piutang management
- Push notifications (FCM) untuk low stock
- Batch/expiry tracking
- Receipt customization (footer, social media)
