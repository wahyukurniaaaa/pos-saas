# Rencana Implementasi: Discount & Voucher Management

Modul ini memungkinkan pemilik toko untuk membuat promo/diskon yang dapat diterapkan pada total transaksi (Checkout) atau pada item spesifik (Item Level). Mendukung diskon nominal (Rp) dan persentase (%), dengan validasi tanggal aktif dan minimal belanja.

## 📱 Project Type: MOBILE (Flutter)

## 🎯 Success Criteria
- [x] CRUD Diskon: Bisa menambah, mengedit, dan menghapus promo.
- [x] Tipe Diskon: Mendukung Rupiah (Fixed) dan Persen (Percentage).
- [ ] Logika Otomatis: Diskon dapat diterapkan **otomatis** jika syarat terpenuhi (misal: "Happy Hour" atau "Promo Jumat").
- [x] Stackable Logic: Mengatur apakah diskon item bisa digabung dengan diskon bill (**Stackable** vs **Exclusive**).
- [x] Validasi Bisnis: Diskon hanya bisa digunakan jika dalam **Periode Aktif** dan memenuhi **Minimal Belanja** (Bill) atau **Minimal Quantity** (Item).
- [x] Integrasi POS: Kasir melihat tag "Promo Terpasang" secara otomatis atau memilih voucher manual.
- [x] Record Database: Nilai diskon tersimpan detail di `Transactions` dan `TransactionItems`.

## 🛠 Tech Stack
- **Database**: Drift (SQLite)
- **State Management**: Riverpod
- **Theme**: `AppTheme` (Navy/Yellow)

## 📁 File Structure
- `mobile/lib/core/database/tables/discounts_table.dart` (Skema baru)
- `mobile/lib/features/pos/providers/discount_provider.dart` (Logika CRUD & Filter validitas)
- `mobile/lib/features/pos/screens/settings/discount_management_screen.dart` (UI Setup promo)
- `mobile/lib/features/pos/screens/payment/discount_selection_sheet.dart` (UI Pilih diskon saat bayar)

## 📝 Task Breakdown

### Phase 1: Foundation (Database)
- [x] **Task 1.1**: Create `discounts` table.
  - Fields: `id`, `name`, `scope` (transaction/item), `type` (fixed/percentage), `value`, `min_spend`, `min_qty`, `is_automatic`, `is_stackable`, `start_date`, `end_date`, `is_active`, `created_at`.
  - **Agent**: `mobile-developer` | **Skill**: `database-design`
  - **Verify**: File created at `mobile/lib/core/database/tables/discounts_table.dart`.
- [x] **Task 1.2**: Update `transactions` & `transaction_items` table with discount fields.
  - `transactions`: Add `discount_id` (nullable FK), `discount_amount` (int).
  - `transaction_items`: Add `discount_id` (nullable FK), `discount_amount` (int).
  - **Agent**: `mobile-developer` | **Skill**: `database-design`
  - **Verify**: Run `flutter pub run build_runner build`.

### Phase 2: Logic (Providers)
- [x] **Task 2.1**: Implement CRUD queries in `database.dart`.
  - Methods: `getAllDiscounts`, `upsertDiscount`, `deleteDiscount`, `getActiveDiscounts`.
  - **Agent**: `mobile-developer` | **Skill**: `api-patterns`
- [x] **Task 2.2**: Create `discount_provider.dart` using `AsyncNotifier`.
  - Include logic to filter valid discounts based on current date & total amount.
  - **Agent**: `mobile-developer` | **Skill**: `clean-code`

### Phase 3: UI (Management)
- [x] **Task 3.1**: Create `DiscountManagementScreen` in Settings.
  - CRUD UI with Navy/Yellow theme. Form with validation (Min Spend, Dates).
  - **Agent**: `mobile-developer` | **Skill**: `frontend-design`
- [x] **Task 3.2**: Add entry point in Dashboard/Settings.
  - **Agent**: `mobile-developer` | **Skill**: `frontend-design`

### Phase 4: POS Integration
- [x] **Task 4.1**: Update POS Checkout to include "Pilih Promo" (Bill Discount).
  - Show selectable list of valid vouchers from `ACTIVE` transaction-scoped discounts.
- [ ] **Task 4.2**: Update Item Detail (Cart) to include "Diskon Item".
  - Allow picking an item-scoped discount or manual amount for a specific product in the cart.
- [x] **Task 4.3**: Recalculate transaction total after discount application.
  - Ensure logic: Total = Σ(ItemSubtotal - ItemDiscount) + Tax + Service - BillDiscount.
  - **Agent**: `mobile-developer` | **Skill**: `clean-code`

## ✅ Phase X: Verification
- [ ] Jalankan `security_scan.py` untuk cek data sensitif.
- [ ] Verifikasi kontras warna di layar baru (No Purple Rule).
- [ ] Test Flow: Buat diskon 10% (Min belanja 50k) -> Tambah item 60k -> Pilih diskon -> Cek total akhir.
- [ ] Verifikasi record transaksi di SQLite (Kartu Transaksi menunjukkan diskon yang terpakai).
