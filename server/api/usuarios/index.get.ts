import { serverSupabaseUser } from '#supabase/server'

/**
 * Lista todos os usuários (auth.users + profiles) — Diretor Geral.
 */
export default defineEventHandler(async (event) => {
  const claims = await serverSupabaseUser(event)
  if (!claims?.sub) {
    throw createError({ statusCode: 401, statusMessage: 'Não autenticado' })
  }

  const admin = supabaseAdmin()

  const { data: perfil } = await admin
    .from('profiles')
    .select('role')
    .eq('id', claims.sub)
    .single()

  if (perfil?.role !== 'diretor_geral') {
    throw createError({ statusCode: 403, statusMessage: 'Apenas o Diretor Geral pode listar usuários' })
  }

  const [{ data: usuarios, error: errUsers }, { data: perfis }] = await Promise.all([
    admin.auth.admin.listUsers({ perPage: 1000 }),
    admin.from('profiles').select('*'),
  ])

  if (errUsers) {
    throw createError({ statusCode: 500, statusMessage: errUsers.message })
  }

  const perfisPorId = new Map((perfis ?? []).map(p => [p.id, p]))

  return usuarios.users
    .map(u => ({
      id: u.id,
      email: u.email ?? '',
      ...(perfisPorId.get(u.id) ?? null),
    }))
    .filter(u => 'role' in u)
    .sort((a, b) => (a.nome ?? '').localeCompare(b.nome ?? ''))
})
