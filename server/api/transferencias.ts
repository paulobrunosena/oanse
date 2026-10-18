import { createError, defineEventHandler, readBody } from 'h3'
import { supabaseAdmin } from '../lib/supabaseAdmin'
import { getUsuarioDoRequest } from '../lib/auth'
import { podeTransferirOansista } from '../utils/autorizacao'

interface TransferenciaBody {
  oansista_id?: string
  turma_destino_id?: string
  motivo?: string | null
}

/**
 * Transferência permanente de oansista entre turmas — Diretor de Clube.
 * Body: { oansista_id, turma_destino_id, motivo? }
 *
 * A autorização é conferida aqui na borda (diretor_geral ou diretor do clube
 * da criança, sempre com perfil ativo) e revalidada dentro de
 * fn_transferir_oansista (migration 0021) — a rota chama a RPC com
 * service_role, então o banco autoriza pelo p_autorizado_por informado.
 */
export default defineEventHandler(async (event) => {
  const claims = await getUsuarioDoRequest(event)
  if (!claims?.sub) {
    throw createError({ statusCode: 401, statusMessage: 'Não autenticado' })
  }

  const admin = supabaseAdmin()
  const body = ((await readBody<TransferenciaBody>(event).catch(() => null)) ?? {}) as TransferenciaBody

  if (!body.oansista_id || !body.turma_destino_id) {
    throw createError({
      statusCode: 400,
      statusMessage: 'oansista_id e turma_destino_id são obrigatórios',
    })
  }

  // Autorização na borda (a RPC revalida no banco).
  const [{ data: perfil }, { data: crianca }] = await Promise.all([
    admin.from('profiles').select('role, ativo, clube_id').eq('id', claims.sub).single(),
    admin.from('oansistas').select('clube_id').eq('id', body.oansista_id).single(),
  ])

  if (!crianca) {
    throw createError({ statusCode: 400, statusMessage: 'Oansista não encontrado' })
  }

  if (!podeTransferirOansista(perfil, crianca.clube_id)) {
    throw createError({ statusCode: 403, statusMessage: 'Apenas o Diretor do clube pode transferir' })
  }

  const { data, error } = await admin.rpc('fn_transferir_oansista', {
    p_oansista_id: body.oansista_id,
    p_turma_destino_id: body.turma_destino_id,
    p_motivo: typeof body.motivo === 'string' ? body.motivo.trim() || undefined : undefined,
    p_autorizado_por: claims.sub,
  })

  if (error) {
    throw createError({
      statusCode: 400,
      statusMessage: error.message,
    })
  }

  return data
})
