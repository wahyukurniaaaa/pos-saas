const brands = [
  'Warung Makan Pak Budi',
  'Toko Kelontong Bu Sari',
  'Kopi Kekinian Malika',
  'Bakso Mas Bro',
  'Laundry Express 24H',
  'Toko Baju Modern',
  'Kedai Es Kelapa Muda',
  'Apotek Sehat Bersama',
]

export default function LogoTicker() {
  const doubled = [...brands, ...brands]
  return (
    <div className="bg-brand-navy border-y border-white/10 py-4 overflow-hidden">
      <div className="ticker-track">
        {doubled.map((name, i) => (
          <div
            key={i}
            className="flex items-center gap-6 px-8 shrink-0"
          >
            <div className="w-1.5 h-1.5 bg-brand-yellow rounded-full shrink-0" />
            <span className="text-white/60 text-sm font-medium tracking-wide whitespace-nowrap">
              {name}
            </span>
          </div>
        ))}
      </div>
    </div>
  )
}
