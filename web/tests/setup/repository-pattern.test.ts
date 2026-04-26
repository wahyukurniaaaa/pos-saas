import { describe, it, expect } from 'vitest'
import fs from 'fs'

describe('Repository Pattern', () => {
  it('should have repository interfaces', () => {
    expect(fs.existsSync('lib/database/interfaces/repository.interface.ts')).toBe(true)
  })

  it('should have base repository', () => {
    expect(fs.existsSync('lib/database/repositories/supabase/base.repository.ts')).toBe(true)
  })

  it('should have repository factory', () => {
    expect(fs.existsSync('lib/database/factory.ts')).toBe(true)
  })
})
