import { beforeEach, describe, expect, it } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { usePreferenciasStore } from './preferencias'

const CHAVE = 'oanse:rotulos-acoes'

describe('usePreferenciasStore', () => {
  beforeEach(() => {
    window.localStorage.clear()
    setActivePinia(createPinia())
  })

  it('começa com rótulos das ações desligados por padrão', () => {
    const store = usePreferenciasStore()
    expect(store.rotulosAcoes).toBe(false)
  })

  it('alterna o estado e persiste em localStorage', () => {
    const store = usePreferenciasStore()

    store.alternarRotulosAcoes()
    expect(store.rotulosAcoes).toBe(true)
    expect(window.localStorage.getItem(CHAVE)).toBe('1')

    store.alternarRotulosAcoes()
    expect(store.rotulosAcoes).toBe(false)
    expect(window.localStorage.getItem(CHAVE)).toBe('0')
  })

  it('recupera o valor persistido ao inicializar', () => {
    window.localStorage.setItem(CHAVE, '1')
    setActivePinia(createPinia())

    const store = usePreferenciasStore()
    expect(store.rotulosAcoes).toBe(true)
  })
})
