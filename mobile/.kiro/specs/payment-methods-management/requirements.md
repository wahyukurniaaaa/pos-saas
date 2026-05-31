# Requirements Document

## Introduction

Fitur **Payment Methods Management** memungkinkan pemilik toko (owner) mengonfigurasi metode pembayaran mana yang aktif dan ditampilkan di layar kasir (POS) pada aplikasi mobile Lumio. Saat ini, metode pembayaran di layar kasir bersifat hardcoded (Tunai, QRIS, Debit, Kasbon, Kredit) dan tidak dapat dikustomisasi per outlet.

Fitur ini mencakup:
1. Tabel baru `payment_methods` di SQLite (Drift) untuk menyimpan konfigurasi per outlet
2. Layar manajemen metode pembayaran di menu Settings
3. Integrasi dengan layar kasir (PaymentModal) agar hanya menampilkan metode yang aktif
4. Sinkronisasi konfigurasi ke Supabase (khusus pengguna Pro)

Referensi: Web dashboard (`lumiopos-web`) sudah memiliki fitur serupa yang dapat dijadikan acuan logika bisnis.

---

## Glossary

- **Payment_Method_Config**: Konfigurasi satu metode pembayaran milik sebuah outlet, disimpan di tabel `payment_methods` SQLite.
- **Payment_Methods_Manager**: Layar di menu Settings untuk mengelola daftar Payment_Method_Config.
- **POS_Screen**: Layar kasir (PaymentModal) tempat kasir memilih metode pembayaran saat checkout.
- **Outlet**: Toko/cabang yang dimiliki pengguna, diidentifikasi dengan `outlet_id`.
- **Owner**: Karyawan dengan role `owner` (L1), satu-satunya yang berhak mengubah konfigurasi metode pembayaran.
- **Sync_Service**: Layanan sinkronisasi data lokal (SQLite) ke Supabase cloud, hanya aktif untuk pengguna Pro.
- **Metode_Bawaan**: Enam metode pembayaran yang sudah didefinisikan sistem: `cash` (Tunai), `qris` (QRIS), `debit` (Debit), `credit` (Kredit), `bon` (Kasbon), `transfer` (Transfer Bank).
- **Split_Payment**: Fitur pembayaran dengan lebih dari satu metode dalam satu transaksi. Kasbon tidak diizinkan dalam split payment.

---

## Requirements

### Requirement 1: Tabel Konfigurasi Metode Pembayaran

**User Story:** Sebagai sistem, saya membutuhkan tabel penyimpanan konfigurasi metode pembayaran per outlet agar pengaturan dapat dipersistensikan secara lokal dan disinkronkan ke cloud.

#### Acceptance Criteria

1. THE Payment_Method_Config SHALL memiliki field: `id` (UUID v7), `outlet_id` (FK→outlets), `method_key` (enum: cash/qris/debit/credit/bon/transfer), `display_name` (TEXT, max 30 karakter), `is_active` (BOOLEAN, default true), `sort_order` (INTEGER), `created_at`, `updated_at`, `is_dirty` (BOOLEAN), `deleted_at` (nullable).
2. THE Payment_Method_Config SHALL memastikan kombinasi `outlet_id` + `method_key` bersifat unik (UNIQUE constraint).
3. WHEN outlet baru dibuat atau aplikasi pertama kali dijalankan tanpa data Payment_Method_Config, THE Payment_Methods_Manager SHALL menyemai (seed) enam Metode_Bawaan dengan `is_active = true` untuk outlet tersebut.
4. THE Payment_Method_Config SHALL menyertakan field `is_dirty` agar Sync_Service dapat mendeteksi perubahan yang perlu disinkronkan ke Supabase.
5. THE Payment_Method_Config SHALL menggunakan soft delete melalui field `deleted_at` yang nullable, konsisten dengan pola tabel lain di database.

---

### Requirement 2: Manajemen Metode Pembayaran (Settings)

**User Story:** Sebagai owner, saya ingin mengaktifkan atau menonaktifkan metode pembayaran tertentu agar kasir hanya melihat metode yang relevan dengan bisnis saya.

#### Acceptance Criteria

1. THE Payment_Methods_Manager SHALL menampilkan daftar semua Payment_Method_Config milik outlet yang sedang aktif, diurutkan berdasarkan `sort_order`.
2. WHEN owner mengubah status `is_active` sebuah Payment_Method_Config, THE Payment_Methods_Manager SHALL menyimpan perubahan ke SQLite dan menambahkan entri ke sync queue.
3. WHEN owner mengubah urutan tampilan metode pembayaran, THE Payment_Methods_Manager SHALL memperbarui field `sort_order` semua Payment_Method_Config yang terpengaruh secara atomik dalam satu transaksi database.
4. WHEN owner mengubah `display_name` sebuah Payment_Method_Config, THE Payment_Methods_Manager SHALL memvalidasi bahwa panjang nama tidak melebihi 30 karakter sebelum menyimpan.
5. IF semua Payment_Method_Config dinonaktifkan, THEN THE Payment_Methods_Manager SHALL menampilkan pesan peringatan dan mencegah penyimpanan, memastikan minimal satu metode tetap aktif.
6. WHILE pengguna bukan Owner (role cashier atau supervisor), THE Payment_Methods_Manager SHALL menampilkan daftar dalam mode read-only tanpa kontrol edit.
7. THE Payment_Methods_Manager SHALL hanya menampilkan Metode_Bawaan yang sudah didefinisikan sistem; pengguna tidak dapat menambah metode baru di luar daftar tersebut.

---

### Requirement 3: Integrasi dengan Layar Kasir (POS)

**User Story:** Sebagai kasir, saya ingin layar pembayaran hanya menampilkan metode yang diaktifkan owner agar saya tidak bingung dengan pilihan yang tidak relevan.

#### Acceptance Criteria

1. WHEN POS_Screen dibuka, THE POS_Screen SHALL memuat daftar Payment_Method_Config dengan `is_active = true` dari SQLite, diurutkan berdasarkan `sort_order`.
2. THE POS_Screen SHALL menampilkan hanya metode pembayaran yang aktif sebagai chip pilihan, menggantikan daftar hardcoded yang ada saat ini.
3. WHEN daftar Payment_Method_Config aktif berubah (karena owner mengubah konfigurasi), THE POS_Screen SHALL memperbarui tampilan chip metode pembayaran secara reaktif tanpa perlu restart aplikasi.
4. IF Payment_Method_Config untuk metode `bon` (Kasbon) berstatus `is_active = true`, THEN THE POS_Screen SHALL menampilkan Kasbon sebagai pilihan tunggal saja dan tidak memasukkannya ke dalam opsi Split_Payment.
5. WHEN POS_Screen dalam mode Split_Payment, THE POS_Screen SHALL hanya menampilkan metode dengan `is_active = true` dan `method_key` bukan `bon` sebagai pilihan dalam dropdown split payment.
6. IF tidak ada Payment_Method_Config dengan `is_active = true` yang tersedia (kondisi tidak normal), THEN THE POS_Screen SHALL menampilkan pesan error dan menonaktifkan tombol bayar.

---

### Requirement 4: Sinkronisasi ke Supabase (Pro)

**User Story:** Sebagai pengguna Pro dengan multi-device, saya ingin konfigurasi metode pembayaran yang saya atur di satu perangkat tersinkronisasi ke perangkat lain secara otomatis.

#### Acceptance Criteria

1. WHEN Sync_Service memproses sync queue dan menemukan entri untuk tabel `payment_methods`, THE Sync_Service SHALL melakukan upsert record Payment_Method_Config ke tabel `payment_methods` di Supabase.
2. WHEN Sync_Service menarik perubahan dari Supabase (pull), THE Sync_Service SHALL menyertakan tabel `payment_methods` dalam daftar tabel yang di-pull, dengan filter `outlet_id` yang sesuai.
3. WHILE pengguna adalah Lite tier (bukan Pro), THE Sync_Service SHALL melewati sinkronisasi tabel `payment_methods` ke Supabase, namun konfigurasi tetap tersimpan lokal di SQLite.
4. WHEN Sync_Service menarik data `payment_methods` dari Supabase dan record sudah ada di SQLite lokal, THE Sync_Service SHALL melakukan upsert (INSERT OR REPLACE) berdasarkan `id` untuk menghindari duplikasi.
5. THE Sync_Service SHALL menempatkan tabel `payment_methods` dalam grup pull pertama (bersama `outlets`, `categories`, dll.) karena tidak memiliki dependensi foreign key ke tabel transaksi.

---

### Requirement 5: Seeding Data Awal

**User Story:** Sebagai pengguna baru, saya ingin semua metode pembayaran sudah tersedia secara default agar saya bisa langsung menggunakan kasir tanpa konfigurasi awal.

#### Acceptance Criteria

1. WHEN aplikasi dijalankan pertama kali dan tabel `payment_methods` kosong untuk outlet aktif, THE Payment_Methods_Manager SHALL menyemai enam Payment_Method_Config dengan data berikut: `cash`/Tunai (sort_order=1), `qris`/QRIS (sort_order=2), `debit`/Debit (sort_order=3), `credit`/Kredit (sort_order=4), `bon`/Kasbon (sort_order=5), `transfer`/Transfer Bank (sort_order=6), semua dengan `is_active = true`.
2. WHEN migrasi database dijalankan pada perangkat yang sudah memiliki data (upgrade dari versi lama), THE Payment_Methods_Manager SHALL menyemai data default hanya jika belum ada Payment_Method_Config untuk outlet tersebut, tanpa menimpa konfigurasi yang sudah ada.
3. THE Payment_Method_Config untuk `bon` (Kasbon) SHALL memiliki `is_active = true` secara default namun sistem SHALL menerapkan aturan bisnis bahwa Kasbon tidak dapat digunakan dalam Split_Payment, terlepas dari status aktifnya.

---

### Requirement 6: Validasi dan Konsistensi Data

**User Story:** Sebagai sistem, saya perlu memastikan data konfigurasi metode pembayaran selalu valid dan konsisten agar tidak terjadi error saat proses checkout.

#### Acceptance Criteria

1. THE Payment_Method_Config SHALL memvalidasi bahwa nilai `method_key` hanya boleh berisi salah satu dari: `cash`, `qris`, `debit`, `credit`, `bon`, `transfer`.
2. WHEN Payment_Method_Config disimpan ke SQLite, THE Payment_Method_Config SHALL memperbarui field `updated_at` ke waktu saat ini secara otomatis.
3. IF `outlet_id` pada Payment_Method_Config tidak merujuk ke outlet yang valid di tabel `outlets`, THEN THE Payment_Method_Config SHALL menolak penyimpanan dengan foreign key constraint error.
4. THE Payment_Methods_Manager SHALL memuat ulang daftar Payment_Method_Config dari SQLite setiap kali layar Settings dibuka, untuk memastikan data yang ditampilkan selalu terkini.
5. WHEN Payment_Method_Config diperbarui melalui sinkronisasi Supabase (pull), THE POS_Screen SHALL memperbarui daftar metode aktif secara reaktif melalui Riverpod stream provider yang mendengarkan perubahan SQLite.

---

### Requirement 7: Tampilan dan UX

**User Story:** Sebagai owner, saya ingin antarmuka manajemen metode pembayaran yang intuitif agar saya dapat mengonfigurasi dengan cepat tanpa panduan.

#### Acceptance Criteria

1. THE Payment_Methods_Manager SHALL menampilkan setiap Payment_Method_Config sebagai item list dengan: ikon metode, `display_name`, toggle switch untuk `is_active`, dan handle drag untuk mengubah urutan.
2. WHEN owner menggeser toggle `is_active` sebuah Payment_Method_Config, THE Payment_Methods_Manager SHALL memberikan feedback visual (animasi toggle) dan menyimpan perubahan secara langsung (auto-save) tanpa tombol konfirmasi terpisah.
3. THE Payment_Methods_Manager SHALL dapat diakses dari menu Settings utama aplikasi, di bawah bagian konfigurasi toko.
4. WHEN Payment_Method_Config memiliki `is_active = false`, THE Payment_Methods_Manager SHALL menampilkan item tersebut dengan tampilan redup (opacity rendah) untuk membedakannya secara visual dari yang aktif.
5. THE Payment_Methods_Manager SHALL menampilkan ikon yang berbeda untuk setiap `method_key`: ikon uang untuk `cash`, ikon QR code untuk `qris`, ikon kartu untuk `debit` dan `credit`, ikon nota untuk `bon`, dan ikon transfer untuk `transfer`.
