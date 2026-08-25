import { vi } from 'vitest'

export type Resultado<T = unknown> = { data: T | null, error: unknown }

export function resposta<T>(data: T | null, error: unknown = null): Resultado<T> {
  return { data, error }
}

/**
 * Builder de cadeia do Supabase (`from(...).select().eq()...`).
 *
 * Todos os métodos encadeáveis retornam o próprio builder, de modo que `await`
 * numa cadeia resolva para `{ data, error }` (data/error do builder). O terminal
 * `.single()` é uma Promise cujo `data` vem de `singleData` (mutável por teste),
 * permitindo simular o retorno de um UPDATE/INSERT sem misturar com o `data`
 * usado nas leituras encadeadas.
 */
export function builder<T = unknown>(data: T | null, error: unknown = null) {
  const b = {
    data,
    error,
    singleData: data,
    select: vi.fn(() => b),
    eq: vi.fn(() => b),
    in: vi.fn(() => b),
    not: vi.fn(() => b),
    order: vi.fn(() => b),
    limit: vi.fn(() => b),
    update: vi.fn(() => b),
    insert: vi.fn(() => b),
    upsert: vi.fn(() => b),
    delete: vi.fn(() => b),
    maybeSingle: vi.fn(() => b),
    single: vi.fn(() => Promise.resolve({ data: b.singleData, error: b.error })),
  }
  return b
}

/**
 * Cliente Supabase de teste: `from(tabela)` devolve um builder por tabela.
 * Opcionalmente recebe um mapa `{ tabela: () => builder }` para configurar
 * dados por teste.
 */
export function clienteSupabase(
  tabelas: Record<string, () => ReturnType<typeof builder>> = {},
) {
  const chamadas: Record<string, ReturnType<typeof builder>> = {}

  const obter = (tabela: string) => {
    if (!chamadas[tabela]) {
      chamadas[tabela] = tabelas[tabela]?.() ?? builder(null)
    }
    return chamadas[tabela]
  }

  const from = vi.fn((tabela: string) => obter(tabela))

  return {
    from,
    rpc: vi.fn(() => Promise.resolve({ data: null, error: null })),
    auth: {
      signOut: vi.fn(() => Promise.resolve()),
      getSession: vi.fn(() => Promise.resolve({ data: { session: null }, error: null })),
    },
    builderDe: obter,
  }
}
