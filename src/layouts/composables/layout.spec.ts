import { beforeEach, describe, expect, it, vi } from 'vitest'

const CHAVE = 'oanse-tema-escuro'

describe('layout (tema escuro)', () => {
  beforeEach(() => {
    localStorage.clear()
    document.documentElement.classList.remove('app-dark')
    vi.resetModules()
  })

  it('alterna o tema, aplica a classe e persiste a escolha', async () => {
    const { useLayout } = await import('./layout')
    const { layoutConfig, toggleDarkMode } = useLayout()

    expect(layoutConfig.darkTheme).toBe(false)
    expect(document.documentElement.classList.contains('app-dark')).toBe(false)

    toggleDarkMode()

    expect(layoutConfig.darkTheme).toBe(true)
    expect(document.documentElement.classList.contains('app-dark')).toBe(true)
    expect(localStorage.getItem(CHAVE)).toBe('1')

    toggleDarkMode()
    expect(localStorage.getItem(CHAVE)).toBe('0')
    expect(document.documentElement.classList.contains('app-dark')).toBe(false)
  })

  it('inicia com o tema salvo e aplica a classe já no boot', async () => {
    localStorage.setItem(CHAVE, '1')

    const { useLayout } = await import('./layout')
    const { layoutConfig } = useLayout()

    expect(layoutConfig.darkTheme).toBe(true)
    expect(document.documentElement.classList.contains('app-dark')).toBe(true)
  })
})
