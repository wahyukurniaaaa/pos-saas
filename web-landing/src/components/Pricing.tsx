import { useRef } from 'react'
import { motion, useInView } from 'framer-motion'
import { Check, ArrowRight } from 'lucide-react'

const plans = [
  {
    name: 'Starter',
    price: 'Gratis',
    period: 'selamanya',
    desc: 'Sempurna untuk warung dan toko kecil yang baru memulai.',
    features: [
      '1 kasir',
      'Maks. 50 produk',
      'Laporan harian dasar',
      'Cetak struk termal',
      'Data offline',
    ],
    cta: 'Mulai Gratis',
    highlight: false,
  },
  {
    name: 'Pro',
    price: 'Rp 99.000',
    period: 'per bulan',
    desc: 'Untuk UMKM yang ingin tumbuh dengan fitur lengkap dan multi-kasir.',
    features: [
      'Kasir tidak terbatas',
      'Produk tidak terbatas',
      'Laporan analytics lengkap',
      'Manajemen shift',
      'Import produk CSV',
      'Manajemen stok otomatis',
      'VOID transaksi',
      'Support prioritas',
    ],
    cta: 'Coba Pro 30 Hari Gratis',
    highlight: true,
  },
  {
    name: 'Enterprise',
    price: 'Custom',
    period: 'hubungi kami',
    desc: 'Solusi skala besar untuk franchise dan jaringan toko multi-cabang.',
    features: [
      'Semua fitur Pro',
      'Multi-cabang dashboard',
      'Integrasi API custom',
      'Pelatihan onsite',
      'SLA 99.9% uptime',
      'Dedicated support',
    ],
    cta: 'Hubungi Sales',
    highlight: false,
  },
]

export default function Pricing() {
  const ref = useRef(null)
  const inView = useInView(ref, { once: true, margin: '-80px' })

  return (
    <section id="pricing" className="bg-bg-dark grain py-24 px-6 relative overflow-hidden" ref={ref}>
      <div className="absolute top-0 left-0 w-px h-full bg-white/10" aria-hidden />
      <div className="absolute top-0 right-1/3 w-px h-full bg-white/5" aria-hidden />

      <div className="relative z-10 max-w-7xl mx-auto">
        <div className="mb-16">
          <span className="section-tag mb-4 inline-block">Harga</span>
          <h2
            className="font-display font-black text-white leading-none tracking-tighter"
            style={{ fontSize: 'clamp(2rem, 4vw, 3.5rem)' }}
          >
            Harga transparan,{' '}
            <span className="text-brand-yellow">tanpa kejutan.</span>
          </h2>
          <p className="text-white/50 mt-4 text-base max-w-xl">
            Mulai gratis, upgrade kapan saja. Tidak ada kontrak, tidak ada biaya tersembunyi.
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-px bg-white/10">
          {plans.map((plan, i) => (
            <motion.div
              key={plan.name}
              className={`relative p-8 flex flex-col ${
                plan.highlight ? 'bg-brand-yellow' : 'bg-bg-dark'
              }`}
              initial={{ opacity: 0, y: 28 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ delay: i * 0.1, duration: 0.55, ease: 'circOut' } as any}
            >
              {plan.highlight && (
                <div className="absolute -top-4 left-8 bg-brand-navy text-brand-yellow text-xs font-black px-3 py-1 uppercase tracking-widest">
                  Paling Populer
                </div>
              )}

              <div className={`text-xs font-bold uppercase tracking-widest mb-2 ${
                plan.highlight ? 'text-brand-navy/60' : 'text-white/40'
              }`}>
                {plan.name}
              </div>

              <div className={`font-display font-black leading-none mb-1 ${
                plan.highlight ? 'text-brand-navy' : 'text-white'
              }`} style={{ fontSize: 'clamp(1.8rem, 3vw, 2.5rem)' }}>
                {plan.price}
              </div>
              <div className={`text-sm mb-4 ${plan.highlight ? 'text-brand-navy/60' : 'text-white/40'}`}>
                {plan.period}
              </div>

              <p className={`text-sm leading-relaxed mb-8 ${
                plan.highlight ? 'text-brand-navy/70' : 'text-white/50'
              }`}>
                {plan.desc}
              </p>

              <ul className="flex flex-col gap-3 mb-10 flex-1">
                {plan.features.map((f) => (
                  <li key={f} className="flex items-start gap-2.5">
                    <Check
                      size={14}
                      className={`mt-0.5 shrink-0 ${plan.highlight ? 'text-brand-navy' : 'text-brand-yellow'}`}
                    />
                    <span className={`text-sm ${plan.highlight ? 'text-brand-navy' : 'text-white/70'}`}>
                      {f}
                    </span>
                  </li>
                ))}
              </ul>

              <a
                href="#"
                className={`inline-flex items-center justify-center gap-2 font-bold py-3.5 px-6 text-sm transition-all duration-200 hover:gap-4 ${
                  plan.highlight
                    ? 'bg-brand-navy text-brand-yellow hover:bg-brand-navy-dark'
                    : 'border border-white/20 text-white hover:bg-white/10'
                }`}
              >
                {plan.cta} <ArrowRight size={14} />
              </a>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}
