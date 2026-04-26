'use client'

import { motion } from 'framer-motion'
import { DashboardHeader } from '@/components/dashboard/dashboard-header'
import { StatsGrid } from '@/components/dashboard/stats-grid'
import { SalesOverview } from '@/components/dashboard/sales-overview'
import { QuickActions } from '@/components/dashboard/quick-actions'
import { RecentTransactions } from '@/components/features/analytics/recent-transactions'
import { TopProducts } from '@/components/dashboard/top-products'

export default function DashboardPage() {
  return (
    <div className="min-h-screen bg-gray-50/50 p-4 sm:p-6 lg:p-8">
      {/* Header Section */}
      <DashboardHeader />

      {/* Stats Grid */}
      <StatsGrid />

      {/* Main Content */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column - Charts & Quick Actions */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.3 }}
          className="lg:col-span-2 space-y-6"
        >
          <SalesOverview />
          <QuickActions />
        </motion.div>

        {/* Right Column - Recent Activity & Top Products */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.4 }}
          className="space-y-6"
        >
          <RecentTransactions />
          <TopProducts />
        </motion.div>
      </div>
    </div>
  )
}
