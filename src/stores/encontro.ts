import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import { supabase } from '@/lib/supabase'
import { apiFetch } from '@/lib/api'
import { sabadosAnteriores } from '@/utils/sabado'
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
  const diasSemOanse = ref<string[]>([])
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

  async function carregarDiasSemOanse() {
    const { data } = await supabase.from('dias_sem_oanse').select('data')
    diasSemOanse.value = (data ?? []).map(d => d.data)
  }

  /** Sábados recentes sem encontro e fora de dias_sem_oanse (backfill). */
  const sabadosFaltantes = computed(() => {
    const comEncontro = new Set(encontros.value.map(e => e.data))
    const semOanse = new Set(diasSemOanse.value)
    return sabadosAnteriores(12).filter(d => !comEncontro.has(d) && !semOanse.has(d))
  })

  async function carregar() {
    carregando.value = true
    erro.value = null
    try {
      const resposta = await apiFetch<EncontroAtualResponse>('/api/encontros/atual')
      encontro.value = resposta.encontro
      semAtividade.value = resposta.semAtividade
      motivoSemAtividade.value = resposta.motivo
      await carregarHistorico()
      await carregarDiasSemOanse()
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

  /**
   * Backfill de sábado perdido: cria o encontro de um sábado passado (via
   * servidor) e o seleciona, para o líder preencher chamada/folha depois.
   */
  async function criarRetroativo(data: string): Promise<{ encontro: Encontro, criado: boolean }> {
    const resposta = await apiFetch<{ encontro: Encontro, criado: boolean }>('/api/encontros/retro', {
      method: 'POST',
      body: { data },
    })
    if (!encontros.value.some(e => e.id === resposta.encontro.id)) {
      encontros.value = [...encontros.value, resposta.encontro].sort((a, b) =>
        b.data.localeCompare(a.data),
      )
    }
    selecionar(resposta.encontro.id)
    return resposta
  }

  return {
    encontro, encontros, diasSemOanse, semAtividade, motivoSemAtividade, carregando, erro,
    sabadosFaltantes,
    carregar, carregarHistorico, carregarDiasSemOanse, selecionar, criarRetroativo,
  }
})
