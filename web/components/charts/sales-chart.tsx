'use client'

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts'

const data = [
  { name: 'Sen', sales: 1200000 },
  { name: 'Sel', sales: 1900000 },
  { name: 'Rab', sales: 1500000 },
  { name: 'Kam', sales: 2200000 },
  { name: 'Jum', sales: 2800000 },
  { name: 'Sab', sales: 2400000 },
  { name: 'Min', sales: 2100000 },
]

export function SalesChart() {
  return (
    <Card className="col-span-2">
      <CardHeader>
        <CardTitle>Trend Penjualan Mingguan</CardTitle>
      </CardHeader>
      <CardContent>
        <ResponsiveContainer width="100%" height={300}>
          <LineChart data={data}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" />
            <YAxis
              tickFormatter={(value) =>
                `Rp ${(value / 1000000).toFixed(1)}M`
              }
            />
            <Tooltip
              formatter={(value: number) =>
                `Rp ${value.toLocaleString()}`
              }
            />
            <Line
              type="monotone"
              dataKey="sales"
              stroke="#4f46e5"
              strokeWidth={2}
            />
          </LineChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  )
}
