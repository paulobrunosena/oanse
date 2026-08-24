import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/types/database.types'

/**
 * Cliente anon do frontend (browser). Usar SOMENTE a chave `anon` — toda
 * autorização vive nas políticas RLS. A chave service_role nunca entra aqui.
 *
 * Valores padrão apontam para o Supabase local (`npx supabase start`); para
 * outro ambiente, defina VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY no `.env`.
 */
const url = import.meta.env.VITE_SUPABASE_URL ?? 'http://127.0.0.1:54321'
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY ?? 'sb_publishable_XXX'

export const supabase = createClient<Database>(url, anonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
  },
})
