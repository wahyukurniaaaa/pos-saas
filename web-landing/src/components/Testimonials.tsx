import { useRef } from 'react'
import { motion, useInView } from 'framer-motion'
import { Star } from 'lucide-react'

const testimonials = [
  {
    name: 'Budi Santoso',
    role: 'Pemilik Warung Makan',
    location: 'Bandung, Jabar',
    text: 'Dulu laporan keuangan saya hanya dari ingatan kasir. Sekarang semua terpantau real-time. Omzet naik 25% dalam 3 bulan!',
    rating: 5,
    size: 'col-span-2',
  },
  {
    name: 'Dewi Lestari',
    role: 'Owner Kedai Kopi',
    location: 'Yogyakarta',
    text: 'POSify mudah banget buat kasir baru. Pelatihan cuma 10 menit dan langsung bisa jalan. Luar biasa!',
    rating: 5,
    size: '',
  },
  {
    name: 'Rizky Pratama',
    role: 'Manajer Toko Kelontong',
    location: 'Surabaya, Jatim',
    text: 'Fitur notifikasi stok menipis yang paling berguna buat saya. Tidak ada lagi kehabisan barang saat ramai.',
    rating: 5,
    size: '',
  },
  {
    name: 'Sinta Wulandari',
    role: 'Pemilik Boutique Fashion',
    location: 'Jakarta Selatan',
    text: 'Shift management dan multi-kasir beda peran adalah fitur yang saya cari-cari selama ini. Akhirnya ketemu!',
    rating: 5,
    size: '',
  },
  {
    name: 'Hendra Wijaya',
    role: 'Franchisee Bakso Pak Min',
    location: 'Semarang, Jateng',
    text: 'Punya 3 cabang sekarang jadi jauh lebih mudah dikontrol. Laporan per shift langsung bisa saya bandingkan.',
    rating: 5,
    size: 'col-span-2',
  },
]

export default function Testimonials() {
  const ref = useRef(null)
  const inView = useInView(ref, { once: true, margin: '-80px' })

  return (
    <section id="testimonials" className="bg-bg-light py-24 px-6" ref={ref}>
      <div className="max-w-7xl mx-auto">
        <div className="mb-16">
          <span className="section-tag mb-4 inline-block">Testimoni</span>
          <h2
            className="font-display font-black text-text-primary leading-none tracking-tighter"
            style={{ fontSize: 'clamp(2rem, 4vw, 3.5rem)' }}
          >
            Dipercaya ribuan{' '}
            <span className="text-brand-navy">pemilik UMKM</span>
            <br />
            di seluruh Indonesia.
          </h2>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-px bg-border">
          {testimonials.map((t, i) => (
            <motion.div
              key={t.name}
              className={`bg-white p-6 ${t.size} group hover:-translate-y-1 hover:shadow-xl transition-all duration-300 relative`}
              initial={{ opacity: 0, y: 24 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ delay: i * 0.1, duration: 0.5, ease: 'circOut' } as any}
            >
              {/* Yellow top bar on hover */}
              <div className="absolute top-0 left-0 w-0 h-1 bg-brand-yellow group-hover:w-full transition-all duration-500" />

              {/* Stars */}
              <div className="flex gap-0.5 mb-4">
                {Array.from({ length: t.rating }).map((_, j) => (
                  <Star key={j} size={13} className="fill-brand-yellow text-brand-yellow" />
                ))}
              </div>

              <p className="text-text-primary text-sm leading-relaxed mb-6">"{t.text}"</p>

              <div className="flex items-center gap-3 mt-auto">
                <div className="w-9 h-9 bg-brand-navy flex items-center justify-center text-brand-yellow font-bold text-sm shrink-0">
                  {t.name[0]}
                </div>
                <div>
                  <div className="font-bold text-text-primary text-sm">{t.name}</div>
                  <div className="text-text-secondary text-xs">
                    {t.role} · {t.location}
                  </div>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}
