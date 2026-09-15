import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import type { Database } from '@/types/database.types'

export type Premio = Database['public']['Tables']['premios']['Row']
export type PremioTipo = Database['public']['Enums']['premio_tipo']

export interface PremioForm {
  nome: string
  tipo: PremioTipo
  descricao: string | null
  estoque: number
  estoque_min: number
  ativo: boolean
}

/**
 * Catálogo de prêmios/materiais da Secretaria (Fase 3). O estoque é controlado
 * via `premios_movimentacoes`; aqui ficam o CRUD do catálogo e a leitura do
 * saldo/estoque mínimo de cada prêmio.
 */
export function usePremios() {
  const premios = ref<Premio[]>([])
  const carregando = ref(false)

  async function carregar() {
    carregando.value = true
    const { data, error } = await supabase.from('premios').select('*').order('nome')
    if (error) throw error
    premios.value = data ?? []
    carregando.value = false
  }

  async function criar(dados: PremioForm) {
    const { error } = await supabase.from('premios').insert(dados)
    if (error) throw error
  }

  async function atualizar(id: string, dados: Partial<PremioForm>) {
    const { error } = await supabase.from('premios').update(dados).eq('id', id)
    if (error) throw error
  }

  async function excluir(id: string) {
    const { error } = await supabase.from('premios').delete().eq('id', id)
    if (error) throw error
  }

  return { premios, carregando, carregar, criar, atualizar, excluir }
}
