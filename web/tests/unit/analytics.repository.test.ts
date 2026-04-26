import { describe, it, expect, beforeEach, vi } from 'vitest'
import { SupabaseAnalyticsRepository } from '../../lib/database/repositories/supabase/analytics.repository'

// Mock Supabase client
const mockSupabaseClient = {
  from: vi.fn(() => mockSupabaseClient),
  select: vi.fn(() => mockSupabaseClient),
  eq: vi.fn(() => mockSupabaseClient),
  gte: vi.fn(() => mockSupabaseClient),
  lte: vi.fn(() => mockSupabaseClient),
  lt: vi.fn(() => mockSupabaseClient),
  order: vi.fn(() => mockSupabaseClient),
  limit: vi.fn(() => mockSupabaseClient),
  single: vi.fn(() => mockSupabaseClient),
}

// Mock the auth helpers
vi.mock('@supabase/auth-helpers-nextjs', () => ({
  createClientComponentClient: () => mockSupabaseClient,
}))

describe('AnalyticsRepository', () => {
  let repo: SupabaseAnalyticsRepository

  beforeEach(() => {
    vi.clearAllMocks()
    repo = new SupabaseAnalyticsRepository()
  })

  describe('getTodaySales', () => {
    it('should fetch today sales with correct structure', async () => {
      const mockData = [
        { total_amount: 100000, payment_status: 'paid' },
        { total_amount: 50000, payment_status: 'paid' },
      ]

      mockSupabaseClient.from.mockReturnValue({
        select: vi.fn(() => ({
          eq: vi.fn(() => ({
            gte: vi.fn(() => mockSupabaseClient),
            lte: vi.fn(() => ({
              order: vi.fn(() => ({
                data: mockData,
                error: null,
              })),
            })),
          })),
        })),
      })

      // Match actual behavior - return mockData with no error
      mockSupabaseClient.eq.mockReturnValue({
        gte: vi.fn(() => mockSupabaseClient),
        lte: vi.fn(() => mockSupabaseClient),
        order: vi.fn(() => ({
          data: mockData,
          error: null,
        })),
        data: mockData,
        error: null,
      })

      mockSupabaseClient.gte.mockReturnValue({
        lte: vi.fn(() => mockSupabaseClient),
        order: vi.fn(() => ({
          data: mockData,
          error: null,
        })),
        data: mockData,
        error: null,
      })

      mockSupabaseClient.lte.mockReturnValue({
        order: vi.fn(() => ({
          data: mockData,
          error: null,
        })),
        data: mockData,
        error: null,
      })

      mockSupabaseClient.order.mockReturnValue({
        data: mockData,
        error: null,
      })

      const result = await repo.getTodaySales('test-outlet-id')

      expect(result).toBeDefined()
      expect(result).toHaveProperty('totalAmount')
      expect(result).toHaveProperty('transactionCount')
      expect(result).toHaveProperty('averageOrderValue')
      expect(result).toHaveProperty('comparisonYesterday')
      expect(result).toHaveProperty('updatedAt')
      expect(typeof result.totalAmount).toBe('number')
      expect(typeof result.transactionCount).toBe('number')
    })

    it('should handle empty data gracefully', async () => {
      mockSupabaseClient.order.mockReturnValue({
        data: [],
        error: null,
      })

      const result = await repo.getTodaySales('test-outlet-id')

      expect(result.totalAmount).toBe(0)
      expect(result.transactionCount).toBe(0)
      expect(result.averageOrderValue).toBe(0)
    })
  })

  describe('getSalesTrend', () => {
    it('should fetch sales trend for specified days', async () => {
      const mockData = [
        { created_at: '2024-01-01T10:00:00Z', total_amount: 100000 },
        { created_at: '2024-01-01T14:00:00Z', total_amount: 50000 },
        { created_at: '2024-01-02T09:00:00Z', total_amount: 75000 },
      ]

      mockSupabaseClient.order.mockReturnValue({
        data: mockData,
        error: null,
      })

      const result = await repo.getSalesTrend('test-outlet-id', 7)

      expect(Array.isArray(result)).toBe(true)
      expect(result.length).toBeGreaterThan(0)
      result.forEach((item) => {
        expect(item).toHaveProperty('date')
        expect(item).toHaveProperty('totalSales')
        expect(item).toHaveProperty('transactionCount')
      })
    })

    it('should group transactions by date', async () => {
      const mockData = [
        { created_at: '2024-01-01T10:00:00Z', total_amount: 100000 },
        { created_at: '2024-01-01T14:00:00Z', total_amount: 50000 },
      ]

      mockSupabaseClient.order.mockReturnValue({
        data: mockData,
        error: null,
      })

      const result = await repo.getSalesTrend('test-outlet-id', 7)

      expect(result.length).toBe(1)
      expect(result[0].totalSales).toBe(150000)
      expect(result[0].transactionCount).toBe(2)
    })
  })

  describe('getTopProducts', () => {
    it('should fetch top products within limit', async () => {
      const mockData = [
        {
          quantity: 45,
          total_price: 675000,
          variants: { products: { id: '1', name: 'Kopi Latte' } },
        },
        {
          quantity: 32,
          total_price: 640000,
          variants: { products: { id: '2', name: 'Nasi Goreng' } },
        },
      ]

      mockSupabaseClient.limit.mockReturnValue({
        data: mockData,
        error: null,
      })

      const result = await repo.getTopProducts('test-outlet-id', 2)

      expect(Array.isArray(result)).toBe(true)
      expect(result.length).toBeLessThanOrEqual(2)
      result.forEach((item) => {
        expect(item).toHaveProperty('productId')
        expect(item).toHaveProperty('productName')
        expect(item).toHaveProperty('totalQuantity')
        expect(item).toHaveProperty('totalRevenue')
      })
    })
  })

  describe('getRecentTransactions', () => {
    it('should fetch recent transactions', async () => {
      const mockData = [
        {
          id: 'tx-1',
          outlet_id: 'outlet-1',
          receipt_number: 'RCP-001',
          total_amount: 100000,
          payment_status: 'paid',
          created_at: '2024-01-01T10:00:00Z',
          employees: { name: 'John' },
          outlets: { name: 'Main Outlet' },
        },
      ]

      mockSupabaseClient.limit.mockReturnValue({
        data: mockData,
        error: null,
      })

      const result = await repo.getRecentTransactions('test-outlet-id', 10)

      expect(Array.isArray(result)).toBe(true)
      expect(result.length).toBeLessThanOrEqual(10)
    })

    it('should handle empty transactions', async () => {
      mockSupabaseClient.limit.mockReturnValue({
        data: [],
        error: null,
      })

      const result = await repo.getRecentTransactions('test-outlet-id', 10)

      expect(Array.isArray(result)).toBe(true)
      expect(result.length).toBe(0)
    })
  })

  describe('getLowStockAlerts', () => {
    it('should fetch low stock items', async () => {
      const mockData = [
        { id: '1', name: 'Susu UHT 1L', stock_quantity: 3, min_stock_level: 10 },
        { id: '2', name: 'Kopi Bubuk 250g', stock_quantity: 2, min_stock_level: 5 },
      ]

      mockSupabaseClient.eq.mockReturnValue({
        lt: vi.fn(() => mockSupabaseClient),
        data: mockData,
        error: null,
      })

      mockSupabaseClient.lt.mockReturnValue({
        data: mockData,
        error: null,
      })

      const result = await repo.getLowStockAlerts('test-outlet-id')

      expect(Array.isArray(result)).toBe(true)
      result.forEach((item) => {
        expect(item).toHaveProperty('productId')
        expect(item).toHaveProperty('productName')
        expect(item).toHaveProperty('currentStock')
        expect(item).toHaveProperty('minStockLevel')
        expect(item.currentStock).toBeLessThan(item.minStockLevel)
      })
    })
  })
})
