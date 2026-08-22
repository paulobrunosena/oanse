import { serverSupabaseUser } from '#supabase/server'

/**
 * Transferência permanente de oansista entre turmas — Diretor de Clube.
 * Body: { oansista_id, turma_destino_id, motivo? }
 *
 * A transação (histórico + novo vínculo) roda na função
 * fn_transferir_oansista (migration 0006) via service_role.
 */
export default defineEventHandler(async (event) => {
  const claims = await serverSupabaseUser(event)
  if (!claims?.sub) {
    throw createError({ statusCode: 401, statusMessage: 'Não autenticado' })
  }

  const admin = supabaseAdmin()
  const body = await readBody<{
    oansista_id?: string
    turma_destino_id?: string
    motivo?: string | null
  }>(event)

  if (!body.oansista_id || !body.turma_destino_id) {
    throw createError({
      statusCode: 400,
      statusMessage: 'oansista_id e turma_destino_id são obrigatórios',
    })
  }

  const { data, error } = await admin.rpc('fn_transferir_oansista', {
    p_oansista_id: body.oansista_id,
    p_turma_destino_id: body.turma_destino_id,
    p_motivo: body.motivo?.trim() || undefined,
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
