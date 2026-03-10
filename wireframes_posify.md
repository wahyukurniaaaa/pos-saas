# 🎨 POSify - ASCII Wireframes (Draft)

Berikut adalah representasi visual sketsa (wireframe) kasar untuk aplikasi POSify berbasis Flutter agar susunan komponen UI (*Touch Target* & *Thumb Zone*) lebih mudah dibayangkan.

---

### 1. Inisiasi & Setup Owner (Satu Kali Saja)

**A. Form Aktivasi Lisensi:**
```text
+---------------------------------------+
|                                       |
|                                       |
|           === POSify ===              |
|          Lisensi Seumur Hidup         |
|                                       |
|   Masukkan Kode Lisensi dari Email    |
|  +---------------------------------+  |
|  | XXXX-YYYY-ZZZZ-WWWW             |  |
|  +---------------------------------+  |
|                                       |
|  [     AKTIFKAN PERANGKAT INI      ]  |
|                                       |
|                                       |
|   *Membutuhkan koneksi internet 1x    |
+---------------------------------------+
```

**B. Setup Profil Owner & Toko:**
```text
+---------------------------------------+
|                                       |
|           === POSify ===              |
|      Pengaturan Pemilik & Toko        |
|                                       |
|   👤 Nama Pemilik                     |
|  +---------------------------------+  |
|  | Bapak Budi                      |  |
|  +---------------------------------+  |
|                                       |
|   🏪 Nama Toko                        |
|  +---------------------------------+  |
|  | Toko Budi Jaya                  |  |
|  +---------------------------------+  |
|                                       |
|   🔒 Buat PIN Akses (6 Digit)         |
|  +---------------------------------+  |
|  | * * * * * *                     |  |
|  +---------------------------------+  |
|   Konfirmasi PIN                      |
|  +---------------------------------+  |
|  | * * * * * *                     |  |
|  +---------------------------------+  |
|                                       |
|  [     MULAI GUNAKAN POSIFY        ]  |
+---------------------------------------+
```

---

### 2. Login & Workspace Kasir (Operasional Harian)

**A. PIN Login Karyawan:**
```text
+---------------------------------------+
|                                       |
|                                       |
|           === POSify ===              |
|                                       |
|          Masukkan PIN Anda            |
|                                       |
|            * * * . . .                |
|                                       |
|                                       |
|        [ 1 ]  [ 2 ]  [ 3 ]            |
|        [ 4 ]  [ 5 ]  [ 6 ]            |
|        [ 7 ]  [ 8 ]  [ 9 ]            |
|        [ C ]  [ 0 ]  [ < ]            |
|                                       |
|                                       |
|                                       |
+---------------------------------------+
```

**B. Dashboard Kasir (Main Workspace):**
```text
+---------------------------------------+
| 👤 Siti (Kasir) | 🟢 Shift Buka  [i]  |
| [🔍 Cari Produk / Scan...        [📷]]|
+-----------------------+---------------+
| ⭐ Populer            | 🛒 Keranjang  |
|                       |               |
| +-------+   +-------+ | Indomie Grg x2|
| | 🍜    |   | ☕    | | Rp 7.000      |
| | Rp 3K |   | Rp 5K | |               |
| +-------+   +-------+ | Teh Pucuk   x1|
|                       |               |
| +-------+   +-------+ | Rp 4.000      |
| | 🥤    |   | 🍞    | |               |
| | Rp 4K |   | Rp 8K | |               |
| +-------+   +-------+ |               |
+-----------------------+---------------+
|         Total: Rp 11.000              |
|                                       |
|     [ 💳 BAYAR - Rp 11.000 ]          |
+---------------------------------------+
| 🏠 POS    |  📦 Stok   | ⚙️ Setting   |
+---------------------------------------+
```

---

### 3. Analytics & Modal Pembayaran

**A. Modal Pembayaran (Bottom Sheet dari tombol Bayar):**
```text
+---------------------------------------+
| 💳 PEMBAYARAN                         |
|    Subtotal: Rp 10.000                |
|    Pajak PB1 (10%): Rp 1.000          |
|    Total Tagihan: Rp 11.000           |
|                                       |
| Metode Pembayaran (Pilih Salah Satu): |
| +-------+ +-------+ +-------+ +-----+ |
| | 💵    | | 📱    | | 💳    | | 📝  | |
| | Tunai | | QRIS  | | Debit | | Bon | |
| +-------+ +-------+ +-------+ +-----+ |
|                                       |
| Informaasi Pelanggan (CRM):             |
|  +-----------------------------------+ |
|  | [Icon] Nomor WhatsApp (Wajib)      | |
|  | [Icon] Nama Pelanggan (Opsional)   | |
|  +-----------------------------------+ |
|                                       |
| [      SELESAIKAN PEMBAYARAN        ] |
+---------------------------------------+
| 🏠 POS    |  📦 Stok   | ⚙️ Setting   |
+---------------------------------------+
```

**B. Sukses Transaksi:**
```text
+---------------------------------------+
|                                       |
|                                       |
|               ✅                      |
|      TRANSAKSI BERHASIL               |
|                                       |
|      Kembalian: Rp 9.000              |
|                                       |
|                                       |
|    [ 🖨️ CETAK ULANG STRUK ]           |
|                                       |
|    [ 🟢 BAGIKAN KE WHATSAPP ]         |
|                                       |
|  [    LANJUT TRANSAKSI BARU       ]   |
|                                       |
|                                       |
+---------------------------------------+
```

**C. Laporan Shift Berjalan (Dibuka dari Icon [i]):**
```text
+---------------------------------------+
| [←] Kembali                           |
|      📊 Laporan Shift Berjalan        |
+---------------------------------------+
|                                       |
|  👤 Kasir           : Siti (Level 3)  |
|  🕒 Mulai Shift     : 08:00 WIB       |
|                                       |
|  -----------------------------------  |
|  💵 Uang Kas Awal        Rp 100.000   |
|  📈 Penjualan Tunai      Rp 350.000   |
|  📱 Penjualan QRIS       Rp 120.000   |
|                                       |
|  🔴 Batal / Void (1)    -Rp  15.000   |
|  -----------------------------------  |
|  💰 Estimasi Uang Laci   Rp 435.000   |
|                                       |
|                                       |
|                                       |
|                                       |
|     [ 🔒 TUTUP SHIFT SEKARANG ]       |
+---------------------------------------+
```

---

### 4. Inventaris & Manajemen Produk (Tab 2)

**A. Inventory List:**
```text
+---------------------------------------+
| 📦 Inventaris Produk                  |
| [🔍 Cari Produk / SKU...             ]|
+---------------------------------------+
| Indomie Goreng Spesial         [ ⋮ ]  |
| SKU: 899123456789     Stok: 24        |
| Rp 3.500                              |
|---------------------------------------|
| Kopi Kapal Api Mix             [ ⋮ ]  |
| SKU: 899987654321     Stok: 5  [!]    |
| Rp 1.500                              |
|---------------------------------------|
| Teh Pucuk Harum 350ml          [ ⋮ ]  |
| SKU: 899345678901     Stok: 12        |
| Rp 4.000                              |
|                                       |
|  [ 📁 Import CSV ]   [ 📝 Opname   ]  |
|                                       |
|  [         ➕ TAMBAH PRODUK        ]  |
+---------------------------------------+
| 🏠 POS    |  📦 Stok   | ⚙️ Setting   |
+---------------------------------------+
```

**Layar Tambah / Edit Produk:**
```text
+---------------------------------------+
| [←] Tambah Produk Utama         [💾]  |
+---------------------------------------+
|                                       |
|       +-----------------------+       |
|       |     [ 📷 FOTO ]       |       |
|       |   (Tap to Upload)     |       |
|       +-----------------------+       |
|                                       |
|   Nama Produk*                        |
|  +---------------------------------+  |
|  | Kemeja Flannel                  |  |
|  +---------------------------------+  |
|                                       |
|   Kategori*                           |
|  +---------------------------------+  |
|  | Pakaian Pria              [ v ] |  |
|  +---------------------------------+  |
|                                       |
|   SKU / Barcode                       |
|  +---------------------------------+  |
|  | 123456789            [📷 Scan]  |  |
|  +---------------------------------+  |
|                                       |
|   Harga Beli                          |
|  +---------------------------------+  |
|  | Rp 50.000                       |  |
|  +---------------------------------+  |
|                                       |
|   Harga Jual (Jika tanpa varian)      |
|  +---------------------------------+  |
|  | Rp 150.000                      |  |
|  +---------------------------------+  |
|                                       |
|   Stok Awal (Jika tanpa varian)       |
|  +---------------------------------+  |
|  | 10                              |  |
|  +---------------------------------+  |
|                                       |
|   --- VARIAN PRODUK ---               |
|  [ + Tambah Varian Baru ]             |
|                                       |
|   +--------------------------------+  |
|   | Varian: M                     X|  |
|   | Harga: Rp 150.000              |  |
|   | Stok: 5                        |  |
|   +--------------------------------+  |
|   +--------------------------------+  |
|   | Varian: L                     X|  |
|   | Harga: Rp 160.000              |  |
|   | Stok: 5                        |  |
|   +--------------------------------+  |
|                                       |
|   [        SIMPAN PRODUK         ]    |
+---------------------------------------+
```

**C. Import CSV / Excel (Batch Upload):**
```text
+---------------------------------------+
| [←] Import Produk Massal              |
+---------------------------------------+
|                                       |
| ℹ️ Format kolom CSV wajib (Baris 1): |
|    Nama_Produk, SKU, Kategori,        |
|    Harga_Jual, Stok                   |
|                                       |
| [ ⬇️ Download Template CSV ]          |
|                                       |
|  +---------------------------------+  |
|  | 📂 Pilih File Data CSV Anda     |  |
|  +---------------------------------+  |
|                                       |
|  Preview 3 Data Pertama:              |
|  -----------------------------------  |
|  1. Aqua Botol 600ml | Rp 3000 | 12 |  |
|  2. Taro Snack       | Rp 2000 | 30 |  |
|  3. Kratingdaeng     | Rp 5000 | 10 |  |
|                                       |
|                                       |
|    [ 🚀 MULAI IMPORT DATA ]           |
|                                       |
+---------------------------------------+
```

**D. Stock Opname (Penyesuaian Stok Cepat):**
```text
+---------------------------------------+
| [←] Penyesuaian Stok (Opname)  [ Simpan ]
+---------------------------------------+
| 🔍 Cari Produk / SKU                   |
+---------------------------------------+
| Indomie Goreng Spesial                |
| Di Sistem: 24   |  [+] Fisik: [ 22 ] [-]
| Selisih: -2                           |
|---------------------------------------|
| Kopi Kapal Api Mix                    |
| Di Sistem: 5    |  [+] Fisik: [  5 ] [-]
| Selisih: 0                            |
|---------------------------------------|
| Teh Pucuk Harum 350ml                 |
| Di Sistem: 12   |  [+] Fisik: [ 10 ] [-]
| Selisih: -2                           |
|---------------------------------------|
|                                       |
| Alasan Perubahan (Untuk Log Audit):   |
| +-----------------------------------+ |
| | Barang rusak/hilang               | |
| +-----------------------------------+ |
+---------------------------------------+
```

---

### 5. Manajemen Toko & Karyawan (Tab 3: Settings)

**A. Settings Menu (Tab 3):**
```text
+---------------------------------------+
| ⚙️ Pengaturan Toko                     |
+---------------------------------------+
|  👤 Budi (Owner)                      |
|  Toko Budi Jaya                       |
|---------------------------------------|
|                                       |
|  🏪 Profil Toko                       |
|  👥 Kelola Karyawan                   |
|  🏷️ Kelola Kategori Produk            |
|                                       |
|---------------------------------------|
|  🧾 Riwayat Transaksi (Nota & Void)   |
|  📊 Laporan Penjualan (Analytics)     |
|  🕒 Daftar Riwayat Sesi Shift         |
|  🖨️ Pengaturan Printer (Bluetooth)   |
|  💸 Pengaturan Pajak & Biaya          |
|                                       |   
|---------------------------------------|
|  💾 Backup ke Storage Internal        |
|  ☁️ Pencadangan Google Drive          |
|                                       |
|---------------------------------------|
|  🔒 Logout Sistem                     |
|                                       |
+---------------------------------------+
| 🏠 POS    |  📦 Stok   | ⚙️ Setting   |
+---------------------------------------+
```

**B. Manajemen Karyawan (Admin Menu):**
```text
+---------------------------------------+
| [←] Daftar Karyawan                   |
+---------------------------------------+
| Budi (Anda)                           |
| Role: Owner                 [ Edit ]  |
|---------------------------------------|
| Siti                                 |
| Role: Kasir (Level 3)       [ Edit ]  |
|---------------------------------------|
| Joko                                 |
| Role: Kasir (Level 3)       [ Edit ]  |
|---------------------------------------|
| Rina                                 |
| Role: Supervisor (Level 2)  [ Edit ]  |
|                                       |
|                                       |
|                                       |
|                                       |
|                            +----+     |
|                            | ➕ |     |
|                            +----+     |
+---------------------------------------+
```

**C. Form Tambah / Edit Karyawan:**
```text
+---------------------------------------+
| [←] Tambah Karyawan Baru              |
+---------------------------------------+
|                                       |
|        📷 [ Upload Foto ]             |
|                                       |
|  👤 Nama Karyawan                     |
|  +---------------------------------+  |
|  | Bintang                         |  |
|  +---------------------------------+  |
|                                       |
|  🎖️ Level Akses (Role)                |
|  +---------------------------------+  |
|  | Kasir (Level 3)               ▼ |  |
|  +---------------------------------+  |
|                                       |
|  🔐 PIN Login (6 Digit)               |
|  +---------------------------------+  |
|  | * * * * * *                     |  |
|  +---------------------------------+  |
|                                       |
|  🛑 Status Akun                       |
|  +---------------------------------+  |
|  | Aktif (Bisa Login)            ▼ |  |
|  +---------------------------------+  |
|                                       |
|                                       |
|        [ 💾 SIMPAN KARYAWAN ]         |
|                                       |
+---------------------------------------+
```

**D. Riwayat Transaksi & Void (L1, L2, L3):**
```text
+---------------------------------------+
| [←] Riwayat Transaksi                 |
+---------------------------------------+
| Filter: [ Hari Ini ▼ ]                |
|                                       |
| 🧾 POS-20260305-001                   |
| 12:30 | Rp 11.000 (Tunai)             |
| Status: [ LUNAS ]           [ Detail ]|
|---------------------------------------|
| 🧾 POS-20260305-002                   |
| 13:15 | Rp 25.000 (QRIS)              |
| Status: [ LUNAS ]           [ Detail ]|
|---------------------------------------|
| 🧾 POS-20260305-003                   |
| 14:00 | Rp 8.000  (Tunai)             |
| Status: [ BATAL / VOID ]    [ Detail ]|
+---------------------------------------+
```

**E. Detail Transaksi (Struk Digital):**
```text
+---------------------------------------+
| [←] Detail Nota                       |
+---------------------------------------+
|                                       |
| 🧾 POS-20260305-001                   |
| 🕒 05 Maret 2026, 12:30               |
| 👤 Kasir: Siti (L3)                   |
|                                       |
| ------------------------------------- |
|  Indomie Goreng Spesial   x2   R 7000 |
|  Teh Pucuk Harum          x1   R 3000 |
| ------------------------------------- |
|  Subtotal                 Rp 10.000   |
|  Pajak Resto (10%)        Rp  1.000   |
|  Total                    Rp 11.000   |
|  Bayar: Tunai             Rp 20.000   |
|  Kembalian                Rp  9.000   |
| ------------------------------------- |
|                                       |
|  [ 🖨️ CETAK ULANG STRUK ]           |
|                                       |
|  * * * * * * * * * * * * * * * * * *  |
|                                       |
|  [ 🚫 BATALKAN TRANSAKSI (VOID) ]     |
|                                       |
+---------------------------------------+
```

**F. Pop-Up Auth Supervisor (Saat L3 menekan Void):**
```text
+---------------------------------------+
|                                       |
|    +-----------------------------+    |
|    | 🛡️ OTORISASI DIBUTUHKAN   |    |
|    |                             |    |
|    | Tindakan Void (Batal)       |    |
|    | membutuhkan izin            |    |
|    | Supervisor / Owner.         |    |
|    |                             |    |
|    | Masukkan PIN (L1/L2):       |    |
|    |  +-----------------------+  |    |
|    |  | * * * * * *           |  |    |
|    |  +-----------------------+  |    |
|    |                             |    |
|    |  [ BATAL ]  [ KONFIRMASI ]  |    |
|    +-----------------------------+    |
|                                       |
+---------------------------------------+
```

**G. Laporan Penjualan (Analytics L1 & L2):**
```text
+---------------------------------------+
| [←] Laporan Penjualan                 |
+---------------------------------------+
| Filter: [ Hari Ini ▼ ]                |
|                                       |
| 💰 Total Pendapatan     : Rp 4.550.000|
| 🛒 Total Transaksi      : 124 Nota    |
| 📊 Rata-Rata Transaksi  : Rp 36.693   |
|                                       |
| 📈 Tren Penjualan:                    |
|       ^                               |
|   150 |       /--\                    |
|   100 |      /    \      /--          |
|    50 | --/ /      \----/             |
|     0 +-----------------------        |
|        08:00   12:00   16:00          |
|                                       |
| ⭐ 5 Produk Terlaris (Top Items)      |
|  1. Kratingdaeng      (40 Terjual)    |
|  2. Indomie Goreng    (35 Terjual)    |
|  3. Teh Botol Sosro   (20 Terjual)    |
|---------------------------------------|
+---------------------------------------+
```

**H. Daftar Riwayat Shift (L1 & L2):**
```text
+---------------------------------------+
| [←] Riwayat Sesi Shift                |
+---------------------------------------+
| Filter: [ 7 Hari Terakhir ▼ ]         |
|                                       |
| 🕒 Hari ini, 08:00 - 15:30            |
| 👤 Siti (Kasir)                       |
| Modal: Rp 100K | Setor: Rp 450K       |
| Selisih: (Rp 0 - PAS)       [ Lihat ] |
|---------------------------------------|
| 🕒 Kemarin, 15:30 - 22:00             |
| 👤 Joko (Kasir)                       |
| Modal: Rp 100K | Setor: Rp 350K       |
| Selisih: (-Rp 5000 - MINUS) [ Lihat ] |
|---------------------------------------|
| 🕒 Kemarin, 08:00 - 15:30             |
| 👤 Siti (Kasir)                       |
| Modal: Rp 100K | Setor: Rp 220K       |
| Selisih: (+Rp 2000 - LEBIH) [ Lihat ] |
+---------------------------------------+
```

**I. Pengaturan Printer (Bluetooth):**
```text
+---------------------------------------+
| [←] Pengaturan Printer                |
+---------------------------------------+
|                                       |
|  Status: 🔴 Terputus                  |
|                                       |
|  [ 🔍 CARI PERANGKAT BARU ]           |
|                                       |
|  Daftar Perangkat Ditemukan:          |
|  -----------------------------------  |
|  🖨️ RPP02N (Printer Termal)           |
|  [ Sambungkan ]                       |
|                                       |
|  🖨️ BluePrinter-58                     |
|  [ Sambungkan ]                       |
|                                       |
|  🖨️ Unknown Device (ABC:123)          |
|  [ Sambungkan ]                       |
|                                       |
|  -----------------------------------  |
|                                       |
|    [ 📄 TEST PRINT HALAMAN COBA ]     |
|                                       |
+---------------------------------------+
```

**J. Manajemen Kategori (Dari menu Kelola Kategori di Tab 3):**
```text
+---------------------------------------+
| [←] Kelola Kategori             [ ➕ ]|
+---------------------------------------+
|                                       |
|  Makanan Berat                  [✎][🗑️] |
|  -----------------------------------  |
|  Makanan Instan                 [✎][🗑️] |
|  -----------------------------------  |
|  Minuman Dingin                 [✎][🗑️] |
|  -----------------------------------  |
|  Cemilan / Snack                [✎][🗑️] |
|                                       |
+---------------------------------------+

*Pop-up Tambah/Edit Kategori:*
+---------------------------------------+
| [ Tambah Kategori Baru ]              |
|                                       |
| Nama Kategori:                        |
| +-----------------------------------+ |
| | Minuman Hangat                    | |
| +-----------------------------------+ |
|                                       |
| [ Batal ]                 [ Simpan ]  |
+---------------------------------------+
```

---

### 6. Profil Toko (Setup Struk)

**Layar Pengaturan Profil Toko:**
```text
+---------------------------------------+
| [←] Profil Toko                 [💾]  |
+---------------------------------------+
|                                       |
|       +-----------------------+       |
|       |       [ LOGO ]        |       |
|       |     (Tap to Upload)   |       |
|       +-----------------------+       |
|                                       |
|   🏪 Nama Toko*                       |
|  +---------------------------------+  |
|  | Toko Budi Jaya                  |  |
|  +---------------------------------+  |
|                                       |
|   📍 Alamat Toko                      |
|  +---------------------------------+  |
|  | Jl. Merdeka No. 123, Jakarta    |  |
|  +---------------------------------+  |
|                                       |
|   📞 Nomor Telepon                    |
|  +---------------------------------+  |
|  | 0812-3456-7890                  |  |
|  +---------------------------------+  |
|                                       |
|   [      SIMPAN PERUBAHAN        ]    |
+---------------------------------------+
```
```
