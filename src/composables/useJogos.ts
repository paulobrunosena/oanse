import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { pontosDoResultado, type PontosJogosConfig } from '@/utils/jogos'

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

/** Opção de oansista para os selects de busca (id + nome). */
export interface OansistaOpcao {
  id: string
  nome: string
}

export interface EventoCor {
  id: string
  cor: string
  oansistas: JogoIntegrante[]
}

export interface EventoJogo {
  id: string
  encontro_id: string
  nome: string
  status: 'em_andamento' | 'finalizado'
  criado_por: string | null
  clubes: JogoClube[]
  cores: EventoCor[]
}

export interface JogoResultadoCor {
  id: string
  cor_id: string
  colocacao: number | null
  desclassificado: boolean
  pontos: number
}

export interface RodadaJogo {
  id: string
  nome: string
  criado_por: string | null
  resultados: JogoResultadoCor[]
}

export interface RankingCor {
  cor: string
  pontos: number
  posicao: number
}

export type FormResultado = {
  colocacao: number | null
  desclassificado: boolean
}

type LinhaEvento = {
  id: string
  encontro_id: string
  nome: string
  status: string
  criado_por: string | null
  evento_jogos_clubes: { clube_id: string, clubes: { nome: string, slug: string, cor: string | null } | null }[]
  evento_jogos_cores: {
    id: string
    cor: string
    evento_jogos_cores_oansistas: { oansista_id: string, oansistas: { nome: string } | null }[]
  }[]
}

type LinhaRodada = {
  id: string
  nome: string
  criado_por: string | null
  jogo_resultados: { id: string, cor_id: string, colocacao: number | null, desclassificado: boolean, pontos: number }[]
}

function normalizarEvento(linha: LinhaEvento): EventoJogo {
  return {
    id: linha.id,
    encontro_id: linha.encontro_id,
    nome: linha.nome,
    status: linha.status === 'finalizado' ? 'finalizado' : 'em_andamento',
    criado_por: linha.criado_por,
    clubes: (linha.evento_jogos_clubes ?? []).map(jc => ({
      clube_id: jc.clube_id,
      nome: jc.clubes?.nome ?? '?',
      slug: jc.clubes?.slug ?? '',
      cor: jc.clubes?.cor ?? null,
    })),
    cores: (linha.evento_jogos_cores ?? []).map(c => ({
      id: c.id,
      cor: c.cor,
      oansistas: (c.evento_jogos_cores_oansistas ?? []).map(i => ({
        oansista_id: i.oansista_id,
        nome: i.oansistas?.nome ?? '?',
      })),
    })),
  }
}

function normalizarRodada(linha: LinhaRodada): RodadaJogo {
  return {
    id: linha.id,
    nome: linha.nome,
    criado_por: linha.criado_por,
    resultados: (linha.jogo_resultados ?? []).map(r => ({
      id: r.id,
      cor_id: r.cor_id,
      colocacao: r.colocacao,
      desclassificado: r.desclassificado,
      pontos: r.pontos,
    })),
  }
}

/**
 * Módulo de jogos do sábado (Líder de Jogos). Um sábado pode ter vários
 * eventos (ex.: um dos Flamas+Tochas e outro dos Ursinhos+Faíscas); cada clube
 * participa de no máximo UM evento por sábado. Cada evento é cadastrado uma
 * única vez (clubes, cores e oansistas de cada cor); depois o líder só registra
 * o resultado de cada rodada. Ao final, finaliza o evento e consulta o ranking
 * das cores. A propagação de pontos/cor_time para as folhas é feita pelo
 * trigger fn_propagar_pontos_jogos no banco.
 */
export function useJogos() {
  const eventos = ref<EventoJogo[]>([])
  const evento = ref<EventoJogo | null>(null)
  const rodadas = ref<RodadaJogo[]>([])
  const catalogo = ref<{ id: string, clube_id: string, nome: string }[]>([])
  const ranking = ref<RankingCor[]>([])
  const carregando = ref(false)
  const encontroIdAtual = ref<string | null>(null)
  const eventoIdAtual = ref<string | null>(null)

  async function carregarEventos(encontroId: string) {
    carregando.value = true
    encontroIdAtual.value = encontroId
    const { data, error } = await supabase
      .from('eventos_jogos')
      .select(`
        id, encontro_id, nome, status, criado_por,
        evento_jogos_clubes(clube_id, clubes(nome, slug, cor)),
        evento_jogos_cores(
          id, cor,
          evento_jogos_cores_oansistas(oansista_id, oansistas(nome))
        )
      `)
      .eq('encontro_id', encontroId)
      .order('created_at')
    if (error) throw error
    eventos.value = ((data ?? []) as unknown as LinhaEvento[]).map(normalizarEvento)

    const atual = evento.value?.id
    const proximo = eventos.value.find(e => e.id === atual) ?? eventos.value[0] ?? null
    evento.value = proximo
    eventoIdAtual.value = proximo?.id ?? null
    carregando.value = false

    if (evento.value) {
      await carregarRodadas(evento.value.id)
      await carregarRanking(evento.value.id)
    }
  }

  async function selecionarEvento(eventoId: string) {
    evento.value = eventos.value.find(e => e.id === eventoId) ?? null
    eventoIdAtual.value = eventoId
    if (evento.value) {
      await carregarRodadas(eventoId)
      await carregarRanking(eventoId)
    }
  }

  async function carregarRodadas(eventoId: string) {
    const { data, error } = await supabase
      .from('jogos')
      .select(`
        id, nome, criado_por,
        jogo_resultados(id, cor_id, colocacao, desclassificado, pontos)
      `)
      .eq('evento_id', eventoId)
      .order('created_at')
    if (error) throw error
    rodadas.value = ((data ?? []) as unknown as LinhaRodada[]).map(normalizarRodada)
  }

  async function criarEvento(nome: string, clubeIds: string[], cores: string[], criadoPor: string): Promise<string> {
    if (!encontroIdAtual.value) throw new Error('Nenhum encontro selecionado')
    const { data, error } = await supabase.rpc('fn_criar_evento_jogos', {
      p_encontro_id: encontroIdAtual.value,
      p_nome: nome,
      p_clubes: clubeIds,
      p_cores: cores,
      p_criado_por: criadoPor,
    })
    if (error) throw error
    if (!data?.id) throw new Error('Erro ao criar o evento de jogos')
    await carregarEventos(encontroIdAtual.value)
    await selecionarEvento(data.id)
    return data.id
  }

  async function atualizarEvento(eventoId: string, dados: { nome?: string, status?: 'em_andamento' | 'finalizado' }) {
    const { error } = await supabase.from('eventos_jogos').update(dados).eq('id', eventoId)
    if (error) throw error
  }

  async function excluirEvento(eventoId: string) {
    const { error } = await supabase.from('eventos_jogos').delete().eq('id', eventoId)
    if (error) throw error
    if (evento.value?.id === eventoId) evento.value = null
  }

  async function adicionarCor(eventoId: string, cor: string) {
    const { error } = await supabase.from('evento_jogos_cores').insert({ evento_id: eventoId, cor })
    if (error) throw error
  }

  async function removerCor(corId: string) {
    const { error } = await supabase.from('evento_jogos_cores').delete().eq('id', corId)
    if (error) throw error
  }

  async function adicionarOansista(corId: string, oansistaId: string) {
    const { error } = await supabase.from('evento_jogos_cores_oansistas').insert({ cor_id: corId, oansista_id: oansistaId })
    if (error) throw error
  }

  async function removerOansista(corId: string, oansistaId: string) {
    const { error } = await supabase.from('evento_jogos_cores_oansistas').delete().eq('cor_id', corId).eq('oansista_id', oansistaId)
    if (error) throw error
  }

  async function adicionarRodada(eventoId: string, nome: string, criadoPor: string): Promise<string> {
    const { data, error } = await supabase
      .from('jogos')
      .insert({ evento_id: eventoId, nome, criado_por: criadoPor })
      .select('id')
      .single()
    if (error || !data) throw error
    return data.id
  }

  async function excluirRodada(jogoId: string) {
    const { error } = await supabase.from('jogos').delete().eq('id', jogoId)
    if (error) throw error
  }

  async function lancarResultado(jogoId: string, corId: string, resultado: FormResultado) {
    const { error } = await supabase
      .from('jogo_resultados')
      .upsert(
        { jogo_id: jogoId, cor_id: corId, ...resultado },
        { onConflict: 'jogo_id,cor_id' },
      )
    if (error) throw error
  }

  async function removerResultado(jogoId: string, corId: string) {
    const { error } = await supabase
      .from('jogo_resultados')
      .delete()
      .eq('jogo_id', jogoId)
      .eq('cor_id', corId)
    if (error) throw error
  }

  function aplicarStatus(eventoId: string, status: 'em_andamento' | 'finalizado') {
    eventos.value = eventos.value.map(e => e.id === eventoId ? { ...e, status } : e)
    if (evento.value?.id === eventoId) evento.value = { ...evento.value, status }
  }

  async function finalizarEvento(eventoId: string) {
    await atualizarEvento(eventoId, { status: 'finalizado' })
    aplicarStatus(eventoId, 'finalizado')
  }

  async function reabrirEvento(eventoId: string) {
    await atualizarEvento(eventoId, { status: 'em_andamento' })
    aplicarStatus(eventoId, 'em_andamento')
  }

  async function carregarCatalogo() {
    const { data, error } = await supabase
      .from('jogos_catalogo')
      .select('id, clube_id, nome')
      .order('nome')
    if (error) throw error
    catalogo.value = data ?? []
  }

  async function criarCatalogoItem(clubeId: string, nome: string) {
    const { error } = await supabase.from('jogos_catalogo').insert({ clube_id: clubeId, nome })
    if (error) throw error
  }

  async function atualizarCatalogoItem(id: string, dados: { clube_id?: string, nome?: string }) {
    const { error } = await supabase.from('jogos_catalogo').update(dados).eq('id', id)
    if (error) throw error
  }

  async function excluirCatalogoItem(id: string) {
    const { error } = await supabase.from('jogos_catalogo').delete().eq('id', id)
    if (error) throw error
  }

  async function carregarRanking(eventoId: string) {
    const { data, error } = await supabase.rpc('fn_ranking_cores_do_evento', { p_evento_id: eventoId })
    if (error) throw error
    ranking.value = (data ?? []).map(r => ({
      cor: r.cor,
      pontos: Number(r.pontos),
      posicao: Number(r.posicao),
    }))
  }

  /** Pontos de uma cor numa rodada (espelho do trigger, só para exibição). */
  function pontosDaCorNaRodada(rodada: RodadaJogo, corId: string, config: PontosJogosConfig[]): number {
    const r = rodada.resultados.find(r => r.cor_id === corId)
    return r ? pontosDoResultado(r, config) : 0
  }

  return {
    eventos, evento, rodadas, catalogo, ranking, carregando,
    carregarEventos, selecionarEvento, carregarRodadas, carregarCatalogo, carregarRanking,
    criarEvento, atualizarEvento, excluirEvento,
    adicionarCor, removerCor,
    adicionarOansista, removerOansista,
    adicionarRodada, excluirRodada,
    lancarResultado, removerResultado,
    finalizarEvento, reabrirEvento,
    criarCatalogoItem, atualizarCatalogoItem, excluirCatalogoItem,
    pontosDaCorNaRodada,
  }
}