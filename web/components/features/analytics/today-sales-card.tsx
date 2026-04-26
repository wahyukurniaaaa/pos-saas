'use client'

import { Card, CardContent } from '@/components/ui/card'
import { TrendingUp, TrendingDown } from 'lucide-react'
import { motion } from 'framer-motion'

interface TodaySalesCardProps {
  title?: string
  value?: string
  change?: string
  trend?: 'up' | 'down'
}

export function TodaySalesCard({
  title = 'Penjualan Hari Ini',
  value = 'Rp 2.450.000',
  change = '+12.5%',
  trend = 'up',
}: TodaySalesCardProps) {
  return (
    <motion.div
      whileHover={{ y: -2 }}
      transition={{ type: 'spring', stiffness: 300 }}
    >
      <Card className="border-0 shadow-sm bg-gradient-to-br from-white to-gray-50/50">
        <CardContent className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-500">{title}</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">{value}</p>
            </div>
            <div
              className={`flex items-center gap-1 text-sm font-medium ${
                trend === 'up' ? 'text-green-600' : 'text-red-600'
              }`}
            >
              {trend === 'up' ? (
                <TrendingUp className="w-4 h-4" />
              ) : (
                <TrendingDown className="w-4 h-4" />
              )}
              {change}
            </div>
          </div>
        </CardContent>
      </Card>
    </motion.div>
  )
}
