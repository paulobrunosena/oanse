import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export interface LinhaFrequencia {
  oansista_id: string
  oansista_nome: string
  clube_nome: string
  turma_nome: string
  presencas: number
  faltas: number
  total_encontros: number
}

/**
 * Percentual de frequência (0-100), arredondado. Retorna 0 quando não há
 * encontros no período para o oansista.
 */
export function percentualFrequencia(l: LinhaFrequencia): number {
  if (l.total_encontros === 0) return 0
  return Math.round((l.presencas / l.total_encontros) * 100)
}

/**
 * Relatório de frequência acumulada por período. Consulta a RPC
 * fn_frequencia_acumulada (escopo por perfil aplicado no banco, mesmo critério
 * da RLS de presencas) e normaliza as linhas.
 */
export function useRelatorioFrequencia() {
  const linhas = ref<LinhaFrequencia[]>([])
  const carregando = ref(false)

  async function carregar(de: string, ate: string) {
    carregando.value = true
    const { data, error } = await supabase.rpc('fn_frequencia_acumulada', {
      p_de: de,
      p_ate: ate,
    })
    if (error) throw error
    linhas.value = ((data ?? []) as unknown as LinhaFrequencia[]).map(r => ({
      oansista_id: r.oansista_id,
      oansista_nome: r.oansista_nome,
      clube_nome: r.clube_nome,
      turma_nome: r.turma_nome ?? '',
      presencas: Number(r.presencas),
      faltas: Number(r.faltas),
      total_encontros: Number(r.total_encontros),
    }))
    carregando.value = false
  }

  return { linhas, carregando, carregar }
}
