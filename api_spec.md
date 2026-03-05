# 🔌 POSify - Go API Specification (License Server)

Dokumen ini mendefinisikan spesifikasi API untuk Backend Lisensi **POSify**, yang dibangun menggunakan **Go (Go Fiber)**. 
Karena POSify berfokus pada pendekatan *Offline-First* (Tier 1), interaksi aplikasi Mobile dengan API Backend ini **sangat minim**—hanya terjadi saat proses aktivasi awal atau pemulihan perangkat (*Restore*).

---

## 🏛️ Base URL
```text
Production : https://api.posify.example.com/v1
Staging    : https://staging-api.posify.example.com/v1
Local      : http://localhost:3000/api/v1
```

## 🔒 Otentikasi
API ini bersifat *Public* untuk *endpoint* aktivasi, namun diproteksi menggunakan **API Key** statis pada HTTP Header untuk mencegah serangan DDoS atau spamming dari luar aplikasi Mobile resmi.

**Global Header Requirements:**
- `X-App-Client-Key`: `string` (*Secret API Key tertanam di dalam APK Flutter*)
- `Content-Type`: `application/json`

---

## 📌 Endpoint: POST `/api/v1/license/activate`

**Deskripsi:**  
Memvalidasi Kode Lisensi yang di-input oleh Owner dari email, dan mendaftarkan identitas perangkat (*Device Fingerprint*) secara permanen. Jika *fingerprint* berbeda di transaksi selanjutnya, backend akan menolak.

### 📥 Request Body
```json
{
  "license_code": "POS-L1-A8F9K2-X1Y2Z3",
  "device_fingerprint": "75c61239-0d2a-4467-b5de-8bb6d1a51167",
  "device_model": "Samsung SM-T295",
  "os_version": "Android 11"
}
```

| Parameter | Type | Keterangan | Validasi |
| :--- | :--- | :--- | :--- |
| `license_code` | `string` | Kode rahasia yang dibeli Owner. | Wajib, Regex format khusus. |
| `device_fingerprint` | `string` | UUID unik dari device fisik (Target: Android/iOS). | Wajib, max 36 char. |
| `device_model` | `string` | Nama HP untuk keperluan log CS. | Opsional |
| `os_version` | `string` | Versi OS. | Opsional |

---

### 📤 Response - Success (200 OK)
Lisensi Ditemukan, Belum Dipakai, dan Berhasil Diikat ke Device.
```json
{
  "status": "success",
  "code": 200,
  "message": "Lisensi berhasil diaktifkan untuk perangkat ini.",
  "data": {
    "license_code": "POS-L1-A8F9K2-X1Y2Z3",
    "activation_date": "2026-03-05T08:30:15Z",
    "tier_level": "Tier 1 - Lifetime",
    "max_devices": 1
  }
}
```

---

### 📤 Response - Gagal / Error

**1. Lisensi Tidak Valid (404 Not Found)**
```json
{
  "status": "error",
  "code": 404,
  "message": "Kode lisensi tidak ditemukan atau format salah."
}
```

**2. Lisensi Sudah Dipakai di Device Lain (403 Forbidden)**
Jika `device_fingerprint` yang datang tidak cocok dengan yang sudah direkam sebelumnya.
```json
{
  "status": "error",
  "code": 403,
  "message": "Lisensi ini sudah diaktifkan di perangkat lain (Samsung SM-T295). Silakan hubungi CS untuk reset perangkat."
}
```

**3. API Key Client Salah (401 Unauthorized)**
```json
{
  "status": "error",
  "code": 401,
  "message": "Akses ditolak. Client Key tidak terdaftar."
}
```

---

## 📌 Endpoint: POST `/api/v1/license/verify`

**Deskripsi:**  
(Opsional) *Endpoint ping* yang dipanggil oleh Mobile App seminggu sekali (atau saat online) untuk memastikan Lisensi tersebut belum di-*banned*/*suspend* secara sepihak oleh sistem pusat (misal: akibat indikasi pembajakan/crack).

### 📥 Request Body
```json
{
  "license_code": "POS-L1-A8F9K2-X1Y2Z3",
  "device_fingerprint": "75c61239-0d2a-4467-b5de-8bb6d1a51167"
}
```

### 📤 Response (200 OK)
```json
{
  "status": "success",
  "code": 200,
  "message": "Lisensi Aktif.",
  "data": {
    "is_active": true
  }
}
```

---

## 🛠️ Security & Rate Limiting Strategy di Fiber Go
* **Rate Limiting:** Menggunakan middleware `fiber/v2/middleware/limiter` (Maksimal 5 request per menit per IP) khusus untuk *endpoint* `/activate` guna mencegah serangan *Brute Force* tebak kode lisensi.
* **Database:** SQLite atau PostgreSQL (tergantung target *production* backend nanti). Data *License Code* akan disimpan dalam bentuk HASH (seperti *password*) jika memungkinkan, atau *plaintext* aman karena berfungsi layaknya kupon sekali pakai.
