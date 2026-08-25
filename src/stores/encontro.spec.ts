import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { builder, clienteSupabase } from '../../tests/helpers/supabase'
import { useEncontroStore, type Encontro } from './encontro'

const ENCONTROS = [
  { id: 'e1', data: '2026-08-22', ativo: true },
  { id: 'e0', data: '2026-08-15', ativo: true },
] as unknown as Encontro[]

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

describe('store de encontro', () => {
  let fetchResposta: unknown
  let fetchFalha: boolean

  beforeEach(() => {
    setActivePinia(createPinia())
    mocks.supabase = clienteSupabase({
      encontros: () => builder(ENCONTROS),
      dias_sem_oanse: () => builder([{ data: '2026-08-08' }]),
    })
    fetchResposta = null
    fetchFalha = false
    globalThis.fetch = vi.fn(async () => {
      if (fetchFalha) throw new Error('rede fora do ar')
      return new Response(JSON.stringify(fetchResposta), { status: 200, headers: { 'Content-Type': 'application/json' } })
    }) as unknown as typeof fetch
  })

  describe('carregar', () => {
    it('define o encontro corrente e carrega o histórico', async () => {
      fetchResposta = { encontro: ENCONTROS[0], semAtividade: false, motivo: null, data: '2026-08-22' }
      const store = useEncontroStore()

      await store.carregar()

      expect(store.encontro).toEqual(ENCONTROS[0])
      expect(store.semAtividade).toBe(false)
      expect(store.motivoSemAtividade).toBeNull()
      expect(store.encontros).toHaveLength(2)
      expect(store.carregando).toBe(false)
    })

    it('marca semAtividade quando o sábado não tem Oanse', async () => {
      fetchResposta = { encontro: null, semAtividade: true, motivo: 'Férias de julho', data: '2026-08-22' }
      const store = useEncontroStore()

      await store.carregar()

      expect(store.encontro).toBeNull()
      expect(store.semAtividade).toBe(true)
      expect(store.motivoSemAtividade).toBe('Férias de julho')
    })

    it('limpa o estado e registra erro quando a API falha', async () => {
      fetchFalha = true
      const store = useEncontroStore()
      store.encontro = ENCONTROS[0]!
      store.semAtividade = true

      await store.carregar()

      expect(store.encontro).toBeNull()
      expect(store.semAtividade).toBe(false)
      expect(store.erro).toBe('Não foi possível carregar o encontro do sábado.')
      expect(store.carregando).toBe(false)
    })
  })

  describe('carregarHistorico', () => {
    it('popula a lista de encontros', async () => {
      const store = useEncontroStore()
      await store.carregarHistorico()
      expect(store.encontros).toEqual(ENCONTROS)
      expect(mocks.supabase.builderDe('encontros').limit).toHaveBeenCalledWith(26)
    })
  })

  describe('selecionar', () => {
    it('seleciona um encontro do histórico', async () => {
      const store = useEncontroStore()
      await store.carregarHistorico()
      store.selecionar('e0')
      expect(store.encontro?.id).toBe('e0')
      expect(store.semAtividade).toBe(false)
      expect(store.motivoSemAtividade).toBeNull()
    })

    it('limpa a seleção quando o id não existe', async () => {
      const store = useEncontroStore()
      await store.carregarHistorico()
      store.selecionar('inexistente')
      expect(store.encontro).toBeNull()
    })
  })

  describe('sabadosFaltantes', () => {
    it('lista sábados recentes sem encontro e fora de dias sem Oanse', () => {
      vi.useFakeTimers()
      vi.setSystemTime(new Date(2026, 7, 24)) // segunda-feira
      const store = useEncontroStore()
      store.encontros = ENCONTROS as Encontro[] // 22 e 15/08
      store.diasSemOanse = ['2026-08-08']

      expect(store.sabadosFaltantes[0]).toBe('2026-08-01')
      expect(store.sabadosFaltantes).not.toContain('2026-08-22')
      expect(store.sabadosFaltantes).not.toContain('2026-08-15')
      expect(store.sabadosFaltantes).not.toContain('2026-08-08')
      vi.useRealTimers()
    })
  })

  describe('criarRetroativo', () => {
    it('cria o sábado perdido, adiciona ao histórico e seleciona', async () => {
      const novo = { id: 'e2', data: '2026-08-01', ativo: true } as unknown as Encontro
      fetchResposta = { encontro: novo, criado: true }
      const store = useEncontroStore()
      await store.carregarHistorico()

      const resposta = await store.criarRetroativo('2026-08-01')

      expect(resposta.criado).toBe(true)
      expect(store.encontros).toHaveLength(3)
      expect(store.encontros).toContainEqual(novo)
      expect(store.encontro?.id).toBe('e2')
      expect(store.semAtividade).toBe(false)

      const [url, init] = (globalThis.fetch as ReturnType<typeof vi.fn>).mock.calls.at(-1) as [string, RequestInit]
      expect(url).toBe('/api/encontros/retro')
      expect(init.method).toBe('POST')
      expect(JSON.parse(init.body as string)).toEqual({ data: '2026-08-01' })
    })
  })
})
