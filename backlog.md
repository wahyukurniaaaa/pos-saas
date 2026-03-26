# Product Backlog: Advanced Inventory & POS

Berikut adalah backlog fitur untuk pengembangan **Posify Inventory Phase 2, 3, & 4**, disusun berdasarkan prioritas bisnis dan kelengkapan fitur kompetitor (Moka/Majoo).

---

## 🟢 Priority 1: Core F&B & Financials (High Impact) - COMPLETED

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
