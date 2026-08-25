import { beforeEach, describe, expect, it, vi } from 'vitest'
import { builder, clienteSupabase } from '../../tests/helpers/supabase'
import { useJogos } from './useJogos'
import { CORES_PREDEFINIDAS, pontosDoResultado, type PontosJogosConfig } from '@/utils/jogos'

const EVENTO = {
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
      eventos_jogos: () => builder(EVENTO),
      jogos: () => builder(RODADAS),
      jogos_catalogo: () => builder([]),
    })
  })

  describe('carregarEvento', () => {
    it('normaliza evento, clubes, cores, oansistas e rodadas', async () => {
      const jogos = useJogos()
      await jogos.carregarEvento('e1')

      expect(jogos.evento.value?.id).toBe('ev1')
      expect(jogos.evento.value?.nome).toBe('Jogos dos Flamas e Tochas')
      expect(jogos.evento.value?.status).toBe('em_andamento')
      expect(jogos.evento.value?.clubes).toEqual([
        { clube_id: 'c1', nome: 'Flamas', slug: 'flamas', cor: '#22C55E' },
        { clube_id: 'c2', nome: 'Tochas', slug: 'tochas', cor: '#3B82F6' },
      ])
      expect(jogos.evento.value?.cores).toHaveLength(2)
      expect(jogos.evento.value?.cores[0]?.oansistas).toEqual([{ oansista_id: 'o1', nome: 'Ana' }])

      expect(jogos.rodadas.value).toHaveLength(1)
      expect(jogos.rodadas.value[0]?.nome).toBe('maratona')
      expect(jogos.rodadas.value[0]?.resultados[0]).toEqual({ id: 'r1', cor_id: 'cor1', colocacao: 1, desclassificado: false, pontos: 100 })
      expect(jogos.carregando.value).toBe(false)
    })

    it('deixa evento nulo quando não existe evento no encontro', async () => {
      mocks.supabase = clienteSupabase({
        eventos_jogos: () => builder(null),
        jogos: () => builder([]),
      })
      const jogos = useJogos()
      await jogos.carregarEvento('e1')
      expect(jogos.evento.value).toBeNull()
    })
  })

  describe('criarEvento', () => {
    it('chama a RPC fn_criar_evento_jogos e recarrega o evento', async () => {
      mocks.supabase.rpc.mockResolvedValue({ data: { id: 'ev9' }, error: null })
      const jogos = useJogos()
      await jogos.carregarEvento('e1')
      const id = await jogos.criarEvento('Jogos dos Flamas e Tochas', ['c1', 'c2'], ['verde', 'azul'], 'p1')

      expect(id).toBe('ev9')
      expect(mocks.supabase.rpc).toHaveBeenCalledWith('fn_criar_evento_jogos', {
        p_encontro_id: 'e1',
        p_nome: 'Jogos dos Flamas e Tochas',
        p_clubes: ['c1', 'c2'],
        p_cores: ['verde', 'azul'],
        p_criado_por: 'p1',
      })
      expect(mocks.supabase.builderDe('eventos_jogos').eq).toHaveBeenCalledWith('encontro_id', 'e1')
    })

    it('lança erro quando a RPC falha', async () => {
      mocks.supabase.rpc.mockResolvedValue({ data: null, error: { message: 'Já existe um evento de jogos para este encontro' } })
      const jogos = useJogos()
      await jogos.carregarEvento('e1')
      await expect(jogos.criarEvento('X', ['c1'], ['verde', 'azul'], 'p1')).rejects.toThrow('Já existe um evento de jogos para este encontro')
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
    it('atualiza o status do evento para finalizado e depois em_andamento', async () => {
      const jogos = useJogos()
      await jogos.carregarEvento('e1')

      await jogos.finalizarEvento('ev1')
      expect(mocks.supabase.builderDe('eventos_jogos').update).toHaveBeenCalledWith({ status: 'finalizado' })
      expect(jogos.evento.value?.status).toBe('finalizado')

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
      await jogos.carregarEvento('e1')
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