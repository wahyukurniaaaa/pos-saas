# POSify Web Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Next.js web dashboard for POSify with marketing landing page, analytics (Phase 1), and tier-based access control (Pro-only)

**Architecture:** Repository pattern with Supabase client (Phase 1) → Go API (Phase 2). Next.js App Router with TanStack Query for caching, Tailwind CSS + shadcn/ui for UI, and Supabase Realtime for metrics.

**Tech Stack:** Next.js 15, TypeScript, Tailwind CSS, shadcn/ui, TanStack Query v5, Supabase Client, Recharts

---

## Phase 1: Foundation & Landing Page (Week 1-2)

### Task 1: Initialize Next.js Project
**Files:**
- Create: All files in `web/` directory
- Create: `web/package.json`, `web/next.config.js`

- [ ] **Step 1: Create Next.js project with shadcn**
```bash
cd /Users/wahyukurnia/www/pos-saas
npx create-next-app@latest web --typescript --tailwind --app --no-src-dir
cd web
npx shadcn-ui@latest init --yes --template next --base-color slate
```

- [ ] **Step 2: Install dependencies**
```bash
cd web
npm install @supabase/supabase-js @tanstack/react-query recharts @heroicons/react
npm install clsx tailwind-merge date-fns
npm install @supabase/auth-helpers-nextjs
npx shadcn-ui@latest add button card table badge skeleton avatar dialog sheet dropdown-menu separator input label textarea tabs checkbox accordion carousel
```

- [ ] **Step 3: Create folder structure**
```bash
mkdir -p web/app/(marketing)/(dashboard)/{dashboard,analytics,reports,upgrade} web/app/(dashboard)  
mkdir -p web/app/api/{auth,payment,webhooks}
mkdir -p web/components/{ui,layout,charts,features/analytics,marketing}
mkdir -p web/lib/{database,database/interfaces,database/repositories/{supabase,api},services,supabase,hooks,types,utils,config}
mkdir -p web/public/{images,icons}
```

- [ ] **Step 4: Commit**
```bash
cd web
git init
git add .
git commit -m "chore: init Next.js project with shadcn/ui and dependencies"
```

### Task 2: Environment Configuration
**Files:**
- Create: `web/.env.local`
- Create: `web/.env.example`
- Create: `web/.gitignore`

- [ ] **Step 1: Create environment files**
```bash
cat > /Users/wahyukurnia/www/pos-saas/web/.env.example << 'EOF'
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
NEXT_PUBLIC_APP_URL=http://localhost:3000

# Database (server-side only - optional for Phase 1)
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
EOF

cp /Users/wahyukurnia/www/pos-saas/web/.env.example /Users/wahyukurnia/www/pos-saas/web/.env.local
```

- [ ] **Step 2: Update .gitignore**
```bash
cat > /Users/wahyukurnia/www/pos-saas/web/.gitignore << 'EOF'
# Dependencies
node_modules
/.pnp
.pnp.js

# Testing
/coverage

# Next.js
/.next/
/out/

# Production
/build

# Misc
.DS_Store
*.pem

# Environment
.env.local
.env.development.local
.env.test.local
.env.production.local

# Debug
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Vercel
.vercel
EOF
```

- [ ] **Step 3: Commit**
```bash
cd /Users/wahyukurnia/www/pos-saas/web
git add .gitignore .env.example
git commit -m "chore: add environment configuration"
```

### Task 3: Tailwind Theme Configuration
**Files:**
- Modify: `web/tailwind.config.ts`
- Modify: `web/app/globals.css`

- [ ] **Step 1: Update Tailwind config with POSify colors**
```typescript
// web/tailwind.config.ts
import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: ["class"],
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
        // POSify Brand Colors
        indigo: {
          50: "#eef2ff",
          100: "#e0e7ff",
          200: "#c7d2fe",
          300: "#a5b4fc",
          400: "#818cf8",
          500: "#6366f1",
          600: "#4f46e5",
          700: "#4338ca",
          800: "#3730a3",
          900: "#312e81",
          950: "#1e1b4b",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      keyframes: {
        "accordion-down": {
          from: { height: "0" },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: "0" },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
};

export default config;
```

- [ ] **Step 2: Update globals.css**
```css
/* web/app/globals.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --card: 0 0% 100%;
    --card-foreground: 222.2 84% 4.9%;
    --popover: 0 0% 100%;
    --popover-foreground: 222.2 84% 4.9%;
    --primary: 243 75% 59%;
    --primary-foreground: 0 0% 100%;
    --secondary: 210 40% 96.1%;
    --secondary-foreground: 222.2 47.4% 11.2%;
    --muted: 210 40% 96.1%;
    --muted-foreground: 215.4 16.3% 46.9%;
    --accent: 210 40% 96.1%;
    --accent-foreground: 222.2 47.4% 11.2%;
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 210 40% 98%;
    --border: 214.3 31.8% 91.4%;
    --input: 214.3 31.8% 91.4%;
    --ring: 243 75% 59%;
    --radius: 0.5rem;
  }

  .dark {
    --background: 222.2 84% 4.9%;
    --foreground: 210 40% 98%;
    --card: 222.2 84% 4.9%;
    --card-foreground: 210 40% 98%;
    --popover: 222.2 84% 4.9%;
    --popover-foreground: 210 40% 98%;
    --primary: 243 75% 59%;
    --primary-foreground: 0 0% 100%;
    --secondary: 217.2 32.6% 17.5%;
    --secondary-foreground: 210 40% 98%;
    --muted: 217.2 32.6% 17.5%;
    --muted-foreground: 215 20.2% 65.1%;
    --accent: 217.2 32.6% 17.5%;
    --accent-foreground: 210 40% 98%;
    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 210 40% 98%;
    --border: 217.2 32.6% 17.5%;
    --input: 217.2 32.6% 17.5%;
    --ring: 243 75% 59%;
  }
}

@layer base {
  * {
    @apply border-border;
  }
  body {
    @apply bg-background text-foreground;
  }
}
```

- [ ] **Step 3: Commit**
```bash
cd /Users/wahyukurnia/www/pos-saas/web
git add tailwind.config.ts app/globals.css
git commit -m "style: configure POSify theme with indigo colors"
```

---

## Phase 2: Supabase Configuration & Types (Week 2)

### Task 4: Supabase Client Setup
**Files:**
- Create: `web/lib/supabase/client.ts`
- Create: `web/lib/supabase/server.ts`

- [ ] **Step 1: Create browser client**
```typescript
// web/lib/supabase/client.ts
import { createBrowserClient } from '@supabase/ssr'

import type { Database } from '@/lib/types/database.types'

export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
```

- [ ] **Step 2: Create types placeholder**
```typescript
// web/lib/types/database.types.ts
// This will be generated by supabase command
export type Database = {
  public: {
    Tables: {
      transactions: {
        Row: {
          id: string
          outlet_id: string
          total_amount: number
          created_at: string
          payment_status: 'paid' | 'unpaid' | 'partial'
        }
      }
    }
  }
}
```

- [ ] **Step 3: Commit**
```bash
cd /Users/wahyukurnia/www/pos-saas/web
git add lib/supabase/ lib/types/
git commit -m "feat: setup supabase client and types"
```

### Task 5: Repository Pattern Base
**Files:**
- Create: `web/lib/database/interfaces/repository.interface.ts`
- Create: `web/lib/database/repositories/supabase/base.repository.ts`
- Create: `web/lib/database/factory.ts`

- [ ] **Step 1: Define repository interfaces**
```typescript
// web/lib/database/interfaces/repository.interface.ts

export interface IAnalyticsRepository {
  getTodaySales(outletId: string): Promise<TodaySales>
  getSalesTrend(outletId: string, days: number): Promise<SalesTrend[]>
  getTopProducts(outletId: string, limit: number): Promise<TopProduct[]>
  getRecentTransactions(outletId: string, limit: number): Promise<Transaction[]>
  getLowStockAlerts(outletId: string): Promise<LowStockAlert[]>
}

export interface ITierProvider {
  getUserTier(): Promise<'free' | 'lite' | 'pro'>
  isPro(): Promise<boolean>
}

// Types
export interface TodaySales {
  totalAmount: number
  transactionCount: number
  averageOrderValue: number
  comparisonYesterday: number
  updatedAt: string
}

export interface SalesTrend {
  date: string
  totalSales: number
  transactionCount: number
}

export interface TopProduct {
  productId: string
  productName: string
  totalQuantity: number
  totalRevenue: number
}

export interface Transaction {
  id: string
  outletId: string
  receiptNumber: string
  totalAmount: number
  paymentStatus: string
  createdAt: string
  employeeName?: string
  outletName?: string
}

export interface LowStockAlert {
  productId: string
  productName: string
  currentStock: number
  minStockLevel: number
}
```

- [ ] **Step 2: Create base repository**
```typescript
// web/lib/database/repositories/supabase/base.repository.ts
import { createClientComponentClient } from '@supabase/auth-helpers-nextjs'
import type { Database } from '@/lib/types/database.types'

export abstract class SupabaseRepository {
  protected supabase = createClientComponentClient<Database>()
  protected userTier: 'free' | 'lite' | 'pro' = 'free'
  protected currentOutletId: string | null = null

  setTier(tier: 'free' | 'lite' | 'pro') {
    this.userTier = tier
  }

  setOutletId(outletId: string) {
    this.currentOutletId = outletId
  }
}
```

- [ ] **Step 3: Create repository factory**
```typescript
// web/lib/database/factory.ts
import { IAnalyticsRepository } from './interfaces/repository.interface'
import { SupabaseAnalyticsRepository } from './repositories/supabase/analytics.repository'

export class RepositoryFactory {
  static createAnalyticsRepository(): IAnalyticsRepository {
    return new SupabaseAnalyticsRepository()
  }
}
```

- [ ] **Step 4: Commit**
```bash
cd /Users/wahyukurnia/www/pos-saas/web
git add lib/database/
git commit -m "feat: implement repository pattern with interfaces"
```

---

## Phase 3: Analytics Repository Implementation (Week 3)

### Task 6: Supabase Analytics Repository
**Files:**
- Create: `web/lib/database/repositories/supabase/analytics.repository.ts`

- [ ] **Step 1: Implement repository**` || this.getDefaultSales()
  }

  async getSalesTrend(outletId: string, days: number): Promise<SalesTrend[]> {
    // MOCK: Return sample data
    const data: SalesTrend[] = []
    const today = new Date()
    
    for (let i = days - 1; i >= 0; i--) {
      const date = new Date(today)
      date.setDate(date.getDate() - i)
      
      data.push({
        date: date.toISOString().split('T')[0],
        totalSales: Math.floor(Math.random() * 2000000) + 500000,
        transactionCount: Math.floor(Math.random() * 50) + 10
      })
    }
    
    return data
  }

  async getTopProducts(outletId: string, limit: number): Promise<TopProduct[]> {
    // MOCK: Return sample data
    return [
      { productId: '1', productName: 'Kopi Latte', totalQuantity: 45, totalRevenue: 675000 },
      { productId: '2', productName: 'Nasi Goreng', totalQuantity: 32, totalRevenue: 640000 },
      { productId: '3', productName: 'Mie Goreng', totalQuantity: 28, totalRevenue: 420000 },
    ].slice(0, limit)
  }

  async getRecentTransactions(outletId: string, limit: number): Promise<Transaction[]> {
    // MOCK: Return sample data
    return [
      { 
        id: '1', 
        outletId: outletId, 
        receiptNumber: 'TRX-001', 
        totalAmount: 150000, 
        paymentStatus: 'paid',
        createdAt: new Date().toISOString()
      },
      { 
        id: '2', 
        outletId: outletId, 
        receiptNumber: 'TRX-002', 
        totalAmount: 235000, 
        paymentStatus: 'paid',
        createdAt: new Date(Date.now() - 3600000).toISOString()
      },
      { 
        id: '3', 
        outletId: outletId, 
        receiptNumber: 'TRX-003', 
        totalAmount: 89000, 
        paymentStatus: 'partial',
        createdAt: new Date(Date.now() - 7200000).toISOString()
      },
    ].slice(0, limit)
  }

  async getLowStockAlerts(outletId: string): Promise<LowStockAlert[]> {
    // MOCK: Return sample data
    return [
      { productId: '1', productName: 'Susu UHT 1L', currentStock: 3, minStockLevel: 10 },
      { productId: '2', productName: 'Kopi Bubuk 250g', currentStock: 2, minStockLevel: 5 },
    ]
  }

  private getDefaultSales(): TodaySales {
    return {
      totalAmount: 0,
      transactionCount: 0,
      averageOrderValue: 0,
      comparisonYesterday: 0,
      updatedAt: new Date().toISOString()
    }
  }
}
```

- [ ] **Step 2: Commit**
```bash
cd /Users/wahyukurnia/www/pos-saas/web
git add lib/database/repositories/supabase/analytics.repository.ts
git commit -m "feat: implement analytics repository with mock data"
```

---

## Phase 4: Supabase Integration (Week 3-4)

### Task 7: Setup Supabase Environment
**Files:**
- Create: `web/supabase/config.toml`

- [ ] **Step 1: Add package.json script**
```json
// Add to web/package.json scripts section:
"scripts": {
  "dev": "next dev",
  "build": "next build",
  "start": "next start",
  "lint": "next lint",
  "typegen": "npx supabase gen types typescript --project-id $NEXT_PUBLIC_SUPABASE_PROJECT_ID --schema public > lib/types/database.types.ts"
}
```

- [ ] **Step 2: Test Supabase connection**
```typescript
// web/lib/supabase/test.ts
import { createClient } from './client'

export async function testConnection() {
  const supabase = createClient()
  
  const { data, error } = await supabase
    .from('transactions')
    .select('count')
    .limit(1)
  
  if (error) {
    console.error('Supabase connection error:', error)
    return false
  }
  
  console.log('Supabase connected:', data)
  return true
}
```

- [ ] **Step 3: Commit**
```bash
cd /Users/wahyukurnia/www/pos-saas/web
git add package.json lib/supabase/
git commit -m "chore: setup supabase type generation"
```

### Task 8: Update Layout Files
**Files:**
- Create: `web/app/layout.tsx`
- Modify: `web/app/(marketing)/layout.tsx`
- Modify: `web/app/(dashboard)/layout.tsx`

- [ ] **Step 1: Create root layout**
```tsx
// web/app/layout.tsx
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "POSify - POS Online & Offline untuk UMKM",
  description: "Kelola bisnis UMKM Anda dengan lebih cepat menggunakan POSify. POS offline-first dengan manajemen cloud.",
  openGraph: {
    title: "POSify - POS Modern untuk UMKM",
    description: "Kelola bisnis Anda dengan lebih cepat",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="id">
      <body className={inter.className}>
        {children}
      </body>
    </html>
  );
}
```

- [ ] **Step 2: Create marketing layout**
```tsx
// web/app/(marketing)/layout.tsx
import { ReactQueryProvider } from '@/components/providers/react-query-provider'

export default function MarketingLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <ReactQueryProvider>
      <div className="min-h-screen">
        {children}
      </div>
    </ReactQueryProvider>
  )
}
```

- [ ] **Step 3: Create React Query Provider**
```tsx
// web/components/providers/react-query-provider.tsx
'use client'

import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { useState } from 'react'

export function ReactQueryProvider({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(() => new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 60 * 1000,
        refetchOnWindowFocus: false,
      },
    },
  }))

  return (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  )
}
```

- [ ] **Step 4: Commit**
```bash
cd /Users/wahyukurnia/www/pos-saas/web
git add app/layout.tsx app/(marketing)/layout.tsx app/(dashboard)/layout.tsx components/providers/
git commit -m "feat: setup React Query provider and marketing layout"
```

---

## Phase 5: Landing Page Sections (Week 4-5)

### Task 9: Marketing Components
**Files:**
- Create: Multiple files in `web/components/marketing/`
- Create: `web/app/(marketing)/page.tsx`

- [ ] **Step 1: Create Hero section**
```tsx
// web/components/marketing/hero.tsx
'use client'

import { Button } from '@/components/ui/button'
import Link from 'next/link'

export function Hero() {
  return (
    <section className="relative overflow-hidden bg-white py-20 lg:py-32">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center">
          <h1 className="text-4xl font-extrabold tracking-tight text-gray-900 sm:text-5xl md:text-6xl lg:text-7xl">
            Kelola Bisnis UMKM
            <span className="block text-indigo-600">Lebih Cepat</span>
          </h1>
          <p className="mx-auto mt-6 max-w-2xl text-lg text-gray-600">
            POS Online & Offline lengkap dengan manajemen multi-outlet. 
            Jualan di toko, di pasar, atau di manapun tetap tersinkronisasi.
          </p>
          <div className="mt-10 flex justify-center gap-4">
            <Link href="/login">
              <Button size="lg" className="bg-indigo-600 hover:bg-indigo-700">
                Coba Gratis
              </Button>
            </Link>
            <Link href="#features">
              <Button size="lg" variant="outline">
                Lihat Fitur
              </Button>
            </Link>
          </div>
        </div>
      </div>
    </section>
  )
}
```

- [ ] **Step 2: Create Features section**
```tsx
// web/components/marketing/features.tsx
'use client'

import { 
  ShoppingCart, 
  Users, 
  Package, 
  LineChart, 
  Store, 
  Receipt 
} from 'lucide-react'

const features = [
  {
    name: 'POS Offline-First',
    description: 'Jualan tanpa khawatir internet putus. Data tersinkron otomatis saat online.',
    icon: ShoppingCart,
  },
  {
    name: 'Multi-Outlet',
    description: 'Kelola banyak cabang dalam satu dashboard. Pantau performa seluruh outlet.',
    icon: Store,
  },
  {
    name: 'Analisis Real-time',
    description: 'Lihat penjualan hari ini, trending produk, dan laporan lengkap.',
    icon: LineChart,
  },
  {
    name: 'Manajemen Produk',
    description: 'Kelola ribuan produk dengan varian, resep, dan tracking stok.',
    icon: Package,
  },
  {
    name: 'Karyawan & Shift',
    description: 'Atur karyawan, kelola shift kasir, dan tracking performa.',
    icon: Users,
  },
  {
    name: 'Struk Digital',
    description: 'Cetak struk thermal atau kirim via WhatsApp. Custom template receipt.',
    icon: Receipt,
  },
]

export function Features() {
  return (
    <section id="features" className="bg-gray-50 py-24">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <h2 className="text-3xl font-bold text-gray-900 sm:text-4xl">
            Semua yang Anda Butuhkan
          </h2>
          <p className="mt-4 text-lg text-gray-600">
            Fitur lengkap untuk kelola bisnis retail dan F&B
          </p>
        </div>
        <div className="grid gap-8 md:grid-cols-2 lg:grid-cols-3">
          {features.map((feature) => (
            <div
              key={feature.name}
              className="relative rounded-2xl bg-white p-8 shadow-sm hover:shadow-md transition-shadow"
            >
              <div className="rounded-lg bg-indigo-50 w-12 h-12 flex items-center justify-center mb-4">
                <feature.icon className="w-6 h-6 text-indigo-600" />
              </div>
              <h3 className="text-lg font-semibold text-gray-900 mb-2">
                {feature.name}
              </h3>
              <p className="text-gray-600">{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
```

- [ ] **Step 3: Create Pricing section**
```tsx
// web/components/marketing/pricing.tsx
'use client'

import { Check } from 'lucide-react'
import { Button } from '@/components/ui/button'
import Link from 'next/link'

const tiers = [
  {
    name: 'Lite',
    price: '99.000',
    description: 'Cocok untuk toko kecil dan UMKM',
    features: [
      '1 Outlet',
      '1 Device',
      'Aplikasi Android & iOS',
      'Offline-first database',
      'Laporan dasar',
    ],
    cta: 'Mulai Lite',
    href: '/login?plan=lite',
  },
  {
    name: 'Pro',
    price: '299.000',
    description: 'Untuk bisnis berkembang dengan multi-outlet',
    features: [
      '3 Outlet',
      '10 Device',
      'Cloud sync real-time',
      'Dashboard web analytics',
      'Manajemen karyawan lengkap',
      'Support prioritas',
    ],
    cta: 'Mulai Pro',
    href: '/login?plan=pro',
    mostPopular: true,
  },
]

export function Pricing() {
  return (
    <section id="pricing" className="py-24 bg-white">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <h2 className="text-3xl font-bold text-gray-900 sm:text-4xl">
            Harga Sederhana
          </h2>
          <p className="mt-4 text-lg text-gray-600">
            Pilih tier yang sesuai. Upgrade kapan saja.
          </p>
        </div>
        <div className="grid md:grid-cols-2 gap-8 max-w-4xl mx-auto">
          {tiers.map((tier) => (
            <div
              key={tier.name}
              className={`rounded-2xl p-8 ${
                tier.mostPopular
                  ? 'bg-indigo-600 text-white ring-4 ring-indigo-100'
                  : 'bg-gray-50 text-gray-900'
              }`}
            >
              <div className="mb-6">
                <h3 className="text-2xl font-bold">{tier.name}</h3>
                <p className={`mt-2 text-sm ${tier.mostPopular ? 'text-indigo-100' : 'text-gray-600'}`}>
                  {tier.description}
                </p>
                <div className="mt-4">
                  <span className="text-4xl font-bold">Rp {tier.price}</span>
                  <span className="text-sm">/bulan</span>
                </div>
              </div>
              <ul className="space-y-4 mb-8">
                {tier.features.map((feature) => (
                  <li key={feature} className="flex items-start">
                    <Check className={`w-5 h-5 mr-3 flex-shrink-0 ${
                      tier.mostPopular ? 'text-indigo-200' : 'text-indigo-600'
                    }`} />
                    <span>{feature}</span>
                  </li>
                ))}
              </ul>
              <Link href={tier.href}>
                <Button 
                  className={`w-full ${
                    tier.mostPopular 
                      ? 'bg-white text-indigo-600 hover:bg-indigo-50' 
                      : 'bg-indigo-600 text-white hover:bg-indigo-700'
                  }`}
                >
                  {tier.cta}
                </Button>
              </Link>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
```

- [ ] **Step 4: Create Landing Page assembly**
```tsx
// web/app/(marketing)/page.tsx
import { Hero } from '@/components/marketing/hero'
import { Features } from '@/components/marketing/features'
import { Pricing } from '@/components/marketing/pricing'

export default function LandingPage() {
  return (
    <main>
      <Hero />
      <Features />
      <Pricing />
    </main>
  )
}
```

- [ ] **Step 5: Commit**
```bash
cd /Users/wahyukurnia/www/pos-saas/web
git add components/marketing/ app/(marketing)/page.tsx
git commit -m "feat: add marketing landing page with Hero, Features, Pricing"
```

---

*[Plan continues with Phase 6-12... run subagent-driven-development to execute tasks]*

---

## Plan Summary

**Total Tasks:** 12 phases, ~60 tasks  
**Estimated Duration:** 10-12 weeks (2 developers)  
**Critical Path:**
1. Week 1-2: Foundation + Landing Page
2. Week 3-4: Auth + Tier Control
3. Week 5-6: Dashboard Core
4. Week 7-8: Analytics Features
5. Week 9-10: Real-time Integration
6. Week 11-12: Testing & Polish

**Next:** Run `superpowers:subagent-driven-development` to execute task-by-task.
