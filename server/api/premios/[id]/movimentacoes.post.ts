import { createError, defineEventHandler, getRouterParam, readBody } from 'h3'
import { supabaseAdmin } from '../../lib/supabaseAdmin'
import { getUsuarioDoRequest } from '../../lib/auth'

/**
 * POST /api/premios/:id/movimentacoes — registra entrada/saída de estoque
 * (Secretaria). Body: { tipo: 'entrada' | 'saida', quantidade: number, observacao? }
 *
 * A transação (validação + atualização do estoque + gravação da movimentação)
 * roda na função fn_movimentar_estoque (migration 0020) via service_role;
 * a autorização (secretaria/diretor_geral) é validada dentro da função.
 */
export default defineEventHandler(async (event) => {
  const claims = await getUsuarioDoRequest(event)
  if (!claims?.sub) {
    throw createError({ statusCode: 401, statusMessage: 'Não autenticado' })
  }

  const id = getRouterParam(event, 'id')
  if (!id) {
    throw createError({ statusCode: 400, statusMessage: 'ID do prêmio ausente' })
  }

  const body = await readBody<{
    tipo: 'entrada' | 'saida'
    quantidade: number
    observacao?: string
  }>(event)

  const admin = supabaseAdmin()

  const { data, error } = await admin.rpc('fn_movimentar_estoque', {
    p_premio_id: id,
    p_tipo: body.tipo,
    p_quantidade: body.quantidade,
    p_observacao: body.observacao?.trim() || undefined,
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
