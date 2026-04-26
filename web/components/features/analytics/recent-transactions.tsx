'use client'

import { motion } from 'framer-motion'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import {
  MoreHorizontal,
  ArrowUpRight,
  ArrowDownRight,
  Clock,
  User,
} from 'lucide-react'

const transactions = [
  {
    id: 'TRX-001',
    customer: 'Ahmad Santoso',
    avatar: 'AS',
    amount: 150000,
    status: 'success',
    time: '2 menit yang lalu',
    items: 3,
  },
  {
    id: 'TRX-002',
    customer: 'Budi Raharjo',
    avatar: 'BR',
    amount: 235000,
    status: 'success',
    time: '5 menit yang lalu',
    items: 5,
  },
  {
    id: 'TRX-003',
    customer: 'Citra Lestari',
    avatar: 'CL',
    amount: 89000,
    status: 'pending',
    time: '12 menit yang lalu',
    items: 2,
  },
  {
    id: 'TRX-004',
    customer: 'Dewi Kusuma',
    avatar: 'DK',
    amount: 320000,
    status: 'success',
    time: '18 menit yang lalu',
    items: 7,
  },
  {
    id: 'TRX-005',
    customer: 'Eko Prasetyo',
    avatar: 'EP',
    amount: 175000,
    status: 'failed',
    time: '25 menit yang lalu',
    items: 4,
  },
]

const getStatusBadge = (status: string) => {
  switch (status) {
    case 'success':
      return (
        <Badge className="bg-green-100 text-green-700 hover:bg-green-100 font-medium">
          <ArrowUpRight className="w-3 h-3 mr-1" />
          Success
        </Badge>
      )
    case 'pending':
      return (
        <Badge className="bg-yellow-100 text-yellow-700 hover:bg-yellow-100 font-medium">
          <Clock className="w-3 h-3 mr-1" />
          Pending
        </Badge>
      )
    case 'failed':
      return (
        <Badge className="bg-red-100 text-red-700 hover:bg-red-100 font-medium">
          <ArrowDownRight className="w-3 h-3 mr-1" />
          Failed
        </Badge>
      )
    default:
      return null
  }
}

export function RecentTransactions() {
  return (
    <Card className="border-0 shadow-sm">
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <div>
            <CardTitle className="text-lg font-semibold">
              Recent Transactions
            </CardTitle>
            <p className="text-sm text-gray-500 mt-1">
              Latest sales activity
            </p>
          </div>
          <Button variant="ghost" size="sm" className="text-gray-400 hover:text-gray-600">
            <MoreHorizontal className="w-4 h-4" />
          </Button>
        </div>
      </CardHeader>
      <CardContent className="p-0">
        <div className="space-y-1">
          {transactions.map((transaction, index) => (
            <motion.div
              key={transaction.id}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.1 }}
              className="flex items-center justify-between p-4 hover:bg-gray-50 transition-colors border-b border-gray-50 last:border-0"
            >
              <div className="flex items-center gap-3">
                <Avatar className="w-10 h-10">
                  <AvatarFallback className="bg-indigo-100 text-indigo-600 text-sm font-semibold">
                    {transaction.avatar}
                  </AvatarFallback>
                </Avatar>
                <div>
                  <p className="font-medium text-gray-900 text-sm">
                    {transaction.customer}
                  </p>
                  <p className="text-xs text-gray-500 flex items-center gap-1">
                    <Clock className="w-3 h-3" />
                    {transaction.time}
                  </p>
                </div>
              </div>
              <div className="text-right">
                <p className="font-semibold text-gray-900">
                  Rp {transaction.amount.toLocaleString()}
                </p>
                <div className="mt-1">
                  {getStatusBadge(transaction.status)}
                </div>
              </div>
            </motion.div>
          ))}
        </div>
        <div className="p-4 border-t border-gray-100">
          <Button variant="ghost" className="w-full text-indigo-600 hover:text-indigo-700 hover:bg-indigo-50">
            View All Transactions
            <ArrowUpRight className="w-4 h-4 ml-2" />
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}
