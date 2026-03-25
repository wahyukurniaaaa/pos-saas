# UI/UX Screen Flow & Database Draft (POSify)

## 1. Konsep UI/UX (Mobile-First & Touch Psychology)

Berdasarkan pedoman `mobile-design`:
- **Thumb Zone:** Navigasi utama (Tab Bar / Bottom Nav) dan tombol aksi utama (CTA seperti "Bayar", "Simpan") ditempatkan di bagian bawah layar.
- **Touch Target:** Semua tombol minimal 48dp x 48dp (standar Material Android / ideal touch).
- **Offline Context:** Tidak ada indikator "Loading dari Server" yang memblokir UI saat transaksi (selalu optimistik lokal). Layar akan responsif seketika (Reactive Stream via Drift ORM).
- **Efisiensi Cepat:** Pencarian produk mendukung Barcode Scanner, dan interaksi kasir meminimalisir pindah-pindah layar (Vertical Feed untuk keranjang belanja).

---

## 2. Struktur Layar (Screen Flow) Flutter

### **A. Flow Inisiasi & Otorisasi**
1. **[Screen] Splash & License Check**
   - System mengecek Token SQLite. Jika kosong -> Buka **License Activation Screen**. Jika ada -> Buka **PIN Login Screen**.
2. **[Screen] License Activation (1x Online)**
   - Input field untuk Kode Lisensi.
   - Tombol CTA: "Aktifkan Perangkat" (Hit server Go).
   - Setelah sukses tersimpan di SQLite, arahkan ke layar **Setup Owner**.
3. **[Screen] Setup Profil Owner & Toko (Satu Kali Saja)**
   - Tampil tepat setelah lisensi berhasil diaktivasi pertama kali.
   - Input Pribadi: Nama Pemilik.
   - Input Usaha: Nama Toko, Alamat (Opsional), No HP (Opsional).
   - Input Keamanan: Pembuatan PIN Akses 6 Digit (Masukkan PIN & Konfirmasi PIN).
   - CTA: "Mulai Gunakan POSify". Sistem akan membuat *record* di tabel `employees` (Role L1) dan `store_profile`.
4. **[Screen] PIN Login**
   - Numpad besar (memenuhi 50% layar bawah).
   - Indikator 6 titik untuk input PIN.
   - CTA: Otomatis masuk jika 6 digit terpenuhi & valid. Memicu pengecekan *Role* (Karyawan Level 1/2/3).

### **B. Flow Kasir (Main Workspace - Role L1, L2, L3)**
1. **[Screen] Pos Dashboard (Tab 1: Kasir)**
   - **Header:** Nama Kasir, Status Shift (Buka/Tutup). Jika shift tutup, memblokir area keranjang dengan tombol "Buka Shift".
   - **Kiri/Atas (Katalog):** Grid produk populer & Search bar + Icon Barcode.
   - **Kanan/Bawah (Keranjang):** List item yang dipilih + Total Harga.
   - **Floating Bottom CTA:** "BAYAR - Rp X.XXX" (Sangat besar).
2. **[Screen] Laporan Shift Berjalan (Current Shift Analytics)**
   - Kasir (L3) menekan icon "i" atau tombol laporan pada **Header** (di sebelah status shift).
   - Menampilkan total penjualan sementara, uang kas awal, dan estimasi uang laci.
   - Tombol peringatan atau peringkasan jika ada transaksi void/batal.
   - Tersedia tombol "Tutup Shift" besar di bawah untuk sesi *closing end-of-day*.
3. **[Screen] Payment Modal (Bottom Sheet)**
   - Muncul dari bawah saat CTA Bayar ditekan.
   - Menampilkan rincian Subtotal, Nilai Pajak & Service (Jika Ada), dan Total Tagihan.
   - Pilihan metode bayar (Tunai, QRIS, dll) -> Tombol *grid* besar.
   - **Informasi Pelanggan (CRM):** Field input untuk Nomor WhatsApp dan Nama Pelanggan (Opsional) untuk pengiriman struk digital.
   - Input uang diterima (jika tunai) dengan Quick Cash buttons (Rp 50K, 100K).
   - CTA: "Selesaikan Pembayaran". Memicu print struk & insert ke DB.
6. **[Screen] Transaction Success**
   - Animasi *check* / Haptic feedback *Success* (sesuai *Touch Psychology*).
   - Info ringkas: "Kembalian: Rp X.XXX".
   - Tiga CTA: "Cetak Ulang Struk" (Secondary), **"Bagikan ke WhatsApp" (Success Green)**, dan "Lanjut Transaksi Baru" (Primary).

### **C. Flow Manajemen Stok (Tab 2: Inventory - Role L1, L2)**
1. **[Screen] Inventory List**
   - List produk dengan info Stok Fisik saat ini. Memiliki opsi "Filter/Search".
   - Tombol indikator visual jika stok menipis (Merah/Kuning).
   - Floating Action Button (FAB) di pojok bawah: "Tambah Produk".
2. **[Screen] Add/Edit Product (Form)**
   - Input field: Nama, Kategori (Dropdown), Harga Beli, Harga Jual, SKU/Barcode, Gambar Produk, Stok.
   - Tombol Scan Barcode via kamera di sebelah input SKU.
   - CTA "Simpan" di ujung form.
3. **[Screen] Supplier Management (List, Form) [NEW]**
   - List pemasok dengan info kontak.
   - Form Manajemen Pemasok: Nama Pemasok, Kontak, Alamat.
4. **[Screen] Ingredient Management (List, Form, History) [NEW]**
   - List bahan baku (susu, kopi, dll) dengan filter & search.
   - Form Manajemen Bahan: Nama, Satuan Dasar (gr/ml/pcs), Min Stok, Modal Awal.
   - **Modal Tambah Stok**: Input jumlah, harga beli baru, dan **Pemilihan Pemasok (Supplier)**.
   - **Form Stok Keluar (Waste)**: Input jumlah keluar dan catatan/alasan (misal: Rusak, Kadaluarsa).
   - **Kartu Stok Bahan**: Riwayat kronologis mutasi bahan baku (Penjualan/Pembelian/Penyesuaian).
5. **[Screen] Recipe Builder (Nested in Add/Edit Product) [NEW]**
   - Bagian khusus dalam form produk untuk memilih bahan baku dan input kuantitas per porsi.
   - Otomatis menampilkan satuan bahan yang dipilih sebagai label input.

3. **[Screen] Import CSV / Excel**
   - Tampilan panduan format kolom yang wajib.
   - Tombol "Pilih File Document" (Membuka *File Picker* bawaan OS).
   - Menampilkan *preview* 5 baris pertama sebelum dieksekusi ke SQLite.
4. **[Screen] Stock Opname (Penyesuaian)**
   - Mode edit stok cepat (mirip form list).
   - Kasir/L3 tidak bisa mengakses ini.

### **D. Flow Manajemen (Tab 3: Settings - Role L1 Owner)**
1. **[Screen] Settings & Data**
   - Menu: Profil Toko, Kelola Pegawai, Kelola Kategori, Riwayat Transaksi (Nota & Void), Laporan Penjualan, Riwayat Shift, Pengaturan Printer, Backup Data.
2. **[Screen] Employee Management (List Karyawan)**
   - Menampilkan list nama karyawan, *Role*, dan status aktif/non-aktif.
   - Cukup tap nama untuk ke form Edit. Tersedia FAB "Tambah Karyawan".
3. **[Screen] Add/Edit Employee (Form)**
   - Input: Foto (Opsional, dari galeri/kamera), Nama, Role (Dropdown L1/L2/L3).
   - Input: PIN Akses (Numpad, 6 Digit, disamarkan *bullet points*).
   - CTA "Simpan". Jika PIN duplikat/mudah ditebak, sistem memunculkan Snackbar error merah.
4. **[Screen] Master Kategori**
   - Diakses dari menu "Master Data".
   - Menampilkan list kategori (Makanan, Minuman, dsb).
   - Form pop-up / layar kecil untuk Tambah/Edit/Hapus nama kategori.
5. **[Screen] Laporan Penjualan & Analitik Laba (Dashboard)**
   - Header: Filter rentang waktu (Hari ini, 7 Hari Terakhir, Bulan Ini, Tahun Ini).
   - Card Ringkasan: Total Pendapatan, Total Transaksi, AOV, dan **Total Laba Kotor**.
   - Chart/Garis sederhana tren penjualan.
   - Daftar 5 Produk Paling Laris (Kuantitas vs Laba).
   - Analisa Kategori (berdasarkan Laba).
5. **[Screen] Riwayat Transaksi & Pembatalan (Void)**
   - Menampilkan list semua nota transaksi hari ini / yang difilter.
   - Ketika nota di-tap, muncul Pop-up Detail Nota (Item yang dibeli, Harga, Waktu).
   - Di dalam detail nota, ada CTA "Batalkan Transaksi (Void)".
   - Jika Kasir (L3) yang menekan Void, akan muncul **Modal Auth Supervisor** meminta PIN 6-digit milik Supervisor (L2) atau Owner (L1) sebelum pembatalan disahkan. Transaksi yang di-void akan mengembalikan stok produk (Reverse).
6. **[Screen] Daftar Shift & Riwayat**
   - List riwayat sesi Kasir (Buka - Tutup).
   - Info tiap baris: Nama Kasir, Waktu, Selisih Uang Laci (Actual vs Expected).
   - Kasir (L3) hanya bisa melihat riwayat shift miliknya sendiri, sementara L1/L2 bisa lihat semua.
76. **[Screen] Pengaturan Printer (Bluetooth)**
   - Scanning perangkat Bluetooth di sekitar.
   - List perangkat yang ditemukan.
   - Status: "Sedang Terkoneksi" atau "Terputus".
   - Tombol "Print Test Page" untuk verifikasi koneksi.
7. **[Screen] Pengaturan Pajak & Biaya Layanan**
   - Toggle switch aktif/nonaktifkan Pajak.
   - Input % Pajak dan Radio Button (Inclusive / Exclusive).
   - Input % Service Charge.
8. **[Screen] Backup & Restore**
   - CTA: "Backup ke Storage Internal" (Manual trigger).
   - CTA: "Export ke Google Drive".

---

## 3. Ekstraksi Kebutuhan Tabel Database (Drift ORM Draft 1)

Dari flow UI di atas, kita membutuhkan struktur *Class List Table* di layer Drift ORM:

1. **`licenses`** (Menyimpan status aktivasi & *device fingerprint*).
2. **`users`** (karyawan, PIN, Role L1/L2/L3).
3. **`categories`** (master kategori).
4. **`products`** (master barang, harga master, stok master, `image_uri`). Stok dan Harga Master hanya dipakai jika tidak ada record di `product_variants`.
5. **`product_variants`** (BARU: id, `product_id`, `name`, `sku`, `price`, `stock`).
6. **`sessions`** (logik buka tutup shift kasir).
   - Kolom: `employee_id`, `start_time`, `end_time`, `starting_cash`, `ending_cash`, `actual_cash`.
7. **`transactions`** & **`transaction_items`** (Pencatatan nota kasir).
   - Kolom `status_bayar` (Tunai, QRIS, dll). Terikat pada `shift_id`.
   - Kolom CRM: `customer_phone`, `customer_name` (Untuk WhatsApp sharing).
   - `transaction_items` memiliki kolom opsional `variant_id` (jika produk varian terjual).
8. **`stock_adjustments`** (Log jejak audit saat Supervisor/Owner mengubah stok / *Stock Opname*. Terikat pada `product_id` dan/opsional `variant_id`).
9. **`backup_logs`** (Mencatat kapan terakhir *Auto-Local Backup* berjalan).
10. **`store_profile`** (Data tunggal profil toko: Nama, Alamat, Telp, **`logo_uri`** untuk kop struk).
11. **`suppliers`** (BARU: id, name, contact, address).
12. **`ingredients`** (BARU: id, name, unit, stock_quantity, average_cost, `last_supplier_id`).
13. **`product_recipes`** (BARU: id, product_id, ingredient_id, quantity_needed).
14. **`ingredient_stock_history`** (BARU: log mutasi bahan baku, termasuk `supplier_id` untuk barang masuk, dan `reason` untuk stok keluar/penyesuaian).

---
*Dokumen ini adalah draf kasar untuk diskusi arsitektur sebelum diubah ke `implementation_plan.md`.*
