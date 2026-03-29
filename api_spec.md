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
API ini bersifat *Public* untuk *endpoint* aktivasi, namun diproteksi menggunakan **API Key** statis pada HTTP Header untuk mencegah serangan DDoS atau spamming dari luar aplikasi Mobile resmi. *Endpoint* admin menggunakan *Admin Secret Key*.

**Global Header Requirements:**
- `X-App-Client-Key`: `string` (*Secret API Key tertanam di dalam APK Flutter*) atau `X-Admin-Secret-Key` (Untuk endpoint /admin)
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
| `license_code` | `string` | Kode 10-digit hasil pembelian marketplace (e.g., `X8Y2K9J1P5`). | Wajib, 10 char alfanumerik. |
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

## 📌 Endpoint: POST `/api/v1/admin/license/generate`

**Deskripsi:**  
(Admin Only) Men-*generate* kode lisensi baru yang bisa diberikan/dijual ke *Owner*. Route ini diproteksi oleh `X-Admin-Secret-Key`.

### 📥 Request Body
```json
{
  "tier_level": "Tier 1 - Lifetime",
  "max_devices": 1
}
```

| Parameter | Type | Keterangan | Validasi |
| :--- | :--- | :--- | :--- |
| `tier_level` | `string` | Tipe tier lisensi | Wajib |
| `max_devices` | `int` | Jumlah maksimal perangkat. | Wajib, min 1 |

### 📤 Response (201 Created)
```json
{
  "status": "success",
  "code": 201,
  "message": "Lisensi berhasil dibuat.",
  "data": {
    "license_code": "X8Y2K9J1P5",
    "tier_level": "Tier 1 - Lifetime",
    "max_devices": 1
  }
}
```

---

## 🛠️ Security & Rate Limiting Strategy di Fiber Go
* **Rate Limiting:** Menggunakan middleware `fiber/v2/middleware/limiter` (Maksimal 5 request per menit per IP) khusus untuk *endpoint* `/activate` guna mencegah serangan *Brute Force* tebak kode lisensi.
* **Database:** **PostgreSQL** (via GORM). Data *License Code* disimpan dalam bentuk HASH (seperti *password*) jika memungkinkan, atau *plaintext* aman karena berfungsi layaknya kupon sekali pakai.

---

## 🔔 Marketplaces Webhooks (Automated Fulfillment)

Endpoint ini digunakan oleh Marketplace untuk memberitahu server Go POSify ketika terjadi pembayaran sukses.

### 📌 POST `/api/v1/webhooks/tiktok`
### 📌 POST `/api/v1/webhooks/shopee`
### 📌 POST `/api/v1/webhooks/tokopedia`

**Deskripsi:**
Menerima payload JSON dari marketplace. Server Go akan melakukan:
1. Validasi Signature (Hmac/Signature header) dari marketplace.
2. Filter Produk: Cek apakah `product_id` / `sku` sesuai dengan produk POSify Lite/Pro.
3. Generate License: Jika cocok, buat `license_code` baru di database.
4. Auto-Email: Kirim email via Resend/SendGrid berisi kode lisensi dan link registrasi.

---

## 🔐 Authentication & Accounts (Unified Registration)

### 📌 POST `/api/v1/auth/register-with-license`

**Deskripsi:**
Menggabungkan pembuatan akun **Supabase Auth** dengan aktivasi lisensi dalam satu langkah (*Redeem to Account*).

### 📥 Request Body
```json
{
  "license_code": "POS-LITE-X8Y2K9",
  "email": "user@example.com",
  "password": "user_secret_password",
  "device_fingerprint": "75c61239-0d2a-4467-b5de-8bb6d1a51167"
}
```

| Parameter | Type | Keterangan |
| :--- | :--- | :--- |
| `license_code` | `string` | Kode 10-digit hasil pembelian marketplace. | Opsional (Jika registrasi Pro langsung). |
| `email` | `string` | Email yang akan didaftarkan sebagai ID SaaS. |
| `password` | `string` | Password minimal 8 karakter. |
| `device_fingerprint` | `string` | Identitas hardware unik untuk pencegahan sharing akun. |

### 📤 Response (201 Created)
```json
{
  "status": "success",
  "message": "Akun berhasil dibuat dan lisensi diaktifkan.",
  "data": {
    "user_id": "uuid-supabase-123",
    "tier": "lite",
    "session_token": "jwt-token-here"
  }
}
```
