# Product Backlog: POSify SaaS Roadmap (2026)

Dokumen ini mendefinisikan urutan eksekusi fitur untuk transisi dari **Tier Lite (Offline-First)** ke **Tier Pro (Cloud-Sync Multi-Outlet)** dengan tetap mempertahankan seluruh backlog fitur operasional.

---

## 📈 EXECUTIVE SUMMARY: PRO ROADMAP

| Phase | Goal | Key Features | Status |
| :--- | :--- | :--- | :--- |
| **Phase 0** | **Essential POS UX** | **Save Bill**, **Split Bill/Payment**, **Notes**. | ✅ Partial |
| **Phase 1** | **Growth & Automation** | Marketplace Webhooks, Auto-License Email, Unified Onboarding. | 🕒 IN PROGRESS |
| **Phase 2** | **Core Infrastructure** | **UUID Migration (v20)**, Outlet Mapping, Soft-Delete. | ✅ SELESAI |
| **Phase 3** | **Cloud Sync & Pro**| PowerSync & Supabase Integration, Multi-Outlet Visibility. | 🔜 Ready |
| **Phase 4** | **Scale & Monetization**| In-App Pro Billing, Dashboard, Advanced F&B, KDS, Tables. | 🔜 Ready |

---

## 🏗️ PHASE 0.0: Outlet Bootstrapping (Infrastructure)
*Tujuan: Menyediakan entitas outlet dasar secara otomatis untuk mendukung sinkronisasi data per cabang.*

🤖 **Applying knowledge of `@[project-planner]`...**

### [NEW] 0.0.1. Automatic First-Outlet Creation
*   **User Story**: "Sebagai Owner baru, saya ingin sistem secara otomatis membuat outlet pertama saya saat pendaftaran agar saya tidak perlu melakukan pengaturan teknis yang rumit sebelum mulai berjualan."
*   **Tasks**:
    - [x] **Logic**: Modifikasi `setupOwner` di `OwnerNotifier` agar melakukan inisialisasi record pertama di tabel `outlets`. (DONE)
    - [x] **Mapping**: Menghubungkan ID karyawan (Owner) dan profil toko ke ID Outlet default yang baru dibuat. (DONE)
    - [x] **Data Scoping**: Mengatur agar state aplikasi mendeteksi outlet aktif segera setelah setup selesai. (DONE)

---

## ✨ PHASE 0: Essential POS UX (URGENT)
*Tujuan: Memperkuat fitur kasir dasar yang sangat dibutuhkan UMKM sebelum masuk ke fase Cloud.*

### 23. Save Bill (Hold / Pending Transaction)
*   **User Story**: "Sebagai Kasir, saya ingin menyimpan sementara keranjang belanja pelanggan (Hold Bill) agar saya bisa melayani pelanggan lain sementara pelanggan sebelumnya masih ingin menambah pesanan atau menunda pembayaran (Open Bill)."
*   **Tasks**:
    - [x] **Database**: Tambahkan status `PENDING` pada tabel transaksi atau buat tabel `draft_orders` untuk penyimpanan sementara. (Implemented via `payment_status` & `receipt_number` nullability).
    - [x] **UI**: Tombol "Simpan Bill" di halaman Kasir/POS.
    - [x] **UI**: Lapisan "Daftar Bill Tersimpan" untuk melihat, mencari, dan memuat ulang (Resume) transaksi.
    - [x] **Logic**: Manajemen stok — apakah stok dikurangi saat simpan bill atau hanya saat bayar (Configurable).
    - [x] **Integration**: Hubungkan dengan fitur Manajemen Meja (Jika aktif) agar bill tersimpan otomatis terikat pada meja tertentu.

### 24. Transaction Notes (Catatan Pesanan)
*   **User Story**: "Sebagai Kasir, saya ingin menambahkan catatan khusus pada transaksi (Misal: 'Jangan pakai sambal', 'Meja Pojok', atau 'Urgent') agar staff lain dapat memahami instruksi spesifik untuk pesanan tersebut."
*   **Tasks**:
    - [x] **Database**: Tambahkan kolom `notes` (TEXT) pada tabel `transactions`. (Implemented via Migration v19/v20).
    - [x] **UI**: Tambahkan field input "Catatan" di `PaymentModal` atau sebelum masuk ke layar pembayaran.
    - [x] **Display**: Tampilkan catatan pada daftar riwayat transaksi dan detail transaksi.
    - [x] **Receipts**: Cetak catatan pada struk thermal dan struk WhatsApp jika terisi.

### 25. Split Bill (Pecah Tagihan)
*   **User Story**: "Sebagai Kasir, saya ingin membagi tagihan pesanan menjadi beberapa pembayaran terpisah (Split Bill) agar rombongan pelanggan bisa membayar bagiannya masing-masing secara individu (berdasarkan item atau jumlah)."
*   **Tasks**:
    - [ ] **UI/UX**: Implementasi layar "Split Bill" yang memungkinkan kasir memilih item mana yang akan dibayar terlebih dahulu.
    - [ ] **Logic**: Manajemen sub-keranjang (Partial Checkout) sehingga sisa item tetap berada di keranjang utama atau menjadi Bill tertunda baru.
    - [ ] **Database**: Pelacakan relasi antar transaksi yang dipecah (Parent Transaction ID) untuk laporan rekonsiliasi yang akurat.
    - [ ] **Validation**: Validasi total pembayaran agar jumlah seluruh pecahan tagihan sesuai dengan nilai transaksi original.
    - [ ] **Receipts**: Cetak struk terpisah untuk setiap pecahan tagihan dengan indikator "Partial Payment".

### 26. Split Payment (Multi-Metode Pembayaran)
*   **User Story**: "Sebagai Kasir, saya ingin menerima lebih dari satu metode pembayaran untuk satu transaksi (Split Payment) agar pelanggan dapat membayar sebagian dengan tunai dan sisanya dengan kartu atau QRIS dalam satu struk."
*   **Tasks**:
    - [x] **UI/UX**: Desain alur input multi-pembayaran di `PaymentModal` yang memungkinkan penambahan baris pembayaran baru.
    - [x] **Logic**: Kalkulator sisa saldo pembayaran yang otomatis berkurang saat satu metode pembayaran dikonfirmasi (Remaining Balance logic).
    - [x] **Database**: Penyesuaian skema untuk menyimpan rincian metode pembayaran ganda per transaksi (Linked payments).
    - [x] **Receipts**: Modifikasi struk agar menampilkan rincian dari setiap metode pembayaran yang digunakan.

---

## 🚀 PHASE 1: Growth & Automation (The "Money" Phase)
*Tujuan: Memaksimalkan penjualan di TikTok/Shopee tanpa intervensi manual.*

### 29. Webhook Proxy & Order Automation (Marketplace Fulfillment)
*   **User Story**: "Sebagai Owner, saya ingin pesanan dari TikTok/Shopee/Tokopedia diproses secara instan (No-Touch Fulfillment) agar pembeli langsung mendapatkan kode lisensi dan saya tidak perlu mengirim email manual."
*   **Tasks**:
    - [x] **Marketplace Connector (Go)**: Implementasi handler untuk webhook TikTok (HMAC verified) dan Shopee (READY_TO_SHIP).
    - [x] **SKU Filter Logic**: Menambahkan tabel `mapping_skus` dan repository lookup untuk memvalidasi produk lisensi.
    - [x] **License Auto-Generator**: Menghasilkan 10-digit alfanumerik kapital acak (`crypto/rand`) tanpa prefix lama.
    - [x] **Transaction Audit Log**: Mencatat `order_id` dan `source` ke tabel `licenses` serta pengecekan duplikasi pesanan.
    - [x] **Testing**: Unit Test coverage untuk `ProcessTikTokOrder` dan `ProcessShopeeOrder`.

### 30. Transactional Email Automation
*   **User Story**: "Sebagai Pembeli, saya ingin menerima email panduan instalasi dan kode lisensi segera setelah pembayaran saya terverifikasi oleh marketplace."
*   **Tasks**:
    - [x] **Email Service Integration**: Menggunakan **Resend Go SDK** dengan API Key terkonfigurasi.
    - [x] **Branded Email Template**: Template HTML premium (Brand Indigo #1A237E) dengan placeholder dinamis untuk lisensi dan tier.
    - [x] **Integration**: Terhubung langsung dengan `License.Generate` yang dipicu oleh Webhook.
    - [ ] **Retry Mechanism**: (Next Path) Implementasi background worker (Asynq/Machinery) jika volume tinggi.

### 31. Unified Registration (The "One-Step" Onboarding)
*   **Status**: **SELESAI**
*   **User Story**: "Sebagai User Baru, saya ingin mendaftarkan akun sekaligus mengaktifkan lisensi dalam satu langkah mudah via link email atau input manual agar proses onboarding cepat."
*   **Tasks**:
    - [x] **Hybrid Registration Flow (Mobile)**: Implementasi layar pendaftaran yang mendukung pengisian otomatis via **Deep Link** (parsing parameter `code`) dan input manual 10-digit kode.
    - [x] **Auth Integration (App)**: Menghubungkan Flutter Auth dengan endpoint `/auth/register-with-license` (Kode lisensi bersifat opsional untuk pendaftaran Free/Pro langsung).
    - [x] **Account Hydration**: Setelah registrasi sukses, aplikasi otomatis melakukan inisiasi data profil (Tier & Source) ke dalam SQLite lokal.

---

## 🏗️ PHASE 2: Core Infrastructure (The "Hard" Phase)
*Tujuan: Menyiapkan basis data yang siap untuk sinkronisasi antar perangkat.*

### 26. Multi-Outlet Infrastructure & Identity (The UUID Migration)
*   **User Story**: "Sebagai Owner, saya ingin mengelola lebih dari satu cabang bisnis dalam satu akun agar saya bisa melihat performa keseluruhan tanpa harus berganti perangkat (Multi-Outlet Management)."
*   **Tasks**:
    - [x] **Database Migration v20 (UUID Overhaul)**: Mengonversi semua Primary Key (PK) dari `INTEGER AUTOINCREMENT` ke `TEXT (UUID)`. Wajib dilakukan agar tidak terjadi ID bentrok (*Collision*) saat banyak perangkat offline melakukan sinkronisasi ke satu database Cloud yang sama.
    - [x] **Outlet Mapping Schema**: Membuat tabel `outlets` dan menambahkan kolom `outlet_id` (FK) pada tabel `transactions`, `stock_transactions`, `products`, `ingredients`, dan `employees`.
    - [x] **Soft-Delete Architecture**: Menambahkan kolom `deleted_at` pada semua tabel utama untuk menggantikan penghapusan fisik (`DELETE`), memastikan status penghapusan data tersinkronisasi ke seluruh perangkat terhubung.
    - [x] **Global vs Local Scoping**: Implementasi logika filter data agar Kasir hanya melihat data outletnya sendiri, sementara Owner dapat mengakses akses "Super-Set" data (seluruh outlet).

---

## ☁️ PHASE 3: Cloud Sync & Pro Core (The "Pro" Phase)
*Tujuan: Mengaktifkan sinkronisasi real-time dan manajemen multi-cabang.*

### 27. Safe & Smart Cloud Sync (Conflict Resolution & Filtering)
*   **User Story**: "Sebagai Merchant, saya ingin data saya tersambung ke Cloud secara otomatis, efisien per cabang, dan tetap konsisten meskipun diupdate dari banyak perangkat sekaligus secara offline."
*   **Tasks**:
    - [x] **Supabase Backend Setup**: Konfigurasi project Supabase beserta skema database untuk menampung data sinkronisasi Cloud. (DONE)
    - [x] **Native Sync & Realtime Integration**: Mengintegrasikan sinkronisasi kustom menggunakan `sync_service.dart` dan `realtime_service.dart`. (DONE)
    - [x] **Outlet-Scoped Sync (Efficiency)**: Optimasi *query filtering* agar tiap *outlet* hanya mengunduh data yang relevan dengan `outlet_id` miliknya untuk menghemat bandwidth. (DONE)
    - [x] **LWW Conflict Resolution**: Implementasi verifikasi `updated_at` di tingkat database sebelum melakukan import data dari cloud agar data lokal tidak tertimpa secara buta. (DONE)
    - [x] **Delta Stock Logic**: Refaktor fungsi update stok agar menggunakan sistem increment/decrement (Delta) daripada overwriting nilai total untuk mencegah kehilangan data stok saat sync antar perangkat. (DONE)
    - [x] **Auth Transition (SaaS Model)**: Migrasi dari "Activation Key" ke Supabase Auth. Sinkronisasi hanya berjalan bagi pengguna Pro.

### 28. Inter-Outlet Stock Transfer & Visibility
*   **User Story**: "Sebagai Owner, saya ingin memindahkan stok antar cabang (Stock Transfer) dan melihat ketersediaan barang di cabang lain langsung dari aplikasi kasir untuk kebutuhan stok mendadak."
*   **Tasks**:
    *   [ ] **Stock Transfer Module**: Membuat entitas `stock_transfers` yang mencatat perpindahan stok: `from_outlet_id` -> `to_outlet_id` dengan status `SENT / RECEIVED`.
    *   [ ] **Cross-Outlet Stock Checker**: Menambahkan button "Cek Cabang Lain" pada Product Grid untuk pengecekan stok real-time (butuh internet aktif untuk cek data outlet lain).

---

## 💰 PHASE 4: Scale & Monetization (The "Scale" Phase)
*Tujuan: Ekspansi fitur bisnis dan penarikan pendapatan berlangganan.*

### 32. In-App Pro Subscription Upgrade
*   **User Story**: "Sebagai user Free/Lite, saya ingin melakukan upgrade ke Tier Pro langsung dari aplikasi agar saya bisa segera menggunakan fitur Multi-Outlet dan Cloud Sync."
*   **Tasks**:
    - [ ] **Payment Gateway Integration (Go)**: Integrasi dengan Midtrans/Xendit untuk pembuatan invoice subscription (Snap/Redirect).
    - [ ] **Billing Webview (Mobile)**: Layar pembayaran di dalam aplikasi menggunakan Webview untuk menyelesaikan transaksi.
    - [ ] **Subscription Webhook Listener**: Handler di backend Go untuk menerima notifikasi pembayaran sukses dan melakukan update status `tier` menjadi `pro` di database Supabase.
    - [ ] **Cloud Sync Awakening**: Logika di aplikasi mobile untuk mengaktifkan PowerSync segera setelah terdeteksi perubahan tier menjadi `pro`.

---

## 💎 PHASE 5: Advanced Cloud & Multi-Outlet Analytics
*Tujuan: Menyempurnakan ekosistem Pro dengan sinkronisasi cerdas dan intelijen bisnis.*


### 34. Background Image Sync (Supabase Storage)
*   **User Story**: "Sebagai Kasir, saya ingin tetap bisa mengambil foto nota belanja meskipun internet mati, dan aplikasi akan otomatis mengunggahnya saat saya mendapatkan koneksi tanpa saya perlu menunggu di layar tersebut."
*   **Tasks**:
    - [ ] **Infrastructure**: Konfigurasi Supabase Storage Bucket & RLS Policies.
    - [ ] **Background Jobs**: Integrasi `work_manager` untuk antrian pengunggahan latar belakang agar hemat baterai & reliable.
    - [ ] **Retry Logic**: Mekanisme percobaan ulang otomatis jika koneksi terputus saat proses upload.

### 35. Owner Global Dashboard (Multi-Outlet)
*   **User Story**: "Sebagai Owner, saya ingin melihat total penjualan dari seluruh cabang saya dalam satu layar ringkasan agar saya bisa segera mengambil keputusan bisnis tanpa harus mengecek satu per satu cabang."
*   **Tasks**:
    - [ ] **UI/UX**: Desain layar "Global Analytics" khusus untuk profil Owner di aplikasi Mobile.
    - [ ] **Data Aggregation**: Implementasi kueri agregasi lintas `outlet_id` di Supabase (RPC) atau kueri Drift lokal.
    - [ ] **Visuals**: Grafik performa outlet (Bar charts/Pie charts) untuk komparasi harian antar cabang.

---

## 🔐 PHASE 6: Auth Consolidation & Tier-Based Logic
*Tujuan: Memastikan pemisahan fitur yang disiplin antara user Lite dan Pro.*

### 36. Unified Auth & Tier Provider
*   **User Story**: "Sebagai pengembang, saya ingin memiliki sistem pengecekan 'Pro' yang terpusat agar fitur Cloud Sync tidak berjalan secara tidak sengaja pada akun Lite."
*   **Tasks**:
    - [ ] **Backend Mapping**: Modifikasi `SyncService` & `RealtimeService` agar bergantung pada `appTierProvider`.
    - [ ] **Metadata Logic**: Implementasi logika pengalihan/sinkronisasi `user_metadata['tier']` dari Supabase ke database lokal.
    - [ ] **Local DB Update**: Penambahan kolom `tier` pada tabel `licenses` lokal (SQLite).
    - [ ] **UI Gating**: Menyembunyikan indikator sinkronisasi jika user terdeteksi sebagai 'lite' (meskipun sudah punya akun).


### 🧩 Future Advanced Modules & Add-ons
Tugas lanjutan yang akan diimplementasikan setelah sinkronisasi stabil:

#### 14. F&B Table Management (Manajemen Meja)
*   **User Story**: "Sebagai Manager Restoran, saya ingin mengatur denah meja secara visual agar saya bisa melihat status keterisian meja."
*   **Tasks**:
    *   [ ] **Database**: Create `tables` (mapping to zones/areas) and `table_sessions` (linking transaction to a physical table).
    *   [ ] **UI**: Visual Floor Maker — Drag & drop interface untuk menyusun denah meja.
    *   [ ] **Status Tracking**: Visual indicator per meja (Hijau: Kosong, Merah: Terisi, Kuning: Menunggu Pembayaran).
    *   [ ] **Advanced Logic**: Feature "Pindah Meja" dan "Gabung Tagihan" (Merge Bill).

#### 15. Kitchen Display System (KDS)
*   **User Story**: "Sebagai Staff Dapur, saya ingin melihat pesanan masuk secara real-time di layar tablet (Paperless Kitchen)."
*   **Tasks**:
    *   [ ] **Communication**: Implement local networking (WebSocket/Socket.io) untuk sinkronisasi instan antara Kasir & Dapur.
    *   [ ] **UI**: KDS Dashboard — Grid view pesanan yang diurutkan berdasarkan waktu masuk (FIFO).

#### 16. Debt (Piutang / Bon) Management
*   **User Story**: "Sebagai Owner, saya ingin mencatat transaksi yang belum lunas (Bon) agar saya bisa menagihnya di kemudian hari."
*   **Tasks**:
    *   [ ] **Database**: Update `transactions` status (`unpaid / partial`) dan buat tabel `debt_payments` untuk cicilan.
    *   [ ] **UI**: Debt Ledger — Halaman khusus di menu Pelanggan untuk melihat daftar hutang.
    *   [ ] **Reminder**: Fitur "Kirim Pengingat" otomatis via WhatsApp API.

#### 17. Employee Commissions & Performance
*   **User Story**: "Sebagai Owner, saya ingin menetapkan komisi per item bagi karyawan agar motivasi staff meningkat."
*   **Tasks**:
    *   [ ] **Logic**: Auto-calculation komisi setiap kali transaksi selesai.
    *   [ ] **UI**: Staff Performance Dashboard.

#### 18. Digital Catalog (Catalog Online)
*   **User Story**: "Sebagai Owner, saya ingin membagikan katalog produk online ke media sosial."
*   **Tasks**:
    *   [ ] **Backend**: Mini-web generator dari database lokal (Cloud Sync required).
    *   [ ] **Order Link**: Tombol "Order via WA".

#### 20. Serial Number / IMEI Tracking
*   **User Story**: "Sebagai Owner Toko Elektronik, saya ingin mencatat nomor seri atau IMEI produk."
*   **Tasks**:
    *   [ ] **Database**: Create `product_serials` table linked to transactions.
    *   [ ] **Search**: Fitur "Cek Garansi" berbasis SN/IMEI.

#### 21. Service Booking & Appointment
*   **User Story**: "Sebagai Owner Salon/Barber, saya ingin mengatur jadwal kunjungan pelanggan."
*   **Tasks**:
    *   [ ] **UI**: Calendar View untuk melihat slot waktu tersedia.
    *   [ ] **Integration**: Merubah "Booking" menjadi "Active Transaction" di POS.

#### 8. Dynamic QRIS API Integration
*   **User Story**: "Sebagai Kasir, saya ingin menampilkan QRIS dinamis otomatis agar pelanggan bisa bayar instan."
*   **Tasks**:
    *   [ ] **Backend**: Integrasi API Payment Gateway (Xendit/Midtrans).
    *   [ ] **UI**: QR Display di `PaymentModal`.

---

## 🟡 OPERATIONAL ENHANCEMENTS (Ongoing)
Fitur peningkatan efisiensi operasional yang sedang berjalan:

#### 13. Expense (Kas Keluar) Management
*   **User Story**: "Sebagai Owner/Kasir, saya ingin mencatat setiap pengeluaran operasional agar laporan laba rugi akurat."
*   **Tasks**:
    *   [x] **Database v15**: Create categories & expenses tables.
    *   [x] **CRUD UI**: Expense management screen with photo proof.
    *   [x] **Analytics**: Pendapatan vs Pengeluaran charts.

#### 6. Batch & Expiry Tracking
*   **User Story**: "Sebagai Owner, saya ingin melacak tanggal kadaluwarsa barang agar tidak menjual produk basi."
*   **Tasks**:
    *   [ ] Add `expiry_date` & `batch_number` to mutations.
    *   [ ] UI Filter: Produk kadaluwarsa dalam 30 hari.

#### 11. Proactive Low Stock Alerts (Push Notifications)
*   **User Story**: "Sebagai Bagian Gudang, saya ingin ada notifikasi otomatis saat stok menipis."
*   **Tasks**:
    *   [ ] Integration with Firebase Cloud Messaging (FCM).

#### 25. Printer Receipt Configuration (Kustomisasi Struk)
*   **User Story**: "Sebagai Owner, saya ingin mengonfigurasi informasi yang tercetak di struk (Footer, Social Media)."
*   **Tasks**:
    *   [ ] `ReceiptConfigScreen` — Edit Header/Footer & Live Preview.

#### 26. Device Management UI (Manajemen Perangkat)
*   **User Story**: "Sebagai Owner, jika saya ganti HP atau HP lama rusak, saya ingin bisa melepas perangkat lama dari lisensi saya sendiri tanpa harus menghubungi CS."
*   **Dependensi**: Backend `/api/v1/license/reset` (selective) ✅ sudah selesai.
*   **Tasks**:
    *   [ ] **UI (Settings)**: `DeviceManagementScreen` — tampilkan daftar perangkat aktif (nama + tanggal aktivasi).
    *   [ ] **UI**: Tombol "Lepas Perangkat Ini" per item, disertai konfirmasi email.
    *   [ ] **UX**: Saat aktivasi gagal (`ErrLicenseUsed`), arahkan user ke halaman ini dari dalam dialog error.
    *   [ ] **Mobile API**: Provider `deviceListProvider` yang memanggil `/reset` dengan `device_fingerprint`.

---

## 🟢 COMPLETED (Archive)
*Fitur yang sudah stabil di core POSify.*

- [x] **Recipe & Ingredient Management**: Pemotongan bahan baku otomatis.
- [x] **COGS (HPP) Tracking**: Perhitungan Moving Average & Laba Kotor.
- [x] **Stock Opname**: Audit stok fisik vs sistem dengan variance reason.
- [x] **Unit of Measure (UoM)**: Konversi satuan (KG ke Gram, dll).
- [x] **Loyalty & Membership**: Poin per belanja & penukaran diskon.
- [x] **Discount & Voucher**: Diskon otomatis & voucher periode tertentu.
- [x] **Purchase Order (PO)**: Flow procurement Draft -> Sent -> Received.
- [x] **License Activation**: UX Refinement (10-digit codes).
