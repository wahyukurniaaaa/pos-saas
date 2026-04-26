'use client'

import { motion } from 'framer-motion'
import { Button } from '@/components/ui/button'
import { ShoppingCart, Package, TrendingUp } from 'lucide-react'

const actions = [
  { label: 'Transaksi Baru', color: 'bg-blue-500', icon: ShoppingCart },
  { label: 'Tambah Produk', color: 'bg-green-500', icon: Package },
  { label: 'Lihat Laporan', color: 'bg-purple-500', icon: TrendingUp },
]

export function QuickActions() {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
      {actions.map((action) => (
        <motion.div
          key={action.label}
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
        >
          <Button
            variant="outline"
            className="w-full h-24 flex flex-col items-center justify-center gap-2 border-2 border-dashed hover:border-solid hover:bg-gray-50"
          >
            <div className={`w-10 h-10 rounded-lg ${action.color} flex items-center justify-center`}>
              <action.icon className="w-5 h-5 text-white" aria-hidden="true" />
            </div>
            <span className="text-sm font-medium">{action.label}</span>
          </Button>
        </motion.div>
      ))}
    </div>
  )
}
