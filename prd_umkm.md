# **Product Requirements Document (PRD)**

**Produk:** Aplikasi Sistem Kasir (POS) SaaS Offline-First

**Versi:** 1.8 (Konsolidasi Total & Final MVP)

**Status:** Siap Pengembangan

## **1\. Ringkasan Eksekutif**

Aplikasi POSify adalah sistem Point of Sale (POS) yang dirancang khusus untuk UMKM dengan pendekatan *offline-first*. Fokus utama produk ini adalah memberikan alternatif yang terjangkau melalui model **Lifetime License (Sekali Bayar)** pada Tier 1, menghilangkan beban langganan bulanan bagi pengusaha kecil. Aplikasi berjalan penuh pada database lokal (SQLite) yang terenkripsi dan hanya membutuhkan koneksi internet satu kali untuk aktivasi lisensi awal serta proses pencadangan data manual.

## **2\. Target Pengguna**

* **Pemilik UMKM Ritel & F\&B Kecil:** Pengusaha yang menginginkan kepastian biaya operasional tanpa biaya langganan tetap.  
* **Bisnis di Area Internet Tidak Stabil:** Membutuhkan kecepatan operasional tanpa bergantung pada latensi *cloud*.  
* **Outlet Tunggal dengan Banyak Karyawan:** Membutuhkan manajemen peran (Owner, Supervisor, Kasir) tanpa biaya tambahan per lisensi pengguna.

## **3\. Struktur Tier & Model Bisnis**

| Fitur | Tier 1: Lite (Lifetime Pay) | Tier 2: Pro (Subscription) |
| :---- | :---- | :---- |
| **Model Biaya** | **Sekali Bayar (Lifetime)** | Langganan Bulanan/Tahunan |
| **Batas Outlet** | 1 Outlet (Terkunci pada Perangkat) | Hingga 3 Outlet |
| **Batas Perangkat** | 1 Perangkat Utama | Multi-perangkat (Sync Cloud) |
| **Batas Karyawan** | **Tidak Terbatas (Lokal)** | Tidak Terbatas |
| **Akses Peran** | Hierarki Kumulatif (L1, L2, L3) | Hierarki Kumulatif (L1, L2, L3) |
| **Manajemen Stok** | Stok In/Out & Opname (Lokal) | Multi-Gudang & Sync Cloud |
| **Penyimpanan** | Full Offline (SQLite via Drift ORM) | Hybrid (SQLite + Supabase via PowerSync) |
| **Backup Data** | **Manual ke Google Drive/Lokal** | **Otomatis (Cloud Sync)** |
| **Aktivasi** | Online License Key (1x) | Login Akun SaaS |

## **4\. Fitur Utama (Functional Requirements)**

### **4.1. Modul Lisensi & Aktivasi**

* **Sistem Aktivasi:** Pengguna memasukkan kode lisensi dari email. Aplikasi melakukan validasi ke server Golang satu kali untuk mencatat *Device Fingerprint*.  
* **Offline Mode:** Setelah aktivasi, seluruh fungsi kasir dan manajemen stok bekerja 100% tanpa internet.

### **4.2. Manajemen Role & Hierarki (Kumulatif)**

Sistem menggunakan PIN 6-digit untuk beralih antar peran dengan tingkat akses:

* **Owner (Level 1):** Akses total. Manajemen lisensi, manajemen karyawan (tambah/edit PIN), manajemen produk/stok, laporan laba rugi, dan operasional kasir.  
* **Supervisor (Level 2):** Manajemen stok, Stock Opname (Penyesuaian), Otorisasi Void/Refund transaksi kasir, dan operasional kasir.  
* **Kasir (Level 3):** Terbatas pada operasional transaksi harian, buka/tutup shift, dan laporan penjualan shift berjalan.

### **4.3. Modul Kasir & Inventaris (Offline)**

* **Manajemen Produk:** Input manual satu-per-satu atau impor massal via file Excel/CSV secara offline.  
* **Manajemen Stok Lokal:** Pencatatan stok masuk, stok keluar, dan penyesuaian (*stock opname*).  
* **Pencatatan Pembayaran (Recording Only):** Memilih status pembayaran (**Tunai, QRIS, Debit, Kredit, Piutang/Bon**). Tidak ada integrasi gateway API untuk menghindari biaya MDR.  
* **Print Engine:** Cetak struk via Bluetooth/USB Thermal (Protokol ESC/POS).

### **4.4. Modul Backup & Restore (Tier 1)**

* **Auto-Local Backup (Failsafe):** Sistem secara otomatis mencadangkan file database (dengan ekstensi khusus, terenkripsi) ke folder penyimpanan perangkat (misal: `/Documents/POSify`) pada titik krusial (seperti saat *Tutup Shift*). Ini mencegah kehilangan data akibat *human error* kelupaan *backup*.
* **Manual Cloud Export:** Fitur pencadangan sekunder ke **Google Drive** pribadi pengusaha sebagai antisipasi jika perangkat fisik hilang atau rusak berat.
* **Data Recovery:** Proses memulihkan dan memuat ulang data operasional dari titik *backup* lokal maupun *cloud* jika melakukan perpindahan atau *reset* perangkat.

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
|  | Harga Beli / Jual | Numeric. Minimal 0\. Tidak boleh negatif. |
|  | Stok | Integer. Default 0\. |
|  | Gambar Produk | Path ke Image Device lokal, opsional. |
| **Kategori** | Nama Kategori | String, max 50 karakter. Wajib diisi & **Unik**. |
| **User (Karyawan)**| Nama User | String, max 50 karakter. Wajib diisi. |
|  | Role (Level) | Enum: {Owner (L1), Supervisor (L2), Kasir (L3)}. |
|  | PIN | Numeric, **Tepat 6 digit**. Wajib unik per perangkat. Dilarang menggunakan pola umum (ex: 123456, 000000). Sistem menerapkan *cooldown* / blokir sementara jika 5x berturut-turut gagal login. |
|  | Foto Profil | Path ke Image Device lokal, opsional. |
| **Profil Toko** | Nama Toko | String, max 50 karakter. Wajib diisi. (Untuk Struk). |
|  | Telp / Alamat | String. Telp Format numerik (opsional). Alamat (opsional). |
|  | Tax & Service | Numeric (0-100%). Enum tipe pajak {inclusive, exclusive}. Perhitungan Service Charge menggunakan persentase (%) dari subtotal. |
| **Transaksi** | Nomor Nota | Format: POS-YYYYMMDD-HHMMSS (Unik berbasis waktu). |
|  | Nilai Transaksi | Integrasi Subtotal, Tax Amount, Service Amount, dan Total Akhir (Nilai Integer/Pembulatan Rupiah). |
|  | Status Bayar | Enum: {Tunai, QRIS, Debit, Kredit, Piutang, **Void/Batal**}. |
|  | Void By | Jika status Void, field ini wajib terisi oleh PIN Supervisor/Owner (L2/L1). |

## **6\. Arsitektur Teknis & Tech Stack**

* **Backend:** **Go (Fiber)** untuk server generator & aktivasi lisensi.  
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
* **Manajemen Produk:** Saya ingin menambah produk secara manual (dengan fitur lampiran foto/gambar) atau **Impor via Excell/CSV** agar katalog cepat tersedia.  
* **Manajemen Karyawan:** Saya ingin menambah banyak akun Kasir/Supervisor, melampirkan foto profil mereka (opsional), mengatur PIN 6-digit yang berbeda tanpa biaya tambahan, dan memantau akun yang terkunci akibat salah PIN 5x.
* **Konfigurasi Biaya:** Saya ingin mengatur besaran persentase Pajak (PPN/PB1) secara *inclusive* atau *exclusive*, serta menetapkan *Service Charge* (%) agar sistem otomatis menghitungnya ke total belanjaan pelanggan. Perhitungan pajak bersifat dinamis dan akan di-record nilainya (nominal) pada setiap nota.
* **Monitoring Lengkap:** Sebagai Owner, saya ingin melihat menu analitik (Laporan Penjualan bulanan, tren penjualan, & riwayat Sesi Buka/Tutup Kasir) demi evaluasi dan pelacakan *fraud* kasir.  
* **Data Safety:** Sebagai Owner, saya ingin mencadangkan data ke Google Drive secara manual, atau *Auto-Local Backup* (otomatis) di *storage internal* untuk keamanan.

### **8.2. Peran: Supervisor (L2)**

* **Manajemen Stok Utama:** Saya ingin menambah stok manual dan melakukan **Stock Opname**, yakni memasukkan stok fisik, melihat perbandingan dengan stok di sistem, sekaligus menulis alasan penambahan/pengurangan di log riwayat.
* **Monitoring Shift:** Saya ingin melihat Laporan Shift & Analytics untuk mengecek uang kasir.
* **Otorisasi Transaksi:** Saya ingin memasukkan PIN saya untuk menyetujui pembatalan (*void*) transaksi yang diajukan kasir.  
* **Operasional:** Saya ingin bisa masuk ke menu kasir untuk membantu melayani antrean pelanggan.

### **8.3. Peran: Kasir**

* **Manajemen Shift:** Saya ingin melakukan "Buka Shift" (input saldo awal) dan "Tutup Shift" (closing) agar uang tunai di laci dapat dipertanggungjawabkan.  
* **Transaksi Cepat:** Saya ingin mencari produk via scan barcode agar pelayanan cepat.  
* **Pembayaran:** Saya ingin memilih metode pembayaran (Tunai/QRIS/Debit) secara manual agar laporan akhir shift akurat.  
* **Struk Fisik:** Saya ingin mencetak struk belanja via Bluetooth segera setelah transaksi selesai sebagai bukti bagi pelanggan.  
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

### **14.2. Alur Transaksi Kasir**

PIN Login Karyawan (L3/L2/L1) \-\> Dashboard Utama \-\> [Opsional] Buka Shift & Input Saldo Kas Awal \-\> Scan Barcode/Input Keranjang \-\> Tekan Tombol BAYAR \-\> Pilih Metode Bayar & Input Nominal (dengan fitur Quick Cash Buttons) \-\> Update Stok SQLite \-\> Tampil Animasi Sukses (Haptic Feedback) & Info Kembalian \-\> Print Struk.

### **14.3. Alur Stock Opname (Penyesuaian Stok)**

Pilih Produk \-\> Input Jumlah Fisik Aktual \-\> Sistem Hitung Selisih \-\> Supervisor Input Alasan Selisih \-\> Update Stok SQLite \-\> Simpan Log Histori.

### **14.4. Alur Input Karyawan (Owner)**

Masuk Pengaturan \-\> Tambah Karyawan \-\> Input Nama & Pilih Role (L2/L3) \-\> Input PIN 6 Digit (Unik) \-\> Simpan SQLite.

### **14.5. Alur Input Produk Manual (Owner/Supervisor)**

Masuk Setting (Master Data) \-\> Tambah Produk / Import CSV \-\> Input Nama, SKU, Harga Beli/Jual, Gambar, & Stok Awal \-\> Simpan SQLite.

### **14.6. Alur Penutupan Sesi (End-of-Day Kasir)**

Tekan Ikon Laporan (Header) \-\> Cek Laporan Shift Berjalan (Current Shift Analytics & Prediksi Laci) \-\> Tekan "Tutup Shift" \-\> Input Aktual Uang Fisik laci \-\> Simpan Selisih (+/-) \-\> Auto-Local Backup berjalan \-\> Logout.

