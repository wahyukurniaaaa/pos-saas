# Product Backlog: Advanced Inventory & POS

Berikut adalah backlog fitur untuk pengembangan **Posify Inventory Phase 2 & 3**, disusun berdasarkan prioritas bisnis dan kelengkapan fitur kompetitor (Moka/Majoo).

---

## 🟢 Priority 1: Core F&B & Financials (High Impact)

### 1. Recipe & Ingredient Management (Sistem Bahan Baku)
*   **Goal**: Otomasi pemotongan stok bahan baku berdasarkan penjualan produk jadi.
*   **Tasks**:
    *   [x] Create `ingredients` table (id, name, unit, sku, stock).
    *   [x] Create `product_recipes` join table (productId, ingredientId, quantityNeeded).
    *   [x] Implement deduction logic in `processCheckout` transaction.
    *   [x] UI: Ingredient selection in Product Form.

### 2. COGS (HPP) & Average Cost Tracking
*   **Goal**: Menghitung keuntungan bersih yang presisi berdasarkan harga beli historis.
*   **Tasks**:
    *   [x] Add `purchase_price` to `stock_transactions` (Implemented via `IngredientStockHistory`).
    *   [x] Implement "Moving Average" cost algorithm in database.
    *   [x] Report: Gross Profit (Laba Kotor) per Product/Category.
    *   [ ] **Retail HPP Support**: Tambahkan `purchase_price` di tabel `Products` & `ProductVariants` untuk mendukung profit ritel tanpa resep.


### 3. Stock Opname & Variance Audit
*   **Goal**: Pencatatan selisih stok (fisik vs sistem) untuk mencegah kerugian.
*   **Tasks**:
    *   [x] Create `stock_opname` table and `opname_items`.
    *   [x] Implement `StockOpnameScreen` and `IngredientOpnameScreen` with DRAFT/COMPLETED flow and auto-adjust.
    *   [x] Implementation of "Variance Reason" (e.g., Waste, Stolen, Sample).
    *   [x] Report: Stock Loss/Waste value summary per periode.


---

## 🟡 Priority 2: Operational Efficiency (Medium Impact)

### 4. Unit of Measure (UoM) Conversion
*   **Goal**: Mendukung satuan yang berbeda antara pembelian (Box/Karung) dan penggunaan (Gr/Pcs).
*   **Tasks**:
    *   [x] Logic to auto-convert 1kg → 1000g during Stock In. (Implemented in Ingredient Stock In Modal)
    *   [x] Create `unit_conversions` table (schema v11) untuk aturan konversi satuan fleksibel.
    *   [x] UI: `UnitConversionScreen` — Owner dapat CRUD aturan konversi dari Pengaturan.


### 5. Low Stock Dashboard & Notifications
*   **Goal**: Memindahkan sistem alert dari pasif (banner) ke aktif (proaktif).
*   **Tasks**:
    *   [ ] Dashboard Widget: Top 5 Stock Out of Stock.
    *   [ ] Background Job: Check low stock daily alert.
    *   [ ] Action: One-Click Reorder to Supplier.

### 6. Batch & Expiry Tracking
*   **Goal**: Pelacakan tanggal kadaluwarsa per kelompok barang masuk.
*   **Tasks**:
    *   [ ] Add `expiry_date` & `batch_number` to mutations.
    *   [ ] UI Filter: Show products expiring within 30 days.

---

## 🔵 Priority 3: Expansion (Scale Up)

### 7. Multi-Warehouse & Stock Transfer
*   **Goal**: Mendukung operasional antar cabang atau pusat-ke-toko.
*   **Tasks**:
    *   [ ] Create `outlets` table.
    *   [ ] Implementation of "Stock Move" logic between outlets.
    *   [ ] UI: Request Stock form for Cashiers.

### 8. Purchase Order (PO) Workflow
*   **Goal**: Manajemen pemesanan ke Supplier secara bertahap.
*   *Workflow*: **Draft** -> **Sent** -> **Partially Received** -> **Received**.

---

> [!NOTE]
> Backlog ini bersifat dinamis dan akan diperbarui seiring dengan perkembangan kebutuhan pengguna dan validasi pasar.
