// @vitest-environment node
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { builder, clienteSupabase } from '../../tests/helpers/supabase'
import { normalizarPremiacao, useRelatorioPremiacoes, type LinhaPremiacao } from './useRelatorioPremiacoes'

const LINHA: LinhaPremiacao = {
  id: 'fp1',
  data_recebimento: '2026-09-10',
  oansistas: { nome: 'Ana', clubes: { nome: 'Faíscas' } },
  folha_blocos: { premio_nome: 'Botão vermelho 01' },
}

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

describe('normalizarPremiacao', () => {
  it('mapeia os nomes via join', () => {
    expect(normalizarPremiacao(LINHA)).toEqual({
      id: 'fp1',
      data_recebimento: '2026-09-10',
      oansista_nome: 'Ana',
      clube_nome: 'Faíscas',
      premio_nome: 'Botão vermelho 01',
    })
  })

  it('usa fallback "?" quando o join vem nulo', () => {
    const r = normalizarPremiacao({ ...LINHA, oansistas: null, folha_blocos: null })
    expect(r).toMatchObject({ oansista_nome: '?', clube_nome: '?', premio_nome: '?' })
  })
})

describe('useRelatorioPremiacoes', () => {
  beforeEach(() => {
    mocks.supabase = clienteSupabase({ folha_premio_progresso: () => builder([LINHA]) })
  })

  it('filtra pelo período e normaliza', async () => {
    const { premiacoes, carregar } = useRelatorioPremiacoes()
    await carregar('2026-09-01', '2026-09-30')

    const b = mocks.supabase.builderDe('folha_premio_progresso')
    expect(b.gte).toHaveBeenCalledWith('data_recebimento', '2026-09-01')
    expect(b.lte).toHaveBeenCalledWith('data_recebimento', '2026-09-30')
    expect(premiacoes.value).toHaveLength(1)
    expect(premiacoes.value[0]!.premio_nome).toBe('Botão vermelho 01')
  })
})
