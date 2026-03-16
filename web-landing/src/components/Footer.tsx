const links = {
  Produk: ['Fitur', 'Cara Kerja', 'Harga', 'Changelog'],
  Perusahaan: ['Tentang Kami', 'Blog', 'Karir', 'Press Kit'],
  Support: ['Dokumentasi', 'FAQ', 'Hubungi Kami', 'Status Sistem'],
  Legal: ['Kebijakan Privasi', 'Syarat & Ketentuan', 'Keamanan Data'],
}

export default function Footer() {
  return (
    <footer className="bg-bg-dark border-t border-white/10">
      <div className="max-w-7xl mx-auto px-6 py-16 grid grid-cols-2 md:grid-cols-5 gap-12">
        {/* Brand column */}
        <div className="col-span-2 md:col-span-1">
          <div className="flex items-center gap-2 mb-4">
            <div className="w-7 h-7 bg-brand-yellow flex items-center justify-center font-display font-black text-brand-navy text-xs">
              P
            </div>
            <span className="font-display font-black text-white text-lg">
              POS<span className="text-brand-yellow">ify</span>
            </span>
          </div>
          <p className="text-white/40 text-sm leading-relaxed">
            Solusi kasir digital untuk UMKM Indonesia. Lebih cerdas, lebih cepat.
          </p>
        </div>

        {/* Link columns */}
        {Object.entries(links).map(([category, items]) => (
          <div key={category}>
            <h4 className="text-white/30 text-xs font-bold uppercase tracking-widest mb-4">
              {category}
            </h4>
            <ul className="flex flex-col gap-2.5">
              {items.map((item) => (
                <li key={item}>
                  <a
                    href="#"
                    className="text-white/60 hover:text-white text-sm transition-colors duration-150"
                  >
                    {item}
                  </a>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>

      <div className="border-t border-white/10 max-w-7xl mx-auto px-6 py-5 flex flex-col sm:flex-row justify-between items-center gap-3">
        <p className="text-white/30 text-sm">
          © 2025 POSify · Dibuat dengan ❤️ untuk UMKM Indonesia.
        </p>
        <div className="flex gap-4">
          {['Instagram', 'TikTok', 'WhatsApp'].map((s) => (
            <a key={s} href="#" className="text-white/30 hover:text-brand-yellow text-xs transition-colors">
              {s}
            </a>
          ))}
        </div>
      </div>
    </footer>
  )
}
