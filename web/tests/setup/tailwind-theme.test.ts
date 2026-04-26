import { describe, it, expect } from 'vitest'
import tailwindConfig from '../../tailwind.config'

describe('Tailwind Theme', () => {
  it('should have indigo color palette', () => {
    const colors = tailwindConfig.theme?.extend?.colors as Record<string, Record<string, string>>
    expect(colors?.indigo).toBeDefined()
    expect(colors?.indigo?.[600]).toBe('#4f46e5')
  })

  it('should have all indigo shades defined', () => {
    const colors = tailwindConfig.theme?.extend?.colors as Record<string, Record<string, string>>
    const indigo = colors?.indigo
    expect(indigo).toBeDefined()

    const expectedShades = [
      { shade: '50', hex: '#eef2ff' },
      { shade: '100', hex: '#e0e7ff' },
      { shade: '200', hex: '#c7d2fe' },
      { shade: '300', hex: '#a5b4fc' },
      { shade: '400', hex: '#818cf8' },
      { shade: '500', hex: '#6366f1' },
      { shade: '600', hex: '#4f46e5' },
      { shade: '700', hex: '#4338ca' },
      { shade: '800', hex: '#3730a3' },
      { shade: '900', hex: '#312e81' },
      { shade: '950', hex: '#1e1b4b' },
    ]

    expectedShades.forEach(({ shade, hex }) => {
      expect(indigo?.[shade]).toBe(hex)
    })
  })
})
