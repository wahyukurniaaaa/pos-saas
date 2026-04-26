# POSify Web Dashboard - Design Specification

**Versi:** 1.0  
**Tanggal:** 2026-04-26  
**Tujuan:** Dashboard web Next.js untuk owner/manager mengakses analytics dan management data bisnis

---

## Executive Summary

Dashboard web modern dengan Next.js App Router yang akan dibangun secara bertahap:
- **Fase 1:** Marketing Landing Page + Analytics Dashboard (active now) - Read-only data dengan real-time updates
- **Fase 2:** Management Features + In-App Payment (future) - CRUD operations via Go Backend API

**Access Control:**
- **Landing Page:** Terbuka untuk semua visitor (SEO optimized)
- **Dashboard:** Khusus untuk user **Tier Pro** (Lite users auto-redirect ke upgrade page)
- **Payment:** Integrated payment gateway untuk upgrade Lite → Pro

---

## 1. Architecture Overview

### 1.1 Tech Stack
- **Framework:** Next.js 15 (App Router)
- **Language:** TypeScript
- **Database:** Supabase Client (@supabase/supabase-js)
- **Styling:** Tailwind CSS + shadcn/ui
- **Charts:** Recharts
- **State Management:** TanStack Query (React Query) v5
- **Real-time:** Supabase Realtime subscriptions
- **Auth:** Supabase Auth (shared dengan mobile app)

### 1.2 Scalable Architecture Pattern

**Repository Pattern + Service Layer:**

```
Presentation (React/Next.js)
    │
    ▼
Service Layer (Business Logic)
    │
    ▼
Repository Layer (Abstract Interface)
    │
    ├─► SupabaseRepository (Phase 1 - Analytics)
    └─► GoApiRepository (Phase 2 - Management)
```

### 1.3 Folder Structure

```bash
app/
├── (marketing)/                   # Public marketing site
│   ├── layout.tsx                 # Marketing layout (clean, no sidebar)
│   ├── page.tsx                   # Landing Page (Hero, Features, Pricing)
│   ├── features/                  # Feature details page
│   ├── pricing/                 # Pricing comparison page
│   └── about/                   # About POSify
├── (dashboard)/                   # Pro-only dashboard
│   ├── layout.tsx                 # Protected layout (tier guard)
│   ├── page.tsx                   # Dashboard home
│   ├── analytics/
│   ├── products/
│   ├── employees/
│   ├── reports/
│   └── upgrade/                   # Upgrade page (Lite users)
├── login/                         # Auth page (shared)
├── payment/                       # Payment flow (future)
│   ├── callback/                # Payment gateway callback
│   └── success/                 # Payment success page
├── layout.tsx                     # Root layout
└── page.tsx                       # Root redirect → marketing
```

components/
├── ui/                             # shadcn components
│   ├── button.tsx
│   ├── card.tsx
│   └── ...
├── layout/
│   ├── dashboard-shell.tsx
│   ├── sidebar.tsx
│   └── header.tsx
├── charts/
│   ├── sales-chart.tsx
│   └── inventory-chart.tsx
└── features/
    └── analytics/

lib/
├── database/
│   ├── interfaces/
│   │   └── repository.interface.ts
│   ├── repositories/
│   │   ├── supabase/               # Phase 1
│   │   │   ├── base.repository.ts
│   │   │   ├── analytics.repository.ts
│   │   │   └── products.repository.ts
│   │   └── api/                    # Phase 2
│   │       ├── base.repository.ts
│   │       └── products.repository.ts
│   └── factory.ts                  # Repository factory
├── services/
│   ├── analytics.service.ts
│   ├── products.service.ts
│   └── realtime.service.ts
├── supabase/
│   ├── client.ts                   # Browser client
│   ├── server.ts                   # Server component client
│   └── realtime.ts                 # Realtime helper
├── hooks/
│   ├── use-analytics.ts
│   ├── use-realtime.ts
│   └── use-auth.ts
├── types/
│   ├── database.types.ts           # Generated Supabase types
│   ├── models.ts
│   └── analytics.ts
└── utils/
    ├── formatters.ts
    └── validators.ts
```

---

## 2. Real-time Strategy

### 2.1 Hybrid Real-time Approach

**Real-time (WebSocket):**
- Total penjualan hari ini
- Transaksi aktif (untuk F&B table management)
- Stok menipis alerts

**Fetch on Demand (TanStack Query):**
- Riwayat transaksi lengkap (paginated)
- Daftar produk (searchable)
- Laporan lengkap (monthly/quarterly)

### 2.2 Implementation Pattern

```typescript
// hooks/use-analytics.ts
export function useTodaySales() {
  const { data, refetch } = useQuery({
    queryKey: ['sales', 'today'],
    queryFn: () => analyticsService.getTodaySales(),
    staleTime: 5 * 60 * 1000
  });

  // Real-time subscription untuk auto-refresh
  useEffect(() => {
    const channel = supabase
      .channel('transactions')
      .on('postgres_changes', {
        event: 'INSERT',
        schema: 'public',
        table: 'transactions'
      }, () => {
        refetch();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [refetch]);

  return { data, isLoading };
}
```

---

## 3. Dashboard Layout & Screens

### 3.1 Shell Layout

```
┌────────────────────────────────────────────────────────────┐
│ Header                                                     │
│ [Logo]          [🔍 Search] [🛎️ Notif] [👤 Profile ▼]       │
├────────────┬───────────────────────────────────────────────┤
│ SIDEBAR    │ CONTENT AREA                                  │
│            │                                               │
│ 🏠 Dashboard│  [Dashboard Home]                            │
│ 📊 Analytics│  ┌─────────┐ ┌─────────┐ ┌─────────┐        │
│ 📄 Reports │  │ Sales   │ │ Trans   │ │ Low     │        │
│ ───────────│  │ Today   │ │ Active  │ │ Stock   │        │
│ 📦 Products│  │         │ │         │ │         │        │
│   (Soon)   │  └─────────┘ └─────────┘ └─────────┘        │
│ 👥 Employees│                                               │
│   (Soon)   │  [📈 Sales Chart: Last 7 Days]               │
│ ⚙️ Settings│                                               │
│   (Soon)   │  [Recent Transactions Table]                  │
│            │                                               │
└────────────┴───────────────────────────────────────────────┘
```

### 3.2 Phase 1 Routes (Analytics)

| Route | Purpose | Data Strategy |
|-------|---------|---------------|
| `/dashboard` | Ringkasan bisnis | Real-time cards + cached stats |
| `/dashboard/analytics` | Trend & charts | TanStack Query (SWR) |
| `/dashboard/reports` | Laporan detail | Fetch on demand |

### 3.3 Phase 2 Routes (Management)

| Route | Purpose | Data Strategy |
|-------|---------|---------------|
| `/dashboard/products` | CRUD produk | Go API |
| `/dashboard/employees` | Manage staff | Go API |
| `/dashboard/settings` | Konfigurasi | Go API |

### 3.4 Navigation Config

```typescript
const navigation = [
  { 
    name: 'Dashboard', 
    href: '/dashboard', 
    icon: HomeIcon, 
    phase: 1 
  },
  { 
    name: 'Analytics', 
    href: '/dashboard/analytics', 
    icon: ChartBarIcon, 
    phase: 1 
  },
  { 
    name: 'Reports', 
    href: '/dashboard/reports', 
    icon: DocumentTextIcon, 
    phase: 1 
  },
  { 
    name: 'Products', 
    href: '/dashboard/products', 
    icon: PackageIcon, 
    phase: 2,
    badge: 'Soon',
    disabled: true 
  },
  { 
    name: 'Employees', 
    href: '/dashboard/employees', 
    icon: UsersIcon, 
    phase: 2,
    badge: 'Soon',
    disabled: true 
  },
  { 
    name: 'Settings', 
    href: '/dashboard/settings', 
    icon: CogIcon, 
    phase: 2,
    badge: 'Soon',
    disabled: true 
  },
];
```

---

## 4. Component Architecture

### 4.1 Component Hierarchy

```
DashboardShell
├── Header
│   ├── SearchBar
│   ├── NotificationBell (real-time)
│   └── UserProfileDropdown
├── Sidebar
│   ├── NavSection (Phase 1 - Active)
│   │   ├── NavItem - Dashboard
│   │   ├── NavItem - Analytics
│   │   └── NavItem - Reports
│   └── NavSection (Phase 2 - Disabled)
│       ├── NavItemDisabled - Products
│       ├── NavItemDisabled - Employees
│       └── NavItemDisabled - Settings
└── ContentArea
    ├── DashboardHomePage
    │   ├── StatCardsGrid
    │   │   ├── TodaySalesCard (real-time)
    │   │   ├── ActiveTransactionsCard (real-time)
    │   │   └── LowStockAlertCard (real-time)
    │   ├── SalesChart (Recharts)
    │   │   └── LineChart - 7/30 days
    │   └── RecentTransactionsTable
    │       └── DataTable + Pagination
    └── AnalyticsPage
        ├── DateRangePicker
        ├── FilterBar
        ├── MainChart
        └── DetailedReportTable
```

### 4.2 Core Components

#### DashboardCard
```typescript
interface DashboardCardProps {
  title: string;
  value: string | number;
  trend?: number;              // +12.5 untuk +12.5%
  icon: React.ComponentType;
  realTime?: boolean;          // Show live indicator
  loading?: boolean;           // Skeleton state
}

// Usage:
<DashboardCard 
  title="Penjualan Hari Ini"
  value="Rp 2.450.000"
  trend={+12.5}
  icon={CurrencyDollarIcon}
  realTime={true}
/>
```

#### DataTable
```typescript
interface DataTableProps<T> {
  data: T[];
  columns: ColumnDef<T>[];
  loading?: boolean;
  pagination?: boolean;
  onRowClick?: (row: T) => void;
}
```

---

## 5. Management Features Detail (Phase 2)

### 5.1 Product Management

#### 5.1.1 Product Master
**Route:** `/dashboard/products`

**Features:**
- **Product List View**
  - Grid/Table view dengan pagination (50/100/200 per page)
  - Search: Nama, SKU, Barcode, Kategori
  - Filter: Kategori, Stock status (In Stock, Low Stock, Out of Stock), Aktif/Nonaktif
  - Sort: Nama, Harga, Stock, Last updated
  - Bulk Actions: Delete, Update category, Update price, Toggle active

- **Product Detail/Edit**
  - Basic Info: Nama, SKU, Barcode, Kategori, Unit
  - Pricing: Base price, HPP (COGS), Margin calculation
  - Inventory: Current stock, Min stock level, Unit konversi
  - Variants: Manage variant combinations (size, color, dll)
  - Status: Aktif/Nonaktif toggle
  - History: Audit log perubahan

- **Add Product Wizard**
  - Step 1: Basic Info
  - Step 2: Pricing & Inventory
  - Step 3: Variant Generation (jika ada)
  - Step 4: Recipe/Ingredients (F&B only)

- **Import/Export**
  - Export: CSV/Excel download
  - Import: CSV upload dengan preview, template download

#### 5.1.2 Category Management
**Route:** `/dashboard/categories`

- CRUD kategori
- Drag-drop reordering
- Hierarchical structure (Parent > Child)
- Icon picker untuk kategori

#### 5.1.3 Unit & Conversion
**Route:** `/dashboard/units`

- Base units: Pcs, Kg, Gram, Liter, Meter, etc
- Conversion rules: 1 Kg = 1000 Gram
- Product-specific conversions

### 5.2 Inventory Management

#### 5.2.1 Stock Management
**Route:** `/dashboard/inventory`

- **Stock Overview Dashboard**
  - Total produk
  - Low stock alerts
  - Out of stock list
  - Stock value (HPP × quantity)

- **Stock Adjustment**
  - Manual adjustment: Add/Reduce stock
  - Adjustment reasons: Rusak, Hilang, Expired, DDP, Lainnya
  - Approval workflow (opsional)
  - Bulk adjustment via CSV

#### 5.2.2 Stock Opname
**Route:** `/dashboard/inventory/opname`

- **Stock Opname Session**
  - Buat session opname baru
  - Assign ke outlet & employee
  - Status: Draft → In Progress → Completed

- **Opname Process**
  - Input fisik count per product
  - System count auto-filled
  - Variance calculation
  - Reason input untuk variance ≠ 0
  - Finalisasi: Update system stock dengan fisik count

- **Opname History**
  - List semua session
  - Detail variance report
  - Export ke PDF/Excel

#### 5.2.3 Recipe & Ingredient (F&B)
**Route:** `/dashboard/recipes`

- **Ingredient Master**
  - Nama, unit, harga beli rata-rata
  - Supplier linking
  - Stock tracking

- **Recipe Management**
  - Link produk dengan ingredients
  - Ingredient quantity per product unit
  - Auto-deduct saat transaksi (opsional)
  - COGS calculation otomatis

#### 5.2.4 Stock Transfer (Multi-Outlet)
**Route:** `/dashboard/inventory/transfers`

- **Create Transfer**
  - Pilih source outlet
  - Pilih destination outlet
  - Products & quantities
  - Notes
  - Status: Draft → Sent → In Transit → Received

- **Receive Transfer**
  - List incoming transfers
  - Accept/Reject dengan reason
  - Variance handling

### 5.3 Employee Management

#### 5.3.1 Employee Master
**Route:** `/dashboard/employees`

- **Employee List**
  - Grid view dengan foto, nama, role, outlet
  - Filter: Outlet, Role, Status
  - Search: Nama, PIN, Email

- **Employee Detail**
  - Basic: Nama, PIN, Email, No HP, Foto
  - Role: Owner, Supervisor, Cashier, Kitchen, Waiter
  - Assignment: Primary outlet, additional outlets
  - Permissions: Role-based access control
  - Status: Aktif/Nonaktif

- **Add/Edit Employee**
  - Form dengan validasi
  - Auto-generate PIN option
  - Email invitation (opsional)
  - Foto upload/capture

#### 5.3.2 Shift Management
**Route:** `/dashboard/employees/shifts`

- **Shift Overview**
  - Shift aktif saat ini
  - Riwayat shift per employee
  - Outlet filter

- **Shift Detail**
  - Employee info
  - Jam buka, jam tutup
  - Modal awal
  - Total penjualan shift
  - Total refund/Void
  - Selisih (jika ada)
  - Status: Open → Closed → Audited

#### 5.3.3 Performance Tracking
**Route:** `/dashboard/employees/performance`

- **Metrics per Employee**
  - Total transaksi
  - Total revenue
  - Average order value
  - Top selling products
  - Shift attendance

- **Comparison**
  - Compare multiple employees
  - Time period: Today, 7 days, 30 days
  - Export report

### 5.4 Customer Management

#### 5.4.1 Customer Master
**Route:** `/dashboard/customers`

- **Customer List**
  - Grid: Nama, No HP, Total transaksi, Total belanja
  - Filter: Loyalty tier, Last purchase
  - Search: Nama, No HP, Member ID

- **Customer Detail**
  - Profile: Nama, No HP, Email, Alamat
  - Transaction history
  - Loyalty points balance
  - Membership tier
  - Notes

#### 5.4.2 Loyalty & Membership
**Route:** `/dashboard/customers/loyalty`

- **Tier Configuration**
  - Setup rules: Silver, Gold, Platinum
  - Min points per tier
  - Benefits per tier (diskon %, point multiplier)

- **Points Management**
  - Manual adjustment (Add/Deduct)
  - Points history
  - Expiry configuration

### 5.5 Supplier Management

#### 5.5.1 Supplier Master
**Route:** `/dashboard/suppliers`

- **Supplier List**
  - Nama, PIC, No HP, Email, Status

- **Supplier Detail**
  - Info: Nama, Alamat, PIC, Kontak
  - Products supplied
  - Purchase history
  - Average lead time
  - Payment terms

#### 5.5.2 Purchase Orders (PO)
**Route:** `/dashboard/purchase-orders`

- **PO List**
  - Status: Draft, Sent, Partial, Received, Cancelled
  - Filter: Supplier, Status, Date range

- **Create PO**
  - Pilih supplier
  - Add products: Unit, quantity, harga beli
  - Auto-calculate total
  - Expected delivery date
  - Notes

- **Receive PO**
  - Mark as received (full/partial)
  - Update stock (jika terima fisik)
  - Record actual delivery date
  - Variance notes

### 5.6 Transaction Management

#### 5.6.1 Transaction History
**Route:** `/dashboard/transactions`

- **Advanced List**
  - Search: Receipt number, customer name
  - Filter: Date range, outlet, payment method, employee
  - Filter: Status (Completed, Voided, Refunded)
  - Sort: Date, Amount

- **Transaction Detail**
  - Complete receipt info
  - Items detail
  - Payment breakdown
  - Void/Refund history
  - Print receipt

#### 5.6.2 Void & Refund Approvals
**Route:** `/dashboard/transactions/approvals`

- **Pending Approvals**
  - List pending void requests
  - Supervisor approval workflow
  - Reason & evidence view
  - Approve/Reject action

### 5.7 Discount & Promo Management

#### 5.7.1 Discount Rules
**Route:** `/dashboard/discounts`

- **Discount List**
  - Nama, Type (Percentage/Fixed), Value, Status
  - Active period

- **Create Discount**
  - Basic: Nama, Description
  - Type: Percentage atau Fixed Amount
  - Value: 10% atau Rp 10.000
  - Applicable products/categories (all or specific)
  - Min purchase requirement
  - Date range: Start - End
  - Usage limit (opsional)

#### 5.7.2 Vouchers
**Route:** `/dashboard/vouchers`

- **Voucher Management**
  - Generate bulk vouchers
  - Unique code generator
  - One-time or multi-use
  - Validity period
  - Usage tracking

### 5.8 Outlets & Settings

#### 5.8.1 Outlet Management
**Route:** `/dashboard/outlets`

- **Outlet List** (khusus Owner)
  - Nama, Alamat, Status
  - Device count aktif
  - Employee count

- **Outlet Detail**
  - Info: Nama, Alamat, Telepon, Email
  - Tax settings (PPN enable/disable, %)
  - Receipt footer custom
  - Operating hours
  - Printer settings (thermal printer config)

#### 5.8.2 Device Management
**Route:** `/dashboard/settings/devices`

- **Active Devices**
  - Device name, Activation date, Last seen
  - Deactivate device (jika ganti HP)

#### 5.8.3 Receipt Customization
**Route:** `/dashboard/settings/receipt`

- **Receipt Template**
  - Header customization
  - Logo upload
  - Footer text
  - Show/hide: Tax, Discount, Payment methods
  - Preview live

#### 5.8.4 Tax & Legal
**Route:** `/dashboard/settings/tax`

- **Tax Configuration**
  - PPN enable/disable
  - PPN percentage (default 11%)
  - NPWP perusahaan
  - Legal business name
  - NIB/SKUsaha

### 5.9 Expense Management

#### 5.9.1 Expense Tracking
**Route:** `/dashboard/expenses`

- **Expense List**
  - Date range filter
  - Category filter
  - Outlet filter

- **Add Expense**
  - Kategori (Utilities, Payroll, Supplies, dll)
  - Amount
  - Description
  - Receipt photo upload (opsional)
  - Date
  - Employee assign

- **Expense Categories**
  - Default: Utilities, Rent, Payroll, Marketing, Supplies
  - Custom categories

#### 5.9.2 Expense Reports
- Monthly expense breakdown
- Comparison vs revenue
- Export ke PDF/Excel

### 5.10 Multi-Outlet Features (Khusus Pro)

#### 5.10.1 Cross-Outlet Stock Visibility
**Route:** `/dashboard/inventory/cross-outlet`

- **Stock Checker**
  - Pilih produk
  - Lihat stock di semua outlet
  - Outlet with lowest/highest stock
  - Request stock transfer

#### 5.10.2 Global Reports
**Route:** `/dashboard/reports/global`

- **Consolidated Reports** (khusus Owner dengan multi-outlet)
  - Total revenue all outlets
  - Outlet comparison
  - Best performing outlet
  - Product performance cross-outlet

## 6. Data Models

### 6.1 Analytics Types

```typescript
// lib/types/analytics.ts

export interface TodaySales {
  total_amount: number;
  transaction_count: number;
  average_order_value: number;
  comparison_yesterday: number;
  updated_at: string;
}

export interface SalesTrend {
  date: string;
  total_sales: number;
  transaction_count: number;
}

export interface TopProduct {
  product_id: string;
  product_name: string;
  total_quantity: number;
  total_revenue: number;
}

export interface LowStockAlert {
  product_id: string;
  product_name: string;
  current_stock: number;
  min_stock_level: number;
  variant_name?: string;
}
```

### 5.2 Repository Interfaces

```typescript
// lib/database/interfaces/repository.interface.ts

export interface IAnalyticsRepository {
  getTodaySales(outletId: string): Promise<TodaySales>;
  getSalesTrend(outletId: string, days: number): Promise<SalesTrend[]>;
  getTopProducts(outletId: string, limit: number): Promise<TopProduct[]>;
  getLowStockAlerts(outletId: string): Promise<LowStockAlert[]>;
  getRecentTransactions(outletId: string, limit: number): Promise<Transaction[]>;
}

export interface IProductsRepository {
  getProducts(outletId: string): Promise<Product[]>;
  getProductById(productId: string): Promise<Product>;
  createProduct(product: CreateProductDTO): Promise<Product>;
  updateProduct(productId: string, updates: UpdateProductDTO): Promise<Product>;
  deleteProduct(productId: string): Promise<void>;
}

export interface AuthRepository {
  getSession(): Promise<Session | null>;
  signIn(email: string, password: string): Promise<AuthResponse>;
  signOut(): Promise<void>;
}
```

---

## 6. Implementation Roadmap

### Phase 1: Analytics Dashboard (2-3 weeks)

**Minggu 1: Setup & Architecture**
- [ ] Initialize Next.js project dengan shadcn/ui
- [ ] Setup folder structure (Repository Pattern)
- [ ] Configure Supabase client (browser + server)
- [ ] Setup Tailwind + tema POSify

**Minggu 2: Core Layout & Components**
- [ ] Dashboard shell (sidebar + header)
- [ ] Navigation dengan Phase indicators
- [ ] DashboardCard component + skeleton states
- [ ] DataTable generic component
- [ ] Recharts integration

**Minggu 3: Analytics Features**
- [ ] TodaySales API + real-time subscription
- [ ] SalesTrend chart (7/30 days)
- [ ] Recent transactions table
- [ ] Low stock alerts (real-time)
- [ ] Reports page dengan date range
- [ ] Auth integration + protected routes

### Phase 2: Management CRUD (4-6 weeks)

**Tahap 1: Backend Expansion**
- [ ] Go API endpoints: Products CRUD
- [ ] Go API endpoints: Employees CRUD
- [ ] Permission middleware (Owner only)

**Tahap 2: Web Integration**
- [ ] Repository switch: Supabase → Go API
- [ ] Products management page
- [ ] Employees management page
- [ ] Settings page

---

## 7. Technical Standards

### 7.1 Code Conventions
- **Components:** PascalCase, functional components
- **Files:** kebab-case untuk utilities, PascalCase untuk components
- **Imports:** Absolute imports dengan `@/` prefix
- **Types:** Strict TypeScript, no `any`

### 7.2 State Management Rules
1. Server state pakai **TanStack Query**
2. Client state pakai **React useState/useReducer**
3. Global state minimal, prefer composition
4. Real-time hanya untuk data yang benar-benar perlu live

### 7.3 Performance Targets
- First Contentful Paint: < 1.5s
- Time to Interactive: < 3s
- Lighthouse Score: > 90
- Bundle size: < 200KB initial

---

## 8. Security Considerations

### 8.1 Auth Flow
1. User login via Supabase Auth (same dengan mobile)
2. Session stored di memory (tanstack query) + cookie
3. RLS policies di Supabase tetap aktif untuk web
4. Phase 2: Additional permission check di Go API

### 8.2 Data Protection
- No sensitive data di localStorage
- API keys di environment variables
- HTTPS only production
- Supabase RLS enabled

---

## 9. Dependencies

### Core Dependencies
```bash
# Framework & UI
npx create-next-app@latest posify-dashboard --typescript --tailwind --app
npx shadcn-ui@latest init
npx shadcn-ui@latest add button card table badge skeleton

# Database & Real-time
npm install @supabase/supabase-js

# State Management
npm install @tanstack/react-query

# Charts
npm install recharts

# Icons
npm install @heroicons/react

# Utils
npm install clsx tailwind-merge
npm install date-fns
```

---

## 10. Landing Page & Marketing Site

### 10.1 Landing Page Structure

**Route:** `posify.id/` atau `dashboard.posify.id/`

```
Landing Page Sections:
├── Hero Section
│   ├── Headline: "Kelola Bisnis UMKM Lebih Cepat"
│   ├── Subheadline: "POS Online & Offline lengkap dengan manajemen multi-outlet"
   ├── CTA Buttons: [Coba Gratis] [Lihat Demo]
│   └── Hero Image: App mockup atau video demo
├── Features Section
│   ├── Grid 3-6 fitur utama
│   ├── POS Offline-First
│   ├── Manajemen Multi-Outlet
│   ├── Analisis Penjualan Real-time
│   ├── Manajemen Produk & Stok
│   ├── Manajemen Karyawan
│   └── Laporan Keuangan Otomatis
├── How It Works
│   ├── Step 1: Download & Aktivasi
│   ├── Step 2: Setup Produk & Outlet
│   ├── Step 3: Mulai Jualan
│   └── Dashboard web untuk owner
├── Pricing Section
│   ├── Lite: Rp 99.000/bln (1 outlet, 1 device)
│   ├── Pro: Rp 299.000/bln (3 outlet, 10 device, cloud sync)
│   └── Enterprise: Custom
├── Testimonials
│   └── Carousel testimoni merchant
├── CTA Section
│   └── Final CTA untuk signup
└── Footer
    ├── Links: Features, Pricing, About, Contact
    ├── Social media
    └── Legal: Privacy, Terms
```

### 10.2 Landing Page Tech

- **Static Generation:** Next.js SSG untuk SEO maksimal
- **Images:** Next.js Image optimization
- **Performance:** Lazy load sections, minimal JS
- **SEO:** Meta tags, Open Graph, structured data
- **Analytics:** Google Analytics / Mixpanel

---

## 11. Tier-Based Access Control

### 11.1 Access Rules

| Tier | Landing Page | Dashboard | Management |
|------|-----------|-----------|------------|
| **Visitor** | ✅ Full access | ❌ Login required | ❌ Login required |
| **Free** | ✅ Full access | ❌ Upgrade page | ❌ Upgrade page |
| **Lite** | ✅ Full access | ❌ Upgrade page | ❌ Upgrade page |
| **Pro** | ✅ Full access | ✅ Full access | ✅ Full access |

### 11.2 Middleware Implementation

```typescript
// middleware.ts - Next.js Edge Middleware

import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { createMiddlewareClient } from '@supabase/auth-helpers-nextjs';

export async function middleware(request: NextRequest) {
  const res = NextResponse.next();
  const supabase = createMiddlewareClient({ req: request, res });
  
  const { data: { session } } = await supabase.auth.getSession();
  
  // Cek path yang dilindungi (dashboard)
  if (request.nextUrl.pathname.startsWith('/dashboard')) {
    if (!session) {
      // Not logged in → login page
      return NextResponse.redirect(new URL('/login', request.url));
    }
    
    // Cek tier dari session/user metadata
    const tier = session.user.user_metadata.tier || 'free';
    
    if (tier !== 'pro') {
      // Not Pro → upgrade page
      return NextResponse.redirect(new URL('/dashboard/upgrade', request.url));
    }
  }
  
  return res;
}

export const config = {
  matcher: ['/dashboard/:path*']
};
```

### 11.3 Upgrade Page Flow

```
User (Lite/Free) logs in
    ↓
Attempt access /dashboard
    ↓
Middleware redirect → /dashboard/upgrade
    ↓
Upgrade Page:
├── "Dashboard hanya untuk tier Pro"
├── Feature comparison table
├── Pricing cards (Lite vs Pro)
├── CTA: "Upgrade ke Pro"
└── Link: "Kembali ke aplikasi mobile"
    ↓
Payment Gateway (Midtrans/Xendit)
    ↓
Success → Webhook update tier → /dashboard
```

---

## 12. Payment Gateway Integration

### 12.1 Payment Flow (Phase 2)

```
User di Upgrade Page
    ↓
Klik "Upgrade ke Pro"
    ↓
Create Payment Session (API Route)
    ├── Pilih subscription plan (monthly/yearly)
    ├── Calculate total
    └── Generate unique order ID
    ↓
Redirect ke Payment Gateway
    ├── Mid Snap / Xendit Checkout
    ├── UI: Card, Bank Transfer, E-wallet
    └── User complete payment
    ↓
Payment Callback/Webhook
    ├── Payment Gateway POST ke /api/webhook/payment
    ├── Verify signature (security)
    ├── Update user tier di Supabase Auth
    ├── Update licenses table
    └── Send confirmation email
    ↓
Redirect ke Success Page
├── "Selamat! Upgrade berhasil"
├── Ringkasan subscription
├── CTA: "Buka Dashboard"
└── Download invoice
    ↓
User sekarang bisa akses Dashboard
```

### 12.2 Implementation Details

**Backend Integration (Go):**
```go
// POST /api/v1/billing/upgrade
type UpgradeRequest struct {
    UserID string `json:"user_id"`
    Tier   string `json:"tier"`   // "pro"
    Period string `json:"period"` // "monthly" | "yearly"
}

type UpgradeResponse struct {
    OrderID       string `json:"order_id"`
    PaymentURL    string `json:"payment_url"`
    ExpiryTime    int64  `json:"expiry_time"`
    Amount        int64  `json:"amount"`        // Rupiah
}
// Webhook handler
POST /api/v1/webhooks/payment/:provider
- Handle Midtrans notification
- Handle Xendit callback
- Idempotency check (duplicate prevention)
- Update user tier
```

**API Routes (Next.js):**
```typescript
// app/api/payment/create/route.ts
export async function POST(request: Request) {
  const { tier, period } = await request.json();
  
  // Call Go API untuk create payment
  const response = await fetch(`${GO_API}/billing/upgrade`, {
    method: 'POST',
    body: JSON.stringify({ tier, period })
  });
  
  const paymentSession = await response.json();
  
  // Return payment URL ke client
  return Response.json(paymentSession);
}

// app/api/webhooks/payment/midtrans/route.ts
export async function POST(request: Request) {
  const body = await request.json();
  
  // Verify Midtrans signature
  // Forward ke Go API untuk proses
  // Return 200 OK (idempotent)
}
```

### 12.3 Pricing Configuration

```typescript
// lib/config/pricing.ts

export const PRICING = {
  lite: {
    id: 'tier_lite',
    name: 'Lite',
    price: 99000,
    yearlyPrice: 990000, // 2 bulan gratis
    outlets: 1,
    devices: 1,
    features: [
      'Aplikasi Android/iOS',
      'Offline-first',
      '1 Outlet',
      '1 Device',
      'Lokal database (SQLite)',
    ],
  },
  pro: {
    id: 'tier_pro',
    name: 'Pro',
    price: 299000,
    yearlyPrice: 2990000, // 2 bulan gratis
    outlets: 3,
    devices: 10,
    features: [
      'Semua fitur Lite',
      'Cloud Sync (Supabase)',
      'Multi-Outlet (3)',
      'Multi-Device (10)',
      'Dashboard Web Analytics',
      'Real-time reporting',
      'Priority Support',
    ],
  },
  enterprise: {
    id: 'tier_enterprise',
    name: 'Enterprise',
    price: null, // Custom
    outlets: 'Unlimited',
    devices: 'Unlimited',
    features: [
      'Semua fitur Pro',
      'Custom integration',
      'Dedicated support',
      'On-premise option',
    ],
  },
};

export type PricingTier = keyof typeof PRICING;
```

---

## 13. Complete Site Map

```
posify.id/
├── /                    # Landing Page (Marketing)
├── /features            # Feature details
├── /pricing             # Pricing comparison
├── /about               # About POSify
├── /login               # Auth (shared)
│   └── ?redirect=dashboard # Redirect after login
├── /register            # Sign up (optional, atau pakai app)
│
├── /dashboard           # Protected (Pro only)
│   ├── /                # Dashboard home
│   ├── /analytics       # Sales analytics
│   ├── /reports         # Detailed reports
│   └── /upgrade         # Upgrade page (jika Lite)
│
├── /api
│   ├── /auth/*          # NextAuth/Supabase auth routes
│   ├── /payment
│   │   ├── /create      # Create payment session
│   │   └── /status      # Check payment status
│   └── /webhooks
│       ├── /midtrans    # Midtrans callback
│       └── /xendit      # Xendit callback
│
└── /payment             # Payment flow (future)
    ├── /checkout        # Checkout page
    └── /success         # Success redirect

app.posify.id/           # Mobile app webview (optional)
```

---

## 14. Implementation Roadmap (Updated)

### Phase 1: Landing Page + Analytics (6 weeks)

**Minggu 1-2: Foundation**
- [ ] Next.js setup + shadcn/ui
- [ ] Landing page sections (Hero, Features, Pricing)
- [ ] Static generation optimization
- [ ] SEO & meta tags

**Minggu 3-4: Auth & Dashboard Shell**
- [ ] Supabase Auth integration
- [ ] Tier-based middleware
- [ ] Protected routes setup
- [ ] Upgrade page (Lite → Pro)

**Minggu 5-6: Analytics Dashboard**
- [ ] Repository pattern setup
- [ ] Dashboard components
- [ ] Real-time subscriptions
- [ ] Charts & reports

### Phase 2: Management + Payment (6-8 weeks)

**Minggu 7-8: Backend Expansion**
- [ ] Go API: Products CRUD
- [ ] Go API: Employees CRUD
- [ ] Permission middleware

**Minggu 9-10: Management Features**
- [ ] Products management page
- [ ] Employees management page
- [ ] Settings page

**Minggu 11-12: Payment Integration**
- [ ] Payment gateway setup (Midtrans/Xendit)
- [ ] Upgrade flow end-to-end
- [ ] Webhook handlers
- [ ] Invoice generation

---

## 15. Next Steps

1. **Review design document** ini bersama tim
2. **Prioritize:** Landing Page terlebih dahulu atau Dashboard?
3. **Finalize:** Pilih Midtrans atau Xendit untuk Phase 2
4. **Setup project** dengan `create-next-app`
5. **Generate types** dari Supabase schema
6. **Implement Phase 1** secara iteratif

---

**Status:** Draft - Ready for review  
**Author:** Claude Code  
**Last Updated:** 2026-04-26
