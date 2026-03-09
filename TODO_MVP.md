# POSify MVP - Remaining Work & Pending Tasks

Dokumen ini berisi daftar rinci fungsi dan tugas tersisa yang diperlukan untuk menyelesaikan **Minimum Viable Product (MVP) POSify**. Semua antarmuka utama sudah diintegrasikan, namun fitur-fitur berikut membutuhkan logika/package tambahan. Dokumen ini sengaja ditempatkan di root project agar mudah di-*commit* ke Git dan diakses dari laptop lain.

---

## 1. Analitik Penjualan (`sales_analytics_screen.dart`)
**Deskripsi:**
Layar dashboard yang dapat diakses Owner/Manager untuk melihat performa penjualan harian, bulanan, atau *custom range*.

**Kebutuhan Tambahan:**
- Package grafik, direkomendasikan `fl_chart` atau package chart lain yang disukai.
- Query database Drift agregasi data (misal: mencari `SUM(total_amount)` per hari atau per bulan).

**Scope of Work (SoW):**
- [ ] Buat layout UI dengan filter waktu (Hari ini, 7 Hari Terakhir, Bulan Ini).
- [ ] Buat fungsi pemanggilan API ke backend (jika online) atau hitung agregat lokal via *Drift* di kelas `PosifyDatabase`.
- [ ] Tampilkan Top 5 Produk Terlaris berdasarkan relasi di tabel `transaction_items` dan `products`.
- [ ] Tampilkan Line chart/Bar chart rekap penjualan.

---

## 2. Impor Produk via CSV (`import_product_screen.dart`)
**Deskripsi:**
Fitur ini mempermudah merchant yang memiliki ratusan produk untuk langsung melakukan *upload* data stok/katalog ke sistem secara massal ketimbang mengisi satu-persatu melalui form.

**Kebutuhan Tambahan:**
- Package file picker: `file_picker` (atau sejenis).
- Package parser CSV ke Dart map/list: `csv`.

**Scope of Work (SoW):**
- [ ] Implementasi UI BottomSheet atau Modal baru yang meminta akses *Storage/Files*.
- [ ] Meng-handle file CSV *parser* dan melakukan iterasi iterasi baris per baris.
- [ ] Menampilkan *Preview* data kepada user (cth: "Ditemukan 150 Produk. Yakin simpan?").
- [ ] Melakukan `insertMulty` atau looping *batch insert* ke dalam tabel `products` (Drift).
- [ ] Membuat error handling apabila format CSV gagal (kolom wajib kurang formanya, format harga teks/huruf, dsb).

---

## 3. Detail Struk Pembelian / Cetak Ulang (Receipt Detail)
**Deskripsi:**
### Features to Implement

- [x] **Sales Analytics**
    - [x] Dashboard report (Daily/Weekly/Monthly)
    - [x] Chart for sales trends (fl_chart)
    - [x] Top-selling products list
- [x] **Transaction History & Receipt Detail**
    - [x] List of past transactions
    - [x] Detailed receipt view with items
    - [x] Printing receipt functionality (blue_thermal_printer)
- [x] **VOID Transaction (Cancellation)**
    - [x] VOID button with supervisor authorization (PIN)
    - [x] Return stock automatically when VOIDed
- [x] **Import Product via CSV**
    - [x] Choose file (Picker)
    - [x] Parsing CSV logic
    - [x] Batch insert to database
- [ ] **Shift Closing Report**
    - [ ] Summary of shift sales
    - [ ] Cash on hand reconciliation
    - [ ] Print shift report
- [ ] **Employee Management**
    - [ ] List of employees
    - [ ] Add/Edit employee
    - [ ] Role-based access (Owner/Supervisor/Cashier)
- [ ] **Category Management**
    - [ ] List of categories
    - [ ] Add/Edit/Delete categories
- [ ] **Stock Opname**
    - [x] UI for stock adjustment
    - [x] Saving adjustment records
    - [ ] Stock history audit log
