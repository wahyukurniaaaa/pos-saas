'use client'

import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'
import { SalesChart } from '@/components/charts/sales-chart'

export function SalesOverview() {
  return (
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
  )
}
