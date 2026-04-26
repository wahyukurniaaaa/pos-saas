import { TodaySalesCard } from '@/components/features/analytics/today-sales-card'
import { SalesChart } from '@/components/charts/sales-chart'
import { RecentTransactions } from '@/components/features/analytics/recent-transactions'

export default function DashboardPage() {
  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold">Dashboard</h1>

      {/* Stats Grid */}
      <div className="grid gap-4 md:grid-cols-3">
        <TodaySalesCard />
        <TodaySalesCard />
        <TodaySalesCard />
      </div>

      {/* Charts */}
      <div className="grid gap-4 md:grid-cols-2">
        <SalesChart />
      </div>

      {/* Recent Data */}
      <RecentTransactions />
    </div>
  )
}
