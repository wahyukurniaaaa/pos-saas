// tests/setup/env-config.test.ts
import { describe, it, expect } from 'vitest'
import fs from 'fs'
import path from 'path'

describe('Environment Configuration', () => {
  const cwd = process.cwd()

  it('should have .env.example file', () => {
    expect(fs.existsSync(path.join(cwd, '.env.example'))).toBe(true)
  })

  it('should have .env.local file', () => {
    expect(fs.existsSync(path.join(cwd, '.env.local'))).toBe(true)
  })

  it('should have .gitignore with env files', () => {
    const gitignore = fs.readFileSync(path.join(cwd, '.gitignore'), 'utf-8')
    expect(gitignore).toContain('.env.local')
    expect(gitignore).toContain('.env*.local')
  })

  it('.env.example should have required variables', () => {
    const envExample = fs.readFileSync(path.join(cwd, '.env.example'), 'utf-8')
    expect(envExample).toContain('NEXT_PUBLIC_SUPABASE_URL')
    expect(envExample).toContain('NEXT_PUBLIC_SUPABASE_ANON_KEY')
    expect(envExample).toContain('NEXT_PUBLIC_APP_URL')
  })
})
