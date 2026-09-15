import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import type { Database } from '@/types/database.types'

export type PendenciaStatus = Database['public']['Enums']['pendencia_status']
export type PremioTipo = Database['public']['Enums']['premio_tipo']

export interface Pendencia {
  id: string
  status: PendenciaStatus
  data_geracao: string
  data_entrega: string | null
  clube_nome: string
  oansista_nome: string
  premio_nome: string
  premio_tipo: PremioTipo
}

export type LinhaPendencia = {
  id: string
  status: PendenciaStatus
  data_geracao: string
  data_entrega: string | null
  oansistas: { nome: string } | null
  premios: { nome: string, tipo: PremioTipo } | null
  clubes: { nome: string } | null
}

export function normalizarPendencia(l: LinhaPendencia): Pendencia {
  return {
    id: l.id,
    status: l.status,
    data_geracao: l.data_geracao,
    data_entrega: l.data_entrega,
    clube_nome: l.clubes?.nome ?? '?',
    oansista_nome: l.oansistas?.nome ?? '?',
    premio_nome: l.premios?.nome ?? '?',
    premio_tipo: l.premios?.tipo ?? 'botom',
  }
}

/**
 * Painel de pendências de premiação da Secretaria. Lê `premios_pendentes`
 * (com nomes via join) e mantém a fila atualizada via Realtime
 * (publication `supabase_realtime` já inclui a tabela).
 */
export function usePendencias() {
  const pendencias = ref<Pendencia[]>([])
  const carregando = ref(false)

  async function carregar(status?: PendenciaStatus, clubeId?: string) {
    carregando.value = true
    let query = supabase
      .from('premios_pendentes')
      .select('id, status, data_geracao, data_entrega, oansistas(nome), premios(nome, tipo), clubes(nome)')
    if (status) query = query.eq('status', status)
    if (clubeId) query = query.eq('clube_id', clubeId)
    query = query.order('data_geracao', { ascending: false })
    const { data, error } = await query
    if (error) throw error
    pendencias.value = ((data ?? []) as unknown as LinhaPendencia[]).map(normalizarPendencia)
    carregando.value = false
  }

  function inscrever(aoChegar?: (payload: { eventType: string, new: Record<string, unknown> }) => void) {
    const canal = supabase
      .channel('pendencias-realtime')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'premios_pendentes' },
        (payload: { eventType: string, new: Record<string, unknown> }) => {
          aoChegar?.(payload)
          carregar()
        },
      )
      .subscribe()
    return () => supabase.removeChannel(canal)
  }

  return { pendencias, carregando, carregar, inscrever }
}
