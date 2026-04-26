'use client'

import { motion } from 'framer-motion'
import { Button } from '@/components/ui/button'
import Link from 'next/link'
import { ArrowRight, Smartphone, TrendingUp, Shield } from 'lucide-react'

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.2,
      delayChildren: 0.3,
    },
  },
}

const itemVariants = {
  hidden: { opacity: 0, y: 30 },
  visible: {
    opacity: 1,
    y: 0,
    transition: {
      type: 'spring',
      stiffness: 100,
      damping: 12,
    },
  },
}

const floatAnimation = {
  y: [-10, 10, -10],
  transition: {
    duration: 6,
    repeat: Infinity,
    ease: 'easeInOut',
  },
}

const pulseAnimation = {
  scale: [1, 1.05, 1],
  transition: {
    duration: 2,
    repeat: Infinity,
    ease: 'easeInOut',
  },
}

export function AnimatedHero() {
  return (
    <section className="relative overflow-hidden bg-white min-h-screen flex items-center">
      {/* Animated Background */}
      <div className="absolute inset-0 overflow-hidden">
        <motion.div
          className="absolute -top-40 -right-40 w-80 h-80 bg-indigo-100 rounded-full mix-blend-multiply opacity-70 blur-3xl"
          animate={{
            x: [0, 50, 0],
            y: [0, 30, 0],
            scale: [1, 1.1, 1],
          }}
          transition={{
            duration: 8,
            repeat: Infinity,
            ease: 'easeInOut',
          }}
        />
        <motion.div
          className="absolute -bottom-40 -left-40 w-80 h-80 bg-purple-100 rounded-full mix-blend-multiply opacity-70 blur-3xl"
          animate={{
            x: [0, -30, 0],
            y: [0, 50, 0],
            scale: [1, 1.2, 1],
          }}
          transition={{
            duration: 10,
            repeat: Infinity,
            ease: 'easeInOut',
          }}
        />
      </div>

      <div className="container mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          {/* Left Content */}
          <motion.div
            variants={containerVariants}
            initial="hidden"
            animate="visible"
            className="text-center lg:text-left"
          >
            <motion.div
              variants={itemVariants}
              className="inline-flex items-center px-4 py-2 rounded-full bg-indigo-50 text-indigo-600 text-sm font-medium mb-6"
            >
              <span className="flex h-2 w-2 rounded-full bg-indigo-600 mr-2 animate-pulse" />
              POSify v2.0 is live
            </motion.div>

            <motion.h1
              variants={itemVariants}
              className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-extrabold tracking-tight text-gray-900"
            >
              Kelola Bisnis{' '}
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-indigo-600 to-purple-600">
                Lebih Cepat
              </span>
            </motion.h1>

            <motion.p
              variants={itemVariants}
              className="mt-6 text-base sm:text-lg text-gray-600 max-w-2xl mx-auto lg:mx-0"
            >
              POS Online & Offline lengkap dengan manajemen multi-outlet.
              Jualan di toko, di pasar, atau di manapun tetap tersinkronisasi.
            </motion.p>

            <motion.div
              variants={itemVariants}
              className="mt-8 flex flex-col sm:flex-row gap-4 justify-center lg:justify-start"
            >
              <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
                <Link href="/login">
                  <Button
                    size="lg"
                    className="bg-indigo-600 hover:bg-indigo-700 text-white px-8 py-6 text-base rounded-full group"
                  >
                    Coba Gratis
                    <ArrowRight className="ml-2 h-4 w-4 group-hover:translate-x-1 transition-transform" />
                  </Button>
                </Link>
              </motion.div>

              <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
                <Link href="#features">
                  <Button
                    size="lg"
                    variant="outline"
                    className="px-8 py-6 text-base rounded-full"
                  >
                    Lihat Fitur
                  </Button>
                </Link>
              </motion.div>
            </motion.div>

            {/* Stats */}
            <motion.div
              variants={itemVariants}
              className="mt-12 grid grid-cols-3 gap-8 border-t border-gray-100 pt-8"
            >
              {[
                { label: 'Pengguna Aktif', value: '10K+' },
                { label: 'Transaksi/Hari', value: '500K+' },
                { label: 'Rating', value: '4.9' },
              ].map((stat) => (
                <div key={stat.label} className="text-center">
                  <div className="text-2xl sm:text-3xl font-bold text-indigo-600">
                    {stat.value}
                  </div>
                  <div className="text-xs sm:text-sm text-gray-600 mt-1">
                    {stat.label}
                  </div>
                </div>
              ))}
            </motion.div>
          </motion.div>

          {/* Right Content - Animated Mockup */}
          <motion.div
            initial={{ opacity: 0, x: 100 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.8, delay: 0.5 }}
            className="hidden lg:block relative"
          >
            <motion.div
              className="relative z-10"
              animate={floatAnimation}
            >
              {/* Main Phone Mockup */}
              <div className="relative mx-auto w-72 h-[580px] bg-gray-900 rounded-[3rem] border-8 border-gray-800 shadow-2xl overflow-hidden">
                {/* Screen */}
                <div className="w-full h-full bg-white rounded-[2.5rem] overflow-hidden">
                  {/* Mock App Header */}
                  <div className="bg-indigo-600 h-24 p-4 flex items-end">
                    <div className="text-white">
                      <p className="text-xs opacity-80">Penjualan Hari Ini</p>
                      <p className="text-2xl font-bold">Rp 2.450.000</p>
                    </div>
                  </div>

                  {/* Mock Content */}
                  <div className="p-4 space-y-3">
                    {[1, 2, 3].map((i) => (
                      <motion.div
                        key={i}
                        className="bg-gray-50 rounded-lg p-3 flex items-center justify-between"
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ delay: 1 + i * 0.2 }}
                      >
                        <div className="flex items-center space-x-3">
                          <div className="w-10 h-10 bg-indigo-100 rounded-lg flex items-center justify-center">
                            <TrendingUp className="w-5 h-5 text-indigo-600" />
                          </div>
                          <div>
                            <p className="text-sm font-medium text-gray-900">Transaksi TRX-{100 + i}</p>
                            <p className="text-xs text-gray-500">{10 + i}:30 AM</p>
                          </div>
                        </div>
                        <p className="text-sm font-semibold text-indigo-600">
                          Rp {(150000 + i * 50000).toLocaleString()}
                        </p>
                      </motion.div>
                    ))}
                  </div>
                </div>

                {/* Notch */}
                <div className="absolute top-4 left-1/2 transform -translate-x-1/2 w-32 h-6 bg-gray-800 rounded-full" />
              </div>

              {/* Floating Cards */}
              <motion.div
                className="absolute -left-8 top-20 bg-white rounded-xl shadow-lg p-3 flex items-center space-x-2"
                initial={{ opacity: 0, scale: 0 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 1.5, type: 'spring' }}
                whileHover={{ scale: 1.1 }}
              >
                <div className="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center">
                  <Shield className="w-5 h-5 text-green-600" />
                </div>
                <div>
                  <p className="text-xs text-gray-500">Status</p>
                  <p className="text-sm font-semibold text-green-600">Online</p>
                </div>
              </motion.div>

              <motion.div
                className="absolute -right-4 bottom-32 bg-white rounded-xl shadow-lg p-3 flex items-center space-x-2"
                initial={{ opacity: 0, scale: 0 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 1.8, type: 'spring' }}
                whileHover={{ scale: 1.1 }}
              >
                <div className="w-10 h-10 bg-indigo-100 rounded-full flex items-center justify-center">
                  <Smartphone className="w-5 h-5 text-indigo-600" />
                </div>
                <div>
                  <p className="text-xs text-gray-500">Devices</p>
                  <p className="text-sm font-semibold text-indigo-600">3 Connected</p>
                </div>
              </motion.div>
            </motion.div>
          </motion.div>

          {/* Mobile/Tablet Only - Simplified Visual */}
          <motion.div
            initial={{ opacity: 0, y: 50 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.8 }}
            className="lg:hidden flex justify-center mt-8"
          >
            <motion.div
              className="bg-gradient-to-br from-indigo-500 to-purple-600 rounded-3xl p-8 shadow-2xl max-w-sm"
              animate={pulseAnimation}
            >
              <div className="text-white text-center">
                <h3 className="text-2xl font-bold mb-2">POSify Mobile</h3>
                <p className="text-indigo-100 text-sm">
                  Jualan di mana saja, tetap tersinkronisasi dengan cloud
                </p>
              </div>
            </motion.div>
          </motion.div>
        </div>
      </div>

      {/* Scroll Indicator */}
      <motion.div
        className="absolute bottom-8 left-1/2 transform -translate-x-1/2"
        animate={{ y: [0, 10, 0] }}
        transition={{ duration: 1.5, repeat: Infinity }}
      >
        <div className="w-6 h-10 border-2 border-gray-300 rounded-full flex justify-center pt-2">
          <motion.div
            className="w-1.5 h-3 bg-indigo-600 rounded-full"
            animate={{ y: [0, 12, 0] }}
            transition={{ duration: 1.5, repeat: Infinity }}
          />
        </div>
      </motion.div>
    </section>
  )
}
