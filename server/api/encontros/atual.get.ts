import { serverSupabaseUser } from '#supabase/server'
import type { Database } from '~/types/database.types'
import { sabadoCorrente } from '../../utils/sabado'

export interface EncontroAtualResponse {
  encontro: Database['public']['Tables']['encontros']['Row'] | null
  semAtividade: boolean
  motivo: string | null
  data: string
}

/**
 * Retorna (criando se necessário) o encontro do sábado corrente.
 * A criação usa service_role porque a RLS de INSERT em encontros é restrita
 * a diretor_geral/secretaria, mas qualquer líder autenticado precisa lançar
 * a chamada do sábado mesmo quando o encontro ainda não foi criado.
 *
 * RN 7: se o sábado consta em dias_sem_oanse (férias/feriado), NÃO cria
 * encontro e responde semAtividade=true — sem encontro, não há chamada/folha.
 */
export default defineEventHandler(async (event) => {
  const claims = await serverSupabaseUser(event)
  if (!claims?.sub) {
    throw createError({ statusCode: 401, statusMessage: 'Não autenticado' })
  }

  const admin = supabaseAdmin()
  const data = sabadoCorrente()

  const { data: diaSemOanse } = await admin
    .from('dias_sem_oanse')
    .select('motivo')
    .eq('data', data)
    .maybeSingle()

  if (diaSemOanse) {
    return {
      encontro: null,
      semAtividade: true,
      motivo: diaSemOanse.motivo,
      data,
    } satisfies EncontroAtualResponse
  }

  const { data: encontro } = await admin
    .from('encontros')
    .select('*')
    .eq('data', data)
    .eq('ativo', true)
    .maybeSingle()

  if (encontro) {
    return { encontro, semAtividade: false, motivo: null, data } satisfies EncontroAtualResponse
  }

  const { data: criado, error } = await admin
    .from('encontros')
    .insert({ data })
    .select()
    .single()

  if (error || !criado) {
    throw createError({ statusCode: 500, statusMessage: 'Não foi possível criar o encontro do sábado' })
  }

  return { encontro: criado, semAtividade: false, motivo: null, data } satisfies EncontroAtualResponse
})
