'use client'

import { motion } from 'framer-motion'
import {
  ShoppingCart,
  Users,
  Package,
  LineChart,
  Store,
  Cloud,
} from 'lucide-react'

const features = [
  {
    name: 'POS Offline-First',
    description: 'Jualan tanpa khawatir internet putus. Data tersinkron otomatis saat online.',
    icon: ShoppingCart,
    color: 'bg-blue-500',
  },
  {
    name: 'Multi-Outlet',
    description: 'Kelola banyak cabang dalam satu dashboard. Pantau performa seluruh outlet.',
    icon: Store,
    color: 'bg-purple-500',
  },
  {
    name: 'Analisis Real-time',
    description: 'Lihat penjualan hari ini, trending produk, dan laporan lengkap.',
    icon: LineChart,
    color: 'bg-green-500',
  },
  {
    name: 'Manajemen Produk',
    description: 'Kelola ribuan produk dengan varian, resep, dan tracking stok.',
    icon: Package,
    color: 'bg-orange-500',
  },
  {
    name: 'Karyawan & Shift',
    description: 'Atur karyawan, kelola shift kasir, dan tracking performa.',
    icon: Users,
    color: 'bg-pink-500',
  },
  {
    name: 'Cloud Backup',
    description: 'Data tersimpan aman di cloud. Akses dari mana saja, kapan saja.',
    icon: Cloud,
    color: 'bg-indigo-500',
  },
]

export function SimpleFeatures() {
  return (
    <section id="features" className="py-24 bg-gray-50">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <span className="inline-block px-4 py-1.5 rounded-full bg-indigo-100 text-indigo-700 text-sm font-semibold mb-4">
            Fitur Lengkap
          </span>
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-gray-900">
            Semua yang Anda Butuhkan
          </h2>
          <p className="mt-4 text-lg text-gray-600 max-w-2xl mx-auto">
            Fitur lengkap untuk kelola bisnis retail dan F&B dengan mudah
          </p>
        </motion.div>

        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {features.map((feature, index) => (
            <motion.div
              key={feature.name}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
              whileHover={{ y: -8, scale: 1.02 }}
              className="group bg-white rounded-2xl p-6 sm:p-8 shadow-sm hover:shadow-xl transition-all duration-300 border border-gray-100"
            >
              <div className={`w-14 h-14 rounded-xl ${feature.color} flex items-center justify-center mb-6`}>
                <feature.icon className="w-7 h-7 text-white" />
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-3">
                {feature.name}
              </h3>
              <p className="text-gray-600">
                {feature.description}
              </p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}
