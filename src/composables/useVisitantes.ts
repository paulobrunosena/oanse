import { computed, ref } from 'vue'
import { supabase } from '@/lib/supabase'
import type { Database } from '@/types/database.types'

type VisitanteRow = Database['public']['Tables']['visitantes']['Row']
type VisitaRow = Database['public']['Tables']['visitas']['Row']
type LicaoRow = Database['public']['Tables']['prova_ingresso_licoes']['Row']

export type StatusVisitante = VisitanteRow['status']

export interface VisitantePayload {
  nome: string
  data_nascimento: string
  responsavel: string | null
  contato: string | null
  indicado_por: string | null
  status: StatusVisitante
}

export interface OansistaOpcao {
  id: string
  nome: string
}

export interface TurmaOpcao {
  id: string
  nome: string
}

/**
 * Folha de Visitantes: cadastro de visitantes do clube, acompanhamento das até
 * 3 visitas e das lições da Prova de Ingresso, e a matrícula (conversão em
 * oansista via RPC fn_matricular_visitante). Escopo de clube vem do perfil;
 * autorização é garantida pela RLS.
 */
export function useVisitantes() {
  const visitantes = ref<VisitanteRow[]>([])
  const visitas = ref<VisitaRow[]>([])
  const licoes = ref<LicaoRow[]>([])
  const oansistas = ref<OansistaOpcao[]>([])
  const turmas = ref<TurmaOpcao[]>([])
  const carregando = ref(false)

  const visitasPorVisitante = computed<Map<string, VisitaRow[]>>(() => {
    const mapa = new Map<string, VisitaRow[]>()
    for (const v of visitas.value) {
      const lista = mapa.get(v.visitante_id) ?? []
      lista.push(v)
      mapa.set(v.visitante_id, lista)
    }
    return mapa
  })

  const licoesPorVisitante = computed<Map<string, LicaoRow[]>>(() => {
    const mapa = new Map<string, LicaoRow[]>()
    for (const l of licoes.value) {
      const lista = mapa.get(l.visitante_id) ?? []
      lista.push(l)
      mapa.set(l.visitante_id, lista)
    }
    return mapa
  })

  async function carregar(clubeId: string) {
    carregando.value = true
    visitantes.value = []
    visitas.value = []
    licoes.value = []
    try {
      const [rVisitantes, rOansistas, rTurmas] = await Promise.all([
        supabase.from('visitantes').select('*').eq('clube_id', clubeId).order('nome'),
        supabase.from('oansistas').select('id, nome').eq('clube_id', clubeId).eq('status', 'ativo').order('nome'),
        supabase.from('turmas').select('id, nome').eq('clube_id', clubeId).eq('ativo', true).order('nome'),
      ])
      if (rVisitantes.error) throw rVisitantes.error
      if (rOansistas.error) throw rOansistas.error
      if (rTurmas.error) throw rTurmas.error
      visitantes.value = rVisitantes.data ?? []
      oansistas.value = rOansistas.data ?? []
      turmas.value = rTurmas.data ?? []

      const ids = visitantes.value.map(v => v.id)
      if (!ids.length) return

      const [rVisitas, rLicoes] = await Promise.all([
        supabase.from('visitas').select('*').in('visitante_id', ids).order('numero'),
        supabase.from('prova_ingresso_licoes').select('*').in('visitante_id', ids).order('licao'),
      ])
      if (rVisitas.error) throw rVisitas.error
      if (rLicoes.error) throw rLicoes.error
      visitas.value = rVisitas.data ?? []
      licoes.value = rLicoes.data ?? []
    } finally {
      carregando.value = false
    }
  }

  async function salvarVisitante(dados: VisitantePayload, clubeId: string, id?: string): Promise<string> {
    if (id) {
      const { data, error } = await supabase
        .from('visitantes')
        .update(dados)
        .eq('id', id)
        .select()
        .single()
      if (error) throw error
      if (!data) throw new Error('Falha ao atualizar o visitante')

      const indice = visitantes.value.findIndex(v => v.id === id)
      if (indice >= 0) visitantes.value[indice] = data
      return data.id
    }

    const { data, error } = await supabase
      .from('visitantes')
      .insert({ ...dados, clube_id: clubeId })
      .select()
      .single()
    if (error) throw error
    if (!data) throw new Error('Falha ao cadastrar o visitante')

    visitantes.value.push(data)
    return data.id
  }

  async function salvarVisita(
    visitanteId: string,
    numero: number,
    dados: { data_visita: string, presente: boolean },
  ): Promise<void> {
    const { data, error } = await supabase
      .from('visitas')
      .upsert({ visitante_id: visitanteId, numero, ...dados }, { onConflict: 'visitante_id,numero' })
      .select()
      .single()
    if (error) throw error
    if (!data) throw new Error('Falha ao salvar a visita')

    const indice = visitas.value.findIndex(v => v.visitante_id === visitanteId && v.numero === numero)
    if (indice >= 0) visitas.value[indice] = data
    else visitas.value.push(data)
  }

  /** `dataConclusao` null remove a lição; caso contrário marca concluída. */
  async function salvarLicao(
    visitanteId: string,
    licao: number,
    dataConclusao: string | null,
    registradoPor: string | null,
  ): Promise<void> {
    if (!dataConclusao) {
      const { error } = await supabase
        .from('prova_ingresso_licoes')
        .delete()
        .eq('visitante_id', visitanteId)
        .eq('licao', licao)
      if (error) throw error
      licoes.value = licoes.value.filter(l => !(l.visitante_id === visitanteId && l.licao === licao))
      return
    }

    const { data, error } = await supabase
      .from('prova_ingresso_licoes')
      .upsert(
        {
          visitante_id: visitanteId,
          licao,
          concluida: true,
          data_conclusao: dataConclusao,
          registrado_por: registradoPor,
        },
        { onConflict: 'visitante_id,licao' },
      )
      .select()
      .single()
    if (error) throw error
    if (!data) throw new Error('Falha ao salvar a lição')

    const indice = licoes.value.findIndex(l => l.visitante_id === visitanteId && l.licao === licao)
    if (indice >= 0) licoes.value[indice] = data
    else licoes.value.push(data)
  }

  async function matricular(visitanteId: string, turmaId: string | null): Promise<void> {
    const { data, error } = await supabase.rpc('fn_matricular_visitante', {
      p_visitante_id: visitanteId,
      p_turma_id: turmaId ?? undefined,
    })
    if (error) throw error
    if (!data) throw new Error('Falha ao matricular o visitante')

    const indice = visitantes.value.findIndex(v => v.id === visitanteId)
    if (indice >= 0) visitantes.value[indice] = { ...visitantes.value[indice]!, status: 'matriculado' }
  }

  return {
    visitantes,
    visitas,
    licoes,
    oansistas,
    turmas,
    carregando,
    visitasPorVisitante,
    licoesPorVisitante,
    carregar,
    salvarVisitante,
    salvarVisita,
    salvarLicao,
    matricular,
  }
}
