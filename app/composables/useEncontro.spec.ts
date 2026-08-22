import { beforeEach, describe, expect, it, vi } from 'vitest'
import { mockNuxtImport } from '@nuxt/test-utils/runtime'
import { builder, clienteSupabase } from '../../tests/helpers/supabase'
import { useEncontro, type Encontro } from './useEncontro'

const ENCONTROS = [
  { id: 'e1', data: '2026-08-22', ativo: true },
  { id: 'e0', data: '2026-08-15', ativo: true },
] as unknown as Encontro[]

let supabase = clienteSupabase()
let fetchResposta: unknown = null
let fetchFalha = false

mockNuxtImport('useSupabaseClient', () => () => supabase)
mockNuxtImport('$fetch', () => vi.fn(async () => {
  if (fetchFalha) throw new Error('rede fora do ar')
  return fetchResposta
}))

describe('useEncontro', () => {
  let encontro: ReturnType<typeof useEncontro>

  beforeEach(() => {
    supabase = clienteSupabase({ encontros: () => builder(ENCONTROS) })
    fetchResposta = null
    fetchFalha = false
    encontro = useEncontro()
    encontro.encontro.value = null
    encontro.encontros.value = []
    encontro.semAtividade.value = false
    encontro.motivoSemAtividade.value = null
    encontro.erro.value = null
    encontro.carregando.value = false
  })

  describe('carregar', () => {
    it('define o encontro corrente e carrega o histórico', async () => {
      fetchResposta = { encontro: ENCONTROS[0], semAtividade: false, motivo: null, data: '2026-08-22' }

      await encontro.carregar()

      expect(encontro.encontro.value).toEqual(ENCONTROS[0])
      expect(encontro.semAtividade.value).toBe(false)
      expect(encontro.motivoSemAtividade.value).toBeNull()
      expect(encontro.encontros.value).toHaveLength(2)
      expect(encontro.carregando.value).toBe(false)
    })

    it('marca semAtividade quando o sábado não tem Oanse', async () => {
      fetchResposta = { encontro: null, semAtividade: true, motivo: 'Férias de julho', data: '2026-08-22' }

      await encontro.carregar()

      expect(encontro.encontro.value).toBeNull()
      expect(encontro.semAtividade.value).toBe(true)
      expect(encontro.motivoSemAtividade.value).toBe('Férias de julho')
    })

    it('limpa o estado e registra erro quando a API falha', async () => {
      fetchFalha = true
      encontro.encontro.value = ENCONTROS[0]!
      encontro.semAtividade.value = true

      await encontro.carregar()

      expect(encontro.encontro.value).toBeNull()
      expect(encontro.semAtividade.value).toBe(false)
      expect(encontro.erro.value).toBe('Não foi possível carregar o encontro do sábado.')
      expect(encontro.carregando.value).toBe(false)
    })
  })

  describe('carregarHistorico', () => {
    it('popula a lista de encontros', async () => {
      await encontro.carregarHistorico()
      expect(encontro.encontros.value).toEqual(ENCONTROS)
      expect(supabase.builderDe('encontros').limit).toHaveBeenCalledWith(26)
    })
  })

  describe('selecionar', () => {
    it('seleciona um encontro do histórico', async () => {
      await encontro.carregarHistorico()
      encontro.selecionar('e0')
      expect(encontro.encontro.value?.id).toBe('e0')
      expect(encontro.semAtividade.value).toBe(false)
      expect(encontro.motivoSemAtividade.value).toBeNull()
    })

    it('limpa a seleção quando o id não existe', async () => {
      await encontro.carregarHistorico()
      encontro.selecionar('inexistente')
      expect(encontro.encontro.value).toBeNull()
    })
  })
})
