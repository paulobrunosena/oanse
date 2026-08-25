import { beforeEach, describe, expect, it, vi } from 'vitest'
import { builder, clienteSupabase } from '../../tests/helpers/supabase'
import { useJogos } from './useJogos'
import { CORES_PREDEFINIDAS, pontosDoResultado, type PontosJogosConfig } from '@/utils/jogos'

const EVENTO_FLAMAS = {
  id: 'ev1',
  encontro_id: 'e1',
  nome: 'Jogos dos Flamas e Tochas',
  status: 'em_andamento',
  criado_por: 'p1',
  evento_jogos_clubes: [
    { clube_id: 'c1', clubes: { nome: 'Flamas', slug: 'flamas', cor: '#22C55E' } },
    { clube_id: 'c2', clubes: { nome: 'Tochas', slug: 'tochas', cor: '#3B82F6' } },
  ],
  evento_jogos_cores: [
    { id: 'cor1', cor: 'verde', evento_jogos_cores_oansistas: [{ oansista_id: 'o1', oansistas: { nome: 'Ana' } }] },
    { id: 'cor2', cor: 'azul', evento_jogos_cores_oansistas: [] },
  ],
}

const EVENTO_URSINHOS = {
  id: 'ev2',
  encontro_id: 'e1',
  nome: 'Jogos dos Ursinhos e Faíscas',
  status: 'em_andamento',
  criado_por: 'p1',
  evento_jogos_clubes: [
    { clube_id: 'c3', clubes: { nome: 'Ursinhos', slug: 'ursinhos', cor: '#EF4444' } },
    { clube_id: 'c4', clubes: { nome: 'Faíscas', slug: 'faiscas', cor: '#EAB308' } },
  ],
  evento_jogos_cores: [
    { id: 'cor3', cor: 'vermelho', evento_jogos_cores_oansistas: [] },
    { id: 'cor4', cor: 'amarelo', evento_jogos_cores_oansistas: [] },
  ],
}

const RODADAS = [
  {
    id: 'j1',
    nome: 'maratona',
    criado_por: 'p1',
    jogo_resultados: [{ id: 'r1', cor_id: 'cor1', colocacao: 1, desclassificado: false, pontos: 100 }],
  },
]

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

describe('useJogos', () => {
  beforeEach(() => {
    mocks.supabase = clienteSupabase({
      eventos_jogos: () => builder([EVENTO_FLAMAS, EVENTO_URSINHOS]),
      jogos: () => builder(RODADAS),
      jogos_catalogo: () => builder([]),
    })
  })

  describe('carregarEventos', () => {
    it('carrega todos os eventos do encontro e seleciona o primeiro', async () => {
      const jogos = useJogos()
      await jogos.carregarEventos('e1')

      expect(jogos.eventos.value).toHaveLength(2)
      expect(jogos.evento.value?.id).toBe('ev1')
      expect(jogos.evento.value?.nome).toBe('Jogos dos Flamas e Tochas')
      expect(jogos.evento.value?.clubes).toEqual([
        { clube_id: 'c1', nome: 'Flamas', slug: 'flamas', cor: '#22C55E' },
        { clube_id: 'c2', nome: 'Tochas', slug: 'tochas', cor: '#3B82F6' },
      ])
      expect(jogos.evento.value?.cores[0]?.oansistas).toEqual([{ oansista_id: 'o1', nome: 'Ana' }])

      expect(jogos.rodadas.value).toHaveLength(1)
      expect(jogos.rodadas.value[0]?.nome).toBe('maratona')
      expect(jogos.carregando.value).toBe(false)
    })

    it('deixa eventos vazios e evento nulo quando não há eventos no encontro', async () => {
      mocks.supabase = clienteSupabase({
        eventos_jogos: () => builder([]),
        jogos: () => builder([]),
      })
      const jogos = useJogos()
      await jogos.carregarEventos('e1')
      expect(jogos.eventos.value).toEqual([])
      expect(jogos.evento.value).toBeNull()
    })

    it('mantém a seleção atual quando ela ainda existe na lista', async () => {
      const jogos = useJogos()
      await jogos.carregarEventos('e1')
      await jogos.selecionarEvento('ev2')
      expect(jogos.evento.value?.id).toBe('ev2')

      await jogos.carregarEventos('e1')
      expect(jogos.evento.value?.id).toBe('ev2')
    })
  })

  describe('selecionarEvento', () => {
    it('troca o evento selecionado e carrega rodadas e ranking', async () => {
      const jogos = useJogos()
      await jogos.carregarEventos('e1')

      await jogos.selecionarEvento('ev2')
      expect(jogos.evento.value?.id).toBe('ev2')
      expect(jogos.evento.value?.nome).toBe('Jogos dos Ursinhos e Faíscas')
      expect(mocks.supabase.builderDe('jogos').eq).toHaveBeenCalledWith('evento_id', 'ev2')
    })
  })

  describe('criarEvento', () => {
    it('chama a RPC fn_criar_evento_jogos e seleciona o novo evento', async () => {
      mocks.supabase.rpc.mockImplementation((nome: string) => {
        if (nome === 'fn_ranking_cores_do_evento') return Promise.resolve({ data: [], error: null })
        return Promise.resolve({ data: { id: 'ev9' }, error: null })
      })
      mocks.supabase.builderDe('eventos_jogos').data = [...mocks.supabase.builderDe('eventos_jogos').data, {
        id: 'ev9', encontro_id: 'e1', nome: 'Jogos dos Flamas e Tochas', status: 'em_andamento',
        criado_por: 'p1', evento_jogos_clubes: [], evento_jogos_cores: [],
      }]
      const jogos = useJogos()
      await jogos.carregarEventos('e1')
      const id = await jogos.criarEvento('Jogos dos Flamas e Tochas', ['c1', 'c2'], ['verde', 'azul'], 'p1')

      expect(id).toBe('ev9')
      expect(mocks.supabase.rpc).toHaveBeenCalledWith('fn_criar_evento_jogos', {
        p_encontro_id: 'e1',
        p_nome: 'Jogos dos Flamas e Tochas',
        p_clubes: ['c1', 'c2'],
        p_cores: ['verde', 'azul'],
        p_criado_por: 'p1',
      })
      expect(jogos.evento.value?.id).toBe('ev9')
    })

    it('lança erro quando a RPC falha (clube já jogou no sábado)', async () => {
      mocks.supabase.rpc.mockImplementation((nome: string) => {
        if (nome === 'fn_ranking_cores_do_evento') return Promise.resolve({ data: [], error: null })
        return Promise.resolve({ data: null, error: { message: 'Um dos clubes selecionados já participou de um evento de jogos neste sábado' } })
      })
      const jogos = useJogos()
      await jogos.carregarEventos('e1')
      await expect(jogos.criarEvento('X', ['c1'], ['verde', 'azul'], 'p1')).rejects.toThrow('Um dos clubes selecionados já participou de um evento de jogos neste sábado')
    })
  })

  describe('adicionarRodada', () => {
    it('insere a rodada e retorna o id', async () => {
      mocks.supabase.builderDe('jogos').singleData = { id: 'j9' }
      const jogos = useJogos()
      const id = await jogos.adicionarRodada('ev1', 'bonanza', 'p1')
      expect(id).toBe('j9')
      const b = mocks.supabase.builderDe('jogos')
      expect(b.insert).toHaveBeenCalledWith({ evento_id: 'ev1', nome: 'bonanza', criado_por: 'p1' })
    })
  })

  describe('lancarResultado', () => {
    it('faz upsert em jogo_resultados com onConflict por jogo+cor', async () => {
      const jogos = useJogos()
      await jogos.lancarResultado('j1', 'cor2', { colocacao: 2, desclassificado: false })
      const resultados = mocks.supabase.builderDe('jogo_resultados')
      expect(resultados.upsert).toHaveBeenCalledWith(
        { jogo_id: 'j1', cor_id: 'cor2', colocacao: 2, desclassificado: false },
        { onConflict: 'jogo_id,cor_id' },
      )
    })
  })

  describe('finalizar/reabrir', () => {
    it('atualiza o status do evento na lista e no selecionado', async () => {
      const jogos = useJogos()
      await jogos.carregarEventos('e1')

      await jogos.finalizarEvento('ev1')
      expect(mocks.supabase.builderDe('eventos_jogos').update).toHaveBeenCalledWith({ status: 'finalizado' })
      expect(jogos.evento.value?.status).toBe('finalizado')
      expect(jogos.eventos.value.find(e => e.id === 'ev1')?.status).toBe('finalizado')

      await jogos.reabrirEvento('ev1')
      expect(jogos.evento.value?.status).toBe('em_andamento')
    })
  })

  describe('carregarRanking', () => {
    it('chama a RPC fn_ranking_cores_do_evento e normaliza', async () => {
      mocks.supabase.rpc.mockResolvedValue({
        data: [{ cor: 'verde', pontos: 200, posicao: 1 }, { cor: 'azul', pontos: 100, posicao: 2 }],
        error: null,
      })
      const jogos = useJogos()
      await jogos.carregarRanking('ev1')
      expect(mocks.supabase.rpc).toHaveBeenCalledWith('fn_ranking_cores_do_evento', { p_evento_id: 'ev1' })
      expect(jogos.ranking.value).toEqual([
        { cor: 'verde', pontos: 200, posicao: 1 },
        { cor: 'azul', pontos: 100, posicao: 2 },
      ])
    })
  })

  describe('catálogo', () => {
    it('carrega o catálogo', async () => {
      mocks.supabase.builderDe('jogos_catalogo').data = [
        { id: 'a', clube_id: 'c1', nome: 'maratona' },
      ]
      const jogos = useJogos()
      await jogos.carregarCatalogo()
      expect(jogos.catalogo.value).toHaveLength(1)
      expect(jogos.catalogo.value[0]?.nome).toBe('maratona')
    })

    it('adiciona, atualiza e exclui itens do catálogo', async () => {
      const jogos = useJogos()
      await jogos.criarCatalogoItem('c1', 'bonanza')
      expect(mocks.supabase.builderDe('jogos_catalogo').insert).toHaveBeenCalledWith({ clube_id: 'c1', nome: 'bonanza' })

      await jogos.atualizarCatalogoItem('a', { nome: 'sprint' })
      expect(mocks.supabase.builderDe('jogos_catalogo').update).toHaveBeenCalledWith({ nome: 'sprint' })

      await jogos.excluirCatalogoItem('a')
      expect(mocks.supabase.builderDe('jogos_catalogo').delete).toHaveBeenCalled()
    })
  })

  describe('pontosDaCorNaRodada', () => {
    const CONFIG: PontosJogosConfig[] = [
      { colocacao: 1, pontos: 100, desclassificado: false },
      { colocacao: 2, pontos: 70, desclassificado: false },
    ]

    it('retorna os pontos da colocação da cor na rodada (espelho do trigger)', async () => {
      const jogos = useJogos()
      await jogos.carregarEventos('e1')
      const rodada = jogos.rodadas.value[0]!
      expect(jogos.pontosDaCorNaRodada(rodada, 'cor1', CONFIG)).toBe(100)
      expect(jogos.pontosDaCorNaRodada(rodada, 'cor2', CONFIG)).toBe(0)
      expect(pontosDoResultado({ colocacao: 1, desclassificado: false }, CONFIG)).toBe(100)
    })
  })

  describe('constantes do módulo', () => {
    it('expõe as cores pré-definidas', () => {
      expect(CORES_PREDEFINIDAS).toEqual(['verde', 'vermelho', 'amarelo', 'azul'])
    })
  })
})