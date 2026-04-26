'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Area,
  AreaChart,
} from 'recharts'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { TrendingUp, Calendar } from 'lucide-react'

const data = [
  { name: '00:00', sales: 1200000, orders: 45 },
  { name: '04:00', sales: 800000, orders: 32 },
  { name: '08:00', sales: 2400000, orders: 78 },
  { name: '12:00', sales: 4200000, orders: 120 },
  { name: '16:00', sales: 3800000, orders: 105 },
  { name: '20:00', sales: 2800000, orders: 82 },
  { name: '23:59', sales: 1500000, orders: 48 },
]

const CustomTooltip = ({ active, payload, label }: any) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-white p-3 border border-gray-100 rounded-lg shadow-lg">
        <p className="text-sm text-gray-600 mb-1">{label}</p>
        <p className="text-lg font-bold text-indigo-600">
          Rp {(payload[0].value / 1000000).toFixed(1)}M
        </p>
        <p className="text-xs text-gray-500 mt-1">
          {payload[0].payload.orders} orders
        </p>
      </div>
    )
  }
  return null
}

export function SalesChart() {
  const [timeRange, setTimeRange] = useState('7d')
  const totalSales = data.reduce((acc, curr) => acc + curr.sales, 0)

  return (
    <Card className="border-0 shadow-sm">
      <CardHeader className="pb-2">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div>
            <CardTitle className="text-lg font-semibold flex items-center gap-2">
              <TrendingUp className="w-5 h-5 text-indigo-600" />
              Sales Performance
            </CardTitle>
            <p className="text-sm text-gray-500 mt-1">
              Total: Rp {(totalSales / 1000000).toFixed(1)}M
            </p>
          </div>
          <div className="flex items-center gap-2">
            <Calendar className="w-4 h-4 text-gray-400" />
            <Tabs value={timeRange} onValueChange={setTimeRange} className="w-auto">
              <TabsList className="bg-gray-100 h-8">
                <TabsTrigger value="24h" className="text-xs px-3">
                  24h
                </TabsTrigger>
                <TabsTrigger value="7d" className="text-xs px-3">
                  7d
                </TabsTrigger>
                <TabsTrigger value="30d" className="text-xs px-3">
                  30d
                </TabsTrigger>
              </TabsList>
            </Tabs>
          </div>
        </div>
      </CardHeader>
      <CardContent className="pt-4">
        <div className="h-[300px] w-full">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={data} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
              <defs>
                <linearGradient id="colorSales" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#4f46e5" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#4f46e5" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" vertical={false} />
              <XAxis
                dataKey="name"
                axisLine={false}
                tickLine={false}
                tick={{ fill: '#9ca3af', fontSize: 12 }}
                dy={10}
              />
              <YAxis
                axisLine={false}
                tickLine={false}
                tick={{ fill: '#9ca3af', fontSize: 12 }}
                tickFormatter={(value) => `Rp${(value / 1000000).toFixed(0)}M`}
                dx={-10}
              />
              <Tooltip content={<CustomTooltip />} />
              <Area
                type="monotone"
                dataKey="sales"
                stroke="#4f46e5"
                strokeWidth={3}
                fillOpacity={1}
                fill="url(#colorSales)"
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </CardContent>
    </Card>
  )
}
