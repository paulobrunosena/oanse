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
  // Dados devolvidos por from(tabela).select(...).eq(...).single()/maybeSingle()
  tabelas: {} as Record<string, unknown>,
  update: vi.fn(async (_tabela: string, _valores: unknown, _id: string): Promise<{ error: unknown }> => ({ error: null })),
  createUser: vi.fn(async (_input: unknown): Promise<{ data: { user: { id: string } } | null, error: unknown }> => ({
    data: { user: { id: 'novo-1' } },
    error: null,
  })),
  deleteUser: vi.fn(async (_id: string): Promise<{ error: unknown }> => ({ error: null })),
}))

vi.mock('./lib/supabaseAdmin', () => ({
  supabaseAdmin: () => ({
    rpc: (fn: string, args: unknown) => mocks.rpc(fn, args),
    from: (tabela: string) => ({
      select: () => ({
        eq: () => ({
          single: async () => ({ data: mocks.tabelas[tabela] ?? null, error: null }),
          maybeSingle: async () => ({ data: mocks.tabelas[tabela] ?? null, error: null }),
        }),
      }),
      insert: () => ({
        select: () => ({
          single: async () => ({ data: mocks.tabelas[`${tabela}:insert`] ?? null, error: null }),
        }),
      }),
      update: (valores: unknown) => ({
        eq: async (coluna: string, id: string) => mocks.update(tabela, valores, id),
      }),
    }),
    auth: {
      admin: {
        createUser: (input: unknown) => mocks.createUser(input),
        deleteUser: (id: string) => mocks.deleteUser(id),
        listUsers: async () => ({ data: { users: [] }, error: null }),
      },
    },
  }),
}))

vi.mock('./lib/auth', () => ({
  getUsuarioDoRequest: mocks.usuario,
}))

import { createApiApp } from './router'
import { sabadoCorrente } from './utils/sabado'

const handler = toPlainHandler(createApiApp())

function post(path: string, body: unknown) {
  return handler({
    method: 'POST',
    path,
    headers: { 'content-type': 'application/json', authorization: 'Bearer token' },
    body: JSON.stringify(body),
  })
}

function request(method: string, path: string) {
  return handler({
    method,
    path,
    headers: { 'content-type': 'application/json', authorization: 'Bearer token' },
  })
}

/** Sábado `semanas` atrás do sábado corrente (formato YYYY-MM-DD local). */
function sabadoAtras(semanas: number): string {
  const d = new Date(`${sabadoCorrente()}T00:00:00`)
  d.setDate(d.getDate() - semanas * 7)
  const mes = String(d.getMonth() + 1).padStart(2, '0')
  const dia = String(d.getDate()).padStart(2, '0')
  return `${d.getFullYear()}-${mes}-${dia}`
}

beforeEach(() => {
  mocks.rpc.mockReset()
  mocks.rpc.mockResolvedValue({ data: { id: 'm1' }, error: null })
  mocks.usuario.mockReset()
  mocks.usuario.mockResolvedValue({ sub: 'sec-1', email: 'sec@oan.se' })
  mocks.tabelas = {}
  mocks.update.mockClear()
  mocks.createUser.mockClear()
  mocks.createUser.mockResolvedValue({ data: { user: { id: 'novo-1' } }, error: null })
  mocks.deleteUser.mockClear()
  mocks.deleteUser.mockResolvedValue({ error: null })
})

describe('rotas de premios (server/router.ts)', () => {
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

  it('aceita entrega sem body (observacao é opcional)', async () => {
    const res = await handler({
      method: 'POST',
      path: '/api/premios/pend1/entregar',
      headers: { 'content-type': 'application/json', authorization: 'Bearer token' },
    })

    expect(res.status).toBe(200)
    expect(mocks.rpc).toHaveBeenCalledWith('fn_entregar_premio', {
      p_pendencia_id: 'pend1',
      p_autorizado_por: 'sec-1',
      p_observacao: undefined,
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

describe('POST /api/transferencias (autorização na borda)', () => {
  const body = { oansista_id: 'o1', turma_destino_id: 't2' }

  it('diretor do clube da criança transfere e a RPC recebe o autorizado', async () => {
    mocks.tabelas = {
      profiles: { role: 'diretor_clube', ativo: true, clube_id: 'c1' },
      oansistas: { clube_id: 'c1' },
    }

    const res = await post('/api/transferencias', body)

    expect(res.status).toBe(200)
    expect(mocks.rpc).toHaveBeenCalledWith('fn_transferir_oansista', {
      p_oansista_id: 'o1',
      p_turma_destino_id: 't2',
      p_motivo: undefined,
      p_autorizado_por: 'sec-1',
    })
  })

  it('líder recebe 403 e a RPC não é chamada', async () => {
    mocks.tabelas = {
      profiles: { role: 'lider', ativo: true, clube_id: 'c1' },
      oansistas: { clube_id: 'c1' },
    }

    const res = await post('/api/transferencias', body)

    expect(res.status).toBe(403)
    expect(mocks.rpc).not.toHaveBeenCalled()
  })

  it('diretor de outro clube recebe 403', async () => {
    mocks.tabelas = {
      profiles: { role: 'diretor_clube', ativo: true, clube_id: 'c2' },
      oansistas: { clube_id: 'c1' },
    }

    const res = await post('/api/transferencias', body)

    expect(res.status).toBe(403)
  })

  it('usuário inativo recebe 403', async () => {
    mocks.tabelas = {
      profiles: { role: 'diretor_geral', ativo: false, clube_id: null },
      oansistas: { clube_id: 'c1' },
    }

    const res = await post('/api/transferencias', body)

    expect(res.status).toBe(403)
  })

  it('responde 400 quando a criança não existe', async () => {
    mocks.tabelas = {
      profiles: { role: 'diretor_geral', ativo: true, clube_id: null },
    }

    const res = await post('/api/transferencias', body)

    expect(res.status).toBe(400)
    expect(mocks.rpc).not.toHaveBeenCalled()
  })
})

describe('POST /api/encontros/retro (autorização e janela)', () => {
  it('líder registra um sábado recente e devolve o encontro existente', async () => {
    mocks.tabelas = {
      profiles: { role: 'lider', ativo: true, clube_id: 'c1' },
      encontros: { id: 'e1', data: sabadoAtras(1), ativo: true },
    }

    const res = await post('/api/encontros/retro', { data: sabadoAtras(1) })

    expect(res.status).toBe(200)
    expect(JSON.parse(String(res.body))).toMatchObject({ criado: false })
  })

  it('lider_jogos recebe 403', async () => {
    mocks.tabelas = { profiles: { role: 'lider_jogos', ativo: true, clube_id: null } }

    const res = await post('/api/encontros/retro', { data: sabadoAtras(1) })

    expect(res.status).toBe(403)
  })

  it('limita o backfill às últimas 12 semanas', async () => {
    mocks.tabelas = { profiles: { role: 'lider', ativo: true, clube_id: 'c1' } }

    const res = await post('/api/encontros/retro', { data: sabadoAtras(15) })

    expect(res.status).toBe(400)
  })

  it('recusa data que não é sábado', async () => {
    mocks.tabelas = { profiles: { role: 'lider', ativo: true, clube_id: 'c1' } }

    const res = await post('/api/encontros/retro', { data: '2026-10-14' })

    expect(res.status).toBe(400)
  })
})

describe('POST /api/usuarios (papel definido com service_role)', () => {
  it('aceita lider_jogos, envia metadata sem papel e define o perfil explicitamente', async () => {
    mocks.tabelas = { profiles: { role: 'diretor_geral', ativo: true, clube_id: null } }

    const res = await post('/api/usuarios', {
      nome: 'Líder de Jogos',
      email: 'jogo@oanse.local',
      senha: 'oanse123',
      role: 'lider_jogos',
    })

    expect(res.status).toBe(200)
    expect(mocks.createUser).toHaveBeenCalledWith({
      email: 'jogo@oanse.local',
      password: 'oanse123',
      email_confirm: true,
      user_metadata: { nome: 'Líder de Jogos', telefone: null },
    })
    expect(mocks.update).toHaveBeenCalledWith(
      'profiles',
      { role: 'lider_jogos', clube_id: null },
      'novo-1',
    )
    expect(mocks.deleteUser).not.toHaveBeenCalled()
  })

  it('recusa papel fora do enum user_role', async () => {
    mocks.tabelas = { profiles: { role: 'diretor_geral', ativo: true, clube_id: null } }

    const res = await post('/api/usuarios', {
      nome: 'X',
      email: 'x@oanse.local',
      senha: 'oanse123',
      role: 'hacker',
    })

    expect(res.status).toBe(400)
    expect(mocks.createUser).not.toHaveBeenCalled()
  })

  it('desfaz a criação quando o perfil não pode ser atualizado', async () => {
    mocks.tabelas = { profiles: { role: 'diretor_geral', ativo: true, clube_id: null } }
    mocks.update.mockResolvedValueOnce({ error: { message: 'falhou' } })

    const res = await post('/api/usuarios', {
      nome: 'X',
      email: 'x@oanse.local',
      senha: 'oanse123',
      role: 'lider',
    })

    expect(res.status).toBe(500)
    expect(mocks.deleteUser).toHaveBeenCalledWith('novo-1')
  })

  it('não-diretor recebe 403', async () => {
    mocks.tabelas = { profiles: { role: 'secretaria', ativo: true, clube_id: null } }

    const res = await post('/api/usuarios', {
      nome: 'X',
      email: 'x@oanse.local',
      senha: 'oanse123',
      role: 'lider',
    })

    expect(res.status).toBe(403)
    expect(mocks.createUser).not.toHaveBeenCalled()
  })
})

describe('DELETE /api/usuarios/:id', () => {
  it('diretor_geral ativo exclui o usuário', async () => {
    mocks.tabelas = { profiles: { role: 'diretor_geral', ativo: true, clube_id: null } }

    const res = await request('DELETE', '/api/usuarios/u2')

    expect(res.status).toBe(200)
    expect(mocks.deleteUser).toHaveBeenCalledWith('u2')
  })

  it('diretor inativo recebe 403', async () => {
    mocks.tabelas = { profiles: { role: 'diretor_geral', ativo: false, clube_id: null } }

    const res = await request('DELETE', '/api/usuarios/u2')

    expect(res.status).toBe(403)
    expect(mocks.deleteUser).not.toHaveBeenCalled()
  })
})
