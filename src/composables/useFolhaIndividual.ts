import { computed, ref } from 'vue'
import { supabase } from '@/lib/supabase'
import {
  normalizarFolhaIndividual,
  type BlocoFolhaRow,
  type ItemProgressoFolhaRow,
  type ManualFolha,
  type ManualFolhaRow,
  type ObservacaoFolhaRow,
  type PremioProgressoFolhaRow,
  type SecaoFolhaRow,
} from '@/utils/folhaIndividual'

/**
 * Folha de Progresso Individual (clube Faíscas): catálogo do clube
 * (manuais > seções > blocos) + progresso do oansista selecionado (itens,
 * prêmios e observações). As escritas são upsert/delete e o estado local é
 * atualizado na sequência; a árvore normalizada `folha` é derivada por
 * `normalizarFolhaIndividual` (utils/folhaIndividual).
 */
export function useFolhaIndividual() {
  const manuais = ref<ManualFolhaRow[]>([])
  const secoes = ref<SecaoFolhaRow[]>([])
  const blocos = ref<BlocoFolhaRow[]>([])
  const itens = ref<ItemProgressoFolhaRow[]>([])
  const premios = ref<PremioProgressoFolhaRow[]>([])
  const observacoes = ref<ObservacaoFolhaRow[]>([])
  const carregando = ref(false)
  const carregandoProgresso = ref(false)
  const oansistaIdAtual = ref<string | null>(null)

  const folha = computed<ManualFolha[]>(() => normalizarFolhaIndividual({
    manuais: manuais.value,
    secoes: secoes.value,
    blocos: blocos.value,
    itens: itens.value,
    premios: premios.value,
    observacoes: observacoes.value,
  }))

  async function carregar(clubeId: string) {
    carregando.value = true
    try {
      const { data: manuaisData, error: erroManuais } = await supabase
        .from('folha_manuais')
        .select('*')
        .eq('clube_id', clubeId)
        .order('ordem')
      if (erroManuais) throw erroManuais
      manuais.value = manuaisData ?? []

      secoes.value = []
      blocos.value = []
      const manualIds = manuais.value.map(m => m.id)
      if (!manualIds.length) return

      const { data: secoesData, error: erroSecoes } = await supabase
        .from('folha_secoes')
        .select('*')
        .in('manual_id', manualIds)
        .order('ordem')
      if (erroSecoes) throw erroSecoes
      secoes.value = secoesData ?? []

      const secaoIds = secoes.value.map(s => s.id)
      if (!secaoIds.length) return

      const { data: blocosData, error: erroBlocos } = await supabase
        .from('folha_blocos')
        .select('*')
        .in('secao_id', secaoIds)
        .order('ordem')
      if (erroBlocos) throw erroBlocos
      blocos.value = blocosData ?? []
    } finally {
      carregando.value = false
    }
  }

  /** Carrega itens, prêmios e observações do oansista (limpa o progresso anterior). */
  async function carregarProgresso(oansistaId: string) {
    carregandoProgresso.value = true
    oansistaIdAtual.value = oansistaId
    itens.value = []
    premios.value = []
    observacoes.value = []
    try {
      const [rItens, rPremios, rObservacoes] = await Promise.all([
        supabase.from('folha_item_progresso').select('*').eq('oansista_id', oansistaId),
        supabase.from('folha_premio_progresso').select('*').eq('oansista_id', oansistaId),
        supabase.from('folha_observacoes').select('*').eq('oansista_id', oansistaId),
      ])
      if (rItens.error) throw rItens.error
      if (rPremios.error) throw rPremios.error
      if (rObservacoes.error) throw rObservacoes.error
      itens.value = rItens.data ?? []
      premios.value = rPremios.data ?? []
      observacoes.value = rObservacoes.data ?? []
    } finally {
      carregandoProgresso.value = false
    }
  }

  /** `dataConclusao` null remove o item; caso contrário faz upsert do registro. */
  async function salvarItem(
    oansistaId: string,
    blocoId: string,
    itemNum: number,
    dataConclusao: string | null,
    registradoPor: string,
  ): Promise<void> {
    if (!dataConclusao) {
      const { error } = await supabase
        .from('folha_item_progresso')
        .delete()
        .eq('oansista_id', oansistaId)
        .eq('bloco_id', blocoId)
        .eq('item_num', itemNum)
      if (error) throw error
      itens.value = itens.value.filter(i => !(i.bloco_id === blocoId && i.item_num === itemNum))
      return
    }

    const { data, error } = await supabase
      .from('folha_item_progresso')
      .upsert(
        {
          oansista_id: oansistaId,
          bloco_id: blocoId,
          item_num: itemNum,
          data_conclusao: dataConclusao,
          registrado_por: registradoPor,
        },
        { onConflict: 'oansista_id,bloco_id,item_num' },
      )
      .select()
      .single()
    if (error) throw error
    if (!data) throw new Error('Falha ao salvar o item da folha')

    const indice = itens.value.findIndex(i => i.bloco_id === blocoId && i.item_num === itemNum)
    if (indice >= 0) itens.value[indice] = data
    else itens.value.push(data)
  }

  /** `dataRecebimento` null remove o prêmio; caso contrário faz upsert do registro. */
  async function salvarPremio(
    oansistaId: string,
    blocoId: string,
    dataRecebimento: string | null,
    registradoPor: string,
  ): Promise<void> {
    if (!dataRecebimento) {
      const { error } = await supabase
        .from('folha_premio_progresso')
        .delete()
        .eq('oansista_id', oansistaId)
        .eq('bloco_id', blocoId)
      if (error) throw error
      premios.value = premios.value.filter(p => p.bloco_id !== blocoId)
      return
    }

    const { data, error } = await supabase
      .from('folha_premio_progresso')
      .upsert(
        {
          oansista_id: oansistaId,
          bloco_id: blocoId,
          data_recebimento: dataRecebimento,
          registrado_por: registradoPor,
        },
        { onConflict: 'oansista_id,bloco_id' },
      )
      .select()
      .single()
    if (error) throw error
    if (!data) throw new Error('Falha ao salvar o prêmio da folha')

    const indice = premios.value.findIndex(p => p.bloco_id === blocoId)
    if (indice >= 0) premios.value[indice] = data
    else premios.value.push(data)
  }

  async function salvarObservacao(oansistaId: string, manualId: string, texto: string): Promise<void> {
    const { data, error } = await supabase
      .from('folha_observacoes')
      .upsert(
        {
          oansista_id: oansistaId,
          manual_id: manualId,
          texto,
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'oansista_id,manual_id' },
      )
      .select()
      .single()
    if (error) throw error
    if (!data) throw new Error('Falha ao salvar as observações da folha')

    const indice = observacoes.value.findIndex(o => o.manual_id === manualId)
    if (indice >= 0) observacoes.value[indice] = data
    else observacoes.value.push(data)
  }

  return {
    folha,
    carregando,
    carregandoProgresso,
    oansistaIdAtual,
    carregar,
    carregarProgresso,
    salvarItem,
    salvarPremio,
    salvarObservacao,
  }
}
