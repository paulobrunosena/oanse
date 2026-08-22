import { serverSupabaseUser } from '#supabase/server'

/**
 * Retorna (criando se necessário) o encontro do sábado corrente.
 * A criação usa service_role porque a RLS de INSERT em encontros é restrita
 * a diretor_geral/secretaria, mas qualquer líder autenticado precisa lançar
 * a chamada do sábado mesmo quando o encontro ainda não foi criado.
 */
export default defineEventHandler(async (event) => {
  const claims = await serverSupabaseUser(event)
  if (!claims?.sub) {
    throw createError({ statusCode: 401, statusMessage: 'Não autenticado' })
  }

  const admin = supabaseAdmin()
  const data = satadoCorrente()

  const { data: encontro } = await admin
    .from('encontros')
    .select('*')
    .eq('data', data)
    .maybeSingle()

  if (encontro) {
    return encontro
  }

  const { data: criado, error } = await admin
    .from('encontros')
    .insert({ data })
    .select()
    .single()

  if (error || !criado) {
    throw createError({ statusCode: 500, statusMessage: 'Não foi possível criar o encontro do sábado' })
  }

  return criado
})

/** Data do sábado mais recente (hoje se for sábado, senão o último sábado). */
function satadoCorrente(d = new Date()): string {
  const dia = d.getDay()
  const diasAtras = (dia + 7 - 6) % 7
  const sabado = new Date(d)
  sabado.setDate(d.getDate() - diasAtras)
  return sabado.toISOString().slice(0, 10)
}
