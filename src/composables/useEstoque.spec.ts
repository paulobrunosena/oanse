// @vitest-environment node
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { builder, clienteSupabase } from '../../tests/helpers/supabase'
import { normalizarMovimentacao, useEstoque, type LinhaMovimentacao } from './useEstoque'

const LINHA: LinhaMovimentacao = {
  id: 'm1',
  tipo: 'entrada',
  quantidade: 10,
  observacao: 'Reposição',
  created_at: '2026-09-15T10:00:00Z',
  premio_id: 'p1',
  premios: { nome: 'Botão vermelho 01' },
  profiles: { nome: 'Secretária' },
}

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

const api = vi.hoisted(() => ({ apiFetch: vi.fn(() => Promise.resolve({})) }))
vi.mock('@/lib/api', () => ({
  apiFetch: api.apiFetch,
}))

describe('normalizarMovimentacao', () => {
  it('mapeia os nomes via join', () => {
    expect(normalizarMovimentacao(LINHA)).toEqual({
      id: 'm1',
      tipo: 'entrada',
      quantidade: 10,
      observacao: 'Reposição',
      created_at: '2026-09-15T10:00:00Z',
      premio_id: 'p1',
      premio_nome: 'Botão vermelho 01',
      feito_por_nome: 'Secretária',
    })
  })

  it('usa fallback "?" quando o join vem nulo', () => {
    const r = normalizarMovimentacao({ ...LINHA, premios: null, profiles: null })
    expect(r).toMatchObject({ premio_nome: '?', feito_por_nome: '?' })
  })
})

describe('useEstoque', () => {
  beforeEach(() => {
    api.apiFetch.mockReset()
    api.apiFetch.mockResolvedValue({})
    mocks.supabase = clienteSupabase({ premios_movimentacoes: () => builder([LINHA]) })
  })

  it('carrega o histórico de movimentações com nomes via join', async () => {
    const { movimentacoes, carregar } = useEstoque()
    await carregar()

    expect(mocks.supabase.from).toHaveBeenCalledWith('premios_movimentacoes')
    expect(movimentacoes.value).toHaveLength(1)
    expect(movimentacoes.value[0]!.premio_nome).toBe('Botão vermelho 01')
    expect(movimentacoes.value[0]!.feito_por_nome).toBe('Secretária')
  })

  it('filtra por prêmio quando informado', async () => {
    const { carregar } = useEstoque()
    await carregar('p1')

    expect(mocks.supabase.builderDe('premios_movimentacoes').eq).toHaveBeenCalledWith('premio_id', 'p1')
  })

  it('registra entrada/saída via server route', async () => {
    const { registrar } = useEstoque()
    await registrar('p1', 'saida', 3, 'Entrega')

    expect(api.apiFetch).toHaveBeenCalledWith('/api/premios/p1/movimentacoes', {
      method: 'POST',
      body: { tipo: 'saida', quantidade: 3, observacao: 'Entrega' },
    })
  })
})
