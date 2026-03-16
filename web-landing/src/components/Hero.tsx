import { motion } from 'framer-motion'
import { ArrowRight, CheckCircle } from 'lucide-react'

const floatingCard = {
  hidden: { opacity: 0, y: 30, scale: 0.9 },
  show: (i: number) => ({
    opacity: 1,
    y: 0,
    scale: 1,
    transition: { delay: i * 0.15 + 0.5, duration: 0.6, ease: 'circOut' },
  }),
} as const

const stats = [
  { value: '10.000+', label: 'UMKM Aktif' },
  { value: '99.9%', label: 'Uptime' },
  { value: 'Rp 0', label: 'Biaya Setup' },
]

const checks = ['Tanpa perangkat khusus', 'Data 100% aman & terenkripsi', 'Support 24/7']

export default function Hero() {
  return (
    <section className="relative min-h-screen bg-bg-dark grain overflow-hidden flex flex-col justify-center pt-20">
      {/* Background accent lines */}
      <div className="absolute inset-0 pointer-events-none" aria-hidden>
        <div className="absolute top-0 left-1/3 w-px h-full bg-white/5" />
        <div className="absolute top-0 right-1/3 w-px h-full bg-white/5" />
        <div className="absolute top-1/3 left-0 w-full h-px bg-white/5" />
      </div>

      {/* Big angled yellow block */}
      <div
        className="absolute -right-20 top-0 w-[45%] h-full bg-brand-navy/60 border-l border-white/10"
        style={{ clipPath: 'polygon(15% 0, 100% 0, 100% 100%, 0% 100%)' }}
        aria-hidden
      />
      <div
        className="absolute -right-20 top-0 w-[44%] h-full bg-brand-cornflower/10"
        style={{ clipPath: 'polygon(15% 0, 100% 0, 100% 100%, 0% 100%)' }}
        aria-hidden
      />

      <div className="relative z-10 max-w-7xl mx-auto px-6 py-20 grid lg:grid-cols-2 gap-12 items-center">
        {/* LEFT: Text */}
        <div>
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.5 }}
          >
            <span className="section-tag mb-6 inline-block">Kasir Digital #1 untuk UMKM</span>
          </motion.div>

          <motion.h1
            className="font-display font-black text-white leading-none tracking-tighter mb-6"
            style={{ fontSize: 'clamp(2.8rem, 6vw, 5.5rem)' }}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.1 }}
          >
            Kelola Bisnis <br />
            <span className="text-brand-yellow">Lebih Cerdas.</span>
            <br />
            Profit Lebih Tinggi.
          </motion.h1>

          <motion.p
            className="text-white/60 text-lg leading-relaxed mb-8 max-w-lg"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.2 }}
          >
            POSify mengubah ponsel biasa menjadi mesin kasir canggih. Catat transaksi, 
            pantau stok, dan lihat laporan bisnis — semua dalam satu aplikasi.
          </motion.p>

          <motion.ul
            className="flex flex-col gap-2 mb-10"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.35 }}
          >
            {checks.map((c) => (
              <li key={c} className="flex items-center gap-2 text-white/70 text-sm">
                <CheckCircle size={14} className="text-brand-yellow shrink-0" />
                {c}
              </li>
            ))}
          </motion.ul>

          <motion.div
            className="flex flex-wrap gap-4"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.4 }}
          >
            <a href="#pricing" className="btn-primary">
              Mulai Gratis 30 Hari <ArrowRight size={16} />
            </a>
            <a href="#how-it-works" className="btn-outline">
              Lihat Demo
            </a>
          </motion.div>
        </div>

        {/* RIGHT: Floating UI Cards */}
        <div className="relative h-[480px] hidden lg:block">
          {/* Main product card */}
          <motion.div
            className="absolute top-0 right-0 w-72 bg-white rounded-none border-l-4 border-brand-yellow shadow-2xl p-5"
            variants={floatingCard as any}
            initial="hidden"
            animate="show"
            custom={0}
            style={{ animation: 'float 7s ease-in-out infinite' }}
          >
            <div className="text-xs font-bold text-brand-navy/40 tracking-widest uppercase mb-3">
              Ringkasan Hari Ini
            </div>
            <div className="font-display font-black text-3xl text-brand-navy mb-1">
              Rp 4.850.000
            </div>
            <div className="text-xs text-brand-slate flex items-center gap-1">
              <span className="w-2 h-2 rounded-full bg-brand-success inline-block" />
              +18% dari kemarin
            </div>
            <div className="mt-4 grid grid-cols-2 gap-2">
              {[
                { label: 'Transaksi', val: '127' },
                { label: 'Produk Terjual', val: '384' },
                { label: 'Rata-rata', val: 'Rp 38.2rb' },
                { label: 'Item Terlaris', val: 'Es Teh' },
              ].map((item) => (
                <div key={item.label} className="bg-bg-light p-2">
                  <div className="text-[10px] text-text-secondary uppercase tracking-wide">
                    {item.label}
                  </div>
                  <div className="font-bold text-text-primary text-sm">{item.val}</div>
                </div>
              ))}
            </div>
          </motion.div>

          {/* Receipt card */}
          <motion.div
            className="absolute top-48 -left-4 w-52 bg-brand-navy text-white shadow-xl p-4"
            variants={floatingCard as any}
            initial="hidden"
            animate="show"
            custom={1}
            style={{ animation: 'float 9s ease-in-out infinite 1.5s' }}
          >
            <div className="text-xs text-white/40 uppercase tracking-widest mb-2">Struk #1842</div>
            {['Kopi Susu', 'Croissant', 'Es Matcha'].map((item, i) => (
              <div key={item} className="flex justify-between text-sm py-1 border-b border-white/10">
                <span className="text-white/80">{item}</span>
                <span className="text-brand-yellow font-semibold">
                  Rp {['18rb', '25rb', '22rb'][i]}
                </span>
              </div>
            ))}
            <div className="mt-3 flex justify-between font-bold">
              <span>Total</span>
              <span className="text-brand-yellow">Rp 65.000</span>
            </div>
          </motion.div>

          {/* Notification badge */}
          <motion.div
            className="absolute bottom-16 right-4 bg-brand-yellow text-brand-navy px-4 py-2.5 shadow-lg flex items-center gap-2"
            variants={floatingCard as any}
            initial="hidden"
            animate="show"
            custom={2}
            style={{ animation: 'float 8s ease-in-out infinite 0.8s' }}
          >
            <span className="w-2 h-2 rounded-full bg-brand-navy animate-pulse" />
            <span className="text-xs font-black tracking-wide uppercase">Stok Mie Goreng &lt; 10</span>
          </motion.div>
        </div>
      </div>

      {/* Stats bar */}
      <motion.div
        className="relative z-10 border-t border-white/10 bg-white/5"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.8 }}
      >
        <div className="max-w-7xl mx-auto px-6 py-6 grid grid-cols-3 divide-x divide-white/10">
          {stats.map((s) => (
            <div key={s.value} className="px-6 text-center">
              <div className="font-display font-black text-2xl text-brand-yellow">{s.value}</div>
              <div className="text-white/50 text-xs uppercase tracking-widest mt-1">{s.label}</div>
            </div>
          ))}
        </div>
      </motion.div>
    </section>
  )
}
