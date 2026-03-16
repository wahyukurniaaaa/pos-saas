import { useState, useEffect } from 'react'
import { motion, useScroll, useTransform } from 'framer-motion'
import { Menu, X } from 'lucide-react'

const links = [
  { label: 'Fitur', href: '#features' },
  { label: 'Cara Kerja', href: '#how-it-works' },
  { label: 'Testimoni', href: '#testimonials' },
  { label: 'Harga', href: '#pricing' },
]

export default function Navbar() {
  const [isOpen, setIsOpen] = useState(false)
  const { scrollY } = useScroll()
  const bgOpacity = useTransform(scrollY, [0, 80], [0, 1])

  useEffect(() => {
    return scrollY.on('change', () => {})
  }, [scrollY])

  return (
    <header className="fixed top-0 left-0 right-0 z-50">
      {/* Animated background */}
      <motion.div
        className="absolute inset-0 bg-bg-dark border-b border-white/10"
        style={{ opacity: bgOpacity }}
      />
      <nav className="relative max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
        {/* Logo */}
        <a href="/" className="flex items-center gap-2 group">
          <div className="w-8 h-8 bg-brand-yellow flex items-center justify-center font-display font-black text-brand-navy text-sm group-hover:scale-110 transition-transform">
            P
          </div>
          <span className="font-display font-black text-white text-xl tracking-tight">
            POS<span className="text-brand-yellow">ify</span>
          </span>
        </a>

        {/* Desktop Links */}
        <ul className="hidden md:flex items-center gap-8">
          {links.map((l) => (
            <li key={l.href}>
              <a
                href={l.href}
                className="text-white/70 hover:text-white text-sm font-medium transition-colors duration-150"
              >
                {l.label}
              </a>
            </li>
          ))}
        </ul>

        {/* CTA */}
        <div className="hidden md:flex items-center gap-3">
          <a
            href="#pricing"
            className="text-white/80 hover:text-white text-sm font-medium transition-colors"
          >
            Masuk
          </a>
          <a href="#pricing" className="btn-primary text-sm py-2.5 px-5">
            Coba Gratis
          </a>
        </div>

        {/* Mobile toggle */}
        <button
          className="md:hidden text-white p-2"
          onClick={() => setIsOpen(!isOpen)}
          aria-label="Toggle menu"
        >
          {isOpen ? <X size={22} /> : <Menu size={22} />}
        </button>
      </nav>

      {/* Mobile menu */}
      {isOpen && (
        <motion.div
          initial={{ opacity: 0, y: -8 }}
          animate={{ opacity: 1, y: 0 }}
          className="relative bg-bg-dark border-t border-white/10 md:hidden"
        >
          <ul className="px-6 py-4 flex flex-col gap-4">
            {links.map((l) => (
              <li key={l.href}>
                <a
                  href={l.href}
                  className="text-white/80 hover:text-white text-base font-medium block"
                  onClick={() => setIsOpen(false)}
                >
                  {l.label}
                </a>
              </li>
            ))}
            <li>
              <a href="#pricing" className="btn-primary text-sm w-full justify-center">
                Coba Gratis 30 Hari
              </a>
            </li>
          </ul>
        </motion.div>
      )}
    </header>
  )
}
