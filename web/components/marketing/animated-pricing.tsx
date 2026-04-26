'use client'

import { motion } from 'framer-motion'
import { Check, Sparkles, Zap } from 'lucide-react'
import { Button } from '@/components/ui/button'
import Link from 'next/link'

const tiers = [
  {
    name: 'Lite',
    price: '99.000',
    description: 'Cocok untuk toko kecil dan UMKM',
    icon: Zap,
    features: [
      '1 Outlet',
      '1 Device',
      'Aplikasi Android & iOS',
      'Offline-first database',
      'Laporan dasar',
      'Support email',
    ],
    cta: 'Mulai Lite',
    href: '/login?plan=lite',
    popular: false,
  },
  {
    name: 'Pro',
    price: '299.000',
    description: 'Untuk bisnis berkembang dengan multi-outlet',
    icon: Sparkles,
    features: [
      '3 Outlet',
      '10 Device',
      'Cloud sync real-time',
      'Dashboard web analytics',
      'Manajemen karyawan lengkap',
      'Priority Support 24/7',
      'Backup otomatis',
      'Integrasi marketplace',
    ],
    cta: 'Mulai Pro',
    href: '/login?plan=pro',
    popular: true,
  },
]

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.2,
    },
  },
}

const itemVariants = {
  hidden: { opacity: 0, y: 50 },
  visible: {
    opacity: 1,
    y: 0,
    transition: {
      type: 'spring' as const,
      stiffness: 100,
      damping: 12,
    },
  },
}

export function AnimatedPricing() {
  return (
    <section id="pricing" className="py-24 bg-white overflow-hidden">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.5 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            className="inline-flex items-center px-4 py-1.5 rounded-full bg-indigo-100 text-indigo-700 text-sm font-semibold mb-4"
          >
            Pricing
          </motion.div>
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-gray-900">
            Harga Sederhana
          </h2>
          <p className="mt-4 text-lg text-gray-600 max-w-2xl mx-auto">
            Pilih tier yang sesuai. Upgrade kapan saja.
          </p>
        </motion.div>

        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: '-100px' }}
          className="grid md:grid-cols-2 gap-8 max-w-4xl mx-auto"
        >
          {tiers.map((tier) => (
            <motion.div
              key={tier.name}
              variants={itemVariants}
              whileHover={{
                y: -12,
                transition: { type: 'spring' as const, stiffness: 300 },
              }}
              className={`relative rounded-3xl p-8 ${
                tier.popular
                  ? 'bg-gradient-to-br from-indigo-600 to-purple-600 text-white shadow-2xl shadow-indigo-500/25'
                  : 'bg-gray-50 text-gray-900 border border-gray-100'
              }`}
            >
              {/* Popular Badge */}
              {tier.popular && (
                <motion.div
                  initial={{ opacity: 0, scale: 0 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ delay: 0.5, type: 'spring' as const }}
                  className="absolute -top-4 left-1/2 transform -translate-x-1/2"
                >
                  <div className="bg-white text-indigo-600 px-4 py-1 rounded-full text-sm font-semibold shadow-lg flex items-center">
                    <Sparkles className="w-4 h-4 mr-1" />
                    Most Popular
                  </div>
                </motion.div>
              )}

              {/* Icon */}
              <div
                className={`w-12 h-12 rounded-xl ${
                  tier.popular ? 'bg-white/20' : 'bg-indigo-100'
                } flex items-center justify-center mb-6`}
              >
                <tier.icon
                  className={`w-6 h-6 ${tier.popular ? 'text-white' : 'text-indigo-600'}`}
                />
              </div>

              {/* Header */}
              <div className="mb-8">
                <h3 className="text-2xl font-bold">{tier.name}</h3>
                <p
                  className={`mt-2 text-sm ${
                    tier.popular ? 'text-indigo-100' : 'text-gray-500'
                  }`}
                >
                  {tier.description}
                </p>
                <div className="mt-4 flex items-baseline">
                  <span className="text-4xl sm:text-5xl font-bold">Rp {tier.price}</span>
                  <span
                    className={`ml-2 text-sm ${
                      tier.popular ? 'text-indigo-200' : 'text-gray-500'
                    }`}
                  >
                    /bulan
                  </span>
                </div>
              </div>

              {/* Features */}
              <ul className="space-y-4 mb-8">
                {tier.features.map((feature, index) => (
                  <motion.li
                    key={feature}
                    initial={{ opacity: 0, x: -10 }}
                    whileInView={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.1 * index }}
                    className="flex items-start"
                  >
                    <div
                      className={`flex-shrink-0 w-5 h-5 rounded-full ${
                        tier.popular ? 'bg-white/20' : 'bg-indigo-100'
                      } flex items-center justify-center mr-3 mt-0.5`}
                    >
                      <Check
                        className={`w-3 h-3 ${
                          tier.popular ? 'text-white' : 'text-indigo-600'
                        }`}
                      />
                    </div>
                    <span
                      className={`text-sm ${
                        tier.popular ? 'text-white/90' : 'text-gray-600'
                      }`}
                    >
                      {feature}
                    </span>
                  </motion.li>
                ))}
              </ul>

              {/* CTA Button */}
              <motion.div whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}>
                <Link href={tier.href}>
                  <Button
                    className={`w-full py-6 text-base font-semibold rounded-xl ${
                      tier.popular
                        ? 'bg-white text-indigo-600 hover:bg-gray-100'
                        : 'bg-indigo-600 text-white hover:bg-indigo-700'
                    }`}
                  >
                    {tier.cta}
                  </Button>
                </Link>
              </motion.div>
            </motion.div>
          ))}
        </motion.div>

        {/* Trust Badges */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ delay: 0.6 }}
          className="mt-16 text-center"
        >
          <p className="text-gray-500 text-sm mb-4">Dipercaya oleh 10,000+ pengusaha</p>
          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            transition={{ delay: 0.8 }}
            className="flex justify-center space-x-8 opacity-50"
          >
            {['Tokopedia', 'Shopee', 'Bukalapak', 'Grab'].map((brand, index) => (
              <motion.span
                key={brand}
                initial={{ opacity: 0, y: 10 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.1 * index }}
                className="text-gray-400 font-semibold"
              >
                {brand}
              </motion.span>
            ))}
          </motion.div>
        </motion.div>
      </div>
    </section>
  )
}
