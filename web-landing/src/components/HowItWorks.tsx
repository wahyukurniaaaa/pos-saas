import { useRef } from 'react'
import { motion, useInView } from 'framer-motion'

const steps = [
  {
    num: '01',
    title: 'Download & Aktivasi',
    desc: 'Unduh POSify, masukkan kode lisensi, dan atur nama toko serta PIN pemilik. Selesai dalam 3 menit.',
  },
  {
    num: '02',
    title: 'Tambah Produk',
    desc: 'Input produk secara manual atau import dari file CSV. Foto produk opsional — nama dan harga sudah cukup.',
  },
  {
    num: '03',
    title: 'Mulai Jualan',
    desc: 'Buka shift kasir, pilih produk, terima pembayaran, cetak struk. Setiap transaksi tercatat otomatis.',
  },
  {
    num: '04',
    title: 'Pantau dari Mana Saja',
    desc: 'Lihat laporan penjualan real-time, stok tersisa, dan kinerja kasir langsung dari smartphone Anda.',
  },
]

export default function HowItWorks() {
  const ref = useRef(null)
  const inView = useInView(ref, { once: true, margin: '-80px' })

  return (
    <section id="how-it-works" className="bg-brand-navy grain relative overflow-hidden py-24 px-6" ref={ref}>
      {/* Decorative large number */}
      <div className="absolute text-[20rem] font-display font-black text-white/[0.03] leading-none select-none pointer-events-none top-0 -right-12">
        HOW
      </div>

      <div className="relative z-10 max-w-7xl mx-auto">
        <div className="mb-16">
          <span className="section-tag mb-4 inline-block">Cara Kerja</span>
          <h2
            className="font-display font-black text-white leading-none tracking-tighter"
            style={{ fontSize: 'clamp(2rem, 4vw, 3.5rem)' }}
          >
            Mulai jualan dalam
            <br />
            <span className="text-brand-yellow">kurang dari 5 menit.</span>
          </h2>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-px bg-white/10">
          {steps.map((s, i) => (
            <motion.div
              key={s.num}
              className="bg-brand-navy p-7 group relative overflow-hidden"
              initial={{ opacity: 0, y: 30 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ delay: i * 0.12, duration: 0.55, ease: 'circOut' } as any}
            >
              {/* Background large step number */}
              <div className="absolute -bottom-4 -right-2 text-8xl font-display font-black text-white/5 select-none leading-none group-hover:text-brand-yellow/10 transition-colors">
                {s.num}
              </div>
              <div className="relative">
                <div className="w-10 h-10 bg-brand-yellow flex items-center justify-center font-display font-black text-brand-navy text-sm mb-5">
                  {s.num}
                </div>
                <h3 className="font-display font-bold text-white text-lg mb-3">{s.title}</h3>
                <p className="text-white/55 text-sm leading-relaxed">{s.desc}</p>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}
