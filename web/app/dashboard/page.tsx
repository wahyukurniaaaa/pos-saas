'use client'

import { motion } from 'framer-motion'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import {
  TrendingUp,
  TrendingDown,
  DollarSign,
  ShoppingCart,
  Users,
  Package,
  Calendar,
  Download,
  ArrowUpRight,
  ArrowDownRight,
} from 'lucide-react'
import { SalesChart } from '@/components/charts/sales-chart'
import { RecentTransactions } from '@/components/features/analytics/recent-transactions'

const stats = [
  {
    title: 'Total Penjualan',
    value: 'Rp 24.5M',
    change: '+12.5%',
    trend: 'up',
    icon: DollarSign,
    color: 'bg-blue-500',
    lightColor: 'bg-blue-50',
  },
  {
    title: 'Transaksi Hari Ini',
    value: '1,284',
    change: '+8.2%',
    trend: 'up',
    icon: ShoppingCart,
    color: 'bg-green-500',
    lightColor: 'bg-green-50',
  },
  {
    title: 'Pelanggan Aktif',
    value: '3,642',
    change: '-2.4%',
    trend: 'down',
    icon: Users,
    color: 'bg-purple-500',
    lightColor: 'bg-purple-50',
  },
  {
    title: 'Produk Terjual',
    value: '856',
    change: '+15.3%',
    trend: 'up',
    icon: Package,
    color: 'bg-orange-500',
    lightColor: 'bg-orange-50',
  },
]

export default function DashboardPage() {
  return (
    <div className="min-h-screen bg-gray-50/50 p-4 sm:p-6 lg:p-8">
      {/* Header Section */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="mb-8 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4"
      >
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-gray-900">
            Dashboard
          </h1>
          <p className="text-gray-500 mt-1">
            Ringkasan bisnis Anda hari ini
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Button variant="outline" className="gap-2">
            <Calendar className="w-4 h-4" />
            <span className="hidden sm:inline">Hari Ini</span>
          </Button>
          <Button variant="outline" className="gap-2">
            <Download className="w-4 h-4" />
            <span className="hidden sm:inline">Export</span>
          </Button>
        </div>
      </motion.div>

      {/* Stats Grid */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.1 }}
        className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8"
      >
        {stats.map((stat, index) => (
          <motion.div
            key={stat.title}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.1 + index * 0.1 }}
            whileHover={{ y: -4 }}
          >
            <Card className="border-0 shadow-sm hover:shadow-md transition-shadow">
              <CardContent className="p-6">
                <div className="flex items-start justify-between">
                  <div className={`p-3 rounded-xl ${stat.lightColor}`}>
                    <stat.icon className={`w-5 h-5 ${stat.color.replace('bg-', 'text-')}`} />
                  </div>
                  <Badge
                    variant={stat.trend === 'up' ? 'default' : 'destructive'}
                    className={`text-xs font-medium ${
                      stat.trend === 'up'
                        ? 'bg-green-100 text-green-700 hover:bg-green-100'
                        : 'bg-red-100 text-red-700 hover:bg-red-100'
                    }`}
                  >
                    <span className="flex items-center gap-1">
                      {stat.trend === 'up' ? (
                        <ArrowUpRight className="w-3 h-3" />
                      ) : (
                        <ArrowDownRight className="w-3 h-3" />
                      )}
                      {stat.change}
                    </span>
                  </Badge>
                </div>
                <div className="mt-4">
                  <p className="text-2xl font-bold text-gray-900">
                    {stat.value}
                  </p>
                  <p className="text-sm text-gray-500 mt-1">{stat.title}</p>
                </div>
              </CardContent>
            </Card>
          </motion.div>
        ))}
      </motion.div>

      {/* Main Content */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column - Charts */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.3 }}
          className="lg:col-span-2 space-y-6"
        >
          <Card className="border-0 shadow-sm">
            <CardHeader className="pb-2">
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle className="text-lg font-semibold">
                    Trend Penjualan
                  </CardTitle>
                  <p className="text-sm text-gray-500">
                    7 hari terakhir
                  </p>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <SalesChart />
            </CardContent>
          </Card>

          {/* Quick Actions */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            {[
              { label: 'Transaksi Baru', color: 'bg-blue-500', icon: ShoppingCart },
              { label: 'Tambah Produk', color: 'bg-green-500', icon: Package },
              { label: 'Lihat Laporan', color: 'bg-purple-500', icon: TrendingUp },
            ].map((action) => (
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
                    <action.icon className="w-5 h-5 text-white" />
                  </div>
                  <span className="text-sm font-medium">{action.label}</span>
                </Button>
              </motion.div>
            ))}
          </div>
        </motion.div>

        {/* Right Column - Recent Activity */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.4 }}
          className="space-y-6"
        >
          <RecentTransactions />

          {/* Top Products */}
          <Card className="border-0 shadow-sm">
            <CardHeader className="pb-2">
              <CardTitle className="text-lg font-semibold">
                Produk Terlaris
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {[
                { name: 'Kopi Latte', sold: 45, revenue: 'Rp 675K' },
                { name: 'Nasi Goreng', sold: 32, revenue: 'Rp 640K' },
                { name: 'Mie Goreng', sold: 28, revenue: 'Rp 420K' },
              ].map((product, index) => (
                <div
                  key={product.name}
                  className="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-600 font-semibold text-sm">
                      {index + 1}
                    </div>
                    <div>
                      <p className="font-medium text-gray-900">{product.name}</p>
                      <p className="text-xs text-gray-500">{product.sold} terjual</p>
                    </div>
                  </div>
                  <p className="font-semibold text-gray-900">{product.revenue}</p>
                </div>
              ))}
            </CardContent>
          </Card>
        </motion.div>
      </div>
    </div>
  )
}
