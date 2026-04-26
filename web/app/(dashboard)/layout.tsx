import { DashboardShell } from '@/components/layout/dashboard-shell'
import { ReactQueryProvider } from '@/components/providers/query-provider'

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <ReactQueryProvider>
      <DashboardShell>{children}</DashboardShell>
    </ReactQueryProvider>
  )
}
