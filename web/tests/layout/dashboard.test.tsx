import { render, screen } from '@testing-library/react'
import { DashboardShell } from '@/components/layout/dashboard-shell'

describe('Dashboard Layout', () => {
  it('renders dashboard shell with children', () => {
    render(
      <DashboardShell>
        <div data-testid="test-content">Dashboard Content</div>
      </DashboardShell>
    )
    expect(screen.getByTestId('test-content')).toBeInTheDocument()
  })
})
