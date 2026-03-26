# Product Backlog: Advanced Inventory & POS

Berikut adalah backlog fitur untuk pengembangan **Posify Inventory Phase 2, 3, & 4**, disusun berdasarkan prioritas bisnis dan kelengkapan fitur kompetitor (Moka/Majoo).

---

## 🟢 Priority 1: Core F&B & Financials (High Impact) - COMPLETED

### 1. Recipe & Ingredient Management (Sistem Bahan Baku)
*   [x] Recipe deduction logic, ingredient tables, and UI selection.

### 2. COGS (HPP) & Average Cost Tracking
*   [x] Moving average cost algorithm and Gross Profit reporting.
*   [ ] **Retail HPP Support**: Tambahkan `purchase_price` di tabel `Products` untuk profit ritel tanpa resep.

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

### 10. Loyalty & Membership System (Points)
*   **User Story**: "Sebagai Owner, saya ingin memberikan poin setiap belanja agar pelanggan kembali lagi (retensi)."
*   **Tasks**:
    *   [ ] Add `points` column to `customers` table.
    *   [ ] Create `loyalty_rules` (e.g., Rp 10.000 = 1 Point).
    *   [ ] Implementation of `Point Calculation` in checkout transaction.
    *   [ ] UI: Tukar Poin menjadi diskon di halaman Pembayaran.
    *   [ ] Report: Member most active analytics.

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
    *   [ ] **Item-Level Discount**: Integrasi pemilihan diskon per produk di dalam keranjang (Cart Detail).
    *   [ ] **Auto-Apply Logic**: Implementasi deteksi promo otomatis saat syarat minimal belanja terpenuhi tanpa input kasir.

---

> [!NOTE]
> Backlog ini disusun kembali menggunakan agen `project-planner` untuk memastikan struktur User Story yang berpusat pada pengguna dan Task Breakdown yang teknis.
