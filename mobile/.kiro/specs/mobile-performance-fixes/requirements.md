# Requirements Document

## Introduction

Dokumen ini mendefinisikan persyaratan untuk perbaikan performa aplikasi mobile Lumio POS berdasarkan hasil audit performa. Audit mengidentifikasi 15 isu yang dikategorikan sebagai Critical (🔴), High (🟠), dan Medium (🟡) yang menyebabkan UI jank, query berlebihan, memory leak, dan rebuild widget yang tidak perlu.

Perbaikan ini bersifat refactoring internal — tidak mengubah fungsionalitas yang terlihat oleh pengguna, tetapi secara signifikan meningkatkan responsivitas, efisiensi memori, dan stabilitas aplikasi.

## Glossary

- **SyncService**: Service di `lib/core/services/sync_service.dart` yang mengelola sinkronisasi data lokal (Drift/SQLite) ke Supabase Cloud.
- **RealtimeService**: Service di `lib/core/services/realtime_service.dart` yang mengelola subscription Supabase Realtime dengan filter per tabel dan tier guard.
- **ProductWithVariantsNotifier**: Riverpod `AsyncNotifier` di `pos_providers.dart` yang menyediakan daftar produk beserta variannya untuk layar inventori.
- **ProductNotifier**: Riverpod `AsyncNotifier` di `pos_providers.dart` yang menyediakan daftar produk untuk layar kasir (POS), sudah menggunakan pola filter in-memory yang benar.
- **CartNotifier**: Riverpod `AsyncNotifier` di `pos_providers.dart` yang mengelola state keranjang belanja, termasuk operasi `resumeBill()` dan `checkout()`.
- **DiscountNotifier**: Riverpod `AsyncNotifier` di `discount_provider.dart` yang mengelola daftar diskon dengan stream subscription ke database.
- **ProductImage**: Widget `ConsumerWidget` di `lib/core/widgets/product_image.dart` yang menampilkan gambar produk dengan fallback ikon kategori.
- **OwnerDashboardScreen**: Layar dashboard owner di `lib/features/dashboard/screens/owner_dashboard_screen.dart` yang menampilkan KPI bisnis harian.
- **PosTab**: Layar kasir utama di `lib/features/pos/screens/pos_tab.dart` yang berisi search bar produk dan grid produk.
- **sessionProvider**: Riverpod provider yang menyimpan data sesi karyawan aktif, termasuk `outletId` dan `role`.
- **ref.invalidateSelf()**: Metode Riverpod yang menghancurkan dan membangun ulang seluruh provider, termasuk re-run query database.
- **ref.select()**: Metode Riverpod untuk subscribe hanya pada sebagian state provider, mencegah rebuild yang tidak perlu.
- **Debounce**: Teknik menunda eksekusi fungsi hingga tidak ada input baru selama durasi tertentu.
- **N+1 Query**: Anti-pattern di mana satu operasi menghasilkan N query tambahan di dalam loop, alih-alih satu query batch.
- **In-memory filter**: Teknik memfilter data dari cache lokal (`_allData`) tanpa query ulang ke database.
- **StreamSubscription**: Objek Dart yang merepresentasikan langganan aktif ke sebuah stream; harus di-cancel saat tidak digunakan untuk mencegah memory leak.
- **Drift ORM**: Library SQLite untuk Flutter yang digunakan sebagai database lokal offline-first.
- **Riverpod**: Library state management Flutter yang digunakan di seluruh aplikasi.
- **GoogleFonts**: Package Flutter untuk menggunakan Google Fonts; memanggil `GoogleFonts.poppins()` di setiap `build()` membuat objek `TextStyle` baru setiap rebuild.
- **cached_network_image**: Package Flutter untuk caching gambar dari network ke disk.
- **SyncQueue**: Antrian tugas sinkronisasi lokal yang menunggu untuk dikirim ke Supabase.

---

## Requirements

### Requirement 1: Eliminasi Dual Realtime Subscription

**User Story:** Sebagai developer, saya ingin menghapus subscription Supabase Realtime yang duplikat di `SyncService`, sehingga aplikasi tidak membuat dua koneksi WebSocket ke channel yang sama secara bersamaan.

#### Acceptance Criteria

1. THE `SyncService` SHALL NOT contain the `_startRealtimePull()` method, `_stopRealtimePull()` method, or `_realtimeChannel` field after the fix is applied.
2. WHEN `SyncService.start()` is called, THE `SyncService` SHALL NOT create any Supabase Realtime channel subscription.
3. WHEN `SyncService.stop()` is called, THE `SyncService` SHALL NOT attempt to unsubscribe from any Realtime channel.
4. THE `RealtimeService` SHALL remain the sole component responsible for managing Supabase Realtime channel subscriptions.
5. WHEN the application is running with a Pro tier user, THE `RealtimeService` SHALL maintain exactly one active Supabase Realtime channel named `'public:lumio_sync'`.
6. THE `RealtimeService` SHALL continue to apply per-table `outlet_id` filters on all Realtime subscriptions as currently implemented.
7. THE `RealtimeService` SHALL continue to enforce the Pro tier guard before creating any Realtime subscription.

---

### Requirement 2: Filter In-Memory pada ProductWithVariantsNotifier

**User Story:** Sebagai kasir, saya ingin pencarian dan filter kategori pada layar inventori berjalan tanpa lag, sehingga saya bisa menemukan produk dengan cepat bahkan saat mengetik cepat.

#### Acceptance Criteria

1. THE `ProductWithVariantsNotifier` SHALL maintain an internal cache field `_allData` of type `List<ProductWithVariants>` that stores the complete unfiltered dataset.
2. WHEN `ProductWithVariantsNotifier.build()` is called, THE `ProductWithVariantsNotifier` SHALL populate `_allData` with the initial data from the database query.
3. WHEN the stream subscription in `ProductWithVariantsNotifier` receives new data, THE `ProductWithVariantsNotifier` SHALL update `_allData` with the new data before applying the filter.
4. WHEN `ProductWithVariantsNotifier.setSearch()` is called with any query string, THE `ProductWithVariantsNotifier` SHALL update the state by filtering `_allData` in-memory WITHOUT calling `ref.invalidateSelf()`.
5. WHEN `ProductWithVariantsNotifier.setCategory()` is called with any category ID, THE `ProductWithVariantsNotifier` SHALL update the state by filtering `_allData` in-memory WITHOUT calling `ref.invalidateSelf()`.
6. THE `ProductWithVariantsNotifier._filter()` method SHALL produce results equivalent to `ProductNotifier._filter()` for the same input data and filter parameters.
7. FOR ALL valid `List<ProductWithVariants>` inputs, calling `setSearch(query)` followed by `setSearch(null)` SHALL produce a state equivalent to the unfiltered `_allData`.
8. FOR ALL valid `List<ProductWithVariants>` inputs, calling `setCategory(id)` followed by `setCategory(null)` SHALL produce a state equivalent to the unfiltered `_allData`.

---

### Requirement 3: Eliminasi N+1 Query pada resumeBill()

**User Story:** Sebagai kasir, saya ingin melanjutkan bill yang disimpan (held bill) dengan cepat, sehingga pelanggan tidak perlu menunggu lama saat saya membuka kembali pesanan yang tertunda.

#### Acceptance Criteria

1. WHEN `CartNotifier.resumeBill()` is called with a transaction containing N items, THE `CartNotifier` SHALL execute at most 3 database queries total (one for all products, one for all variants, one for all discounts), regardless of the value of N.
2. THE `CartNotifier.resumeBill()` SHALL batch-fetch all required products using a single query before iterating over transaction items.
3. THE `CartNotifier.resumeBill()` SHALL batch-fetch all required variants using a single query before iterating over transaction items.
4. THE `CartNotifier.resumeBill()` SHALL batch-fetch all required discounts using a single query before iterating over transaction items.
5. WHEN `CartNotifier.resumeBill()` is called, THE `CartNotifier` SHALL build lookup maps (e.g., `Map<String, Product>`) from the batch-fetched data to resolve items by ID in O(1) time.
6. FOR ALL transactions with N items where N >= 1, the number of database queries executed by `resumeBill()` SHALL be independent of N.
7. WHEN `CartNotifier.resumeBill()` is called with a transaction that has a `customerId`, THE `CartNotifier` SHALL use a single-record lookup (e.g., `db.getCustomerById()`) instead of fetching all customers.
8. IF a product referenced in a transaction item does not exist in the database, THEN THE `CartNotifier` SHALL skip that item and continue processing the remaining items.

---

### Requirement 4: Refactor ProductImage menjadi StatelessWidget

**User Story:** Sebagai pengguna, saya ingin grid produk di layar kasir tidak mengalami jank saat kategori diperbarui, sehingga pengalaman scrolling tetap mulus.

#### Acceptance Criteria

1. THE `ProductImage` widget SHALL be a `StatelessWidget` instead of a `ConsumerWidget`.
2. THE `ProductImage` widget SHALL accept a `categoryName` parameter of type `String?` instead of a `categoryId` parameter.
3. THE `ProductImage` widget SHALL NOT call `ref.watch()` or any Riverpod method internally.
4. WHEN `ProductImage` is rendered with a non-null `categoryName`, THE `ProductImage` SHALL use `categoryName` directly for icon resolution via `getCategoryIcon()`.
5. THE parent widget that uses `ProductImage` SHALL be responsible for resolving `categoryId` to `categoryName` before passing it to `ProductImage`.
6. WHEN `categoryProvider` state changes, THE `ProductImage` widget instances SHALL NOT rebuild unless their own `categoryName` parameter value changes.
7. THE `ProductImage.getCategoryIcon()` static method SHALL remain a pure function that maps a category name string to an `IconData`, with no side effects.
8. FOR ALL valid `categoryName` strings, `getCategoryIcon(categoryName)` SHALL return the same `IconData` for the same input (referential transparency).

---

### Requirement 5: Debounce pada Search Input di PosTab

**User Story:** Sebagai kasir, saya ingin pencarian produk tidak langsung memproses setiap keystroke, sehingga aplikasi tidak terasa berat saat saya mengetik nama produk dengan cepat.

#### Acceptance Criteria

1. THE `PosTab` search `TextField.onChanged` callback SHALL debounce calls to `productProvider.notifier.setSearch()` with a delay of 300 milliseconds.
2. WHEN a user types continuously, THE `PosTab` SHALL call `setSearch()` only once, 300 milliseconds after the last keystroke.
3. WHEN a user stops typing for 300 milliseconds, THE `PosTab` SHALL call `setSearch()` exactly once with the current input value.
4. WHEN the search field is cleared (via the clear button), THE `PosTab` SHALL call `setSearch(null)` immediately without debounce delay.
5. WHEN `PosTab` is disposed, THE `PosTab` SHALL cancel the active debounce `Timer` to prevent calling `setSearch()` after the widget is unmounted.
6. THE debounce implementation SHALL use `dart:async Timer` and SHALL be cancelled and replaced on each new keystroke within the debounce window.

---

### Requirement 6: Penggunaan ref.select() pada sessionProvider

**User Story:** Sebagai developer, saya ingin provider yang hanya membutuhkan `outletId` dari sesi tidak ikut rebuild saat field lain di sesi berubah, sehingga jumlah rebuild provider yang tidak perlu berkurang.

#### Acceptance Criteria

1. WHEN a provider only requires `outletId` from the session, THE provider SHALL use `ref.watch(sessionProvider.select((s) => s.value?.outletId))` instead of `ref.watch(sessionProvider)`.
2. THE `DiscountNotifier.build()` SHALL use `ref.watch(sessionProvider.select((s) => s.value?.outletId))` to obtain `outletId`.
3. THE `validTransactionDiscountsProvider` SHALL use `ref.watch(sessionProvider.select((s) => s.value?.outletId))` to obtain `outletId`.
4. THE `validItemDiscountsProvider` SHALL use `ref.watch(sessionProvider.select((s) => s.value?.outletId))` to obtain `outletId`.
5. WHEN `sessionProvider` state changes but `outletId` remains the same value, THE providers listed in criteria 2-4 SHALL NOT rebuild.
6. WHEN `sessionProvider` state changes and `outletId` changes to a different value, THE providers listed in criteria 2-4 SHALL rebuild.

---

### Requirement 7: Perbaikan Stream Subscription Leak pada DiscountNotifier

**User Story:** Sebagai developer, saya ingin stream subscription di `DiscountNotifier` selalu di-cancel saat provider di-dispose, sehingga tidak ada memory leak atau callback yang dipanggil setelah provider tidak aktif.

#### Acceptance Criteria

1. THE `DiscountNotifier.build()` SHALL store the `StreamSubscription` returned by `watchAllDiscounts().listen()` in a local variable.
2. THE `DiscountNotifier.build()` SHALL register a `ref.onDispose()` callback that calls `cancel()` on the stored `StreamSubscription`.
3. WHEN `DiscountNotifier` is disposed by Riverpod, THE `DiscountNotifier` SHALL cancel the active stream subscription.
4. AFTER `DiscountNotifier` is disposed, THE stream listener callback SHALL NOT update the provider state.
5. THE `DiscountNotifier` subscription management pattern SHALL be equivalent to the pattern already used in `CategoryNotifier` and `ProductNotifier`.

---

### Requirement 8: Hapus ref.invalidate(productProvider) setelah Checkout

**User Story:** Sebagai developer, saya ingin proses checkout tidak memicu rebuild `productProvider` yang tidak perlu, karena stream subscription sudah menangani pembaruan stok secara otomatis.

#### Acceptance Criteria

1. THE `CartNotifier.checkout()` method SHALL NOT call `ref.invalidate(productProvider)` after a successful checkout.
2. WHEN a checkout is completed successfully, THE `productProvider` SHALL receive stock updates automatically via its existing stream subscription to `db.watchAllProducts()`.
3. WHEN a checkout is completed successfully, THE `CartNotifier` SHALL still call `clearCart()` to reset the cart state.
4. THE removal of `ref.invalidate(productProvider)` SHALL NOT cause product stock to become stale or out-of-sync with the database after checkout.

---

### Requirement 9: Single-Record Lookup untuk Customer di resumeBill()

**User Story:** Sebagai kasir, saya ingin melanjutkan held bill lebih cepat, sehingga sistem tidak perlu memuat seluruh daftar pelanggan hanya untuk menemukan satu pelanggan berdasarkan ID.

#### Acceptance Criteria

1. WHEN `CartNotifier.resumeBill()` needs to restore customer information and `transaction.customerId` is not null, THE `CartNotifier` SHALL use a single-record database lookup (e.g., `db.getCustomerById(customerId)`) instead of `db.getAllCustomers(outletId)`.
2. THE `LumioDatabase` SHALL expose a `getCustomerById(String id)` method that returns a single `Customer?` record.
3. WHEN `getCustomerById()` is called with a valid customer ID, THE `LumioDatabase` SHALL return the matching `Customer` object.
4. IF `getCustomerById()` is called with an ID that does not exist in the database, THEN THE `LumioDatabase` SHALL return `null`.
5. THE `getCustomerById()` query SHALL use a primary key lookup (WHERE id = ?) and SHALL NOT perform a full table scan.

---

### Requirement 10: Migrasi KPI Dashboard ke Riverpod Provider

**User Story:** Sebagai owner, saya ingin dashboard KPI tidak menyebabkan full-screen rebuild setiap kali data statistik dimuat, sehingga animasi dan elemen UI lain di dashboard tetap responsif.

#### Acceptance Criteria

1. THE `OwnerDashboardScreen` SHALL delegate KPI data loading to a dedicated Riverpod `AsyncNotifierProvider` (e.g., `dashboardKpiProvider`).
2. THE `dashboardKpiProvider` SHALL encapsulate all 8 database queries currently in `_loadStats()` (revenue today/yesterday, transactions today/yesterday, top products, hourly sales, low stock products, low stock ingredients).
3. WHEN KPI data is loading, THE `OwnerDashboardScreen` SHALL display a loading indicator only in the KPI section, NOT trigger a full-screen `setState()` rebuild.
4. WHEN KPI data finishes loading, THE `OwnerDashboardScreen` SHALL update only the KPI widget subtree, NOT rebuild the entire screen.
5. THE `dashboardKpiProvider` SHALL watch `sessionProvider.select((s) => s.value?.outletId)` to avoid unnecessary rebuilds when other session fields change.
6. THE `dashboardKpiProvider` SHALL expose a `refresh()` method that can be called from the `RefreshIndicator.onRefresh` callback.
7. WHEN `db.watchAllTransactions()` emits a new event, THE `dashboardKpiProvider` SHALL automatically refresh KPI data.
8. THE `dashboardKpiProvider` SHALL cancel its transaction stream subscription via `ref.onDispose()`.

---

### Requirement 11: Optimasi GoogleFonts TextStyle

**User Story:** Sebagai developer, saya ingin `TextStyle` dari `GoogleFonts.poppins()` tidak dibuat ulang setiap kali widget di-rebuild, sehingga mengurangi alokasi objek yang tidak perlu.

#### Acceptance Criteria

1. THE `OwnerDashboardScreen` and all widgets that use `GoogleFonts.poppins()` SHALL define frequently-used `TextStyle` instances as `static final` constants at the class level.
2. THE `static final` `TextStyle` constants SHALL be defined outside of the `build()` method.
3. WHEN a widget rebuilds, THE widget SHALL reuse the pre-defined `static final` `TextStyle` instances instead of calling `GoogleFonts.poppins()` again.
4. FOR ALL `TextStyle` instances that do not depend on runtime values (e.g., `Theme` colors or dynamic sizes), THE widget SHALL use `static final` constants.

---

### Requirement 12: Disk Caching untuk NetworkImage

**User Story:** Sebagai kasir, saya ingin gambar produk yang sudah pernah dimuat tidak diunduh ulang dari internet saat saya scroll grid produk, sehingga grid terasa lebih responsif dan hemat data.

#### Acceptance Criteria

1. THE `ProductImage` widget SHALL use `CachedNetworkImageProvider` from the `cached_network_image` package instead of `NetworkImage` for URLs that start with `'http'`.
2. THE `pubspec.yaml` SHALL include `cached_network_image` as a dependency.
3. WHEN a network image URL is loaded for the first time, THE `ProductImage` SHALL download and cache the image to disk.
4. WHEN a network image URL is loaded subsequently (e.g., after scrolling), THE `ProductImage` SHALL serve the image from disk cache WITHOUT making a new network request.
5. THE `ProductImage` SHALL continue to use `FileImage` for local file paths (URIs that do not start with `'http'`).
6. THE error builder and loading builder behavior SHALL be preserved after the migration to `CachedNetworkImageProvider`.

---

### Requirement 13: Optimasi GridView Layout dengan mainAxisExtent

**User Story:** Sebagai kasir, saya ingin grid produk di layar kasir tidak melakukan pengukuran layout yang berlebihan, sehingga rendering grid lebih cepat terutama saat ada banyak produk.

#### Acceptance Criteria

1. THE `GridView.builder` in `PosTab._buildProductGrid()` SHALL use `SliverGridDelegateWithFixedCrossAxisCount` with a fixed `mainAxisExtent` value instead of relying on `childAspectRatio` alone.
2. THE `mainAxisExtent` value SHALL be set to a fixed pixel value appropriate for the product card design (e.g., consistent with the current `childAspectRatio: 0.75` rendering).
3. WHEN `mainAxisExtent` is set, THE `GridView` SHALL NOT perform intrinsic height measurement on each child widget during layout.

---

### Requirement 14: Debounce pada Sync Queue

**User Story:** Sebagai developer, saya ingin proses sinkronisasi tidak dipicu puluhan kali berturutan saat checkout, sehingga beban I/O dan network berkurang secara signifikan.

#### Acceptance Criteria

1. THE `SyncService` stream listener on `db.syncQueueNotifier` SHALL debounce calls to `_processSyncQueue()` with a delay of 500 milliseconds.
2. WHEN multiple sync queue events are emitted within 500 milliseconds (e.g., during checkout), THE `SyncService` SHALL call `_processSyncQueue()` only once, 500 milliseconds after the last event.
3. WHEN `SyncService.stop()` is called, THE `SyncService` SHALL cancel the active debounce `Timer` to prevent `_processSyncQueue()` from being called after the service is stopped.
4. THE debounce SHALL NOT delay the initial sync triggered by `SyncService.start()` calling `performSync()` directly.
5. THE `SyncService` SHALL store the debounce `Timer` as a field and cancel it in `stop()`.

---

### Requirement 15: Debounce pada Dashboard Stats Loading

**User Story:** Sebagai owner, saya ingin dashboard tidak menjalankan 8 query database berulang kali dalam waktu singkat saat ada banyak transaksi masuk bersamaan, sehingga performa database tetap stabil.

#### Acceptance Criteria

1. THE `dashboardKpiProvider` (atau mekanisme refresh yang setara) SHALL debounce calls to the stats-loading logic with a delay of 2000 milliseconds when triggered by stream events.
2. WHEN multiple transaction stream events are emitted within 2000 milliseconds, THE `dashboardKpiProvider` SHALL execute the 8 KPI database queries only once, 2000 milliseconds after the last event.
3. WHEN a user manually triggers a refresh via `RefreshIndicator`, THE stats loading SHALL execute immediately WITHOUT debounce delay.
4. THE debounce timer SHALL be cancelled via `ref.onDispose()` to prevent queries from running after the provider is disposed.

---

## Correctness Properties

Bagian ini mendefinisikan properti-properti yang dapat diverifikasi secara otomatis menggunakan property-based testing.

### Property 1: In-Memory Filter Idempotence (Req. 2 & 3)

**Tipe**: Idempotence

Untuk semua `List<ProductWithVariants>` yang valid, menerapkan filter yang sama dua kali berturutan harus menghasilkan hasil yang identik dengan menerapkannya sekali:

```
filter(filter(data, query, category), query, category) == filter(data, query, category)
```

### Property 2: Filter Round-Trip (Req. 2)

**Tipe**: Round-Trip

Untuk semua `List<ProductWithVariants>` yang valid, menerapkan filter lalu menghapus filter harus mengembalikan dataset yang setara dengan dataset asli:

```
setSearch(null) after setSearch(query) → state equivalent to _allData
setCategory(null) after setCategory(id) → state equivalent to _allData
```

### Property 3: N+1 Query Elimination (Req. 3)

**Tipe**: Metamorphic / Invariant

Untuk semua transaksi dengan N item (N ≥ 1), jumlah query database yang dieksekusi oleh `resumeBill()` harus konstan dan tidak bergantung pada N:

```
queryCount(resumeBill(transaction_with_1_item)) == queryCount(resumeBill(transaction_with_N_items))
```

### Property 4: Filter Subset Invariant (Req. 2)

**Tipe**: Metamorphic

Untuk semua input yang valid, hasil filter harus selalu merupakan subset dari dataset asli:

```
len(filter(data, query, category)) <= len(data)
```

### Property 5: Debounce Coalescing (Req. 5 & 14)

**Tipe**: Idempotence

Untuk N panggilan berturutan dalam window debounce, hanya satu eksekusi yang terjadi:

```
N calls within debounce_window → exactly 1 execution after debounce_window
```

### Property 6: getCategoryIcon Pure Function (Req. 4)

**Tipe**: Invariant / Referential Transparency

Untuk semua string input yang valid, `getCategoryIcon()` harus selalu mengembalikan nilai yang sama untuk input yang sama:

```
getCategoryIcon(name) == getCategoryIcon(name)  // for all name
getCategoryIcon(name.toLowerCase()) == getCategoryIcon(name)  // case insensitive
```
