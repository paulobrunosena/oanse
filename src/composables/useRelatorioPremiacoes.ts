import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export interface Premiacao {
  id: string
  data_recebimento: string
  oansista_nome: string
  clube_nome: string
  premio_nome: string
}

export type LinhaPremiacao = {
  id: string
  data_recebimento: string
  oansistas: { nome: string, clubes: { nome: string } | null } | null
  folha_blocos: { premio_nome: string } | null
}

export function normalizarPremiacao(l: LinhaPremiacao): Premiacao {
  return {
    id: l.id,
    data_recebimento: l.data_recebimento,
    oansista_nome: l.oansistas?.nome ?? '?',
    clube_nome: l.oansistas?.clubes?.nome ?? '?',
    premio_nome: l.folha_blocos?.premio_nome ?? '?',
  }
}

/**
 * Relatório de premiações entregues por período. Lê `folha_premio_progresso`
 * (data de recebimento gravada na entrega pela Secretaria) com os nomes via join.
 */
export function useRelatorioPremiacoes() {
  const premiacoes = ref<Premiacao[]>([])
  const carregando = ref(false)

  async function carregar(de: string, ate: string) {
    carregando.value = true
    const { data, error } = await supabase
      .from('folha_premio_progresso')
      .select('id, data_recebimento, oansistas(nome, clubes(nome)), folha_blocos(premio_nome)')
      .gte('data_recebimento', de)
      .lte('data_recebimento', ate)
      .order('data_recebimento')
    if (error) throw error
    premiacoes.value = ((data ?? []) as unknown as LinhaPremiacao[]).map(normalizarPremiacao)
    carregando.value = false
  }

  return { premiacoes, carregando, carregar }
}
