import { computed, ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { pontosPorChave, type ItensPontuacaoMap } from '@/utils/pontos'
import type { Database } from '@/types/database.types'

export type Folha = Database['public']['Tables']['folhas_semanais']['Row']
type ItemPontuacao = Database['public']['Tables']['itens_pontuacao']['Row']

export type FormFolha = Pick<Folha, 'uniforme' | 'biblia' | 'ebd' | 'manual' | 'conduta' | 'secoes_dia' | 'atividade_extra'>

/**
 * Folha Semanal: configuração de pontuação + folhas do encontro.
 * O total é calculado no banco (trigger fn_calcular_total_folha); aqui mantemos
 * apenas o preview de leitura (utils/pontos.ts) e a persistência por upsert.
 */
export function useFolhaSemanal() {
  const folhas = ref<Folha[]>([])
  const itens = ref<ItemPontuacao[]>([])
  const carregando = ref(false)

  const pontos = computed<ItensPontuacaoMap>(() => pontosPorChave(itens.value))

  async function carregar(encontroId: string, oansistaIds: string[]) {
    carregando.value = true
    const [rItens, rFolhas] = await Promise.all([
      supabase.from('itens_pontuacao').select('*').eq('ativo', true),
      oansistaIds.length
        ? supabase.from('folhas_semanais').select('*').eq('encontro_id', encontroId).in('oansista_id', oansistaIds)
        : Promise.resolve({ data: [] as Folha[] }),
    ])
    itens.value = rItens.data ?? []
    folhas.value = rFolhas.data ?? []
    carregando.value = false
  }

  function folhaDe(oansistaId: string): Folha | undefined {
    return folhas.value.find(f => f.oansista_id === oansistaId)
  }

  async function salvar(
    encontroId: string,
    oansistaId: string,
    presencaId: string,
    registradoPor: string,
    form: FormFolha,
  ): Promise<Folha> {
    const existente = folhaDe(oansistaId)

    if (existente) {
      const { data, error } = await supabase
        .from('folhas_semanais')
        .update(form)
        .eq('id', existente.id)
        .select()
        .single()
      if (error || !data) throw error
      Object.assign(existente, data)
      return existente
    }

    const { data, error } = await supabase
      .from('folhas_semanais')
      .insert({ encontro_id: encontroId, oansista_id: oansistaId, presenca_id: presencaId, registrado_por: registradoPor, ...form })
      .select()
      .single()
    if (error || !data) throw error
    folhas.value.push(data)
    return data
  }

  return { folhas, itens, pontos, carregando, carregar, folhaDe, salvar }
}
