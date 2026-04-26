import { SupabaseRepository } from './base.repository'
import {
  IAnalyticsRepository,
  TodaySales,
  SalesTrend,
  TopProduct,
  Transaction,
  LowStockAlert
} from '../../interfaces/repository.interface'

export class SupabaseAnalyticsRepository
  extends SupabaseRepository
  implements IAnalyticsRepository
{
  async getTodaySales(outletId: string): Promise<TodaySales> {
    const today = new Date().toISOString().split('T')[0]

    const { data, error } = await this.supabase
      .from('transactions')
      .select('total_amount, payment_status')
      .eq('outlet_id', outletId)
      .gte('created_at', today)

    if (error) throw error

    const transactions = data || []
    const totalAmount = transactions.reduce((sum, t) => sum + (t.total_amount || 0), 0)

    return {
      totalAmount,
      transactionCount: transactions.length,
      averageOrderValue: transactions.length > 0 ? totalAmount / transactions.length : 0,
      comparisonYesterday: 0,
      updatedAt: new Date().toISOString()
    }
  }

  async getSalesTrend(outletId: string, days: number): Promise<SalesTrend[]> {
    const startDate = new Date()
    startDate.setDate(startDate.getDate() - days)

    const { data, error } = await this.supabase
      .from('transactions')
      .select('created_at, total_amount')
      .eq('outlet_id', outletId)
      .gte('created_at', startDate.toISOString())
      .order('created_at', { ascending: true })

    if (error) throw error

    const grouped = new Map<string, { totalSales: number; count: number }>()

    for (const transaction of data || []) {
      const date = new Date(transaction.created_at).toISOString().split('T')[0]
      const current = grouped.get(date) || { totalSales: 0, count: 0 }
      current.totalSales += transaction.total_amount || 0
      current.count += 1
      grouped.set(date, current)
    }

    return Array.from(grouped.entries()).map(([date, stats]) => ({
      date,
      totalSales: stats.totalSales,
      transactionCount: stats.count
    }))
  }

  async getTopProducts(outletId: string, limit: number): Promise<TopProduct[]> {
    const { data, error } = await this.supabase
      .from('transaction_items')
      .select(`
        quantity,
        total_price,
        variants!inner(products!inner(name, id))
      `)
      .eq('variants.products.outlet_id', outletId)
      .limit(limit)

    if (error) throw error

    return (data || []).map((item: any) => ({
      productId: item.variants?.products?.id || '',
      productName: item.variants?.products?.name || 'Unknown',
      totalQuantity: item.quantity || 0,
      totalRevenue: item.total_price || 0
    }))
  }

  async getRecentTransactions(outletId: string, limit: number): Promise<Transaction[]> {
    const { data, error } = await this.supabase
      .from('transactions')
      .select(`
        id,
        outlet_id,
        receipt_number,
        total_amount,
        payment_status,
        created_at,
        employees(name),
        outlets(name)
      `)
      .eq('outlet_id', outletId)
      .order('created_at', { ascending: false })
      .limit(limit)

    if (error) throw error

    return (data || []).map((t: any) => ({
      id: t.id,
      outletId: t.outlet_id,
      receiptNumber: t.receipt_number,
      totalAmount: t.total_amount,
      paymentStatus: t.payment_status,
      createdAt: t.created_at,
      employeeName: t.employees?.name,
      outletName: t.outlets?.name
    }))
  }

  async getLowStockAlerts(outletId: string): Promise<LowStockAlert[]> {
    const { data, error } = await this.supabase
      .from('ingredients')
      .select('id, name, stock_quantity, min_stock_level')
      .eq('outlet_id', outletId)
      .lt('stock_quantity', 'min_stock_level')

    if (error) throw error

    return (data || []).map((item: any) => ({
      productId: item.id,
      productName: item.name,
      currentStock: item.stock_quantity || 0,
      minStockLevel: item.min_stock_level || 0
    }))
  }
}
