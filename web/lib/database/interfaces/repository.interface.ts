// Repository interfaces for type safety

export interface TodaySales {
  totalAmount: number
  transactionCount: number
  averageOrderValue: number
  comparisonYesterday: number
  updatedAt: string
}

export interface SalesTrend {
  date: string
  totalSales: number
  transactionCount: number
}

export interface TopProduct {
  productId: string
  productName: string
  totalQuantity: number
  totalRevenue: number
}

export interface Transaction {
  id: string
  outletId: string
  receiptNumber: string
  totalAmount: number
  paymentStatus: string
  createdAt: string
  employeeName?: string
  outletName?: string
}

export interface LowStockAlert {
  productId: string
  productName: string
  currentStock: number
  minStockLevel: number
}

export interface IAnalyticsRepository {
  getTodaySales(outletId: string): Promise<TodaySales>
  getSalesTrend(outletId: string, days: number): Promise<SalesTrend[]>
  getTopProducts(outletId: string, limit: number): Promise<TopProduct[]>
  getRecentTransactions(outletId: string, limit: number): Promise<Transaction[]>
  getLowStockAlerts(outletId: string): Promise<LowStockAlert[]>
}

export interface ITierProvider {
  getUserTier(): Promise<'free' | 'lite' | 'pro'>
  isPro(): Promise<boolean>
}
