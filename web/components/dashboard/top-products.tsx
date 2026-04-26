'use client'

import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'

const products = [
  { name: 'Kopi Latte', sold: 45, revenue: 'Rp 675K' },
  { name: 'Nasi Goreng', sold: 32, revenue: 'Rp 640K' },
  { name: 'Mie Goreng', sold: 28, revenue: 'Rp 420K' },
]

export function TopProducts() {
  return (
    <Card className="border-0 shadow-sm">
      <CardHeader className="pb-2">
        <CardTitle className="text-lg font-semibold">
          Produk Terlaris
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {products.map((product, index) => (
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
  )
}
