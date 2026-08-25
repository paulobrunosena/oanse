import { createError, defineEventHandler, readBody } from 'h3'
import type { Database } from '../types/database.types'
import { validarDataRetroativa } from '../../utils/sabado'
import { supabaseAdmin } from '../../lib/supabaseAdmin'
import { getUsuarioDoRequest } from '../../lib/auth'

interface RetroBody {
  data?: string
}

export interface EncontroRetroResponse {
  encontro: Database['public']['Tables']['encontros']['Row']
  criado: boolean
}

/**
 * Cria (ou devolve) o encontro de um sábado passado — backfill de "sábado
 * perdido" (ex.: sistema fora do ar o sábado inteiro e ninguém conseguiu
 * lançar). Sem isso não existe registro do encontro e o líder não tem o que
 * preencher depois (RN 6).
 *
 * A criação usa service_role porque a RLS de INSERT em encontros é restrita
 * a diretor_geral/secretaria — mesma decisão do /api/encontros/atual.
 *
 * RN 7: sábados marcados como sem Oanse continuam bloqueados.
 */
export default defineEventHandler(async (event) => {
  const claims = await getUsuarioDoRequest(event)
  if (!claims?.sub) {
    throw createError({ statusCode: 401, statusMessage: 'Não autenticado' })
  }

  const body = await readBody<RetroBody>(event).catch(() => ({}))
  const data = body?.data ?? ''

  const validacao = validarDataRetroativa(data)
  if (!validacao.ok) {
    throw createError({ statusCode: 400, statusMessage: validacao.motivo })
  }

  const admin = supabaseAdmin()

  const { data: diaSemOanse } = await admin
    .from('dias_sem_oanse')
    .select('motivo')
    .eq('data', data)
    .maybeSingle()

  if (diaSemOanse) {
    throw createError({ statusCode: 400, statusMessage: 'Este sábado está marcado como sem Oanse' })
  }

  // Sem filtro de ativo: se já houver registro para a data, devolve-o em vez
  // de tentar inserir e quebrar a constraint UNIQUE (data).
  const { data: existente } = await admin
    .from('encontros')
    .select('*')
    .eq('data', data)
    .maybeSingle()

  if (existente) {
    return { encontro: existente, criado: false } satisfies EncontroRetroResponse
  }

  const { data: criado, error } = await admin
    .from('encontros')
    .insert({ data })
    .select()
    .single()

  if (error || !criado) {
    throw createError({ statusCode: 500, statusMessage: 'Não foi possível criar o encontro do sábado' })
  }

  return { encontro: criado, criado: true } satisfies EncontroRetroResponse
})