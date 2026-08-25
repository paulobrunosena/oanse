import { beforeEach, describe, expect, it, vi } from 'vitest'
import { clienteSupabase } from '../../tests/helpers/supabase'
import { ordenarGeral, useRanking, type LinhaRanking } from './useRanking'

const LINHAS: LinhaRanking[] = [
  { clube_nome: 'Ursinhos', oansista_id: 'o1', oansista_nome: 'Ana', total: 80, posicao: 1 },
  { clube_nome: 'Ursinhos', oansista_id: 'o2', oansista_nome: 'Bia', total: 80, posicao: 1 },
  { clube_nome: 'Ursinhos', oansista_id: 'o3', oansista_nome: 'Cai', total: 70, posicao: 3 },
]

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

describe('useRanking', () => {
  beforeEach(() => {
    mocks.supabase = clienteSupabase()
  })

  it('carrega as linhas do ranking do encontro via RPC', async () => {
    mocks.supabase.rpc.mockResolvedValue({ data: LINHAS, error: null })
    const ranking = useRanking()
    await ranking.carregar('e1')

    expect(mocks.supabase.rpc).toHaveBeenCalledWith('fn_ranking_do_encontro', { p_encontro_id: 'e1' })
    expect(ranking.linhas.value).toHaveLength(3)
    expect(ranking.linhas.value[0]).toEqual(LINHAS[0])
    expect(ranking.carregando.value).toBe(false)
  })

  it('lança erro quando a RPC falha', async () => {
    mocks.supabase.rpc.mockResolvedValue({ data: null, error: { message: 'Falha' } })
    const ranking = useRanking()
    await expect(ranking.carregar('e1')).rejects.toThrow('Falha')
  })
})

describe('ordenarGeral', () => {
  it('reordena por total desc mantendo empates na mesma posição', () => {
    const geral = ordenarGeral(LINHAS)
    expect(geral.map(l => [l.oansista_nome, l.posicao])).toEqual([
      ['Ana', 1],
      ['Bia', 1],
      ['Cai', 3],
    ])
  })

  it('desempata por nome quando os totais são iguais', () => {
    const linhas = [
      { clube_nome: 'X', oansista_id: 'a', oansista_nome: 'Zeca', total: 50, posicao: 1 },
      { clube_nome: 'X', oansista_id: 'b', oansista_nome: 'Ana', total: 50, posicao: 1 },
    ]
    const geral = ordenarGeral(linhas)
    expect(geral[0]!.oansista_nome).toBe('Ana')
    expect(geral[1]!.oansista_nome).toBe('Zeca')
  })

  it('não modifica o array original', () => {
    const copia = [...LINHAS]
    ordenarGeral(LINHAS)
    expect(LINHAS).toEqual(copia)
  })
})