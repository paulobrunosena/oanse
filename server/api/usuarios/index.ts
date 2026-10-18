import { createError, defineEventHandler, readBody } from 'h3'
import type { H3Event } from 'h3'
import type { Database } from '../../types/database.types'
import { supabaseAdmin } from '../../lib/supabaseAdmin'
import { getUsuarioDoRequest } from '../../lib/auth'
import { podeGerenciarUsuarios } from '../../utils/autorizacao'

type UserRole = Database['public']['Enums']['user_role']

const ROLES_VALIDAS: UserRole[] = ['diretor_geral', 'secretaria', 'diretor_clube', 'lider', 'lider_jogos']

async function precisaSerDiretorGeral(event: H3Event) {
  const claims = await getUsuarioDoRequest(event)
  if (!claims?.sub) {
    throw createError({ statusCode: 401, statusMessage: 'Não autenticado' })
  }
  const admin = supabaseAdmin()
  const { data: perfil } = await admin
    .from('profiles')
    .select('role, ativo, clube_id')
    .eq('id', claims.sub)
    .single()
  if (!podeGerenciarUsuarios(perfil)) {
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

  const body = ((await readBody<{
    nome?: string
    email?: string
    senha?: string
    telefone?: string
    role?: UserRole
    clube_id?: string | null
  }>(event).catch(() => null)) ?? {})

  const nome = typeof body.nome === 'string' ? body.nome.trim() : ''
  const email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : ''
  const senha = typeof body.senha === 'string' ? body.senha : ''
  const role = (body.role ?? 'lider') as UserRole

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
    // O trigger fn_handle_new_user cria o profile com papel 'lider' e ignora
    // o metadata (migration 0021) — o papel/clube são definidos abaixo.
    user_metadata: {
      nome,
      telefone: typeof body.telefone === 'string' ? body.telefone.trim() || null : null,
    },
  })

  if (errCreate) {
    const mensagem = errCreate.message.includes('already')
      ? 'Já existe um usuário com este e-mail'
      : errCreate.message
    throw createError({ statusCode: 400, statusMessage: mensagem })
  }

  // Define papel e clube explicitamente; se falhar, desfaz a criação para não
  // deixar um usuário com papel padrão ('lider') fora do combinado.
  const { error: errPerfil } = await admin
    .from('profiles')
    .update({ role, clube_id: body.clube_id ?? null })
    .eq('id', novoUsuario.user.id)

  if (errPerfil) {
    await admin.auth.admin.deleteUser(novoUsuario.user.id).catch(() => undefined)
    throw createError({
      statusCode: 500,
      statusMessage: 'Não foi possível definir o perfil do usuário; a criação foi desfeita',
    })
  }

  return { id: novoUsuario.user.id, email }
}
