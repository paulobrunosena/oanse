import type { H3Event } from 'h3'
import { getHeader } from 'h3'
import { supabaseAdmin } from './supabaseAdmin'

export interface ClaimsUsuario {
  sub: string
  email: string | null
}

/**
 * Obtém o usuário autenticado a partir do token JWT no header Authorization.
 * Equivale ao `serverSupabaseUser` do Nitro, mas o SPA envia o token via Bearer.
 */
export async function getUsuarioDoRequest(event: H3Event): Promise<ClaimsUsuario | null> {
  const auth = getHeader(event, 'authorization')
  if (!auth?.startsWith('Bearer ')) return null

  const token = auth.slice(7).trim()
  if (!token) return null

  const { data, error } = await supabaseAdmin().auth.getUser(token)
  if (error || !data.user) return null

  return { sub: data.user.id, email: data.user.email ?? null }
}
