# Requirements Document

## Introduction

Fitur ini mengubah flow registrasi mobile Lumio POS dari satu langkah tunggal menjadi tiga langkah terstruktur yang selaras dengan flow web yang sudah berjalan. Pengguna baru akan melewati: (1) pengisian data akun & toko, (2) pemilihan paket berlangganan, dan (3) penyelesaian pembayaran atau aktivasi trial. Selain itu, fitur ini mencakup modifikasi Web API (`/api/subscription/checkout` dan `/api/subscription/status`) agar mendukung autentikasi Bearer token dari mobile, serta penambahan mekanisme trial license lokal 7 hari di SQLite.

Konteks sistem:
- **Mobile**: Flutter + Riverpod + Drift ORM (SQLite), app name "Lumio"
- **Web API**: Next.js (lumiopos-web) — endpoint checkout & status yang sudah ada
- **Backend**: Go Fiber — license server
- **Cloud**: Supabase (PostgreSQL + Realtime)

---

## Glossary

- **Registration_Screen**: Widget Flutter multi-step yang menggantikan `UnifiedRegistrationScreen` saat ini
- **Step_Indicator**: Komponen visual yang menampilkan progres 3 langkah registrasi
- **Package_Card**: Widget kartu yang menampilkan detail satu paket berlangganan
- **Checkout_API**: Endpoint Next.js `/api/subscription/checkout` yang dimodifikasi
- **Status_API**: Endpoint Next.js `/api/subscription/status` yang dimodifikasi
- **License_Notifier**: `LicenseNotifier` di `auth_providers.dart` — mengelola state lisensi lokal
- **Trial_License**: Lisensi lokal tier `'trial'` dengan durasi 7 hari, disimpan di SQLite
- **Supabase_Realtime**: Mekanisme subscription PostgreSQL changes via Supabase channel
- **Bearer_Token**: JWT access token Supabase yang dikirim di header `Authorization: Bearer <token>`
- **Payment_URL**: URL eksternal ke halaman pembayaran Pakasir yang dibuka di browser sistem
- **Store_Profile**: Tabel Supabase `store_profile` — menyimpan data toko pengguna
- **Subscription_Packages**: Tabel Supabase `subscription_packages` — daftar paket berlangganan aktif
- **Licenses**: Tabel Supabase `licenses` — status lisensi aktif per user
- **Subscription_Transactions**: Tabel Supabase `subscription_transactions` — rekaman transaksi pembayaran
- **AppBootstrap**: Widget entry point di `main.dart` yang menentukan routing awal aplikasi
- **appTierProvider**: Riverpod provider yang membaca `tierLevel` dari lisensi lokal SQLite
- **licenseProvider**: `AsyncNotifierProvider<LicenseNotifier, License?>` — sumber kebenaran lisensi lokal

---

## Requirements

### Requirement 1: Step 1 — Pengisian Data Akun & Toko

**User Story:** Sebagai pengguna baru, saya ingin mengisi data toko dan akun dalam satu langkah terstruktur, sehingga saya dapat mendaftar dengan mudah dan melanjutkan ke pemilihan paket.

#### Acceptance Criteria

1. WHEN pengguna membuka halaman registrasi, THE Registration_Screen SHALL menampilkan Step_Indicator dengan 3 langkah dan form Step 1 yang aktif.
2. THE Registration_Screen SHALL menampilkan field input dalam urutan berikut: Nama Toko → Kategori Usaha → Nomor WhatsApp → (pemisah visual) → Email → Password.
3. WHEN pengguna mengosongkan field Nama Toko dan menekan tombol submit, THE Registration_Screen SHALL menampilkan pesan validasi "Nama toko wajib diisi" dan mencegah pengiriman form. IF Nama Toko diisi lebih dari 50 karakter, THE Registration_Screen SHALL menampilkan pesan validasi "Nama toko maksimal 50 karakter" dan mencegah pengiriman form.
4. Kategori Usaha adalah field opsional; THE Registration_Screen SHALL tidak menampilkan pesan validasi jika Kategori Usaha tidak dipilih, dan SHALL menggunakan nilai default `'lainnya'` saat submit.
5. WHEN pengguna mengosongkan field Nomor WhatsApp dan menekan tombol submit, THE Registration_Screen SHALL menampilkan pesan validasi "Nomor WA wajib diisi" dan mencegah pengiriman form.
6. WHEN pengguna memasukkan nomor WhatsApp dengan kurang dari 9 karakter atau lebih dari 15 karakter dan menekan tombol submit, THE Registration_Screen SHALL menampilkan pesan validasi "Nomor WA tidak valid" dan mencegah pengiriman form.
7. WHEN pengguna mengosongkan field Email dan menekan tombol submit, THE Registration_Screen SHALL menampilkan pesan validasi "Email wajib diisi" dan mencegah pengiriman form.
8. WHEN pengguna memasukkan email tanpa karakter '@' dan menekan tombol submit, THE Registration_Screen SHALL menampilkan pesan validasi "Email tidak valid" dan mencegah pengiriman form.
9. WHEN pengguna memasukkan password kurang dari 6 karakter dan menekan tombol submit, THE Registration_Screen SHALL menampilkan pesan validasi "Password min. 6 karakter" dan mencegah pengiriman form.
10. WHEN semua field valid dan pengguna menekan tombol submit, THE Registration_Screen SHALL menampilkan indikator loading dan menonaktifkan semua input selama proses berlangsung. IF proses tidak selesai dalam 30 detik, THE Registration_Screen SHALL menghentikan loading, menampilkan pesan "Koneksi timeout. Coba lagi.", dan mengaktifkan kembali semua input.
11. WHEN proses submit berhasil, THE Registration_Screen SHALL memanggil `supabase.auth.signUp()` dengan email, password, dan metadata `{store_name, phone, business_type}`, kemudian melakukan insert ke tabel `store_profile` di Supabase dengan field `{name, phone, business_type, user_id}`.
12. WHEN insert `store_profile` gagal setelah `signUp` berhasil, THE Registration_Screen SHALL tetap melanjutkan navigasi ke Step 2 tanpa menampilkan error ke pengguna.
13. IF `signUp` gagal, THE Registration_Screen SHALL mencegah navigasi ke Step 2 terlepas dari status insert `store_profile`.
14. WHEN `signUp` berhasil, THE Registration_Screen SHALL menyimpan `userId` dan `accessToken` Supabase di state lokal, lalu menavigasi ke Step 2.
15. IF `signUp` mengembalikan error "User already registered", THEN THE Registration_Screen SHALL menampilkan pesan dalam Bahasa Indonesia "Email sudah terdaftar. Silakan login." dan tidak menavigasi ke Step 2.
16. IF `signUp` mengembalikan error selain "User already registered", THEN THE Registration_Screen SHALL menampilkan pesan error dalam Bahasa Indonesia yang sesuai dengan jenis error yang diterima.

---

### Requirement 2: Step 2 — Pemilihan Paket Berlangganan

**User Story:** Sebagai pengguna baru yang telah mengisi data akun, saya ingin melihat dan memilih paket berlangganan yang tersedia, sehingga saya dapat memutuskan paket yang sesuai atau mencoba trial terlebih dahulu.

#### Acceptance Criteria

1. WHEN Registration_Screen memasuki Step 2, THE Registration_Screen SHALL mengambil daftar paket dari tabel `subscription_packages` Supabase dengan filter `is_active = true` dan menampilkan loading indicator selama fetch berlangsung. IF fetch tidak selesai dalam 10 detik, THE Registration_Screen SHALL menghentikan loading dan menampilkan daftar paket fallback hardcoded.
2. WHEN data paket berhasil diambil, THE Registration_Screen SHALL menampilkan setiap paket sebagai Package_Card yang memuat: nama paket, harga (format Rupiah `id_ID`), durasi, dan daftar fitur.
3. IF paket dengan slug `'pro'` tersedia dalam daftar, THEN THE Registration_Screen SHALL menampilkan paket tersebut sebagai pilihan yang terpilih secara default saat Step 2 pertama kali ditampilkan. IF slug `'pro'` tidak ditemukan, THE Registration_Screen SHALL memilih paket pertama dalam daftar sebagai default.
4. WHEN pengguna mengetuk Package_Card yang belum terpilih, THE Registration_Screen SHALL memperbarui state pilihan paket dan memberikan visual feedback (border/highlight) pada kartu yang dipilih, serta menghapus visual feedback dari kartu yang sebelumnya dipilih.
5. IF fetch `subscription_packages` gagal atau timeout, THEN THE Registration_Screen SHALL menampilkan daftar paket fallback hardcoded (Lite: Rp 99.000, Pro: Rp 249.000) agar flow tidak terhenti.
6. WHEN pengguna menekan tombol "Lanjut ke Pembayaran", THE Registration_Screen SHALL menonaktifkan tombol tersebut untuk mencegah double-submit, lalu memanggil Checkout_API dengan header `Authorization: Bearer <accessToken>`, body `{userId, packageSlug}` dari paket yang dipilih.
7. WHEN Checkout_API mengembalikan respons sukses, THE Registration_Screen SHALL menyimpan `invoiceNumber`, `paymentUrl`, dan `expiredAt` di state lokal, lalu menavigasi ke Step 3.
8. IF Checkout_API mengembalikan error dengan body JSON, THEN THE Registration_Screen SHALL menampilkan pesan error dari field `error` dalam respons dan tetap berada di Step 2. IF Checkout_API mengembalikan error tanpa body JSON yang valid, THE Registration_Screen SHALL menampilkan pesan "Terjadi kesalahan. Coba lagi." dan tetap berada di Step 2.
9. WHEN pengguna menekan tombol "Coba Trial 7 Hari", THE Registration_Screen SHALL mencoba membuat Trial_License di SQLite lokal. WHEN Trial_License berhasil dibuat, THE Registration_Screen SHALL memanggil `ref.invalidate(licenseProvider)` dan menavigasi ke AppBootstrap flow tanpa melewati Step 3.
10. IF pembuatan Trial_License gagal (error SQLite), THEN THE Registration_Screen SHALL menampilkan pesan "Gagal mengaktifkan trial. Coba lagi." dan tetap berada di Step 2.
11. WHILE Step 2 ditampilkan, THE Registration_Screen SHALL menampilkan tombol "Kembali" yang menavigasi pengguna ke Step 1 tanpa menghapus data yang sudah diisi di Step 1.

---

### Requirement 3: Step 3 — Menunggu Konfirmasi Pembayaran

**User Story:** Sebagai pengguna yang telah memilih paket berbayar, saya ingin melihat detail tagihan dan menyelesaikan pembayaran di browser, sehingga lisensi saya dapat diaktifkan secara otomatis setelah pembayaran berhasil.

#### Acceptance Criteria

1. WHEN Registration_Screen memasuki Step 3, THE Registration_Screen SHALL menampilkan: nomor invoice, nama paket yang dipilih, total tagihan (format Rupiah `id_ID`), dan countdown timer. IF `expiredAt` dari Checkout_API sudah terlewati saat Step 3 dibuka, THE Registration_Screen SHALL langsung menampilkan state kedaluwarsa tanpa menjalankan countdown.
2. WHEN pengguna menekan tombol "Buka Halaman Pembayaran", THE Registration_Screen SHALL membuka `paymentUrl` di browser eksternal sistem (bukan WebView embedded) menggunakan `url_launcher`.
3. WHILE selisih antara `expiredAt` dan waktu saat ini lebih dari 0 detik, THE Registration_Screen SHALL menjalankan countdown timer yang memperbarui tampilan setiap detik.
4. WHEN countdown timer mencapai nol, THE Registration_Screen SHALL menampilkan pesan "Sesi pembayaran telah kedaluwarsa" dan mengganti tombol "Buka Halaman Pembayaran" dengan tombol "Buat Tagihan Baru". Perubahan UI ini hanya dipicu oleh countdown timer yang mencapai nol di sisi klien.
5. WHEN pengguna menekan tombol "Buat Tagihan Baru" setelah sesi kedaluwarsa, THE Registration_Screen SHALL memanggil ulang Checkout_API dan memperbarui data invoice serta timer. IF Checkout_API gagal saat "Buat Tagihan Baru", THE Registration_Screen SHALL menampilkan pesan error dan tetap menampilkan tombol "Buat Tagihan Baru".
6. WHILE Step 3 ditampilkan, THE Registration_Screen SHALL berlangganan ke Supabase_Realtime channel pada tabel `licenses` dengan filter `user_id=eq.{userId}`. IF subscribe gagal dalam 10 detik, THE Registration_Screen SHALL menampilkan tombol "Cek Status Pembayaran" yang memanggil Status_API secara manual.
7. WHEN Supabase_Realtime mengirimkan event dengan `is_active = true` pada tabel `licenses`, THE Registration_Screen SHALL memanggil `ref.invalidate(licenseProvider)` dan menunggu `licenseProvider` selesai memuat ulang data lisensi dari Supabase sebelum menavigasi ke AppBootstrap flow. IF `licenseProvider` tidak selesai dalam 30 detik, THE Registration_Screen SHALL menampilkan pesan error dan menawarkan tombol untuk mencoba ulang.
8. WHEN Registration_Screen meninggalkan Step 3 (baik karena sukses maupun navigasi kembali), THE Registration_Screen SHALL membatalkan subscription Supabase_Realtime channel untuk mencegah memory leak.
9. WHILE Step 3 ditampilkan, THE Registration_Screen SHALL menampilkan tombol "Hubungi Admin via WhatsApp" yang membuka URL WhatsApp dengan pesan pre-filled berisi nomor invoice dan email pengguna.
10. WHEN pengguna menekan tombol "Kembali" di Step 3, THE Registration_Screen SHALL menavigasi kembali ke Step 2 dan membatalkan subscription Supabase_Realtime yang aktif.
11. WHEN pengguna telah berada di Step 3 selama lebih dari 5 menit tanpa konfirmasi pembayaran, THE Registration_Screen SHALL menampilkan saran untuk menghubungi admin via WhatsApp di bawah tombol yang sudah ada.

---

### Requirement 4: Trial License

**User Story:** Sebagai pengguna baru yang belum siap berlangganan, saya ingin mencoba aplikasi selama 7 hari secara gratis, sehingga saya dapat mengevaluasi fitur sebelum memutuskan untuk berlangganan.

#### Acceptance Criteria

1. WHEN pengguna memilih "Coba Trial 7 Hari" di Step 2, THE Registration_Screen SHALL membuat satu baris baru di tabel `licenses` SQLite lokal dengan nilai: `licenseCode = 'TRIAL-{userId}'`, `tierLevel = 'trial'`, `status = 'active'`, `expiredAt = DateTime.now().add(Duration(days: 7))`, `maxDevices = 1`, `maxOutlets = 1`.
2. WHEN Trial_License berhasil disimpan ke SQLite, THE Registration_Screen SHALL memanggil `ref.invalidate(licenseProvider)` agar `appTierProvider` membaca tier `'trial'` dari lisensi baru.
3. THE appTierProvider SHALL mengembalikan nilai `'trial'` ketika lisensi lokal memiliki `tierLevel = 'trial'` dan `expiredAt` belum terlewati.
4. WHILE pengguna menggunakan Trial_License, THE Registration_Screen SHALL tidak melakukan panggilan ke Checkout_API maupun membuka browser eksternal.
5. WHILE pengguna menggunakan Trial_License, THE AppBootstrap SHALL mengizinkan akses ke semua fitur POS offline (transaksi, produk, laporan lokal).
6. WHILE pengguna menggunakan Trial_License, THE AppBootstrap SHALL menonaktifkan fitur cloud sync ke Supabase dengan tidak memanggil `syncServiceProvider.start()` dan `realtimeServiceProvider.start()`.
7. WHEN `expiredAt` Trial_License telah terlewati dan pengguna membuka aplikasi, THE AppBootstrap SHALL mendeteksi lisensi kedaluwarsa dan menavigasi pengguna ke `UnlicensedScreen`, bukan ke `EmployeeSelectionScreen`.
8. IF Trial_License sudah ada di SQLite lokal (pengguna sudah pernah trial sebelumnya), THEN THE Registration_Screen SHALL tidak menampilkan tombol "Coba Trial 7 Hari" di Step 2.

---

### Requirement 5: Modifikasi Web API — Dukungan Bearer Token

**User Story:** Sebagai sistem mobile, saya ingin memanggil endpoint checkout dan status menggunakan Bearer token Supabase, sehingga mobile tidak perlu mengelola session cookie yang tidak didukung oleh HTTP client Flutter.

#### Acceptance Criteria

1. WHEN Checkout_API menerima request dengan header `Authorization: Bearer <token>` yang valid (non-expired, merujuk ke user Supabase yang terdaftar), THE Checkout_API SHALL memvalidasi token dan mengidentifikasi pengguna menggunakan modul autentikasi bersama.
2. WHEN Checkout_API menerima request dengan cookie session yang valid tanpa header Bearer (flow web existing), THE Checkout_API SHALL memproses request menggunakan identitas dari cookie session tanpa perubahan perilaku.
3. IF Checkout_API menerima request tanpa cookie session maupun Bearer token yang valid, THEN THE Checkout_API SHALL mengembalikan respons HTTP 401 dengan body JSON yang mengandung field `error`. Respons ini berlaku untuk semua kondisi autentikasi yang tidak valid.
4. WHEN Status_API menerima request dengan header `Authorization: Bearer <token>` yang valid, THE Status_API SHALL memvalidasi token menggunakan modul autentikasi bersama yang sama dengan Checkout_API.
5. WHEN Status_API menerima request dengan cookie session yang valid tanpa header Bearer (flow web existing), THE Status_API SHALL memproses request menggunakan identitas dari cookie session tanpa perubahan perilaku.
6. IF Status_API menerima request tanpa cookie session maupun Bearer token yang valid, THEN THE Status_API SHALL mengembalikan respons HTTP 401 dengan format body JSON yang sama dengan Checkout_API.
7. WHEN Checkout_API berhasil memvalidasi Bearer token, THE Checkout_API SHALL menggunakan `user.id` dari token sebagai identitas pengguna yang berwenang.
8. IF `userId` di request body tidak cocok dengan `user.id` dari Bearer token yang tervalidasi, THEN THE Checkout_API SHALL mengembalikan respons HTTP 403 dengan body JSON yang mengandung field `error`. Validasi ini hanya berlaku untuk autentikasi Bearer token, tidak untuk cookie session.
9. IF Supabase tidak dapat dijangkau saat validasi Bearer token, THEN THE Checkout_API dan Status_API SHALL mengembalikan respons HTTP 503 dengan body JSON yang mengandung field `error`.

---

### Requirement 6: Navigasi & State Management Multi-Step

**User Story:** Sebagai pengguna, saya ingin dapat berpindah antar langkah registrasi dengan lancar dan data yang sudah diisi tidak hilang, sehingga pengalaman registrasi terasa mulus.

#### Acceptance Criteria

1. THE Registration_Screen SHALL mempertahankan data form Step 1 (nama toko, kategori, WA, email, password) di state widget selama sesi registrasi berlangsung, termasuk saat pengguna kembali dari Step 2 ke Step 1.
2. THE Registration_Screen SHALL mempertahankan pilihan paket di Step 2 saat pengguna kembali dari Step 3 ke Step 2.
3. WHEN pengguna berada di Step 1 dan menekan tombol back sistem Android, THE Registration_Screen SHALL menavigasi ke halaman login, bukan keluar dari aplikasi.
4. WHEN pengguna berada di Step 2 dan menekan tombol back sistem Android, THE Registration_Screen SHALL menavigasi ke Step 1.
5. WHEN pengguna berada di Step 3 dan menekan tombol back sistem Android, THE Registration_Screen SHALL menavigasi ke Step 2 dan membatalkan subscription Supabase_Realtime yang aktif.
6. THE Step_Indicator SHALL memperbarui tampilan visual secara real-time sesuai langkah aktif saat ini; langkah yang sudah selesai, langkah aktif, dan langkah yang belum dikunjungi SHALL dibedakan secara visual.
7. WHILE proses loading berlangsung (submit Step 1, fetch paket, panggil Checkout_API), THE Registration_Screen SHALL menonaktifkan semua tombol aksi untuk mencegah double-submit.

---

### Requirement 7: Integrasi dengan AppBootstrap

**User Story:** Sebagai sistem, saya ingin AppBootstrap mengenali tier `'trial'` dan mengarahkan pengguna ke layar yang tepat, sehingga pengguna trial mendapatkan akses yang sesuai dengan batasan tier mereka.

#### Acceptance Criteria

1. WHEN `licenseProvider` mengembalikan lisensi dengan `tierLevel = 'trial'` dan `expiredAt` belum terlewati, THE AppBootstrap SHALL menavigasi pengguna ke `EmployeeSelectionScreen` seperti tier lainnya.
2. WHEN `licenseProvider` mengembalikan lisensi dengan `tierLevel = 'trial'` dan `expiredAt` sudah terlewati, THE AppBootstrap SHALL menavigasi pengguna ke `UnlicensedScreen` dengan parameter yang menunjukkan trial telah berakhir.
3. WHEN `licenseProvider` mengembalikan lisensi dengan `tierLevel = 'trial'`, THE AppBootstrap SHALL tidak memanggil `syncServiceProvider.start()` maupun `realtimeServiceProvider.start()`.
4. WHEN `licenseProvider` mengembalikan lisensi dengan `tierLevel = 'pro'` (terlepas dari tier sebelumnya), THE AppBootstrap SHALL memanggil `syncServiceProvider.start()` dan `realtimeServiceProvider.start()` untuk mengaktifkan cloud sync.
5. WHEN `licenseProvider` mengembalikan `null` dan Supabase session aktif, THE AppBootstrap SHALL menavigasi ke `UnlicensedScreen` yang menampilkan opsi untuk memulai registrasi ulang atau upgrade. Pengguna tidak diizinkan mengakses `EmployeeSelectionScreen` tanpa lisensi yang valid.

---

### Requirement 9: Shared Authentication Module (Web API)

**User Story:** Sebagai developer, saya ingin logika validasi autentikasi Bearer token dan cookie session diimplementasikan dalam satu modul bersama, sehingga Checkout_API dan Status_API tidak menduplikasi kode autentikasi.

#### Acceptance Criteria

1. THE Checkout_API dan Status_API SHALL menggunakan satu fungsi helper bersama untuk memvalidasi autentikasi, yang menerima objek `Request` dan mengembalikan identitas pengguna yang tervalidasi atau indikasi kegagalan.
2. WHEN fungsi helper autentikasi dipanggil dan request mengandung header `Authorization: Bearer <token>`, THE helper SHALL memvalidasi token tersebut terlebih dahulu tanpa memeriksa cookie session.
3. WHEN fungsi helper autentikasi dipanggil dan request tidak mengandung header `Authorization: Bearer`, THE helper SHALL memeriksa cookie session Supabase sebagai metode autentikasi.
4. WHEN fungsi helper autentikasi berhasil memvalidasi identitas pengguna (dari Bearer token maupun cookie), THE helper SHALL mengembalikan data pengguna yang valid kepada API handler.
5. IF fungsi helper autentikasi tidak menemukan metode autentikasi yang valid, THEN THE helper SHALL mengembalikan indikasi kegagalan yang dapat digunakan oleh API handler untuk mengembalikan HTTP 401.
6. IF Supabase tidak dapat dijangkau saat validasi Bearer token dan tidak ada respons dalam 5 detik, THEN THE helper SHALL mengembalikan indikasi kegagalan yang dapat dibedakan dari kegagalan autentikasi biasa, sehingga API handler dapat mengembalikan HTTP 503.
7. THE helper autentikasi SHALL memvalidasi Bearer token tanpa bergantung pada cookie session server-side, sehingga validasi dapat dilakukan untuk request yang tidak memiliki cookie.

---

### Requirement 10: Penanganan Error & Koneksi

**User Story:** Sebagai pengguna, saya ingin mendapatkan umpan balik yang jelas ketika terjadi kesalahan koneksi atau server, sehingga saya tahu apa yang harus dilakukan selanjutnya.

#### Acceptance Criteria

1. IF koneksi internet tidak tersedia saat pengguna menekan submit di Step 1, THEN THE Registration_Screen SHALL menampilkan pesan "Tidak ada koneksi internet. Periksa jaringan Anda." dan tetap berada di Step 1.
2. IF Checkout_API mengembalikan HTTP 400 dengan error "User already has an active subscription license", THEN THE Registration_Screen SHALL menampilkan pesan "Akun ini sudah memiliki lisensi aktif." dan menawarkan tombol untuk langsung masuk ke aplikasi.
3. IF Checkout_API mengembalikan HTTP 404 dengan error "Subscription package not found", THEN THE Registration_Screen SHALL menampilkan pesan "Paket tidak tersedia saat ini. Coba lagi nanti." dan tetap berada di Step 2.
4. IF Checkout_API mengembalikan HTTP 5xx, THEN THE Registration_Screen SHALL menampilkan pesan "Terjadi kesalahan server. Coba lagi dalam beberapa saat." dan tetap berada di Step 2.
5. IF Supabase_Realtime terputus saat menunggu di Step 3, THEN THE Registration_Screen SHALL menampilkan indikator "Koneksi terputus, mencoba menghubungkan kembali..." dan mencoba reconnect secara otomatis.
6. WHEN pengguna telah berada di Step 3 selama lebih dari 5 menit tanpa konfirmasi pembayaran, THE Registration_Screen SHALL menampilkan saran untuk menghubungi admin via WhatsApp di bawah elemen UI yang sudah ada.
