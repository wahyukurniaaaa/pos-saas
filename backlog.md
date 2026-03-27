# Product Backlog: Advanced Inventory & POS

Berikut adalah backlog fitur untuk pengembangan **Posify Inventory Phase 2, 3, & 4**, disusun berdasarkan prioritas bisnis dan kelengkapan fitur kompetitor (Moka/Majoo).

---

## 🟢 Priority 1: Core F&B & Financials (High Impact) - COMPLETED (Updated)

### 0. Simplified License Activation (UX Refinement)
*   **User Story**: "Sebagai Owner, saya ingin kode lisensi yang saya terima lebih sederhana (hanya 10 digit alfanumerik, tanpa prefix) agar proses input aktivasi di aplikasi mobile menjadi sangat cepat dan minim kesalahan."
*   **Tasks**:
    *   [ ] **Backend (Go)**: Update fungsi `Generate` di `license/service.go` untuk menghasilkan kode alfanumerik 10 karakter murni (Contoh: `X8Y2K9J1P5`).
    *   [ ] **Backend (Mailer)**: Update template email lisensi untuk format baru.
    *   [ ] **Mobile (UI/UX)**: Sesuaikan `ActivationScreen` untuk input 10 karakter (tambahkan auto-focus/masking jika perlu).
    *   [ ] **Mobile (Validation)**: Update regex validasi di Flutter.

### 1. Recipe & Ingredient Management (Sistem Bahan Baku)
*   [x] Recipe deduction logic, ingredient tables, and UI selection.

### 2. COGS (HPP) & Average Cost Tracking
*   [x] Moving average cost algorithm and Gross Profit reporting.
*   [x] **Retail HPP Support**: Tambahkan `purchase_price` di tabel `Products` untuk profit ritel tanpa resep.

### 3. Stock Opname & Variance Audit
*   [x] Physical vs System stock reconciliation with variance reason.

---

## 🟡 Priority 2: Operational Efficiency (Medium Impact)

### 4. Unit of Measure (UoM) Conversion
*   [x] `unit_conversions` table and rule-based conversion (KG to Gram, etc).

### 5. Low Stock Dashboard Widget
*   **User Story**: "Sebagai Kasir, saya ingin melihat ringkasan stok yang menipis di dashboard agar saya tahu apa yang harus dipromosikan (atau jangan dijual)."
*   **Tasks**:
    *   [x] UI: Widget "Stok Menipis" di Dashboard POS.
    *   [ ] UI: Filter "Hampir Habis" di Product Grid.

### 6. Batch & Expiry Tracking
*   **User Story**: "Sebagai Owner, saya ingin melacak tanggal kadaluwarsa barang agar saya tidak menjual produk basi (Loss Prevention)."
*   **Tasks**:
    *   [ ] Add `expiry_date` & `batch_number` to mutations.
    *   [ ] UI Filter: Show products expiring within 30 days.

---

## 🔵 Priority 3: Expansion & Ecosystem (Scale Up)

### 7. Multi-Outlet & Stock Transfer
*   **User Story**: "Sebagai Owner, saya ingin mengelola stok di banyak cabang dan melakukan transfer stok antar cabang agar distribusi barang terpantau."
*   **Tasks**:
    *   [ ] Create `outlets` table (id, name, address, phone).
    *   [ ] Refactor `products` & `ingredients` stock to be outlet-specific (mapping table).
    *   [ ] Create `stock_transfers` table (fromOutlet, toOutlet, items, status).
    *   [ ] UI: Outlet Switcher di Dashboard & Pengaturan.
    *   [ ] UI: Form Mutasi Stok antar Cabang.

### 8. Dynamic QRIS API Integration
*   **User Story**: "Sebagai Kasir, saya ingin menampilkan QRIS dinamis otomatis agar pelanggan bisa bayar instan tanpa saya harus cek mutasi manual."
*   **Tasks**:
    *   [ ] Backend: Integrasi API Payment Gateway (Xendit/Midtrans).
    *   [ ] Backend: Webhook listener untuk update status transaksi `paid`.
    *   [ ] UI: QR Display di `PaymentModal` saat memilih metode QRIS.
    *   [ ] Mobile: Real-time payment check (Polling/WebSocket).

### 9. Purchase Order (PO) Workflow
*   **User Story**: "Sebagai Manager, saya ingin membuat pesanan resmi ke supplier dan melacaknya hingga barang diterima agar procurement terdokumentasi."
*   **Tasks**:
    *   [x] Create `purchase_orders` & `po_items` tables.
    *   [x] Logic: Status flow (Draft -> Sent -> Partially Received -> Received).
    *   [x] Automation: Update stok otomatis saat PO berstatus `Received`.
    *   [x] UI: PO Management Screen (List & Form).

---

## 🟣 Priority 4: Loyalty & Automation (Growth)

### 10. Loyalty & Membership System (Points) - COMPLETED
*   **User Story**: "Sebagai Owner, saya ingin memberikan poin setiap belanja agar pelanggan kembali lagi (retensi)."
*   **Tasks**:
    *   [x] **Database**: Add `points` column to `customers` table and `points_earned/points_redeemed` to `transactions`.
    *   [x] **Configuration**: Create loyalty rules in Store Profile (Poin per Belanja & Nilai Tukar Poin).
    *   [x] **Logic**: Implementation of point calculation and balance persistence during checkout.
    *   [x] **Redemption**: UI/Logic to redeem points for direct discounts in Payment Modal.
    *   [x] **Reporting**: Loyalty Analytics screen with member leaderboard (Most Points & Most Active).
    *   [x] **Receipts**: Include point earned/total balance info in Thermal and WhatsApp receipts.

### 11. Proactive Low Stock Alerts (Push Notifications)
*   **User Story**: "Sebagai Bagian Gudang, saya ingin ada notifikasi otomatis saat stok menipis agar tidak telat restock."
*   **Tasks**:
    *   [ ] Backend: Cron Job untuk cek `low_stock_threshold` setiap jam.
    *   [ ] Integration with Firebase Cloud Messaging (FCM).
    *   [ ] UI: Low Stock Notification setup di Pengaturan.
 
### 12. Discount & Voucher Management
*   **User Story**: "Sebagai Owner, saya ingin membuat promo diskon (nominal/persen) dengan minimal belanja dan periode waktu tertentu serta dukungan diskon otomatis agar saya bisa meningkatkan penjualan."
*   **Tasks**:
    *   [x] **Database**: Create `discounts` table with scope (bill/item), stackable logic, and period validation (Migration v14).
    *   [x] **UI**: Discount Management Screen in Settings (Navy/Yellow Theme).
    *   [x] **Logic**: Handle "Voucher Selection" in Payment Modal with real-time validation.
    *   [x] **Integration**: Recalculation logic (Subtotal - Discount) and audit trail in transactions.
    *   [x] **Item-Level Discount**: Integrasi pemilihan diskon per produk di dalam keranjang (Cart Detail).
    *   [x] **Auto-Apply Logic**: Implementasi deteksi promo otomatis saat syarat minimal belanja terpenuhi tanpa input kasir.

---


> [!NOTE]
> Backlog ini disusun kembali menggunakan agen `project-planner` untuk memastikan struktur User Story yang berpusat pada pengguna dan Task Breakdown yang teknis.

---

## 🟠 Priority 5: Financial Visibility (High Demand - Market Gap)

### 13. Expense (Kas Keluar) Management
*   **User Story**: "Sebagai Owner/Kasir, saya ingin mencatat setiap pengeluaran operasional (belanja bahan, gaji, listrik) langsung dari aplikasi agar arus kas bisnis saya dapat dipantau secara real-time dan laporan laba rugi akurat."
*   **💡 Insight Kompetitor**: Kasir Pintar, Majoo, dan Moka semuanya memiliki fitur Kas Keluar terintegrasi dengan shift. Ini adalah **gap utama** yang harus ditutup untuk bersaing di segmen UMKM.
*   **Tasks**:
    *   [x] **Database v15**: Create `expense_categories` table (default: Bahan Baku, Gaji, Listrik, Operasional, Lain-lain) dan `expenses` table (linked to shift, category & employee).
    *   [x] **CRUD UI**: `ExpenseManagementScreen` — list per hari, form input (nominal, kategori, catatan, foto bukti opsional).
    *   [x] **Kategori Kustom**: `ExpenseCategoryManagementScreen` — Owner bisa buat/edit/hapus kategori dengan icon & warna.
    *   [x] **Integrasi Shift**: Total pengeluaran per shift tampil di rekap "Tutup Shift" sebagai Kas Keluar.
    *   [x] **Cashflow Analytics**: `CashFlowScreen` — bar chart Pendapatan vs Pengeluaran, tampilkan Laba Operasional bersih.
    *   [x] **Quick Action**: Tombol "Kas Keluar" di tab Kasir untuk input cepat tanpa buka Pengaturan.

## 🎨 Priority 6: Advanced & Add-ons (Future Growth)

### 14. F&B Table Management (Manajemen Meja)
*   **User Story**: "Sebagai Manager Restoran, saya ingin mengatur denah meja secara visual agar saya bisa melihat status keterisian meja (Kosong/Terisi/Selesai) dan mengelola pesanan per meja (Split Bill/Merge Table) dengan mudah."
*   **Tasks**:
    *   [ ] **Database**: Create `tables` (mapping to zones/areas) and `table_sessions` (linking transaction to a physical table).
    *   [ ] **UI**: Visual Floor Maker — Drag & drop interface untuk menyusun denah meja (Bundar/Kotak).
    *   [ ] **Status Tracking**: Visual indicator per meja (Hijau: Kosong, Merah: Terisi, Kuning: Menunggu Pembayaran).
    *   [ ] **Advanced Logic**: Feature "Pindah Meja" dan "Gabung Tagihan" (Merge Bill) antar meja dalam satu sesi.

### 15. Kitchen Display System (KDS)
*   **User Story**: "Sebagai Staff Dapur, saya ingin melihat pesanan masuk secara real-time di layar tablet agar saya bisa langsung memasak tanpa perlu kertas struk fisik (Paperless Kitchen)."
*   **Tasks**:
    *   [ ] **Communication**: Implement local networking (WebSocket/Socket.io) untuk sinkronisasi instan antara Kasir & Dapur.
    *   [ ] **UI**: KDS Dashboard — Grid view pesanan yang diurutkan berdasarkan waktu masuk (FIFO).
    *   [ ] **Status Flow**: Tombol "Start Cooking", "Ready to Serve", dan "Collected".
    *   [ ] **Alerts**: Tanda peringatan (Warna Merah/Blink) jika pesanan belum selesai dalam waktu > 15 menit.

### 16. Debt (Piutang / Bon) Management
*   **User Story**: "Sebagai Owner, saya ingin mencatat transaksi yang belum lunas (Bon) atas nama pelanggan tertentu agar saya bisa melacak total piutang dan menagihnya di kemudian hari."
*   **Tasks**:
    *   [ ] **Database**: Update `transactions` status (`unpaid / partial`) dan buat tabel `debt_payments` untuk cicilan.
    *   [ ] **UI**: Debt Ledger — Halaman khusus di menu Pelanggan untuk melihat daftar hutang yang belum lunas.
    *   [ ] **Reminder**: Fitur "Kirim Pengingat" otomatis via WhatsApp API untuk jatuh tempo hutang.
    *   [ ] **Analytics**: Laporan penuaan piutang (Aging Report) untuk melihat hutang macet.

### 17. Employee Commissions & Performance
*   **User Story**: "Sebagai Owner, saya ingin menetapkan komisi per item atau per total penjualan bagi karyawan agar motivasi staff meningkat dan saya bisa melihat siapa 'Top Performer' bulan ini secara otomatis."
*   **Tasks**:
    *   [ ] **Database**: Create `commissions_config` (Fixed amount or Percentage per product/category).
    *   [ ] **Logic**: Auto-calculation komisi setiap kali transaksi selesai, dikaitkan dengan `employee_id`.
    *   [ ] **UI**: Staff Performance Dashboard — Grafik penjualan per karyawan dan estimasi gaji/bonus bulanan.

### 18. Digital Catalog (Catalog Online / Link-in-Bio)
*   **User Story**: "Sebagai Owner, saya ingin membagikan katalog produk online ke media sosial agar pelanggan bisa melihat menu/produk saya secara mandiri dan melakukan pre-order."
*   **Tasks**:
    *   [ ] **Backend**: Mini-web generator yang mengambil data produk & stok dari database lokal (Cloud Sync required).
    *   [ ] **UI**: Public Product Landing Page — Tampilan katalog yang mobile-friendly dan estetik.
    *   [ ] **Order Link**: Tombol "Order via WA" yang otomatis menyusun pesan format belanja berdasarkan item yang dipilih di web.

### 19. Customer Feedback System (NPS)
*   **User Story**: "Sebagai Owner, saya ingin mendapatkan feedback langsung dari pelanggan setelah transaksi agar saya bisa mengevaluasi kualitas layanan dan komplain secara cepat."
*   **Tasks**:
    *   [ ] **Implementation**: Short-url feedback link yang disertakan di struk WhatsApp.
    *   [ ] **UI**: Rating star (1-5) dan kolom komentar sederhana (Web-based).
    *   [ ] **Monitoring**: Notifikasi instan ke Owner jika ada rating < 3 agar bisa segera dilakukan *service recovery*.

### 20. Serial Number / IMEI Tracking (Retail Electronics)
*   **User Story**: "Sebagai Owner Toko Elektronik, saya ingin mencatat nomor seri atau IMEI produk saat barang masuk dan terjual agar saya bisa melacak histori garansi dan mencegah klaim palsu."
*   **Tasks**:
    *   [ ] **Database**: Create `product_serials` table linked to `transaction_items` and `stock_history`.
    *   [ ] **UI**: Popup input SN/IMEI di menu POS saat item dipilih.
    *   [ ] **Validation**: Cek apakah SN/IMEI sudah pernah terjual atau masih tersedia di stok.
    *   [ ] **Search**: Fitur "Cek Garansi" berbasis SN/IMEI di menu Riwayat.

### 21. Service Booking & Appointment (Jasa / Barber / Salon)
*   **User Story**: "Sebagai Owner Salon/Barber, saya ingin mengatur jadwal kunjungan pelanggan agar saya bisa melihat beban kerja staff dan memastikan tidak ada tabrakan jadwal (Double Booking)."
*   **Tasks**:
    *   [ ] **UI**: Calendar View (Day/Week) untuk melihat slot waktu yang tersedia.
    *   [ ] **Logic**: Link booking ke `employee_id` (Stylist/Therapist) dan `customer_id`.
    *   [ ] **Integration**: Saat pelanggan datang, satu klik untuk merubah "Booking" menjadi "Active Transaction" di POS.

### 22. Purchase Order (PO) Management (General Retail)
*   **User Story**: "Sebagai Purchasing Manager, saya ingin membuat dokumen pesanan resmi (PO) ke Supplier sebelum barang dikirim agar saya bisa mencocokkan jumlah pesanan dengan jumlah barang yang datang (Stock In Match)."
*   **Tasks**:
    *   [ ] **Database**: Create `purchase_orders` and `po_items` tables with states (`Draft/Sent/Partial/Received`).
    *   [ ] **UI**: PO Creator — Form input barang yang ingin dipesan ke Supplier terpilih.
    *   [ ] **Inventory Sync**: Fitur "Receive from PO" di menu Stock In untuk input stok otomatis berbasis dokumen PO yang sudah ada.

### 23. Save Bill (Hold / Pending Transaction)
*   **User Story**: "Sebagai Kasir, saya ingin menyimpan sementara keranjang belanja pelanggan (Hold Bill) agar saya bisa melayani pelanggan lain sementara pelanggan sebelumnya masih ingin menambah pesanan atau menunda pembayaran (Open Bill)."
*   **Tasks**:
    *   [ ] **Database**: Tambahkan status `PENDING` pada tabel transaksi atau buat tabel `draft_orders` untuk penyimpanan sementara.
    *   [ ] **UI**: Tombol "Simpan Bill" di halaman Kasir/POS.
    *   [ ] **UI**: Lapisan "Daftar Bill Tersimpan" untuk melihat, mencari, dan memuat ulang (Resume) transaksi.
    *   [ ] **Logic**: Manajemen stok — apakah stok dikurangi saat simpan bill atau hanya saat bayar (Configurable).
    *   [ ] **Integration**: Hubungkan dengan fitur Manajemen Meja (Jika aktif) agar bill tersimpan otomatis terikat pada meja tertentu.

### 24. Transaction Notes (Catatan Pesanan)
*   **User Story**: "Sebagai Kasir, saya ingin menambahkan catatan khusus pada transaksi (Misal: 'Jangan pakai sambal', 'Meja Pojok', atau 'Urgent') agar staff lain dapat memahami instruksi spesifik untuk pesanan tersebut."
*   **Tasks**:
    *   [ ] **Database**: Tambahkan kolom `notes` (TEXT) pada tabel `transactions`.
    *   [ ] **UI**: Tambahkan field input "Catatan" di `PaymentModal` atau sebelum masuk ke layar pembayaran.
    *   [ ] **Display**: Tampilkan catatan pada daftar riwayat transaksi dan detail transaksi.
    *   [ ] **Receipts**: Cetak catatan pada struk thermal dan struk WhatsApp jika terisi.

### 25. Printer Receipt Configuration (Kustomisasi Struk)
*   **User Story**: "Sebagai Owner, saya ingin mengonfigurasi informasi yang tercetak di struk (Header tambahan, Footer, dan Social Media) agar nota belanja saya terlihat lebih profesional dan informatif bagi pelanggan."
*   **Tasks**:
    *   [ ] **Database**: Update tabel `store_profile` (Migration v16) untuk menambah kolom `receipt_footer`, `social_media_handle`, `website_url`, dan `show_logo_on_receipt`.
    *   [ ] **UI**: `ReceiptConfigScreen` — Form untuk mengedit:
        *   **Header**: Toggle Logo, Nama Outlet, No. Telepon.
        *   **Social Info**: Input Instagram/TikTok handle & Website.
        *   **Footer**: Pesan kustom (Slogan, WiFi Password, atau Pesan Terima Kasih).
    *   [ ] **UI Preview**: Tampilkan *Live Preview* draf struk di dalam layar pengaturan agar user tidak perlu print fisik untuk cek hasil.
    *   [ ] **Logo Optimization**: Fitur upload & cropping logo agar pas dengan resolusi printer thermal (Hitam-Putih/Monokrom).
    *   [ ] **Logic**: Integrasi variabel kustom ini ke dalam `PrinterService` (Helper Bluetooth).
