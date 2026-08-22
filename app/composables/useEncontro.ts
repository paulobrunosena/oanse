import type { Database } from '~/types/database.types'

export type Encontro = Database['public']['Tables']['encontros']['Row']

interface EncontroAtualResponse {
  encontro: Encontro | null
  semAtividade: boolean
  motivo: string | null
  data: string
}

/**
 * Encontro do sábado corrente — busca ou cria via server/api/encontros/atual.
 * Criado no servidor (service_role) para qualquer perfil autenticado conseguir
 * lançar a chamada do sábado, mesmo que o encontro ainda não exista.
 *
 * RN 7: quando o sábado consta em dias_sem_oanse (férias/feriado), o endpoint
 * responde semAtividade=true e nenhum encontro é criado — sem encontro, não há
 * chamada/folha para lançar.
 *
 * Também mantém o histórico de encontros (RLS encontros_select = true) para o
 * líder navegar entre sábados — cobre chamadas atrasadas (ex.: sábado sem
 * internet, lançado na semana seguinte).
 */
export function useEncontro() {
  const supabase = useSupabaseClient()
  const encontro = useState<Encontro | null>('encontro:atual', () => null)
  const encontros = useState<Encontro[]>('encontro:lista', () => [])
  const semAtividade = useState<boolean>('encontro:sem-atividade', () => false)
  const motivoSemAtividade = useState<string | null>('encontro:motivo-sem-atividade', () => null)
  const carregando = useState<boolean>('encontro:carregando', () => false)
  const erro = useState<string | null>('encontro:erro', () => null)

  async function carregarHistorico() {
    const { data } = await supabase
      .from('encontros')
      .select('*')
      .order('data', { ascending: false })
      .limit(26)
    encontros.value = data ?? []
  }

  async function carregar() {
    carregando.value = true
    erro.value = null
    try {
      const resposta = await $fetch<EncontroAtualResponse>('/api/encontros/atual')
      encontro.value = resposta.encontro
      semAtividade.value = resposta.semAtividade
      motivoSemAtividade.value = resposta.motivo
      await carregarHistorico()
    }
    catch {
      encontro.value = null
      semAtividade.value = false
      erro.value = 'Não foi possível carregar o encontro do sábado.'
    }
    finally {
      carregando.value = false
    }
  }

  async function selecionar(id: string) {
    encontro.value = encontros.value.find(e => e.id === id) ?? null
    semAtividade.value = false
    motivoSemAtividade.value = null
  }

  return { encontro, encontros, semAtividade, motivoSemAtividade, carregando, erro, carregar, carregarHistorico, selecionar }
}
