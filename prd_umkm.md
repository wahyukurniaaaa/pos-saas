# **Product Requirements Document (PRD)**

**Produk:** Aplikasi Sistem Kasir (POS) SaaS Offline-First

**Versi:** 2.4 (UI Responsiveness & Brand Refresh)

**Status:** Implementasi Progresif (Phase 1-3, Phase 7-10 Selesai)

## **Update Log (v2.4):**
*   **UI Responsiveness & Brand Harmonization**: Standardisasi layout tablet menggunakan `ResponsiveCenter` (max-width 768px). Harmonisasi warna brand menggunakan Navy (`primaryColor`) dan Kuning (`secondaryColor`) di seluruh layar utama (Dashboard, PO, Inventory).
*   **Purple Ban Enforcement**: Pembersihan seluruh elemen UI dari warna ungu terlarang untuk menjaga konsistensi identitas brand.
*   **Versi App**: Bump ke `2.0.0 (Beta UI Refresh)`.

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
| **Penyimpanan** | Full Offline (SQLite via Drift ORM) | Hybrid (SQLite + Supabase via PowerSync) |
| **Backup Data** | **Manual/Auto Encrypted (AES-256)** | **Otomatis (Cloud Sync)** |
| **Aktivasi** | Online License Key & Heartbeat 24j | Login Akun SaaS |

## **4\. Fitur Utama (Functional Requirements)**

### **4.1. Modul Lisensi & Aktivasi**

* **Sistem Aktivasi:** Pengguna memasukkan kode lisensi dari email. Aplikasi melakukan validasi ke server Golang untuk mencatat *Device Fingerprint*.  
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
* **Manajemen Pemasok (Supplier):** [BARU]
    * Mendata profil pemasok (Nama, Kontak, Alamat).
    * Menautkan pemasok saat mencatat "Barang Masuk" (Stock In) untuk bahan baku, memudahkan pelacakan asal usul dan riwayat harga.
* **Manajemen Bahan Baku & Resep (Advanced Inventory) [BARU]:**
    * **Ingredient Maintenance**: Mengelola stok mentah (biji kopi, susu, gula) dengan satuan dasar (gr, ml, pcs).
    * **Stock Out & Waste Management**: Fitur "Stok Keluar" manual dengan pencatatan alasan (Misal: Kedaluwarsa, Rusak, Tumpah) untuk transparansi pengurangan inventaris.
    * **Recipe Builder**: Menentukan komposisi bahan baku per produk. Contoh: 1 cup "Copi Susu" memotong 15gr biji kopi dan 150ml susu.
    * **Auto-Stock Deduction**: Pemotongan stok bahan baku secara otomatis dan *real-time* saat transaksi pembayaran selesai (Checkout).
    * **Kalkulasi HPP (Weighted Moving Average)**: Sistem menghitung modal rata-rata secara otomatis setiap kali ada stok baru masuk (pembelian), memberikan akurasi laba kotor yang presisi bagi Owner.
    * **Unit Conversion**: Fleksibilitas input stok dalam satuan besar (Kg/Liter) yang otomatis dikonversi ke satuan penyimpan dasar (Gram/Ml) di database.
* **Pencatatan Pembayaran (Recording Only):** Memilih status pembayaran (**Tunai, QRIS, Debit, Kredit, Piutang/Bon**). Tidak ada integrasi gateway API untuk menghindari biaya MDR.  
* **Print & Share Engine:** 
    *   Cetak struk via Bluetooth/USB Thermal (Protokol ESC/POS).
    *   **WhatsApp Hybrid Sharing:** Mengirim struk digital (Image + Text summary) ke WhatsApp pelanggan.
    *   **CRM & Database Pelanggan (Member):** Sistem mendata identitas pelanggan untuk pencarian cepat saat *checkout*. Pelanggan terdaftar bisa dianalisis riwayat belanjanya.

### **4.4. Modul Backup & Restore (Tier 1)**

* **Auto-Local Backup (Failsafe):** Sistem secara otomatis mencadangkan database terenkripsi (AES-256) ke penyimpanan internal pada saat *Tutup Shift*.
* **Backup Export & Share:** Pengguna dapat membagikan file backup (.enc) ke email, WhatsApp, atau cloud storage secara manual.
* **Recovery Key Management:** Setiap perangkat memiliki Kunci Pemulihan unik yang diperlukan untuk mendekripsi file backup saat dipindahkan ke perangkat lain.
* **Data Migration:** Mendukung pemindahan data penuh antar perangkat dengan validasi ulang lisensi di perangkat tujuan.

### **4.5. Arsitektur Reactive Offline-First (Local State)**

*   **Database Engine:** Menggunakan **Drift ORM** di atas SQLite untuk memberikan lapisan keamanan pengetikan data (*Type-Safety*) penuh dan kehandalan struktur.
*   **Reactive UI:** Setiap perubahan data stok, status transaksi, atau operasional shift dari SQLite divisualisasikan secara *Real-Time* menggunakan *Stream* Drift ke antarmuka aplikasi Kasir (Flutter) tanpa membebani perangkat secara aktif.
*   **Tier 2 Readiness:** Struktur tabel dirancang agar sepenuhnya kompatibel dengan integrasi PowerSync (Server Sync) yang akan dihidupkan di iterasi bisnis mendatang dengan *coding overhaul* 0%.

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
|  | Alamat/Email | String, opsional. |
| **Profil Toko** | Nama Toko | String, max 50 karakter. Wajib diisi. (Untuk Struk). |
|  | Telp / Alamat | String. Telp Format numerik (opsional). Alamat (opsional). |
|  | Logo | Path ke Image lokal (`logoUri`). Mendukung cetak logo pada struk thermal. |
|  | Tax & Service | Numeric (0-100%). Enum tipe pajak {inclusive, exclusive}. Perhitungan Service Charge menggunakan persentase (%) dari subtotal. |
| **Transaksi** | Nomor Nota | Format: POS-YYYYMMDD-HHMMSS (Unik berbasis waktu). |
|  | Customer Info | `customerPhone` (WhatsApp) & `customerName` (Opsional). Digunakan untuk pengiriman struk digital & CRM. |
|  | Nilai Transaksi | Integrasi Subtotal, Tax Amount, Service Amount, dan Total Akhir (Nilai Integer/Pembulatan Rupiah). |
|  | Status Bayar | Enum: {Tunai, QRIS, Debit, Kredit, Piutang, **Void/Batal**}. |
|  | Void By | Jika status Void, field ini wajib terisi oleh PIN Supervisor/Owner (L2/L1). |
| **Bahan Baku** | Nama Bahan | String, unik. Contoh: "Susu UHT", "Biji Kopi Arabica". |
| (Baru) | Unit | Enum: {gr, ml, pcs}. Disimpan dalam satuan terkecil. |
|  | HPP (Avg Cost) | Numeric. Dihitung otomatis (Weighted Average). |
| **Resep** | Qty Needed | REAL. Jumlah bahan per 1 porsi produk. |

## **6\. Arsitektur Teknis & Tech Stack**

* **Backend:** **Go (Fiber)** untuk server generator & aktivasi lisensi.
* **Database Backend:** **PostgreSQL** untuk database lisensi (melalui GORM).
* **Database App:** **SQLite (via Drift ORM)** (Lokal) & **Supabase** (Master lisensi & akun owner).
* **Mobile Framework:** **Flutter** (Target Android APK).
* **Integrasi:** Google Drive API (Backup) & ESC/POS (Printing).

## **7\. Fase Pengembangan (Roadmap)**

* **Fase 1 (Bulan 1):** Development Backend License Generator (Go), Setup Supabase, & Integrasi Email Lisensi.  
* **Fase 2 (Bulan 2):** Development App Kasir (Flutter), SQLite, Modul Import Excel, & Manajemen Stok Lokal.  
* **Fase 3 (Bulan 3):** Implementasi Modul Aktivasi Offline, Google Drive Backup, & Peluncuran Resmi APK Tier 1\.  
* **Fase 4 (Bulan 4+):** Pengembangan Tier 2 (Pro) mencakup integrasi PowerSync (Cloud Sync), Multi-outlet, & Dashboard Web.

## **8\. User Stories Detail**

### **8.1. Peran: Owner (Level Teratas - L1)**

* **Setup Awal:** Sebagai Owner, setelah memasukkan kode lisensi yang valid, saya wajib mendata Nama dan PIN 6-digit saya untuk akun Owner yang sah. 
* **Aktivasi Offline:** Saya ingin menginput lisensi dari email agar aplikasi aktif selamanya tanpa perlu internet lagi.  
* **Manajemen Master Produk:** Saya ingin menambah produk sederhana (seperti sabun) atau kompleks beserta Varian & Foto Produk (seperti ukuran Baju/Rasa Kopi) agar memudahkan kasir dalam memilih item pesanan.
* **Manajemen Karyawan:** Saya ingin menambah banyak akun Kasir/Supervisor, melampirkan foto profil mereka (opsional), mengatur PIN 6-digit yang berbeda tanpa biaya tambahan, dan memantau akun yang terkunci akibat salah PIN 5x.
* **Konfigurasi Biaya:** Saya ingin mengatur besaran persentase Pajak (PPN/PB1) secara *inclusive* atau *exclusive*, serta menetapkan *Service Charge* (%) agar sistem otomatis menghitungnya ke total belanjaan pelanggan. Perhitungan pajak bersifat dinamis dan akan di-record nilainya (nominal) pada setiap nota.
* **Branded Receipt:** Saya ingin mengunggah logo toko saya agar struk fisik (Thermal) maupun struk digital (WhatsApp) terlihat lebih profesional.
* **Monitoring Lengkap & Profitabilitas:** Sebagai Owner, saya ingin melihat menu analitik (Laporan Penjualan, tren, **Laba Kotor (Gross Profit)**, dan Kategori paling menguntungkan) demi mengevaluasi performa bisnis.
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
* **Pembayaran:** Saya ingin memilih metode pembayaran (Tunai/QRIS/Debit) secara manual agar laporan akhir shift akurat.  
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

* **OS:** Android 10+ / iOS 14+.  
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

### **14.1. Alur Aktivasi Lisensi**

Input Kode Lisensi \-\> Validasi Backend Go \-\> Generate Device Fingerprint \-\> Simpan Token ke SQLite \-\> Mode Offline Aktif.

### **14.2. Alur Transaksi & Navigasi Utama**

PIN Login Karyawan (L3/L2/L1) -> Dashboard Utama (4 Tab: Kasir, Riwayat, Stok, Setting) -> [Opsional] Buka Shift -> Scan Barcode -> Tekan Tombol BAYAR -> Cari/Input Data Pelanggan (Member) -> Pilih Metode Bayar -> Selesaikan Pembayaran -> Update Stok & Catat Kartu Stok (SALE) -> Tampil Animasi Sukses -> Pilih [Cetak Struk] atau [Bagikan ke WhatsApp]. Riwayat transaksi dapat diakses langsung dari navbar tanpa masuk ke menu Setting.

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

