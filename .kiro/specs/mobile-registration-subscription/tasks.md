# Implementation Plan: Mobile Registration & Subscription Flow

## Overview

Implementasi dilakukan dalam 10 tahap sesuai urutan dependensi: dimulai dari fondasi Web API (shared auth helper), lalu modifikasi endpoint yang ada, kemudian data model dan state management Flutter, diikuti UI multi-step, dan diakhiri dengan update AppBootstrap dan test suite.

Bahasa: **TypeScript** (Web API) + **Dart/Flutter** (Mobile)

## Tasks

- [x] 1. Buat shared auth helper di Web API
  - Buat file baru `lumiopos-web/lib/auth/auth-helper.ts`
  - Implementasikan tipe `AuthResult` dengan union type `{ success: true; user: User } | { success: false; reason: 'unauthorized' | 'service_unavailable' }`
  - Implementasikan fungsi `resolveAuthenticatedUser(request: Request): Promise<AuthResult>`
  - Priority 1: cek header `Authorization: Bearer <token>` — validasi via `supabase.auth.getUser(token)` menggunakan anon client (bukan server client)
  - Priority 2: fallback ke cookie session via `createServerClient()` yang sudah ada
  - Tangani timeout Supabase (5 detik) dengan mengembalikan `reason: 'service_unavailable'`
  - Tangani error network/unreachable dengan `reason: 'service_unavailable'`
  - Jika tidak ada Bearer dan tidak ada cookie valid, kembalikan `reason: 'unauthorized'`
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7_


- [x] 2. Modifikasi Checkout_API untuk mendukung Bearer token
  - Edit `lumiopos-web/app/api/subscription/checkout/route.ts`
  - Ganti blok auth check yang ada (cookie-only) dengan `resolveAuthenticatedUser(request)` dari helper baru
  - Petakan `authResult.reason === 'service_unavailable'` → HTTP 503
  - Petakan `authResult.reason === 'unauthorized'` → HTTP 401
  - Tambahkan validasi userId mismatch: jika request menggunakan Bearer token DAN `userId` di body berbeda dengan `authResult.user.id`, kembalikan HTTP 403 dengan `{ error: 'Forbidden: userId mismatch' }`
  - Deteksi Bearer auth dengan `request.headers.get('Authorization')?.startsWith('Bearer ')` — validasi mismatch hanya berlaku untuk Bearer, tidak untuk cookie session
  - Pastikan flow web existing (cookie session) tidak berubah perilakunya
  - _Requirements: 5.1, 5.2, 5.3, 5.7, 5.8, 5.9, 9.1_

- [x] 3. Modifikasi Status_API untuk mendukung Bearer token
  - Edit `lumiopos-web/app/api/subscription/status/route.ts`
  - Ganti blok auth check yang ada dengan `resolveAuthenticatedUser(request)` dari helper yang sama
  - Petakan `authResult.reason === 'service_unavailable'` → HTTP 503
  - Petakan `authResult.reason === 'unauthorized'` → HTTP 401
  - Pastikan format error response JSON konsisten dengan Checkout_API: `{ error: '...' }`
  - Pastikan flow web existing (cookie session) tidak berubah perilakunya
  - _Requirements: 5.4, 5.5, 5.6, 5.9, 9.1_


- [x] 4. Buat model `SubscriptionPackage` di Flutter
  - Buat file baru `mobile/lib/features/auth/models/subscription_package.dart`
  - Definisikan class `SubscriptionPackage` dengan field: `name` (String), `slug` (String), `price` (int, dalam Rupiah), `durationMonths` (int, 0 = lifetime), `features` (List\<String\>)
  - Tambahkan factory constructor `SubscriptionPackage.fromJson(Map<String, dynamic> json)` untuk parsing dari Supabase response (`subscription_packages` table: `name`, `slug`, `price`, `duration_months`, `features` JSONB)
  - Tambahkan getter `formattedPrice` yang mengembalikan string format Rupiah menggunakan `NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)`
  - Tambahkan static getter `fallbackPackages` yang mengembalikan list hardcoded: Lite (slug: `'lite'`, price: 99000) dan Pro (slug: `'pro'`, price: 249000) sesuai design doc
  - _Requirements: 2.2, 2.5_

- [x] 5. Buat `RegistrationState` dan `RegistrationNotifier` di Flutter
  - Buat file baru `mobile/lib/features/auth/providers/registration_provider.dart`
  - Definisikan class `RegistrationState` dengan semua field yang dibutuhkan: `currentStep` (int, default 0), `isLoading` (bool), `errorMessage` (String?), field Step 1 (`storeName`, `businessType`, `phone`, `email`, `password`), field Step 1 result (`userId`, `accessToken`), field Step 2 (`packages` List\<SubscriptionPackage\>, `selectedPackageSlug` String), field Step 3 (`invoiceNumber`, `paymentUrl`, `expiredAt`)
  - Implementasikan `RegistrationState.copyWith()` untuk immutable state updates
  - Buat `RegistrationNotifier extends AsyncNotifier<RegistrationState>` dengan `@riverpod` annotation
  - Implementasikan `submitStep1({required String storeName, required String businessType, required String phone, required String email, required String password})`: panggil `supabase.auth.signUp()` dengan metadata, insert ke `store_profile` (lanjutkan ke Step 2 meski insert gagal), simpan `userId` dan `accessToken`, set `currentStep = 1`; tangani timeout 30 detik
  - Implementasikan `fetchPackages()`: query `subscription_packages` dengan filter `is_active = true`, timeout 10 detik, fallback ke `SubscriptionPackage.fallbackPackages` jika gagal/timeout
  - Implementasikan `selectPackage(String slug)`: update `selectedPackageSlug` di state
  - Implementasikan `initiateCheckout(String packageSlug)`: POST ke Checkout_API dengan header `Authorization: Bearer <accessToken>`, body `{userId, packageSlug}`, simpan `invoiceNumber`, `paymentUrl`, `expiredAt`, set `currentStep = 2`
  - Implementasikan `renewCheckout()`: panggil ulang Checkout_API dengan data yang sama
  - Implementasikan `createTrialLicense()`: delegasikan ke `LicenseNotifier.createTrialLicense()`, lalu `ref.invalidate(licenseProvider)`
  - Implementasikan `startRealtimeSubscription(String userId)` dan `cancelRealtimeSubscription()` untuk Supabase channel pada tabel `licenses` dengan filter `user_id=eq.{userId}`
  - _Requirements: 1.10, 1.11, 1.12, 1.13, 1.14, 2.1, 2.6, 2.7, 2.8, 2.9, 3.6, 3.7, 3.8, 4.1, 4.2, 6.7_


- [x] 6. Tambahkan `createTrialLicense()` ke `LicenseNotifier`
  - Edit `mobile/lib/features/auth/providers/auth_providers.dart`
  - Tambahkan method `createTrialLicense(String userId)` ke class `LicenseNotifier` (bukan extension, langsung di class)
  - Cek apakah trial sudah pernah dibuat: query `db.getLocalLicense()` dan cek apakah `licenseCode.startsWith('TRIAL-')` — jika ya, kembalikan `(false, 'Trial sudah pernah digunakan.')`
  - Jika belum ada trial, insert ke tabel `licenses` via Drift dengan nilai: `licenseCode = 'TRIAL-$userId'`, `status = 'active'`, `tierLevel = 'trial'`, `maxDevices = 1`, `maxOutlets = 1`, `activationDate = DateTime.now()`, `expiredAt = DateTime.now().add(const Duration(days: 7))`, `deviceFingerprint = null`
  - Kembalikan `(true, null)` jika berhasil, `(false, 'Gagal mengaktifkan trial. Coba lagi.')` jika ada exception SQLite
  - _Requirements: 4.1, 4.2, 4.8_

- [x] 7. Buat widget `StepIndicatorWidget` dan `PackageCardWidget`
  - Buat file `mobile/lib/features/auth/widgets/step_indicator_widget.dart`
  - `StepIndicatorWidget` menerima parameter `currentStep` (int, 0-indexed) dan `totalSteps` (int)
  - Tampilkan 3 langkah dengan visual berbeda: langkah selesai (filled circle + checkmark), langkah aktif (filled circle + nomor, warna primary), langkah belum dikunjungi (outlined circle + nomor, warna abu)
  - Hubungkan antar langkah dengan garis horizontal; garis ke langkah selesai berwarna primary, garis ke langkah belum dikunjungi berwarna abu
  - Buat file `mobile/lib/features/auth/widgets/package_card_widget.dart`
  - `PackageCardWidget` menerima parameter `package` (SubscriptionPackage), `isSelected` (bool), `onTap` (VoidCallback)
  - Tampilkan: nama paket, harga terformat (`package.formattedPrice`), durasi (jika `durationMonths == 0` tampilkan "Seumur Hidup", jika > 0 tampilkan "$durationMonths Bulan"), dan daftar fitur dengan ikon centang
  - Berikan visual feedback saat `isSelected = true`: border berwarna primary dengan lebar 2, background sedikit lebih terang
  - _Requirements: 1.1, 2.2, 2.4, 6.6_


- [x] 8. Buat `RegistrationScreen` — Step 1 (Data Akun & Toko)
  - Buat file baru `mobile/lib/features/auth/screens/registration_screen.dart`
  - Buat `RegistrationScreen` sebagai `ConsumerStatefulWidget` yang menggunakan `IndexedStack` untuk mengelola 3 step (bukan `Navigator.push`)
  - Gunakan `PopScope` untuk intercept back button: Step 1 → navigasi ke `LoginScreen`, Step 2 → kembali ke Step 1, Step 3 → kembali ke Step 2 + cancel Realtime
  - Tampilkan `StepIndicatorWidget` di bagian atas dengan `currentStep` dari `registrationProvider`
  - Implementasikan form Step 1 dengan field dalam urutan: Nama Toko → Kategori Usaha → Nomor WhatsApp → (Divider) → Email → Password
  - Gunakan `TextEditingController` terpisah untuk setiap field; pertahankan controller di `State` agar data tidak hilang saat navigasi antar step
  - Validasi inline (di bawah field, bukan dialog): Nama Toko wajib + maks 50 karakter, WhatsApp wajib + 9-15 karakter, Email wajib + mengandung '@', Password wajib + min 6 karakter; Kategori Usaha opsional (default `'lainnya'`)
  - Saat submit: set loading, nonaktifkan semua input dan tombol, panggil `registrationNotifier.submitStep1()`
  - Tangani error: "User already registered" → tampilkan "Email sudah terdaftar. Silakan login.", error lain → tampilkan pesan dari `_parseAuthError()` yang sudah ada di `AuthNotifier`
  - Tangani timeout 30 detik: tampilkan "Koneksi timeout. Coba lagi." dan aktifkan kembali semua input
  - Tangani no internet: tampilkan "Tidak ada koneksi internet. Periksa jaringan Anda."
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 1.10, 1.11, 1.12, 1.13, 1.14, 1.15, 1.16, 6.1, 6.3, 6.7, 10.1_


- [x] 9. Implementasikan Step 2 di `RegistrationScreen` (Pilih Paket + Trial)
  - Tambahkan konten Step 2 ke `IndexedStack` di `RegistrationScreen`
  - Saat Step 2 pertama kali ditampilkan (currentStep berubah ke 1), panggil `registrationNotifier.fetchPackages()`
  - Tampilkan loading indicator selama fetch berlangsung; setelah selesai tampilkan list `PackageCardWidget`
  - Default selection: pilih paket dengan slug `'pro'` jika ada, jika tidak pilih paket pertama
  - Saat pengguna mengetuk `PackageCardWidget`, panggil `registrationNotifier.selectPackage(slug)`
  - Tombol "Lanjut ke Pembayaran": nonaktifkan saat loading, panggil `registrationNotifier.initiateCheckout(selectedSlug)` saat ditekan
  - Tangani error Checkout_API: HTTP 400 "User already has an active subscription license" → tampilkan "Akun ini sudah memiliki lisensi aktif." + tombol masuk; HTTP 404 → "Paket tidak tersedia saat ini. Coba lagi nanti."; HTTP 5xx → "Terjadi kesalahan server. Coba lagi dalam beberapa saat."; error JSON tidak valid → "Terjadi kesalahan. Coba lagi."
  - Cek apakah trial sudah pernah digunakan: query `db.getLocalLicense()` dan cek `licenseCode.startsWith('TRIAL-')` — jika sudah ada, sembunyikan tombol "Coba Trial 7 Hari"
  - Tombol "Coba Trial 7 Hari": panggil `registrationNotifier.createTrialLicense()`, jika berhasil navigasi ke AppBootstrap flow; jika gagal tampilkan "Gagal mengaktifkan trial. Coba lagi."
  - Tombol "Kembali": navigasi ke Step 1 tanpa menghapus data form
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 2.10, 2.11, 4.4, 4.8, 6.2, 6.7, 10.2, 10.3, 10.4_


- [x] 10. Implementasikan Step 3 di `RegistrationScreen` (Countdown + Realtime)
  - Tambahkan konten Step 3 ke `IndexedStack` di `RegistrationScreen`
  - Tampilkan: nomor invoice, nama paket yang dipilih, total tagihan (format Rupiah `id_ID`), dan countdown timer
  - Saat Step 3 pertama kali ditampilkan, cek apakah `expiredAt` sudah terlewati — jika ya, langsung tampilkan state kedaluwarsa tanpa menjalankan countdown
  - Implementasikan countdown timer menggunakan `Timer.periodic(Duration(seconds: 1), ...)` yang memperbarui tampilan setiap detik; hitung selisih `expiredAt.difference(DateTime.now())`
  - Saat countdown mencapai nol: tampilkan "Sesi pembayaran telah kedaluwarsa", ganti tombol "Buka Halaman Pembayaran" dengan tombol "Buat Tagihan Baru"
  - Tombol "Buka Halaman Pembayaran": buka `paymentUrl` di browser eksternal menggunakan `url_launcher` (`launchUrl(Uri.parse(paymentUrl), mode: LaunchMode.externalApplication)`)
  - Tombol "Buat Tagihan Baru": panggil `registrationNotifier.renewCheckout()`, update invoice dan timer; jika gagal tampilkan pesan error dan tetap tampilkan tombol "Buat Tagihan Baru"
  - Saat Step 3 ditampilkan, panggil `registrationNotifier.startRealtimeSubscription(userId)` untuk subscribe ke channel `licenses` dengan filter `user_id=eq.{userId}`
  - Jika subscribe gagal dalam 10 detik, tampilkan tombol "Cek Status Pembayaran" yang memanggil Status_API secara manual
  - Saat Realtime mengirim event dengan `is_active = true`: panggil `ref.invalidate(licenseProvider)`, tunggu `licenseProvider` selesai (timeout 30 detik), lalu navigasi ke AppBootstrap flow
  - Jika `licenseProvider` timeout 30 detik: tampilkan pesan error + tombol retry
  - Jika Realtime terputus: tampilkan "Koneksi terputus, mencoba menghubungkan kembali..." dan auto-reconnect
  - Setelah 5 menit tanpa konfirmasi: tampilkan saran "Hubungi admin via WhatsApp" di bawah elemen yang ada
  - Tombol "Hubungi Admin via WhatsApp": buka URL WhatsApp dengan pesan pre-filled berisi nomor invoice dan email pengguna
  - Tombol "Kembali": navigasi ke Step 2 + panggil `registrationNotifier.cancelRealtimeSubscription()`
  - Saat widget di-dispose (navigasi keluar): pastikan `cancelRealtimeSubscription()` dipanggil untuk mencegah memory leak
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10, 3.11, 6.5, 10.5, 10.6_


- [x] 11. Update `AppBootstrap` dan routing untuk mendukung tier `'trial'`
  - Edit `mobile/lib/main.dart`
  - Di `ref.listen(licenseProvider, ...)`: tambahkan kondisi untuk tier `'trial'` — jangan panggil `syncServiceProvider.start()` maupun `realtimeServiceProvider.start()` untuk trial
  - Di blok `data: (license)`: tambahkan pengecekan `expiredAt` untuk tier `'trial'` — jika `license.tierLevel == 'trial'` dan `license.expiredAt != null` dan `license.expiredAt!.isBefore(DateTime.now())`, navigasi ke `UnlicensedScreen` dengan parameter yang menunjukkan trial telah berakhir
  - Jika `license.tierLevel == 'trial'` dan belum expired, lanjutkan ke `EmployeeSelectionScreen` seperti tier lainnya
  - Pastikan `appTierProvider` di `license_tier_provider.dart` sudah mengembalikan `'trial'` untuk license dengan `tierLevel = 'trial'` yang belum expired — verifikasi logika yang ada sudah cukup (tidak perlu modifikasi jika sudah benar)
  - Update route `/register` di `LumioApp` untuk mengarah ke `RegistrationScreen` (bukan `UnifiedRegistrationScreen`)
  - Tambahkan import `RegistrationScreen` dan hapus import `UnifiedRegistrationScreen` yang tidak lagi digunakan
  - _Requirements: 4.3, 4.5, 4.6, 4.7, 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 12. Checkpoint — Pastikan semua komponen terhubung
  - Pastikan semua tests pass, ask the user if questions arise.
  - Verifikasi bahwa `RegistrationScreen` dapat diakses dari `LoginScreen` via route `/register`
  - Verifikasi bahwa `UnifiedRegistrationScreen` masih ada (belum dihapus) untuk backward compatibility jika ada referensi lain
  - Verifikasi bahwa `AppBootstrap` menangani semua kombinasi tier: `null`, `'trial'` (valid), `'trial'` (expired), `'lite'`, `'pro'`


- [x] 13. Tulis property tests untuk Web API (TypeScript)
  - Install `fast-check` sebagai dev dependency di `lumiopos-web`: `bun add -d fast-check`
  - Buat file `lumiopos-web/tests/unit/auth-helper.property.test.ts`

  - [x]* 13.1 Property test untuk Property 13: Bearer token divalidasi sebelum cookie
    - `// Feature: mobile-registration-subscription, Property 13: Bearer token divalidasi sebelum cookie`
    - Gunakan `fc.string()` untuk generate token acak; mock `supabase.auth.getUser()` agar selalu dipanggil saat ada header Bearer
    - Verifikasi bahwa `resolveAuthenticatedUser` memanggil validasi Bearer (bukan cookie) untuk setiap request yang mengandung header `Authorization: Bearer <token>`
    - Verifikasi bahwa cookie path hanya ditempuh jika tidak ada header Bearer
    - _Requirements: 9.2, 9.3_

  - [x]* 13.2 Property test untuk Property 14: Konsistensi hasil auth helper
    - `// Feature: mobile-registration-subscription, Property 14: Konsistensi hasil auth helper`
    - Generate request yang sama dan verifikasi bahwa hasil `resolveAuthenticatedUser` identik (deterministik) untuk input yang sama
    - _Requirements: 9.1_

  - [x]* 13.3 Property test untuk Property 15: HTTP 401 untuk semua request tanpa auth valid
    - `// Feature: mobile-registration-subscription, Property 15: HTTP 401 untuk semua request tanpa auth valid`
    - Gunakan `fc.record({ hasBearer: fc.boolean(), hasValidCookie: fc.constant(false) })` untuk generate request tanpa auth valid
    - Mock `resolveAuthenticatedUser` agar mengembalikan `{ success: false, reason: 'unauthorized' }`
    - Verifikasi bahwa Checkout_API dan Status_API mengembalikan HTTP 401 dengan body `{ error: '...' }`
    - _Requirements: 5.3, 5.6_

  - [x]* 13.4 Property test untuk Property 16: HTTP 403 jika userId body tidak cocok dengan Bearer token
    - `// Feature: mobile-registration-subscription, Property 16: HTTP 403 jika userId body tidak cocok`
    - Gunakan `fc.tuple(fc.uuid(), fc.uuid()).filter(([a, b]) => a !== b)` untuk generate pasangan userId yang berbeda
    - Mock `resolveAuthenticatedUser` agar mengembalikan user dengan `id = tokenUserId`; kirim request dengan `userId = bodyUserId` yang berbeda
    - Verifikasi response HTTP 403 dengan body `{ error: '...' }`
    - _Requirements: 5.8_


- [x] 14. Tulis property tests untuk validasi form Flutter (Dart)
  - Buat file `mobile/test/unit/property_registration_validation_test.dart`
  - Gunakan pola yang sama dengan `property_filter_test.dart`: `Random` dengan fixed seed, loop 100 iterasi, generator manual

  - [x]* 14.1 Property test untuk Property 1: Validasi panjang Nama Toko
    - `// Feature: mobile-registration-subscription, Property 1: Validasi panjang field menolak input di luar batas`
    - Generator: string dengan panjang acak 0–100 karakter
    - Verifikasi: panjang 0 → error "Nama toko wajib diisi"; panjang > 50 → error "Nama toko maksimal 50 karakter"; panjang 1–50 → null (valid)
    - _Requirements: 1.3_

  - [x]* 14.2 Property test untuk Property 2: Validasi panjang Nomor WhatsApp
    - `// Feature: mobile-registration-subscription, Property 2: Validasi panjang Nomor WhatsApp`
    - Generator: string dengan panjang acak 0–20 karakter
    - Verifikasi: panjang 0 → error "Nomor WA wajib diisi"; panjang 1–8 atau > 15 → error "Nomor WA tidak valid"; panjang 9–15 → null (valid)
    - _Requirements: 1.5, 1.6_

  - [x]* 14.3 Property test untuk Property 3: Validasi format email
    - `// Feature: mobile-registration-subscription, Property 3: Validasi format email`
    - Generator: string acak dengan/tanpa karakter '@'
    - Verifikasi: string kosong → error "Email wajib diisi"; string tanpa '@' → error "Email tidak valid"; string dengan '@' → null (valid)
    - _Requirements: 1.7, 1.8_

  - [x]* 14.4 Property test untuk Property 4: Validasi panjang password
    - `// Feature: mobile-registration-subscription, Property 4: Validasi panjang password`
    - Generator: string dengan panjang acak 0–10 karakter
    - Verifikasi: panjang 0 → error wajib diisi; panjang 1–5 → error "Password min. 6 karakter"; panjang ≥ 6 → null (valid)
    - _Requirements: 1.9_

  - [x]* 14.5 Property test untuk Property 6: Format harga paket locale id_ID
    - `// Feature: mobile-registration-subscription, Property 6: Format harga paket selalu menggunakan locale id_ID`
    - Generator: integer acak 1.000–10.000.000 (harga Rupiah)
    - Verifikasi: `SubscriptionPackage(price: n, ...).formattedPrice` mengandung pemisah ribuan titik (`.`) sesuai locale `id_ID`; contoh: 249000 → mengandung "249.000"
    - _Requirements: 2.2_


- [x] 15. Tulis property tests untuk logika bisnis Flutter (Dart)
  - Buat file `mobile/test/unit/property_registration_logic_test.dart`

  - [x]* 15.1 Property test untuk Property 9: Trial License round-trip
    - `// Feature: mobile-registration-subscription, Property 9: Trial License round-trip — buat dan baca kembali`
    - Gunakan in-memory Drift database (`LumioDatabase.forTesting(NativeDatabase.memory())`)
    - Generator: string userId acak (UUID-like, 10–36 karakter)
    - Untuk setiap userId: panggil `createTrialLicense(userId)`, lalu `db.getLocalLicense()`
    - Verifikasi: `licenseCode == 'TRIAL-$userId'`, `tierLevel == 'trial'`, `status == 'active'`, `expiredAt` sekitar 7 hari dari sekarang (toleransi ±5 detik)
    - _Requirements: 4.1, 4.2_

  - [x]* 15.2 Property test untuk Property 10: `appTierProvider` mengembalikan 'trial' untuk license trial valid
    - `// Feature: mobile-registration-subscription, Property 10: appTierProvider mengembalikan 'trial' untuk license trial yang valid`
    - Generator: `expiredAt` acak — sebagian di masa depan (valid), sebagian di masa lalu (expired)
    - Verifikasi: license dengan `tierLevel = 'trial'` dan `expiredAt` di masa depan → `appTierProvider` mengembalikan `'trial'`; license dengan `expiredAt` di masa lalu → `appTierProvider` mengembalikan `null` atau bukan `'trial'`
    - _Requirements: 4.3, 4.7_

  - [x]* 15.3 Property test untuk Property 12: Tombol trial tidak muncul jika trial sudah ada
    - `// Feature: mobile-registration-subscription, Property 12: Tombol trial tidak muncul jika trial sudah ada`
    - Generator: state SQLite dengan/tanpa license yang `licenseCode.startsWith('TRIAL-')`
    - Verifikasi: jika ada license dengan prefix `'TRIAL-'`, fungsi `shouldShowTrialButton(license)` mengembalikan `false`; jika tidak ada, mengembalikan `true`
    - Implementasikan fungsi helper `shouldShowTrialButton(License? license)` yang dapat ditest secara terpisah
    - _Requirements: 4.8_

  - [x]* 15.4 Property test untuk Property 17: Data form Step 1 tidak hilang saat navigasi
    - `// Feature: mobile-registration-subscription, Property 17: Data form Step 1 tidak hilang saat navigasi antar step`
    - Generator: kombinasi acak nilai form (storeName 1–50 char, phone 9–15 char, email dengan '@', password ≥ 6 char, businessType dari enum)
    - Verifikasi: setelah `RegistrationState` di-update dengan data Step 1, lalu `currentStep` diubah ke 1 dan kembali ke 0, semua nilai form tetap sama
    - _Requirements: 6.1_

  - [x]* 15.5 Property test untuk Property 18: Tombol aksi disabled saat loading
    - `// Feature: mobile-registration-subscription, Property 18: Tombol aksi disabled saat loading`
    - Generator: berbagai kombinasi `isLoading` (true/false) dan `currentStep` (0, 1, 2)
    - Verifikasi: saat `isLoading = true`, fungsi `areActionsEnabled(state)` mengembalikan `false` untuk semua step
    - Implementasikan fungsi helper `areActionsEnabled(RegistrationState state)` yang dapat ditest secara terpisah
    - _Requirements: 6.7_


- [x] 16. Tulis property tests untuk Checkout flow Flutter (Dart)
  - Buat file `mobile/test/unit/property_checkout_flow_test.dart`
  - Gunakan `mocktail` untuk mock Dio HTTP client

  - [x]* 16.1 Property test untuk Property 5: signUp gagal memblokir navigasi ke Step 2
    - `// Feature: mobile-registration-subscription, Property 5: signUp gagal memblokir navigasi ke Step 2`
    - Generator: berbagai jenis `AuthException` message (string acak)
    - Mock `supabase.auth.signUp()` agar selalu throw `AuthException`
    - Verifikasi: setelah `submitStep1()` gagal, `state.currentStep` tetap `0` dan `state.errorMessage` tidak null
    - _Requirements: 1.13_

  - [x]* 16.2 Property test untuk Property 7: Checkout sukses menyimpan semua field
    - `// Feature: mobile-registration-subscription, Property 7: Checkout sukses menyimpan semua field yang diperlukan`
    - Generator: kombinasi acak `invoiceNumber` (string), `paymentUrl` (URL-like string), `expiredAt` (DateTime di masa depan)
    - Mock Dio agar mengembalikan response sukses dengan ketiga field tersebut
    - Verifikasi: setelah `initiateCheckout()` sukses, `state.invoiceNumber`, `state.paymentUrl`, dan `state.expiredAt` semuanya tidak null, dan `state.currentStep == 2`
    - _Requirements: 2.7_

  - [x]* 16.3 Property test untuk Property 8: Error Checkout_API mencegah navigasi ke Step 3
    - `// Feature: mobile-registration-subscription, Property 8: Error Checkout_API mencegah navigasi ke Step 3`
    - Generator: HTTP status code acak dari set {400, 401, 403, 404, 500, 502, 503}
    - Mock Dio agar mengembalikan `DioException` dengan status code tersebut
    - Verifikasi: setelah `initiateCheckout()` gagal, `state.currentStep` tetap `1` dan `state.errorMessage` tidak null
    - _Requirements: 2.8_

- [x] 17. Final checkpoint — Pastikan semua tests pass
  - Pastikan semua tests pass, ask the user if questions arise.
  - Jalankan `cd mobile && flutter test` — semua test harus hijau
  - Jalankan `cd lumiopos-web && bun run test` — semua test harus hijau
  - Verifikasi tidak ada import yang rusak setelah penambahan file baru
  - Verifikasi `RegistrationScreen` dapat di-navigate dari `LoginScreen`


## Notes

- Tasks bertanda `*` adalah opsional dan dapat dilewati untuk MVP yang lebih cepat
- Setiap task mereferensikan requirements spesifik untuk traceability
- Urutan implementasi mengikuti dependensi: Web API helper → endpoint modifikasi → Flutter data model → state management → UI → AppBootstrap → tests
- **Tidak ada migrasi schema SQLite yang diperlukan** — kolom `tierLevel` dan `expiredAt` sudah ada di tabel `licenses` sejak schema version 25
- `fast-check` perlu di-install di `lumiopos-web` sebelum mengerjakan task 13
- Property tests Flutter menggunakan pola `Random` dengan fixed seed (seperti `property_filter_test.dart` yang sudah ada) — tidak memerlukan library tambahan
- `IndexedStack` dipilih untuk navigasi antar step agar data form Step 1 tetap terjaga di memori
- Validasi userId mismatch di Checkout_API hanya berlaku untuk Bearer token, tidak untuk cookie session (backward compatibility)
- Trial license menggunakan format `licenseCode = 'TRIAL-{userId}'` untuk memudahkan deteksi dan memastikan uniqueness per user per device

## Task Dependency Graph

```json
{
  "waves": [
    { "wave": 1, "tasks": ["1"] },
    { "wave": 2, "tasks": ["2", "3", "4"] },
    { "wave": 3, "tasks": ["5", "6", "7"] },
    { "wave": 4, "tasks": ["8"] },
    { "wave": 5, "tasks": ["9"] },
    { "wave": 6, "tasks": ["10"] },
    { "wave": 7, "tasks": ["11"] },
    { "wave": 8, "tasks": ["12"] },
    { "wave": 9, "tasks": ["13", "14", "15", "16"] },
    { "wave": 10, "tasks": ["17"] }
  ]
}
```
