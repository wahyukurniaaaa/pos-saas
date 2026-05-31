# Implementation Plan: Mobile Performance Fixes

## Overview

Implementasi 15 perbaikan performa pada aplikasi Lumio POS (Flutter + Riverpod + Drift). Semua perubahan bersifat refactoring internal — tidak mengubah fungsionalitas yang terlihat pengguna. Urutan eksekusi diprioritaskan berdasarkan impact dan dependencies: quick wins tanpa dependencies dikerjakan lebih dulu, diikuti core fixes, refactoring breaking change, medium optimizations, dan terakhir property-based tests.

## Tasks

- [x] 1. Quick Wins — Perbaikan tanpa dependencies eksternal
  - [x] 1.1 Hapus `ref.invalidate(productProvider)` dari `CartNotifier.checkout()`
    - Di `lib/features/pos/providers/pos_providers.dart`, hapus baris `ref.invalidate(productProvider)` dari method `checkout()` setelah successful checkout
    - Pastikan `clearCart()` tetap dipanggil
    - Stream subscription di `ProductNotifier` sudah menangani update stok secara otomatis via `db.watchAllProducts()`
    - _Requirements: 8.1, 8.2, 8.3, 8.4_

  - [x] 1.2 Tambah debounce 500ms pada `SyncService` sync queue listener
    - Di `lib/core/services/sync_service.dart`, tambah field `Timer? _syncDebounceTimer`
    - Wrap listener `db.syncQueueNotifier.stream` dengan debounce 500ms sebelum memanggil `_processSyncQueue()`
    - Di method `stop()`, tambah `_syncDebounceTimer?.cancel()` dan set ke `null`
    - Pastikan `performSync()` yang dipanggil langsung di `start()` tidak terpengaruh debounce
    - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5_

  - [x] 1.3 Tambah `mainAxisExtent` pada `GridView` di `PosTab`
    - Di `lib/features/pos/screens/pos_tab.dart`, pada `_buildProductGrid()`, ganti `childAspectRatio: 0.75` dengan `mainAxisExtent: 200` di `SliverGridDelegateWithFixedCrossAxisCount`
    - Nilai 200px setara dengan rasio 0.75 pada layar 375px
    - _Requirements: 13.1, 13.2, 13.3_

- [x] 2. Checkpoint — Quick wins selesai
  - Pastikan semua tests pass, tanyakan ke user jika ada pertanyaan.

- [x] 3. Core Fixes — Eliminasi N+1 query dan in-memory filter
  - [x] 3.1 Tambah metode batch-fetch baru di `LumioDatabase`
    - Di `lib/core/database/database.dart`, tambah 4 metode baru:
      - `Future<List<Product>> getProductsByIds(List<String> ids)` — query dengan `p.id.isIn(ids) & p.deletedAt.isNull()`
      - `Future<List<ProductVariant>> getVariantsByIds(List<String> ids)` — query dengan `v.id.isIn(ids) & v.deletedAt.isNull()`
      - `Future<List<Discount>> getDiscountsByIds(List<String> ids)` — query dengan `d.id.isIn(ids)`
      - `Future<Customer?> getCustomerById(String id)` — query dengan `c.id.equals(id)`, return `getSingleOrNull()`
    - Semua metode harus return early dengan empty list/null jika input kosong
    - Tidak perlu jalankan `build_runner` karena ini query manual, bukan generated code
    - _Requirements: 3.2, 3.3, 3.4, 9.2, 9.3, 9.4, 9.5_

  - [x] 3.2 Refactor `CartNotifier.resumeBill()` untuk eliminasi N+1 query
    - Di `lib/features/pos/providers/pos_providers.dart`, refactor method `resumeBill()`:
      - Ekstrak semua `productId`, `variantId`, `discountId` dari items sebelum loop
      - Panggil `db.getProductsByIds()`, `db.getVariantsByIds()`, `db.getDiscountsByIds()` masing-masing sekali (3 queries total)
      - Bangun lookup maps: `Map<String, Product>`, `Map<String, ProductVariant>`, `Map<String, Discount>`
      - Iterasi items menggunakan lookup maps (O(1) per item, tanpa DB call di dalam loop)
      - Jika product tidak ditemukan di map, skip item tersebut (Req 3.8)
      - Untuk customer: gunakan `db.getCustomerById(transaction.customerId!)` bukan `getAllCustomers()`
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 9.1_

  - [x] 3.3 Refactor `ProductWithVariantsNotifier` untuk in-memory filter
    - Di `lib/features/pos/providers/pos_providers.dart`, pada class `ProductWithVariantsNotifier`:
      - Tambah field `List<ProductWithVariants> _allData = []`
      - Di `build()`, populate `_allData` dari initial data dan update di stream listener
      - Ubah `setSearch()`: hapus `ref.invalidateSelf()`, ganti dengan `state = AsyncValue.data(_filter(_allData))`
      - Ubah `setCategory()`: hapus `ref.invalidateSelf()`, ganti dengan `state = AsyncValue.data(_filter(_allData))`
      - Implementasi `_filter()` harus ekuivalen dengan `ProductNotifier._filter()` yang sudah ada
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

  - [x] 3.4 Tambah debounce 300ms pada search input di `PosTab`
    - Di `lib/features/pos/screens/pos_tab.dart`, pada `_PosTabState`:
      - Tambah field `Timer? _debounceTimer`
      - Di `dispose()`, tambah `_debounceTimer?.cancel()`
      - Pada `TextField.onChanged`: cancel timer lama, start timer baru 300ms, panggil `setSearch()` setelah timer selesai
      - Pada clear button `onPressed`: cancel timer, panggil `setSearch(null)` langsung (tanpa debounce)
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [x] 4. Checkpoint — Core fixes selesai
  - Pastikan semua tests pass, tanyakan ke user jika ada pertanyaan.

- [x] 5. Refactoring — Breaking changes dan stream subscription fix
  - [x] 5.1 Perbaiki `DiscountNotifier`: tambah `ref.select()` dan fix stream subscription leak
    - Di `lib/features/discount/providers/discount_provider.dart` (atau path yang sesuai):
      - Ubah `ref.watch(sessionProvider).value?.outletId` menjadi `ref.watch(sessionProvider.select((s) => s.value?.outletId))`
      - Simpan `StreamSubscription` dari `watchAllDiscounts().listen()` ke variabel lokal
      - Tambah `ref.onDispose(() => subscription.cancel())`
    - Terapkan perubahan `ref.select()` yang sama pada `validTransactionDiscountsProvider` dan `validItemDiscountsProvider`
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 7.1, 7.2, 7.3, 7.4, 7.5_

  - [x] 5.2 Eliminasi dual Realtime subscription di `SyncService`
    - Di `lib/core/services/sync_service.dart`:
      - Hapus field `RealtimeChannel? _realtimeChannel`
      - Hapus method `_startRealtimePull()`
      - Hapus method `_stopRealtimePull()`
      - Hapus panggilan `_startRealtimePull()` dari `start()`
      - Hapus panggilan `_stopRealtimePull()` dari `stop()`
    - Verifikasi `RealtimeService` tetap menjadi satu-satunya komponen yang mengelola Supabase Realtime channel
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7_

  - [x] 5.3 Refactor `ProductImage` dari `ConsumerWidget` menjadi `StatelessWidget` (breaking change)
    - Di `lib/core/widgets/product_image.dart`:
      - Ubah `class ProductImage extends ConsumerWidget` menjadi `class ProductImage extends StatelessWidget`
      - Hapus parameter `String? categoryId` dari constructor
      - Tambah parameter `String? categoryName` ke constructor
      - Ubah `Widget build(BuildContext context, WidgetRef ref)` menjadi `Widget build(BuildContext context)`
      - Hapus semua `ref.watch()` call di dalam widget
      - Gunakan `categoryName` langsung (bukan resolve dari `categoryId` via provider)
      - Ganti `NetworkImage` dengan `CachedNetworkImageProvider` untuk URL yang dimulai dengan `'http'`
      - Method `getCategoryIcon()` tetap static, tidak berubah
    - Update semua call site yang menggunakan `categoryId:` parameter:
      - `lib/features/pos/screens/pos_tab.dart` (di `_showImagePreview()`)
      - `lib/features/pos/widgets/pos_cards.dart` (di `PosProductCard`)
      - `lib/features/pos/screens/inventory_tab.dart` (jika ada)
      - Cari semua call site lain: `grep -r "categoryId:" lib/ --include="*.dart" | grep "ProductImage"`
      - Di setiap call site, resolve `categoryId → categoryName` menggunakan `categoryProvider` yang sudah di-watch di parent widget
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 12.1, 12.5, 12.6_

- [x] 6. Checkpoint — Refactoring selesai
  - Pastikan semua tests pass, tanyakan ke user jika ada pertanyaan.

- [x] 7. Medium Optimizations — GoogleFonts, cached_network_image, dan Dashboard KPI provider
  - [x] 7.1 Tambah dependency `cached_network_image` ke `pubspec.yaml`
    - Di `pubspec.yaml`, tambah `cached_network_image: ^3.4.1` di bawah `dependencies`
    - Jalankan `flutter pub get`
    - _Requirements: 12.2_

  - [x] 7.2 Optimasi `GoogleFonts` TextStyle menjadi `static final` constants
    - Di semua widget yang memanggil `GoogleFonts.poppins()` di dalam `build()`:
      - Pindahkan `TextStyle` yang tidak bergantung pada runtime value ke level class sebagai `static final`
      - Prioritaskan: `OwnerDashboardScreen`, `PosTab`, dan widget lain yang sering rebuild
      - Contoh: `static final _styleLabel = GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary);`
      - Hanya `TextStyle` yang tidak bergantung pada `Theme` colors dinamis atau ukuran runtime yang dijadikan `static final`
    - _Requirements: 11.1, 11.2, 11.3, 11.4_

  - [x] 7.3 Buat file baru `dashboard_kpi_provider.dart` dengan `DashboardKpiNotifier`
    - Buat file `lib/features/dashboard/providers/dashboard_kpi_provider.dart`
    - Definisikan class `DashboardKpiData` dengan fields `kpis: List<KpiItem>` dan `lowStockSummary: LowStockSummary`
    - Implementasi `DashboardKpiNotifier extends AsyncNotifier<DashboardKpiData>`:
      - Gunakan `ref.watch(sessionProvider.select((s) => s.value?.outletId))` untuk `outletId`
      - Di `build()`, setup stream subscription ke `db.watchAllTransactions(outletId)` dengan debounce 2000ms
      - Implementasi `_fetchKpiData()` yang menjalankan 8 queries secara paralel via `Future.wait()`
      - Implementasi method `refresh()` untuk manual refresh (immediate, tanpa debounce)
      - Di `ref.onDispose()`, cancel `_debounceTimer` dan `_txnSubscription`
    - Daftarkan `dashboardKpiProvider` sebagai `AsyncNotifierProvider<DashboardKpiNotifier, DashboardKpiData>`
    - _Requirements: 10.1, 10.2, 10.5, 10.6, 10.7, 10.8, 15.1, 15.2, 15.3, 15.4_

  - [x] 7.4 Migrasi `OwnerDashboardScreen` untuk menggunakan `dashboardKpiProvider`
    - Di `lib/features/dashboard/screens/owner_dashboard_screen.dart`:
      - Ubah dari `ConsumerStatefulWidget` menjadi `ConsumerWidget`
      - Hapus fields `_isLoading`, `_kpis`, `_txnSubscription`
      - Hapus method `_loadStats()` dan `initState()`/`dispose()` yang terkait
      - Gunakan `ref.watch(dashboardKpiProvider)` untuk mendapatkan `AsyncValue<DashboardKpiData>`
      - Update `RefreshIndicator.onRefresh` untuk memanggil `ref.read(dashboardKpiProvider.notifier).refresh()`
      - Tampilkan loading indicator hanya di KPI section (bukan full-screen `setState()`)
      - Gunakan `.when(loading:, error:, data:)` untuk render KPI section
    - _Requirements: 10.3, 10.4_

- [x] 8. Checkpoint — Medium optimizations selesai
  - Pastikan semua tests pass, tanyakan ke user jika ada pertanyaan.

- [x] 9. Property-Based Tests dan Unit Tests
  - [x]* 9.1 Tulis unit tests untuk `CartNotifier.checkout()` (Req 8)
    - Verifikasi `ref.invalidate(productProvider)` tidak dipanggil setelah checkout
    - Verifikasi `clearCart()` tetap dipanggil
    - _Requirements: 8.1, 8.3_

  - [x]* 9.2 Tulis unit tests untuk `LumioDatabase` batch-fetch methods (Req 3 & 9)
    - Verifikasi `getProductsByIds([])` return empty list tanpa query
    - Verifikasi `getCustomerById(validId)` return `Customer` object
    - Verifikasi `getCustomerById(invalidId)` return `null`
    - Verifikasi `getProductsByIds(ids)` hanya memanggil satu query
    - _Requirements: 3.2, 3.3, 3.4, 9.3, 9.4, 9.5_

  - [x]* 9.3 Tulis unit tests untuk `ProductWithVariantsNotifier` (Req 2)
    - Verifikasi `_allData` terpopulasi setelah `build()`
    - Verifikasi `setSearch()` tidak memanggil `invalidateSelf()`
    - Verifikasi `setCategory()` tidak memanggil `invalidateSelf()`
    - Verifikasi state diupdate dari `_allData` setelah `setSearch()`
    - _Requirements: 2.1, 2.2, 2.4, 2.5_

  - [x]* 9.4 Tulis unit tests untuk `ProductImage` (Req 4 & 12)
    - Verifikasi class extends `StatelessWidget` (bukan `ConsumerWidget`)
    - Verifikasi tidak ada `ref.watch()` di source code widget
    - Verifikasi `CachedNetworkImageProvider` digunakan untuk URL yang dimulai dengan `'http'`
    - Verifikasi `FileImage` digunakan untuk path lokal
    - _Requirements: 4.1, 4.3, 12.1, 12.5_

  - [x]* 9.5 Tulis unit tests untuk `DiscountNotifier` (Req 6 & 7)
    - Verifikasi `subscription.cancel()` dipanggil saat provider di-dispose
    - Verifikasi `ref.select()` digunakan untuk `outletId`
    - _Requirements: 6.2, 7.2, 7.3_

  - [x]* 9.6 Tulis unit tests untuk `dashboardKpiProvider` (Req 10 & 15)
    - Verifikasi 8 queries dijalankan via `Future.wait()`
    - Verifikasi `ref.onDispose()` cancel timer dan subscription
    - Verifikasi `refresh()` memanggil `invalidateSelf()` tanpa debounce
    - _Requirements: 10.2, 10.8, 15.3, 15.4_

  - [x]* 9.7 Tulis property test untuk Filter Round-Trip Search (Property 1)
    - **Property 1: Filter Round-Trip — Search**
    - Untuk 100 iterasi dengan random `List<ProductWithVariants>` dan random query string: `setSearch(query)` lalu `setSearch(null)` harus menghasilkan state ekuivalen dengan `_allData`
    - **Validates: Requirements 2.7**

  - [x]* 9.8 Tulis property test untuk Filter Round-Trip Category (Property 2)
    - **Property 2: Filter Round-Trip — Category**
    - Untuk 100 iterasi dengan random `List<ProductWithVariants>` dan random category ID: `setCategory(id)` lalu `setCategory(null)` harus menghasilkan state ekuivalen dengan `_allData`
    - **Validates: Requirements 2.8**

  - [x]* 9.9 Tulis property test untuk Filter Idempotence (Property 3)
    - **Property 3: Filter Idempotence**
    - Untuk 100 iterasi: `_filter(_filter(data, q, cat), q, cat) == _filter(data, q, cat)` untuk semua kombinasi data, query, dan category
    - **Validates: Requirements 2.4, 2.5**

  - [x]* 9.10 Tulis property test untuk Filter Subset Invariant (Property 4)
    - **Property 4: Filter Subset Invariant**
    - Untuk 100 iterasi: `len(_filter(data, query, category)) <= len(data)` untuk semua input valid
    - **Validates: Requirements 2.4, 2.5**

  - [x]* 9.11 Tulis property test untuk N+1 Query Elimination (Property 5)
    - **Property 5: N+1 Query Elimination**
    - Untuk N ∈ {1, 5, 10, 20, 50}: jumlah DB queries dari `resumeBill()` harus ≤ 3 dan tidak bergantung pada N
    - **Validates: Requirements 3.1, 3.6**

  - [x]* 9.12 Tulis property test untuk `getCategoryIcon` Referential Transparency (Property 6)
    - **Property 6: getCategoryIcon Referential Transparency**
    - Untuk 100 iterasi dengan random string: `getCategoryIcon(name) == getCategoryIcon(name)` (pure function, no side effects)
    - **Validates: Requirements 4.7, 4.8**

  - [x]* 9.13 Tulis property test untuk Debounce Coalescing (Property 7)
    - **Property 7: Debounce Coalescing**
    - Untuk N ∈ {2..20} panggilan dalam window debounce W: hanya 1 eksekusi yang terjadi setelah W berlalu
    - Berlaku untuk search debounce (W=300ms), sync queue debounce (W=500ms), dashboard debounce (W=2000ms)
    - Gunakan `fake_async` package untuk simulasi waktu
    - **Validates: Requirements 5.1, 5.2, 5.3, 14.1, 14.2, 15.1, 15.2**

  - [x]* 9.14 Tulis property test untuk `ref.select()` Rebuild Isolation (Property 8)
    - **Property 8: ref.select() Rebuild Isolation**
    - Verifikasi bahwa perubahan `sessionProvider` yang tidak mengubah `outletId` tidak memicu rebuild pada `DiscountNotifier`, `validTransactionDiscountsProvider`, dan `validItemDiscountsProvider`
    - **Validates: Requirements 6.5**

- [x] 10. Final Checkpoint — Semua tasks selesai
  - Pastikan semua tests pass, tanyakan ke user jika ada pertanyaan.

## Notes

- Tasks bertanda `*` bersifat opsional dan dapat dilewati untuk MVP yang lebih cepat
- Setiap task mereferensikan requirements spesifik untuk traceability
- Urutan eksekusi: quick wins (1) → core fixes (3) → refactoring (5) → medium optimizations (7) → tests (9)
- **Breaking change di task 5.3**: `ProductImage` mengubah parameter `categoryId` → `categoryName`. Semua call site harus diupdate sebelum task ini dianggap selesai
- Setelah task 7.1 (`flutter pub get`), tidak perlu `build_runner` karena tidak ada perubahan Drift table schema
- Property tests menggunakan `dart:test` + implementasi manual generator dengan `dart:math` Random (minimum 100 iterasi per property)
- Unit tests ada di `mobile/test/unit/`

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "1.3"] },
    { "id": 1, "tasks": ["3.1"] },
    { "id": 2, "tasks": ["3.2", "3.3", "3.4", "5.1", "5.2"] },
    { "id": 3, "tasks": ["5.3"] },
    { "id": 4, "tasks": ["7.1"] },
    { "id": 5, "tasks": ["7.2", "7.3"] },
    { "id": 6, "tasks": ["7.4"] },
    { "id": 7, "tasks": ["9.1", "9.2", "9.3", "9.4", "9.5", "9.6"] },
    { "id": 8, "tasks": ["9.7", "9.8", "9.9", "9.10", "9.11", "9.12", "9.13", "9.14"] }
  ]
}
```
