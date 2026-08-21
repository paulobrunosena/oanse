import { serverSupabaseUser } from '#supabase/server'
import type { UserRole } from '~/composables/useAuth'

const ROLES_VALIDAS: UserRole[] = ['diretor_geral', 'secretaria', 'diretor_clube', 'lider']

/**
 * Cria usuário (auth + profile) — Diretor Geral.
 * Body: { nome, email, senha, telefone?, role, clube_id? }
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
    throw createError({ statusCode: 403, statusMessage: 'Apenas o Diretor Geral pode criar usuários' })
  }

  const body = await readBody<{
    nome?: string
    email?: string
    senha?: string
    telefone?: string
    role?: UserRole
    clube_id?: string | null
  }>(event)

  const nome = body.nome?.trim()
  const email = body.email?.trim().toLowerCase()
  const senha = body.senha ?? ''
  const role = body.role ?? 'lider'

  if (!nome || !email || senha.length < 6 || !ROLES_VALIDAS.includes(role)) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Dados inválidos: nome, e-mail, senha (mín. 6 caracteres) e perfil são obrigatórios',
    })
  }

  const { data: novoUsuario, error: errCreate } = await admin.auth.admin.createUser({
    email,
    password: senha,
    email_confirm: true,
    user_metadata: {
      nome,
      telefone: body.telefone?.trim() || null,
      role,
    },
  })

  if (errCreate) {
    const mensagem = errCreate.message.includes('already')
      ? 'Já existe um usuário com este e-mail'
      : errCreate.message
    throw createError({ statusCode: 400, statusMessage: mensagem })
  }

  // Trigger criou o profile; vincula o clube quando aplicável
  if (body.clube_id) {
    await admin.from('profiles').update({ clube_id: body.clube_id }).eq('id', novoUsuario.user.id)
  }

  return { id: novoUsuario.user.id, email }
})
