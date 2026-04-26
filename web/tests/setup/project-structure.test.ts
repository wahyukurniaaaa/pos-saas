import { describe, it, expect } from 'vitest'
import fs from 'fs'
import path from 'path'

describe('Project Structure', () => {
  // Correct path (tests run from web directory)
  const rootDir = process.cwd()

  it('should have Next.js config', () => {
    const hasTsConfig = fs.existsSync(path.join(rootDir, 'next.config.ts'))
    const hasJsConfig = fs.existsSync(path.join(rootDir, 'next.config.js'))
    expect(hasTsConfig || hasJsConfig).toBe(true)
  })

  it('should have package.json with dependencies', () => {
    const pkgPath = path.join(rootDir, 'package.json')
    expect(fs.existsSync(pkgPath)).toBe(true)

    const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf-8'))
    expect(pkg.dependencies).toHaveProperty('next')
    expect(pkg.dependencies).toHaveProperty('@supabase/supabase-js')
    expect(pkg.dependencies).toHaveProperty('@tanstack/react-query')
    expect(pkg.dependencies).toHaveProperty('recharts')
  })

  it('should have app directory', () => {
    const appDir = path.join(rootDir, 'app')
    expect(fs.existsSync(appDir)).toBe(true)
  })

  it('should have components directory', () => {
    const componentsDir = path.join(rootDir, 'components')
    expect(fs.existsSync(componentsDir)).toBe(true)
  })

  it('should have lib directory', () => {
    const libDir = path.join(rootDir, 'lib')
    expect(fs.existsSync(libDir)).toBe(true)
  })

  it('should have TypeScript configuration', () => {
    const tsConfigPath = path.join(rootDir, 'tsconfig.json')
    expect(fs.existsSync(tsConfigPath)).toBe(true)
  })

  it('should have Tailwind configuration', () => {
    const hasTailwindConfig = fs.existsSync(path.join(rootDir, 'tailwind.config.ts')) ||
                              fs.existsSync(path.join(rootDir, 'tailwind.config.js'))
    expect(hasTailwindConfig).toBe(true)
  })
})
