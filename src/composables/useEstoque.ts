import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { apiFetch } from '@/lib/api'

export type TipoMovimentacao = 'entrada' | 'saida'

export interface Movimentacao {
  id: string
  tipo: TipoMovimentacao
  quantidade: number
  observacao: string | null
  created_at: string
  premio_id: string
  premio_nome: string
  feito_por_nome: string
}

export type LinhaMovimentacao = {
  id: string
  tipo: TipoMovimentacao
  quantidade: number
  observacao: string | null
  created_at: string
  premio_id: string
  premios: { nome: string } | null
  profiles: { nome: string } | null
}

export function normalizarMovimentacao(l: LinhaMovimentacao): Movimentacao {
  return {
    id: l.id,
    tipo: l.tipo,
    quantidade: l.quantidade,
    observacao: l.observacao,
    created_at: l.created_at,
    premio_id: l.premio_id,
    premio_nome: l.premios?.nome ?? '?',
    feito_por_nome: l.profiles?.nome ?? '?',
  }
}

/**
 * Movimentações de estoque da Secretaria (Fase 3). Leitura do histórico (com
 * nome do prêmio e do responsável via join) e registro de entrada/saída via
 * server route (`/api/premios/:id/movimentacoes`), que roda a transação
 * `fn_movimentar_estoque` com service_role.
 */
export function useEstoque() {
  const movimentacoes = ref<Movimentacao[]>([])
  const carregando = ref(false)

  async function carregar(premioId?: string) {
    carregando.value = true
    let query = supabase
      .from('premios_movimentacoes')
      .select('id, tipo, quantidade, observacao, created_at, premio_id, premios(nome), profiles(nome)')
    if (premioId) query = query.eq('premio_id', premioId)
    query = query.order('created_at', { ascending: false })
    const { data, error } = await query
    if (error) throw error
    movimentacoes.value = ((data ?? []) as unknown as LinhaMovimentacao[]).map(normalizarMovimentacao)
    carregando.value = false
  }

  async function registrar(
    premioId: string,
    tipo: TipoMovimentacao,
    quantidade: number,
    observacao?: string,
  ) {
    return apiFetch(`/api/premios/${premioId}/movimentacoes`, {
      method: 'POST',
      body: { tipo, quantidade, observacao },
    })
  }

  return { movimentacoes, carregando, carregar, registrar }
}
