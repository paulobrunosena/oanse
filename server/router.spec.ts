// @vitest-environment node
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { toPlainHandler } from 'h3'

const mocks = vi.hoisted(() => ({
  rpc: vi.fn(async (_fn: string, _args: unknown): Promise<{ data: unknown, error: unknown }> => ({
    data: null,
    error: null,
  })),
  usuario: vi.fn(async (_event: unknown): Promise<{ sub: string, email: string } | null> => ({
    sub: 'sec-1',
    email: 'sec@oan.se',
  })),
}))

vi.mock('./lib/supabaseAdmin', () => ({
  supabaseAdmin: () => ({ rpc: mocks.rpc }),
}))

vi.mock('./lib/auth', () => ({
  getUsuarioDoRequest: mocks.usuario,
}))

import { createApiApp } from './router'

const handler = toPlainHandler(createApiApp())

function post(path: string, body: unknown) {
  return handler({
    method: 'POST',
    path,
    headers: { 'content-type': 'application/json', authorization: 'Bearer token' },
    body: JSON.stringify(body),
  })
}

describe('rotas de premios (server/router.ts)', () => {
  beforeEach(() => {
    mocks.rpc.mockReset()
    mocks.rpc.mockResolvedValue({ data: { id: 'm1' }, error: null })
    mocks.usuario.mockReset()
    mocks.usuario.mockResolvedValue({ sub: 'sec-1', email: 'sec@oan.se' })
  })

  it('monta POST /api/premios/:id/movimentacoes chamando fn_movimentar_estoque', async () => {
    const res = await post('/api/premios/p1/movimentacoes', {
      tipo: 'entrada',
      quantidade: 5,
      observacao: 'Reposição',
    })

    expect(res.status).toBe(200)
    expect(mocks.rpc).toHaveBeenCalledTimes(1)
    expect(mocks.rpc).toHaveBeenCalledWith('fn_movimentar_estoque', {
      p_premio_id: 'p1',
      p_tipo: 'entrada',
      p_quantidade: 5,
      p_observacao: 'Reposição',
      p_autorizado_por: 'sec-1',
    })
  })

  it('monta POST /api/premios/:id/entregar chamando fn_entregar_premio', async () => {
    const res = await post('/api/premios/pend1/entregar', { observacao: 'ok' })

    expect(res.status).toBe(200)
    expect(mocks.rpc).toHaveBeenCalledWith('fn_entregar_premio', {
      p_pendencia_id: 'pend1',
      p_autorizado_por: 'sec-1',
      p_observacao: 'ok',
    })
  })

  it('normaliza observacao vazia para undefined na movimentação', async () => {
    const res = await post('/api/premios/p1/movimentacoes', {
      tipo: 'saida',
      quantidade: 2,
      observacao: '   ',
    })

    expect(res.status).toBe(200)
    expect(mocks.rpc).toHaveBeenCalledWith('fn_movimentar_estoque', {
      p_premio_id: 'p1',
      p_tipo: 'saida',
      p_quantidade: 2,
      p_observacao: undefined,
      p_autorizado_por: 'sec-1',
    })
  })

  it('responde 401 quando não há usuário autenticado', async () => {
    mocks.usuario.mockResolvedValue(null)

    const res = await post('/api/premios/p1/movimentacoes', { tipo: 'entrada', quantidade: 1 })

    expect(res.status).toBe(401)
    expect(mocks.rpc).not.toHaveBeenCalled()
  })

  it('responde 400 quando a RPC retorna erro (ex.: estoque insuficiente)', async () => {
    mocks.rpc.mockResolvedValue({ data: null, error: { message: 'Estoque insuficiente para esta saída' } })

    const res = await post('/api/premios/p1/movimentacoes', { tipo: 'saida', quantidade: 999 })

    expect(res.status).toBe(400)
  })
})
