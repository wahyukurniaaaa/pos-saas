import { describe, it, expect } from 'vitest'
import fs from 'fs'
import path from 'path'

describe('React Query Provider Setup', () => {
  const rootDir = process.cwd()

  it('should have QueryProvider in components/providers', () => {
    const providerPath = path.join(rootDir, 'components/providers/query-provider.tsx')
    expect(fs.existsSync(providerPath)).toBe(true)
  })

  it('should have marketing layout using QueryProvider', () => {
    const layoutPath = path.join(rootDir, 'app/(marketing)/layout.tsx')
    expect(fs.existsSync(layoutPath)).toBe(true)

    const content = fs.readFileSync(layoutPath, 'utf-8')
    expect(content).toContain('ReactQueryProvider')
    expect(content).toContain('components/providers/query-provider')
  })

  it('should have correct metadata in root layout', () => {
    const layoutPath = path.join(rootDir, 'app/layout.tsx')
    const content = fs.readFileSync(layoutPath, 'utf-8')
    expect(content).toContain('POSify')
    expect(content).toContain('POS Online')
  })
})
