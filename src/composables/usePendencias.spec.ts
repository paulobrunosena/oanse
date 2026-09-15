// @vitest-environment node
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { builder, clienteSupabase } from '../../tests/helpers/supabase'
import { normalizarPendencia, usePendencias, type LinhaPendencia } from './usePendencias'

const LINHA: LinhaPendencia = {
  id: 'pp1',
  status: 'pendente',
  data_geracao: '2026-09-15T10:00:00Z',
  data_entrega: null,
  oansistas: { nome: 'Ana' },
  premios: { nome: 'Botão vermelho 01', tipo: 'botom' },
  clubes: { nome: 'Faíscas' },
}

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

describe('normalizarPendencia', () => {
  it('mapeia os nomes via join', () => {
    expect(normalizarPendencia(LINHA)).toEqual({
      id: 'pp1',
      status: 'pendente',
      data_geracao: '2026-09-15T10:00:00Z',
      data_entrega: null,
      clube_nome: 'Faíscas',
      oansista_nome: 'Ana',
      premio_nome: 'Botão vermelho 01',
      premio_tipo: 'botom',
    })
  })

  it('usa fallback "?" quando o join vem nulo', () => {
    const r = normalizarPendencia({ ...LINHA, oansistas: null, premios: null, clubes: null })
    expect(r).toMatchObject({ clube_nome: '?', oansista_nome: '?', premio_nome: '?' })
  })
})

describe('usePendencias', () => {
  const canal = {
    on: vi.fn((_event: string, _filter: object, _cb: (p: unknown) => void) => canal),
    subscribe: vi.fn(() => canal),
  }

  beforeEach(() => {
    canal.on.mockClear()
    canal.subscribe.mockClear()
    mocks.supabase = clienteSupabase({ premios_pendentes: () => builder([LINHA]) })
    mocks.supabase.channel = vi.fn(() => canal)
    mocks.supabase.removeChannel = vi.fn(() => Promise.resolve())
  })

  it('carrega e normaliza as pendências', async () => {
    const { pendencias, carregar } = usePendencias()
    await carregar()

    expect(mocks.supabase.from).toHaveBeenCalledWith('premios_pendentes')
    expect(pendencias.value).toHaveLength(1)
    expect(pendencias.value[0]!.oansista_nome).toBe('Ana')
  })

  it('aplica o filtro de status quando informado', async () => {
    const { carregar } = usePendencias()
    await carregar('entregue')

    expect(mocks.supabase.builderDe('premios_pendentes').eq).toHaveBeenCalledWith('status', 'entregue')
  })

  it('não aplica filtro quando status é undefined', async () => {
    const { carregar } = usePendencias()
    await carregar()

    expect(mocks.supabase.builderDe('premios_pendentes').eq).not.toHaveBeenCalled()
  })

  it('aplica o filtro de clube quando informado', async () => {
    const { carregar } = usePendencias()
    await carregar('pendente', 'c2')

    expect(mocks.supabase.builderDe('premios_pendentes').eq).toHaveBeenCalledWith('status', 'pendente')
    expect(mocks.supabase.builderDe('premios_pendentes').eq).toHaveBeenCalledWith('clube_id', 'c2')
  })

  it('inscreve no canal de tempo real e devolve função de cancelamento', () => {
    const { inscrever } = usePendencias()
    const cancelar = inscrever()

    expect(mocks.supabase.channel).toHaveBeenCalledWith('pendencias-realtime')
    expect(canal.on).toHaveBeenCalledWith(
      'postgres_changes',
      { event: '*', schema: 'public', table: 'premios_pendentes' },
      expect.any(Function),
    )
    expect(canal.subscribe).toHaveBeenCalled()

    cancelar()
    expect(mocks.supabase.removeChannel).toHaveBeenCalledWith(canal)
  })

  it('repassa o payload do realtime ao callback informado', () => {
    const { inscrever } = usePendencias()
    const aoChegar = vi.fn()
    inscrever(aoChegar)

    const handler = canal.on.mock.calls[0]![2]
    const payload = { eventType: 'INSERT', new: { status: 'pendente' } }
    handler(payload)

    expect(aoChegar).toHaveBeenCalledWith(payload)
  })
})
