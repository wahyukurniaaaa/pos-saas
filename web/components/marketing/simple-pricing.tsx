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
      'Priority Support',
    ],
    cta: 'Mulai Pro',
    href: '/login?plan=pro',
    popular: true,
  },
]

export function SimplePricing() {
  return (
    <section id="pricing" className="py-24 bg-white">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <span className="inline-block px-4 py-1.5 rounded-full bg-indigo-100 text-indigo-700 text-sm font-semibold mb-4">
            Pricing
          </span>
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-gray-900">
            Harga Sederhana
          </h2>
          <p className="mt-4 text-lg text-gray-600 max-w-2xl mx-auto">
            Pilih tier yang sesuai. Upgrade kapan saja.
          </p>
        </motion.div>

        <div className="grid md:grid-cols-2 gap-8 max-w-4xl mx-auto">
          {tiers.map((tier, index) => (
            <motion.div
              key={tier.name}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: index * 0.2 }}
              whileHover={{ y: -8 }}
              className={`rounded-3xl p-8 ${
                tier.popular
                  ? 'bg-gradient-to-br from-indigo-600 to-purple-600 text-white'
                  : 'bg-gray-50 text-gray-900 border border-gray-100'
              }`}
            >
              {tier.popular && (
                <div className="mb-4">
                  <span className="bg-white text-indigo-600 px-3 py-1 rounded-full text-sm font-semibold flex items-center gap-1">
                    <Sparkles className="w-4 h-4" />
                    Most Popular
                  </span>
                </div>
              )}

              <div className={`w-12 h-12 rounded-xl ${
                tier.popular ? 'bg-white/20' : 'bg-indigo-100'
              } flex items-center justify-center mb-6`}>
                <tier.icon className={`w-6 h-6 ${tier.popular ? 'text-white' : 'text-indigo-600'}`} />
              </div>

              <div className="mb-8">
                <h3 className="text-2xl font-bold">{tier.name}</h3>
                <p className={`mt-2 text-sm ${tier.popular ? 'text-indigo-100' : 'text-gray-500'}`}>
                  {tier.description}
                </p>
                <div className="mt-4">
                  <span className="text-4xl sm:text-5xl font-bold">Rp {tier.price}</span>
                  <span className={`text-sm ${tier.popular ? 'text-indigo-200' : 'text-gray-500'}`}>
                    /bulan
                  </span>
                </div>
              </div>

              <ul className="space-y-4 mb-8">
                {tier.features.map((feature) => (
                  <li key={feature} className="flex items-start">
                    <div className={`flex-shrink-0 w-5 h-5 rounded-full ${
                      tier.popular ? 'bg-white/20' : 'bg-indigo-100'
                    } flex items-center justify-center mr-3 mt-0.5`}>
                      <Check className={`w-3 h-3 ${tier.popular ? 'text-white' : 'text-indigo-600'}`} />
                    </div>
                    <span className={`text-sm ${tier.popular ? 'text-white/90' : 'text-gray-600'}`}>
                      {feature}
                    </span>
                  </li>
                ))}
              </ul>

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
          ))}
        </div>
      </div>
    </section>
  )
}
