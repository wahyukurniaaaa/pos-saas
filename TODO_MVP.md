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
Pada layar "Riwayat Transaksi" (`transaction_history_screen.dart`), ketika sebuah transaksi di-tap, seharusnya membuka layar detail transaksi lengkap beserta daftar item yang dibeli.

**Kebutuhan Tambahan:**
- Query join antara tabel `transactions` dan tabel `transaction_items` menggunakan `transaction_id`.

**Scope of Work (SoW):**
- [ ] Buat UI `receipt_detail_screen.dart` / modal yang visualnya mirip dengan struk/nota.
- [ ] Buat fungsi untuk mem-fetch relasi item transaksi dari Drift. (Inner join ke tabel `products` untuk ambil nama produk & SKU).
- [ ] Tambahkan tombol **Cetak Ulang (Reprint)**, yang memanggil kembali fungsi cetak dari package Bluetooth printer.
- [ ] Tambahkan tombol **Batal/VOID** pada riwayat ini.

---

## 4. Logical Workflow: VOID Transaksi dengan Otorisasi
**Deskripsi:**
Menghubungkan layar keamanan `SupervisorAuthDialog` dengan aksi sesungguhnya di database lokal Drift saat transaksi dibatalkan.

**Scope of Work (SoW):**
- [ ] Hubungkan tombol **VOID** (dari Detail Struk di poin 3) agar memunculkan `SupervisorAuthDialog`.
- [ ] Apabila PIN Owner/Supervisor benar dan disahkan, update status transaksi di database lokal Drift menjadi "VOID".
- [ ] **(KRITIKAL)**: Saat transaksi di-VOID, buat fungsi pengembalian *stok produk/restock* (berdasarkan `transaction_items`) ke tabel utama `products`.
- [ ] Perbarui visual pada `transaction_history_screen` (tulisan tercoret merah / berlabel "Batal") menggunakan state Riverpod secara reaktif ketika pembaruan database selesai.
