'use client'

import { LucideIcon } from 'lucide-react'
import { motion } from 'framer-motion'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { ArrowUpRight, ArrowDownRight } from 'lucide-react'

interface StatCardProps {
  title: string
  value: string
  change: string
  trend: 'up' | 'down'
  icon: LucideIcon
  color: string
  lightColor: string
  index?: number
}

export function StatCard({
  title,
  value,
  change,
  trend,
  icon: Icon,
  color,
  lightColor,
  index = 0,
}: StatCardProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, delay: 0.1 + index * 0.1 }}
      whileHover={{ y: -4 }}
    >
      <Card className="border-0 shadow-sm hover:shadow-md transition-shadow">
        <CardContent className="p-6">
          <div className="flex items-start justify-between">
            <div className={`p-3 rounded-xl ${lightColor}`}>
              <Icon className={`w-5 h-5 ${color.replace('bg-', 'text-')}`} aria-hidden="true" />
            </div>
            <Badge
              variant={trend === 'up' ? 'default' : 'destructive'}
              className={`text-xs font-medium ${
                trend === 'up'
                  ? 'bg-green-100 text-green-700 hover:bg-green-100'
                  : 'bg-red-100 text-red-700 hover:bg-red-100'
              }`}
            >
              <span className="flex items-center gap-1">
                {trend === 'up' ? (
                  <ArrowUpRight className="w-3 h-3" aria-hidden="true" />
                ) : (
                  <ArrowDownRight className="w-3 h-3" aria-hidden="true" />
                )}
                {change}
              </span>
            </Badge>
          </div>
          <div className="mt-4">
            <p className="text-2xl font-bold text-gray-900">
              {value}
            </p>
            <p className="text-sm text-gray-500 mt-1">{title}</p>
          </div>
        </CardContent>
      </Card>
    </motion.div>
  )
}
