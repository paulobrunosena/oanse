// @vitest-environment node
import { describe, expect, it } from 'vitest'
import { resolverConfigSupabase } from './env'

describe('resolverConfigSupabase', () => {
  it('usa as variáveis informadas', () => {
    expect(resolverConfigSupabase({
      url: 'https://proj.supabase.co',
      anonKey: 'sb_publishable_abc',
    }, true)).toEqual({
      url: 'https://proj.supabase.co',
      anonKey: 'sb_publishable_abc',
    })
  })

  it('ignora espaços em volta das variáveis', () => {
    expect(resolverConfigSupabase({ url: ' https://x.supabase.co ', anonKey: ' key ' }, true))
      .toEqual({ url: 'https://x.supabase.co', anonKey: 'key' })
  })

  it('cai no padrão local fora de produção', () => {
    expect(resolverConfigSupabase({}, false)).toEqual({
      url: 'http://127.0.0.1:54321',
      anonKey: 'sb_publishable_XXX',
    })
  })

  it('falha em produção sem as variáveis', () => {
    expect(() => resolverConfigSupabase({}, true)).toThrow(/obrigatórias no build de produção/)
    expect(() => resolverConfigSupabase({ url: 'https://x.supabase.co' }, true)).toThrow()
    expect(() => resolverConfigSupabase({ anonKey: 'k' }, true)).toThrow()
  })
})
