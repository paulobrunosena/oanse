import { beforeEach, describe, expect, it, vi } from 'vitest'
import { useTransferenciaClube } from './useTransferenciaClube'

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

describe('useTransferenciaClube', () => {
  beforeEach(() => {
    mocks.supabase = {
      rpc: vi.fn(() => Promise.resolve({ data: {}, error: null })),
    }
  })

  it('chama fn_transferir_clube com oansista, destino e motivo', async () => {
    const api = useTransferenciaClube()
    await api.transferir('o1', 'c2', 'Completou 9 anos')

    expect(mocks.supabase.rpc).toHaveBeenCalledWith('fn_transferir_clube', {
      p_oansista_id: 'o1',
      p_clube_destino_id: 'c2',
      p_motivo: 'Completou 9 anos',
    })
  })

  it('omite o motivo quando vazio', async () => {
    const api = useTransferenciaClube()
    await api.transferir('o1', 'c2', null)

    expect(mocks.supabase.rpc).toHaveBeenCalledWith('fn_transferir_clube', {
      p_oansista_id: 'o1',
      p_clube_destino_id: 'c2',
      p_motivo: undefined,
    })
  })

  it('chama fn_cancelar_transferencia_clube', async () => {
    const api = useTransferenciaClube()
    await api.cancelar('o1')

    expect(mocks.supabase.rpc).toHaveBeenCalledWith('fn_cancelar_transferencia_clube', {
      p_oansista_id: 'o1',
    })
  })

  it('propaga erro da RPC', async () => {
    mocks.supabase.rpc = vi.fn(() => Promise.resolve({ data: null, error: new Error('Apenas o Diretor do clube pode transferir') }))

    const api = useTransferenciaClube()
    await expect(api.transferir('o1', 'c2')).rejects.toThrow('Apenas o Diretor do clube pode transferir')
    await expect(api.cancelar('o1')).rejects.toThrow('Apenas o Diretor do clube pode transferir')
  })
})
