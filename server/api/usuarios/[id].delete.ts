import { serverSupabaseUser } from '#supabase/server'

/**
 * Exclui usuário (auth + profile via cascade) — Diretor Geral.
 */
export default defineEventHandler(async (event) => {
  const claims = await serverSupabaseUser(event)
  if (!claims?.sub) {
    throw createError({ statusCode: 401, statusMessage: 'Não autenticado' })
  }

  const id = getRouterParam(event, 'id')
  if (!id) {
    throw createError({ statusCode: 400, statusMessage: 'ID ausente' })
  }

  if (id === claims.sub) {
    throw createError({ statusCode: 400, statusMessage: 'Você não pode excluir a si mesmo' })
  }

  const admin = supabaseAdmin()

  const { data: perfil } = await admin
    .from('profiles')
    .select('role')
    .eq('id', claims.sub)
    .single()

  if (perfil?.role !== 'diretor_geral') {
    throw createError({ statusCode: 403, statusMessage: 'Apenas o Diretor Geral pode excluir usuários' })
  }

  const { error } = await admin.auth.admin.deleteUser(id)
  if (error) {
    throw createError({ statusCode: 500, statusMessage: error.message })
  }

  return { ok: true }
})
