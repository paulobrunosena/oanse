import { createError, defineEventHandler, readBody } from 'h3'
import type { H3Event } from 'h3'
import { supabaseAdmin } from '../../lib/supabaseAdmin'
import { getUsuarioDoRequest } from '../../lib/auth'

type UserRole = 'diretor_geral' | 'secretaria' | 'diretor_clube' | 'lider'

const ROLES_VALIDAS: UserRole[] = ['diretor_geral', 'secretaria', 'diretor_clube', 'lider']

async function precisaSerDiretorGeral(event: H3Event) {
  const claims = await getUsuarioDoRequest(event)
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
    throw createError({ statusCode: 403, statusMessage: 'Apenas o Diretor Geral pode gerenciar usuários' })
  }
  return { claims, admin }
}

/**
 * GET: lista todos os usuários (auth.users + profiles) — Diretor Geral.
 * POST: cria usuário (auth + profile) — Diretor Geral.
 */
export default defineEventHandler(async (event) => {
  if (event.method === 'GET') return listar(event)
  if (event.method === 'POST') return criar(event)
  throw createError({ statusCode: 405, statusMessage: 'Método não permitido' })
})

async function listar(event: H3Event) {
  const { admin } = await precisaSerDiretorGeral(event)

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
}

async function criar(event: H3Event) {
  const { admin } = await precisaSerDiretorGeral(event)

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
}
