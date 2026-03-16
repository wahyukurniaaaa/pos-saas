import { motion } from 'framer-motion'
import { ArrowRight } from 'lucide-react'

export default function FinalCTA() {
  return (
    <section className="bg-brand-yellow relative overflow-hidden py-24 px-6">
      {/* Decorative background text */}
      <div className="absolute -bottom-6 -right-4 text-[14rem] font-display font-black text-brand-navy/[0.07] leading-none select-none pointer-events-none whitespace-nowrap">
        POSify
      </div>

      <motion.div
        className="relative z-10 max-w-4xl mx-auto"
        initial={{ opacity: 0, y: 32 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true, margin: '-80px' }}
        transition={{ duration: 0.6, ease: 'circOut' } as any}
      >
        <h2
          className="font-display font-black text-brand-navy leading-none tracking-tighter mb-6"
          style={{ fontSize: 'clamp(2.5rem, 6vw, 5rem)' }}
        >
          Bisnis Anda layak
          <br /> alat yang lebih baik.
        </h2>
        <p className="text-brand-navy/65 text-lg leading-relaxed mb-10 max-w-lg">
          Daftar sekarang dan rasakan perbedaannya dalam hari pertama. 
          Gratis 30 hari, tidak perlu kartu kredit.
        </p>
        <div className="flex flex-wrap gap-4">
          <a
            href="#"
            className="inline-flex items-center gap-2 bg-brand-navy text-brand-yellow font-bold px-8 py-4 hover:scale-105 hover:shadow-2xl transition-all duration-200 active:scale-95"
          >
            Mulai Gratis Sekarang <ArrowRight size={16} />
          </a>
          <a
            href="#how-it-works"
            className="inline-flex items-center gap-2 border-2 border-brand-navy text-brand-navy font-bold px-8 py-4 hover:bg-brand-navy hover:text-brand-yellow transition-all duration-200"
          >
            Lihat Cara Kerja
          </a>
        </div>
      </motion.div>
    </section>
  )
}
