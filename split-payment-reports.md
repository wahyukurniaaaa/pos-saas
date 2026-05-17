# Split Payment — Report & Transaction Fix

## Goal
Memperbaiki laporan shift, riwayat transaksi, dan detail transaksi agar akurat membaca data pembayaran dari tabel `transaction_payments` (bukan hanya kolom `payment_method` di tabel `transactions` yang sekarang bisa bernilai "mixed").

## Root Cause
Tabel `transaction_payments` menyimpan breakdown pembayaran per metode (tunai, qris, dll), tapi semua kalkulasi laporan masih membaca dari `transactions.payment_method` yang hanya berisi "mixed" untuk transaksi split. Ini menyebabkan:
- Kas yang diterima dari split payment tidak masuk kalkulasi laci kasir
- Laporan metode pembayaran menampilkan "mixed" alih-alih breakdown yang benar

---

## Tasks Status

- [x] **Task 1: Helper DB `getShiftPaymentTotals(shiftId)`**
  Di `database.dart` — query `transaction_payments` join `transactions` by `shiftId`, group by `method`, sum `amount`.
  → **Status:** Terverifikasi di `database.dart:1330`.

- [x] **Task 2: Rewrite `getPaymentMethodBreakdown`**
  Di `database.dart` — ganti query dari `transactions.payment_method` ke aggregate `transaction_payments`, filter by date range dan status `paid`.
  → **Status:** Terverifikasi di `database.dart:1297`.

- [x] **Task 3: Fix `ShiftReportModal` (kalkulasi laci kasir)**
  Di `shift_report_modal.dart` — ganti loop manual dengan panggil `getShiftPaymentTotals(shiftId)`.
  → **Status:** Terverifikasi di `shift_report_modal.dart:23-27` dan logic kalkulasi di line `110-116`.

- [x] **Task 4: Fix Summary Card di `CurrentShiftHistoryTab`**
  Di `current_shift_history_tab.dart` — muat `paymentTotals` dari accurate providers.
  → **Status:** Terverifikasi di `current_shift_history_tab.dart:335-345`.

- [x] **Task 5: Detail pembayaran di `ReceiptDetailScreen`**
  Di `receipt_detail_screen.dart` — muat `getTransactionPayments(transactionId)` dan tampilkan breakdown.
  → **Status:** Terverifikasi di `receipt_detail_screen.dart:191-212`.

- [x] **Task 6: Verifikasi Kode & Logic**
  Running `dart analyze` dan review manual keterkaitan antar logic.
  → **Status:** Logic konsisten di semua layer (DB -> Provider -> UI).

---

## Done When
- [x] Tidak ada nilai "mixed" di laporan metode pembayaran
- [x] "Estimasi Uang Dalam Laci" di shift report akurat untuk split payment
- [x] Detail transaksi split menampilkan breakdown per metode

## Files Terdampak
| File | Deskripsi Perubahan |
|------|-----------|
| `mobile/lib/core/database/database.dart` | Implementasi query aggregasi `transaction_payments` |
| `mobile/lib/features/pos/screens/shift/shift_report_modal.dart` | Migrasi ke `shiftPaymentTotalsProvider` |
| `mobile/lib/features/pos/screens/current_shift_history_tab.dart` | Migrasi ringkasan harian ke `historyPaymentTotalsProvider` |
| `mobile/lib/features/settings/screens/receipt_detail_screen.dart` | Display breakdown per baris pembayaran |
| `mobile/lib/core/services/receipt_service.dart` | (Internal) Mendukung print breakdown split payment |

## Notes
- `getTransactionPayments(transactionId)` sudah tersedia di core database.
- Tidak ada schema migration tambahan; tabel `transaction_payments` (v21) sudah menampung data dengan benar.
- Fitur Share WhatsApp juga sudah menggunakan data breakdown pembayaran yang akurat.

