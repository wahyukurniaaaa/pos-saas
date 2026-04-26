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
