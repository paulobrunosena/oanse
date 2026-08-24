import { ref } from 'vue'
import { defineStore } from 'pinia'
import { supabase } from '@/lib/supabase'
import { apiFetch } from '@/lib/api'
import type { Database } from '@/types/database.types'

export type Encontro = Database['public']['Tables']['encontros']['Row']

interface EncontroAtualResponse {
  encontro: Encontro | null
  semAtividade: boolean
  motivo: string | null
  data: string
}

/**
 * Encontro do sábado corrente — busca ou cria via /api/encontros/atual.
 * Criado no servidor (service_role) para qualquer perfil autenticado conseguir
 * lançar a chamada do sábado, mesmo que o encontro ainda não exista.
 *
 * RN 7: quando o sábado consta em dias_sem_oanse (férias/feriado), o endpoint
 * responde semAtividade=true e nenhum encontro é criado.
 *
 * Também mantém o histórico de encontros para o líder navegar entre sábados.
 */
export const useEncontroStore = defineStore('encontro', () => {
  const encontro = ref<Encontro | null>(null)
  const encontros = ref<Encontro[]>([])
  const semAtividade = ref(false)
  const motivoSemAtividade = ref<string | null>(null)
  const carregando = ref(false)
  const erro = ref<string | null>(null)

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
      const resposta = await apiFetch<EncontroAtualResponse>('/api/encontros/atual')
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

  function selecionar(id: string) {
    encontro.value = encontros.value.find(e => e.id === id) ?? null
    semAtividade.value = false
    motivoSemAtividade.value = null
  }

  return {
    encontro, encontros, semAtividade, motivoSemAtividade, carregando, erro,
    carregar, carregarHistorico, selecionar,
  }
})
