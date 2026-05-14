# **Product Requirements Document (PRD)**

**Produk:** Aplikasi Sistem Kasir (POS) SaaS Offline-First

**Versi:** 3.2 (Next Features Roadmap)

**Status:** Implementasi Progresif (Phase 0-3, Phase 4 (Partial Sync), Phase 7-13 Selesai)

## **Update Log (v3.2):**
*   **Next Features Roadmap**: Penambahan dokumentasi formal untuk fitur-fitur lanjutan yang sebelumnya hanya terdapat di backlog. Mencakup: Inter-Outlet Stock Transfer, Background Image Sync, Unified Tier Provider, Piutang/Bon Management, Receipt Customization, Batch & Expiry Tracking, FCM Push Notifications, Table Management (F&B), KDS, Employee Commissions, Split Bill (per-item), dan Dynamic QRIS.

## **Update Log (v3.1):**
*   **Auto-Stock Deduction (Phase 13)**: Pemotongan stok bahan baku secara sistematis dan otomatis saat transaksi diselesaikan di kasir (Checkout).
*   **Recipe-Based Logic**: Pengurangan stok bahan baku bersifat dinamis sesuai dengan "Resep" yang dikonfigurasi pada saat input data produk. Jika produk memiliki resep, sistem akan menghitung iterasi pemotongan setiap bahan secara holistik.

## **Update Log (v3.0):**
*   **Split Payment (Phase 0)**: Implementasi pembayaran multi-metode dalam satu transaksi (contoh: Tunai + QRIS). Didukung hingga **4 metode** sesuai standar POS kompetitor (Moka, iReap, Kasir Pintar). Kasbon tidak dapat digabung dalam split.
*   **Tabel `transaction_payments`**: Skema database baru (Migrasi v21) untuk menyimpan rincian setiap metode bayar per transaksi secara individual.
*   **Struk Terpisah Per Metode**: Struk termal & digital menampilkan baris rincian untuk setiap metode pembayaran yang digunakan.

## **Update Log (v2.9):**
*   **Unified Registration (Phase 2)**: Implementasi pendaftaran akun SaaS (Email & Password) yang terintegrasi langsung dengan aktivasi lisensi (Hybrid Flow) dalam satu langkah.
*   **Deep Link Integration**: Dukungan *Custom URL Scheme* (`posify://register`) untuk pengisian otomatis kode lisensi dari email/marketplaces.
*   **Backend Auth Module**: Penambahan sistem autentikasi berbasis PostgreSQL (GORM) di sisi server untuk keamanan akun *Owner*.

## **Update Log (v2.8):**
*   **Essential POS UX (Phase 0)**: Penambahan fitur Save Bill (Hold Transaction) dan Transaction Notes untuk operasional kasir yang lebih fleksibel.
*   **Expense Management**: Implementasi sistem pencatatan Kas Keluar (Expense) dengan dukungan kategori khusus (Ikon & Warna) dan histori pengeluaran untuk akurasi Laba Bersih.

## **Update Log (v2.7):**
*   **Loyalty & Membership System (Phase 10)**: Sistem poin member terintegrasi. Pelanggan mendapatkan poin berdasarkan nominal belanja yang dapat ditukarkan menjadi diskon langsung di kasir.
*   **Loyalty Analytics**: Dashboard leaderboard untuk memantau member paling loyal (berdasarkan poin dan frekuensi transaksi).
*   **Database Migration v17**: Penambahan kolom `points` pada `customers`, pengaturan poin di `store_profile`, dan audit poin pada `transactions`.

## **Update Log (v2.6):**
*   **Retail HPP Support (Phase 12)**: Tambahkan dukungan Harga Pokok Penjualan (HPP) untuk produk retail murni (non-resep).
*   **Moving Average Algorithm**: Implementasi perhitungan modal rata-rata otomatis pada produk retail saat proses *Stock In*, menjaga akurasi laba kotor di tengah fluktuasi harga supplier.
*   **Database Migration v16**: Penambahan kolom `purchase_price` pada tabel `products`.

## **Update Log (v2.5):**
*   **Discount & Voucher Management (Phase 11)**: Sistem promosi fleksibel pendukung diskon per-item dan per-transaksi (bill level). Mendukung minimal belanja, periode aktif, dan diskon otomatis.
*   **Database Migration v14**: Penambahan tabel `discounts` serta kolom audit diskon pada `transactions` dan `transaction_items`.
*   **UI Refresh**: Integrasi "Pilih Promo" pada modal pembayaran POS.

## **Update Log (v2.3):**
*   **Stock Opname Bahan Baku (Phase 8)**: Layar audit stok fisik untuk bahan baku. User memasukkan stok fisik, sistem otomatis menghitung selisih dan membuat entri `ADJUST` di `ingredient_stock_history`.
*   **Unit of Measure (UoM) Conversion (Phase 9)**: Tabel `unit_conversions` baru untuk aturan konversi satuan fleksibel (misal: 1 kg = 1000 gr). Layar manajemen konversi tersedia di Pengaturan (role Owner).
*   **Database Migration v11**: Penambahan tabel `unit_conversions` pada skema database SQLite.

## **Update Log (v2.2):**
*   **Advanced Inventory**: Implementasi fitur "Stok Keluar" dengan alasan (Waste/Expired/Damage).
*   **Supplier Management**: Penambahan Master Data Supplier dan integrasi pada Stock In bahan baku.
*   **Gross Profit**: Penambahan perhitungan Laba Kotor otomatis di dashboard analitik berbasis resep (COGS).
*   **ERD Sync**: Sinkronisasi tabel `suppliers`, `ingredients`, dan `ingredient_stock_history`.

## **1\. Ringkasan Eksekutif**

Aplikasi POSify adalah sistem Point of Sale (POS) yang dirancang khusus untuk UMKM dengan pendekatan *offline-first*. Fokus utama produk ini adalah memberikan alternatif yang terjangkau melalui model **Lifetime License (Sekali Bayar)** pada Tier 1. Keamanan data dijamin melalui enkripsi AES-256 pada setiap backup, dan lisensi diamankan dengan sistem *24-hour heartbeat* serta *device fingerprinting*.

## **2\. Target Pengguna**

* **Pemilik UMKM Ritel & F\&B Kecil:** Pengusaha yang menginginkan kepastian biaya operasional tanpa biaya langganan tetap.  
* **Bisnis di Area Internet Tidak Stabil:** Membutuhkan kecepatan operasional tanpa bergantung pada latensi *cloud*.  
* **Outlet Tunggal dengan Banyak Karyawan:** Membutuhkan manajemen peran (Owner, Supervisor, Kasir) tanpa biaya tambahan per lisensi pengguna.

## **3\. Struktur Tier & Model Bisnis**

| Fitur | Tier 1: Lite (Lifetime Pay) | Tier 2: Pro (Subscription) |
| :---- | :---- | :---- |
| **Model Biaya** | **Sekali Bayar (Lifetime)** | Langganan Bulanan/Tahunan |
| **Batas Outlet** | 1 Outlet (Terkunci pada Perangkat) | Hingga 3 Outlet |
| **Ubah Perangkat** | Mendukung Migrasi (via Recovery Key) | Multi-perangkat (Sync Cloud) |
| **Batas Karyawan** | **Tidak Terbatas (Lokal)** | Tidak Terbatas |
| **Akses Peran** | Hierarki Kumulatif (L1, L2, L3) | Hierarki Kumulatif (L1, L2, L3) |
| **Manajemen Stok** | Stok In/Out & Opname (Lokal) | Multi-Gudang & Sync Cloud |
| **Penyimpanan** | Full Offline (SQLite via Drift ORM) | Hybrid (SQLite + Direct Supabase Sync) |
| **Backup Data** | **Manual/Auto Encrypted (AES-256)** | **Otomatis (Cloud Sync)** |
| **Aktivasi** | Online License Key & Heartbeat 24j | Login Akun SaaS |

## **4\. Fitur Utama (Functional Requirements)**

### **4.1. Modul Lisensi & Aktivasi (Unified Registration)**

* **Sistem Registrasi & Aktivasi:** Pengguna melakukan pendaftaran akun SaaS (Email & Password) sekaligus aktivasi lisensi dalam satu layar. Mendukung input manual atau pengisian otomatis melalui **Deep Link** (`posify://register?code=...`) yang dikirimkan via email pasca-pembelian.
* **Verification Heartbeat:** Sistem melakukan verifikasi berkala ke server setiap 24 jam untuk memastikan lisensi tidak dipindah-tangankan secara ilegal ke perangkat lain.
* **Offline Limit:** Aplikasi mendukung penggunaan offline penuh maksimal **7 hari**. Jika dalam 7 hari perangkat tidak pernah terhubung ke internet untuk verifikasi, aplikasi akan terkunci otomatis (Hard Block) hingga verifikasi ulang berhasil dilakukan.
* **Offline Mode:** Seluruh fungsi kasir dan manajemen stok tetap bekerja 100% tanpa internet selama masa berlaku *heartbeat* (cache) masih aktif.

### **4.2. Manajemen Role & Hierarki (Kumulatif)**

Sistem menggunakan PIN 6-digit untuk beralih antar peran dengan tingkat akses:

* **Owner (Level 1):** Akses total. Manajemen lisensi, manajemen karyawan (tambah/edit PIN), manajemen produk/stok, laporan laba rugi, dan operasional kasir.  
* **Supervisor (Level 2):** Manajemen stok, Stock Opname (Penyesuaian), Otorisasi Void/Refund transaksi kasir, dan operasional kasir.  
* **Kasir (Level 3):** Terbatas pada operasional transaksi harian, buka/tutup shift, dan laporan penjualan shift berjalan.

### **4.3. Modul Kasir & Inventaris (Offline)**

* **Manajemen Produk (Hybrid):** 
    * Input manual satu-per-satu atau impor massal via file Excel/CSV secara offline.
    * **Foto Produk**: Dapat mengunggah foto lokal yang tersimpan efisien (auto-delete jika produk dihapus).
    * **Varian Produk**: Mendukung produk sederhana (tanpa varian) bagi toko kelontong, maupun produk kompleks dengan varian (ukuran/rasa) bagi toko baju/F&B. Harga dan stok varian diatur secara individu.
* **Barcode Scanning System:** 
    * **Continuous Scanning:** Scanner tetap terbuka untuk input keranjang belanja yang cepat di menu POS.
    * **Inventory Input:** Integrasi scanner pada form tambah/edit produk untuk mengisi SKU secara otomatis.
    * setiap pergerakan stok dicatat di **Kartu Stok** sehingga ada *audit trail* yang jelas (Histori masuk/keluar/terjual).
    * Notifikasi **Low Stock Alert** jika stok mendekati batas minimum.
* **Manajemen Pemasok (Supplier) & Pembelian (Purchase Order):** [BARU]
    * Mendata profil pemasok (Nama, Kontak, Alamat).
    * Membuat *Purchase Order* (PO) untuk dikirim ke pemasok.
    * Melacak status PO (`draft` → `sent` → `received` | `cancelled`) dan menerima pesanan (otomatis memotong stok PO menjadi *Stock In* bahan baku/produk).
* **Manajemen Bahan Baku & Resep (Advanced Inventory) [BARU]:**
    * **Ingredient Maintenance**: Mengelola stok mentah (biji kopi, susu, gula) dengan satuan dasar (gr, ml, pcs).
    * **Stock Out & Waste Management**: Fitur "Stok Keluar" manual dengan pencatatan alasan (Misal: Kedaluwarsa, Rusak, Tumpah) untuk transparansi pengurangan inventaris.
    * **Recipe Builder**: Menentukan komposisi bahan baku per produk. Contoh: 1 cup "Copi Susu" memotong 15gr biji kopi dan 150ml susu.
    * **Auto-Stock Deduction [AKTIF]**: Pemotongan stok bahan baku secara otomatis dan *real-time* berdasarkan komposisi **Recipe Builder** saat transaksi pembayaran selesai (Checkout). Jika resep telah diinput pada saat pendaftaran produk, sistem akan otomatis mengurangi saldo bahan baku terkait.
    * **Kalkulasi HPP (Weighted Moving Average)**: Sistem menghitung modal rata-rata secara otomatis setiap kali ada stok baru masuk (pembelian), memberikan akurasi laba kotor yang presisi bagi Owner.
    * **Unit Conversion**: Fleksibilitas input stok dalam satuan besar (Kg/Liter) yang otomatis dikonversi ke satuan penyimpan dasar (Gram/Ml) di database.
* **Modul Promosi & Diskon (Advanced) [BARU]:**
    * **Flexible Discount Engine**: Mendukung diskon berbasis Nominal (Rp) dan Persentase (%).
    * **Promotion Scope**: Pengaturan diskon berlaku untuk seluruh keranjang (Bill-level) atau produk tertentu saja (Item-level).
    * **Validation Rules**: Menetapkan syarat minimal belanja (Spend) atau minimal kuantitas item agar promo dapat digunakan.
    * **Time-Bound Promo**: Mengatur periode aktif promo (Tanggal Mulai/Selesai) untuk program musiman.
    * **Automatic vs Manual**: Promo dapat bersifat otomatis (terpasang saat syarat terpenuhi) atau voucher manual yang harus dipilih kasir.
* **Pencatatan Pembayaran (Recording Only):** Memilih status pembayaran (**Tunai, QRIS, Debit, Kredit**) untuk pembayaran tunggal. Tidak ada integrasi gateway API untuk menghindari biaya MDR.
* **Split Payment (Multi-Metode):** Kasir dapat menggabungkan hingga **4 metode pembayaran** dalam satu transaksi. Setiap baris pembayaran memiliki nominal sendiri, dan sisa tagihan (*remaining balance*) dihitung otomatis secara real-time. Kasbon/Bon **tidak dapat** digunakan dalam mode split. Kembalian dihitung dari input Tunai yang dimasukkan terakhir.
* **Print & Share Engine:** 
    *   Cetak struk via Bluetooth/USB Thermal (Protokol ESC/POS).
    *   **WhatsApp Hybrid Sharing:** Mengirim struk digital (Image + Text summary) ke WhatsApp pelanggan. Incl. Info Poin Member.
    *   **CRM & Database Pelanggan (Member) & Loyalty [BARU]:** Sistem mendata identitas pelanggan untuk pencarian cepat saat *checkout*. Pelanggan terdaftar otomatis mengumpulkan poin belanja (Berdasarkan aturan konversi Rp -> Poin) yang dapat ditukarkan (Redeem) menjadi potongan harga tunai.

### **4.4. Modul Backup & Restore (Tier 1)**

* **Auto-Local Backup (Failsafe):** Sistem secara otomatis mencadangkan database terenkripsi (AES-256) ke penyimpanan internal pada saat *Tutup Shift*.
* **Backup Export & Share:** Pengguna dapat membagikan file backup (.enc) ke email, WhatsApp, atau cloud storage secara manual.
* **Recovery Key Management:** Setiap perangkat memiliki Kunci Pemulihan unik yang diperlukan untuk mendekripsi file backup saat dipindahkan ke perangkat lain.
* **Data Migration:** Mendukung pemindahan data penuh antar perangkat dengan validasi ulang lisensi di perangkat tujuan.

### **4.5. Arsitektur Reactive Offline-First (Local State)**

*   **Database Engine:** Menggunakan **Drift ORM** di atas SQLite untuk memberikan lapisan keamanan pengetikan data (*Type-Safety*) penuh dan kehandalan struktur.
*   **Reactive UI:** Setiap perubahan data stok, status transaksi, atau operasional shift dari SQLite divisualisasikan secara *Real-Time* menggunakan *Stream* Drift ke antarmuka aplikasi Kasir (Flutter) tanpa membebani perangkat secara aktif.
*   **Cloud Sync Integration:** Implementasi **Tier 2 (Pro)** telah diaktifkan penuh menggunakan arsitektur **Direct Supabase Sync & Realtime Channel**, memungkinkan sinkronisasi *multi-device* berjalan mulus berdampingan dengan kapabilitas SQLite *Offline-First*.

## **5\. Aturan Validasi Data (Data Integrity)**

| Entitas | Field | Aturan Validasi |
| :---- | :---- | :---- |
| **Produk** | Nama Produk | String, 3 \- 100 karakter. Wajib diisi. |
|  | Kategori | Relasi ke tabel Kategori. |
|  | SKU / Barcode | Alphanumeric, 3 \- 30 karakter. **Harus Unik** (Primary Identifier). |
|  | Harga Beli / Jual | Numeric. Minimal 0\. Tersedia jika tidak ada varian. |
|  | Stok | Integer. Default 0\. Tersedia jika tidak ada varian. (Jika ada varian, rekap info). |
|  | Low Stock | Integer. Batas stok minimum untuk *alert*. Default 0. |
|  | Foto / Gambar | Path ke Image Device lokal, opsional. (`imageUri`) |
| **Varian Produk** | Nama Varian | String, opsional. (Contoh: "Besar", "L", "Rasa Coklat"). |
| (Baru) | SKU Varian | Alphanumeric. Opsional, unik. |
|  | Harga | Numeric. Harga spesifik varian ini. |
|  | Stok Varian | Integer. Stok spesifik varian ini. |
| **Kategori** | Nama Kategori | String, max 50 karakter. Wajib diisi & **Unik**. |
| **User (Karyawan)**| Nama User | String, max 50 karakter. Wajib diisi. |
|  | Role (Level) | Enum: {Owner (L1), Supervisor (L2), Kasir (L3)}. |
|  | PIN | Numeric, **Tepat 6 digit**. Wajib unik per perangkat. Dilarang menggunakan pola umum (ex: 123456, 000000). Sistem menerapkan *cooldown* / blokir sementara jika 5x berturut-turut gagal login. |
|  | Foto Profil | Path ke Image Device lokal, opsional. |
| **Pelanggan (Member)** | Nama | String, wajib. |
| (Baru) | Telepon (WA) | String, opsional (tapi unik jika ada). |
|  | Poin | Integer. Default 0. Bertambah saat belanja, berkurang saat redeem. |
|  | Alamat/Email | String, opsional. |
| **Profil Toko** | Nama Toko | String, max 50 karakter. Wajib diisi. (Untuk Struk). |
|  | Telp / Alamat | String. Telp Format numerik (opsional). Alamat (opsional). |
|  | Logo | Path ke Image lokal (`logoUri`). Mendukung cetak logo pada struk thermal. |
|  | Tax & Service | Numeric (0-100%). Enum tipe pajak {inclusive, exclusive}. Perhitungan Service Charge menggunakan persentase (%) dari subtotal. |
| **Transaksi** | Nomor Nota | Format: POS-YYYYMMDD-HHMMSS (Unik berbasis waktu). |
|  | Customer Info | `customerPhone` (WhatsApp) & `customerName` (Opsional). Digunakan untuk pengiriman struk digital & CRM. |
|  | Nilai Transaksi | Integrasi Subtotal, Tax Amount, Service Amount, dan Total Akhir (Nilai Integer/Pembulatan Rupiah). |
|  | Status Bayar | Enum: {Tunai, QRIS, Debit, Kredit, Piutang, **Void/Batal**, **Mixed (Split)**}. |
|  | Void By | Jika status Void, field ini wajib terisi oleh PIN Supervisor/Owner (L2/L1). |
| **Split Payment** | Jumlah Metode | Maksimum **4 metode** per transaksi. Minimum 1. |
|  | Nilai Per Metode | Integer (Rp). Minimal Rp 1. Total semua metode harus **≥ Total Tagihan Akhir**. |
|  | Metode Kasbon | Kasbon **tidak diperbolehkan** dalam kombinasi Split Payment. Hanya untuk transaksi tunggal. |
|  | Kembalian (Change) | Hanya berlaku untuk metode **Tunai**. Dihitung sebagai `amount - sisa_tagihan` pada input Tunai terakhir. |
| **Bahan Baku** | Nama Bahan | String, unik. Contoh: "Susu UHT", "Biji Kopi Arabica". |
| (Baru) | Unit | Enum: {gr, ml, pcs}. Disimpan dalam satuan terkecil. |
|  | HPP (Avg Cost) | Numeric. Dihitung otomatis (Weighted Average). |
|  | Histori Waktu | Metadata `updated_at` untuk mendukung sinkronisasi dan *audit trail*. |
| **Resep** | Qty Needed | REAL. Jumlah bahan per 1 porsi produk. |

## **6\. Arsitektur Teknis & Tech Stack**

* **Backend:** **Go (Fiber)** untuk server generator & aktivasi lisensi. Sistem autentikasi mandiri berbasis GORM untuk data *SaaS Account*.
* **Database Backend:** **PostgreSQL** untuk database lisensi & user account (melalui GORM).
* **Database App:** **SQLite (via Drift ORM ^2.32.0)** (Lokal) & **Supabase** (Master lisensi & akun owner).
* **Mobile Framework:** **Flutter ^3.11.0** dengan *State Management* **Riverpod ^3.2.1** (Target Android APK).
* **Integrasi:** Google Drive API (Backup) & ESC/POS (Printing).

## **7\. Fase Pengembangan (Roadmap)**

* **Fase 0 (Pre-Requisite):** Setup struktur ERD utama, fitur kasir inti, Save Bill, dan Expense Management. **(SELESAI)**
* **Fase 1 (Bulan 1):** Development Backend License Generator (Go), Setup Supabase, & Integrasi Email Lisensi.  
* **Fase 2 (Bulan 2):** Development App Kasir (Flutter), SQLite, Modul Import Excel, & Manajemen Stok Lokal.  
* **Fase 3 (Bulan 3):** Implementasi Modul Aktivasi Offline, Google Drive Backup, & Peluncuran Resmi APK Tier 1\.  
* **Fase 4 (Bulan 4+):** Pengembangan Tier 2 (Pro) mencakup integrasi Direct Supabase (Cloud Sync), Multi-outlet, & Dashboard Web.

## **8\. User Stories Detail**

### **8.1. Peran: Owner (Level Teratas - L1)**

* **Setup Awal:** Sebagai Owner, setelah memasukkan kode lisensi yang valid, saya wajib mendata Nama dan PIN 6-digit saya untuk akun Owner yang sah. 
* **Aktivasi Offline:** Saya ingin menginput lisensi dari email agar aplikasi aktif selamanya tanpa perlu internet lagi.  
* **Manajemen Master Produk:** Saya ingin menambah produk sederhana (seperti sabun) atau kompleks beserta Varian & Foto Produk (seperti ukuran Baju/Rasa Kopi) agar memudahkan kasir dalam memilih item pesanan.
* **Manajemen Karyawan:** Saya ingin menambah banyak akun Kasir/Supervisor, melampirkan foto profil mereka (opsional), mengatur PIN 6-digit yang berbeda tanpa biaya tambahan, dan memantau akun yang terkunci akibat salah PIN 5x.
* **Konfigurasi Biaya:** Saya ingin mengatur besaran persentase Pajak (PPN/PB1) secara *inclusive* atau *exclusive*, serta menetapkan *Service Charge* (%) agar sistem otomatis menghitungnya ke total belanjaan pelanggan. Perhitungan pajak bersifat dinamis dan akan di-record nilainya (nominal) pada setiap nota.
* **Branded Receipt:** Saya ingin mengunggah logo toko saya agar struk fisik (Thermal) maupun struk digital (WhatsApp) terlihat lebih profesional.
* **Manajemen Promosi:** Saya ingin membuat berbagai jenis promo (Misal: Diskon Hari Raya 10%, Voucher Potongan Rp 15rb) dengan syarat minimal belanja untuk meningkatkan omzet dan menarik loyalitas pelanggan.
*   **Monitoring Lengkap & Profitabilitas:** Sebagai Owner, saya ingin melihat menu analitik (Laporan Penjualan, tren, **Laba Kotor (Gross Profit)**, **Loyalty Analytics (Leaderboard Member)**, dan Kategori paling menguntungkan) demi mengevaluasi performa bisnis.
* **Manajemen Modal (HPP):** Saya ingin sistem menghitung otomatis modal (COGS) dari setiap produk berdasarkan resep dan harga beli bahan baku agar sistem bisa menyajikan estimasi Laba Kotor secara otomatis.
* **Data Safety:** Sebagai Owner, saya ingin mencadangkan data ke Google Drive secara manual, atau *Auto-Local Backup* (otomatis) di *storage internal* untuk keamanan.

### **8.2. Peran: Supervisor (L2)**

* **Manajemen Stok & Bahan:** Saya ingin menambah stok manual (bahan baku atau produk jadi) dan melakukan **Stock Opname**, yakni memasukkan stok fisik, melihat perbandingan dengan stok di sistem, sekaligus menulis alasan penambahan/pengurangan di log riwayat.
* **Monitoring Shift:** Saya ingin melihat Laporan Shift & Analytics untuk mengecek uang kasir.
* **Otorisasi Transaksi:** Saya ingin memasukkan PIN saya untuk menyetujui pembatalan (*void*) transaksi yang diajukan kasir.  
* **Operasional:** Saya ingin bisa masuk ke menu kasir untuk membantu melayani antrean pelanggan.

### **8.3. Peran: Kasir**

* **Manajemen Shift:** Saya ingin melakukan "Buka Shift" (input saldo awal) dan "Tutup Shift" (closing) agar uang tunai di laci dapat dipertanggungjawabkan.  
* **Transaksi Cepat (Hybrid):** Saya ingin tap produk biasa dan langsung masuk keranjang, ATAU jika produk punya Varian, saya ingin memilih ukuran/rasa spesifik sebelum masuk ke keranjang. Foto produk akan membedakan nama yang mirip.
* **Pembayaran:** Saya ingin memilih metode pembayaran (Tunai/QRIS/Debit) secara manual. Jika pelanggan ingin membayar sebagian dengan Tunai dan sisanya dengan QRIS, saya dapat mengaktifkan mode **Split Payment** dan menambahkan baris metode bayar baru beserta nominalnya masing-masing hingga total lunas.  
* **Struk Fisik:** Saya ingin mencetak struk belanja via Bluetooth segera setelah transaksi selesai sebagai bukti bagi pelanggan.  
* **WhatsApp Sharing & CRM:** Saya ingin menanyakan nomor WhatsApp pelanggan dan mengirimkan struk digital secara instan untuk menghemat kertas dan membangun database pelanggan.
* **Self-Monitoring:** Saya ingin melihat ringkasan penjualan saya selama shift berjalan untuk memastikan kesesuaian fisik uang tunai.

## **9\. Non-Functional Requirements (NFR)**

* **Reliabilitas:** Aplikasi harus stabil tanpa *crash* saat internet mati total.  
* **Performa:** Waktu inisiasi pencarian produk dan *checkout* harus di bawah 1 detik.  
* **Keamanan & Device Management:** Lisensi terkunci permanen pada *Device Fingerprint*. Kasus pengecualian (seperti perangkat rusak/hilang) memerlukan pengajuan *reset* lisensi manual yang dikelola oleh Admin *SaaS* lewat *Support Dashboard*.
* **Lokalisasi:** Antarmuka dan format data (Tanggal, Mata Uang Rp, Angka) harus mengikuti standar `id_ID` (Indonesian Locale) secara konsisten.

## **10\. Batasan Ruang Lingkup (Out of Scope)**

* Integrasi otomatis API E-wallet/Bank (Hanya pencatatan status manual).  
* Integrasi otomatis ojek online (Grab/GoFood).  
* Sinkronisasi multi-perangkat di Tier 1 (Hanya 1 perangkat aktif per lisensi).

## **11\. Spesifikasi Hardware Minimum**

* **OS:** Android 10+ (iOS 14+ secara arsitektur didukung, namun rilis utama saat ini dikonfigurasi khusus untuk Android APK demi menekan beban biaya App Store bagi UMKM).
* **RAM:** Minimum 3GB (Rekomendasi 4GB).  
* **Storage:** Sisa 1GB untuk database SQLite.  
* **Printer:** Bluetooth/USB Thermal Printer standard ESC/POS.

## **12\. Asumsi & Ketergantungan**

* Merchant sudah memiliki perangkat EDC atau QRIS statis mandiri.  
* Koneksi internet hanya dibutuhkan 1x saat aktivasi awal dan saat proses backup Google Drive.

## **13\. Kriteria Kesuksesan (KPI)**

* Akurasi laporan penjualan harian mencapai 100%.  
* Nol insiden kehilangan data saat penggunaan offline murni.  
* Waktu *onboarding* user (instal hingga transaksi pertama) \< 15 menit.

## **14\. User Flows Utama**

### **14.1. Alur Unified Registration & Aktivasi**

Input Email & Password -> [Opsional] Input/Deep Link Kode Lisensi -> Validasi & Simpan User (Backend) -> Aktivasi Lisensi & Sync Device Fingerprint -> Simpan Status ke SQLite -> Onboarding Selesai.

### **14.2. Alur Transaksi & Navigasi Utama**

PIN Login Karyawan (L3/L2/L1) -> Dashboard Utama (4 Tab: Kasir, Riwayat, Stok, Setting) -> [Opsional] Buka Shift -> Scan Barcode -> Tekan Tombol BAYAR -> Cari/Input Data Pelanggan (Member) -> Pilih Metode Bayar **[Tunggal atau Split (maks. 4 metode)]** -> Selesaikan Pembayaran -> Update Stok & Catat Kartu Stok (SALE) -> Tampil Animasi Sukses -> Pilih [Cetak Struk] atau [Bagikan ke WhatsApp]. Riwayat transaksi dapat diakses langsung dari navbar tanpa masuk ke menu Setting.

### **14.3. Alur Kelola Stok (In/Out/Opname)**

*   **Stock In**: Pilih Produk -> Pilih Supplier -> Input Jumlah Masuk, Harga Beli Baru, & Invoice -> Simpan -> Update Stok Master & Catat ke Kartu Stok (IN) -> Stok Bertambah.
*   **Stock Out**: Pilih Produk -> Input Jumlah Keluar & Alasan -> Catat ke Kartu Stok (OUT) -> Stok Berkurang.
*   **Stock Opname**: Pilih Produk \-\> Lihat Stok Sistem -> Input Jumlah Fisik Aktual \-\> Sistem Hitung Selisih \-\> Input Alasan Selisih \-\> Catat ke Kartu Stok (ADJUST) \-\> Update Stok SQLite.

### **14.4. Alur Input Karyawan (Owner)**

Masuk Pengaturan \-\> Tambah Karyawan \-\> Input Nama & Pilih Role (L2/L3) \-\> Input PIN 6 Digit (Unik) \-\> Simpan SQLite.

### **14.5. Alur Input Produk Manual (Owner/Supervisor)**

Masuk Setting (Master Data) \-\> Tambah Produk / Import CSV \-\> Input Nama, SKU, Harga Beli/Jual, Gambar, & Stok Awal \-\> Simpan SQLite.

### **14.6. Alur Penutupan Sesi (End-of-Day Kasir)**

Tekan Ikon Laporan (Header) \-\> Cek Laporan Shift Berjalan (Current Shift Analytics & Prediksi Laci) \-\> Tekan "Tutup Shift" \-\> Input Aktual Uang Fisik laci \-\> Simpan Selisih (+/-) \-\> Auto-Local Backup berjalan \-\> Logout.

### **14.7. Alur Migrasi Perangkat (Device Migration)**

Generate Recovery Key (HP Lama) \-\> Export File Backup \-\> Kirim/Pindah File \-\> Install App (HP Baru) \-\> Import Backup \-\> Input Recovery Key \-\> Database Terpulihkan \-\> Validasi Ulang Lisensi (Online) \-\> Aktivasi Selesai.

## **15\. Daftar Use Case Sistem Lengkap**

Bagian ini merangkum kapabilitas utama berdasarkan *Use Case* operasional POS.

### **15.1. Autentikasi & Manajemen Sesi**
*   **UC-AUTH:** Pendaftaran Akun (Email/Password), Aktivasi Lisensi (Manual/Deep Link), Login via PIN 6-digit (Lokal), dan *Logout*.

### **15.2. Transaksi Kasir (Point of Sales)**
*   **UC-POS:** Buka Shift (modal awal), Pencarian/Pindai Barang, Kelola Keranjang (termasuk fitur *Hold/Save Bill*), Terapkan Diskon (Item/Global), Proses Pembayaran **[Tunggal & Split Multi-Metode (maks. 4, tanpa Kasbon)]**, Cetak Struk (dengan rincian per metode bayar), dan Tutup Shift (Validasi Uang Laci).

### **15.3. Manajemen Stok & Backoffice**
*   **UC-INV:** Kelola Master Produk, Import/Export Massal (CSV), Catat *Stock In* & *Stock Out* (dengan alasan waste), Lacak Kartu Stok (Mutasi log), *Stock Opname* (audit fisik vs sistem), dan Manajemen Resep/Bahan Baku.
*   **UC-EXP:** Manajemen Kas Keluar (Expense) untuk operasional, pengkategorian jenis pengeluaran, dan pelampiran foto bukti kuitansi demi pelaporan pendanaan/laba rugi yang akurat.

### **15.4. Pembelian & Supplier (Purchasing)**
*   **UC-PUR:** Pendaftaran Database Supplier, Pembuatan Dokumen *Purchase Order* (PO), dan Pelacakan Status Penerimaan Barang.

### **15.5. Laporan & Metrik Analitik**
*   **UC-RPT:** Dashboard Owner *Real-Time* (Laba Kotor), Grafik Tren Penjualan, Laporan Barang Hilang/Susut, Analitik Loyalitas Pelanggan (CRM *Whale*), dan Pemantauan Arus Kas Komprehensif.

### **15.6. Lacak Histori Administrasi**
*   **UC-HIS:** Pencarian Riwayat Transaksi Historis, Proses Void/Refund Transaksi, Cetak Ulang Nota (*Reprint*), serta Laporan Shift Karyawan Lampau.

### **15.7. Pengaturan Sistem Global**
*   **UC-SET:** Konfigurasi Profil Toko/Kustomisasi Struk, Manajemen Tingkat Akses Karyawan, Buku Alamat Pelanggan, Manajemen Konversi Satuan (UoM), Pajak/Servis Otomatis, Manajemen Promo, Setel Printer Bluetooth, dan Ekspor/Backup Database Keamanan Terenkripsi.

---

## **16\. Rencana Fitur Lanjutan (Next Features Roadmap)**

Bagian ini mendokumentasikan fitur-fitur yang telah direncanakan di product backlog namun belum memiliki spesifikasi formal di PRD. Semua fitur di bagian ini **belum diimplementasi** dan menjadi target pengembangan fase berikutnya.

---

### **16.1. Inter-Outlet Stock Transfer & Visibility (Phase 3)**
*   **Deskripsi:** Memindahkan stok antar cabang secara terstruktur dan melihat ketersediaan barang di cabang lain langsung dari aplikasi kasir.
*   **Fitur:**
    *   **Stock Transfer Module**: Entitas `stock_transfers` yang mencatat perpindahan stok: `from_outlet_id` → `to_outlet_id` dengan status tracking (`SENT` / `IN_TRANSIT` / `RECEIVED`).
    *   **Cross-Outlet Stock Checker**: Tombol "Cek Cabang Lain" pada Product Grid untuk melihat stok outlet lain secara real-time (membutuhkan koneksi internet aktif).
    *   **Transfer History**: Riwayat lengkap perpindahan stok per outlet untuk audit trail.
*   **Dependensi:** Phase 3 Cloud Sync, UUID Migration (Phase 2) ✅, Outlet Infrastructure ✅.
*   **Tier:** Pro only.

---

### **16.2. Background Image Sync (Phase 5)**
*   **Deskripsi:** Pengunggahan foto nota belanja dan gambar produk secara asinkron ke Supabase Storage, bahkan saat internet tidak tersedia saat pengambilan gambar.
*   **Fitur:**
    *   **Upload Queue**: Antrian pengunggahan latar belakang menggunakan `work_manager` agar hemat baterai dan reliabel.
    *   **Retry Logic**: Mekanisme percobaan ulang otomatis jika koneksi terputus di tengah proses upload.
    *   **Offline Capture**: Kasir tetap bisa mengambil foto nota/kuitansi meskipun sedang offline; upload otomatis berjalan saat koneksi tersedia.
    *   **Supabase Storage Bucket**: Konfigurasi bucket dengan RLS Policies berbasis `outlet_id`.
*   **Tier:** Pro only.

---

### **16.3. Unified Auth & Tier-Based Logic (Phase 6)**
*   **Deskripsi:** Sistem pengecekan tier terpusat yang memastikan fitur Cloud Sync hanya aktif untuk akun Pro dan tidak berjalan secara tidak sengaja pada akun Lite.
*   **Fitur:**
    *   **Tier Provider**: `appTierProvider` terpusat sebagai single source of truth untuk status tier pengguna (`lite` / `pro`).
    *   **Sync Gating**: `SyncService` & `RealtimeService` hanya aktif jika tier terdeteksi sebagai Pro.
    *   **Metadata Sync**: Sinkronisasi `user_metadata['tier']` dari Supabase Auth ke database lokal SQLite.
    *   **UI Gating**: Menyembunyikan indikator sinkronisasi dan fitur multi-outlet jika user adalah Lite.
    *   **Upgrade Trigger**: Logika otomatis mengaktifkan Cloud Sync segera setelah perubahan tier terdeteksi.

---

### **16.4. In-App Pro Subscription Upgrade (Phase 4)**
*   **Deskripsi:** Alur upgrade ke Tier Pro langsung dari dalam aplikasi tanpa harus keluar ke browser atau menghubungi CS.
*   **Fitur:**
    *   **Payment Gateway (Backend Go)**: Integrasi Midtrans/Xendit untuk pembuatan invoice subscription (Snap/Redirect).
    *   **Billing Webview (Mobile)**: Layar pembayaran di dalam aplikasi menggunakan `WebView` untuk menyelesaikan transaksi tanpa keluar dari app.
    *   **Subscription Webhook Listener (Backend)**: Handler untuk menerima notifikasi pembayaran sukses dan mengupdate status `tier` menjadi `pro` di Supabase.
    *   **Upgrade Success Flow**: Animasi konfirmasi dan aktivasi fitur Pro segera setelah pembayaran berhasil.
*   **Dependensi:** Unified Tier Provider (§16.3).

---

### **16.5. Piutang / Bon Management**
*   **Deskripsi:** Pencatatan transaksi yang belum lunas (Bon/Kasbon) dengan kemampuan cicilan dan pengingat otomatis.
*   **Fitur:**
    *   **Debt Ledger**: Halaman khusus di menu Pelanggan yang menampilkan daftar tagihan terbuka per pelanggan beserta riwayat cicilannya.
    *   **Partial Payment**: Dukungan pembayaran cicilan (`debt_payments`) yang mengurangi saldo piutang secara bertahap.
    *   **WhatsApp Reminder**: Fitur "Kirim Pengingat" yang mengirimkan notifikasi tagihan ke nomor WA pelanggan.
    *   **Kasbon di POS**: Metode pembayaran `Kasbon` tersedia sebagai opsi tunggal di kasir (tidak dapat dikombinasikan dalam Split Payment).
*   **Catatan:** Kasbon/Piutang sudah terdaftar di Enum status transaksi (PRD §5), namun modul manajemennya belum ada.

---

### **16.6. Receipt Customization (Kustomisasi Struk)**
*   **Deskripsi:** Kemampuan Owner untuk mengonfigurasi informasi yang tercetak pada struk termal dan struk digital.
*   **Fitur:**
    *   **`ReceiptConfigScreen`**: Layar edit Header (nama toko, logo, alamat) dan Footer (ucapan terima kasih, akun media sosial, WiFi password) dengan live preview sebelum menyimpan.
    *   **Social Media Fields**: Input field untuk handle Instagram, Facebook, atau TikTok yang tercetak di footer struk.
    *   **Promo Footer**: Opsi menampilkan promo berjalan di bagian bawah struk sebagai marketing tool.
    *   **Font Size Control**: Pengaturan ukuran teks untuk printer thermal dengan lebar kertas berbeda (57mm / 80mm).

---

### **16.7. Batch & Expiry Date Tracking**
*   **Deskripsi:** Pelacakan tanggal kadaluwarsa dan nomor batch produk untuk mencegah penjualan barang basi dan manajemen FIFO.
*   **Fitur:**
    *   **Expiry Date pada Mutasi**: Kolom `expiry_date` dan `batch_number` pada tabel stock mutations (`stock_transactions` / `ingredient_stock_history`).
    *   **Expiry Alert**: Filter dan peringatan otomatis untuk produk yang kadaluwarsa dalam 7 dan 30 hari ke depan.
    *   **FIFO Recommendation**: Sistem merekomendasikan produk dengan batch terlama untuk dijual terlebih dahulu.
    *   **Waste Report**: Laporan produk yang di-write-off karena kadaluwarsa (terintegrasi dengan Stock Out).

---

### **16.8. Push Notifications — Low Stock & Proactive Alerts**
*   **Deskripsi:** Notifikasi push proaktif untuk kejadian penting yang membutuhkan perhatian Owner/Supervisor tanpa harus membuka aplikasi.
*   **Fitur:**
    *   **FCM Integration**: Integrasi Firebase Cloud Messaging (FCM) untuk pengiriman notifikasi ke perangkat Android.
    *   **Low Stock Alert**: Notifikasi otomatis saat stok produk atau bahan baku menyentuh batas `low_stock_threshold`.
    *   **Expiry Warning**: Notifikasi H-7 dan H-1 sebelum tanggal kadaluwarsa batch produk.
    *   **Daily Sales Summary**: Ringkasan penjualan harian yang dikirim setiap akhir hari (dapat dikonfigurasi).
    *   **Notification Preferences**: Owner dapat mengatur jenis notifikasi apa saja yang ingin diterima di Settings.

---

### **16.9. Split Bill (Pecah Tagihan per Item)**
*   **Deskripsi:** Memisahkan satu transaksi menjadi beberapa tagihan individual berdasarkan item yang dipilih — berbeda dengan Split Payment yang memecah metode bayar dalam satu tagihan.
*   **Fitur:**
    *   **Item Selection UI**: Kasir memilih item mana yang akan dimasukkan ke tagihan pertama, sisanya otomatis menjadi tagihan kedua.
    *   **Sub-Cart Management**: Setelah item dipilih, sistem membuat sub-keranjang baru (`draft_order`) untuk sisa item yang belum dibayar.
    *   **Parent Transaction Tracking**: Kolom `parent_transaction_id` untuk menghubungkan transaksi-transaksi yang dipecah dalam laporan rekonsiliasi.
    *   **Partial Receipt**: Struk terpisah per pecahan tagihan dengan label "Tagihan 1/2", "Tagihan 2/2", dsb.
*   **Catatan:** Berbeda fundamental dengan Split Payment (PRD §4.3 & §5) yang sudah diimplementasi.

---

### **16.10. Dynamic QRIS API Integration**
*   **Deskripsi:** Menampilkan QRIS dinamis yang di-generate secara real-time oleh payment gateway, sehingga nilai transaksi sudah terisi otomatis dan kasir tidak perlu memasukkan nominal di aplikasi dompet digital pelanggan.
*   **Fitur:**
    *   **QRIS Display di PaymentModal**: QR Code ditampilkan langsung di layar kasir saat metode QRIS dipilih, dengan nilai yang sudah terkunci sesuai total tagihan.
    *   **Payment Gateway Integration (Backend)**: Integrasi API Xendit/Midtrans untuk generate QRIS dinamis dan menerima callback konfirmasi pembayaran.
    *   **Auto-Confirmation**: Kasir tidak perlu konfirmasi manual — sistem otomatis mendeteksi pembayaran berhasil via webhook dan menutup transaksi.
    *   **Timeout Handling**: QRIS memiliki waktu kedaluwarsa (misalnya 5 menit) dengan opsi generate ulang.
*   **Catatan:** Berbeda dengan pencatatan QRIS statis yang sudah ada (recording only, PRD §10).

---

### **16.11. F&B Table Management (Manajemen Meja)**
*   **Deskripsi:** Sistem manajemen tata letak meja restoran secara visual untuk bisnis F&B dengan layanan dine-in.
*   **Fitur:**
    *   **Visual Floor Maker**: Antarmuka drag-and-drop untuk menyusun dan mengonfigurasi denah meja per zona/area.
    *   **Table Status Tracking**: Indikator visual real-time per meja — Hijau (Kosong), Merah (Terisi/Sedang Makan), Kuning (Menunggu Pembayaran).
    *   **Table Session**: Tabel `table_sessions` yang menghubungkan setiap transaksi ke meja fisik.
    *   **Pindah Meja**: Fitur memindahkan seluruh pesanan dari satu meja ke meja lain.
    *   **Gabung Tagihan (Merge Bill)**: Menggabungkan dua tagihan meja berbeda menjadi satu transaksi.
    *   **Integrasi Save Bill**: Bill yang tersimpan otomatis terikat ke meja tertentu.
*   **Tier:** Pro only (multi-outlet F&B).

---

### **16.12. Kitchen Display System (KDS)**
*   **Deskripsi:** Layar tampilan pesanan dapur (*paperless kitchen*) yang menerima order secara real-time dari kasir.
*   **Fitur:**
    *   **Order Grid**: Tampilan grid pesanan yang masuk, diurutkan berdasarkan waktu (FIFO) dengan status visual (Baru / Sedang Disiapkan / Selesai).
    *   **Local Network Sync**: Komunikasi real-time antara perangkat kasir dan perangkat KDS menggunakan WebSocket lokal (tidak memerlukan internet).
    *   **Item-Level Status**: Staff dapur dapat menandai setiap item pesanan sebagai selesai secara individual.
    *   **Alert Suara**: Bunyi notifikasi saat pesanan baru masuk ke layar KDS.
*   **Dependensi:** Table Management (§16.11) untuk informasi nomor meja.
*   **Tier:** Pro only.

---

### **16.13. Employee Commissions & Performance Tracking**
*   **Deskripsi:** Sistem komisi berbasis transaksi untuk memotivasi karyawan dan memantau performa penjualan individual.
*   **Fitur:**
    *   **Commission Rules**: Owner dapat menetapkan komisi per item produk (nominal Rp atau persentase %) yang terkait ke karyawan penjual.
    *   **Auto-Calculation**: Komisi dihitung dan dicatat otomatis setiap kali transaksi diselesaikan, berdasarkan karyawan yang sedang aktif shift.
    *   **Staff Performance Dashboard**: Laporan performa per karyawan: total transaksi, total nilai penjualan, dan total komisi dalam periode tertentu.
    *   **Commission Payout Log**: Riwayat pembayaran komisi yang dapat digunakan sebagai dasar penggajian.

---

### **16.14. Owner Global Dashboard Multi-Outlet (Phase 5)**
*   **Deskripsi:** Dashboard analitik agregasi lintas seluruh outlet untuk Owner dalam satu tampilan ringkasan.
*   **Fitur:**
    *   **Revenue Aggregation**: Total penjualan dari seluruh outlet dalam satu hari/minggu/bulan.
    *   **Outlet Comparison Charts**: Grafik batang/pie untuk komparasi performa antar outlet secara visual.
    *   **Top Products Cross-Outlet**: Produk terlaris secara keseluruhan vs per outlet.
    *   **Real-Time Sync**: Data diambil via Supabase RPC untuk agregasi yang efisien tanpa membebani client.
*   **Dependensi:** Cloud Sync (Phase 3) ✅, Inter-Outlet Infrastructure.
*   **Tier:** Pro only.
