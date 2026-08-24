import { supabase } from './supabase'

/**
 * Erro de API com status HTTP e mensagem amigável (statusMessage).
 * O backend (h3) responde com { statusMessage } em respostas de erro.
 */
export class ApiError extends Error {
  status: number
  statusMessage?: string

  constructor(status: number, statusMessage?: string) {
    super(statusMessage ?? 'Erro na requisição')
    this.name = 'ApiError'
    this.status = status
    this.statusMessage = statusMessage
  }
}

export type ApiOptions = Omit<RequestInit, 'body'> & { body?: unknown }

/**
 * Wrapper de fetch para as rotas do backend (/api/**).
 * Serializa body de objetos, parseia JSON e lança ApiError em respostas de erro.
 */
export async function apiFetch<T = unknown>(path: string, options: ApiOptions = {}): Promise<T> {
  let res: Response
  try {
    const body = isPlainObject(options.body)
      ? JSON.stringify(options.body)
      : (options.body as BodyInit | undefined)

    const { data: sessao } = await supabase.auth.getSession()
    const token = sessao.session?.access_token
    const headers = { 'Content-Type': 'application/json', ...(options.headers ?? {}) }
    if (token) {
      (headers as Record<string, string>).Authorization = `Bearer ${token}`
    }

    res = await fetch(path, {
      ...options,
      body,
      headers,
    })
  }
  catch {
    throw new ApiError(0, 'Não foi possível conectar ao servidor')
  }

  const corpo = await res.json().catch(() => null) as { statusMessage?: string } | null

  if (!res.ok) {
    throw new ApiError(res.status, corpo?.statusMessage)
  }

  return corpo as T
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return value != null && typeof value === 'object' && !(value instanceof FormData)
}
