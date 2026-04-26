import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import DashboardPage from '@/app/dashboard/page'

describe('Dashboard UI', () => {
  it('renders dashboard title', () => {
    render(<DashboardPage />)
    expect(screen.getByText('Dashboard')).toBeInTheDocument()
  })

  it('renders all stat cards', () => {
    render(<DashboardPage />)
    expect(screen.getByText('Total Penjualan')).toBeInTheDocument()
    expect(screen.getByText('Transaksi Hari Ini')).toBeInTheDocument()
    expect(screen.getByText('Pelanggan Aktif')).toBeInTheDocument()
    expect(screen.getByText('Produk Terjual')).toBeInTheDocument()
  })

  it('renders chart section', () => {
    render(<DashboardPage />)
    expect(screen.getByText('Trend Penjualan')).toBeInTheDocument()
  })

  it('renders quick actions', () => {
    render(<DashboardPage />)
    expect(screen.getByText('Transaksi Baru')).toBeInTheDocument()
    expect(screen.getByText('Tambah Produk')).toBeInTheDocument()
    expect(screen.getByText('Lihat Laporan')).toBeInTheDocument()
  })
})
