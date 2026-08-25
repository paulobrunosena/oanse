import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { podeAdicionarTime, podeLancarResultado } from '@/utils/jogos'

export { podeAdicionarTime, podeLancarResultado }

export interface JogoClube {
  clube_id: string
  nome: string
  slug: string
  cor: string | null
}

export interface JogoIntegrante {
  oansista_id: string
  nome: string
}

export interface JogoResultado {
  id: string
  colocacao: number | null
  desclassificado: boolean
  pontos: number
}

export interface JogoTime {
  id: string
  nome: string
  cor: string | null
  lider_id: string | null
  integrantes: JogoIntegrante[]
  resultado: JogoResultado | null
}

export interface Jogo {
  id: string
  nome: string
  criado_por: string | null
  clubes: JogoClube[]
  times: JogoTime[]
}

type LinhaJogo = {
  id: string
  nome: string
  criado_por: string | null
  jogos_clubes: { clube_id: string, clubes: { nome: string, slug: string, cor: string | null } | null }[]
  jogo_times: {
    id: string
    nome: string
    cor: string | null
    lider_id: string | null
    jogo_time_integrantes: { oansista_id: string, oansistas: { nome: string } | null }[]
    jogo_resultados: { id: string, colocacao: number | null, desclassificado: boolean, pontos: number }[]
  }[]
}

function normalizarJogo(linha: LinhaJogo): Jogo {
  return {
    id: linha.id,
    nome: linha.nome,
    criado_por: linha.criado_por,
    clubes: (linha.jogos_clubes ?? []).map(jc => ({
      clube_id: jc.clube_id,
      nome: jc.clubes?.nome ?? '?',
      slug: jc.clubes?.slug ?? '',
      cor: jc.clubes?.cor ?? null,
    })),
    times: (linha.jogo_times ?? []).map(t => ({
      id: t.id,
      nome: t.nome,
      cor: t.cor,
      lider_id: t.lider_id,
      integrantes: (t.jogo_time_integrantes ?? []).map(i => ({
        oansista_id: i.oansista_id,
        nome: i.oansistas?.nome ?? '?',
      })),
      resultado: (t.jogo_resultados ?? [])[0] ?? null,
    })),
  }
}

export type FormResultado = {
  colocacao: number | null
  desclassificado: boolean
}

/**
 * Jogos do encontro (Diretor de Clube): criação via RPC fn_criar_jogo (atômica,
 * valida o clube do autor), times (2-4), integrantes com busca de oansistas e
 * lançamento do placar. A propagação de pontos/ cor_time para as folhas é feita
 * pelo trigger fn_propagar_pontos_jogos no banco.
 */
export function useJogos() {
  const jogos = ref<Jogo[]>([])
  const carregando = ref(false)
  const encontroIdAtual = ref<string | null>(null)

  async function carregar(encontroId: string) {
    carregando.value = true
    encontroIdAtual.value = encontroId
    const { data, error } = await supabase
      .from('jogos')
      .select(`
        id, nome, criado_por,
        jogos_clubes(clube_id, clubes(nome, slug, cor)),
        jogo_times(
          id, nome, cor, lider_id,
          jogo_time_integrantes(oansista_id, oansistas(nome)),
          jogo_resultados(id, colocacao, desclassificado, pontos)
        )
      `)
      .eq('encontro_id', encontroId)
      .order('created_at')
    if (error) throw error
    jogos.value = (data ?? []).map(normalizarJogo)
    carregando.value = false
  }

  async function criarJogo(nome: string, clubeIds: string[], criadoPor: string): Promise<string> {
    if (!encontroIdAtual.value) throw new Error('Nenhum encontro selecionado')
    const { data, error } = await supabase.rpc('fn_criar_jogo', {
      p_encontro_id: encontroIdAtual.value,
      p_nome: nome,
      p_clubes: clubeIds,
      p_criado_por: criadoPor,
    })
    if (error) throw error
    if (!data?.id) throw new Error('Erro ao criar o jogo')
    await carregar(encontroIdAtual.value)
    return data.id
  }

  async function atualizarJogo(jogoId: string, nome: string) {
    const { error } = await supabase.from('jogos').update({ nome }).eq('id', jogoId)
    if (error) throw error
  }

  async function excluirJogo(jogoId: string) {
    const { error } = await supabase.from('jogos').delete().eq('id', jogoId)
    if (error) throw error
  }

  async function criarTime(jogoId: string, nome: string, cor: string | null): Promise<string> {
    const { data, error } = await supabase
      .from('jogo_times')
      .insert({ jogo_id: jogoId, nome, cor })
      .select('id')
      .single()
    if (error || !data) throw error
    return data.id
  }

  async function atualizarTime(timeId: string, dados: { nome: string, cor: string | null }) {
    const { error } = await supabase.from('jogo_times').update(dados).eq('id', timeId)
    if (error) throw error
  }

  async function excluirTime(timeId: string) {
    const { error } = await supabase.from('jogo_times').delete().eq('id', timeId)
    if (error) throw error
  }

  async function adicionarIntegrante(timeId: string, oansistaId: string) {
    const { error } = await supabase
      .from('jogo_time_integrantes')
      .insert({ time_id: timeId, oansista_id: oansistaId })
    if (error) throw error
  }

  async function removerIntegrante(timeId: string, oansistaId: string) {
    const { error } = await supabase
      .from('jogo_time_integrantes')
      .delete()
      .eq('time_id', timeId)
      .eq('oansista_id', oansistaId)
    if (error) throw error
  }

  async function lancarResultado(jogoId: string, timeId: string, resultado: FormResultado) {
    const { error } = await supabase
      .from('jogo_resultados')
      .upsert(
        { jogo_id: jogoId, time_id: timeId, ...resultado },
        { onConflict: 'jogo_id,time_id' },
      )
    if (error) throw error
  }

  async function removerResultado(timeId: string) {
    const { error } = await supabase.from('jogo_resultados').delete().eq('time_id', timeId)
    if (error) throw error
  }

  return {
    jogos, carregando, carregar, criarJogo, atualizarJogo, excluirJogo,
    criarTime, atualizarTime, excluirTime,
    adicionarIntegrante, removerIntegrante,
    lancarResultado, removerResultado,
  }
}