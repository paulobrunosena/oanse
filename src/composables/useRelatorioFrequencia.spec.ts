// @vitest-environment node
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { clienteSupabase } from '../../tests/helpers/supabase'
import {
  percentualFrequencia,
  useRelatorioFrequencia,
  type LinhaFrequencia,
} from './useRelatorioFrequencia'

const LINHAS: LinhaFrequencia[] = [
  {
    oansista_id: 'o1',
    oansista_nome: 'Ana',
    clube_nome: 'Faíscas',
    turma_nome: 'Turma 1',
    presencas: 4,
    faltas: 1,
    total_encontros: 5,
  },
]

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

describe('percentualFrequencia', () => {
  it('arredonda o percentual de presenças', () => {
    expect(percentualFrequencia(LINHAS[0]!)).toBe(80)
  })

  it('retorna 0 quando não há encontros no período', () => {
    expect(percentualFrequencia({ ...LINHAS[0]!, presencas: 0, faltas: 0, total_encontros: 0 })).toBe(0)
  })
})

describe('useRelatorioFrequencia', () => {
  beforeEach(() => {
    mocks.supabase = clienteSupabase()
  })

  it('carrega a frequência via RPC e normaliza', async () => {
    mocks.supabase.rpc.mockResolvedValue({ data: LINHAS, error: null })
    const { linhas, carregando, carregar } = useRelatorioFrequencia()
    await carregar('2026-01-01', '2026-12-31')

    expect(mocks.supabase.rpc).toHaveBeenCalledWith('fn_frequencia_acumulada', {
      p_de: '2026-01-01',
      p_ate: '2026-12-31',
    })
    expect(linhas.value).toHaveLength(1)
    expect(linhas.value[0]).toEqual(LINHAS[0])
    expect(carregando.value).toBe(false)
  })

  it('converte contagens bigint/string em número e turma nula em vazio', async () => {
    mocks.supabase.rpc.mockResolvedValue({
      data: [{ ...LINHAS[0], turma_nome: null, presencas: '4', faltas: '1', total_encontros: '5' }],
      error: null,
    })
    const { linhas, carregar } = useRelatorioFrequencia()
    await carregar('2026-01-01', '2026-12-31')

    expect(linhas.value[0]!.presencas).toBe(4)
    expect(linhas.value[0]!.turma_nome).toBe('')
  })

  it('lança erro quando a RPC falha', async () => {
    mocks.supabase.rpc.mockResolvedValue({ data: null, error: { message: 'Falha' } })
    const { carregar } = useRelatorioFrequencia()
    await expect(carregar('2026-01-01', '2026-12-31')).rejects.toThrow('Falha')
  })
})
