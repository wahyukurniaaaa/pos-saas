'use client'

import { DollarSign, ShoppingCart, Users, Package } from 'lucide-react'
import { StatCard } from './stat-card'

const stats = [
  {
    title: 'Total Penjualan',
    value: 'Rp 24.5M',
    change: '+12.5%',
    trend: 'up' as const,
    icon: DollarSign,
    color: 'bg-blue-500',
    lightColor: 'bg-blue-50',
  },
  {
    title: 'Transaksi Hari Ini',
    value: '1,284',
    change: '+8.2%',
    trend: 'up' as const,
    icon: ShoppingCart,
    color: 'bg-green-500',
    lightColor: 'bg-green-50',
  },
  {
    title: 'Pelanggan Aktif',
    value: '3,642',
    change: '-2.4%',
    trend: 'down' as const,
    icon: Users,
    color: 'bg-purple-500',
    lightColor: 'bg-purple-50',
  },
  {
    title: 'Produk Terjual',
    value: '856',
    change: '+15.3%',
    trend: 'up' as const,
    icon: Package,
    color: 'bg-orange-500',
    lightColor: 'bg-orange-50',
  },
]

export function StatsGrid() {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
      {stats.map((stat, index) => (
        <StatCard key={stat.title} {...stat} index={index} />
      ))}
    </div>
  )
}
