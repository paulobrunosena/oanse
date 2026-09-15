import { createError, defineEventHandler, getRouterParam, readBody } from 'h3'
import { supabaseAdmin } from '../../../lib/supabaseAdmin'
import { getUsuarioDoRequest } from '../../../lib/auth'

/**
 * POST /api/premios/:id/entregar — entrega de um prêmio pendente (Secretaria).
 * Body opcional: { observacao? }
 *
 * A transação (marcar entregue + baixa de estoque + movimentação + data na
 * folha) roda na função fn_entregar_premio (migration 0019) via service_role;
 * a autorização (secretaria/diretor_geral) é validada dentro da função.
 */
export default defineEventHandler(async (event) => {
  const claims = await getUsuarioDoRequest(event)
  if (!claims?.sub) {
    throw createError({ statusCode: 401, statusMessage: 'Não autenticado' })
  }

  const id = getRouterParam(event, 'id')
  if (!id) {
    throw createError({ statusCode: 400, statusMessage: 'ID da pendência ausente' })
  }

  const body = await readBody<{ observacao?: string }>(event)

  const admin = supabaseAdmin()

  const { data, error } = await admin.rpc('fn_entregar_premio', {
    p_pendencia_id: id,
    p_autorizado_por: claims.sub,
    p_observacao: body.observacao?.trim() || undefined,
  })

  if (error) {
    throw createError({
      statusCode: 400,
      statusMessage: error.message,
    })
  }

  return data
})
