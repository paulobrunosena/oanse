// @vitest-environment happy-dom
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { ApiError, apiFetch } from './api'

const mocks = vi.hoisted(() => ({
  supabase: {
    auth: {
      getSession: vi.fn(async () => ({ data: { session: { access_token: 'token-123' } }, error: null })),
    },
  },
}))

vi.mock('./supabase', () => ({
  supabase: mocks.supabase,
}))

function respostaJson(body: unknown, init: Partial<Response> = {}) {
  return {
    ok: true,
    status: 200,
    statusText: 'OK',
    json: vi.fn(async () => body),
    ...init,
  } as unknown as Response
}

describe('apiFetch', () => {
  beforeEach(() => {
    mocks.supabase.auth.getSession.mockResolvedValue({ data: { session: { access_token: 'token-123' } }, error: null })
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('serializa o body e envia o token de acesso', async () => {
    const fetchMock = vi.fn(async () => respostaJson({ ok: true }))
    vi.stubGlobal('fetch', fetchMock)

    await apiFetch('/api/premios/p1/movimentacoes', {
      method: 'POST',
      body: { tipo: 'entrada', quantidade: 1 },
    })

    expect(fetchMock).toHaveBeenCalledTimes(1)
    const [url, init] = fetchMock.mock.calls[0] as unknown as [string, RequestInit]
    expect(url).toBe('/api/premios/p1/movimentacoes')
    expect(JSON.parse(init.body as string)).toEqual({ tipo: 'entrada', quantidade: 1 })
    expect((init.headers as Record<string, string>).Authorization).toBe('Bearer token-123')
    expect((init.headers as Record<string, string>)['Content-Type']).toBe('application/json')
  })

  it('retorna o JSON da resposta', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => respostaJson({ id: 'm1' })))

    const resultado = await apiFetch<{ id: string }>('/api/x')

    expect(resultado).toEqual({ id: 'm1' })
  })

  it('lança ApiError com a mensagem do backend em erro JSON', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => respostaJson(
      { statusMessage: 'Estoque insuficiente' },
      { ok: false, status: 400, statusText: 'Bad Request' },
    )))

    await expect(apiFetch('/api/x', { method: 'POST', body: {} })).rejects.toMatchObject({
      status: 400,
      statusMessage: 'Estoque insuficiente',
      message: 'Estoque insuficiente',
    })
  })

  it('usa o statusText quando o erro não é JSON (ex.: 502 do proxy)', async () => {
    const fetchMock = vi.fn(async () => respostaJson(
      undefined,
      { ok: false, status: 502, statusText: 'Bad Gateway', json: vi.fn(async () => { throw new Error('not json') }) },
    ))
    vi.stubGlobal('fetch', fetchMock)

    await expect(apiFetch('/api/x', { method: 'POST', body: {} })).rejects.toMatchObject({
      status: 502,
      message: 'Bad Gateway',
    })
  })

  it('lança ApiError de conexão quando o fetch falha', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => { throw new TypeError('fetch failed') }))

    await expect(apiFetch('/api/x')).rejects.toBeInstanceOf(ApiError)
    await expect(apiFetch('/api/x')).rejects.toMatchObject({
      status: 0,
      message: 'Não foi possível conectar ao servidor',
    })
  })
})
