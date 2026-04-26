import { describe, it, expect } from 'vitest'
import fs from 'fs'
import path from 'path'

const __dirname = path.dirname(new URL(import.meta.url).pathname)
const projectRoot = path.resolve(__dirname, '../..')

describe('Supabase Client Setup', () => {
  it('should have browser client', () => {
    const filePath = path.join(projectRoot, 'lib/supabase/client.ts')
    expect(fs.existsSync(filePath)).toBe(true)
  })

  it('should have server client', () => {
    const filePath = path.join(projectRoot, 'lib/supabase/server.ts')
    expect(fs.existsSync(filePath)).toBe(true)
  })

  it('should have middleware helper', () => {
    const filePath = path.join(projectRoot, 'lib/supabase/middleware.ts')
    expect(fs.existsSync(filePath)).toBe(true)
  })

  it('should have database types placeholder', () => {
    const filePath = path.join(projectRoot, 'lib/types/database.types.ts')
    expect(fs.existsSync(filePath)).toBe(true)
  })
})
