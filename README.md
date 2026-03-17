# POSify (Point of Sales SaaS)

POSify is a modern Point of Sales (POS) Software-as-a-Service application consisting of a Flutter mobile client and a Go (Fiber) backend. It features local database capabilities on the mobile app using Drift (SQLite) and a centralized license management system on the Go backend.

## 🚀 Tech Stack

- **Mobile Client:** Flutter, Riverpod (State Management), Drift & SQLite3 (Local Database), Dio (Networking).
- **Backend API:** Go, Fiber Web Framework, GORM, SQLite (License Database).
- **Design System:** Custom UI based on Google Stitch MCP (Clean & Modern).

---

## 📋 Prerequisites

Before you begin, ensure you have the following installed on your machine:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.24.x or later)
- [Go](https://go.dev/doc/install) (v1.21 or later)
- [Android Studio](https://developer.android.com/studio) or Xcode (for emulator/simulator)
- SQLite3 (usually pre-installed on Mac/Linux)

---

## 🛠️ Backend Setup (Go)

The backend is responsible for verifying licenses and generating new ones.

1. **Navigate to the backend directory:**
   ```bash
   cd backend
   ```

2. **Setup Environment Variables:**
   Copy the example environment file to `.env` and adjust the values if necessary.
   ```bash
   cp .env.example .env
   ```

3. **Install Dependencies:**
   ```bash
   go mod tidy
   ```

4. **Run Database Seeding (Generate Dummy License):**
   This step will create the `posify-license.db` file and insert a dummy license for testing.
   ```bash
   go run seeding.go
   ```
   *(The dummy license generated is: `POS-L1-A8F9K2-X1Y2Z3`)*

5. **Start the Backend Server:**
   ```bash
   go run cmd/api/main.go
   ```
   *The server will run by default on `http://localhost:3000`.*

---

## 📱 Mobile App Setup (Flutter)

The mobile app functions mainly offline using Drift as the local database, but it requires the backend for initial license activation.

1. **Navigate to the mobile directory:**
   ```bash
   cd mobile
   ```

2. **Setup Environment Variables:**
   Copy the example environment file to `.env`.
   ```bash
   cp .env.example .env
   ```
   Open the `.env` file. If you are using the Android Emulator, `BASE_URL` should be `http://10.0.2.2:3000/api/v1` (10.0.2.2 is the localhost alias for Android Emulator).
   If you are testing on a real device, change it to your computer's local IP address (e.g., `http://192.168.1.5:3000/api/v1`).

3. **Install Flutter Dependencies:**
   ```bash
   flutter pub get
   ```

4. **Generate Drift Database Code (Optional/If Needed):**
   If you make changes to the database tables (`lib/core/database/tables/*.dart`), you need to regenerate the Drift code.
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Run the Application:**
   Make sure your emulator is running or a device is connected, then execute:
   ```bash
   flutter run
   ```

---

## 🔑 Initial Setup Flow

When you run the app for the very first time:

1. **License Activation:** You will be placed on the License Activation Screen.
2. Ensure your Go backend is running.
3. Enter the test license code: `POS-L1-A8F9K2-X1Y2Z3`
4. **Owner Setup:** After successful activation, you will be prompted to create the Owner PIN and set up the Store Name.
5. **Dashboard:** You will be logged in and redirected to the POS Dashboard. Next time you open the app, you will just need to enter your PIN.

---

## 💡 Troubleshooting

- **Error 403 (License already used):** The license binds to a device fingerprint. If you reinstall the app or wipe emulator data, the fingerprint changes. You need to reset the license in the backend database:
  ```bash
  cd backend
  sqlite3 posify-license.db "UPDATE licenses SET device_fingerprint = NULL, activation_date = NULL WHERE license_code = 'POS-L1-A8F9K2-X1Y2Z3';"
  ```
- **"Connection Refused" when activating license:** Make sure the Go backend is running (`go run cmd/api/main.go`). Also check your `.env` in the `mobile` folder to ensure the `BASE_URL` is pointing to the correct address (use `10.0.2.2` for Android Emulators).

---

## 🎯 Next Development Pipeline

### Fitur Peningkat Omzet & Retensi (Loyalty & CRM)
Karena fitur pengiriman struk digital via WhatsApp sudah ada (mengumpulkan data nomor telepon):
- **Manajemen Promo / Diskon:** Kemampuan membuat promo otomatis (cth: "Diskon 10% untuk produk kopi" atau "Beli 2 Gratis 1").
- **Poin Membership (Loyalty Program):** Mengumpulkan poin berdasarkan nominal belanja yang ditautkan ke tabel `customer`. Poin bisa ditukar diskon.
- **Manajemen Piutang / Kasbon:** Pencatatan limit utang pelanggan dan sistem pengingat tagihan otomatis via WhatsApp.

### Fitur Operasional Kasir Lanjutan (F&B / Ritel)
Fokus pada *edge-cases* operasional yang lebih kompleks (sejalan dengan roadmap menuju SaaS):
- **Manajemen Resep / BOM (Bill of Materials):** Memotong stok bahan baku mentah (misalnya 15gr Kopi, 1 Cup) alih-alih stok barang jadi.
- **Save Order / Split Bill:** Opsi menahan pesanan sebelum checkout/pembayaran ("pesan dulu, bayar belakangan" atau patungan).
- **Multi-Printer Routing:** Bisa memisahkan order masakan ke dapur (Kitchen Station) dan kasir, berdasarkan kategori barang.
