# POSify Landing Page Design & Implementation Plan

🤖 **Applying knowledge of `@frontend-specialist`...**

## 🎨 DESIGN COMMITMENT: High-Contrast Dynamic Flow

- **Topological Choice:** Menghindari layout 50/50 hero yang klise. Kita akan menggunakan **Massive Typographic Hero** (Centered, overlapping UI elements) di mana elemen kartu UI POS keluar dari grid dan mengambang di atas tipografi.
- **Risk Factor:** Menggunakan geometri yang lebih tajam/agresif (2px-4px border radius) dibanding sudut bulat SaaS pada umumnya, dikombinasikan dengan kontras tinggi antara Navy (#141F9C) dan Kuning Vibran (#FADF61).
- **Readability Conflict:** Tipografi hero akan berukuran masif dengan sedikit *overlapping* dari elemen UI POS yang mengambang untuk menciptakan ilusi kedalaman (Depth).
- **Cliché Liquidation:** TIDAK ADA *bento grids* yang membosankan untuk seksi fitur. TIDAK ADA *mesh gradients* di latar belakang. Kita akan memanfaatkan tekstur *solid grain*, garis pembatas yang tegas, dan blok warna pekat.

## 🎨 Color Palette (Sourced from `app_theme.dart`)

- **Primary:** Navy (`#141F9C`) - Kepercayaan & Stabilitas
- **Secondary:** Yellow (`#FADF61`) - Aksi & Energi
- **Tertiary:** Cornflower (`#5C77F7`) - Logika & Aksen
- **Backgrounds:** Slate 50 (`#F8FAFC`) / Dark (`#121320`)

## 📝 4-Phase Implementation Plan

### Phase 1: Analysis & Discovery (Current Phase)
Validasi *tech stack*, konten, dan pendekatan UI secara Socratic.

### Phase 2: Planning
Mendefinisikan spesifikasi seksi (Hero, Value Prop, Fitur, CTA) dan arsitektur komponen setelah *tech stack* disepakati.

### Phase 3: Solutioning (No Code)
Mendesain arsitektur *state* dan hierarki komponen (jika React/Next.js) atau arsitektur CSS (jika HTML statis).

### Phase 4: Implementation
Membangun *landing page* responsif secara iteratif dengan memegang prinsip *mobile-first* dan menambahkan animasi wajib (*scroll-reveals*, *micro-interactions*) tanpa mengorbankan performa (menggunakan GPU-accelerated properties).
