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
