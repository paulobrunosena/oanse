import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/types/database.types'
import { resolverConfigSupabase } from './env'

/**
 * Cliente anon do frontend (browser). Usar SOMENTE a chave `anon` — toda
 * autorização vive nas políticas RLS. A chave service_role nunca entra aqui.
 *
 * Valores padrão apontam para o Supabase local (`npx supabase start`); para
 * outro ambiente, defina VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY no `.env`
 * (obrigatórias no build de produção — ver `resolverConfigSupabase`).
 */
const { url, anonKey } = resolverConfigSupabase({
  url: import.meta.env.VITE_SUPABASE_URL,
  anonKey: import.meta.env.VITE_SUPABASE_ANON_KEY,
}, import.meta.env.PROD)

export const supabase = createClient<Database>(url, anonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
  },
})
