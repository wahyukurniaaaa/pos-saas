# Rencana Implementasi: Expense (Kas Keluar) Management

Modul ini memungkinkan pemilik dan supervisor mencatat setiap pengeluaran operasional di luar transaksi penjualan — seperti belanja bahan, gaji harian, listrik, dan biaya tak terduga — langsung dari aplikasi kasir. Data ini terintegrasi ke laporan Arus Kas dan Laba Rugi otomatis.

## 📱 Project Type: MOBILE (Flutter)

## 🎯 Success Criteria
- [x] CRUD Pengeluaran: Catat, edit, dan hapus pengeluaran dengan nominal, kategori, dan catatan.
- [x] Kategori Pengeluaran: Bisa membuat kategori kustom (Bahan Baku, Gaji, Listrik, Operasional, Lain-lain).
- [x] Integrasi Shift: Pengeluaran yang dicatat saat shift berjalan terhubung ke shift tersebut untuk rekap laci.
- [ ] Batas Kas Keluar per Shift: Supervisor/Owner bisa atur budget maksimal per shift (fitur Moka/Majoo).
- [x] Laporan Arus Kas: Dashboard analitik menampilkan ringkasan Pendapatan vs Pengeluaran per hari/minggu/bulan.
- [ ] Lampiran Bukti (Opsional): Foto bon/struk dapat dilampirkan pada setiap entri.

## 🛠 Tech Stack
- **Database**: Drift (SQLite) — Migration v15
- **State Management**: Riverpod
- **Theme**: `AppTheme` (Navy/Yellow)

## 📁 File Structure
- `mobile/lib/core/database/tables/expenses_table.dart` (Skema baru)
- `mobile/lib/core/database/tables/expense_categories_table.dart` (Kategori kustom)
- `mobile/lib/features/pos/providers/expense_provider.dart` (CRUD & Analytics)
- `mobile/lib/features/pos/screens/settings/expense_management_screen.dart` (UI CRUD)
- `mobile/lib/features/dashboard/screens/cashflow_screen.dart` (Laporan Arus Kas)

## 📝 Task Breakdown

### Phase 1: Foundation (Database — Migration v15)
- [x] **Task 1.1**: Create `expense_categories` table.
  - Fields: `id`, `name`, `icon`, `color`, `is_default`, `created_at`.
  - Seed default categories: *Bahan Baku, Gaji, Listrik/Air, Operasional, Lain-lain*.
  - **Verify**: Migration v15 berhasil jalan tanpa error.
- [x] **Task 1.2**: Create `expenses` table.
  - Fields: `id`, `category_id` (FK), `shift_id` (FK, nullable), `amount`, `note`, `photo_uri` (nullable), `recorded_by` (employee_id FK), `created_at`.
  - **Verify**: `flutter pub run build_runner build` sukses.

### Phase 2: Logic (Providers)
- [x] **Task 2.1**: Implement CRUD queries in `database.dart`.
  - Methods: `getAllExpenses`, `getExpensesByShift`, `getExpensesByDateRange`, `upsertExpense`, `deleteExpense`.
  - **Agent**: `backend-specialist` | **Skill**: `database-design`
- [x] **Task 2.2**: Create `expense_provider.dart` (`AsyncNotifier`).
  - Include `dailyExpenseSummaryProvider` dan `cashFlowProvider` (Pendapatan - Pengeluaran per periode).
  - **Agent**: `mobile-developer` | **Skill**: `clean-code`

### Phase 3: UI (Management & Entry)
- [x] **Task 3.1**: Create `ExpenseManagementScreen`.
  - List pengeluaran per hari dengan filter tanggal. `FAB` untuk input cepat.
  - Form: Nominal, Pilih Kategori (chip), Catatan (opsional), Foto Bukti (opsional).
  - **Agent**: `mobile-developer` | **Skill**: `frontend-design`
- [x] **Task 3.2**: Create `ExpenseCategoryManagementScreen`.
  - Buat/edit/hapus kategori kustom + set icon & warna.
  - **Agent**: `mobile-developer` | **Skill**: `frontend-design`
- [x] **Task 3.3**: Add entry point di Dashboard (Kasir tab) — tombol "Kas Keluar" cepat.
  - Tersedia untuk role Kasir, Supervisor, dan Owner.
  - **Verify**: Tap tombol → form muncul, simpan → tampil di list harian.
- [x] **Task 3.4**: Add entry point di Owner Dashboard → menu Pengaturan.
  - Halaman rekap lengkap + manajemen kategori.

### Phase 4: Cashflow Analytics
- [x] **Task 4.1**: Create `CashFlowScreen` (Laporan Arus Kas).
  - Bar chart: Pendapatan (Penjualan) vs Pengeluaran per hari selama 7/30 hari.
  - Ringkasan: Laba Operasional = Total Penjualan - Total Pengeluaran.
  - **Agent**: `frontend-specialist` | **Skill**: `frontend-design`
- [x] **Task 4.2**: Integrasi ke Summary Shift.
  - Pada laporan "Tutup Shift", tampilkan total pengeluaran shift tersebut: `Kas Keluar: Rp X.XXX`.
  - **Verify**: Close shift → laporan shift menyertakan kolom Kas Keluar.

## ✅ Phase X: Verification
- [x] Test Flow: Buka shift → Input pengeluaran 50k (Listrik) → Tutup Shift → Rekap shift menampilkan Kas Keluar 50k.
- [x] Verifikasi Laporan Arus Kas: Total revenue shift - total expense = Laba Operasional yang akurat.
- [x] No Purple Rule check pada semua layar baru.
- [x] Jalankan `security_scan.py`.
