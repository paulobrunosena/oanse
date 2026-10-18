export interface EnvSupabase {
  url?: string
  anonKey?: string
}

/**
 * Resolve a configuração do cliente Supabase.
 *
 * Em produção, build sem `VITE_SUPABASE_URL`/`VITE_SUPABASE_ANON_KEY` não pode
 * cair silenciosamente no localhost (o app subiria "funcionando" apontando para
 * uma máquina que não existe) — melhor falhar no build.
 */
export function resolverConfigSupabase(env: EnvSupabase, producao: boolean): { url: string, anonKey: string } {
  const url = env.url?.trim()
  const anonKey = env.anonKey?.trim()

  if (producao && (!url || !anonKey)) {
    throw new Error('VITE_SUPABASE_URL e VITE_SUPABASE_ANON_KEY são obrigatórias no build de produção')
  }

  return {
    url: url || 'http://127.0.0.1:54321',
    anonKey: anonKey || 'sb_publishable_XXX',
  }
}
