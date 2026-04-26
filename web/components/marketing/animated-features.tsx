'use client'

import { motion } from 'framer-motion'
import { useInView } from 'framer-motion'
import { useRef } from 'react'
import {
  ShoppingCart,
  Users,
  Package,
  LineChart,
  Store,
  Receipt,
  Zap,
  Shield,
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

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
    },
  },
}

const itemVariants = {
  hidden: { opacity: 0, y: 40, scale: 0.9 },
  visible: {
    opacity: 1,
    y: 0,
    scale: 1,
    transition: {
      type: 'spring' as const,
      stiffness: 100,
      damping: 12,
    },
  },
}

export function AnimatedFeatures() {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true, margin: '-100px' })

  return (
    <section id="features" className="py-24 bg-gray-50 overflow-hidden">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <motion.span
            initial={{ opacity: 0, scale: 0.5 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            className="inline-block px-4 py-1.5 rounded-full bg-indigo-100 text-indigo-700 text-sm font-semibold mb-4"
          >
            Fitur Lengkap
          </motion.span>
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-gray-900">
            Semua yang Anda Butuhkan
          </h2>
          <p className="mt-4 text-lg text-gray-600 max-w-2xl mx-auto">
            Fitur lengkap untuk kelola bisnis retail dan F&B dengan mudah
          </p>
        </motion.div>

        <motion.div
          ref={ref}
          variants={containerVariants}
          initial="hidden"
          animate={isInView ? 'visible' : 'hidden'}
          className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3"
        >
          {features.map((feature, index) => (
            <motion.div
              key={feature.name}
              variants={itemVariants}
              whileHover={{
                y: -8,
                scale: 1.02,
                transition: { type: 'spring' as const, stiffness: 300 },
              }}
              className="group relative bg-white rounded-2xl p-6 sm:p-8 shadow-sm hover:shadow-xl transition-all duration-300 border border-gray-100"
            >
              <motion.div
                className={`absolute inset-0 rounded-2xl bg-gradient-to-br from-${feature.color.replace('bg-', '')} to-purple-600 opacity-0 group-hover:opacity-5 transition-opacity duration-300`}
              />

              <div className="relative">
                <motion.div
                  whileHover={{ rotate: 360, scale: 1.1 }}
                  transition={{ duration: 0.5 }}
                  className={`w-14 h-14 rounded-xl ${feature.color} flex items-center justify-center mb-6 group-hover:shadow-lg group-hover:shadow-${feature.color.replace('bg-', '')}/30 transition-shadow`}
                >
                  <feature.icon className="w-7 h-7 text-white" />
                </motion.div>

                <h3 className="text-xl font-semibold text-gray-900 mb-3 group-hover:text-indigo-600 transition-colors">
                  {feature.name}
                </h3>
                <p className="text-gray-600 leading-relaxed">
                  {feature.description}
                </p>

                <motion.div
                  initial={{ opacity: 0, x: -10 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.2 }}
                  className="mt-6 flex items-center text-indigo-600 font-medium text-sm opacity-0 group-hover:opacity-100 transition-opacity"
                >
                  <Zap className="w-4 h-4 mr-2" />
                  Coba Fitur Ini
                </motion.div>
              </div>

              {/* Hover gradient border effect */}
              <div className="absolute inset-0 rounded-2xl border-2 border-transparent group-hover:border-indigo-100 transition-colors duration-300 pointer-events-none" />
            </motion.div>
          ))}
        </motion.div>

        {/* Stats Section */}
        <motion.div
          initial={{ opacity: 0, y: 40 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ delay: 0.4 }}
          className="mt-20 grid grid-cols-2 sm:grid-cols-4 gap-8"
        >
          {[
            { label: 'Business Owners', value: '10,000+' },
            { label: 'Daily Transactions', value: '500K+' },
            { label: 'Uptime', value: '99.9%' },
            { label: 'Customer Rating', value: '4.9/5' },
          ].map((stat, index) => (
            <motion.div
              key={stat.label}
              initial={{ opacity: 0, scale: 0.5 }}
              whileInView={{ opacity: 1, scale: 1 }}
              viewport={{ once: true }}
              transition={{ delay: 0.1 * index, type: 'spring' as const }}
              className="text-center"
            >
              <div className="text-3xl sm:text-4xl font-bold text-indigo-600">
                {stat.value}
              </div>
              <div className="mt-2 text-sm text-gray-600">{stat.label}</div>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  )
}
