# Sinkronisasi Realtime & Berbasis Event

## Goal
Mengganti sistem polling 30 detik dengan sinkronisasi instan berbasis WebSocket dan deteksi koneksi otomatis.

## Tasks
- [ ] **Task 1: Tambah Dependensi**  
  Jalankan `flutter pub add connectivity_plus` → Verify: Cek `pubspec.yaml`
- [ ] **Task 2: Setup Notifier di Database**  
  Tambahkan `StreamController` di `LumioDatabase` untuk memancarkan event setiap kali `enqueueSync` dipanggil → Verify: Panggil `enqueueSync` dan tangkap event di test/log.
- [ ] **Task 3: Implementasi Realtime Pull**  
  Subscribe ke `supabase.channel('public:*')` di `SyncService` dan hubungkan ke `db.importCloudRows` → Verify: Update data di Supabase Dashboard, cek apakah data masuk ke SQLite lokal secara instan.
- [x] **Task 4: Setup Subscription di `SyncService`**  
  Hapus `Timer.periodic` dan ganti dengan listener pada `syncQueueNotifier` dari database → Verify: Simpan transaksi baru, cek apakah langsung terkirim ke Supabase tanpa delay.
- [x] **Task 5: Implementasi Network Recovery**  
  Listen ke `Connectivity().onConnectivityChanged` untuk memicu `processSyncQueue` saat status menjadi online → Verify: Matikan wifi, buat data, nyalakan wifi, data harus otomatis sinkron.
- [x] **Task 6: Optimasi `importCloudRows`**  
  Tambahkan pengecekan `sync_queue` di dalam `importCloudRows` untuk mencegah overwrite data lokal yang belum sinkron → Verify: Cloud update untuk ID yang ada di queue harus di-skip.

## Done When
- [x] Tidak ada lagi `Timer` yang berjalan di `SyncService`.
- [x] Data tersinkronisasi < 2 detik setelah perubahan (jika online).
- [x] Aplikasi otomatis sinkron saat kembali online setelah offline.

## Notes
Pastikan Supabase Replication sudah aktif di dashboard.
