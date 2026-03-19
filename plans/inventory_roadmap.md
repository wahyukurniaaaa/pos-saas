# Inventory Roadmap: Phase 2 & Beyond

Berdasarkan analisis kompetitor (Moka, Majoo, Olsera) dan kondisi sistem saat ini, berikut adalah konsolidasi fitur yang diperlukan untuk menjadikan sistem inventori Posify setara dengan pemimpin pasar.

## 1. Konsolidasi Celah (Gap Analysis)

| Fitur | Status Saat Ini | Kebutuhan Implementasi |
| :--- | :--- | :--- |
| **Recipe / Bahan Baku** | Hanya potong produk utuh. | Tabel `ingredients` & `product_recipes`. Otomasi potong stok bahan saat barang jadi terjual. |
| **Low Stock Alert** | Ada threshold & banner UI. | Notifikasi Push/Email & Widget Dashboard khusus "Stok Kritis". |
| **Multi-Gudang/Outlet** | Single database location. | Tabel `outlets`. Fitur "Stock Transfer" & "Request Stock" (Antar Cabang). |
| **COGS / HPP Tracking** | Catat quantity & supplier. | Kalkulasi Average Cost / FIFO. Laporan Laba Kotor berdasarkan harga beli historis. |
| **Batch & Expiry** | Stok diperlakukan general. | Field `batch_number` & `expiry_date` pada mutasi stok. Laporan barang mendekati kadaluwarsa. |

---

## 2. Fitur Tambahan yang Harus Ada (Expert Recommendations)

Selain 5 poin di atas, untuk benar-benar mengalahkan kompetitor, kita butuh:

### A. Unit of Measure (UoM) Conversion
*   **Kasus**: Beli Biji Kopi dalam Karung (25kg), tapi di resep digunakan dalam Gram (15g).
*   **Implementasi**: Sistem konversi satuan otomatis agar stok tetap akurat meskipun satuan beli dan satuan pakai berbeda.

### B. Stock Opname & Variance Report
*   **Kasus**: Kasir menghitung fisik barang, ternyata kurang 2 dari sistem.
*   **Implementasi**: Fitur pencatatan "Variance" (Selisih) dan alasan (Rusak, Hilang, Sample) untuk audit keuangan yang presisi.

### C. Supplier Management & Auto-PO
*   **Kasus**: Pemilik toko lupa pesan barang.
*   **Implementasi**: Tombol "Generate PO" otomatis berdasarkan data stok yang sudah di bawah threshold, langsung dikirim ke WhatsApp/Email Supplier.

### D. Production / Assembly Log
*   **Kasus**: Toko roti membuat 50 Roti Bun di pagi hari dari bahan baku.
*   **Implementasi**: Pencatatan proses produksi (Mengubah bahan baku menjadi barang jadi secara manual sebelum terjual).

---

## 3. Prioritas Eksekusi (Proposed Path)

> [!IMPORTANT]
> Saya menyarankan urutan pengerjaan sebagai berikut agar dampak ke bisnis terasa paling cepat:

1.  **High Priority**: **Recipe Management (Bahan Baku)** - Ini fitur paling krusial untuk F&B agar HPP akurat.
2.  **Medium Priority**: **COGS & Financial Tracking** - Tanpa ini, pemilik bisnis tidak tahu untung bersih yang sebenarnya.
3.  **Medium Priority**: **Stock Opname & Variance** - Untuk mencegah kebocoran/kecurangan di outlet.
4.  **Low Priority**: **Multi-Outlet & Batch Tracking** - Biasanya dibutuhkan saat bisnis mulai ekspansi besar.

---

**Apakah Anda setuju dengan urutan prioritas ini, atau ingin mendahulukan Multi-Outlet/Batch Tracking?**
