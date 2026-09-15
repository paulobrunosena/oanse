// @vitest-environment node
import { describe, expect, it } from 'vitest'
import { primevuePreset } from '@/lib/theme'

describe('primevuePreset', () => {
  it('mantém o preset aura-compat como base', () => {
    expect(primevuePreset.components).toBeDefined()
    expect(primevuePreset.components!.tabs).toBeDefined()
  })

  it('usa o inkbar deslizante nas tabs (sem borda inferior estática)', () => {
    expect(primevuePreset.components!.tabs!.tab.borderWidth).toBe('0')
    expect(primevuePreset.components!.tabs!.tab.borderColor).toBe('transparent')
    expect(primevuePreset.components!.tabs!.tab.hoverBorderColor).toBe('transparent')
    expect(primevuePreset.components!.tabs!.tab.activeBorderColor).toBe('transparent')
    expect(primevuePreset.components!.tabs!.tab.margin).toBe('0')
  })

  it('posiciona o inkbar na base da tablist (bottom 0)', () => {
    expect(primevuePreset.components!.tabs!.activeBar.bottom).toBe('0')
    expect(primevuePreset.components!.tabs!.activeBar.height).toBe('1px')
  })
})
