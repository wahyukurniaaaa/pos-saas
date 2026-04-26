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
