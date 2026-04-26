import { ReactQueryProvider } from '@/components/providers/query-provider'

export default function MarketingLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <ReactQueryProvider>
      <div className="min-h-screen bg-background">
        {children}
      </div>
    </ReactQueryProvider>
  )
}
