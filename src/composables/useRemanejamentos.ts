import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import type { Database } from '@/types/database.types'

type Remanejamento = Database['public']['Tables']['remanejamentos_temporarios']['Row']

export interface TurmaRemanejamento {
  id: string
  nome: string
  lider_id: string
  lider_nome: string | null
}

/**
 * Remanejamentos temporários: o Diretor de Clube libera a turma de um líder
 * ausente para outro líder naquele encontro. Via fn_responsavel_pela_turma o
 * substituto passa a enxergar/editar chamada e folha da turma (RLS).
 */
export function useRemanejamentos() {
  const turmas = ref<TurmaRemanejamento[]>([])
  const lideres = ref<{ id: string, nome: string }[]>([])
  const remanejamentos = ref<Remanejamento[]>([])
  const carregando = ref(false)

  async function carregar(clubeId: string, encontroId: string) {
    carregando.value = true
    const [rTurmas, rLideres, rRem] = await Promise.all([
      supabase.from('turmas')
        .select('id, nome, lider_id, lider:profiles!turmas_lider_id_fkey(nome)')
        .eq('clube_id', clubeId)
        .eq('ativo', true)
        .order('nome'),
      supabase.from('profiles')
        .select('id, nome')
        .eq('clube_id', clubeId)
        .eq('role', 'lider')
        .eq('ativo', true)
        .order('nome'),
      supabase.from('remanejamentos_temporarios')
        .select('*')
        .eq('encontro_id', encontroId),
    ])
    turmas.value = (rTurmas.data ?? []).map(t => ({
      id: t.id,
      nome: t.nome,
      lider_id: t.lider_id,
      lider_nome: (t.lider as unknown as { nome: string } | null)?.nome ?? null,
    }))
    lideres.value = rLideres.data ?? []
    remanejamentos.value = rRem.data ?? []
    carregando.value = false
  }

  function remanejamentoDe(turmaId: string): Remanejamento | undefined {
    return remanejamentos.value.find(r => r.turma_id === turmaId)
  }

  async function salvar(
    encontroId: string,
    turma: TurmaRemanejamento,
    liderSubstitutoId: string,
    criadoPor: string,
  ): Promise<void> {
    const existente = remanejamentoDe(turma.id)
    if (existente) {
      const { error } = await supabase
        .from('remanejamentos_temporarios')
        .update({ lider_substituto_id: liderSubstitutoId })
        .eq('id', existente.id)
      if (error) throw error
      existente.lider_substituto_id = liderSubstitutoId
      return
    }
    const { data, error } = await supabase
      .from('remanejamentos_temporarios')
      .insert({
        encontro_id: encontroId,
        turma_id: turma.id,
        lider_titular_id: turma.lider_id,
        lider_substituto_id: liderSubstitutoId,
        criado_por: criadoPor,
      })
      .select()
      .single()
    if (error || !data) throw error
    remanejamentos.value.push(data)
  }

  async function remover(turmaId: string): Promise<void> {
    const existente = remanejamentoDe(turmaId)
    if (!existente) return
    const { error } = await supabase
      .from('remanejamentos_temporarios')
      .delete()
      .eq('id', existente.id)
    if (error) throw error
    remanejamentos.value = remanejamentos.value.filter(r => r.id !== existente.id)
  }

  return { turmas, lideres, remanejamentos, carregando, carregar, remanejamentoDe, salvar, remover }
}
