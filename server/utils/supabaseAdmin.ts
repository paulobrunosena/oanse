import { createClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'

/**
 * Client admin (service_role) — USAR SOMENTE EM server/api/**.
 * Criação/exclusão de usuários no Auth e operações administrativas.
 */
export function supabaseAdmin() {
  const config = useRuntimeConfig()
  const url = config.public.supabase.url
  const key = config.supabase.secretKey
  if (!url || !key) {
    throw createError({ statusCode: 500, statusMessage: 'Credenciais do Supabase ausentes no servidor' })
  }
  return createClient<Database>(url, key, {
    auth: { autoRefreshToken: false, persistSession: false },
  })
}
