# 🗄️ POSify - Database Schema (ERD)

Dokumen ini memuat skema database relasional (SQLite via Drift ORM) untuk mendukung semua fitur *Offline-First* secara reaktif sesuai dengan draf UI/UX, dan dipersiapkan (*Future-Proof*) untuk sinkronisasi Tier 2 di masa mendatang.

---

## 1. Entity Relationship Diagram (Mermaid)

```mermaid
erDiagram
    licenses ||--o{ employees : "mengaktifkan aplikasi"
    licenses ||--o| store_profile : "mempunyai data toko"
    employees ||--o{ shifts : "membuka shift"
    employees ||--o{ transactions : "membatalkan (void)"
    employees ||--o{ stock_adjustments : "melakukan penyesuaian"
    
    shifts ||--o{ transactions : "menampung nota"
    
    categories ||--|{ products : "mengkelompokkan"
    
    products ||--o{ stock_adjustments : "memiliki riwayat"
    products ||--o{ transaction_items : "dibeli dalam"
    
    transactions ||--|{ transaction_items : "memiliki detail"

    %% Definisi Entitas %%

    licenses {
        INTEGER id PK "Auto Increment"
        TEXT license_code "Unik (Dari Email)"
        TEXT device_fingerprint "Unik UUID"
        TEXT activation_date "ISO 8601"
        TEXT last_verified "ISO 8601, Nullable"
        TEXT status "active/suspended"
    }

    employees {
        INTEGER id PK "Auto Increment"
        TEXT name 
        TEXT pin "6 Digit, UNIQUE"
        TEXT role "owner/supervisor/cashier"
        INTEGER failed_login_attempts "Default 0"
        TEXT locked_until "ISO 8601, Nullable"
        TEXT status "active/inactive"
        TEXT photo_uri "Opsional, Path lokal gambar"
        TEXT created_at "ISO 8601"
        TEXT updated_at "ISO 8601"
    }

    store_profile {
        INTEGER id PK "Auto Increment"
        TEXT name "Nama Toko"
        TEXT address "Alamat Toko (Opsional)"
        TEXT phone "Standar (+62) Opsional"
        TEXT logo_uri "Opsional, Path URI gambar logo"
        INTEGER tax_percentage "Persentase Pajak (0-100)"
        TEXT tax_type "inclusive/exclusive"
        INTEGER service_charge_percentage "Persen Service (0-100)"
    }

    categories {
        INTEGER id PK "Auto Increment"
        TEXT name "Unik"
    }

    products {
        INTEGER id PK "Auto Increment"
        INTEGER category_id FK 
        TEXT name 
        TEXT sku "Unik, Barcode"
        INTEGER price "Harga Jual"
        INTEGER purchase_price "Harga Beli"
        INTEGER stock "Sisa Fisik"
        TEXT image_uri "Path lokal gambar"
        TEXT created_at "ISO 8601"
        TEXT updated_at "ISO 8601"
    }

    shifts {
        INTEGER id PK "Auto Increment"
        INTEGER employee_id FK "Siapa yg buka"
        TEXT start_time "ISO 8601"
        TEXT end_time "ISO 8601, Nullable"
        INTEGER starting_cash "Modal Uang Laci"
        INTEGER expected_ending_cash "Estimasi Sistem"
        INTEGER actual_ending_cash "Hitungan Fisik Laci"
        TEXT status "open/closed"
    }

    transactions {
        INTEGER id PK "Auto Increment"
        TEXT receipt_number "Unik: POS-YYYYMMDD-XXX"
        INTEGER shift_id FK 
        INTEGER subtotal "Subtotal Item"
        INTEGER tax_amount "Nominal Pajak"
        INTEGER service_charge_amount "Nominal Biaya Layanan"
        INTEGER total_amount "Total Bayar Akhir"
        TEXT payment_method "cash/qris/debit/credit"
        TEXT payment_status "paid/void"
        INTEGER void_by FK "ID Pegawai L1/L2, Nullable"
        TEXT created_at "Waktu Transaksi"
    }

    transaction_items {
        INTEGER id PK "Auto Increment"
        INTEGER transaction_id FK 
        INTEGER product_id FK 
        INTEGER quantity "Jml Beli"
        INTEGER price_at_transaction "Harga saat dibeli"
        INTEGER subtotal "Q * Harga"
    }

    stock_adjustments {
        INTEGER id PK "Auto Increment"
        INTEGER product_id FK
        INTEGER employee_id FK "Pelaku opname"
        INTEGER previous_stock "Stok sistem"
        INTEGER new_stock "Stok fisik"
        TEXT reason "Alasan perbedaan"
        TEXT created_at "Waktu edit"
    }

    printer_settings {
        INTEGER id PK "Auto Increment"
        TEXT device_name "Nama Printer"
        TEXT mac_address "Identitas Unik"
        TEXT status "paired/last_connected"
    }
```

---

## 2. Struktur Tabel & Penjelasan (SQLite Data Types - Drift ORM)

Di dalam SQLite (yang diatur via Drift ORM), tipe data utama yang dipakai adalah `TEXT` dan `INTEGER`. Tanggal dan UUID akan disesuaikan menjadi *class type-safe* di layer Dart dengan *fallback* fungsi penyimpanan secara `TEXT` berformat `ISO 8601` untuk standar lokalisasi dan sinkronisasi log di Tier 2 nanti.

### a) `licenses` (Otorisasi Perangkat)
Satu perangkat SQLite hanya perlu `SELECT * FROM licenses LIMIT 1`. Jika perangkat terganti, *device fingerprint* tidak akan cocok dan aplikasi akan terkunci otomatis.

### b) `employees` (Pengguna & Hak Akses)
Keamanan L1/L2/L3 dari PRD diimplementasikan lewat tabel ini. Kolom `pin` sifatnya *UNIQUE* sehingga query login sangat cepat dan bebas ambigu. Apabila salah login 5x, kolom `locked_until` akan terisi jam berapa akun bisa dipakai lagi.

### c) `categories` & `products` (Katalog)
`sku` wajib *UNIQUE* untuk memastikan operasional barcode scanner berjalan dengan semestinya. Gambar produk disimpan di variabel `image_uri` yang berisi path absolut ke internal storage HP, agar aplikasi tidak berat menampung BLOB dalam SQLite.

### d) `shifts` (Riwayat Sesi)
Sebuah transaksi (*receipt*) tidak bisa terjadi jika di device tersebut tidak ada `shifts` yang berstatus `open`. Shift diikat per individu (satu kasir satu laci).

### e) `transactions` & `transaction_items` (Nota)
- Data historis (`price_at_transaction`) disimpan secara terpisah di tabel detail. Mengapa? Supaya kalau besok harga produk naik, nota lama yang sudah terjadi tidak ikut membengkak harganya.
- Nilai Pajak (`tax_amount`) dan Service (`service_charge_amount`) di-record per nota secara mutlak (angka rupiahnya) pada saat transaksi final. Ini memastikan rekap harian tidak bocor ketika Owner merubah persentase pajaknya di kemudian hari.
- Jika transaksi di-*Refund* (batal), maka `payment_status` akan berubah jadi `void`, dan `void_by` mencatat `employee_id` sang *Supervisor* (L2) atau *Owner* (L1) yang memberi ACC pembatalan tersebut.

### f) `stock_adjustments` (Audit Trail)
Setiap kali terjadi *Stock Opname* (fitur Tab 2) yang menyebabkan stok produk berubah bukan karena laku dijual, perubahan tersebut akan dicatat di tabel ini beserta alasan kenapa angkanya selisih.

### g) `store_profile` (Informasi Usaha & Konfigurasi Biaya)
Hanya akan berisi 1 baris (single record). Data `name`, `address`, dan `phone` ini akan dipanggil otomatis oleh *Bluetooth Printer* untuk mencetak Header Nota kertas. 
Di tabel ini pula letak variabel Global untuk menghitung **Pajak (PB1/PPN)** dan **Service Charge**. Owner secara bebas mengatur apakah model pajaknya `inclusive` (sudah termasuk harga menu) atau `exclusive` (ditambahkan saat bayar).

### h) `printer_settings` (Koneksi Hardware)
Menyimpan data printer terakhir yang digunakan agar aplikasi bisa otomatis *re-connect* saat kasir dibuka tanpa perlu mengulang proses scanning setiap hari.
