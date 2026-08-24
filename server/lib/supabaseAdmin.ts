import { createClient } from '@supabase/supabase-js'
import type { Database } from '../types/database.types'

/**
 * Client admin (service_role) — USAR SOMENTE no servidor (server/** e api/**).
 * A chave vem de VITE_SUPABASE_SERVICE_ROLE_KEY (process.env). Nunca importar
 * nada que exponha essa chave em src/ (client).
 */
export function supabaseAdmin() {
  const url = process.env.VITE_SUPABASE_URL ?? 'http://127.0.0.1:54321'
  const key = process.env.VITE_SUPABASE_SERVICE_ROLE_KEY ?? ''
  if (!key) {
    throw new Error('VITE_SUPABASE_SERVICE_ROLE_KEY ausente no servidor')
  }
  return createClient<Database>(url, key, {
    auth: { autoRefreshToken: false, persistSession: false },
  })
}
