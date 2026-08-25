import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export interface LinhaRanking {
  clube_nome: string
  oansista_id: string
  oansista_nome: string
  total: number
  posicao: number
}

/**
 * Reordena as linhas pelo total (desc) e recalcula a posição geral, mantendo
 * empates na mesma posição (mesmo critério de rank() do banco).
 */
export function ordenarGeral(linhas: LinhaRanking[]): LinhaRanking[] {
  const ordenadas = [...linhas].sort(
    (a, b) => b.total - a.total || a.oansista_nome.localeCompare(b.oansista_nome, 'pt-BR'),
  )
  let totalAtual = -1
  let posicao = 0
  return ordenadas.map((l, i) => {
    if (l.total !== totalAtual) {
      totalAtual = l.total
      posicao = i + 1
    }
    return { ...l, posicao }
  })
}

/**
 * Ranking do sábado (Diretor de Clube / Diretor Geral). Consulta a RPC
 * fn_ranking_do_encontro (posição por clube, mesmo critério de desempate do
 * ranking semanal). O "geral" é derivado no cliente com ordenarGeral.
 */
export function useRanking() {
  const linhas = ref<LinhaRanking[]>([])
  const carregando = ref(false)

  async function carregar(encontroId: string) {
    carregando.value = true
    const { data, error } = await supabase.rpc('fn_ranking_do_encontro', {
      p_encontro_id: encontroId,
    })
    if (error) throw error
    linhas.value = (data ?? []).map(r => ({
      clube_nome: r.clube_nome,
      oansista_id: r.oansista_id,
      oansista_nome: r.oansista_nome,
      total: r.total,
      posicao: Number(r.posicao),
    }))
    carregando.value = false
  }

  return { linhas, carregando, carregar }
}