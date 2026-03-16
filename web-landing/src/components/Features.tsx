import { useRef } from 'react'
import { motion, useInView } from 'framer-motion'
import { ShoppingCart, BarChart3, Package, Users, Printer, ShieldCheck } from 'lucide-react'

const features = [
  {
    icon: ShoppingCart,
    title: 'Kasir Kilat',
    desc: 'Proses transaksi dalam hitungan detik. Scan barcode, pilih produk, dan terima pembayaran — tunai maupun QRIS.',
    accent: 'bg-brand-yellow text-brand-navy',
  },
  {
    icon: BarChart3,
    title: 'Laporan Real-Time',
    desc: 'Dashboard analitik yang menampilkan omzet, produk terlaris, dan tren penjualan setiap saat — langsung dari HP.',
    accent: 'bg-brand-cornflower text-white',
  },
  {
    icon: Package,
    title: 'Manajemen Stok',
    desc: 'Stok otomatis berkurang setiap transaksi. Notifikasi otomatis saat stok menipis — tidak ada lagi kehabisan barang dadakan.',
    accent: 'bg-brand-navy text-brand-yellow',
  },
  {
    icon: Users,
    title: 'Multi Kasir',
    desc: 'Kelola banyak kasir dengan peran berbeda (Owner, Supervisor, Kasir). Setiap shift tercatat rapi dan aman.',
    accent: 'bg-brand-success text-white',
  },
  {
    icon: Printer,
    title: 'Cetak Struk Otomatis',
    desc: 'Koneksi ke printer termal Bluetooth. Struk profesional dicetak dalam 2 detik — pelanggan lebih percaya.',
    accent: 'bg-bg-dark text-brand-yellow border border-white/10',
  },
  {
    icon: ShieldCheck,
    title: 'Data Aman & Offline',
    desc: 'Semua data tersimpan lokal di perangkat Anda. Tetap bekerja meski tanpa internet — dan terenkripsi penuh.',
    accent: 'bg-brand-danger text-white',
  },
]

const container = {
  hidden: {},
  show: { transition: { staggerChildren: 0.1 } },
}

const item = {
  hidden: { opacity: 0, y: 32 },
  show: { opacity: 1, y: 0, transition: { duration: 0.55, ease: 'circOut' } },
} as const

export default function Features() {
  const ref = useRef(null)
  const inView = useInView(ref, { once: true, margin: '-100px' })

  return (
    <section id="features" className="bg-bg-light py-24 px-6" ref={ref}>
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-16">
          <span className="section-tag mb-4 inline-block">Fitur Unggulan</span>
          <h2 className="font-display font-black text-text-primary leading-none tracking-tighter"
            style={{ fontSize: 'clamp(2rem, 4vw, 3.5rem)' }}
          >
            Semua yang dibutuhkan<br />
            <span className="text-brand-navy">bisnis Anda. Satu aplikasi.</span>
          </h2>
        </div>

        {/* Grid - intentionally broken 4+2 */}
        <motion.div
          className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-px bg-border"
          variants={container as any}
          initial="hidden"
          animate={inView ? 'show' : 'hidden'}
        >
          {features.map((f) => {
            const Icon = f.icon
            return (
              <motion.div
                key={f.title}
                variants={item as any}
                className="bg-white p-7 group hover:z-10 hover:-translate-y-1 hover:shadow-xl transition-all duration-300 relative"
              >
                <div className={`w-10 h-10 flex items-center justify-center mb-5 ${f.accent}`}>
                  <Icon size={18} />
                </div>
                <h3 className="font-display font-bold text-lg text-text-primary mb-2">
                  {f.title}
                </h3>
                <p className="text-text-secondary text-sm leading-relaxed">{f.desc}</p>
                {/* bottom accent */}
                <div className="absolute bottom-0 left-0 w-0 h-0.5 bg-brand-yellow group-hover:w-full transition-all duration-500" />
              </motion.div>
            )
          })}
        </motion.div>
      </div>
    </section>
  )
}
